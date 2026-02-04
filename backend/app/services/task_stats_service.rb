# frozen_string_literal: true

# TaskStatsService encapsulates all business logic for calculating task statistics.
# This follows the Service Object pattern to keep domain logic separate from controllers
# and makes the statistics calculation testable and reusable.
#
# Usage:
#   service = TaskStatsService.new
#   stats = service.calculate
class TaskStatsService
  # Initialize the service with a task relation (default: all tasks)
  def initialize(tasks = Task.all)
    @tasks = tasks
  end

  # Calculate comprehensive task statistics
  #
  # @return [Hash] Statistics hash with counts and rates
  def calculate
    {
      total: total_count,
      pending: pending_count,
      in_progress: in_progress_count,
      completed: completed_count,
      archived: archived_count,
      by_priority: priority_breakdown,
      by_status: status_breakdown,
      by_category: category_breakdown,
      completion_rate: completion_rate,
      overdue: overdue_count
    }
  end

  private

  # Count total tasks
  def total_count
    @tasks.count
  end

  # Count pending tasks
  def pending_count
    @tasks.where(status: :pending).count
  end

  # Count in-progress tasks
  def in_progress_count
    @tasks.where(status: :in_progress).count
  end

  # Count completed tasks
  def completed_count
    @completed_tasks ||= @tasks.where(status: :completed).count
  end

  # Count archived tasks
  def archived_count
    @tasks.where(status: :archived).count
  end

  # Breakdown of tasks by priority
  def priority_breakdown
    {
      low: @tasks.where(priority: :low).count,
      medium: @tasks.where(priority: :medium).count,
      high: @tasks.where(priority: :high).count,
      urgent: @tasks.where(priority: :urgent).count
    }
  end

  # Breakdown of tasks by status
  def status_breakdown
    {
      pending: pending_count,
      in_progress: in_progress_count,
      completed: completed_count,
      archived: archived_count
    }
  end

  # Breakdown of tasks by category
  def category_breakdown
    Category.left_joins(:tasks)
            .group(:id, :name)
            .count("tasks.id")
  end

  # Calculate task completion rate as percentage
  def completion_rate
    return 0.0 if total_count.zero?

    (completed_count.to_f / total_count * 100).round(2)
  end

  # Count overdue tasks (excluding completed and archived)
  def overdue_count
    @tasks.where("due_date < ? AND status NOT IN (?)", Time.current, [2, 3]).count
  end
end
