<!-- TODO
* - 
* - Final checks before submission
*   - Ensure you're complying with the following:
*     - Folder name, md file name, id, and end of "fork repo link" all match exactly
*     - Keep H2 to a minimum and keep short (show up on right side nav bar)
*     - Images
*       - Name: all lowercase + underscores
*       - Be in Assets subfolder (no additional subfolders)
*       - Do no use HTML code for adding images
*       - Be web-optimized (recommended: tinypng), and MUST be <1MB
*         - Guide recommended: tinypng
*         - MPB to explore: Oxipng (CLI) OR JUST USE SNAGIT
*     
-->

author: Matt Barreiro (@mattbarreiro)
id: ingest-opentelemetry-otlp-to-snowflake
language: en
summary: Use Snowflake's native OTLP endpoint to ingest OpenTelemetry telemetry data
categories: snowflake-site:taxonomy/solution-center/certification/quickstart,snowflake-site:taxonomy/product/platform,snowflake-site:taxonomy/snowflake-feature/ingestion,snowflake-site:taxonomy/snowflake-feature/observability,snowflake-site:taxonomy/snowflake-feature/data-lake
environments: web
status: Published
feedback link: https://github.com/Snowflake-Labs/sfguides/issues
fork repo link: https://github.com/Snowflake-Labs/sfquickstarts/tree/master/site/sfguides/src/ingest-opentelemetry-otlp-to-snowflake
<!-- open in snowflake: <optional but modify to link into the product e.g. https://docs.snowflake.com/en/user-guide/ui-snowsight/snowsight-templates>  and https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-intelligence/ -->

# Ingest OpenTelemetry (OTLP) Telemetry to Snowflake
<!-- ------------------------ -->
## Overview

OpenTelemetry is the industry-standard, vendor-neutral framework for instrumenting applications to produce telemetry data — logs, metrics, and traces — and shipping it to an observability backend using the OpenTelemetry Protocol (OTLP). In this guide, you'll stand up the [OpenTelemetry Demo](https://opentelemetry.io/ecosystem/demo/), a realistic e-commerce application fully instrumented with OpenTelemetry, and configure its OpenTelemetry Collector to export logs, metrics, and traces directly to Snowflake using Snowflake's native OTLP ingest endpoint — no external pipeline or ETL required.

### Prerequisites

- Familiarity with:
  - Running Docker containers and using the command line
  - Basic Snowflake objects (databases, schemas, roles) and running SQL in Snowsight
  - The basic concepts of Observability such as logs, metrics, and traces
  - (Helpful) OpenTelemetry

### What You’ll Learn

- How to configure Snowflake to natively receive OpenTelemetry (OTLP) data via a managed public endpoint
- How to configure an OpenTelemetry Collector to export logs, metrics, and traces to Snowflake Event Tables
- How to query OpenTelemetry logs, metrics, and traces stored in Snowflake using SQL

### What You’ll Need

