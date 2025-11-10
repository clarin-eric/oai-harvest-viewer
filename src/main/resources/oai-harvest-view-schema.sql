CREATE SCHEMA api;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- TABLE: endpoint

CREATE TABLE api.endpoint (
    id bigint NOT NULL,
    name text
);

ALTER TABLE api.endpoint OWNER TO oai;

-- - primary key

CREATE SEQUENCE api.endpoint_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE api.endpoint_id_seq OWNER TO oai;

ALTER SEQUENCE api.endpoint_id_seq OWNED BY api.endpoint.id;

ALTER TABLE ONLY api.endpoint ALTER COLUMN id SET DEFAULT nextval('api.endpoint_id_seq'::regclass);

ALTER TABLE ONLY api.endpoint
    ADD CONSTRAINT key_endpoint PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY api.endpoint
    ADD CONSTRAINT unique_endpoint_name UNIQUE (name);

-- - index

CREATE INDEX idx_endpoint_name ON api.endpoint USING btree (name);

-- TABLE: harvest

CREATE TABLE api.harvest (
    id bigint NOT NULL,
    "when" timestamp with time zone DEFAULT now(),
    location text,
    type text
);

ALTER TABLE api.harvest OWNER TO oai;

-- - primary key

CREATE SEQUENCE api.harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE api.harvest_id_seq OWNER TO oai;

ALTER SEQUENCE api.harvest_id_seq OWNED BY api.harvest.id;

ALTER TABLE ONLY api.harvest ALTER COLUMN id SET DEFAULT nextval('api.harvest_id_seq'::regclass);

ALTER TABLE ONLY api.harvest
    ADD CONSTRAINT harvest_key PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY api.harvest
    ADD CONSTRAINT unique_location UNIQUE (location);

-- TABLE: endpoint_harvest

CREATE TABLE api.endpoint_harvest (
    id bigint NOT NULL,
    location text,
    harvest bigint,
    endpoint bigint,
    url text
);

ALTER TABLE api.endpoint_harvest OWNER TO oai;

-- - primary key

CREATE SEQUENCE api.endpoint_harvest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE api.endpoint_harvest_id_seq OWNER TO oai;

ALTER SEQUENCE api.endpoint_harvest_id_seq OWNED BY api.endpoint_harvest.id;

ALTER TABLE ONLY api.endpoint_harvest ALTER COLUMN id SET DEFAULT nextval('api.endpoint_harvest_id_seq'::regclass);

ALTER TABLE ONLY api.endpoint_harvest
    ADD CONSTRAINT key_endpoint_harvest PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY api.endpoint_harvest
    ADD CONSTRAINT unique_endpoint_harvest UNIQUE (harvest, location);

-- - foreign keys

CREATE INDEX fki_endpoint_harvest_endpoint ON api.endpoint_harvest USING btree (endpoint);

ALTER TABLE ONLY api.endpoint_harvest
    ADD CONSTRAINT endpoint_harvest_endpoint FOREIGN KEY (endpoint) REFERENCES api.endpoint(id) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE INDEX fki_endpoint_harvest_harvest ON api.endpoint_harvest USING btree (harvest);

ALTER TABLE ONLY api.endpoint_harvest
    ADD CONSTRAINT endpoint_harvest_harvest FOREIGN KEY (harvest) REFERENCES api.harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- TABLE: request

CREATE TABLE api.request (
    id bigint NOT NULL,
    endpoint_harvest bigint,
    location text,
    url text,
    "when" timestamp with time zone
);

ALTER TABLE api.request OWNER TO oai;

-- - primary key

CREATE SEQUENCE api.request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE api.request_id_seq OWNER TO oai;

ALTER SEQUENCE api.request_id_seq OWNED BY api.request.id;

ALTER TABLE ONLY api.request ALTER COLUMN id SET DEFAULT nextval('api.request_id_seq'::regclass);

ALTER TABLE ONLY api.request
    ADD CONSTRAINT key_request PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY api.request
    ADD CONSTRAINT unique_request UNIQUE (endpoint_harvest, location);

