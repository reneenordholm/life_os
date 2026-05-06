class Document < ApplicationRecord
  has_many :document_chunks, dependent: :destroy
  has_many :document_entities, dependent: :destroy
  has_many :entities, through: :document_entities

  after_commit :ingest_if_needed, on: [ :create, :update ]

  private

  def ingest_if_needed
    return unless previous_changes.key?("content")

    DocumentIngestionService.new(self).call
  rescue StandardError => e
    Rails.logger.error(
      "Document ingestion failed for Document##{id}: #{e.class}: #{e.message}"
    )
  end
end
