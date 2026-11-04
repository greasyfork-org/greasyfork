# Disable SSL verification
if defined?(Searchkick)
  Searchkick.queue_name = :low
  Searchkick.client_options = {
    transport_options: {
      ssl: {
        verify: false,
      },
    },
  }
end
