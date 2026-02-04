# frozen_string_literal: true

# TaskSerializer handles the JSON representation of Task instances.
# This follows the Serializer pattern to separate presentation logic from models,
# ensuring consistent API responses and making serialization logic testable.
#
# Usage:
#   TaskSerializer.new(task).as_json
#   TaskSerializer.new(tasks).as_json(multiple: true)
class TaskSerializer
  # Initialize serializer with task(s)
  #
  # @param task [Task, Array<Task>] Task instance or array of tasks
  def initialize(task)
    @task = task
  end

  # Serialize task(s) to JSON-compatible hash
  #
  # @param multiple [Boolean] Whether serializing multiple records
  # @param include [Array<Symbol>] Associations to include in output
  # @return [Hash, Array<Hash>] Serialized task(s)
  def as_json(multiple: false, include: [:category, :tags])
    if multiple
      @task.map { |t| serialize_task(t, include: include) }
    else
      serialize_task(@task, include: include)
    end
  end

  private

  # Serialize a single task instance
  #
  # @param task [Task] The task to serialize
  # @param include [Array<Symbol>] Associations to include
  # @return [Hash] Serialized task
  def serialize_task(task, include: [:category, :tags])
    data = {
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      due_date: task.due_date,
      position: task.position,
      estimated_minutes: task.estimated_minutes,
      parent_id: task.parent_id,
      category_id: task.category_id,
      created_at: task.created_at,
      updated_at: task.updated_at,
      overdue: task.overdue?,
      days_until_due: task.days_until_due
    }

    # Include associated records if requested
    data[:category] = serialize_category(task.category) if include.include?(:category) && task.category.present?
    data[:tags] = serialize_tags(task.tags) if include.include?(:tags)
    data[:subtasks] = serialize_subtasks(task.subtasks) if include.include?(:subtasks) && task.subtasks.any?

    data
  end

  # Serialize category association
  #
  # @param category [Category] The category instance
  # @return [Hash] Serialized category
  def serialize_category(category)
    {
      id: category.id,
      name: category.name,
      color: category.color,
      created_at: category.created_at,
      updated_at: category.updated_at
    }
  end

  # Serialize tags association
  #
  # @param tags [Array<Tag>] Array of tags
  # @return [Array<Hash>] Serialized tags
  def serialize_tags(tags)
    tags.map { |tag| serialize_tag(tag) }
  end

  # Serialize a single tag
  #
  # @param tag [Tag] The tag instance
  # @return [Hash] Serialized tag
  def serialize_tag(tag)
    {
      id: tag.id,
      name: tag.name,
      color: tag.color,
      created_at: tag.created_at,
      updated_at: tag.updated_at
    }
  end

  # Serialize subtasks association (recursive)
  #
  # @param subtasks [Array<Task>] Array of subtask instances
  # @return [Array<Hash>] Serialized subtasks
  def serialize_subtasks(subtasks)
    subtasks.map { |subtask| serialize_task(subtask, include: [:tags]) }
  end
end
