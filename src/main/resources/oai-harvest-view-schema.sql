--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.9
-- Dumped by pg_dump version 10.3

-- Started on 2018-05-14 17:29:40 CEST

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 12655)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2470 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 198 (class 1255 OID 27546)
-- Name: insert_endpoint(character varying); Type: FUNCTION; Schema: public; Owner: oai
--

CREATE FUNCTION public.insert_endpoint(name character varying) RETURNS void
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

--
-- TOC entry 199 (class 1255 OID 27547)
-- Name: link_record(bigint); Type: FUNCTION; Schema: public; Owner: oai
--

CREATE FUNCTION public.link_record(hid bigint) RETURNS void
    LANGUAGE plpgsql
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


ALTER FUNCTION public.link_record(hid bigint) OWNER TO oai;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 185 (class 1259 OID 27548)
-- Name: endpoint; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE public.endpoint (
    id integer NOT NULL,
    name text
);


ALTER TABLE public.endpoint OWNER TO oai;

--
-- TOC entry 186 (class 1259 OID 27554)
-- Name: endpoint_harvest; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE public.endpoint_harvest (
    id integer NOT NULL,
    location text,
    harvest integer,
    endpoint integer,
    url text
);


ALTER TABLE public.endpoint_harvest OWNER TO oai;

--
-- TOC entry 187 (class 1259 OID 27560)
-- Name: endpoint_harvest_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE public.endpoint_harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.endpoint_harvest_id_seq OWNER TO oai;

--
-- TOC entry 2471 (class 0 OID 0)
-- Dependencies: 187
-- Name: endpoint_harvest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE public.endpoint_harvest_id_seq OWNED BY public.endpoint_harvest.id;


--
-- TOC entry 188 (class 1259 OID 27562)
-- Name: endpoint_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE public.endpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.endpoint_id_seq OWNER TO oai;

--
-- TOC entry 2472 (class 0 OID 0)
-- Dependencies: 188
-- Name: endpoint_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE public.endpoint_id_seq OWNED BY public.endpoint.id;


--
-- TOC entry 189 (class 1259 OID 27564)
-- Name: harvest; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE public.harvest (
    id integer NOT NULL,
    "when" timestamp with time zone DEFAULT now(),
    location text,
    type text
);


ALTER TABLE public.harvest OWNER TO oai;

--
-- TOC entry 190 (class 1259 OID 27571)
-- Name: record; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE public.record (
    id integer NOT NULL,
    identifier text,
    alfanum text,
    "metadataPrefix" text,
    location text,
    request integer,
    endpoint_name text
);


ALTER TABLE public.record OWNER TO oai;

--
-- TOC entry 191 (class 1259 OID 27577)
-- Name: request; Type: TABLE; Schema: public; Owner: oai
--

CREATE TABLE public.request (
    id integer NOT NULL,
    endpoint_harvest integer,
    location text,
    url text,
    "when" timestamp with time zone
);


ALTER TABLE public.request OWNER TO oai;

--
-- TOC entry 192 (class 1259 OID 27583)
-- Name: endpoint_info; Type: VIEW; Schema: public; Owner: oai
--

CREATE VIEW public.endpoint_info AS
 SELECT endpoint.id,
    COALESCE(requests.count, (0)::bigint) AS requests,
    COALESCE(records.count, (0)::bigint) AS records,
    harvest."when",
    harvest.type,
    harvest.id AS harvest,
    endpoint.name,
    endpoint_harvest.location,
    endpoint_harvest.url
   FROM ((((public.endpoint
     JOIN public.endpoint_harvest ON ((endpoint.id = endpoint_harvest.endpoint)))
     JOIN public.harvest ON ((harvest.id = endpoint_harvest.harvest)))
     LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
           FROM public.request
          GROUP BY request.endpoint_harvest) requests ON ((endpoint_harvest.id = requests.endpoint_harvest)))
     LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
           FROM (public.request
             JOIN public.record ON ((request.id = record.request)))
          WHERE (record."metadataPrefix" = 'cmdi'::text)
          GROUP BY request.endpoint_harvest) records ON ((endpoint_harvest.id = records.endpoint_harvest)))
  ORDER BY harvest."when" DESC;


