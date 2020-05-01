# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SimpleFlag do
  describe '#initialize' do
    it 'yields self to allow better setup' do
      expect { |b| described_class.new(&b) }.to yield_with_args(described_class)
    end

    it 'allows definition of features within the yielded block' do
      features = described_class.new do |feature|
        feature.define(:flag1)
        feature.define('flag2')
      end

      expect(features.flags.size).to eq 2
      expect(features.flags).to include :flag1, 'flag2'
    end
  end

  describe '#define' do
    let(:flag_result) { double('flag_result') }

    it 'defines feature flag' do
      subject.define(:flag)

      expect(subject.flags).to include :flag
    end

    it 'raises SimpleFlag::FlagAlreadyDefined when defines feature flag again' do
      subject.define(:flag)
      expect { subject.define(:flag) }.to raise_error(SimpleFlag::FlagAlreadyDefined)
    end

    it 'defines feature flag as block' do
      subject.define(:flag) { flag_result }

      expect(subject.active?(:flag)).to eq flag_result
    end

    it 'cannot define feature flag as proc' do
      expect {
        subject.define(:flag, proc { flag_result })
      }
      .to raise_error(ArgumentError, 'wrong number of arguments (given 2, expected 1)')
    end

    it 'cannot define feature flag as lambda' do
      expect {
        subject.define(:flag, -> { flag_result })
      }
      .to raise_error(ArgumentError, 'wrong number of arguments (given 2, expected 1)')
    end
  end

  describe '#redefine' do
    let(:flag_result) { double('flag_result') }

    it 'defines feature flag' do
      subject.redefine(:flag)

      expect(subject.flags).to include :flag
    end

    it 'does not raise error when define feature flag again' do
      subject.define(:flag)
      expect { subject.redefine(:flag) }.not_to raise_error
    end

    it 'defines feature flag as block' do
      subject.redefine(:flag) { flag_result }

      expect(subject.active?(:flag)).to eq flag_result
    end

    it 'cannot redefine feature flag as proc' do
      expect {
        subject.redefine(:flag, proc { flag_result })
      }
      .to raise_error(ArgumentError, 'wrong number of arguments (given 2, expected 1)')
    end

    it 'cannot redefine feature flag as lambda' do
      expect {
        subject.redefine(:flag, -> { flag_result })
      }
      .to raise_error(ArgumentError, 'wrong number of arguments (given 2, expected 1)')
    end
  end

  describe '#flags' do
    context 'when no flag is defined' do
      it 'returns empty array' do
        expect(subject.flags).to eq []
      end
    end

    context 'when flags are defined' do
      it 'contains defined flag names' do
        subject.define(:flag1)
        subject.define('flag2')

        expect(subject.flags.size).to eq 2
        expect(subject.flags).to include :flag1, 'flag2'
      end
    end
  end

  describe 'flag evaluation' do
    context 'when flag is defined with 1 argument' do
      before do
        subject.define(:flag) { |_a| 'a flag' }
      end

      it 'returns flag result when called with 1 argument' do
        expect(subject.active?(:flag, :a)).to eq 'a flag'
      end

      it 'raises FlagArgumentsMismatch when called with 0 arguments' do
        expect { subject.active?(:flag) }.to raise_error(SimpleFlag::FlagArgumentsMismatch)
      end

      it 'raises FlagArgumentsMismatch when called with 2 arguments' do
        expect { subject.active?(:flag, :a, :b) }.to raise_error(SimpleFlag::FlagArgumentsMismatch)
      end
    end

    context 'when flag is defined with 2 required and variable arguments' do
      before do
        subject.define(:flag) { |_a, _b, *_c| 'a flag' }
      end

      it 'raises FlagArgumentsMismatch when called with 0 arguments' do
        expect { subject.active?(:flag) }.to raise_error(SimpleFlag::FlagArgumentsMismatch)
      end

      it 'raises FlagArgumentsMismatch when called with 1 argument' do
        expect { subject.active?(:flag, :a) }.to raise_error(SimpleFlag::FlagArgumentsMismatch)
      end

      it 'returns flag result when called with 2 arguments' do
        expect(subject.active?(:flag, :a, :b)).to eq 'a flag'
      end

      it 'returns flag result when called with 3 arguments' do
        expect(subject.active?(:flag, :a, :b, :c)).to eq 'a flag'
      end
    end
  end

  %i[enabled? active? on?].each do |enabled_method|
    describe "##{enabled_method}" do
      context 'when flag is truthy' do
        it 'returns true' do
          subject.define(:flag) { true }

          expect(subject.public_send(enabled_method, :flag)).to eq true
        end
      end

      context 'when flag is falsy' do
        it 'returns false' do
          subject.define(:flag) { false }

          expect(subject.public_send(enabled_method, :flag)).to eq false
        end
      end

      context 'when flag is not defined' do
        it 'returns false' do
          expect(subject.public_send(enabled_method, :flag)).to eq false
        end
      end
    end
  end

  %i[disabled? inactive? off?].each do |enabled_method|
    describe "##{enabled_method}" do
      context 'when flag is truthy' do
        it 'returns false' do
          subject.define(:flag) { true }

          expect(subject.public_send(enabled_method, :flag)).to eq false
        end
      end

      context 'when flag is falsy' do
        it 'returns true' do
          subject.define(:flag) { false }

          expect(subject.public_send(enabled_method, :flag)).to eq true
        end
      end

      context 'when flag is not defined' do
        it 'returns true' do
          expect(subject.public_send(enabled_method, :flag)).to eq true
        end
      end
    end
  end

  describe '#presence' do
    context 'when flag is truthy' do
      it 'returns true' do
        subject.define(:flag) { true }

        expect(subject.presence(:flag)).to eq true
      end
    end

    context 'when flag is falsy' do
      it 'returns nil' do
        subject.define(:flag) { false }

        expect(subject.presence(:flag)).to eq nil
      end
    end
  end

  describe '#with &block' do
    context 'when flag is truthy' do
      it 'calls the block' do
        subject.define(:flag) { true }

        probe = -> {}
        allow(probe).to receive(:call)

        subject.with(:flag, &probe)

        expect(probe).to have_received(:call)
      end
    end

    context 'when flag is falsy' do
      it 'does not call the block' do
        subject.define(:flag) { false }

        probe = -> {}
        allow(probe).to receive(:call)

        subject.with(:flag, &probe)

        expect(probe).not_to have_received(:call)
      end
    end
  end

  describe '#env?' do
    let(:features) { described_class.new(env: 'aloha') }

    it 'is true when #env and argument are equal' do
      expect(features.env?('aloha')).to be true
    end

    it 'is false when #env and argument are not equal' do
      expect(features.env?('halo')).to be false
    end

    it 'accepts both single and multiple argument' do
      expect(features.env?('aloha')).to be true
      expect(features.env?('halo', 'aloha')).to be true
    end

    it 'accepts both symbols and strings' do
      expect(features.env?('aloha')).to be true
      expect(features.env?(:aloha)).to be true
    end
  end

  describe 'use of #env within the #define block' do
    it 'is accessible' do
      features = described_class.new(env: 'aloha') do |f|
        f.define(:flag) { f.env }
      end

      expect(features.active?(:flag)).to eq 'aloha'
    end
  end

  describe '#flag?' do
    it 'returns true if flag was defined' do
      features = described_class.new do |f|
        f.define(:flag) { false }
      end

      expect(features.flag?(:flag)).to eq true
    end

    it 'returns false if flag wasn\'t defined' do
      features = described_class.new do |f|
      end

      expect(features.flag?(:flag)).to eq false
    end
  end

  describe '#override' do
    it 'overrides defined flag with result' do
      features = described_class.new do |f|
        f.define(:flag) { |_a| false }
      end

      features.override(:flag, true)

      expect(features).to be_active(:flag)
    end

    it 'overrides defined flag with block of same arity' do
      features = described_class.new do |f|
        f.define(:flag) { |_a, _b| 'original' }
      end

      features.override(:flag) { |_a, _b| 'overridden' }

      expect(features.active?(:flag, :a, :b)).to eq 'overridden'
    end

    it 'raises exception when overriding defined flag with block of different arity' do
      features = described_class.new do |f|
        f.define(:flag) { |_a, _b| false }
      end

      expect { features.override(:flag) { |_a| 'overridden' } }.to raise_error(SimpleFlag::FlagArgumentsMismatch)
    end

    it 'raises exception when trying to override non-existing flag' do
      features = described_class.new do |f|
      end

      expect { features.override(:flag, true) }.to raise_error(SimpleFlag::FlagNotDefined)
    end

    it 'raises exception when trying to override already overridden flag' do
      features = described_class.new do |f|
        f.define(:flag) { false }
      end

      features.override(:flag, true)

      expect { features.override(:flag, true) }.to raise_error(SimpleFlag::FlagAlreadyDefined)
    end
  end

  describe '#reset_override' do
    it 'reset overridden flag' do
      features = described_class.new do |f|
        f.define(:flag) { false }
        f.override(:flag, true)
      end

      features.reset_override(:flag)

      expect(features).not_to be_active(:flag)
    end

    it 'raises exception when flag was not overridden' do
      features = described_class.new do |f|
        f.define(:flag) { false }
      end

      expect { features.reset_override(:flag) }.to raise_error(SimpleFlag::FlagNotOverridden)
    end
  end

  describe '#reset_all_overrides' do
    it 'reset overridden flag' do
      features = described_class.new do |f|
        f.define(:flag1) { false }
        f.define(:flag2) { true }
        f.override(:flag1, true)
        f.override(:flag2, false)
      end

      features.reset_all_overrides

      expect(features).not_to be_active(:flag1)
      expect(features).to be_active(:flag2)
    end
  end

  describe '#override_with &block' do
    it 'overrides defined flag in a block and return to original behaviour immediately' do
      features = described_class.new do |f|
        f.define(:flag) { false }
      end

      features.override_with(:flag, true) do
        expect(features).to be_active(:flag)
      end

      expect(features).not_to be_active(:flag)
    end
  end

  describe '#overridden?' do
    it 'returns true if flag was overridden' do
      features = described_class.new do |f|
        f.define(:flag) { false }
        f.override(:flag, true)
      end

      expect(features.overridden?(:flag)).to eq true
    end

    it 'returns false if flag wasn\'t overridden' do
      features = described_class.new do |f|
        f.define(:flag) { false }
      end

      expect(features.overridden?(:flag)).to eq false
    end
  end
end
