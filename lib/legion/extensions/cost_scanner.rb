# frozen_string_literal: true

require_relative 'cost_scanner/version'
require_relative 'cost_scanner/helpers/constants'
require_relative 'cost_scanner/helpers/classifier'
require_relative 'cost_scanner/helpers/findings_store'
require_relative 'cost_scanner/runners/scanner'
require_relative 'cost_scanner/runners/reporter'

if defined?(Legion::Extensions::Actors::Every)
  require_relative 'cost_scanner/actors/weekly_scan'
end

module Legion
  module Extensions
    module CostScanner
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
