CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- TABLE: endpoint

CREATE TABLE public.endpoint (
    id integer NOT NULL,
    name text
);

ALTER TABLE public.endpoint OWNER TO oai;

-- - primary key

CREATE SEQUENCE public.endpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE public.endpoint_id_seq OWNER TO oai;

ALTER SEQUENCE public.endpoint_id_seq OWNED BY public.endpoint.id;

ALTER TABLE ONLY public.endpoint ALTER COLUMN id SET DEFAULT nextval('public.endpoint_id_seq'::regclass);

ALTER TABLE ONLY public.endpoint
    ADD CONSTRAINT key_endpoint PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY public.endpoint
    ADD CONSTRAINT unique_endpoint_name UNIQUE (name);

-- - index

CREATE INDEX idx_endpoint_name ON public.endpoint USING btree (name);

-- TABLE: harvest

CREATE TABLE public.harvest (
    id integer NOT NULL,
    "when" timestamp with time zone DEFAULT now(),
    location text,
    type text
);

ALTER TABLE public.harvest OWNER TO oai;

-- - primary key

CREATE SEQUENCE public.harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE public.harvest_id_seq OWNER TO oai;

ALTER SEQUENCE public.harvest_id_seq OWNED BY public.harvest.id;

ALTER TABLE ONLY public.harvest ALTER COLUMN id SET DEFAULT nextval('public.harvest_id_seq'::regclass);

ALTER TABLE ONLY public.harvest
    ADD CONSTRAINT harvest_key PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY public.harvest
    ADD CONSTRAINT unique_location UNIQUE (location);

-- TABLE: endpoint_harvest

CREATE TABLE public.endpoint_harvest (
    id integer NOT NULL,
    location text,
    harvest integer,
    endpoint integer,
    url text
);

ALTER TABLE public.endpoint_harvest OWNER TO oai;

-- - primary key

CREATE SEQUENCE public.endpoint_harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE public.endpoint_harvest_id_seq OWNER TO oai;

ALTER SEQUENCE public.endpoint_harvest_id_seq OWNED BY public.endpoint_harvest.id;

ALTER TABLE ONLY public.endpoint_harvest ALTER COLUMN id SET DEFAULT nextval('public.endpoint_harvest_id_seq'::regclass);

ALTER TABLE ONLY public.endpoint_harvest
    ADD CONSTRAINT key_endpoint_harvest PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY public.endpoint_harvest
    ADD CONSTRAINT unique_endpoint_harvest UNIQUE (harvest, location);

-- - foreign keys

CREATE INDEX fki_endpoint_harvest_endpoint ON public.endpoint_harvest USING btree (endpoint);

