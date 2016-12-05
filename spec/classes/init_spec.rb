require 'spec_helper'

describe 'swap' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          let(:content) { File.read('spec/expected/dynamic_swappiness.rb') }
          it { is_expected.to create_file('/usr/local/sbin/dynamic_swappiness.rb').with_content(content) }
          it { is_expected.to create_cron('dynamic_swappiness') }
          it { is_expected.not_to create_sysctl('vm.swappiness') }
        end

        context 'with different template parameters' do
          let(:content) { File.read('spec/expected/dynamic_swappiness_off_default.rb') }
          let(:params) {{
            :max_swappiness => 70,
            :maximum        => 80
          }}
          it { is_expected.to create_file('/usr/local/sbin/dynamic_swappiness.rb').with_content(content) }
        end

        context 'with dynamic_script => false' do
          let(:params) {{
            :dynamic_script => false,
            :swappiness     => 10
          }}
          it { is_expected.not_to create_file('/usr/local/sbin/dynamic_swappiness.rb') }
          it { is_expected.to create_cron('dynamic_swappiness').with(:ensure => 'absent') }
          it { is_expected.to create_sysctl('vm.swappiness').with_value('10') }
        end

      end
    end
  end
end
