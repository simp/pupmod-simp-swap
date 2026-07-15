require 'spec_helper_acceptance'

test_name 'swap class'

describe 'swap class' do
  let(:manifest) do
    <<-EOS
      include 'swap'
    EOS
  end

  hosts.each do |host|
    # On a fresh node the Sicura console previews this module with
    # `puppet apply --noop`, which must not error. Exercise that here before
    # the real applies below. No package-removal step: swap manages sysctl
    # state only, so noop-only is the representative check (as with fips).
    context 'in noop mode from a clean state' do
      it 'applies without errors in noop mode' do
        apply_manifest_on(host, manifest, catch_failures: true, noop: true)
      end
    end

    context 'default parameters' do
      it 'works with no errors' do
        apply_manifest_on(host, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(host, manifest, catch_changes: true)
      end

      it 'sets the system swappiness to 60' do
        on(host, 'sysctl vm.swappiness=20')

        apply_manifest_on(host, manifest, catch_failures: true)

        result = on(host, 'sysctl -n vm.swappiness').stdout.strip.to_i

        expect(result).to eq(60)
      end
    end
  end
end
