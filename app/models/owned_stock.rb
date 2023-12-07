class OwnedStock < ApplicationRecord
  self.primary_key = :code

  belongs_to :stock, foreign_key: :code

  delegate :name, :price, to: :stock
end