ALTER TABLE public.endpoint_info OWNER TO oai;

--
-- TOC entry 193 (class 1259 OID 27588)
-- Name: endpoint_record; Type: VIEW; Schema: public; Owner: oai
--

CREATE VIEW public.endpoint_record WITH (security_barrier='false') AS
 SELECT record.id,
    record.identifier,
    record."metadataPrefix",
    record.location,
    request.id AS request,
    endpoint_harvest.endpoint,
    endpoint_harvest.harvest
   FROM ((public.record
     JOIN public.request ON ((record.request = request.id)))
     JOIN public.endpoint_harvest ON ((request.endpoint_harvest = endpoint_harvest.id)));


ALTER TABLE public.endpoint_record OWNER TO oai;

--
-- TOC entry 194 (class 1259 OID 27592)
-- Name: harvest_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE public.harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.harvest_id_seq OWNER TO oai;

--
-- TOC entry 2473 (class 0 OID 0)
-- Dependencies: 194
-- Name: harvest_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE public.harvest_id_seq OWNED BY public.harvest.id;


--
-- TOC entry 197 (class 1259 OID 27679)
-- Name: harvest_info; Type: VIEW; Schema: public; Owner: oai
--

CREATE VIEW public.harvest_info AS
 SELECT lh.id,
    count(endpoint_harvest.endpoint) AS endpoints,
    COALESCE(sum(requests.count), (0)::numeric) AS requests,
    COALESCE(sum(records.count), (0)::numeric) AS records,
    lh."when",
    lh.type
   FROM (((( SELECT h.id,
            h."when",
            h.location,
            h.type
           FROM (public.harvest h
             LEFT JOIN public.harvest n ON (((h.type = n.type) AND (h."when" < n."when"))))
          WHERE (n."when" IS NULL)) lh
     LEFT JOIN public.endpoint_harvest ON ((lh.id = endpoint_harvest.harvest)))
     LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
           FROM public.request
          GROUP BY request.endpoint_harvest) requests ON ((endpoint_harvest.id = requests.endpoint_harvest)))
     LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
           FROM (public.request
             JOIN public.record ON ((request.id = record.request)))
          WHERE (record."metadataPrefix" = 'oai'::text)
          GROUP BY request.endpoint_harvest) records ON ((endpoint_harvest.id = records.endpoint_harvest)))
  GROUP BY lh.id, lh.type, lh."when"
  ORDER BY lh."when" DESC;


ALTER TABLE public.harvest_info OWNER TO oai;

--
-- TOC entry 195 (class 1259 OID 27600)
-- Name: record_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE public.record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.record_id_seq OWNER TO oai;

--
-- TOC entry 2474 (class 0 OID 0)
-- Dependencies: 195
-- Name: record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE public.record_id_seq OWNED BY public.record.id;


--
-- TOC entry 196 (class 1259 OID 27602)
-- Name: request_id_seq; Type: SEQUENCE; Schema: public; Owner: oai
--

CREATE SEQUENCE public.request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.request_id_seq OWNER TO oai;

--
-- TOC entry 2475 (class 0 OID 0)
-- Dependencies: 196
-- Name: request_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: oai
--

ALTER SEQUENCE public.request_id_seq OWNED BY public.request.id;


--
-- TOC entry 2310 (class 2604 OID 27604)
-- Name: endpoint id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.endpoint ALTER COLUMN id SET DEFAULT nextval('public.endpoint_id_seq'::regclass);


--
-- TOC entry 2311 (class 2604 OID 27605)
-- Name: endpoint_harvest id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.endpoint_harvest ALTER COLUMN id SET DEFAULT nextval('public.endpoint_harvest_id_seq'::regclass);


--
-- TOC entry 2313 (class 2604 OID 27606)
-- Name: harvest id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.harvest ALTER COLUMN id SET DEFAULT nextval('public.harvest_id_seq'::regclass);


