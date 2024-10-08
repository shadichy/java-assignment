package vn.shadichy.assignment;

import org.dizitart.no2.mvstore.MVStoreModule;
import vn.shadichy.assignment.content.UndertowServer;
import vn.shadichy.assignment.firstrun.FirstRunSetup;

import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Properties;
import java.util.Scanner;

public class Main {
    public static final String s = FileSystems.getDefault().getSeparator();
    public static final String uHome = System.getProperty("user.home");
    public static final String confDir = uHome + s + ".assignment.conf.d";
    public static final Path CONFIG = Paths.get(confDir + s + ".java.assignment.conf");

    private static final Path lockfile = Paths.get(System.getProperty("java.io.tmpdir") + s + "port.asn");
    private static final String hostname = System.getProperty("assignment.hostname", "localhost");
    private static final int httpPort = Integer.parseInt(System.getProperty("assignment.httpport", "8080"));
    private static final int httpsPort = Integer.parseInt(System.getProperty("assignment.httpsport", "8443"));
    private static final String dbName = System.getProperty("assignment.dbname", "AssignmentDiscDB");
    private static final String dbPath = confDir + s + dbName + ".db";

    public static void main(String[] args) throws Exception {
        Scanner stdin = new Scanner(System.in);
        final String username = stdin.next();
        final String password = stdin.next();
        stdin.close();

        if (!Files.exists(CONFIG) || !Files.isRegularFile(CONFIG)) {
            Thread setup = new FirstRunSetup(username, password);
            setup.start();
            setup.join();
        }

        Properties p = new Properties(System.getProperties());
        FileInputStream propFile = new FileInputStream(CONFIG.toFile());
        p.load(propFile);
        propFile.close();
        System.setProperties(p);

        Files.writeString(lockfile, String.valueOf(httpsPort), StandardCharsets.UTF_8);
        Runtime.getRuntime().addShutdownHook(new ExitHook(lockfile));

        MVStoreModule storeModule = MVStoreModule.withConfig()
                .filePath(dbPath)
                .compress(true)
                .build();

        new UndertowServer("https://" + hostname + ":" + httpsPort, hostname, storeModule, httpPort, httpsPort, username, password).start();
    }

    private static class ExitHook extends Thread {
        private final Path lockfile;

        private ExitHook(Path lockfile) {
            this.lockfile = lockfile;
        }

        @Override
        public void run() {
            lockfile.toFile().delete();
        }
    }
}