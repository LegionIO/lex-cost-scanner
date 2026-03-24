# frozen_string_literal: true

module Legion
  module Extensions
    module CostScanner
      module Runners
        module Reporter
          def generate_report(limit: 10)
            top = Helpers::FindingsStore.top_by_savings(limit: limit)
            stats = Helpers::FindingsStore.stats

            { total_savings: stats[:total_savings],
              findings_count: stats[:total],
              by_type: stats[:by_type],
              top_findings: top,
              generated_at: Time.now }
          end

          def format_slack_blocks(report:)
            blocks = []
            savings = format('%.2f', report[:total_savings])

            blocks << { type: 'header', text: { type: 'plain_text', text: 'Weekly Cost Optimization Report' } }
            blocks << { type: 'section', text: { type: 'mrkdwn',
                                                 text: "*Total potential savings:* $#{savings}/month\n" \
                                                       "*Findings:* #{report[:findings_count]}" } }
            blocks << { type: 'divider' }

            (report[:top_findings] || []).each_with_index do |finding, i|
              blocks << { type: 'section', text: { type: 'mrkdwn',
                                                   text: "*#{i + 1}. #{finding[:resource_id]}* (#{finding[:finding_type]})\n" \
                                                         "Savings: $#{format('%.2f',
                                                                             finding[:estimated_monthly_savings] || 0)}/month\n" \
                                                         "#{finding[:recommendation]}" } }
            end

            blocks
          end

          def post_report(limit: 10)
            report = generate_report(limit: limit)
            format_slack_blocks(report: report)

            webhook = report_webhook
            if webhook && defined?(Legion::Extensions::Slack::Client)
              message = "Cost Optimization: $#{format('%.2f', report[:total_savings])}/month in savings identified"
              Legion::Extensions::Slack::Client.new.send_webhook(message: message, webhook: webhook)
            end

            { success: true, report: report }
          rescue StandardError => e
            { success: false, error: e.message }
          end

          private

          def report_webhook
            return nil unless defined?(Legion::Settings)

            config = Legion::Settings[:cost_scanner] || {}
            config[:slack_webhook]
          end
        end
      end
    end
  end
end
