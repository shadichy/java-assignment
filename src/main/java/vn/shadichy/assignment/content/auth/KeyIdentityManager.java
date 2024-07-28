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

    @Override
    public Account verify(Account account) {
        return null;
    }

    @Override
    public Account verify(Credential credential) {
        return null;
    }

    @Override
    public Account verify(String username, Credential credential) {
        if (!(credential instanceof PasswordCredential)) return null;

        char[] key = (username + ":" + new String(((PasswordCredential) credential).getPassword())).toCharArray();

        try {
            loadKeyStore("server.keystore", key);
            loadKeyStore("server.truststore", key);
            loadKeyStore("client.keystore", key);
            loadKeyStore("client.truststore", key);
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

    private KeyStore loadKeyStore(String name, char[] key) throws Exception {
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
            loadedKeystore.load(is, key);
            return loadedKeystore;
        }
    }

}
