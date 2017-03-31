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
    
    public RecordVisitor(Harvest harvest) {
        this.harvest = harvest;
    }
    
    @Override
    public FileVisitResult visitFile(Path file,BasicFileAttributes attr) {
        Path loc = harvest.getDirectory().relativize(file);
        String id = file.getFileName().toString().replaceAll("\\.[^.]+$","");
        Path endpoint = file.getName(file.getNameCount()-2);
        Path prefix = file.getName(file.getNameCount()-3);
        System.err.format("-- Record: %s%n", file);
        System.out.format(
                "INSERT INTO \"record\"(identifier,\"metadataPrefix\",location,request)%n" +
                "     SELECT \"record\".identifier,'%s','%s',\"record\".request%n" +
                "       FROM \"record\", request, endpoint_harvest, endpoint%n" +
                "      WHERE (alfanum = '%s')%n" +
                "        AND \"record\".request = request.id%n" +
                "        AND request.endpoint_harvest = endpoint_harvest.id%n" +
                "        AND endpoint_harvest.endpoint = endpoint.id%n" +
                "        AND endpoint.name= '%s';%n",
            prefix, loc, id.replaceAll("[^a-zA-Z0-9]","_"), endpoint);
        return CONTINUE;
    }
    
    @Override
    public FileVisitResult preVisitDirectory(Path dir,BasicFileAttributes attr) {
        System.err.format("-- Record Directory: %s%n", dir);
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
