# Disable SSL verification
if defined?(Searchkick)
  Searchkick.client_options = {
    transport_options: {
      headers: {
        accept: 'application/vnd.elasticsearch+json; compatible-with=8',
        content_type: 'application/vnd.elasticsearch+json; compatible-with=8',
      },
      ssl: {
        verify: false,
      },
    },
  }
end
