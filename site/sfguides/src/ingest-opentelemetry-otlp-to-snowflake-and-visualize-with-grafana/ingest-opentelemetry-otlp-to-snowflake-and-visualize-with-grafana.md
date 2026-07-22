<!-- TODO
* - 
* - Final checks before submission
*   - Ensure that folder name, md file name, id, and end of "fork repo link" all match exactly
-->

author: Matt Barreiro (@mattbarreiro)
id: ingest-opentelemetry-otlp-to-snowflake-and-visualize-with-grafana
language: en
summary: Use Snowflake's native OTLP endpoint to ingest OpenTelemetry data, then visualize it using Grafana.
categories: snowflake-site:taxonomy/solution-center/certification/quickstart,snowflake-site:taxonomy/product/platform,snowflake-site:taxonomy/snowflake-feature/ingestion,snowflake-site:taxonomy/snowflake-feature/observability,snowflake-site:taxonomy/snowflake-feature/data-lake
environments: web
status: Published
feedback link: https://github.com/Snowflake-Labs/sfguides/issues
fork repo link: https://github.com/Snowflake-Labs/sfquickstarts/tree/master/site/sfguides/src/ingest-opentelemetry-otlp-to-snowflake-and-visualize-with-grafana
<!-- open in snowflake: <optional but modify to link into the product> -->

# Ingest OpenTelemetry to Snowflake and Visualize with Grafana
<!-- ------------------------ -->
## Overview

<!-- TODO -->

<!-- TODO something about how you can still do the ingest portion without grafana!!! -->

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

**To complete the Grafana Visualization portion:**

