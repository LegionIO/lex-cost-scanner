# frozen_string_literal: true

RSpec.describe Legion::Extensions::CostScanner::Helpers::FindingsStore do
  before { described_class.reset! }

  let(:finding) do
    { account_id: 'acc-1', resource_id: 'i-abc', resource_type: 'ec2',
      finding_type: :idle, severity: :high, monthly_cost: 200.0,
      estimated_monthly_savings: 200.0, recommendation: 'Terminate' }
  end

  describe '.record' do
    it 'stores a new finding' do
      result = described_class.record(**finding)
      expect(result[:new]).to be true
    end

    it 'deduplicates identical findings' do
      described_class.record(**finding)
      result = described_class.record(**finding)
      expect(result[:new]).to be false
    end

    it 'updates last_seen on duplicate' do
      described_class.record(**finding)
      sleep 0.01
      described_class.record(**finding)
      stored = described_class.all.first
      expect(stored[:last_seen]).to be > stored[:first_seen]
    end
  end

  describe '.new_since' do
    it 'returns findings first seen after the given time' do
      described_class.record(**finding)
      expect(described_class.new_since(Time.now - 60).size).to eq(1)
      expect(described_class.new_since(Time.now + 60).size).to eq(0)
    end
  end

  describe '.total_savings' do
    it 'sums estimated savings across all findings' do
      described_class.record(**finding)
      described_class.record(**finding, resource_id: 'i-def', estimated_monthly_savings: 100.0)
      expect(described_class.total_savings).to eq(300.0)
    end
  end

  describe '.top_by_savings' do
    it 'returns findings sorted by savings descending' do
      described_class.record(**finding, resource_id: 'i-1', estimated_monthly_savings: 50.0)
      described_class.record(**finding, resource_id: 'i-2', estimated_monthly_savings: 300.0)
      described_class.record(**finding, resource_id: 'i-3', estimated_monthly_savings: 150.0)
      top = described_class.top_by_savings(limit: 2)
      expect(top.map { |f| f[:resource_id] }).to eq(%w[i-2 i-3])
    end
  end
end
