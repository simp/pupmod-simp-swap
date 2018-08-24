require 'spec_helper_acceptance'

test_name 'swap class'

describe 'swap class' do
  let(:manifest) {
    <<-EOS
      include 'swap'
    EOS
  }

  context 'default parameters' do
    it 'should work with no errors' do
      apply_manifest(manifest, :catch_failures => true)
    end

    it 'should be idempotent' do
      apply_manifest(manifest, :catch_changes => true)
    end

  end
end
