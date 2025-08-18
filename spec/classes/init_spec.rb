require 'spec_helper'

describe 'swap' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        context 'with default parameters' do
          it { is_expected.to create_sysctl('vm.swappiness').with_value('60') }
          it { is_expected.not_to create_file('/usr/local/sbin/dynamic_swappiness.rb') }
          it { is_expected.to create_cron('dynamic_swappiness').with_ensure('absent') }
        end

        context 'with dynamic_script => true' do
          context 'with default parameters' do
            let(:params) { { dynamic_script: true, } }
            let(:content) { File.read('spec/expected/dynamic_swappiness.rb') }

            it { is_expected.to create_file('/usr/local/sbin/dynamic_swappiness.rb').with_content(content) }
            it {
              is_expected.to create_cron('dynamic_swappiness')
                .with_command('/usr/local/sbin/dynamic_swappiness.rb')
            }
            it { is_expected.not_to create_sysctl('vm.swappiness') }
          end

          context 'with different template parameters' do
            let(:content) { File.read('spec/expected/dynamic_swappiness_off_default.rb') }
            let(:params) do
              {
                dynamic_script: true,
                cron_step: 10,
                maximum: 45,
                median: 25,
                minimum: 15,
                min_swappiness: 3,
                low_swappiness: 18,
                high_swappiness: 48,
                max_swappiness: 88,
              }
            end

            it { is_expected.to create_file('/usr/local/sbin/dynamic_swappiness.rb').with_content(content) }
          end
        end
      end
    end
  end
end
