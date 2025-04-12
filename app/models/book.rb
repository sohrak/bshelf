class Book < ApplicationRecord
  # Basic validations for MVP
  validates :title, presence: true
  validates :author, presence: true

  # Optional: Add more specific validations later
  # validates :isbn, uniqueness: true, allow_blank: true, format: { with: /\A(?:ISBN(?:-1[03])?:? )?(?=[0-9X]{10}$|(?=(?:[0-9]+[- ]){3})[- 0-9X]{13}$|97[89][0-9]{10}$|(?=(?:[0-9]+[- ]){4})[- 0-9]{17}$)(?:97[89][- ]?)?[0-9]{1,5}[- ]?[0-9]+[- ]?[0-9]+[- ]?[0-9X]\z/, message: "format is invalid" }
  # validates :page_count, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
end
