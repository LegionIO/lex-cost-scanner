# frozen_string_literal: true

module Legion
  module Extensions
    module CostScanner
      module Helpers
        module Constants
          FINDING_TYPES = %i[idle oversized unused_reservation orphaned_storage rightsizing none].freeze
          SEVERITIES = %i[critical high medium low info].freeze
          IDLE_CPU_THRESHOLD = 5.0
          OVERSIZED_CPU_THRESHOLD = 20.0
          MIN_MONTHLY_COST = 50.0
        end
      end
    end
  end
end
