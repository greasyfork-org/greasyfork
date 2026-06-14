require 'test_helper'

class DataCentreIpTest < ActiveSupport::TestCase
  setup do
    @data_centre_ips = DataCentreIps.new
  end

  test 'data_centre_according_to_ipcat? ipv4 positive' do
    assert @data_centre_ips.data_centre_according_to_dbip?(IPAddr.new('1.178.174.0').to_i)
  end

  test 'data_centre_according_to_ipcat? ipv4 negative' do
    assert_not @data_centre_ips.data_centre_according_to_dbip?(IPAddr.new('123.4.5.6').to_i)
  end

  test 'data_centre_according_to_dbip? ipv4 positive' do
    assert @data_centre_ips.data_centre_according_to_dbip?(IPAddr.new('1.178.174.0').to_i)
  end

  test 'data_centre_according_to_dbip? ipv4 negative' do
    assert_not @data_centre_ips.data_centre_according_to_dbip?(IPAddr.new('123.4.5.6').to_i)
  end

  test 'data_centre_according_to_dbip? ipv6 positive' do
    assert @data_centre_ips.data_centre_according_to_dbip?(IPAddr.new('2001:04f8:000b:0000:0000:0000:0000:0000').to_i)
  end

  test 'data_centre_according_to_dbip? ipv6 negative' do
    assert_not @data_centre_ips.data_centre_according_to_dbip?(IPAddr.new('2001:db8::2').to_i)
  end

  test 'analyze_ips_with_dbip' do
    results = @data_centre_ips.analyze_ips_with_dbip(['1.178.174.0', '2001:04f8:000b:0000:0000:0000:0000:0000'])
    assert_equal '16509', results[0][:asn_number]
    assert_equal '16509', results[1][:asn_number]
  end
end
