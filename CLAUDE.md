# lex-cost-scanner: Cloud Cost Optimization Scanner

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Cloud cost optimization scanner for LegionIO. Scans configured AWS/GCP/Azure accounts for idle and oversized resources, classifies findings (with optional LLM-enhanced classification), deduplicates across scans via in-memory store, and delivers a weekly Slack Block Kit report.

## Gem Info

- **Gem name**: `lex-cost-scanner`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CostScanner`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cost_scanner/
  version.rb
  cost_scanner.rb                     # Entry point
  helpers/
    constants.rb                      # FINDING_TYPES, SEVERITIES, IDLE_CPU_THRESHOLD, OVERSIZED_CPU_THRESHOLD, MIN_MONTHLY_COST
    classifier.rb                     # Classifier module — classify(resource_id:, resource_type:, monthly_cost:, utilization:)
    findings_store.rb                 # FindingsStore module — record, stats, top_by_savings, total_savings; thread-safe dedup
  runners/
    scanner.rb                        # scan_all, scan_account, scan_stats; fetch_resources delegates to lex-http
    reporter.rb                       # generate_report, format_slack_blocks, post_report
  actors/
    weekly_scan.rb                    # Every 604800s (1 week): scan_all
spec/
```

## Key Constants

```ruby
FINDING_TYPES          = %i[idle oversized unused_reservation orphaned_storage rightsizing none]
SEVERITIES             = %i[critical high medium low info]
IDLE_CPU_THRESHOLD     = 5.0    # % avg CPU — below this is "idle"
OVERSIZED_CPU_THRESHOLD = 20.0  # % avg CPU — between idle and this is "oversized"
MIN_MONTHLY_COST       = 50.0   # $ — resources cheaper than this are skipped
```

## Classification Rules

The Classifier uses `legion-llm` when available, falling back to CPU utilization rules:

| CPU Average | Finding Type | Severity |
|-------------|-------------|----------|
| < 5% | `idle` | `high` |
| 5–20% | `oversized` | `medium` |
| >= 20% | `none` | — |

Resources with `monthly_cost < MIN_MONTHLY_COST` are skipped entirely before classification.

## FindingsStore

Thread-safe in-memory store. Deduplication key: `"#{account_id}:#{resource_id}:#{finding_type}"`. `record` returns `{ new: true/false }`. `top_by_savings(limit:)` returns the top N findings sorted by `estimated_monthly_savings` descending.

## Runners

### `Runners::Scanner`

- `scan_all` — iterates `Settings[:cost_scanner][:accounts]`, calls `scan_account` for each
- `scan_account(account_id:, cloud:)` — `fetch_resources` (currently returns `[]` pending real cloud API integration via `lex-http`), classifies each resource, records findings
- `scan_stats` — delegates to `FindingsStore.stats`

### `Runners::Reporter`

- `generate_report(limit:)` — returns `{ total_savings:, findings_count:, by_type:, top_findings:, generated_at: }`
- `format_slack_blocks(report:)` — produces Slack Block Kit JSON blocks
- `post_report(limit:)` — runs `generate_report`, posts to Slack webhook via `lex-slack` if configured

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

## Actor: WeeklyScan

`Every` actor. Fires `scan_all` every 604,800 seconds (1 week). `run_now?` should be `false` — waits for the first interval.

## Integration Points

- **lex-slack** (`extensions-other/`): `post_report` posts via `Slack::Client#send_webhook`
- **legion-llm**: Classifier uses `LLM.chat` when available for enhanced classification
- **lex-http** (`extensions/`): `fetch_resources` is wired through `Http::Client` (currently returns `[]` until cloud adapter is implemented)
- **lex-finops**: FinOps handles USD budget limits; CostScanner identifies optimization opportunities

## Development Notes

- `fetch_resources` returns `[]` in the current implementation — it is a stub guarded by `defined?(Legion::Extensions::Http::Client)`. Real cloud API adapters (AWS Cost Explorer, GCP BigQuery, Azure Cost Management) are planned.
- `FindingsStore` is a module-level singleton using `@findings` ivar — the store is process-wide
- All runner methods use `include` pattern (not `extend self`) — they are mixed into `Client`

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

---

**Maintained By**: Matthew Iverson (@Esity)
