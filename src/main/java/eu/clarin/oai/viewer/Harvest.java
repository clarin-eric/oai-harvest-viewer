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
    
    public Harvest(Path dir) {
        this.dir = dir.toAbsolutePath().normalize();
    }
    
    public Path getDirectory() {
        return dir;
    }
    
    public void setOverview(Path overview) {
        this.overview = overview;
    }
    
    public boolean crawl() {
        System.err.format("-- OAI Harvest: %s%n", dir);
        System.out.format("INSERT INTO harvest(location) VALUES ('%s');%n", dir);
        try {
            // first crawl the OAI-PMH responses
            OAIVisitor visitor = new OAIVisitor(this);
            Files.walkFileTree(dir.resolve("oai-pmh"),visitor);
        } catch (IOException ex) {
            Logger.getLogger(Harvest.class.getName()).log(Level.SEVERE, null, ex);
            return false;
        }
        try {
            // second crawl the records
            RecordVisitor visitor = new RecordVisitor(this);
            Files.walkFileTree(dir.resolve("results"),visitor);
        } catch (IOException ex) {
            Logger.getLogger(Harvest.class.getName()).log(Level.SEVERE, null, ex);
            return false;
        }
        return true;
    }
    
}
