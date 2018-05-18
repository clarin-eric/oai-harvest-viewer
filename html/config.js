// OAI DreamFactory API
//var base = "http://localhost/api/v2/oai/_table/";
var base = "${DF_API_URI}";
var key = "00551c93af07a0e2c22628ad6214b9ab250cdfa82a5be2fc04789920e27a7170";
var endPagesize = 10;
var recPagesize = 1000;

// endpoints
var curationModule = "https://clarin.oeaw.ac.at/curate/#!ResultView/collection/";
//var logDir         = "http://localhost/oai-harvest-result/log";
//var outDir         = "http://localhost/oai-harvest-result/output";
var outDir         = "${OAI_OUTPUT_URI}";