-- - foreign key

CREATE INDEX fki_request_endpoint_harvest ON api.request USING btree (endpoint_harvest);

ALTER TABLE ONLY api.request
    ADD CONSTRAINT request_endpoint_harvest FOREIGN KEY (endpoint_harvest) REFERENCES api.endpoint_harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- TABLE: record

CREATE TABLE api.record (
    id bigint NOT NULL,
    identifier text,
    alfanum text,
    "metadataPrefix" text,
    location text,
    request bigint,
    endpoint_name text
);

ALTER TABLE api.record OWNER TO oai;

-- - primary key

CREATE SEQUENCE api.record_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE api.record_id_seq OWNER TO oai;

ALTER SEQUENCE api.record_id_seq OWNED BY api.record.id;

ALTER TABLE ONLY api.record ALTER COLUMN id SET DEFAULT nextval('api.record_id_seq'::regclass);

ALTER TABLE ONLY api.record
    ADD CONSTRAINT key_record PRIMARY KEY (id);

-- - unique

ALTER TABLE ONLY api.record
    ADD CONSTRAINT unique_identifier UNIQUE (identifier, "metadataPrefix", request);

ALTER TABLE ONLY api.record
    ADD CONSTRAINT unique_record_location UNIQUE (location, "metadataPrefix", request);

-- - foreign key

CREATE INDEX fki_record_request ON api.record USING btree (request);

ALTER TABLE ONLY api.record
    ADD CONSTRAINT record_request FOREIGN KEY (request) REFERENCES api.request(id) ON DELETE CASCADE;

-- - indices

CREATE INDEX idx_record_metadataPrefix ON api.record USING btree ("metadataPrefix");
CREATE INDEX idx_record_alfanum ON api.record USING btree (alfanum);
CREATE INDEX idx_record_endpoint_name ON api.record USING btree (endpoint_name);

-- Name:  table_endpoint_info

CREATE TABLE api.table_endpoint_info (
    id bigint,
    endpoint_id bigint,
    requests bigint,
    records bigint,
    harvest_id bigint
);

ALTER TABLE api.table_endpoint_info OWNER TO oai;

-- - primary key

CREATE SEQUENCE api.table_endpoint_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE api.table_endpoint_info_id_seq OWNER TO oai;

ALTER SEQUENCE api.table_endpoint_info_id_seq OWNED BY api.table_endpoint_info.id;

ALTER TABLE ONLY api.table_endpoint_info ALTER COLUMN id SET DEFAULT nextval('api.table_endpoint_info_id_seq'::regclass);

ALTER TABLE ONLY api.table_endpoint_info
    ADD CONSTRAINT key_table_endpoint_info PRIMARY KEY (id);

-- - foreign key

CREATE INDEX fki_endpoint_info ON api.table_endpoint_info USING btree (endpoint_id);

