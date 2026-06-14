require 'open-uri'

class DataCentreIps
  # This CSV has a range per row, with the starting IP as the first column and the ending IP as the second. It's
  # non-overlapping and sorted. It only contains IPV4 addresses.
  DATA_SOURCE_IPCAT = URI.parse('https://raw.githubusercontent.com/growlfm/ipcat/refs/heads/main/datacenters.csv')

  # This CSV has a range per row and supports IPV4 and IPV6, but it's not limited to data centres. We need to manually
  # identify data centres based on ASN.
  DATA_SOURCE_DBIP = URI.parse('https://download.db-ip.com/free/dbip-asn-lite-2026-05.csv.gz')

  DATA_CENTRE_ASN_NUMBERS = [
    '8075',  # Microsoft Corporation
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
               .sort
    end
  end

  def load_ip_ranges_dbip(force: false)
    @load_ip_ranges_dbip ||= Rails.cache.fetch('data_centre_ips_dbip', force:, expires_in: 1.day) do
      Zlib::GzipReader.wrap(DATA_SOURCE_DBIP.open) do |gz|
        gz.read.each_line.filter_map do |line|
          ip_start, ip_end, asn_number, _asn_name = line.split(',')
          next unless DATA_CENTRE_ASN_NUMBERS.include?(asn_number)

          [IPAddr.new(ip_start).to_i, IPAddr.new(ip_end).to_i]
        end.sort
      end
    end
  end

  def data_centre?(ip)
    ip_int = IPAddr.new(ip).to_i
    data_centre_according_to_ipcat?(ip_int) || data_centre_according_to_dbip?(ip_int)
  end

  def data_centre_according_to_ipcat?(ip_int)
    binary_ip_search(load_ip_ranges_ipcat, ip_int)
  end

  def data_centre_according_to_dbip?(ip_int)
    binary_ip_search(load_ip_ranges_dbip, ip_int)
  end

  def analyze_ips_with_dbip(ips)
    dbip_data = nil

    Zlib::GzipReader.wrap(DATA_SOURCE_DBIP.open) do |gz|
      dbip_data = gz.read.each_line.map do |line|
        ip_start, ip_end, asn_number, asn_name = line.split(',')
        [IPAddr.new(ip_start).to_i, IPAddr.new(ip_end).to_i, asn_number, asn_name]
      end.sort
    end

    ips.map do |ip|
      ip_int = IPAddr.new(ip).to_i
      match = binary_ip_search(dbip_data, ip_int)
      if match
        {
          ip: ip,
          asn_number: match[2],
          asn_name: match[3].strip,
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

  # search_array needs to be an Array of Arrays whose first two elements are the start and end of the IP range (as integers), and it needs to be sorted by the starting IP.
  def binary_ip_search(search_array, ip_int)
    # With bsearch_index, we need to ensure the comparison's results for the rule is all falses first.
    # So we find the first range whose start is greater than the IP, and then check the previous one for an actual match.
    potential_match_index = search_array.bsearch_index { |ip_start, _ip_end| ip_int < ip_start }
    return nil unless potential_match_index && potential_match_index > 0

    potential_match = search_array[potential_match_index - 1]
    return potential_match if potential_match && ip_int.between?(potential_match[0], potential_match[1])

    nil
  end
end
