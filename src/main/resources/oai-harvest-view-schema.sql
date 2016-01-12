--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.5
-- Dumped by pg_dump version 9.4.0
-- Started on 2015-11-27 19:42:28 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 182 (class 3079 OID 12123)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2326 (class 0 OID 0)
-- Dependencies: 182
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 195 (class 1255 OID 19044)
-- Name: insert_endpoint(character varying); Type: FUNCTION; Schema: public; Owner: menzowi
--

CREATE FUNCTION insert_endpoint(name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	BEGIN
	    INSERT INTO "endpoint"("name") VALUES (name);
	    RETURN;
	EXCEPTION WHEN unique_violation THEN
	    -- Do nothing
	END;
END;
$$;


ALTER FUNCTION public.insert_endpoint(name character varying) OWNER TO menzowi;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 172 (class 1259 OID 19045)
-- Name: endpoint; Type: TABLE; Schema: public; Owner: menzowi; Tablespace: 
--

CREATE TABLE endpoint (
    id integer NOT NULL,
    name text
);


ALTER TABLE endpoint OWNER TO menzowi;

--
-- TOC entry 173 (class 1259 OID 19051)
-- Name: endpoint_harvest; Type: TABLE; Schema: public; Owner: menzowi; Tablespace: 
--

CREATE TABLE "endpoint_harvest" (
    id integer NOT NULL,
    location text,
    harvest integer,
    endpoint integer
);


ALTER TABLE "endpoint_harvest" OWNER TO menzowi;

--
-- TOC entry 174 (class 1259 OID 19057)
-- Name: endpoint_harvest_id_seq; Type: SEQUENCE; Schema: public; Owner: menzowi
--

CREATE SEQUENCE "endpoint_harvest_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "endpoint_harvest_id_seq" OWNER TO menzowi;

--
-- TOC entry 2327 (class 0 OID 0)
-- Dependencies: 174
-- Name: endpoint_harvest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: menzowi
--

ALTER SEQUENCE "endpoint_harvest_id_seq" OWNED BY "endpoint_harvest".id;


--
-- TOC entry 175 (class 1259 OID 19059)
-- Name: endpoint_id_seq; Type: SEQUENCE; Schema: public; Owner: menzowi
--

CREATE SEQUENCE endpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE endpoint_id_seq OWNER TO menzowi;

--
-- TOC entry 2328 (class 0 OID 0)
-- Dependencies: 175
-- Name: endpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: menzowi
--

ALTER SEQUENCE endpoint_id_seq OWNED BY endpoint.id;


--
-- TOC entry 176 (class 1259 OID 19061)
-- Name: harvest; Type: TABLE; Schema: public; Owner: menzowi; Tablespace: 
--

CREATE TABLE harvest (
    id integer NOT NULL,
    "when" timestamp with time zone DEFAULT now(),
    location text
);


ALTER TABLE harvest OWNER TO menzowi;

--
-- TOC entry 177 (class 1259 OID 19068)
-- Name: harvest_id_seq; Type: SEQUENCE; Schema: public; Owner: menzowi
--

CREATE SEQUENCE harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE harvest_id_seq OWNER TO menzowi;

--
-- TOC entry 2329 (class 0 OID 0)
-- Dependencies: 177
-- Name: harvest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: menzowi
--

ALTER SEQUENCE harvest_id_seq OWNED BY harvest.id;


--
-- TOC entry 178 (class 1259 OID 19070)
-- Name: record; Type: TABLE; Schema: public; Owner: menzowi; Tablespace: 
--

CREATE TABLE record (
    id integer NOT NULL,
    identifier text,
    "metadataPrefix" text,
    location text,
    request integer
);


ALTER TABLE record OWNER TO menzowi;

--
-- TOC entry 179 (class 1259 OID 19076)
-- Name: record_id_seq; Type: SEQUENCE; Schema: public; Owner: menzowi
--

CREATE SEQUENCE record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE record_id_seq OWNER TO menzowi;

--
-- TOC entry 2330 (class 0 OID 0)
-- Dependencies: 179
-- Name: record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: menzowi
--

ALTER SEQUENCE record_id_seq OWNED BY record.id;


--
-- TOC entry 180 (class 1259 OID 19078)
-- Name: request; Type: TABLE; Schema: public; Owner: menzowi; Tablespace: 
--

CREATE TABLE request (
    id integer NOT NULL,
    "endpoint_harvest" integer,
    location text
);


ALTER TABLE request OWNER TO menzowi;

--
-- TOC entry 181 (class 1259 OID 19084)
-- Name: request_id_seq; Type: SEQUENCE; Schema: public; Owner: menzowi
--

CREATE SEQUENCE request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE request_id_seq OWNER TO menzowi;

--
-- TOC entry 2331 (class 0 OID 0)
-- Dependencies: 181
-- Name: request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: menzowi
--

ALTER SEQUENCE request_id_seq OWNED BY request.id;


--
-- TOC entry 2177 (class 2604 OID 19086)
-- Name: id; Type: DEFAULT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY endpoint ALTER COLUMN id SET DEFAULT nextval('endpoint_id_seq'::regclass);


--
-- TOC entry 2178 (class 2604 OID 19087)
-- Name: id; Type: DEFAULT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY "endpoint_harvest" ALTER COLUMN id SET DEFAULT nextval('"endpoint_harvest_id_seq"'::regclass);


--
-- TOC entry 2180 (class 2604 OID 19088)
-- Name: id; Type: DEFAULT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY harvest ALTER COLUMN id SET DEFAULT nextval('harvest_id_seq'::regclass);


--
-- TOC entry 2181 (class 2604 OID 19089)
-- Name: id; Type: DEFAULT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY record ALTER COLUMN id SET DEFAULT nextval('record_id_seq'::regclass);


--
-- TOC entry 2182 (class 2604 OID 19090)
-- Name: id; Type: DEFAULT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY request ALTER COLUMN id SET DEFAULT nextval('request_id_seq'::regclass);


--
-- TOC entry 2193 (class 2606 OID 19092)
-- Name: harvest_key; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY harvest
    ADD CONSTRAINT harvest_key PRIMARY KEY (id);


--
-- TOC entry 2184 (class 2606 OID 19094)
-- Name: key_endpoint; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY endpoint
    ADD CONSTRAINT key_endpoint PRIMARY KEY (id);


--
-- TOC entry 2189 (class 2606 OID 19096)
-- Name: key_endpoint_harvest; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY "endpoint_harvest"
    ADD CONSTRAINT "key_endpoint_harvest" PRIMARY KEY (id);


--
-- TOC entry 2197 (class 2606 OID 19098)
-- Name: key_record; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY record
    ADD CONSTRAINT key_record PRIMARY KEY (id);


--
-- TOC entry 2203 (class 2606 OID 19100)
-- Name: key_request; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY request
    ADD CONSTRAINT key_request PRIMARY KEY (id);


--
-- TOC entry 2191 (class 2606 OID 19102)
-- Name: unique_endpoint_harvest; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY "endpoint_harvest"
    ADD CONSTRAINT "unique_endpoint_harvest" UNIQUE (harvest, location);


--
-- TOC entry 2186 (class 2606 OID 19133)
-- Name: unique_endpoint_name; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY endpoint
    ADD CONSTRAINT unique_endpoint_name UNIQUE (name);


--
-- TOC entry 2199 (class 2606 OID 19104)
-- Name: unique_identifier; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY record
    ADD CONSTRAINT unique_identifier UNIQUE (identifier, "metadataPrefix", request);


--
-- TOC entry 2195 (class 2606 OID 19106)
-- Name: unique_location; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY harvest
    ADD CONSTRAINT unique_location UNIQUE (location);


--
-- TOC entry 2201 (class 2606 OID 19108)
-- Name: unique_record_location; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY record
    ADD CONSTRAINT unique_record_location UNIQUE (location, "metadataPrefix", request);


--
-- TOC entry 2205 (class 2606 OID 19110)
-- Name: unique_request; Type: CONSTRAINT; Schema: public; Owner: menzowi; Tablespace: 
--

ALTER TABLE ONLY request
    ADD CONSTRAINT unique_request UNIQUE ("endpoint_harvest", location);


--
-- TOC entry 2187 (class 1259 OID 19111)
-- Name: fki_endpoint_harvest_endpoint; Type: INDEX; Schema: public; Owner: menzowi; Tablespace: 
--

CREATE INDEX "fki_endpoint_harvest_endpoint" ON "endpoint_harvest" USING btree (endpoint);


--
-- TOC entry 2206 (class 2606 OID 19112)
-- Name: endpoint_harvest_endpoint; Type: FK CONSTRAINT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY "endpoint_harvest"
    ADD CONSTRAINT "endpoint_harvest_endpoint" FOREIGN KEY (endpoint) REFERENCES endpoint(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2207 (class 2606 OID 19117)
-- Name: endpoint_harvest_harvest; Type: FK CONSTRAINT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY "endpoint_harvest"
    ADD CONSTRAINT "endpoint_harvest_harvest" FOREIGN KEY (harvest) REFERENCES harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2208 (class 2606 OID 19122)
-- Name: record_request; Type: FK CONSTRAINT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY record
    ADD CONSTRAINT record_request FOREIGN KEY (request) REFERENCES request(id);


--
-- TOC entry 2209 (class 2606 OID 19127)
-- Name: request_endpoint_harvest; Type: FK CONSTRAINT; Schema: public; Owner: menzowi
--

ALTER TABLE ONLY request
    ADD CONSTRAINT "request_endpoint_harvest" FOREIGN KEY ("endpoint_harvest") REFERENCES "endpoint_harvest"(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2325 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: menzowi
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM menzowi;
GRANT ALL ON SCHEMA public TO menzowi;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2015-11-27 19:42:28 CET

--
-- PostgreSQL database dump complete
--

CREATE OR REPLACE VIEW
	endpoint_record
AS SELECT
	record.*,
	endpoint_harvest.endpoint
FROM
	record
JOIN
	request
ON
	record.request = request.id
JOIN
    endpoint_harvest
ON
    request.endpoint_harvest = endpoint_harvest.id;
;