ALTER TABLE ONLY public.endpoint_harvest
    ADD CONSTRAINT endpoint_harvest_endpoint FOREIGN KEY (endpoint) REFERENCES public.endpoint(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE INDEX fki_endpoint_harvest_harvest ON public.endpoint_harvest USING btree (harvest);

ALTER TABLE ONLY public.endpoint_harvest
    ADD CONSTRAINT endpoint_harvest_harvest FOREIGN KEY (harvest) REFERENCES public.harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- TABLE: request

CREATE TABLE public.request (
    id integer NOT NULL,
    endpoint_harvest integer,
    location text,
    url text,
    "when" timestamp with time zone
);

ALTER TABLE public.request OWNER TO oai;

-- - primary key

CREATE SEQUENCE public.request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE public.request_id_seq OWNER TO oai;

ALTER SEQUENCE public.request_id_seq OWNED BY public.request.id;

ALTER TABLE ONLY public.request ALTER COLUMN id SET DEFAULT nextval('public.request_id_seq'::regclass);

ALTER TABLE ONLY public.request
    ADD CONSTRAINT key_request PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY public.request
    ADD CONSTRAINT unique_request UNIQUE (endpoint_harvest, location);

-- - foreign key

CREATE INDEX fki_request_endpoint_harvest ON public.request USING btree (endpoint_harvest);

ALTER TABLE ONLY public.request
    ADD CONSTRAINT request_endpoint_harvest FOREIGN KEY (endpoint_harvest) REFERENCES public.endpoint_harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- TABLE: record

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

-- - primary key

CREATE SEQUENCE public.record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE public.record_id_seq OWNER TO oai;

ALTER SEQUENCE public.record_id_seq OWNED BY public.record.id;

ALTER TABLE ONLY public.record ALTER COLUMN id SET DEFAULT nextval('public.record_id_seq'::regclass);

ALTER TABLE ONLY public.record
    ADD CONSTRAINT key_record PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY public.record
    ADD CONSTRAINT unique_identifier UNIQUE (identifier, "metadataPrefix", request);

ALTER TABLE ONLY public.record
    ADD CONSTRAINT unique_record_location UNIQUE (location, "metadataPrefix", request);

-- - foreign key

CREATE INDEX fki_record_request ON public.record USING btree (request);

ALTER TABLE ONLY public.record
    ADD CONSTRAINT record_request FOREIGN KEY (request) REFERENCES public.request(id);

-- - indices

CREATE INDEX idx_record_metadataPrefix ON public.record USING btree ("metadataPrefix");
CREATE INDEX idx_record_alfanum ON public.record USING btree (alfanum);
CREATE INDEX idx_record_endpoint_name ON public.record USING btree (endpoint_name);

-- VIEW: endpoint_info

CREATE MATERIALIZED VIEW public.mv_endpoint_info AS
 SELECT endpoint.id,
    COALESCE(requests.count, (0)::bigint) AS requests,
    COALESCE(records.count, (0)::bigint) AS records,
    harvest."when",
    harvest.type,
    harvest.id AS harvest,
    LOWER(endpoint.name) AS name_lower,
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

ALTER TABLE public.mv_endpoint_info OWNER TO oai;

CREATE VIEW public.endpoint_info AS
    SELECT * FROM public.mv_endpoint_info;

ALTER TABLE public.endpoint_info OWNER TO oai;

-- - index

CREATE INDEX idx_endpoint_info_name_lower ON public.mv_endpoint_info USING gin (name_lower gin_trgm_ops);

-- VIEW: endpoint_record

CREATE MATERIALIZED VIEW public.mv_endpoint_record AS
 SELECT record.id,
    LOWER(record.identifier) AS identifier_lower,
    record.identifier,
    record."metadataPrefix",
    record.location,
    request.id AS request,
    endpoint_harvest.endpoint,
    endpoint_harvest.harvest
   FROM ((public.record
     JOIN public.request ON ((record.request = request.id)))
     JOIN public.endpoint_harvest ON ((request.endpoint_harvest = endpoint_harvest.id)));

ALTER TABLE public.mv_endpoint_record OWNER TO oai;

CREATE VIEW public.endpoint_record AS
    SELECT * FROM public.mv_endpoint_record;

ALTER TABLE public.endpoint_record OWNER TO oai;

-- - index

CREATE INDEX idx_mv_endpoint_record_identifier_lower ON public.mv_endpoint_record USING gin (identifier_lower gin_trgm_ops);

-- VIEW: harvest_info

CREATE MATERIALIZED VIEW public.mv_harvest_info AS
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

ALTER TABLE public.mv_harvest_info OWNER TO oai;

CREATE VIEW public.harvest_info AS
    SELECT * FROM public.mv_harvest_info;

ALTER TABLE public.harvest_info OWNER TO oai;

-- FUNCTION: insert_endpoint
-- TODO: replace by UPSERT

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

-- FUNCTION: link_harvest_records

CREATE FUNCTION public.link_harvest_records(hid bigint) RETURNS void
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
    WHERE record.id = rr.id;
END;
$$;

ALTER FUNCTION public.link_harvest_records(hid bigint) OWNER TO oai;

-- FUNCTION: check_harvests

CREATE FUNCTION public.check_harvests() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    cnt bigint;
BEGIN
    cnt := (SELECT COUNT(*) FROM record WHERE identifier IS NULL) ;

    IF (cnt > 0) THEN
        RAISE WARNING '[%] record(s) without identifier!', cnt;
    END IF;
END;
$$;

ALTER FUNCTION public.check_harvests() OWNER TO oai;