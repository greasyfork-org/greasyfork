class CachingService
  def self.cache_with_log(key, options = {})
    options[:version] = key.cache_version if key.respond_to?(:cache_version)
    key = "#{options.delete(:namespace)}/#{key.respond_to?(:cache_key) ? key.cache_key : key.to_s}" if options[:namespace]
    Rails.cache.fetch(key, options) do
      Rails.logger.warn("Cache miss - #{key} - #{options}") if Greasyfork::Application.config.log_cache_misses
      o = yield
      Rails.logger.warn("Cache stored - #{key} - #{options}") if Greasyfork::Application.config.log_cache_misses
      next o
    end
  end
end
