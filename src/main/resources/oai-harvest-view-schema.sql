--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

-- Started on 2017-03-08 13:08:44 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 12655)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2463 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- TOC entry 197 (class 1255 OID 16610)
-- Name: insert_endpoint(character varying); Type: FUNCTION; Schema: public; Owner: oai
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

ALTER FUNCTION public.insert_endpoint(name character varying) OWNER TO oai;

CREATE OR REPLACE FUNCTION public.link_record(hid bigint) RETURNS void
    LANGUAGE 'plpgsql'
    AS $$

BEGIN
    UPDATE record 
    SET identifier = rr.identifier, request = rr.request
    FROM (
      SELECT r.id, oai.identifier, oai.request
      FROM record AS r, record AS oai, request, endpoint_harvest, endpoint
      WHERE r.request ISNULL
        AND oai.alfanum = r.alfanum
        AND oai."metadataPrefix" = 'oai'
        AND oai.request = request.id
        AND request.endpoint_harvest = endpoint_harvest.id
        AND endpoint_harvest.endpoint = endpoint.id
        AND endpoint.name = r.endpoint_name
        AND endpoint_harvest.harvest = hid
    ) AS rr
    WHERE record.id = rr.id;END;

$$;

ALTER FUNCTION public.link_record(bigint) OWNER TO oai;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 185 (class 1259 OID 16611)
-- Name: endpoint; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE endpoint (
    id integer NOT NULL,
    name text
);


ALTER TABLE endpoint OWNER TO oai;

--
-- TOC entry 186 (class 1259 OID 16617)
-- Name: endpoint_harvest; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE endpoint_harvest (
    id integer NOT NULL,
    location text,
    harvest integer,
    endpoint integer,
    url text
);


ALTER TABLE endpoint_harvest OWNER TO oai;

--
-- TOC entry 187 (class 1259 OID 16623)
-- Name: endpoint_harvest_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE endpoint_harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE endpoint_harvest_id_seq OWNER TO oai;

--
-- TOC entry 2464 (class 0 OID 0)
-- Dependencies: 187
-- Name: endpoint_harvest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE endpoint_harvest_id_seq OWNED BY endpoint_harvest.id;


--
-- TOC entry 188 (class 1259 OID 16625)
-- Name: endpoint_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE endpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE endpoint_id_seq OWNER TO oai;

--
-- TOC entry 2465 (class 0 OID 0)
-- Dependencies: 188
-- Name: endpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE endpoint_id_seq OWNED BY endpoint.id;


--
-- TOC entry 189 (class 1259 OID 16627)
-- Name: harvest; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE harvest (
    id integer NOT NULL,
    "when" timestamp with time zone DEFAULT now(),
    location text,
    "type" text
);


ALTER TABLE harvest OWNER TO oai;

--
-- TOC entry 191 (class 1259 OID 16636)
-- Name: record; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE record (
    id integer NOT NULL,
    identifier text,
    alfanum text,
    "metadataPrefix" text,
    location text,
    request integer,
    endpoint_name text
);


ALTER TABLE record OWNER TO oai;

--
-- TOC entry 193 (class 1259 OID 16644)
-- Name: request; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE request (
    id integer NOT NULL,
    endpoint_harvest integer,
    location text,
    url text,
    "when" TIMESTAMP WITH TIME ZONE
);


ALTER TABLE request OWNER TO oai;

--
-- TOC entry 196 (class 1259 OID 16711)
-- Name: endpoint_info; Type: VIEW; Schema: public; Owner: oai
--

CREATE VIEW endpoint_info AS
 SELECT endpoint.id,
    COALESCE(requests.count, (0)::bigint) AS requests,
    COALESCE(records.count, (0)::bigint) AS records,
    endpoint_harvest.location,
    endpoint_harvest.url,
    harvest.id AS harvest,
    harvest."when",
    harvest."type"
   FROM ((((endpoint
     JOIN endpoint_harvest ON ((endpoint.id = endpoint_harvest.endpoint)))
     JOIN harvest ON ((harvest.id = endpoint_harvest.harvest)))
     LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
          FROM request
          GROUP BY request.endpoint_harvest) requests ON ((endpoint_harvest.id = requests.endpoint_harvest)))
     LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
          FROM (request
          JOIN record ON ((request.id = record.request)))
﻿         WHERE record."metadataPrefix" = 'cmdi'
          GROUP BY request.endpoint_harvest) records ON ((endpoint_harvest.id = records.endpoint_harvest)))
  ORDER BY harvest."when" DESC;


ALTER TABLE endpoint_info OWNER TO oai;

--
-- TOC entry 195 (class 1259 OID 16700)
-- Name: endpoint_record; Type: VIEW; Schema: public; Owner: oai
--

CREATE VIEW endpoint_record WITH (security_barrier='false') AS
 SELECT record.id,
    record.identifier,
    record."metadataPrefix",
    record.location,
    request.id AS request,
    endpoint_harvest.endpoint,
    endpoint_harvest.harvest
   FROM ((record
     JOIN request ON ((record.request = request.id)))
     JOIN endpoint_harvest ON ((request.endpoint_harvest = endpoint_harvest.id)));


ALTER TABLE endpoint_record OWNER TO oai;

CREATE VIEW harvest_info AS
 SELECT harvest.id,
    COUNT(endpoint_harvest.endpoint) AS endpoints,
    SUM(requests.count) AS requests,
    SUM(records.count) AS records,
    harvest."when",
    harvest.type
   FROM harvest
     JOIN endpoint_harvest ON harvest.id = endpoint_harvest.harvest
     LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
           FROM request
          GROUP BY request.endpoint_harvest) requests ON endpoint_harvest.id = requests.endpoint_harvest
     LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
           FROM request
             JOIN record ON request.id = record.request
           WHERE record.metadataPrefix='oai'
          GROUP BY request.endpoint_harvest) records ON endpoint_harvest.id = records.endpoint_harvest
  GROUP BY harvest.id
  ORDER BY harvest."when" DESC;

