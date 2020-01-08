require 'spec_helper_acceptance'

test_name 'swap class'

describe 'swap class' do
  let(:manifest) {
    <<-EOS
      include 'swap'
    EOS
  }

  hosts.each do |host|
    context 'default parameters' do
      it 'should work with no errors' do
        apply_manifest_on(host, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(host, manifest, :catch_changes => true)
      end

      it 'should set the system swappiness to 60' do
        on(host, 'sysctl vm.swappiness=20')

        apply_manifest_on(host, manifest, :catch_failures => true)

        result = on(host, 'sysctl -n vm.swappiness').stdout.strip.to_i

        expect(result).to eq(60)
      end
    end
  end
end
