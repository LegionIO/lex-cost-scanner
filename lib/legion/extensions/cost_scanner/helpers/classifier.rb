# frozen_string_literal: true

module Legion
  module Extensions
    module CostScanner
      module Helpers
        module Classifier
          extend Constants

          CLASSIFY_PROMPT = <<~PROMPT
            Analyze this cloud resource and classify it. Reply with ONLY valid JSON:
            {"finding_type":"idle|oversized|unused_reservation|orphaned_storage|rightsizing|none",
             "severity":"critical|high|medium|low|info",
             "estimated_monthly_savings":0.0,
             "recommendation":"one sentence action"}

            Resource: %<resource_type>s %<resource_id>s
            Monthly cost: $%<monthly_cost>.2f
            Utilization: %<utilization>s
          PROMPT

          module_function

          def classify(resource_id:, resource_type:, monthly_cost:, utilization:)
            if llm_available?
              llm_classify(resource_id: resource_id, resource_type: resource_type,
                           monthly_cost: monthly_cost, utilization: utilization)
            else
              result = rule_based_classify(utilization: utilization, monthly_cost: monthly_cost)
              result.merge(resource_id: resource_id, resource_type: resource_type, method: :rule_based)
            end
          end

          def rule_based_classify(utilization:, monthly_cost:)
            cpu = utilization[:cpu_avg] || 100.0

            if cpu < Constants::IDLE_CPU_THRESHOLD
              { finding_type: :idle, severity: :high,
                estimated_monthly_savings: monthly_cost,
                recommendation: 'Terminate or stop idle resource' }
            elsif cpu < Constants::OVERSIZED_CPU_THRESHOLD
              savings = monthly_cost * 0.4
              { finding_type: :oversized, severity: :medium,
                estimated_monthly_savings: savings,
                recommendation: 'Rightsize to smaller instance type' }
            else
              { finding_type: :none, severity: :info,
                estimated_monthly_savings: 0.0,
                recommendation: 'Resource is adequately utilized' }
            end
          end

          def llm_classify(resource_id:, resource_type:, monthly_cost:, utilization:)
            prompt = format(CLASSIFY_PROMPT, resource_type: resource_type, resource_id: resource_id,
                                             monthly_cost: monthly_cost, utilization: utilization.inspect)
            response = Legion::LLM.chat(
              message: prompt,
              caller: { extension: 'lex-cost-scanner', function: 'classify' }
            )
            parsed = Legion::JSON.load(response)
            parsed[:finding_type] = parsed[:finding_type].to_sym
            parsed[:severity] = parsed[:severity].to_sym
            parsed.merge(resource_id: resource_id, resource_type: resource_type, method: :llm)
          rescue StandardError
            result = rule_based_classify(utilization: utilization, monthly_cost: monthly_cost)
            result.merge(resource_id: resource_id, resource_type: resource_type, method: :rule_based_fallback)
          end

          def llm_available?
            defined?(Legion::LLM) && Legion::LLM.respond_to?(:started?) && Legion::LLM.started?
          end
        end
      end
    end
  end
end
