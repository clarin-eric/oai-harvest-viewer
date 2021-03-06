/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package eu.clarin.oai.viewer;

import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.text.Normalizer;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;
import javax.xml.namespace.QName;
import org.codehaus.stax2.XMLInputFactory2;
import org.codehaus.stax2.XMLStreamReader2;
import org.codehaus.stax2.evt.XMLEvent2;
/**
 *
 * @author menzowi
 */
public class OAIRequest {
    
    static final String STATIC_NS = "http://www.openarchives.org/OAI/2.0/static-repository";
    static final String OAI_NS = "http://www.openarchives.org/OAI/2.0/";
    
    private enum State {
        START,OAI,REPOSITORY,IDENTIFY,BASEURL,RESPONSE,REQUEST,SCENARIO,RECORD,HEADER,IDENTIFIER,STOP,ERROR
    }

    protected Path request = null;
    protected Path location = null;
    protected int requests = 0;
    
    public OAIRequest(Path request,Path location,int requests) {
        this.request = request;
        this.location = location;
        this.requests = requests;
    }
    
    public void getRecords() {
        SimpleDateFormat xsd = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssX");
        xsd.setLenient(false); // be strict
        
        HashMap<String,String> records = new HashMap<>();
        String url = null;
        
        XMLInputFactory2 xmlif = null;
        InputStream in = null;
        XMLStreamReader2 xmlr = null;
        try {
            xmlif = (XMLInputFactory2) XMLInputFactory2.newInstance();
            xmlif.configureForConvenience();
            in = Files.newInputStream(request);
            xmlr = (XMLStreamReader2) xmlif.createXMLStreamReader(in);
            State state = State.START;
            int sdepth = 0;
            int depth = 0;
            String params = "";
            while (!state.equals(State.STOP) && !state.equals(State.ERROR) ) {
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
                                    state = State.OAI;
                                    sdepth = depth;
                                } else if (qn.getNamespaceURI().equals(STATIC_NS) && qn.getLocalPart().equals("Repository")) {
                                    state = State.REPOSITORY;
                                    sdepth = depth;
                                } else {
                                    System.err.println("!ERR: "+request+": no oai:OAI-PMH or static Repository root found!");
                                    state = State.ERROR;
                                }
                                break;
                            case XMLEvent2.END_DOCUMENT:
                                System.err.println("!ERR: "+request+": no XML content found!");
                                state = State.ERROR;
                                break;
                        }       
                        break;
                    case REPOSITORY:
                        //System.out.println("DBG: state[REPOSITORY]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(STATIC_NS) && (qn.getLocalPart().equals("ListRecords") || qn.getLocalPart().equals("GetRecord"))) {
                                    state = State.SCENARIO;
                                    sdepth = depth;
                                } else if (qn.getNamespaceURI().equals(STATIC_NS) && qn.getLocalPart().equals("Identify")) {
                                    state = State.IDENTIFY;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(STATIC_NS) && qn.getLocalPart().equals("Repository")) {
                                    state = State.STOP;
                                }
                                break;
                        }       
                        break;
                    case IDENTIFY:
                        //System.out.println("DBG: state[IDENTIFY]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("baseURL")) {
                                    state = State.BASEURL;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (qn.getNamespaceURI().equals(STATIC_NS) && qn.getLocalPart().equals("Identify")) {
                                    state = State.REPOSITORY;
                                }
                                break;
                        }       
                        break;
                    case BASEURL:
                        //System.out.println("DBG: state[BASEURL]");
                        switch (eventType) {
                            case XMLEvent2.CHARACTERS:
                                if (requests==0) {
                                    url = xmlr.getText();
                                    System.out.format("UPDATE endpoint_harvest SET \"url\" = '%s' WHERE id = currval('endpoint_harvest_id_seq'::regclass);%n", url);
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("baseURL")) {
                                    state = State.IDENTIFY;
                                }
                                break;
                        }       
                        break;
                    case OAI:
                        //System.out.println("DBG: state[OAI]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && (qn.getLocalPart().equals("responseDate"))) {
                                    state = State.RESPONSE;
                                    sdepth = depth;
                                } else if (qn.getNamespaceURI().equals(OAI_NS) && (qn.getLocalPart().equals("request"))) {
                                    state = State.REQUEST;
                                    params = "";
                                    for (int a=0;a<xmlr.getAttributeCount();a++) {
                                        params += (a>0?"&":"")+xmlr.getAttributeLocalName(a)+"="+xmlr.getAttributeValue(a);
                                    }
                                    sdepth = depth;
                                } else if (qn.getNamespaceURI().equals(OAI_NS) && (qn.getLocalPart().equals("ListRecords") || qn.getLocalPart().equals("GetRecord"))) {
                                    state = State.SCENARIO;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("OAI-PMH")) {
                                    if (requests == 0 && url != null)
                                        System.out.format("UPDATE endpoint_harvest SET \"url\" = '%s?verb=Identify' WHERE id = currval('endpoint_harvest_id_seq'::regclass);%n", url);
                                    state = State.STOP;
                                }
                                break;
                        }       
                        break;
                    case RESPONSE:
                        //System.out.println("DBG: state[RESPONSE]");
                        switch (eventType) {
                            case XMLEvent2.CHARACTERS:
                                String when = xmlr.getText();
                                try {
                                    Date w = xsd.parse(when);
                                    System.out.format("UPDATE request SET \"when\" = TIMESTAMP WITH TIME ZONE '%s' WHERE id = (select currval('request_id_seq'::regclass));%n", when);
                                } catch(ParseException x) {
                                    System.err.println("-- WRN: skipped faulty date["+when+"] in OAI Request["+request+"]");
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("responseDate")) {
                                    state = State.OAI;
                                    sdepth--;
                                }
                                break;
                        }       
                        break;
                    case REQUEST:
                        //System.out.println("DBG: state[REQUEST][sdepth="+sdepth+"][depth="+depth+"]");
                        switch (eventType) {
                            case XMLEvent2.CHARACTERS:
                                String uri = xmlr.getText();
                                if (url == null)
                                    url = uri;
                                if (!params.equals(""))
                                    uri += "?"+params;
                                System.out.format("UPDATE request SET url = '%s' WHERE id = (select currval('request_id_seq'::regclass));%n", uri);
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("request")) {
                                    state = State.OAI;
                                    sdepth--;
                                }
                                break;
                        }       
                        break;
                    case SCENARIO:
                        //System.out.println("DBG: state[SCENARIO]");                        
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("record")) {
                                    state = State.RECORD;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && (qn.getLocalPart().equals("ListRecords") || qn.getLocalPart().equals("GetRecord"))) {
                                    state = State.OAI;
                                    sdepth--;
                                } else if (depth==sdepth && qn.getNamespaceURI().equals(STATIC_NS) && (qn.getLocalPart().equals("ListRecords") || qn.getLocalPart().equals("GetRecord"))) {
                                    state = State.REPOSITORY;
                                    sdepth--;
                                }
                                if (state != State.SCENARIO) {
                                    if (!records.isEmpty()) {
                                        // identifier sometimes appear multiple times (possibly in other requests to the same endpoint),
                                        // the harvester will overwrite the files using this identifier so only the last one is maintained
                                        // reflected in SQL by doing an UPSERT overwritting only the location and request
                                        System.out.format("INSERT INTO record(identifier,alfanum,\"metadataPrefix\",location,request) VALUES %n  ");
                                        System.out.print(records.values().stream().collect(Collectors.joining(",\n  ")));
                                        System.out.format("%n ON CONFLICT ON CONSTRAINT unique_identifier DO UPDATE SET location=EXCLUDED.location,request=EXCLUDED.request;%n");
                                    }
                                }
                                break;
                        }       
                        break;
                    case RECORD:
                        //System.out.println("DBG: state[RECORD]");
                        switch (eventType) {
                            case XMLEvent2.START_ELEMENT:
                                if (qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("header")) {
                                    state = State.HEADER;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("record")) {
                                    state = State.SCENARIO;
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
                                    state = State.IDENTIFIER;
                                    sdepth = depth;
                                }
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("header")) {
                                    state = State.RECORD;
                                    sdepth--;
                                }
                                break;
                        }       
                        break;
                    case IDENTIFIER:
                        //System.out.println("DBG: state[IDENTIFIER]");
                        switch (eventType) {
                            case XMLEvent2.CHARACTERS:
                                String id = xmlr.getText().trim();
                                if (records.containsKey(id))
                                    System.err.format("-- duplicate! OAI Record: %s%n", id);
                                else
                                    System.err.format("-- OAI Record: %s%n", id);
                                String sql = String.format("('%s','%s','oai','%s#%s', currval('request_id_seq'::regclass))", id, toAlfaNum(id), this.location, id);
                                // the records map will only retain the info of the last record with a specific identifier
                                records.put(id,sql);
                                break;
                            case XMLEvent2.END_ELEMENT:
                                if (depth==sdepth && qn.getNamespaceURI().equals(OAI_NS) && qn.getLocalPart().equals("identifier")) {
                                    state = State.HEADER;
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
    
    protected String toAlfaNum(String name) {
	if (name == null)
	    return null;

	return Normalizer.normalize(name.trim(), Normalizer.Form.NFD)
		.replaceAll("\\p{M}", "").replaceAll("\\W+", "_");
    }
    
}
