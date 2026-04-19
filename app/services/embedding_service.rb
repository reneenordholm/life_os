class EmbeddingService
  def self.client
    @client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
  end

  def self.embed(text)
    response = client.embeddings(
      parameters: {
        model: "text-embedding-3-small",
        input: text
      }
    )

    response.dig("data", 0, "embedding")
  end
end