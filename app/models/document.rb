class Document < ApplicationRecord
  has_many :document_chunks, dependent: :destroy
  has_many :document_entities, dependent: :destroy
  has_many :entities, through: :document_entities

  after_save :mark_for_ingestion
  after_commit :ingest_if_needed, on: [ :create, :update ]

  private

  def mark_for_ingestion
    @needs_ingestion = saved_change_to_content? ||
                       saved_change_to_title? ||
                       saved_change_to_doc_type? ||
                       saved_change_to_metadata?
  end

  def ingest_if_needed
    return unless @needs_ingestion

    DocumentIngestionService.new(self).call
  end
end
