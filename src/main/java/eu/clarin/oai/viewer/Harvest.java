/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.clarin.oai.viewer;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author menzowi
 */
public class Harvest {
    
    Path dir = null;
    Path overview = null;
    String reqsDirName = "oai-pmh";
    String fmtsDirName = "results";
    String type = null;
    
    public Harvest(Path dir) {
        this.dir = dir.toAbsolutePath().normalize();
    }
    
    public Path getDirectory() {
        return dir;
    }
    
    public void setRequestDirName(String reqsDirName) {
        this.reqsDirName = reqsDirName;
    }
    
    public void setFormatsDirName(String fmtsDirName) {
        this.fmtsDirName = fmtsDirName;
    }
    
    public void setOverview(Path overview) {
        this.overview = overview;
    }
    
    public void setType(String type) {
        this.type = type;
    }
    
    public boolean crawl() {
        System.out.format("BEGIN;%n");
        System.err.format("-- OAI Harvest: %s%n", dir);
        System.out.format("INSERT INTO harvest(location,type) VALUES ('%s', '%s');%n", dir, type);
        try {
            // first crawl the OAI-PMH responses
            OAIVisitor visitor = new OAIVisitor(this);
            visitor.setRequestsDirName(reqsDirName);
            Files.walkFileTree(dir.resolve(reqsDirName),visitor);
        } catch (IOException ex) {
            Logger.getLogger(Harvest.class.getName()).log(Level.SEVERE, null, ex);
            return false;
        }
        try {
            // second crawl the records
            RecordVisitor visitor = new RecordVisitor(this);
            Files.walkFileTree(dir.resolve(fmtsDirName),visitor);
        } catch (IOException ex) {
            Logger.getLogger(Harvest.class.getName()).log(Level.SEVERE, null, ex);
            return false;
        }
        System.out.format("COMMIT;%n");
        return true;
    }
    
}
