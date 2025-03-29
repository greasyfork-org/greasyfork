require 'digest'
require 'open-uri'

class Subresource < ApplicationRecord
  has_many :script_subresource_usages
  has_many :scripts, through: :script_subresource_usages
  has_many :subresource_integrity_hashes, dependent: :destroy

  scope :with_integrity_hash_usages, -> { joins(:script_subresource_usages).where.not(script_subresource_usages: { integrity_hash: nil }) }

  def calculate_hashes!
    now = Time.zone.now

    update(last_attempt_at: now)

    begin
      contents = download
    rescue OpenURI::HTTPError, Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET, Socket::ResolutionError, Zlib::DataError => e
      Rails.logger.warn(e)
      return
    end

    changed = false

    [
      [->(c) { Digest::SHA1.hexdigest(c) }, { algorithm: 'sha1', encoding: 'hex' }],
      [->(c) { Digest::SHA1.base64digest(c) }, { algorithm: 'sha1', encoding: 'base64' }],
      [->(c) { Digest::SHA2.hexdigest(c) }, { algorithm: 'sha256', encoding: 'hex' }],
      [->(c) { Digest::SHA2.base64digest(c) }, { algorithm: 'sha256', encoding: 'base64' }],
      [->(c) { Digest::SHA384.hexdigest(c) }, { algorithm: 'sha384', encoding: 'hex' }],
      [->(c) { Digest::SHA384.base64digest(c) }, { algorithm: 'sha384', encoding: 'base64' }],
      [->(c) { Digest::SHA512.hexdigest(c) }, { algorithm: 'sha512', encoding: 'hex' }],
      [->(c) { Digest::SHA512.base64digest(c) }, { algorithm: 'sha512', encoding: 'base64' }],
      [->(c) { Digest::MD5.hexdigest(c) }, { algorithm: 'md5', encoding: 'hex' }],
      [->(c) { Digest::MD5.base64digest(c) }, { algorithm: 'md5', encoding: 'base64' }],
    ].each do |calculator, data|
      digest = calculator.call(contents)
      entry = subresource_integrity_hashes.find_or_initialize_by(**data)
      changed = true if entry.integrity_hash && entry.integrity_hash != digest
      unless entry.integrity_hash == digest
        entry.integrity_hash = digest
        entry.save!
      end
    end

    if changed
      update(last_success_at: now, last_change_at: now)
    else
      update(last_success_at: now)
    end
  end

  def download
    raise ArgumentError, 'URL must be http or https' unless url&.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))

    uri = URI.parse(url)
    Timeout.timeout(11) do
      return uri.read({ read_timeout: 10 })
    end
  end
end
