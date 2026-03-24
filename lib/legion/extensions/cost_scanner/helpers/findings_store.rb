# frozen_string_literal: true

module Legion
  module Extensions
    module CostScanner
      module Helpers
        module FindingsStore
          @mutex = Mutex.new
          @findings = {}

          module_function

          def dedup_key(account_id:, resource_id:, finding_type:, **)
            "#{account_id}:#{resource_id}:#{finding_type}"
          end

          def record(account_id:, resource_id:, finding_type:, **attrs)
            key = dedup_key(account_id: account_id, resource_id: resource_id, finding_type: finding_type)
            now = Time.now

            @mutex.synchronize do
              if @findings.key?(key)
                @findings[key][:last_seen] = now
                @findings[key][:scan_count] += 1
                return { new: false, key: key }
              end

              @findings[key] = {
                account_id: account_id, resource_id: resource_id, finding_type: finding_type,
                first_seen: now, last_seen: now, scan_count: 1, status: :new
              }.merge(attrs)
              { new: true, key: key }
            end
          end

          def all
            @mutex.synchronize { @findings.values.dup }
          end

          def new_since(time)
            @mutex.synchronize { @findings.values.select { |f| f[:first_seen] >= time } }
          end

          def total_savings
            @mutex.synchronize { @findings.values.sum { |f| f[:estimated_monthly_savings] || 0.0 } }
          end

          def top_by_savings(limit: 10)
            @mutex.synchronize do
              @findings.values
                       .sort_by { |f| -(f[:estimated_monthly_savings] || 0.0) }
                       .first(limit)
            end
          end

          def stats
            @mutex.synchronize do
              { total: @findings.size,
                total_savings: @findings.values.sum { |f| f[:estimated_monthly_savings] || 0.0 },
                by_type: @findings.values.group_by { |f| f[:finding_type] }.transform_values(&:size) }
            end
          end

          def reset!
            @mutex.synchronize { @findings.clear }
          end
        end
      end
    end
  end
end
