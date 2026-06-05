require 'open-uri'

class DataCentreIps
  # This CSV has a range per row, with the starting IP as the first column and the ending IP as the second. It's
  # non-overlapping and sorted. It only contains IPV4 addresses.
  DATA_SOURCE_IPCAT = URI.parse('https://raw.githubusercontent.com/growlfm/ipcat/refs/heads/main/datacenters.csv')

  # This CSV has a range per row and supports IPV4 and IPV6, but it's not limited to data centres. We need to manually
  # identify data centres based on ASN.
  DATA_SOURCE_DBIP = URI.parse('https://download.db-ip.com/free/dbip-asn-lite-2026-05.csv.gz')

  DATA_CENTRE_ASN_NUMBERS = [
    '16509', # Amazon.com, Inc.
    '18450', # WebNX, Inc.
    '20473', # ClearDocks LLC
    '33763', # Paratus Telecommunications Limited
  ].freeze

  def load_ip_ranges_ipcat(force: false)
    @load_ip_ranges_ipcat ||= Rails.cache.fetch('data_centre_ips_ipcat', force:, expires_in: 1.day) do
      Net::HTTP.get(DATA_SOURCE_IPCAT)
               .split("\n")
               .map { |row| row.split(',')[0..1].map { |ip| IPAddr.new(ip).to_i } }
    end
  end

  def load_ip_ranges_dbip(force: false)
    @load_ip_ranges_dbip ||= Rails.cache.fetch('data_centre_ips_dbip', force:, expires_in: 1.day) do
      Zlib::GzipReader.wrap(DATA_SOURCE_DBIP.open) do |gz|
        gz.read.each_line.filter_map do |line|
          ip_start, ip_end, asn_number, _asn_name = line.split(',')
          next unless DATA_CENTRE_ASN_NUMBERS.include?(asn_number)

          [IPAddr.new(ip_start).to_i, IPAddr.new(ip_end).to_i]
        end
      end
    end
  end

  def data_centre?(ip)
    ip_int = IPAddr.new(ip).to_i
    data_centre_according_to_ipcat?(ip_int) || data_centre_according_to_dbip?(ip_int)
  end

  def data_centre_according_to_ipcat?(ip_int)
    # Find the first one where we're before the end of the range.
    first_range = load_ip_ranges_ipcat.find { |range| ip_int <= range[1] }
    return false unless first_range

    # Check the start of the range.
    ip_int >= first_range[0]
  end

  def data_centre_according_to_dbip?(ip_int)
    load_ip_ranges_dbip.any? { |ip_start, ip_end| ip_int.between?(ip_start, ip_end) }
  end

  def analyze_ips_with_dbip(ips)
    dbip_data = nil

    Zlib::GzipReader.wrap(DATA_SOURCE_DBIP.open) do |gz|
      dbip_data = gz.read.each_line.map do |line|
        ip_start, ip_end, asn_number, asn_name = line.split(',')
        [IPAddr.new(ip_start).to_i, IPAddr.new(ip_end).to_i, asn_number, asn_name]
      end
    end

    ips.map do |ip|
      ip_int = IPAddr.new(ip).to_i
      matching_entry = dbip_data.find { |ip_start, ip_end, _asn_number, _asn_name| ip_int.between?(ip_start, ip_end) }

      if matching_entry
        {
          ip: ip,
          asn_number: matching_entry[2],
          asn_name: matching_entry[3].strip,
        }
      else
        {
          ip: ip,
          asn_number: nil,
          asn_name: nil,
        }
      end
    end
  end
end
