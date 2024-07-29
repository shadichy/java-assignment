package vn.shadichy.assignment.content;

import com.google.gson.Gson;
import io.undertow.Undertow;
import io.undertow.UndertowOptions;
import io.undertow.protocols.ssl.UndertowXnioSsl;
import io.undertow.security.api.AuthenticationMechanism;
import io.undertow.security.api.AuthenticationMode;
import io.undertow.security.handlers.AuthenticationCallHandler;
import io.undertow.security.handlers.AuthenticationConstraintHandler;
import io.undertow.security.handlers.AuthenticationMechanismsHandler;
import io.undertow.security.handlers.SecurityInitialHandler;
import io.undertow.security.idm.IdentityManager;
import io.undertow.security.impl.BasicAuthenticationMechanism;
import io.undertow.server.HttpHandler;
import io.undertow.server.HttpServerExchange;
import io.undertow.server.handlers.LearningPushHandler;
import io.undertow.server.handlers.ResponseCodeHandler;
import io.undertow.server.handlers.proxy.LoadBalancingProxyClient;
import io.undertow.server.handlers.proxy.ProxyHandler;
import io.undertow.server.session.InMemorySessionManager;
import io.undertow.server.session.SessionAttachmentHandler;
import io.undertow.server.session.SessionCookieConfig;
import io.undertow.util.Headers;
import io.undertow.util.HttpString;
import io.undertow.util.StatusCodes;
import org.dizitart.no2.Nitrite;
import org.dizitart.no2.collection.FindOptions;
import org.dizitart.no2.common.SortOrder;
import org.dizitart.no2.common.WriteResult;
import org.dizitart.no2.exceptions.NotIdentifiableException;
import org.dizitart.no2.exceptions.UniqueConstraintException;
import org.dizitart.no2.exceptions.ValidationException;
import org.dizitart.no2.filters.Filter;
import org.dizitart.no2.filters.NitriteFilter;
import org.dizitart.no2.migration.InstructionSet;
import org.dizitart.no2.migration.Migration;
import org.dizitart.no2.mvstore.MVStoreModule;
import org.dizitart.no2.repository.Cursor;
import org.dizitart.no2.repository.ObjectRepository;
import org.xnio.OptionMap;
import org.xnio.Xnio;
import vn.shadichy.assignment.Main;
import vn.shadichy.assignment.content.auth.KeyIdentityManager;
import vn.shadichy.assignment.internal.TypeCaster;
import vn.shadichy.assignment.provider.*;

import javax.net.ssl.*;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.*;
import java.security.cert.CertificateException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.BiFunction;
import java.util.function.Function;
import java.util.stream.Collectors;

import static org.dizitart.no2.filters.FluentFilter.$;
import static org.dizitart.no2.filters.FluentFilter.where;
import static vn.shadichy.assignment.internal.TypeCaster.*;

public class UndertowServer extends Thread {

    private static final Gson gson = new Gson();
    private final String hostname;
    private final int httpPort;
    private final int httpsPort;
    private final String host;
    private final String username;
    private final String password;
    private final MVStoreModule storeModule;
    private final char[] key;

    public UndertowServer(String host, String hostname, MVStoreModule storeModule, int httpPort, int httpsPort, String username, String password) {
        this.hostname = hostname;
        this.httpPort = httpPort;
        this.httpsPort = httpsPort;
        this.host = host;
        this.username = username;
        this.password = password;
        this.storeModule = storeModule;
        this.key = (username + ":" + password).toCharArray();
    }

    private HttpHandler addSecurity(final HttpHandler toWrap, final IdentityManager identityManager) {
        HttpHandler handler = toWrap;
        handler = new AuthenticationCallHandler(handler);
        handler = new AuthenticationConstraintHandler(handler);
        final List<AuthenticationMechanism> mechanisms = List.of(new BasicAuthenticationMechanism("Realm"));
        handler = new AuthenticationMechanismsHandler(handler, mechanisms);
        handler = new SecurityInitialHandler(AuthenticationMode.PRO_ACTIVE, identityManager, handler);
        return handler;
    }

