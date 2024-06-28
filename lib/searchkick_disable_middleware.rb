class SearchkickDisableMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    Searchkick.callbacks(false) do
      @app.call(env)
    end
  end
end
