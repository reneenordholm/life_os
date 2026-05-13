class Document < ApplicationRecord
  has_many :document_chunks, dependent: :destroy
  has_many :document_entities, dependent: :destroy
  has_many :entities, through: :document_entities

  after_commit :ingest_if_needed, on: [ :create, :update ]
  before_update :clear_summary_if_content_changed

  private

  def clear_summary_if_content_changed
    self.summary = nil if will_save_change_to_content?
  end

  def ingest_if_needed
    return unless previous_changes.key?("content")

    DocumentIngestionService.new(self).call
  rescue StandardError => e
    Rails.logger.error("Document ingestion failed for Document##{id}")
    Rails.logger.error(e.full_message)
  end
end
