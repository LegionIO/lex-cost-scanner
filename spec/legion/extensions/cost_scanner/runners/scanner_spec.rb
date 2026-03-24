# frozen_string_literal: true

RSpec.describe Legion::Extensions::CostScanner::Runners::Scanner do
  subject { Object.new.extend(described_class) }

  before { Legion::Extensions::CostScanner::Helpers::FindingsStore.reset! }

  describe '#scan_account' do
    let(:resources) do
      [{ resource_id: 'i-abc', resource_type: 'ec2', monthly_cost: 200.0,
         utilization: { cpu_avg: 2.0 } }]
    end

    before do
      allow(subject).to receive(:fetch_resources).and_return(resources)
    end

    it 'classifies and stores findings' do
      result = subject.scan_account(account_id: 'acc-1')
      expect(result[:success]).to be true
      expect(result[:scanned]).to eq(1)
      expect(result[:findings]).to be >= 0
    end
  end

  describe '#scan_all' do
    before do
      allow(Legion::Settings).to receive(:[]).with(:cost_scanner).and_return(
        { accounts: [{ id: 'acc-1', cloud: 'aws' }] }
      )
      allow(subject).to receive(:scan_account).and_return({ success: true, scanned: 5, findings: 2 })
    end

    it 'scans all configured accounts' do
      result = subject.scan_all
      expect(result[:accounts_scanned]).to eq(1)
    end
  end

  describe '#scan_stats' do
    it 'returns current findings statistics' do
      stats = subject.scan_stats
      expect(stats).to have_key(:total)
      expect(stats).to have_key(:total_savings)
    end
  end
end
