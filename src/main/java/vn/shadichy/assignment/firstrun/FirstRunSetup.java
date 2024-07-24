package vn.shadichy.assignment.firstrun;

import org.dizitart.no2.Nitrite;
import org.dizitart.no2.mvstore.MVStoreModule;
import vn.shadichy.assignment.Main;
import vn.shadichy.assignment.provider.Artist;
import vn.shadichy.assignment.provider.Customer;
import vn.shadichy.assignment.provider.Disc;
import vn.shadichy.assignment.provider.Invoice;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

public class FirstRunSetup extends Thread {
    //    requirement: MongoDB, OpenSSL, Java 17+
    private final MVStoreModule storeModule;
    //    private final int port;
//    private final String dbName;
    private final String username;
    private final String password;

    public FirstRunSetup(MVStoreModule storeModule, String username, String password) {
        this.storeModule = storeModule;
        this.username = username;
        this.password = password;
    }

    @Override
    public void run() {
        try {

//        String password = BCrypt.with(new SecureRandom(username.getBytes())).hashToString(8, password.toCharArray());

//        // System.err.println("Hashed password: " + password);

//            List<BasicDBObject> roles = new ArrayList<>();
//            roles.add(new BasicDBObject("role", "readWrite").append("db", dbName));
//            final BasicDBObject createUserCommand = new BasicDBObject("createUser", username)
//                    .append("pwd", password)
//                    .append("roles", roles);
////            createUserCommand.wait();
//
//            MongoClient mongoClient = MongoClients.create(MongoClientSettings
//                    .builder()
//                    .applyToClusterSettings(builder -> builder.hosts(List.of(new ServerAddress(hostname, port))))
//                    .build());
//
////            mongoClient.wait();
////            mongoClient.getDatabase("admin").runCommand(createUserCommand);
//
//            MongoDatabase database = mongoClient.getDatabase(dbName);
//            database.runCommand(createUserCommand);
////            database.wait();
//
//            database.createCollection("Artist");
//            database.createCollection("Customer");
//            database.createCollection("Disc");


//            mongoClient.close();

//            Nitrite db = Nitrite.builder().loadModule(storeModule).openOrCreate(username, password);
//            db.getRepository(Artist.class, "Artist");
//            db.getRepository(Customer.class, "Customer");
//            db.getRepository(Disc.class, "Disc");
//            db.getRepository(Invoice.class, "Invoice");
//            db.close();

            String jHome = System.getProperty("java.home");
            String s = Main.s;

            String confDir = Main.confDir;
            Path confPath = Path.of(confDir);
            if (!Files.isDirectory(confPath)) {
                Files.createDirectory(confPath);
            }

            String keytool = jHome + s + "bin" + s + "keytool";

            if (System.getProperty("os.name").toLowerCase().contains("windows")) {
                keytool = keytool + ".exe";
            }

            String serverKeystore = confDir + s + "server.keystore.ks";
            String serverTruststore = confDir + s + "server.truststore.ks";
            String clientKeystore = confDir + s + "client.keystore.ks";
            String clientTruststore = confDir + s + "client.truststore.ks";

            ProcessBuilder createServerKeystore = new ProcessBuilder(
                    keytool,
                    "-genkey",
                    "-alias", "server.keystore",
                    "-keyalg", "RSA",
                    "-sigalg", "SHA256withRSA",
                    "-keysize", "2048",
                    "-keystore", serverKeystore,
                    "-dname", "CN=Assignment, C=VN",
                    "-storepass", password,
                    "-keypass", password);
            ProcessBuilder createServerTruststore = new ProcessBuilder(
                    keytool,
                    "-genkey",
                    "-alias", "server.truststore",
                    "-keyalg", "RSA",
                    "-sigalg", "SHA256withRSA",
                    "-keysize", "2048",
                    "-keystore", serverTruststore,
                    "-dname", "CN=Assignment, C=VN",
                    "-storepass", password,
                    "-keypass", password);
            ProcessBuilder createServerCert = new ProcessBuilder(
                    keytool,
                    "-export",
                    "-alias",
                    "server.keystore",
                    "-keypass", password,
                    "-storepass", password,
                    "-file", confDir + s + "server.keystore.cer",
                    "-keystore", serverKeystore);
            ProcessBuilder createClientKeystore = new ProcessBuilder(
                    keytool,
                    "-genkey",
                    "-alias", "client.keystore",
                    "-keyalg", "RSA",
                    "-keystore", clientKeystore,
                    "-dname", "CN=Assignment Client, C=VN",
                    "-storepass", password,
                    "-keypass", password);
            ProcessBuilder createClientTruststore = new ProcessBuilder(
                    keytool,
                    "-genkey",
                    "-alias", "client.truststore",
                    "-keyalg", "RSA",
                    "-sigalg", "SHA256withRSA",
                    "-keysize", "2048",
                    "-keystore", clientTruststore,
                    "-dname", "CN=Assignment, C=VN",
                    "-storepass", password,
                    "-keypass", password);
            ProcessBuilder createClientCert = new ProcessBuilder(
                    keytool,
                    "-export",
                    "-alias",
                    "client.keystore",
                    "-keypass", password,
                    "-storepass", password,
                    "-file", confDir + s + "client.keystore.cer",
                    "-keystore", clientKeystore);
            ProcessBuilder importServerCert = new ProcessBuilder(
                    keytool,
                    "-import",
                    "-v",
                    "-trustcacerts",
                    "-alias",
                    "server",
                    "-keypass", password,
                    "-storepass", password,
                    "-file", confDir + s + "server.keystore.cer",
                    "-keystore", clientTruststore);
            ProcessBuilder importClientCert = new ProcessBuilder(
                    keytool,
                    "-import",
                    "-v",
                    "-trustcacerts",
                    "-alias",
                    "client",
                    "-keypass", password,
                    "-storepass", password,
                    "-file", confDir + s + "client.keystore.cer",
                    "-keystore", serverTruststore);

            createServerKeystore.start();
            createServerTruststore.start();
            createServerCert.start();
            createClientKeystore.start();
            createClientTruststore.start();
            createClientCert.start();
            importServerCert.start();
            importClientCert.start();

            System.setProperty("server.keystore", serverKeystore);
            System.setProperty("server.truststore", serverTruststore);
            System.setProperty("client.keystore", clientKeystore);
            System.setProperty("client.truststore", clientTruststore);


            Files.writeString(Main.CONFIG,
                    "server.keystore=" + serverKeystore + "\n" +
                            "server.truststore=" + serverTruststore + "\n" +
                            "client.keystore=" + clientKeystore + "\n" +
                            "client.truststore=" + clientTruststore + "\n",
                    StandardCharsets.UTF_8);

//            notifyAll();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
