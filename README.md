# OAI harvest viewer
A web application to inspect an OAI harvest made by the [OAI harvest manager](https://github.com/clarin-eric/oai-harvest-viewer.git).

## Implementation

* [CLI](src/main/java/eu/clarin/oai/viewer/Main.java) to index a harvest into a PostgreSQL database
* [DreamFactory](https://www.dreamfactory.com/) to provide a REST API to the database
* [React](https://facebook.github.io/react/index.html)-based [web page](html/index.html) to interact with the REST API

## TODO

* Add space for statistics/properties to the database
* Let CLI interact directy with PostgreSQL instead of using psql
* Docker setup for the DreamFactory setup
* More work on the React-based web page ...