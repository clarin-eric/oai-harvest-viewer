// OAI PostgRest API
var base = "${PGRST_OPENAPI_SERVER_PROXY_URI}"; //"http://localhost:3000/";
var harvPagesize = 5;
var endPagesize = 10;
var recPagesize = 1000;

// endpoints
var curationModule = "https://clarin.oeaw.ac.at/curate/#!ResultView/collection/";
var outDir         = "${OAI_OUTPUT_URI}"; //"http://localhost/oai-harvest-result/output";