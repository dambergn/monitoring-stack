Of course! Using Grafana to monitor status pages is an excellent and very common use case. It allows you to correlate external service outages (like GitHub, AWS, Cloudflare, etc.) with your own internal system metrics on a single pane of glass.
When you see a spike in your application errors, you can immediately look at your "External Services" dashboard and see if GitHub Actions is down, saving you hours of debugging.
The best way to do this depends on the technology powering the status page. Most modern status pages, like GitHub's (which is powered by Atlassian Statuspage), provide a machine-readable API endpoint.
Here are the best methods, from most recommended to least.
Method 1: The Best Way - Using the JSON API Data Source
Most services like Atlassian Statuspage, Status.io, etc., provide a summary.json endpoint. This is the most reliable way to get structured data.
GitHub's status page API endpoint is: https://www.githubstatus.com/api/v2/summary.json
Here’s a step-by-step guide:
1. Install the JSON API Plugin:
This is a community plugin, but it's widely used and stable.
In your Grafana instance, go to Administration -> Plugins.
Search for JSON API and install it.
Alternatively, use the grafana-cli:
Generated bash
grafana-cli plugins install marcusolsson-json-datasource
Use code with caution.
Bash
Restart your Grafana server for the plugin to be loaded.
2. Configure the JSON API Data Source:
Go to Connections -> Data sources -> Add new data source.
Search for JSON API and select it.
Name: GitHub Status (or whatever you like).
URL: https://www.githubstatus.com/api/v2/summary.json
Click Save & test. You should see a "Success" message.
3. Create Dashboard Panels:
Now for the fun part. You can create different panels for different views.
Panel A: Overall Status (Using the Stat Panel)
This gives you a big, clear indicator of the overall health.
Add a new panel and select the Stat visualization.
Select your GitHub Status data source.
In the query options, under Fields, set the Path to: $.status.indicator
This uses JSONPath to extract the indicator field from the status object in the JSON response. The response looks like this: {"status":{"indicator":"none","description":"All Systems Operational"}, ...}.
Transformations (Optional but recommended): Go to the Transform tab and use "Value mapping" to map text values to colors:
none -> Green
minor -> Yellow
major -> Orange
critical -> Red
In the Panel options on the right, you can set the color mode to "Background" to make it very obvious.
Panel B: Individual Component Status (Using Status History or Table)
This is great for seeing the status of each individual component (e.g., Git Operations, API Requests, GitHub Actions).
Add a new panel and select the Status History visualization.
Select your GitHub Status data source.
For the Path, use: $.components[*]
The [*] selects all items in the components array.
Grafana will now have access to each component object, which looks like: {"id":"...","name":"Git Operations","status":"operational",...}
Under the Fields options, map the JSON fields to the panel fields:
Name field: name
Value field: status
Value Mappings (Crucial!): Go to the Overrides or main panel options and set up Value Mappings to get colors.
operational -> Green
degraded_performance -> Yellow
partial_outage -> Orange
major_outage -> Red
Method 2: Using an RSS/Atom Feed
If a status page doesn't have a JSON API, it will almost certainly have an RSS or Atom feed for incidents. This is better for a historical log of incidents than a real-time status.
GitHub's incident history RSS feed is: https://www.githubstatus.com/history.rss
Install the RSS/Atom Plugin:
Go to Administration -> Plugins and search for RSS/Atom. Install the grafana-rss-datasource.
Restart Grafana.
Configure the Data Source:
Add a new RSS/Atom data source.
Name: GitHub Incidents RSS
URL: https://www.githubstatus.com/history.rss
Save & test.
Create a Dashboard Panel:
A Table panel is best for this.
Select your GitHub Incidents RSS data source.
The data will be pre-formatted with columns like title, description, and published. You can show or hide these as needed. This gives you a great log of recent incidents.
Method 3: Advanced - Prometheus + Blackbox Exporter
If you are already heavily invested in the Prometheus ecosystem, this is a very powerful and robust method.
Concept: The Blackbox exporter probes the status page's API endpoint. It checks for a 200 OK status and can even be configured to check the JSON content for a specific string (e.g., "indicator":"none"). Prometheus scrapes Blackbox, and Grafana queries Prometheus.
High-level steps:
Configure Blackbox Exporter: Add a module to your blackbox.yml to check the JSON content.
Generated yaml
modules:
  http_json_check:
    prober: http
    http:
      # Fails if the body doesn't contain this regex
      fail_if_body_not_matches_regexp:
        - '.*"indicator": ?"none".*'
        - '.*"description": ?"All Systems Operational".*'
Use code with caution.
Yaml
Configure Prometheus: Add a scrape job in prometheus.yml to probe the GitHub status URL via Blackbox.
Generated yaml
scrape_configs:
  - job_name: 'github_status'
    metrics_path: /probe
    params:
      module: [http_json_check] # Use the module from blackbox.yml
    static_configs:
      - targets:
          - https://www.githubstatus.com/api/v2/summary.json
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115 # Your Blackbox exporter address
Use code with caution.
Yaml
Grafana: Use your existing Prometheus data source and query the probe_success metric. A value of 1 means success, and 0 means failure.
Summary & Recommendation
Method	Pros	Cons	Best For
JSON API	Structured data, real-time, easy to visualize specific components.	Requires a simple plugin installation.	This is the recommended approach for almost everyone.
RSS/Atom Feed	Simple, widely available, good for incident history.	Not real-time status, less structured data.	Viewing a log of recent incidents and announcements.
Prometheus	Integrates perfectly with a Prometheus monitoring stack, very robust.	Most complex setup, requires multiple components.	Users who are already Prometheus experts.
For your goal of monitoring the GitHub status page, start with Method 1 (JSON API Data Source). It's the perfect balance of simplicity, power, and gives you exactly the kind of visualizations you need.