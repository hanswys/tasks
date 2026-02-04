# frozen_string_literal: true

module Tasks
  # UpdateService encapsulates the complex logic for creating and updating tasks,
  # including handling of tag associations with atomicity guarantees.
  # This follows the Service Object pattern to keep transaction logic and domain
  # operations separate from controllers.
  #
  # Usage:
  #   service = Tasks::UpdateService.new(task)
  #   result = service.call(task_params: {...}, tag_ids: [...])
  #
  #   if result.success?
  #     task = result.task
  #   else
  #     errors = result.errors
  #   end
  class UpdateService
    # Result object for service operations
    class Result
      attr_reader :task, :errors

      def initialize(task, errors = nil)
        @task = task
        @errors = errors || {}
      end

      def success?
        errors.empty?
      end
    end

    # Initialize service with a task instance
    #
    # @param task [Task] The task instance to update
    def initialize(task)
      @task = task
    end

    # Update task attributes and handle tag associations atomically
    #
    # @param task_params [Hash] Task attributes to update
    # @param tag_ids [Array] Array of tag IDs to associate with the task
    # @return [Result] Result object containing task and any errors
    def call(task_params:, tag_ids: nil)
      Task.transaction do
        @task.assign_attributes(task_params)

        unless @task.save
          # Convert ActiveModel::Errors to a simple hash for the Result object
          error_hash = @task.errors.messages.transform_values { |msgs| msgs }
          return Result.new(@task, error_hash)
        end

        # Handle tag updates if tag_ids is provided (including empty arrays)
        if tag_ids.is_a?(Array)
          update_tags(tag_ids)
        end

        Result.new(@task, {})
      rescue StandardError => e
        Result.new(@task, { base: [e.message] })
      end
    end

    private

    # Update tag associations for the task
    #
    # @param tag_ids [Array] Array of tag IDs
    def update_tags(tag_ids)
      @task.tag_ids = tag_ids
    end
  end
end
