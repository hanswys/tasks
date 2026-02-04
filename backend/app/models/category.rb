class Category < ApplicationRecord
  has_many :tasks, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }, allow_blank: true
end
