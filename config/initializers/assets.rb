Rails.application.config.assets.precompile << Proc.new { |path,fn| fn.starts_with?(Rails.root.join('vendor').to_s)}
