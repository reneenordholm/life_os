class Document < ApplicationRecord
  has_many :document_chunks, dependent: :destroy
end