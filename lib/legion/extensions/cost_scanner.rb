# frozen_string_literal: true

require_relative 'cost_scanner/version'
require_relative 'cost_scanner/helpers/constants'
require_relative 'cost_scanner/helpers/classifier'

module Legion
  module Extensions
    module CostScanner
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
