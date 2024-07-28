package vn.shadichy.assignment.firstrun;

import vn.shadichy.assignment.Main;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

public class FirstRunSetup extends Thread {
    private final String key;

    public FirstRunSetup(String username, String password) {
        this.key = username + ":" + password;
    }

    @Override
    public void run() {
        try {
            String jHome = System.getProperty("java.home");
            String s = Main.s;

            String confDir = Main.confDir;
            Path confPath = Path.of(confDir);
            if (!Files.isDirectory(confPath)) {
                Files.createDirectory(confPath);
            }

            String keytool = jHome + s + "bin" + s + "keytool";

            boolean isWindows = System.getProperty("os.name").toLowerCase().contains("windows");

            if (isWindows) keytool = keytool + ".exe";

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
                    "-storepass", key,
                    "-keypass", key);
            ProcessBuilder createServerTruststore = new ProcessBuilder(
                    keytool,
                    "-genkey",
                    "-alias", "server.truststore",
                    "-keyalg", "RSA",
                    "-sigalg", "SHA256withRSA",
                    "-keysize", "2048",
                    "-keystore", serverTruststore,
                    "-dname", "CN=Assignment, C=VN",
                    "-storepass", key,
                    "-keypass", key);
            ProcessBuilder createServerCert = new ProcessBuilder(
                    keytool,
                    "-export",
                    "-alias", "server.keystore",
                    "-keypass", key,
                    "-storepass", key,
                    "-file", confDir + s + "server.keystore.cer",
                    "-keystore", serverKeystore);
            ProcessBuilder createClientKeystore = new ProcessBuilder(
                    keytool,
                    "-genkey",
                    "-alias", "client.keystore",
                    "-keyalg", "RSA",
                    "-keystore", clientKeystore,
                    "-dname", "CN=Assignment Client, C=VN",
                    "-storepass", key,
                    "-keypass", key);
            ProcessBuilder createClientTruststore = new ProcessBuilder(
                    keytool,
                    "-genkey",
                    "-alias", "client.truststore",
                    "-keyalg", "RSA",
                    "-sigalg", "SHA256withRSA",
                    "-keysize", "2048",
                    "-keystore", clientTruststore,
                    "-dname", "CN=Assignment, C=VN",
                    "-storepass", key,
                    "-keypass", key);
            ProcessBuilder createClientCert = new ProcessBuilder(
                    keytool,
                    "-export",
                    "-alias", "client.keystore",
                    "-keypass", key,
                    "-storepass", key,
                    "-file", confDir + s + "client.keystore.cer",
                    "-keystore", clientKeystore);
            ProcessBuilder importServerCert = new ProcessBuilder(
                    keytool,
                    "-import",
                    "-v",
                    "-noprompt",
                    "-trustcacerts",
                    "-alias", "server",
                    "-keypass", key,
                    "-storepass", key,
                    "-file", confDir + s + "server.keystore.cer",
                    "-keystore", clientTruststore);
            ProcessBuilder importClientCert = new ProcessBuilder(
                    keytool,
                    "-import",
                    "-v",
                    "-noprompt",
                    "-trustcacerts",
                    "-alias", "client",
                    "-keypass", key,
                    "-storepass", key,
                    "-file", confDir + s + "client.keystore.cer",
                    "-keystore", serverTruststore);

            createServerKeystore.inheritIO().start().waitFor();
            createServerTruststore.inheritIO().start().waitFor();
            createServerCert.inheritIO().start().waitFor();
            createClientKeystore.inheritIO().start().waitFor();
            createClientTruststore.inheritIO().start().waitFor();
            createClientCert.inheritIO().start().waitFor();
            importServerCert.inheritIO().start().waitFor();
            importClientCert.inheritIO().start().waitFor();


            System.setProperty("server.keystore", serverKeystore);
            System.setProperty("server.truststore", serverTruststore);
            System.setProperty("client.keystore", clientKeystore);
            System.setProperty("client.truststore", clientTruststore);

            String configContents = "server.keystore=" + serverKeystore + "\n" +
                    "server.truststore=" + serverTruststore + "\n" +
                    "client.keystore=" + clientKeystore + "\n" +
                    "client.truststore=" + clientTruststore + "\n";

            // There's a problem with file writing on windows that we need to double up the backslashes
            if (isWindows) configContents = configContents.replaceAll(s, s + s);

            Files.writeString(Main.CONFIG, configContents, StandardCharsets.UTF_8);

        } catch (IOException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    }
}
