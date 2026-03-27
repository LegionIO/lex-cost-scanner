# frozen_string_literal: true

module Legion
  module Extensions
    module CostScanner
      module Actor
        class WeeklyScan < Legion::Extensions::Actors::Every
          def time
            604_800
          end

          def runner_class
            'Legion::Extensions::CostScanner::Runners::Scanner'
          end

          def runner_function
            'scan_all'
          end

          def run_now?
            false
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end

          def use_runner?
            false
          end
        end
      end
    end
  end
end
