class CentralRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :primary, reading: :primary }
end
