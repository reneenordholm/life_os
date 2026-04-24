class DocumentEntity < ApplicationRecord
  belongs_to :document
  belongs_to :entity
end
