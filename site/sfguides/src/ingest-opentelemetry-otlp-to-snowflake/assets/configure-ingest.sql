-- Copyright 2026 Snowflake Inc.
-- SPDX-License-Identifier: Apache-2.0

-- =============================================================================
-- Object Creation DDL
-- =============================================================================
-- ---- 1) Create Database, Schema, and Event Tables ---------------------------
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS OTLP_INGEST_QS;
USE DATABASE OTLP_INGEST_QS;

CREATE SCHEMA IF NOT EXISTS TELEMETRY;
USE SCHEMA TELEMETRY;

CREATE EVENT TABLE IF NOT EXISTS LOGS
  COMMENT = 'Contains logs ingested via OTLP';
CREATE EVENT TABLE IF NOT EXISTS METRICS
  COMMENT = 'Contains metrics ingested via OTLP';
CREATE EVENT TABLE IF NOT EXISTS TRACES
  COMMENT = 'Contains traces ingested via OTLP';

-- ---- 2) Create Role and Ingest Grants ---------------------------------------
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS QS_TELEMETRY_INGEST_RL;

GRANT INGEST TELEMETRY ON EVENT TABLE OTLP_INGEST_QS.TELEMETRY.LOGS
  TO ROLE QS_TELEMETRY_INGEST_RL;
GRANT INGEST TELEMETRY ON EVENT TABLE OTLP_INGEST_QS.TELEMETRY.METRICS
  TO ROLE QS_TELEMETRY_INGEST_RL;
GRANT INGEST TELEMETRY ON EVENT TABLE OTLP_INGEST_QS.TELEMETRY.TRACES
  TO ROLE QS_TELEMETRY_INGEST_RL;

-- ---- 3) Create User and Assign Role ------------------------------------------
USE ROLE USERADMIN;
CREATE USER IF NOT EXISTS QS_TELEMETRY_INGEST_USER
  TYPE = SERVICE
  DEFAULT_ROLE = QS_TELEMETRY_INGEST_RL
  COMMENT = 'Used to ingest telemetry via the OTLP public-endpoint';

USE ROLE SECURITYADMIN;
GRANT ROLE QS_TELEMETRY_INGEST_RL TO USER QS_TELEMETRY_INGEST_USER;

-- ---- 4) Create and Assign Network Policy -------------------------------------
-- ---- You MUST change the following value -------------------------------------
-- Replace 192.0.2.0 with your public IP (see https://checkip.amazonaws.com/)
-- and/or CIDR(s). Add more than one by comma-separating them within the parens.
CREATE NETWORK POLICY IF NOT EXISTS QS_TELEMETRY_INGEST_NP
  ALLOWED_IP_LIST = ('192.0.2.0'); -- <<< CHANGE THIS!

ALTER USER QS_TELEMETRY_INGEST_USER SET NETWORK_POLICY = QS_TELEMETRY_INGEST_NP;

-- ---- 5) Create and Assign PAT ------------------------------------------------
ALTER USER QS_TELEMETRY_INGEST_USER
  ADD PROGRAMMATIC ACCESS TOKEN TELEMETRY_INGEST_PAT_TOKEN
  DAYS_TO_EXPIRY = 14              -- PAT lifetime in days; keep short and rotate
  ROLE_RESTRICTION = QS_TELEMETRY_INGEST_RL;

-- =============================================================================
-- Cleanup DDL
-- =============================================================================

-- -- ---- 1) Drop the service user (also removes its PAT) ----------------------
-- USE ROLE USERADMIN;
-- DROP USER IF EXISTS QS_TELEMETRY_INGEST_USER;

-- -- ---- 2) Drop Network Policy and Role ---------------------------------------
-- USE ROLE SECURITYADMIN;
-- DROP NETWORK POLICY IF EXISTS QS_TELEMETRY_INGEST_NP;
-- DROP ROLE IF EXISTS QS_TELEMETRY_INGEST_RL;

-- -- ---- 3) Drop Database (cascades to the schema and event tables) ------------
-- USE ROLE SYSADMIN;
-- DROP DATABASE IF EXISTS OTLP_INGEST_QS;
