class DataCentreIps
  # This CSV has a range per row, with the starting IP as the first column and the ending IP as the second. It's
  # non-overlapping and sorted.
  DATA_SOURCE = URI.parse('https://raw.githubusercontent.com/growlfm/ipcat/refs/heads/main/datacenters.csv')

  def load_ip_ranges(force: false)
    @load_ip_ranges ||= Rails.cache.fetch('data_centre_ips', force:, expires_in: 1.day) do
      Net::HTTP.get(DATA_SOURCE)
               .split("\n")
               .map { |row| row.split(',')[0..1].map { |ip| IPAddr.new(ip).to_i } }
    end
  end

  def data_centre?(ip)
    ip_int = IPAddr.new(ip).to_i

    # Find the first one where we're before the end of the range.
    first_range = load_ip_ranges.find { |range| ip_int <= range[1] }
    return false unless first_range

    # Check the start of the range.
    ip_int >= first_range[0]
  end
end