ALTER TABLE harvest_info OWNER TO oai;



--
-- TOC entry 190 (class 1259 OID 16634)
-- Name: harvest_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE harvest_id_seq OWNER TO oai;

--
-- TOC entry 2466 (class 0 OID 0)
-- Dependencies: 190
-- Name: harvest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE harvest_id_seq OWNED BY harvest.id;


--
-- TOC entry 192 (class 1259 OID 16642)
-- Name: record_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE record_id_seq OWNER TO oai;

--
-- TOC entry 2467 (class 0 OID 0)
-- Dependencies: 192
-- Name: record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE record_id_seq OWNED BY record.id;


--
-- TOC entry 194 (class 1259 OID 16650)
-- Name: request_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE request_id_seq OWNER TO oai;

--
-- TOC entry 2468 (class 0 OID 0)
-- Dependencies: 194
-- Name: request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE request_id_seq OWNED BY request.id;


--
-- TOC entry 2305 (class 2604 OID 16652)
-- Name: endpoint id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY endpoint ALTER COLUMN id SET DEFAULT nextval('endpoint_id_seq'::regclass);


--
-- TOC entry 2306 (class 2604 OID 16653)
-- Name: endpoint_harvest id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY endpoint_harvest ALTER COLUMN id SET DEFAULT nextval('endpoint_harvest_id_seq'::regclass);


--
-- TOC entry 2308 (class 2604 OID 16654)
-- Name: harvest id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY harvest ALTER COLUMN id SET DEFAULT nextval('harvest_id_seq'::regclass);


--
-- TOC entry 2309 (class 2604 OID 16655)
-- Name: record id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY record ALTER COLUMN id SET DEFAULT nextval('record_id_seq'::regclass);


--
-- TOC entry 2310 (class 2604 OID 16656)
-- Name: request id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY request ALTER COLUMN id SET DEFAULT nextval('request_id_seq'::regclass);


--
-- TOC entry 2321 (class 2606 OID 16658)
-- Name: harvest harvest_key; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY harvest
    ADD CONSTRAINT harvest_key PRIMARY KEY (id);


--
-- TOC entry 2312 (class 2606 OID 16660)
-- Name: endpoint key_endpoint; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY endpoint
    ADD CONSTRAINT key_endpoint PRIMARY KEY (id);


--
-- TOC entry 2317 (class 2606 OID 16662)
-- Name: endpoint_harvest key_endpoint_harvest; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY endpoint_harvest
    ADD CONSTRAINT key_endpoint_harvest PRIMARY KEY (id);


--
-- TOC entry 2325 (class 2606 OID 16664)
-- Name: record key_record; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY record
    ADD CONSTRAINT key_record PRIMARY KEY (id);


--
-- TOC entry 2331 (class 2606 OID 16666)
-- Name: request key_request; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY request
    ADD CONSTRAINT key_request PRIMARY KEY (id);


--
-- TOC entry 2319 (class 2606 OID 16668)
-- Name: endpoint_harvest unique_endpoint_harvest; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY endpoint_harvest
    ADD CONSTRAINT unique_endpoint_harvest UNIQUE (harvest, location);


--
-- TOC entry 2314 (class 2606 OID 16670)
-- Name: endpoint unique_endpoint_name; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY endpoint
    ADD CONSTRAINT unique_endpoint_name UNIQUE (name);


--
-- TOC entry 2327 (class 2606 OID 16672)
-- Name: record unique_identifier; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY record
    ADD CONSTRAINT unique_identifier UNIQUE (identifier, "metadataPrefix", request);


--
-- TOC entry 2323 (class 2606 OID 16674)
-- Name: harvest unique_location; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY harvest
    ADD CONSTRAINT unique_location UNIQUE (location);


--
-- TOC entry 2329 (class 2606 OID 16676)
-- Name: record unique_record_location; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY record
    ADD CONSTRAINT unique_record_location UNIQUE (location, "metadataPrefix", request);


--
-- TOC entry 2333 (class 2606 OID 16678)
-- Name: request unique_request; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY request
    ADD CONSTRAINT unique_request UNIQUE (endpoint_harvest, location);


--
-- TOC entry 2315 (class 1259 OID 16679)
-- Name: fki_endpoint_harvest_endpoint; Type: INDEX; Schema: public; Owner: oai
--

CREATE INDEX fki_endpoint_harvest_endpoint ON endpoint_harvest USING btree (endpoint);


--
-- TOC entry 2334 (class 2606 OID 16680)
-- Name: endpoint_harvest endpoint_harvest_endpoint; Type: FK CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY endpoint_harvest
    ADD CONSTRAINT endpoint_harvest_endpoint FOREIGN KEY (endpoint) REFERENCES endpoint(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2335 (class 2606 OID 16685)
-- Name: endpoint_harvest endpoint_harvest_harvest; Type: FK CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY endpoint_harvest
    ADD CONSTRAINT endpoint_harvest_harvest FOREIGN KEY (harvest) REFERENCES harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2336 (class 2606 OID 16690)
-- Name: record record_request; Type: FK CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY record
    ADD CONSTRAINT record_request FOREIGN KEY (request) REFERENCES request(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2337 (class 2606 OID 16695)
-- Name: request request_endpoint_harvest; Type: FK CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY request
    ADD CONSTRAINT request_endpoint_harvest FOREIGN KEY (endpoint_harvest) REFERENCES endpoint_harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2017-03-08 13:08:44 CET

--
-- PostgreSQL database dump complete
--