- A Grafana instance with Enterprise Plugin access, such as:
  - The [Grafana Cloud free tier](https://grafana.com/products/cloud/free-tier/) (free for up to 3 users with limited ingest) <!-- TODO at one point, the free tier included enterprise plugins for free. Need to wait for trial to expire to make sure it still does. -->
  - [Amazon Managed Grafana](https://docs.aws.amazon.com/grafana/latest/userguide/) with the [Enterprise Plugin license added](https://docs.aws.amazon.com/grafana/latest/userguide/AMG-workspace-manage-enterprise.html)
  - [Azure Managed Grafana](https://learn.microsoft.com/en-us/azure/managed-grafana/overview) with the [Grafana Enterprise add-on](https://learn.microsoft.com/en-us/azure/managed-grafana/how-to-grafana-enterprise)
  - A self-hosted Grafana instance with an existing Enterprise License


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


Clone the OpenTelemetry Demo repo, then checkout the specified release tag.

```shell
git clone https://github.com/open-telemetry/opentelemetry-demo.git
cd opentelemetry-demo
git checkout 3.0.0
```

Now start the basic demo:

```shell
docker compose up -d
```

Once it comes up, you cn 

Web store: [http://localhost:8080/](http://localhost:8080/)

For more details, see the official [OpenTelemetry Demo Docker deployment documentation](https://opentelemetry.io/docs/demo/docker-deployment/).


<!-- ------------------------ -->
## Configure Snowflake to Receive OpenTelemetry Data  

<!-- ------------------------ -->
## Configure the OpenTelemetry Collector to Ship Logs to Snowflake


<!-- ------------------------ -->
## Metadata Configuration

It is important to set the correct metadata for your Snowflake Guide. This is the first thing that goes on top of your guide. 
The metadata contains all the information required for listing and publishing your guide and includes some required and some optional information.


```diff
- REQUIRED FIELDS
```

- **id**: sample-separated-by-hyphens-not-underscores 
  - make sure to match the id here with the name of the file, all one word.
- **language**: pick from list 
  - pick the appropriate language from the list provided here: https://www.snowflake.com/en/developers/guides/get-started-with-guides/#language-and-category-tags 
- **categories**: Pick from the list
  - select from the complete list of categories provided here: https://www.snowflake.com/en/developers/guides/get-started-with-guides/#language-and-category-tags.  Please DO NOT create new categories.
- **status**: (`Published`, `Archived`, `Hidden`)<br>
  `Published` - implies the guide is active<br>
  `Archived` - implies the sfguide is out of date and deprecated and no longer available.
- **authors**: Author Full Name 
  - Indicate the author(s) of this specific sfguide.  


```diff
- OPTIONAL
```
  - **summary**: This is a sample Snowflake Guide 
  - This should be a short, 1 sentence description of your guide. This will be visible on the main landing page. 
  - **environments**: web 
  - `web` is default. If this will be published for a specific event or  conference, include it here.
  - **feedback link**: https://github.com/Snowflake-Labs/sfguides/issues
  - **fork repo link**: add your repo link here for GitHub
  - **open in snowflake**: add deeplinks straight into the product or to a template within Snowflake.



<!-- ------------------------ -->
## Creating Sections

A single sfguide consists of multiple steps or sections. 
These sections are defined in Markdown using Header tags.  Header 2 tag is `##`, Header 3 tag is `###` and so forth. 

```markdown
## Step 1 Title as H2 tag

All the content for the step goes here.

## Step 2 Title as H2 tag

### Subheader goes here as H3 tag.


```
>Please avoid going beyond H4 #### as it will not render on the page correctly!

<!-- ------------------------ -->
## Headers and Subheaders

Keep the headers to a minimum as a best practice.
These show up as your menu on the right.  Keeping them short (3-4 words) helps keep the guide precise and easy to follow.



### Formatting Operations

You can format various elements in markdown format in your guide.
Details of that are available at: 

[Get Started with Guides](##) to refresh markdown to add formatting, generate code snippets, info boxes, and download buttons etc. 


The guide linked above explains how you can use various formatting elements and the tag categories etc. to keep in mind when drafting your guide.<br>
Please use the guide to add elements to your markdown within this template.  <p>


> NOTE:
> This template is an example of the layout/flow to use.



<!-- ------------------------ -->
## Adding Appropriate Tags 

**Content Type & Industries Tags** 
- Pick the appropriate content type that applies to your Guide. This helps with filtering content on the website.
- If relevant, please pick industry tags as well so content is reflected appropriately on the website.

- Languages
Guides are available in various languages for the regions.
specific language tags must be added to the document to ensure the regional pages can see your guide.

**Please pick from the list of languages** 
- These are the supported exact acronyms used on the main page.  
- Deviating from the accronyms means your pages will not show up on the regional pages.


**Please pick tags from the list of 3 types of categories** 
- DO NOT create new tags if you don't see them in the list.  


A complete list of the language and category tags is available here: https://www.snowflake.com/en/developers/guides/get-started-with-guides/#language-and-category-tags



<!-- ------------------------ -->
## Images and Videos

Ensure your videos are uploaded to the YouTube Channel (Snowflake Developer) before you start working on your guide.

You have the option to submit videos to Snowflake Corporate channel, Developers Channel or International Channel.
Use this link to [submit your videos](https://www.wrike.com/frontend/requestforms/index.html?token=eyJhY2NvdW50SWQiOjE5ODk1MzYsInRhc2tGb3JtSWQiOjExNDYyNzB9CTQ4NDU3Mjk1MjcxNjYJMTk3ZmNhNWQ1ODM5NTc1OGI2OWY5Mjc4Mzk4M2YwOGQ1Y2RiNGVlMGUzZDg3OTk3NzI3N2JkMTIyOGViZTdjMQ==)


Look at the [markdown source for this guide](https://raw.githubusercontent.com/Snowflake-Labs/sfguides/master/site/sfguides/sample.md) to see how to use markdown to generate these elements. 

### Images
Image Guidelines: 
- Naming convention should be all lower case and include underscores (no hyphens)
- No special characters 
- File size should be less than 1MB. Gifs may be larger, however, should be optimized to prevent reduction of page load times
- Image file name should align to the name in .md file (this is case sensitive) 
- All images should be added to the 'assets' subfolder for your guide (please do not create additional subfolders within the 'assets' subfolder)
- No full resolution images; these should be optimized for web (recommended: tinypng) 
- Do no use HTML code for adding images



<!-- ------------------------ -->
## Conclusion And Resources

At the end of your Snowflake Guide, always have a clear call to action (CTA). This CTA could be a link to the docs pages, links to videos on youtube, a GitHub repo link, etc. 

If you want to learn more about Snowflake Guide formatting, checkout the official documentation here: [Snowflake Guide](#)

### What You Learned
- Basics of creating sections
- adding formatting and code snippets
- Adding images and videos with considerations to keep in mind

### Related Resources
- <link to github code repo>
- <link to related documentation>

### EXAMPLES:
* **Logged Out experience with one click into product:** [Understanding Customer Reviews using Snowflake Cortex](https://www.snowflake.com/en/developers/guides/understanding-customer-reviews-using-snowflake-cortex/)
* **Topic pages with multiple use cases below the Overview:** [Data Connectivity with Snowflake Openflow](https://www.snowflake.com/en/developers/guides/data-connectivity-with-snowflake-openflow/)
* **Simple Hands-on Guide**: [Getting Started with Snowflake Intelligence](https://www.snowflake.com/en/developers/guides/getting-started-with-snowflake-intelligence/)
