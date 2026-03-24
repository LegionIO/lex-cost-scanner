# frozen_string_literal: true

module Legion
  module Extensions
    module CostScanner
      module Runners
        module Scanner
          def scan_all
            accounts = scanner_config[:accounts] || []
            results = accounts.map { |acct| scan_account(account_id: acct[:id], cloud: acct[:cloud]) }

            { success: true, accounts_scanned: results.size, results: results,
              total_savings: Helpers::FindingsStore.total_savings }
          end

          def scan_account(account_id:, cloud: 'aws')
            resources = fetch_resources(account_id: account_id, cloud: cloud)
            findings_count = 0

            resources.each do |resource|
              next if (resource[:monthly_cost] || 0) < Helpers::Constants::MIN_MONTHLY_COST

              classification = Helpers::Classifier.classify(
                resource_id: resource[:resource_id],
                resource_type: resource[:resource_type],
                monthly_cost: resource[:monthly_cost],
                utilization: resource[:utilization] || {}
              )

              next if classification[:finding_type] == :none

              result = Helpers::FindingsStore.record(
                account_id: account_id,
                resource_id: resource[:resource_id],
                resource_type: resource[:resource_type],
                finding_type: classification[:finding_type],
                severity: classification[:severity],
                monthly_cost: resource[:monthly_cost],
                estimated_monthly_savings: classification[:estimated_monthly_savings],
                recommendation: classification[:recommendation]
              )
              findings_count += 1 if result[:new]
            end

            { success: true, account_id: account_id, scanned: resources.size,
              findings: findings_count }
          rescue StandardError => e
            { success: false, account_id: account_id, error: e.message }
          end

          def scan_stats
            Helpers::FindingsStore.stats
          end

          private

          def scanner_config
            return {} unless defined?(Legion::Settings)

            Legion::Settings[:cost_scanner] || {}
          end

          def fetch_resources(account_id:, cloud: 'aws')
            return [] unless defined?(Legion::Extensions::Http::Client)

            []
          end
        end
      end
    end
  end
end
