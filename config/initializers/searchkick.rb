# Disable SSL verification
if defined?(Searchkick)
  Searchkick.client_options = {
    transport_options: {
      ssl: {
        verify: false,
      },
    },
  }
end
