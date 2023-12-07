class Stock < ApplicationRecord
  self.primary_key = :code

  has_many :owned_stocks, foreign_key: :code
end
