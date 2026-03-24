# lex-cost-scanner

Cloud cost optimization scanner for LegionIO. Scans AWS/Azure accounts for idle and oversized resources, classifies findings via LLM (with rule-based fallback), deduplicates across scans, and delivers a weekly Slack Block Kit report.

## Architecture

- **WeeklyScan actor** — interval actor fires `scan_all` every 604,800 seconds (1 week)
- **Scanner runner** — iterates configured accounts, fetches resources, classifies each one
- **Classifier helper** — uses `legion-llm` if available; falls back to CPU utilization rules
- **FindingsStore** — thread-safe in-memory store with dedup by `account_id:resource_id:finding_type`
- **Reporter runner** — generates Slack Block Kit weekly summary and posts via `lex-slack`

## Settings

```yaml
cost_scanner:
  slack_webhook: "https://hooks.slack.com/services/..."
  accounts:
    - id: "123456789012"
      cloud: "aws"
    - id: "my-gcp-project"
      cloud: "gcp"
```

## Classification Rules (rule-based fallback)

| CPU Avg | Finding | Severity |
|---------|---------|----------|
| < 5%    | idle    | high     |
| 5–20%   | oversized | medium |
| >= 20%  | none    | —        |

Resources costing less than $50/month are skipped (`MIN_MONTHLY_COST`).

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```
