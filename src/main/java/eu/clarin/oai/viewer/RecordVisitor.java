/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.clarin.oai.viewer;

import java.io.IOException;
import java.nio.file.FileVisitResult;
import static java.nio.file.FileVisitResult.CONTINUE;
import java.nio.file.Path;
import java.nio.file.SimpleFileVisitor;
import java.nio.file.attribute.BasicFileAttributes;

/**
 *
 * @author menzowi
 */
public class RecordVisitor extends SimpleFileVisitor<Path> {
    
    protected Harvest harvest = null;
    protected int records = 0;
    
    public RecordVisitor(Harvest harvest) {
        this.harvest = harvest;
    }
    
    @Override
    public FileVisitResult preVisitDirectory(Path dir,BasicFileAttributes attr) {
        System.err.format("-- Record Directory: %s%n", dir);
        
        records = 0;
        return CONTINUE;
    }

    @Override
    public FileVisitResult visitFile(Path file,BasicFileAttributes attr) {
        if (records == 0)
            System.out.format("INSERT INTO \"record\"(\"metadataPrefix\",location,endpoint_name,alfanum) VALUES %n");
        else
            System.out.format(",%n");

        System.err.format("-- Record: %s%n", file);

        Path loc = harvest.getDirectory().relativize(file);
        String id = file.getFileName().toString().replaceAll("\\.[^.]+$","");
        Path endpoint = file.getName(file.getNameCount()-2);
        Path prefix = file.getName(file.getNameCount()-3);
        System.out.format("  ('%s', '%s', '%s', '%s')", prefix, loc, endpoint, id.replaceAll("[^a-zA-Z0-9]","_"));

        records++;
        return CONTINUE;
    }

    @Override
    public FileVisitResult postVisitDirectory(Path dir,IOException ex) {
        if (ex!=null) {
            System.err.println(ex);
        } else {

            if (records>0)
                System.out.format(";%n");

        }
        return CONTINUE;
    }

    // If there is some error accessing
    // the file, let the user know.
    // If you don't override this method
    // and an error occurs, an IOException 
    // is thrown.
    @Override
    public FileVisitResult visitFileFailed(Path file,IOException ex) {
        System.err.println(ex);
        return CONTINUE;
    }
    
}
