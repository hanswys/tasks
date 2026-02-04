class Tag < ApplicationRecord
  has_many :task_tags, dependent: :destroy
  has_many :tasks, through: :task_tags

  validates :name, presence: true, uniqueness: true
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: "must be a valid hex color" }, allow_blank: true
end
