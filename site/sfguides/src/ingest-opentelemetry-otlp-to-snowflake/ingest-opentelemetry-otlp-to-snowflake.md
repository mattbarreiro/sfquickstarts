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

<!-- TODO -->

<!-- TODO explain what the otel demo is (collection of microservices to) -->

OpenTelemetry is
Utilizes the OpenTelemetry Demo to generate telem



### Prerequisites

- Familiarity with .... <!-- TODO  i think this is more about "what you should know/understand" vs "what you need" -->
- 
- Familiarity with the basic concepts of Observability such as logs, metrics, and traces.
- (Helpful) Familiarity with OpenTelemetry

### What You’ll Learn

- <!-- TODO -->
- 

### What You’ll Need

- A Snowflake account with _____ permissions <!-- TODO  test with USE SECONDARY ROLES NONE -->
- A computer with:
  - Git
  - Docker
  - [Docker Compose v2.0.0+](https://docs.docker.com/compose/install/)
  - 6 GB of RAM for the application (or ~3 GB using [minimal mode](https://opentelemetry.io/docs/demo/docker-deployment/#run-in-minimal-mode))
  - 14 GB of disk space
  - (optional) Make

### What You’ll Build

- <!-- TODO -->


<!-- ------------------------ -->
## Background

OpenTelemetry (OTEL) is .... <!-- TODO -->
The OpenTelemetry Protocol (OTLP) is .... <!-- TODO -->

The [OpenTelemetry Demo](https://opentelemetry.io/ecosystem/demo/) is a "microservice-based distributed system intended to illustrate the implementation of OpenTelemetry in a near real-world environment". <!-- TODO paraphrase--> 
This make it a great source of realistic telemetry data, as well as a great tool for learning more about the OpenTelemetry ecosystem.

In the past, storing OpenTelemetry data on Snowflake typically meant emitting data as OTLP/JSON, pushing that JSON to a streaming service such as Kafka, ingesting that JSON to Snowflake as a `VARIANT`, and running transformations to flatten it into a tabular structure. This was complicated by OpenTelemetry's data model containing multiple tiers of nested data, with context needing to be preserved at all levels.

Snowflake now provides a managed OTLP endpoint to make ingesting OpenTelemetry data as simple as pointing your OpenTelemetry Collector directly at Snowflakes's endpoint.

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

Open in the `opentelemetry-demo` repo and add the following placeholders to the end of `.env.override`: 

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

<!-- TODO sentance intro / transition  -->

<!-- TODO explain what we are about to do, and that we have it in one big block because of session variables -->

Login to Snowsight and open a new worksheet. Paste the following in:

```sql
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
```

In a new tab, visit [https://checkip.amazonaws.com/](https://checkip.amazonaws.com/) to get your public IP. Then update `SET QS_INGEST_IP_ALLOWLIST = ...` with your IP address. 

> Note: If your account is configured to require all access via PrivateLink, use your private IP instead.

Review all the other variable definitions, and update if desired. 

Next paste all of the following into the same worksheet:

```sql
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
```

Then select and run all of the pasted code. This will set the session variables and then create all the required resources.

The last SQL command will display the PAT for the newly created user. Copy this and paste as the value for `SNOWFLAKE_PAT` in `.env.override`. Also, if you modified the default values for any of `QS_DB`, `QS_SCHEMA`, `QS_ET_L`, `QS_ET_M, or `QS_ET_T`, you also need to update `SNOWFLAKE_EVENT_TABLE_[LOGS|METRICS|TRACES]`.env.override` to match.

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

In the `opentelemetry-demo` repo, add the following to the end of `src/otel-collector/otelcol-config-extras.yml`:

```yaml
exporters:
  otlphttp/snowflake_traces:
    endpoint: ${env:SNOWFLAKE_OTLP_ENDPOINT}
    encoding: json
    headers:
      event-table: ${env:SNOWFLAKE_EVENT_TABLE_TRACES}
      Authorization: "Bearer ${env:SNOWFLAKE_PAT}"
  otlphttp/snowflake_metrics:
    endpoint: ${env:SNOWFLAKE_OTLP_ENDPOINT}
    encoding: json
    headers:
      event-table: ${env:SNOWFLAKE_EVENT_TABLE_METRICS}
      Authorization: "Bearer ${env:SNOWFLAKE_PAT}"
  otlphttp/snowflake_logs:
    endpoint: ${env:SNOWFLAKE_OTLP_ENDPOINT}
    encoding: json    # Snowflake expects OTLP JSON format
    headers:
      event-table: ${env:SNOWFLAKE_EVENT_TABLE_LOGS}
      Authorization: "Bearer ${env:SNOWFLAKE_PAT}"

service:
  pipelines:
    traces:
      exporters: [debug, span_metrics, otlphttp/snowflake_traces]
    metrics:
      exporters: [debug, otlphttp/snowflake_metrics]
    logs:
      exporters: [debug, otlphttp/snowflake_logs]

```

You can now bring the application up again with either:

```shell
docker compose up -d
```

for minimal mode, or

```shell
docker compose -f compose.yaml -f compose.full.yaml up -d
```

for full mode (depending on how much RAM you have.)

Then run 


<!-- ------------------------ -->
## Query Telemetry Data
<!-- TODO -->

<!-- ------------------------ -->
## Cleaning Up
<!-- TODO -->

<!-- ------------------------ -->
## Conclusion And Resources



<!-- TODO

At the end of your Snowflake Guide, always have a clear call to action (CTA). This CTA could be a link to the docs pages, links to videos on youtube, a GitHub repo link, etc. 

If you want to learn more about Snowflake Guide formatting, checkout the official documentation here: [Snowflake Guide](#)
 -->

### What You Learned

<!-- TODO 
- Basics of creating sections
- adding formatting and code snippets
- Adding images and videos with considerations to keep in mind
-->

### Related Resources

<!-- TODO 
- <link to github code repo>
- <link to related documentation>
-->
