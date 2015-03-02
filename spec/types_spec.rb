require 'aether/types'

RSpec.describe 'salesforce to redshift value conversions' do
  describe 'int conversion' do
    it 'handles nil' do
      bigint = Aether::RSTypes::Bigint.new
      expect(bigint.transform_from_salesforce(nil)).to be_nil
    end

    it 'handles floats' do
      bigint = Aether::RSTypes::Bigint.new
      expect(bigint.transform_from_salesforce('1.0')).to eq(1)
    end
  end

  describe 'datetime conversion' do
    it 'handles empty string' do
      timestamp = Aether::RSTypes::Timestamp.new
      expect(timestamp.transform_from_salesforce('')).to be_nil
    end

    it 'handles salesforce format' do
      timestamp = Aether::RSTypes::Timestamp.new
      salesforce_timestamp = '2014-07-29T18:23:36.000Z'
      redshift_timestamp = timestamp.transform_from_salesforce(salesforce_timestamp)
      expect(redshift_timestamp).to eq('2014-07-29 18:23:36.000000')
    end
  end
end
