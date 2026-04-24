class EntityExtractionService
  PEOPLE = [
    "Mom",
    "Marley",
    "William"
  ]

  def initialize(document)
    @document = document
  end

  def call
    text = @document.content

    PEOPLE.each do |name|
      if text.include?(name)
        entity = Entity.find_or_create_by!(
          name: name,
          entity_type: "person"
        )

        DocumentEntity.find_or_create_by!(
          document: @document,
          entity: entity
        )
      end
    end
  end
end
