package vn.shadichy.assignment.content.auth;

//import at.favre.lib.crypto.bcrypt.BCrypt;
//import com.mongodb.reactivestreams.client.MongoDatabase;
import vn.shadichy.assignment.Main;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.KeyStore;

public class LoginExecutor {
    private final String hostname;
    private final int port;
    private final String username;
    private final String password;
//    private final char[] password;
    private final String dbName;
//    private MongoDatabase database;

    public LoginExecutor(String hostname, int port, String dbName, String username, String password) throws Exception {
        this.hostname = hostname;
        this.port = port;
        this.dbName = dbName;
        this.username = username;
        this.password = password;
//        this.password = BCrypt.with(new SecureRandom(username.getBytes())).hashToChar(8, password.toCharArray());

        // System.err.println("Hashed password: " + new String(password));


        loadKeyStore("server.keystore");
        loadKeyStore("server.truststore");
        loadKeyStore("client.keystore");
        loadKeyStore("client.truststore");
    }

    private KeyStore loadKeyStore(String name) throws Exception {
        String storeLoc = String.valueOf(System.getProperty(name));
        final InputStream stream;
        if (storeLoc.equals("null")) {
            stream = Main.class.getResourceAsStream(name);
        } else {
            stream = Files.newInputStream(Paths.get(storeLoc));
        }

        if (stream == null) {
            throw new RuntimeException("Could not load keystore");
        }
        try (InputStream is = stream) {
            KeyStore loadedKeystore = KeyStore.getInstance("JKS");
            loadedKeystore.load(is, password.toCharArray());
            return loadedKeystore;
        }
    }
}
