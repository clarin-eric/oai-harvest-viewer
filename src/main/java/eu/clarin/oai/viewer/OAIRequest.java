/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.clarin.oai.viewer;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.xml.namespace.QName;
import org.codehaus.stax2.XMLInputFactory2;
import org.codehaus.stax2.XMLStreamReader2;
import org.codehaus.stax2.evt.XMLEvent2;
/**
 *
 * @author menzowi
 */
public class OAIRequest {
    
    static final String OAI_NS = "http://www.openarchives.org/OAI/2.0/";
    
    static final int ERROR = -1;
    static final int START = 0;
    static final int OAI = 1;
    static final int SCENARIO = 2;
    static final int RECORD = 3;
    static final int HEADER = 4;
    static final int IDENTIFIER = 5;
    static final int STOP = 9;
    
    Path request = null;
    
    public OAIRequest(Path request) {
        this.request = request;
    }
    
    public void getRecords() {
        XMLInputFactory2 xmlif = null;
        InputStream in = null;
        XMLStreamReader2 xmlr = null;
        try {
            xmlif = (XMLInputFactory2) XMLInputFactory2.newInstance();
            xmlif.configureForConvenience();
            in = Files.newInputStream(request);
            xmlr = (XMLStreamReader2) xmlif.createXMLStreamReader(in);
            int state = START;
            int sdepth = 0;
            int depth = 0;
            while (state != STOP && state != ERROR) {
                int eventType = xmlr.getEventType();
                QName qn = null;
                switch (eventType) {
                    case XMLEvent2.START_ELEMENT:
                        qn = xmlr.getName();
                        depth++;
                        //System.out.println("DBG: start element["+qn+"]["+depth+"]");
                        break;
                    case XMLEvent2.END_ELEMENT:
                        qn = xmlr.getName();
                        //System.out.println("DBG: end element["+qn+"]["+depth+"]");
                        break;
                }
                switch (state) {
                    case START:
                        //System.out.println("DBG: state[START]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("OAI-PMH")) {
                                    state = OAI;
                                    sdepth = depth;
                                } else {
                                    System.err.println("!ERR: "+request+": no oai:OAI-PMH root found!");
                                    state = ERROR;
                                }
                                break;
                            case XMLEvent2.END_DOCUMENT:
                                System.err.println("!ERR: "+request+": no XML content found!");
                                state = ERROR;
                                break;
                        }       
                        break;
                    case OAI:
                        //System.out.println("DBG: state[OAI]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && (qn.getLocalPart().equals("ListRecords") || qn.getLocalPart().equals("GetRecord"))) {
                                    state = SCENARIO;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("OAI-PMH")) {
                                    state = STOP;
                                }
                                break;
                        }       
                        break;
                    case SCENARIO:
                        //System.out.println("DBG: state[SCENARIO]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("record")) {
                                    state = RECORD;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && (qn.getLocalPart().equals("ListRecords") || qn.getLocalPart().equals("GetRecord"))) {
                                    state = OAI;
                                    sdepth--;
                                }
                                break;
                        }       
                        break;
                    case RECORD:
                        //System.out.println("DBG: state[RECORD]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("header")) {
                                    state = HEADER;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("record")) {
                                    state = SCENARIO;
                                    sdepth--;
                                }
                                break;
                        }       
                        break;
                    case HEADER:
                        //System.out.println("DBG: state[HEADER]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("identifier") && sdepth+1==depth) {
                                    state = IDENTIFIER;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("header")) {
                                    state = RECORD;
                                    sdepth--;
                                }
                                break;
                        }       
                        break;
                    case IDENTIFIER:
                        //System.out.println("DBG: state[IDENTIFIER]");
                        switch (eventType) {
                            case XMLEvent2.CHARACTERS:
                                String id = xmlr.getText();
                                System.err.format("-- OAI Record: %s%n", id);
                                System.out.format("INSERT INTO record(identifier,\"metadataPrefix\",location,request) SELECT '%s','oai',location||'#'||'%s',id FROM request WHERE id = currval('request_id_seq'::regclass);%n",id,id);
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("identifier")) {
                                    state = HEADER;
                                    sdepth--;
                                }
                                break;
                        }
                        break;
                }
                switch (eventType) {
                    case XMLEvent2.END_ELEMENT:
                        depth--;
                        break;
                }
                eventType = xmlr.next();
            }
        } catch (Exception ex) {
            System.err.println("!ERR: "+request+": "+ex);
            ex.printStackTrace(System.err);
        } finally {
            try {
                xmlr.close();
                in.close();
            } catch (Exception ex) {
                System.err.println("!ERR: "+request+": "+ex);
                ex.printStackTrace(System.err);
            }
        }
    }
}
