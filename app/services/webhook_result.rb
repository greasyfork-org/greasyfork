WebhookChangedFile = Struct.new(
  :commit, :revision, :previous_revision, :ref, :messages, :urls, :asset_url,
  :scripts, :script_attributes, :content,
  keyword_init: true
) do
  def initialize(**attributes)
    super
    self.messages ||= []
    self.urls ||= []
    self.scripts ||= []
    self.script_attributes ||= []
  end

  def self.from_hash(attributes)
    new(**attributes.symbolize_keys.slice(*members))
  end
end

WebhookResponse = Struct.new(:status, :body, keyword_init: true)

WebhookResult = Struct.new(
  :changed_files, :repository_url, :changelog_markup, :response,
  keyword_init: true
) do
  def self.process(changed_files:, repository_url:, changelog_markup: 'text')
    new(changed_files:, repository_url:, changelog_markup:)
  end

  def self.respond(status:, body: nil)
    new(response: WebhookResponse.new(status:, body:))
  end

  def response?
    response.present?
  end
end
