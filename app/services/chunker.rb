class Chunker
  CHUNK_SIZE = 800

  def self.call(text)
    text.scan(/.{1,#{CHUNK_SIZE}}/m)
  end
end
