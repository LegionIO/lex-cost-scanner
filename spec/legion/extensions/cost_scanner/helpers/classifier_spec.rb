# frozen_string_literal: true

RSpec.describe Legion::Extensions::CostScanner::Helpers::Classifier do
  describe '.classify' do
    context 'when LLM is available' do
      before do
        stub_const('Legion::LLM', double('LLM', started?: true))
        allow(Legion::LLM).to receive(:chat).and_return(
          '{"finding_type":"idle","severity":"high","estimated_monthly_savings":150.0,"recommendation":"Terminate instance"}'
        )
      end

      it 'returns parsed classification' do
        result = described_class.classify(
          resource_id: 'i-abc123', resource_type: 'ec2',
          monthly_cost: 200.0, utilization: { cpu_avg: 2.0 }
        )
        expect(result[:finding_type]).to eq(:idle)
        expect(result[:estimated_monthly_savings]).to eq(150.0)
      end
    end

    context 'when LLM is not available' do
      it 'uses rule-based classification' do
        result = described_class.classify(
          resource_id: 'i-abc123', resource_type: 'ec2',
          monthly_cost: 200.0, utilization: { cpu_avg: 2.0 }
        )
        expect(result[:finding_type]).to eq(:idle)
        expect(result[:method]).to eq(:rule_based)
      end
    end
  end

  describe '.rule_based_classify' do
    it 'classifies < 5% CPU as idle' do
      result = described_class.rule_based_classify(utilization: { cpu_avg: 3.0 }, monthly_cost: 100.0)
      expect(result[:finding_type]).to eq(:idle)
    end

    it 'classifies 5-20% CPU as oversized' do
      result = described_class.rule_based_classify(utilization: { cpu_avg: 12.0 }, monthly_cost: 100.0)
      expect(result[:finding_type]).to eq(:oversized)
    end

    it 'classifies >= 20% CPU as none' do
      result = described_class.rule_based_classify(utilization: { cpu_avg: 45.0 }, monthly_cost: 100.0)
      expect(result[:finding_type]).to eq(:none)
    end
  end
end
