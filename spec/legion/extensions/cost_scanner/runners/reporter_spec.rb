# frozen_string_literal: true

RSpec.describe Legion::Extensions::CostScanner::Runners::Reporter do
  subject { Object.new.extend(described_class) }

  before { Legion::Extensions::CostScanner::Helpers::FindingsStore.reset! }

  describe '#generate_report' do
    before do
      Legion::Extensions::CostScanner::Helpers::FindingsStore.record(
        account_id: 'acc-1', resource_id: 'i-abc', resource_type: 'ec2',
        finding_type: :idle, severity: :high, monthly_cost: 200.0,
        estimated_monthly_savings: 200.0, recommendation: 'Terminate'
      )
    end

    it 'generates a report hash with summary and findings' do
      report = subject.generate_report
      expect(report[:total_savings]).to eq(200.0)
      expect(report[:findings_count]).to eq(1)
      expect(report[:top_findings].size).to eq(1)
    end
  end

  describe '#format_slack_blocks' do
    it 'returns an array of Slack Block Kit blocks' do
      report = { total_savings: 500.0, findings_count: 3,
                 top_findings: [{ resource_id: 'i-abc', finding_type: :idle,
                                  estimated_monthly_savings: 200.0, recommendation: 'Stop it' }] }
      blocks = subject.format_slack_blocks(report: report)
      expect(blocks).to be_an(Array)
      expect(blocks.first[:type]).to eq('header')
    end
  end

  describe '#post_report' do
    it 'returns success even without Slack configured' do
      result = subject.post_report
      expect(result[:success]).to be true
    end
  end
end
