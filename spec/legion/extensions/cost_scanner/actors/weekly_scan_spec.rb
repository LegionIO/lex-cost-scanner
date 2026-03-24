# frozen_string_literal: true

RSpec.describe Legion::Extensions::CostScanner::Actors::WeeklyScan do
  subject { described_class.new }

  it 'runs every 604800 seconds (1 week)' do
    expect(subject.time).to eq(604_800)
  end

  it 'targets the scanner runner class' do
    expect(subject.runner_class).to eq('Legion::Extensions::CostScanner::Runners::Scanner')
  end

  it 'calls scan_all as the runner function' do
    expect(subject.runner_function).to eq('scan_all')
  end

  it 'does not run immediately on boot' do
    expect(subject.run_now?).to be false
  end

  it 'disables subtask checking' do
    expect(subject.check_subtask?).to be false
  end
end
