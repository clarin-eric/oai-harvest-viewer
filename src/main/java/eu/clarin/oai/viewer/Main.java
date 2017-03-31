package eu.clarin.oai.viewer;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import joptsimple.OptionParser;
import joptsimple.OptionSet;
import net.java.truevfs.access.TPath;

/**
 * @author Menzo Windhouwer
 */
public class Main {
    
    private static void showHelp() {
        System.err.println("INF: oaiViewer <options> -- <DIR>?");
        System.err.println("INF: <DIR> harvest source directory (default: .)");
        System.err.println("INF: oaiViewer options:");
        System.err.println("INF: -f <name> of the directory the formats (default: results)");
        System.err.println("INF: -o <FILE> overview file (optional)");
        System.err.println("INF: -r <name> of the directory containing the OAI requests (default: oai-pmh)");
        System.err.println("INF: -t <type> harvest type (default: clarin)");
    }

    public static void main(String[] args) {
        String dir = ".";
        String overview = null;
        String type = "clarin";
        String reqs = "oai-pmh";
        String fmts = "results";
        // check command line
        OptionParser parser = new OptionParser( "f:o:r:t:?*" );
        OptionSet options = parser.parse(args);
        if (options.has("o")) {
            overview = (String)options.valueOf("o");
            Path path = new TPath(overview);
            if (!Files.isRegularFile(path)) {
                System.err.println("FTL: the overview file["+path.toAbsolutePath()+"] doesn't exist!");
                System.exit(1);
            }
            if (!Files.isReadable(path)) {
                System.err.println("FTL: the overview file["+path.toAbsolutePath()+"] can't be read!");
                System.exit(1);
            }
        }
        if (options.has("f")) {
            fmts = (String)options.valueOf("f");
        }
        if (options.has("r")) {
            reqs = (String)options.valueOf("r");
        }
        if (options.has("t")) {
            type = (String)options.valueOf("t");
        }
        if (options.has("?")) {
            showHelp();
            System.exit(0);
        }
        
        List arg = options.nonOptionArguments();
        if (arg.size()>1) {
            System.err.println("FTL: only one source <DIR> argument is allowed!");
            showHelp();
            System.exit(1);
        }
        
        if (arg.size() == 1)
            dir = (String)arg.get(0);
        
        // check if the expected directory structure exists:
        // $DIR/oai-pmh/<repo>/<oai-response>.xml
        // $DIR/results/<format>/<repo>/<oai-record>.xml
        Path path = new TPath(dir+"/"+reqs);
        if (!Files.isDirectory(path)) {
            System.err.println("FTL: the OAI requests directory["+path.toAbsolutePath()+"] doesn't exist!");
            System.exit(1);
        }
        if (!Files.isReadable(path)) {
            System.err.println("FTL: the OAI requests directory["+path.toAbsolutePath()+"] can't be read!");
            System.exit(1);
        }
        path = new TPath(dir+"/"+fmts);
        if (!Files.isDirectory(path)) {
            System.err.println("FTL: the results directory["+path.toAbsolutePath()+"] doesn't exist!");
            System.exit(1);
        }        
        if (!Files.isReadable(path)) {
            System.err.println("FTL: the results directory["+path.toAbsolutePath()+"] can't be read!");
            System.exit(1);
        }
        
        // harvest info
        Harvest harvest = new Harvest(Paths.get(dir));
        harvest.setFormatsDirName(fmts);
        harvest.setRequestDirName(reqs);
        harvest.setType(type);
        if (overview!=null)
            harvest.setOverview(new TPath(overview));
        harvest.crawl();
    }
}