    private HttpHandler addSessionManager(final HttpHandler toWrap) {
        HttpHandler handler = toWrap;
        handler = new LearningPushHandler(100, -1, handler);
        handler = new SessionAttachmentHandler(handler, new InMemorySessionManager("sessionManager"), new SessionCookieConfig());
        return handler;
    }

    private <T extends DatabaseEntry> String findToArr(ObjectRepository<T> repository, List<NitriteFilter> filters, int offset, int limit) {
        Cursor<T> cursor;

        if (filters.isEmpty()) {
            FindOptions opts = FindOptions.orderBy("date", SortOrder.Descending);
            if (offset > 0) opts = opts.skip(offset);
            if (limit > 0) opts = opts.limit(limit);
            cursor = repository.find(opts);
        } else if (filters.size() == 1) cursor = repository.find(filters.get(0));
        else cursor = repository.find(Filter.and(filters.toArray(new NitriteFilter[0])));

        return "[" + cursor.toList().stream().map(DatabaseEntry::get).collect(Collectors.joining(",")) + "]";
    }

    @Override
    public void run() {
        final IdentityManager identityManager = new KeyIdentityManager();
        final SSLContext serverSslContext = createSSLContext(loadKeyStore("server.keystore"), loadKeyStore("server.truststore"));

        final Nitrite db = Nitrite.builder()
                .registerEntityConverter(new Artist.Converter())
                .registerEntityConverter(new Customer.Converter())
                .registerEntityConverter(new Disc.Converter())
                .registerEntityConverter(new Invoice.Converter())
                .loadModule(storeModule)
                .openOrCreate(username, password);

        final ObjectRepository<Artist> artists = db.getRepository(Artist.class, "Artist");
        final ObjectRepository<Customer> customers = db.getRepository(Customer.class, "Customer");
        final ObjectRepository<Disc> discs = db.getRepository(Disc.class, "Disc");
        final ObjectRepository<Invoice> invoices = db.getRepository(Invoice.class, "Invoice");

        final Function<Integer, WriteResult> removeInvoice = id -> invoices.remove(invoices.getById(id));
        final Function<Integer, WriteResult> removeDisc = id -> {
            invoices.remove(where("trackIDs").elemMatch($.eq(id)));
            return discs.remove(discs.getById(id));
        };
        final Function<Integer, WriteResult> removeCustomer = id -> {
            invoices.remove(where("customer").eq(id));
            return customers.remove(customers.getById(id));
        };
        final Function<Integer, WriteResult> removeArtist = id -> {
            discs.find(where("artists").elemMatch($.eq(id))).forEach(disc -> removeDisc.apply(disc.getId()));
            return artists.remove(artists.getById(id));
        };

        final BiFunction<HttpServerExchange, byte[], Void> bodyProcess = (exchange, message) -> {
            Map<?, ?> body;
            try {
                body = gson.fromJson(new String(message), Map.class);
            } catch (Exception e) {
                exchange.setStatusCode(StatusCodes.INTERNAL_SERVER_ERROR).getResponseSender().send("{\"response\": \"Invalid body\"}");
                return null;
            }
            int statusCode = StatusCodes.OK;
            String result = "{\"response\": \"ok\"}";

            String path = String.valueOf(body.get("path"));
            switch ((String) body.get("method")) {
                case "get" -> {
                    Integer limit = toInt(body.get("limit"));
                    if (limit == null) limit = 60;
                    Integer offset = toInt(body.get("offset"));
                    if (offset == null) offset = 0;

                    List<NitriteFilter> f = new ArrayList<>(List.of());

                    Integer id = toInt(body.get("id"));

                    switch (path) {
                        case "artist" -> {
                            if (id != null) {
                                result = artists.getById(id).toString();
                                break;
                            }
                            String name = (String) body.get("name");
                            if (name != null) f.add(where("name").regex(name));
                            String desc = (String) body.get("description");
                            if (desc != null) f.add(where("description").regex(desc));
                            Long debutBefore = toLong(body.get("debutBefore"));
                            if (debutBefore != null) f.add(where("date").lte(debutBefore));
                            Integer debutAfter = toInt(body.get("debutAfter"));
                            if (debutAfter != null) f.add(where("date").gte(debutAfter));
                            List<String> hasAlbums = (List) body.get("hasAlbums");
                            if (hasAlbums != null && !hasAlbums.isEmpty()) {
                                f.add(where("albumNames").elemMatch($.in(hasAlbums.toArray(new String[0]))));
                            }
                            List<?> hasTracks = (List<?>) body.get("hasTracks");
                            if (hasTracks != null && !hasTracks.isEmpty()) {
                                f.add(where("tracks").elemMatch($.in(castList(hasTracks, TypeCaster::toInt).toArray(new Integer[0]))));
                            }
                            result = findToArr(artists, f, offset, limit);
                        }
                        case "customer" -> {
                            if (id != null) {
                                result = customers.getById(id).toString();
                                break;
                            }
                            String name = (String) body.get("name");
                            if (name != null) f.add(where("name").regex(name));
                            String email = (String) body.get("email");
                            if (email != null) f.add(where("desc").regex(email));
                            Integer createdBefore = toInt(body.get("createdBefore"));
                            if (createdBefore != null) f.add(where("date").lte(createdBefore));
                            Integer createdAfter = toInt(body.get("createdAfter"));
                            if (createdAfter != null) f.add(where("date").gte(createdAfter));
                            List<String> hasPhones = (List) body.get("hasPhones");
                            if (hasPhones != null && !hasPhones.isEmpty())
                                f.add(where("phoneNo").elemMatch($.in(hasPhones.toArray(new String[0]))));
                            result = findToArr(customers, f, offset, limit);
                        }
                        case "disc" -> {
                            if (id != null) {
                                result = discs.getById(id).toString();
                                break;
                            }
                            String name = (String) body.get("name");
                            if (name != null) f.add(where("name").regex(name));
                            Integer releaseBefore = toInt(body.get("releaseBefore"));
                            if (releaseBefore != null) f.add(where("date").lte(releaseBefore));
                            Integer releaseAfter = toInt(body.get("releaseAfter"));
                            if (releaseAfter != null) f.add(where("date").gte(releaseAfter));
                            Integer stockHighest = toInt(body.get("stockHighest"));
                            if (stockHighest != null) f.add(where("stockCount").lte(stockHighest));
                            Integer stockLowest = toInt(body.get("stockLowest"));
                            if (stockLowest != null) f.add(where("stockCount").gte(stockLowest));
                            Integer priceHighest = toInt(body.get("priceHighest"));
                            if (priceHighest != null) f.add(where("price").lte(priceHighest));
                            Integer priceLowest = toInt(body.get("priceLowest"));
                            if (priceLowest != null) f.add(where("price").gte(priceLowest));
                            List<?> hasArtists = (List<?>) body.get("hasArtists");
                            if (hasArtists != null && !hasArtists.isEmpty())
                                f.add(where("artists").elemMatch($.in((castList(hasArtists, TypeCaster::toInt)).toArray(new Integer[0]))));
                            result = findToArr(discs, f, offset, limit);

                        }
                        case "invoice" -> {
                            if (id != null) {
                                result = invoices.getById(id).toString();
                                break;
                            }
                            Integer customer = toInt(body.get("customer"));
                            if (customer != null) f.add(where("customer").eq(customer));
                            Integer before = toInt(body.get("before"));
                            if (before != null) f.add(where("date").lte(before));
                            Integer after = toInt(body.get("after"));
                            if (after != null) f.add(where("date").gte(after));
                            List<?> hasDiscs = (List<?>) body.get("hasDiscs");
                            if (hasDiscs != null && !hasDiscs.isEmpty())
                                f.add(where("trackIDs").elemMatch($.in(castList(hasDiscs, TypeCaster::toInt).toArray(new Integer[0]))));
                            List<?> hasCustomers = (List<?>) body.get("hasCustomers");
                            if (hasCustomers != null && !hasCustomers.isEmpty())
                                f.add(where("customer").in(castList(hasCustomers, TypeCaster::toInt).toArray(new Integer[0])));
                            result = findToArr(invoices, f, offset, limit);
                        }
                        default -> {
                            result = "{\"response\": \"illegal path\"}";
                            statusCode = StatusCodes.NOT_FOUND;
                        }
                    }

                    if (statusCode == StatusCodes.NOT_FOUND) return null;
                }
                case "add" -> {
                    List<Map<Object, Object>> data = (List) body.get("data");
                    try {
                        switch (path) {
                            case "artist" -> artists.insert(castList(data, Artist::addNew).toArray(new Artist[0]));
                            case "customer" -> customers.insert(castList(data, Customer::addNew).toArray(new Customer[0]));
                            case "disc" -> discs.insert(castList(data, Disc::addNew).toArray(new Disc[0]));
                            case "invoice" -> invoices.insert(castList(data, Invoice::fromMap).toArray(new Invoice[0]));
                            default -> {
                                result = "{\"response\": \"illegal path\"}";
                                statusCode = StatusCodes.NOT_FOUND;
                            }
                        }
                    } catch (UniqueConstraintException | ValidationException e) {
                        result = "{\"response\": \"already exist\"}";
                        statusCode = StatusCodes.INTERNAL_SERVER_ERROR;
                    }
                }
                case "update" -> {
                    try {
                        switch (path) {
                            case "artist" -> artists.update(Artist.fromMap((Map<?, ?>) body.get("data")));
                            case "customer" -> customers.update(Customer.fromMap((Map<?, ?>) body.get("data")));
                            case "disc" -> discs.update(Disc.fromMap((Map<?, ?>) body.get("data")));
                            // invoice is unmodifiable
                            default -> {
                                result = "{\"response\": \"illegal path\"}";
                                statusCode = StatusCodes.NOT_FOUND;
                            }
                        }
                    } catch (ValidationException | NotIdentifiableException e) {
                        result = "{\"response\": \"invalid\"}";
                        statusCode = StatusCodes.INTERNAL_SERVER_ERROR;
                    }
                }
                case "delete" -> {
                    try {
                        int id = toInt(body.get("id"));
                        switch (path) {
                            case "artist" -> removeArtist.apply(id);
                            case "customer" -> removeCustomer.apply(id);
                            case "disc" -> removeDisc.apply(id);
                            case "invoice" -> removeInvoice.apply(id);
                            default -> {
                                result = "{\"response\": \"illegal path\"}";
                                statusCode = StatusCodes.NOT_FOUND;
                            }
                        }
                    } catch (NotIdentifiableException | ValidationException e) {
                        result = "{\"response\": \"non exist\"}";
                        statusCode = StatusCodes.INTERNAL_SERVER_ERROR;
                    }
                }
                case "system" -> {
                    int code = 0;
                    switch (path) {
                        case "shutdown" -> {
                        }
                        case "wipe" -> code = Paths.get(Main.confDir).toFile().delete() ? 0 : 1;
                        case "password" -> {
                            db.close();
                            String newPwd = String.valueOf(body.get("data"));
                            if (newPwd.equals("null") || newPwd.isEmpty()) {
                                result = "{\"response\": \"empty string\"}";
                                statusCode = StatusCodes.NOT_ACCEPTABLE;
                                code = -1;
                                break;
                            }
                            Nitrite.builder()
                                    .registerEntityConverter(new Artist.Converter())
                                    .registerEntityConverter(new Customer.Converter())
                                    .registerEntityConverter(new Disc.Converter())
                                    .registerEntityConverter(new Invoice.Converter())
                                    .loadModule(storeModule)
                                    .schemaVersion(0)
                                    .addMigrations(new Migration(0, 1) {
                                        @Override
                                        public void migrate(InstructionSet set) {
                                            set.forDatabase().changePassword(username, password, newPwd);
                                        }
                                    })
                                    .openOrCreate(username, newPwd)
                                    .close();
                            Main.CONFIG.toFile().delete();
                            Paths.get(System.getProperty("server.keystore")).toFile().delete();
                            Paths.get(System.getProperty("server.truststore")).toFile().delete();
                            Paths.get(System.getProperty("client.keystore")).toFile().delete();
                            Paths.get(System.getProperty("client.truststore")).toFile().delete();
                        }
                        default -> {
                            result = "{\"response\": \"illegal path\"}";
                            statusCode = StatusCodes.NOT_FOUND;
                            code = -1;
                        }
                    }
                    if (code == -1) break;
                    System.exit(code);
                }
                default -> {
                    result = "{\"response\": \"illegal method\"}";
                    statusCode = StatusCodes.NOT_FOUND;
                }
            }
            exchange.setStatusCode(statusCode).getResponseSender().send(result);
            return null;
        };

        final Function<HttpServerExchange, Void> requestHandler = exchange -> {
            exchange.getResponseHeaders().put(Headers.CONTENT_TYPE, "application/json");
            if (!exchange.getRequestMethod().equals(HttpString.tryFromString("POST"))) {
                exchange.setStatusCode(StatusCodes.OK).getResponseSender().send("{\"response\": \"only POST is allowed\"}");
                return null;
            }

            exchange.getRequestReceiver().receiveFullBytes((exchange1, message) -> bodyProcess.apply(exchange, message));

            if (!exchange.isResponseStarted()) {
                exchange.setStatusCode(StatusCodes.INTERNAL_SERVER_ERROR).getResponseSender().send("{\"response\": \"server error\"}");
            }
            return null;
        };

        final io.undertow.Undertow server = Undertow.builder()
                .setServerOption(UndertowOptions.ENABLE_HTTP2, true)
                .addHttpListener(httpPort, hostname)
                .addHttpsListener(httpsPort, hostname, serverSslContext)
                .setHandler(addSecurity(addSessionManager(requestHandler::apply), identityManager))
                .build();

        server.start();

        SSLContext clientSslContext = createSSLContext(loadKeyStore("client.keystore"), loadKeyStore("client.truststore"));

        LoadBalancingProxyClient proxy;
        try {
            final org.xnio.ssl.XnioSsl ssl = new UndertowXnioSsl(Xnio.getInstance(), OptionMap.EMPTY, clientSslContext);
            final org.xnio.OptionMap options = OptionMap.create(UndertowOptions.ENABLE_HTTP2, true);
            proxy = new LoadBalancingProxyClient()
                    .addHost(new URI(host), null, ssl, options)
                    .setConnectionsPerThread(20);
        } catch (URISyntaxException e) {
            throw new RuntimeException(e);
        }

        io.undertow.Undertow reverseProxy = io.undertow.Undertow.builder()
                .setServerOption(UndertowOptions.ENABLE_HTTP2, true)
                .addHttpListener(httpPort + 1, hostname)
                .addHttpsListener(httpsPort + 1, hostname, serverSslContext)
                .setHandler(new ProxyHandler(proxy, 30000, ResponseCodeHandler.HANDLE_404))
                .build();
        reverseProxy.start();

    }

