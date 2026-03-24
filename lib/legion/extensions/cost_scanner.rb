# frozen_string_literal: true

require_relative 'cost_scanner/version'

module Legion
  module Extensions
    module CostScanner
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
