package vn.shadichy.assignment;

//import com.mongodb.reactivestreams.client.MongoClient;
//import com.mongodb.reactivestreams.client.MongoClients;
import org.dizitart.no2.mvstore.MVStoreModule;
import vn.shadichy.assignment.firstrun.FirstRunSetup;
import vn.shadichy.assignment.content.UndertowServer;

import java.io.FileInputStream;
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

    private static final String hostname = System.getProperty("assignment.hostname", "localhost");
    private static final int dbPort = Integer.parseInt(System.getProperty("assignment.dbport", "27017"));
    private static final int httpPort = Integer.parseInt(System.getProperty("assignment.httpport", "8080"));
    private static final int httpsPort = Integer.parseInt(System.getProperty("assignment.httpsport", "8443"));
    private static final String dbName = System.getProperty("assignment.dbname", "AssignmentDiscDB");
    public static final String dbPath = confDir + s + dbName + ".db";

    public static void main(String[] args) throws Exception {
        Properties p = new Properties(System.getProperties());

        Scanner stdin = new Scanner(System.in);

        final String username = stdin.next();
        final String password = stdin.next();

        MVStoreModule storeModule = MVStoreModule.withConfig()
                .filePath(dbPath)
                .compress(true)
                .build();

        if (!Files.exists(CONFIG) || !Files.isRegularFile(CONFIG)) {
            Thread setup = new FirstRunSetup(storeModule, username, password);
            setup.start();
            setup.wait();
        }

        FileInputStream propFile = new FileInputStream(CONFIG.toFile());
        p.load(propFile);
        System.setProperties(p);

//        new LoginExecutor(hostname, dbPort, dbName, username, password);

        new UndertowServer("https://" + hostname + ":" + httpsPort, hostname, storeModule, httpPort, httpsPort, username, password).start();
    }
}