    private KeyStore loadKeyStore(String name) {
        String storeLoc = String.valueOf(System.getProperty(name));
        final InputStream stream;
        if (storeLoc.equals("null")) {
            stream = Main.class.getResourceAsStream(name);
        } else {
            try {
                stream = Files.newInputStream(Paths.get(storeLoc));
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }

        if (stream == null) {
            throw new RuntimeException("Could not load keystore");
        }

        try (InputStream is = stream) {
            KeyStore loadedKeystore = KeyStore.getInstance("JKS");
            loadedKeystore.load(is, key);
            return loadedKeystore;
        } catch (IOException | CertificateException | KeyStoreException | NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }


    private SSLContext createSSLContext(final KeyStore keyStore, final KeyStore trustStore) {
        try {
            KeyManager[] keyManagers;
            KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            keyManagerFactory.init(keyStore, key);
            keyManagers = keyManagerFactory.getKeyManagers();

            TrustManager[] trustManagers;
            TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            trustManagerFactory.init(trustStore);
            trustManagers = trustManagerFactory.getTrustManagers();

            SSLContext sslContext;
            sslContext = SSLContext.getInstance("TLS");
            sslContext.init(keyManagers, trustManagers, null);

            return sslContext;
        } catch (UnrecoverableKeyException | NoSuchAlgorithmException | KeyStoreException | KeyManagementException e) {
            throw new RuntimeException(e);
        }
    }
}
