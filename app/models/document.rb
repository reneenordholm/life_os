class Document < ApplicationRecord
  has_many :document_chunks, dependent: :destroy
  has_many :document_entities, dependent: :destroy
  has_many :entities, through: :document_entities
end