ALTER TABLE ONLY api.table_endpoint_info
    ADD CONSTRAINT endpoint_table_endpoint_info FOREIGN KEY (endpoint_id) REFERENCES api.endpoint(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- - index
-- Do we need this?
-- CREATE INDEX idx_endpoint_info_name_lower ON api.mv_endpoint_info USING gin (name_lower gin_trgm_ops);

-- VIEW: mv_endpoint_info

CREATE MATERIALIZED VIEW api.mv_endpoint_info AS
    SELECT
      table_endpoint_info.id,
      requests,
      records,
      harvest_id,
      harvest."when",
      harvest.type,
      endpoint_id,
      LOWER(endpoint.name) AS name_lower,
      endpoint.name,
      endpoint_harvest.location,
      endpoint_harvest.url
    FROM api.table_endpoint_info
    JOIN api.endpoint ON (endpoint.id = endpoint_id)
    JOIN api.harvest ON (harvest.id = harvest_id)
    JOIN api.endpoint_harvest ON (endpoint_harvest.harvest = harvest_id and endpoint_harvest.endpoint = endpoint.id)
    ;

-- Name: table_harvest_info

CREATE TABLE api.table_harvest_info (
    id bigint,
    harvest_id bigint,
    endpoints numeric,
    requests numeric,
    records numeric,
    "when" timestamp with time zone,
    type text
);

ALTER TABLE api.table_harvest_info OWNER TO oai;

-- - primary key

CREATE SEQUENCE api.table_harvest_info_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE api.table_harvest_info_id_seq OWNER TO oai;

ALTER SEQUENCE api.table_harvest_info_id_seq OWNED BY api.table_harvest_info.id;

ALTER TABLE ONLY api.table_harvest_info ALTER COLUMN id SET DEFAULT nextval('api.table_harvest_info_id_seq'::regclass);

ALTER TABLE ONLY api.table_harvest_info
    ADD CONSTRAINT key_table_harvest_info PRIMARY KEY (id);

-- - foreign key

CREATE INDEX fki_table_harvest_info ON api.table_harvest_info USING btree (harvest_id);

ALTER TABLE ONLY api.table_harvest_info
    ADD CONSTRAINT harvest_table_harvest_info FOREIGN KEY (harvest_id) REFERENCES api.harvest(id) ON UPDATE CASCADE ON DELETE CASCADE;

-- VIEW: mv_harvest_info

CREATE MATERIALIZED VIEW api.mv_harvest_info AS
    SELECT
      table_endpoint_info.harvest_id,
      count(mv_endpoint_info.endpoint_id) AS endpoints,
      SUM(mv_endpoint_info.requests) as requests,
      SUM(mv_endpoint_info.records) as rcords,
      harvest."when",
      harvest.type
    FROM api.table_endpoint_info
    JOIN api.harvest ON (harvest.id = table_endpoint_info.harvest_id)
    JOIN api.mv_endpoint_info ON mv_endpoint_info.harvest_id = table_endpoint_info.harvest_id
    GROUP BY api.table_endpoint_info.harvest_id, harvest."when", harvest.type ;

-- VIEW: endpoint_record

CREATE MATERIALIZED VIEW api.mv_endpoint_record AS
 SELECT record.id,
    LOWER(record.identifier) AS identifier_lower,
    record.identifier,
    record."metadataPrefix",
    record.location,
    request.id AS request,
    endpoint_harvest.endpoint,
    endpoint_harvest.harvest
    FROM ((api.record
        JOIN api.request ON ((record.request = request.id))) 
        JOIN api.endpoint_harvest ON ((request.endpoint_harvest = endpoint_harvest.id))
        JOIN api.harvest ON ((endpoint_harvest.harvest = harvest.id))
        JOIN api.table_harvest_info ON ((harvest.id = table_harvest_info.id)));
		
ALTER TABLE api.mv_endpoint_record OWNER TO oai;

CREATE VIEW api.endpoint_record AS
    SELECT * FROM api.mv_endpoint_record;

ALTER TABLE api.endpoint_record OWNER TO oai;

-- - index

CREATE INDEX idx_mv_endpoint_record_identifier_lower ON api.mv_endpoint_record USING gin (identifier_lower gin_trgm_ops);

-- FUNCTION: insert_endpoint
-- TODO: replace by UPSERT

CREATE FUNCTION api.insert_endpoint(name character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	BEGIN
	    INSERT INTO api."endpoint"("name") VALUES (name);
	    RETURN;
	EXCEPTION WHEN unique_violation THEN
	    -- Do nothing
	END;
END;
$$;

ALTER FUNCTION api.insert_endpoint(name character varying) OWNER TO oai;

-- FUNCTION: link_harvest_records

CREATE FUNCTION api.link_harvest_records(hid bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE api.record 
    SET identifier = rr.identifier, request = rr.request
    FROM (
      SELECT r.id, oai.identifier, oai.request
      FROM api.record AS r, api.record AS oai, api.request, api.endpoint_harvest, api.endpoint
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

ALTER FUNCTION api.link_harvest_records(hid bigint) OWNER TO oai;

-- FUNCTION: check_harvests

CREATE FUNCTION api.check_harvests() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    cnt bigint;
BEGIN
    cnt := (SELECT COUNT(*) FROM api.record WHERE identifier IS NULL) ;

    IF (cnt > 0) THEN
        RAISE WARNING '[%] record(s) without identifier!', cnt;
    END IF;
END;
$$;

ALTER FUNCTION api.check_harvests() OWNER TO oai;


-- Function: insert latest harvest into table_endpoint_info

CREATE FUNCTION api.insert_endpoint_info(hid bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO api.table_endpoint_info (endpoint_id, requests, records, harvest_id)
    SELECT
      endpoint.id,
      COALESCE(requests.count, (0)::bigint) AS requests,
      COALESCE(records.count, (0)::bigint) AS records,
      harvest.id AS harvest_id
    FROM api.endpoint_harvest
    JOIN api.endpoint ON (endpoint.id = endpoint_harvest.endpoint)
    JOIN api.harvest ON (harvest.id = endpoint_harvest.harvest)
    LEFT JOIN ( -- get # requests
      SELECT
        request.endpoint_harvest,
        count(*) AS count
      FROM api.request
      GROUP BY request.endpoint_harvest
    ) requests ON (requests.endpoint_harvest = endpoint_harvest.id)
    LEFT JOIN ( -- get # records
      SELECT
        request.endpoint_harvest,
        count(*) AS count
      FROM api.request
      JOIN api.record ON (record.request = request.id)
      WHERE (record."metadataPrefix" = 'cmdi'::text)
      GROUP BY request.endpoint_harvest
    ) records ON (records.endpoint_harvest = endpoint_harvest.id)
    WHERE endpoint_harvest.harvest=hid;
END;
$$;

ALTER FUNCTION api.insert_endpoint_info(hid bigint) OWNER TO oai;

-- Function: insert latest harvest into harvest_info

CREATE FUNCTION api.insert_harvest_info(hid bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO api.table_harvest_info (harvest_id, endpoints, requests, records, "when", type)
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
          FROM (api.harvest h
              LEFT JOIN api.harvest n ON (((h.type = n.type) AND (h."when" < n."when"))))
          WHERE (n."when" IS NULL)) lh
    LEFT JOIN api.endpoint_harvest ON ((lh.id = hid)))
    LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
          FROM api.request
          GROUP BY request.endpoint_harvest) requests ON ((endpoint_harvest.id = requests.endpoint_harvest)))
    LEFT JOIN ( SELECT request.endpoint_harvest,
            count(*) AS count
          FROM (api.request
            JOIN api.record ON ((request.id = record.request)))
          WHERE (record."metadataPrefix" = 'oai'::text)
          GROUP BY request.endpoint_harvest) records ON ((endpoint_harvest.id = records.endpoint_harvest)))
    GROUP BY lh.id, lh.type, lh."when"
    ORDER BY lh."when" DESC LIMIT 1;
END;
$$;

ALTER FUNCTION api.insert_harvest_info(hid bigint) OWNER TO oai;

-- FUNCTION: delete all the requests and records from previuous harvests

CREATE FUNCTION api.delete_old_data(dtype text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM api.request where endpoint_harvest IN (
      WITH last AS
        ( SELECT id FROM api. harvest WHERE harvest.type=type ORDER BY harvest.when DESC LIMIT 1)
        SELECT id FROM api. endpoint_harvest WHERE harvest NOT IN (select * from last)
);
END;
$$;

ALTER FUNCTION api.delete_old_data(dtype text) OWNER TO oai;

-- setup postgrest access
create role view_api nologin;

grant usage on schema api to view_api;
grant select on api.record to view_api;
grant select on api.request to view_api;
grant select on api.endpoint to view_api;
grant select on api.endpoint_harvest to view_api;
grant select on api.harvest to view_api;
grant select on api.mv_endpoint_record  to view_api;
grant select on api.mv_harvest_info to view_api;

grant view_api to oai;
