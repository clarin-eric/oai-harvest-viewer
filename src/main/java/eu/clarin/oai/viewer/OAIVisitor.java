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
public class OAIVisitor extends SimpleFileVisitor<Path> {
    
    protected String reqsDirName = "oai-pmh";
    protected Harvest harvest = null;
    
    public OAIVisitor(Harvest harvest) {
        this.harvest = harvest;
    }
    
    public void setRequestsDirName(String reqsDirName) {
        this.reqsDirName = reqsDirName;
    }
    
    @Override
    public FileVisitResult preVisitDirectory(Path dir,BasicFileAttributes attr) {
        System.err.format("-- OAI Endpoint: %s%n", dir);
        Path loc = harvest.getDirectory().relativize(dir);
        Path name = dir.getName(dir.getNameCount()-1);
        if (!name.toString().equals(this.reqsDirName)) {
            System.out.format("SELECT insert_endpoint('%s');%n",name);
            System.out.format("INSERT INTO endpoint_harvest(harvest,endpoint,location) SELECT currval('harvest_id_seq'::regclass),endpoint.id,'%s' FROM endpoint WHERE endpoint.name = '%s';%n",loc,name);
        }
        return CONTINUE;
    }

    @Override
    public FileVisitResult visitFile(Path file,BasicFileAttributes attr) {
        System.err.format("-- OAI Request: %s%n", file);
        Path loc = harvest.getDirectory().relativize(file);
        System.out.format("INSERT INTO request(endpoint_harvest,location) VALUES(currval('endpoint_harvest_id_seq'::regclass),'%s');%n",loc);
        OAIRequest request = new OAIRequest(file,loc);
        request.getRecords();
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
