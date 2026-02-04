class Task < ApplicationRecord
  # Enums
  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }
  enum :status, { pending: 0, in_progress: 1, completed: 2, archived: 3 }

  # Associations
  belongs_to :category, optional: true
  belongs_to :parent, class_name: "Task", optional: true
  has_many :subtasks, class_name: "Task", foreign_key: "parent_id", dependent: :destroy
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags

  # Validations
  validates :title, presence: true

  # Scopes for filtering
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :by_category, ->(category_id) { where(category_id: category_id) if category_id.present? }
  scope :due_before, ->(date) { where("due_date <= ?", date) if date.present? }
  scope :due_after, ->(date) { where("due_date >= ?", date) if date.present? }
  scope :search, ->(query) { where("title LIKE ? OR description LIKE ?", "%#{query}%", "%#{query}%") if query.present? }
  scope :top_level, -> { where(parent_id: nil) }

  # Computed methods
  def overdue?
    due_date.present? && due_date < Time.current && !completed?
  end

  def days_until_due
    return nil unless due_date.present?
    (due_date.to_date - Date.current).to_i
  end
end
