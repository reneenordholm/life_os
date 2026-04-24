class Entity < ApplicationRecord
  has_many :document_entities, dependent: :destroy
  has_many :documents, through: :document_entities
end
