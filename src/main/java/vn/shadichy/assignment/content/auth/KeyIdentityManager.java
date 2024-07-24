package vn.shadichy.assignment.content.auth;

import io.undertow.security.idm.Account;
import io.undertow.security.idm.Credential;
import io.undertow.security.idm.IdentityManager;
import io.undertow.security.idm.PasswordCredential;
import vn.shadichy.assignment.Main;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.security.KeyStore;
import java.security.Principal;
import java.util.Set;

public class KeyIdentityManager implements IdentityManager {

//    private static final int[] realSecret = {15499, 475, 119, 14289, 7508, 10062, 2378, 6820, 707, 14553, 15237, 8466, 7786, 2882, 7278, 4853};
//    private final String hostname;
//    private final int port;
//    private final String dbName;

//    KeyIdentityManager(String hostname, int port, String databaseName) {
//        this.hostname = hostname;
//        this.port = port;
//        this.dbName = databaseName;
//    }

    @Override
    public Account verify(Account account) {
        // System.err.println("Has acc");
        return null;
    }

    @Override
    public Account verify(Credential credential) {
        // System.err.println("Has cred");
        return null;
    }

    @Override
    public Account verify(String username, Credential credential) {
        // System.err.println("Has both");
        if (!(credential instanceof PasswordCredential)) {
            return null;
        }

        char[] password = ((PasswordCredential) credential).getPassword();

        try {
            // System.err.println("Received: " + new String(password));
            loadKeyStore("server.keystore", password);
            loadKeyStore("server.truststore", password);
            loadKeyStore("client.keystore", password);
            loadKeyStore("client.truststore", password);
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }

        return new Account() {
            @Override
            public Principal getPrincipal() {
                return () -> username;
            }

            @Override
            public Set<String> getRoles() {
                return Set.of();
            }
        };
    }

    private KeyStore loadKeyStore(String name, char[] password) throws Exception {
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
            loadedKeystore.load(is, password);
            return loadedKeystore;
        }
    }

}
