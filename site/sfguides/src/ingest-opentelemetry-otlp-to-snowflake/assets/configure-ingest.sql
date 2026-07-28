-- Copyright 2026 Snowflake Inc.
-- SPDX-License-Identifier: Apache-2.0

-- =============================================================================
-- Variable Definitions
-- =============================================================================
-- ---- You MUST change the following values -----------------------------------
-- Ingest network policy allowlist. Change to a comma-separated list of 
-- public IPs and/or CIDR(s) that are allowed to ingest telemetry.
SET QS_INGEST_IP_ALLOWLIST = '192.0.2.0'; -- <<< CHANGE THIS!

-- ---- You may optionally change the following values -------------------------
-- DB, Schema, and Event Tables
SET QS_DB      = 'OTLP_INGEST_QS';
SET QS_SCHEMA  = 'TELEMETRY';
SET QS_ET_L    = 'LOGS';
SET QS_ET_M    = 'METRICS';
SET QS_ET_T    = 'TRACES';

-- Security and Identity
SET QS_INGEST_RL       = 'QS_TELEMETRY_INGEST_RL';
SET QS_INGEST_USER     = 'QS_TELEMETRY_INGEST_USER';
SET QS_INGEST_NP       = 'QS_TELEMETRY_INGEST_NP';      -- network policy
SET QS_INGEST_PAT_NAME = 'TELEMETRY_INGEST_PAT_TOKEN';  -- PAT token name
SET QS_INGEST_PAT_DAYS = 14;                            -- PAT lifetime in days; keep short and rotate

-- =============================================================================
-- Object Creation DDL
-- =============================================================================
-- ---- 1) Create Database, Schema, and Event Tables ---------------------------
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS IDENTIFIER($QS_DB);
USE DATABASE IDENTIFIER($QS_DB);

CREATE SCHEMA IF NOT EXISTS IDENTIFIER($QS_SCHEMA);
USE SCHEMA IDENTIFIER($QS_SCHEMA);

CREATE EVENT TABLE IF NOT EXISTS IDENTIFIER($QS_ET_L)
  COMMENT = 'Contains logs ingested via OTLP';
CREATE EVENT TABLE IF NOT EXISTS IDENTIFIER($QS_ET_M)
  COMMENT = 'Contains metrics ingested via OTLP';
CREATE EVENT TABLE IF NOT EXISTS IDENTIFIER($QS_ET_T)
  COMMENT = 'Contains traces ingested via OTLP';

-- ---- 2) Create Role and Ingest Grants ---------------------------------------
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS IDENTIFIER($QS_INGEST_RL);

GRANT INGEST TELEMETRY ON EVENT TABLE IDENTIFIER($QS_ET_L)
  TO ROLE IDENTIFIER($QS_INGEST_RL);
GRANT INGEST TELEMETRY ON EVENT TABLE IDENTIFIER($QS_ET_M)
  TO ROLE IDENTIFIER($QS_INGEST_RL);
GRANT INGEST TELEMETRY ON EVENT TABLE IDENTIFIER($QS_ET_T)
  TO ROLE IDENTIFIER($QS_INGEST_RL);

-- ---- 3) Create User and Assign Role ------------------------------------------
USE ROLE USERADMIN;
CREATE USER IF NOT EXISTS IDENTIFIER($QS_INGEST_USER)
  TYPE = SERVICE
  DEFAULT_ROLE = $QS_INGEST_RL
  COMMENT = 'Used to ingest telemetry via the OTLP public-endpoint';

USE ROLE SECURITYADMIN;
GRANT ROLE IDENTIFIER($QS_INGEST_RL) TO USER IDENTIFIER($QS_INGEST_USER);

-- ---- 4) Create and Assign Network Policy ------------------------------------
SET qs_np_ddl = (SELECT
  'CREATE NETWORK POLICY IF NOT EXISTS ' || $QS_INGEST_NP ||
  ' ALLOWED_IP_LIST = (''' || REPLACE($QS_INGEST_IP_ALLOWLIST, ',', ''',''') || ''')');
EXECUTE IMMEDIATE $qs_np_ddl;

ALTER USER IDENTIFIER($QS_INGEST_USER) SET NETWORK_POLICY = $QS_INGEST_NP;

-- ---- 5) Create and Assign PAT ------------------------------------------------
SET qs_pat_ddl =
  'ALTER USER ' || $QS_INGEST_USER ||
  ' ADD PROGRAMMATIC ACCESS TOKEN ' || $QS_INGEST_PAT_NAME ||
  ' DAYS_TO_EXPIRY = ' || $QS_INGEST_PAT_DAYS ||
  ' ROLE_RESTRICTION = ' || $QS_INGEST_RL;
EXECUTE IMMEDIATE $qs_pat_ddl;

-- ---- Cleanup
-- USE ROLE SECURITYADMIN;

-- =============================================================================
-- Cleanup DDL  (re-run the Variable Definitions block first if in a new session)
-- =============================================================================

-- -- ---- 1) Drop the service user (also removes its PAT) ----------------------
-- USE ROLE USERADMIN;
-- DROP USER IF EXISTS IDENTIFIER($QS_INGEST_USER);

-- -- ---- 2) Drop Network Policy and Role ---------------------------------------
-- USE ROLE SECURITYADMIN;
-- SET qs_drop_np_ddl = 'DROP NETWORK POLICY IF EXISTS ' || $QS_INGEST_NP;
-- EXECUTE IMMEDIATE $qs_drop_np_ddl;

-- DROP ROLE IF EXISTS IDENTIFIER($QS_INGEST_RL);

-- -- ---- 3) Drop Database (cascades to the schema and event tables) ------------
-- USE ROLE SYSADMIN;
-- DROP DATABASE IF EXISTS IDENTIFIER($QS_DB);
