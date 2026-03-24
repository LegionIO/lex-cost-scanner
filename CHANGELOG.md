# Changelog

## [0.1.0] - 2026-03-24

### Added
- Resource classifier with LLM + rule-based fallback (idle < 5% CPU, oversized 5-20%)
- Findings store with deduplication by account + resource + finding type
- Scanner runner: `scan_account`, `scan_all`, `scan_stats`
- Reporter runner: `generate_report`, `format_slack_blocks`, `post_report`
- WeeklyScan interval actor (604800s / 1 week)