- A Snowflake account with a role that can act as `SYSADMIN`, `SECURITYADMIN`, and `USERADMIN` (for example, `ACCOUNTADMIN`), used to create the database, event tables, role, service user, network policy, and PAT
- A computer with:
  - Git
  - Docker
  - [Docker Compose v2.0.0+](https://docs.docker.com/compose/install/)
  - 6 GB of RAM for the application (or ~3 GB using [minimal mode](https://opentelemetry.io/docs/demo/docker-deployment/#run-in-minimal-mode))
  - 14 GB of disk space
  - (optional) Make

### What You’ll Build

- A set of Snowflake Event Tables that store OpenTelemetry logs, metrics, and traces ingested directly via OTLP
- A dedicated, network-restricted service user and role used only for telemetry ingestion
- A running instance of the OpenTelemetry Demo shop application, streaming its telemetry straight to Snowflake

<!-- ------------------------ -->
## Background

[OpenTelemetry](https://opentelemetry.io/) (OTel) is an open-source, vendor-neutral framework and set of standards, backed by the Cloud Native Computing Foundation (CNCF), for instrumenting, generating, collecting, and exporting telemetry data — logs, metrics, and traces — from applications and infrastructure. It has become the industry standard for observability instrumentation.

The [OpenTelemetry Protocol (OTLP)](https://opentelemetry.io/docs/specs/otlp/) is the wire protocol OpenTelemetry uses to transmit telemetry data between components — for example, from an application's SDK to an [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/), and from a Collector to one or more observability backends.

The [OpenTelemetry Demo](https://opentelemetry.io/ecosystem/demo/) is a mock e-commerce application, implemented as microservices and fully instrumented with OpenTelemetry, designed to illustrate realistic, production-like telemetry across a distributed system.
This makes it a great source of realistic telemetry data, as well as a great tool for learning more about the OpenTelemetry ecosystem.

In the past, storing OpenTelemetry data on Snowflake typically meant emitting data as OTLP/JSON, pushing that JSON to a streaming service such as Kafka, ingesting that JSON to Snowflake as a `VARIANT`, and running transformations to flatten it into a tabular structure. This was complicated by OpenTelemetry's data model containing multiple tiers of nested data, with context needing to be preserved at all levels.

Snowflake now provides a managed OTLP endpoint to make ingesting OpenTelemetry data as simple as pointing your OpenTelemetry Collector directly at Snowflake's endpoint.

> You may already be familiar with OpenTelemetry from [Snowflake Trail](https://www.snowflake.com/en/product/features/snowflake-trail/). Snowflake also collects telemetry data emitted from the Snowflake platform itself and your apps/workloads running on Snowflake. All this data is emitted in OpenTelemetry format and stored in the Event Table(s) configured for your Snowflake Account. For more info, see [Getting Started with Snowflake Trail for Observability](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-trail-for-observability/).

<!-- ------------------------ -->
## Stand Up the OpenTelemetry Demo

Clone the OpenTelemetry Demo repo, then checkout the specified release tag:

```shell
git clone https://github.com/open-telemetry/opentelemetry-demo.git
cd opentelemetry-demo
git checkout 3.0.0
```

Now start the Shop demo:

```shell
docker compose up -d
```

Now navigate to [http://localhost:8080/](http://localhost:8080/) and you should now see the Shop demo application!

Once you've confirmed that the website comes up and you can click through a few pages, run the following to stop the demo application for now:

```shell
docker compose down --remove-orphans
```

> For more details on config options, see the official [OpenTelemetry Demo Docker deployment documentation](https://opentelemetry.io/docs/demo/docker-deployment/).

<!-- ------------------------ -->
## Configure Snowflake to Receive Telemetry

We need to create some resources in Snowflake to support ingestion, which will later be used to configure the OpenTelemetry collector to ingest data to Snowflake. We will add these to an ENV file as we go to keep track.

### Add Placeholders to `.env.override`

In the `opentelemetry-demo` repo, open `.env.override` and add the following placeholders to the end of the file:

```shell
SNOWFLAKE_ACCOUNT_URL=https://
SNOWFLAKE_EVENT_TABLE_LOGS=OTLP_INGEST_QS.TELEMETRY.LOGS
SNOWFLAKE_EVENT_TABLE_METRICS=OTLP_INGEST_QS.TELEMETRY.METRICS
SNOWFLAKE_EVENT_TABLE_TRACES=OTLP_INGEST_QS.TELEMETRY.TRACES
SNOWFLAKE_OTLP_ENDPOINT=https://
SNOWFLAKE_PAT=
```

Then add your Snowflake Account/Server URL to the end of `SNOWFLAKE_ACCOUNT_URL=https://` (e.g. `SNOWFLAKE_ACCOUNT_URL=https://myaccount-myorg.snowflakecomputing.com`) and save the file.

### Create Snowflake Resources

Next, create the Snowflake objects needed to receive telemetry: a database and schema to hold the Event Tables, one Event Table per signal type (logs, metrics, traces), a dedicated role and service user for ingestion, a network policy restricting access to that user, and a PAT the OpenTelemetry Collector will use to authenticate.

Login to Snowsight, open a new worksheet, and run each of the following steps in order.

#### 1. Create the Database, Schema, and Event Tables

```sql
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
```

> Feel free to rename `OTLP_INGEST_QS`, `TELEMETRY`, `LOGS`, `METRICS`, or `TRACES` — just use the same names in the remaining steps below and in `.env.override` later.

#### 2. Create a Role and Grant Ingest Privileges

Create a role dedicated to telemetry ingestion, then grant it the `INGEST TELEMETRY` privilege on each Event Table:

```sql
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS QS_TELEMETRY_INGEST_RL;

GRANT INGEST TELEMETRY ON EVENT TABLE OTLP_INGEST_QS.TELEMETRY.LOGS
  TO ROLE QS_TELEMETRY_INGEST_RL;
GRANT INGEST TELEMETRY ON EVENT TABLE OTLP_INGEST_QS.TELEMETRY.METRICS
  TO ROLE QS_TELEMETRY_INGEST_RL;
GRANT INGEST TELEMETRY ON EVENT TABLE OTLP_INGEST_QS.TELEMETRY.TRACES
  TO ROLE QS_TELEMETRY_INGEST_RL;
```

#### 3. Create a Service User and Assign the Role

```sql
USE ROLE USERADMIN;
CREATE USER IF NOT EXISTS QS_TELEMETRY_INGEST_USER
  TYPE = SERVICE
  DEFAULT_ROLE = QS_TELEMETRY_INGEST_RL
  COMMENT = 'Used to ingest telemetry via the OTLP public-endpoint';

USE ROLE SECURITYADMIN;
GRANT ROLE QS_TELEMETRY_INGEST_RL TO USER QS_TELEMETRY_INGEST_USER;
```

#### 4. Create and Assign a Network Policy

Service users must be subject to a network policy to authenticate. In a new tab, visit [https://checkip.amazonaws.com/](https://checkip.amazonaws.com/) to get your public IP, then replace `192.0.2.0` below with that IP before running:

```sql
CREATE NETWORK POLICY IF NOT EXISTS QS_TELEMETRY_INGEST_NP
  ALLOWED_IP_LIST = ('192.0.2.0'); -- <<< CHANGE THIS!

ALTER USER QS_TELEMETRY_INGEST_USER SET NETWORK_POLICY = QS_TELEMETRY_INGEST_NP;
```

> **Note:** To allow more than one address, comma-separate them inside the parentheses, e.g. `ALLOWED_IP_LIST = ('192.0.2.0', '192.168.0.0/24')`. And if your account is configured to require all access via PrivateLink, use your private IP instead.

#### 5. Create a Programmatic Access Token (PAT)

Finally, issue a PAT for the service user, restricted to the ingest role:

```sql
ALTER USER QS_TELEMETRY_INGEST_USER
  ADD PROGRAMMATIC ACCESS TOKEN TELEMETRY_INGEST_PAT_TOKEN
  DAYS_TO_EXPIRY = 14
  ROLE_RESTRICTION = QS_TELEMETRY_INGEST_RL;
```

This command's output includes a `token_secret` column. Copy that value and paste it as the value for `SNOWFLAKE_PAT` in `.env.override`.

> If you renamed anything in Step 1, remember to update `SNOWFLAKE_EVENT_TABLE_LOGS`, `SNOWFLAKE_EVENT_TABLE_METRICS`, and `SNOWFLAKE_EVENT_TABLE_TRACES` in `.env.override` to match.

### Retrieve the Telemetry Endpoint URL

The URL used for the OTLP endpoint is different from the typical Snowflake account URL. Retrieve it by running the following:

```shell
# Load the env file
set -a && source .env.override && set +a
# Retrieve the OTLP endpoint URL
result=$(curl "${SNOWFLAKE_ACCOUNT_URL}/observability/event-table/hostname" -H "Authorization: Bearer ${SNOWFLAKE_PAT}")
echo $result
```

Then copy the result and paste it at the end of `SNOWFLAKE_OTLP_ENDPOINT=https://` in  `.env.override` (e.g. `SNOWFLAKE_OTLP_ENDPOINT=https://myaccount-myorg.telemetry.foo.snowflakecomputing.com`) and save the file.

> Before proceeding to the next section, confirm that your `.env.override` file has key-value pairs for all of the placeholders we added at the beginning of this section.

<!-- ------------------------ -->
## Configure the OpenTelemetry Collector

Now that all resources are created and our `.env.override` is filled out, the last step is to configure the OpenTelemetry Collector to use the Snowflake OTLP endpoint. The Collector is managed by YAML config files, which are merged into one final configuration (NOTE: arrays are replaced, not appended).

If you haven't already, stop the existing Compose stack:

```shell
docker compose down --remove-orphans
```

In the `opentelemetry-demo` repo, add the following to the end of `compose.extras.yaml`:

```yaml
# compose.extras.yaml
services:
  # Patch otel-collector to add the environment variables needed for Snowflake.
  otel-collector:
    environment:
      - SNOWFLAKE_OTLP_ENDPOINT
      - SNOWFLAKE_EVENT_TABLE_TRACES
      - SNOWFLAKE_EVENT_TABLE_METRICS
      - SNOWFLAKE_EVENT_TABLE_LOGS
      - SNOWFLAKE_PAT
```

Also in the `opentelemetry-demo` repo, add the following to the end of `src/otel-collector/otelcol-config-extras.yml`:

```yaml
# src/otel-collector/otelcol-config-extras.yml
exporters:
  otlp_http/snowflake_traces:
    endpoint: ${env:SNOWFLAKE_OTLP_ENDPOINT}
    encoding: json
    headers:
      event-table: ${env:SNOWFLAKE_EVENT_TABLE_TRACES}
      Authorization: "Bearer ${env:SNOWFLAKE_PAT}"
  otlp_http/snowflake_metrics:
    endpoint: ${env:SNOWFLAKE_OTLP_ENDPOINT}
    encoding: json
    headers:
      event-table: ${env:SNOWFLAKE_EVENT_TABLE_METRICS}
      Authorization: "Bearer ${env:SNOWFLAKE_PAT}"
  otlp_http/snowflake_logs:
    endpoint: ${env:SNOWFLAKE_OTLP_ENDPOINT}
    encoding: json    # Snowflake expects OTLP JSON format
    headers:
      event-table: ${env:SNOWFLAKE_EVENT_TABLE_LOGS}
      Authorization: "Bearer ${env:SNOWFLAKE_PAT}"

service:
  pipelines:
    traces:
      exporters: [span_metrics, otlp_http/snowflake_traces]
    metrics:
      exporters: [otlp_http/snowflake_metrics]
    logs:
      exporters: [otlp_http/snowflake_logs]

```

You can now bring the application up with the following, which merges both compose files:

```shell
docker compose -f compose.yaml -f compose.extras.yaml up -d
```

Give the demo application a few moments to start up, then generate some traffic by clicking around the [Web store](http://localhost:8080/) — browse products, add items to your cart, and check out. This traffic generates logs, metrics, and traces that flow through the Collector to Snowflake.

To confirm telemetry is being exported successfully, check the Collector's logs for errors:

```shell
docker compose logs otel-collector
```

### Optional: Full Mode

If you have ~6GB or more of free RAM, you can also run the application in "full" mode. This adds Kafka, additional services that depend on Kafka, and patches other core services for Kafka-awareness. This is not required, but does <!-- TODO -->

```shell
docker compose down --remove-orphans
docker compose -f compose.yaml -f compose.full.yaml -f compose.extras.yaml up -d
```

<!-- ------------------------ -->
## Query Telemetry Data

With telemetry flowing into your Event Tables, you can query logs, metrics, and traces directly with SQL. Run the following in a Snowsight worksheet:

```sql
USE DATABASE OTLP_INGEST_QS;
USE SCHEMA TELEMETRY;

-- Most recent trace spans, by service
SELECT
  TIMESTAMP,
  RESOURCE_ATTRIBUTES:"service.name"::STRING AS SERVICE_NAME,
  RECORD:"name"::STRING AS SPAN_NAME,
  RECORD_TYPE
FROM TRACES
ORDER BY TIMESTAMP DESC
LIMIT 25;

-- Most recent log messages, by service
SELECT
  TIMESTAMP,
  RESOURCE_ATTRIBUTES:"service.name"::STRING AS SERVICE_NAME,
  RECORD:"severity_text"::STRING AS SEVERITY,
  VALUE AS LOG_MESSAGE
FROM LOGS
ORDER BY TIMESTAMP DESC
LIMIT 25;

-- Most recent metric data points, by service
SELECT
  TIMESTAMP,
  RESOURCE_ATTRIBUTES:"service.name"::STRING AS SERVICE_NAME,
  RECORD:"metric":"name"::STRING AS METRIC_NAME,
  VALUE
FROM METRICS
ORDER BY TIMESTAMP DESC
LIMIT 25;
```

> If these queries return no rows, give the pipeline another minute and re-run — the Collector batches exports on an interval — or check `docker compose logs otel-collector` for delivery errors.

Each row's `RESOURCE_ATTRIBUTES`, `RECORD`, and `RECORD_ATTRIBUTES` columns are semi-structured `OBJECT`/`VARIANT` data, so you can use standard Snowflake [JSON path notation](https://docs.snowflake.com/en/user-guide/querying-semistructured) to pull out any attribute emitted by the OpenTelemetry SDKs. For the full column reference, see [Event table columns](https://docs.snowflake.com/en/developer-guide/logging-tracing/event-table-columns).

<!-- ------------------------ -->
## Cleaning Up

When you're done, stop the OpenTelemetry Demo and remove its containers, network, and volumes:

```shell
docker compose down --remove-orphans -v
```

Next, clean up the Snowflake resources created earlier by running the following in a Snowsight worksheet:

```sql
-- ---- 1) Drop the service user (also removes its PAT) -------------------------
USE ROLE USERADMIN;
DROP USER IF EXISTS QS_TELEMETRY_INGEST_USER;

-- ---- 2) Drop Network Policy and Role ------------------------------------------
USE ROLE SECURITYADMIN;
DROP NETWORK POLICY IF EXISTS QS_TELEMETRY_INGEST_NP;
DROP ROLE IF EXISTS QS_TELEMETRY_INGEST_RL;

-- ---- 3) Drop Database (cascades to the schema and event tables) --------------
USE ROLE SYSADMIN;
DROP DATABASE IF EXISTS OTLP_INGEST_QS;
```

<!-- ------------------------ -->
## Conclusion And Resources

Congratulations! You've configured Snowflake to natively ingest OpenTelemetry logs, metrics, and traces via OTLP — no Kafka, no external pipeline, and no manual flattening of nested JSON required. From here, you can point any OpenTelemetry Collector at your Snowflake account and start querying your own applications' telemetry with SQL.

### What You Learned

- How OpenTelemetry, OTLP, and the OpenTelemetry Demo fit together
- How to create Snowflake Event Tables dedicated to OTLP-ingested logs, metrics, and traces
- How to create a network-restricted service user and role, and issue a PAT scoped for telemetry ingestion only
- How to configure an OpenTelemetry Collector exporter to send data directly to Snowflake's managed OTLP endpoint
- How to query OpenTelemetry data stored in Event Tables using standard SQL and semi-structured data functions

### Related Resources

- [OpenTelemetry Demo documentation](https://opentelemetry.io/docs/demo/)
- [Event table columns](https://docs.snowflake.com/en/developer-guide/logging-tracing/event-table-columns)
- [Using programmatic access tokens for authentication](https://docs.snowflake.com/en/user-guide/programmatic-access-tokens)
- [Getting Started with Snowflake Trail for Observability](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-trail-for-observability/)