--
-- TOC entry 2314 (class 2604 OID 27607)
-- Name: record id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.record ALTER COLUMN id SET DEFAULT nextval('public.record_id_seq'::regclass);


--
-- TOC entry 2315 (class 2604 OID 27608)
-- Name: request id; Type: DEFAULT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.request ALTER COLUMN id SET DEFAULT nextval('public.request_id_seq'::regclass);


--
-- TOC entry 2326 (class 2606 OID 27610)
-- Name: harvest harvest_key; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.harvest
    ADD CONSTRAINT harvest_key PRIMARY KEY (id);


--
-- TOC entry 2317 (class 2606 OID 27612)
-- Name: endpoint key_endpoint; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.endpoint
    ADD CONSTRAINT key_endpoint PRIMARY KEY (id);


--
-- TOC entry 2322 (class 2606 OID 27614)
-- Name: endpoint_harvest key_endpoint_harvest; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.endpoint_harvest
    ADD CONSTRAINT key_endpoint_harvest PRIMARY KEY (id);


--
-- TOC entry 2330 (class 2606 OID 27616)
-- Name: record key_record; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.record
    ADD CONSTRAINT key_record PRIMARY KEY (id);


--
-- TOC entry 2336 (class 2606 OID 27618)
-- Name: request key_request; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT key_request PRIMARY KEY (id);


--
-- TOC entry 2324 (class 2606 OID 27620)
-- Name: endpoint_harvest unique_endpoint_harvest; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.endpoint_harvest
    ADD CONSTRAINT unique_endpoint_harvest UNIQUE (harvest, location);


--
-- TOC entry 2319 (class 2606 OID 27622)
-- Name: endpoint unique_endpoint_name; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.endpoint
    ADD CONSTRAINT unique_endpoint_name UNIQUE (name);


--
-- TOC entry 2332 (class 2606 OID 27624)
-- Name: record unique_identifier; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.record
    ADD CONSTRAINT unique_identifier UNIQUE (identifier, "metadataPrefix", request);


--
-- TOC entry 2328 (class 2606 OID 27627)
-- Name: harvest unique_location; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.harvest
    ADD CONSTRAINT unique_location UNIQUE (location);


--
-- TOC entry 2334 (class 2606 OID 27629)
-- Name: record unique_record_location; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.record
    ADD CONSTRAINT unique_record_location UNIQUE (location, "metadataPrefix", request);


--
-- TOC entry 2338 (class 2606 OID 27631)
-- Name: request unique_request; Type: CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT unique_request UNIQUE (endpoint_harvest, location);


--
-- TOC entry 2320 (class 1259 OID 27632)
-- Name: fki_endpoint_harvest_endpoint; Type: INDEX; Schema: public; Owner: oai
--

CREATE INDEX fki_endpoint_harvest_endpoint ON public.endpoint_harvest USING btree (endpoint);


--
-- TOC entry 2339 (class 2606 OID 27635)
-- Name: endpoint_harvest endpoint_harvest_endpoint; Type: FK CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.endpoint_harvest
    ADD CONSTRAINT endpoint_harvest_endpoint FOREIGN KEY (endpoint) REFERENCES public.endpoint(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2340 (class 2606 OID 27640)
-- Name: endpoint_harvest endpoint_harvest_harvest; Type: FK CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.endpoint_harvest
    ADD CONSTRAINT endpoint_harvest_harvest FOREIGN KEY (harvest) REFERENCES public.harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2341 (class 2606 OID 27645)
-- Name: record record_request; Type: FK CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.record
    ADD CONSTRAINT record_request FOREIGN KEY (request) REFERENCES public.request(id);


--
-- TOC entry 2342 (class 2606 OID 27650)
-- Name: request request_endpoint_harvest; Type: FK CONSTRAINT; Schema: public; Owner: oai
--

ALTER TABLE ONLY public.request
    ADD CONSTRAINT request_endpoint_harvest FOREIGN KEY (endpoint_harvest) REFERENCES public.endpoint_harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2018-05-14 17:29:41 CEST

--
-- PostgreSQL database dump complete
--

