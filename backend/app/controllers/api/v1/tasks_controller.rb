# frozen_string_literal: true

module Api
  module V1
    # TasksController handles HTTP requests for task management.
    # Following the Skinny Controller pattern, it delegates business logic to:
    # - TaskQuery for filtering, sorting, and pagination
    # - TaskStatsService for statistics calculations
    # - Tasks::UpdateService for atomic create/update operations
    # - TaskSerializer for JSON serialization
    #
    # This keeps the controller focused solely on request routing and response formatting.
    class TasksController < ApplicationController
      before_action :set_task, only: [:show, :update, :destroy]

      # GET /api/v1/tasks
      # Supports filtering: status, priority, category_id, due_before, due_after, search, tag_ids
      # Supports sorting: sort_by (field), sort_order (asc/desc)
      # Supports pagination: page, per_page
      def index
        result = TaskQuery.new.call(
          filters: extract_filters,
          sort: extract_sort,
          page: params[:page],
          per_page: params[:per_page]
        )

        render json: {
          data: TaskSerializer.new(result[:data]).as_json(multiple: true),
          meta: result[:meta]
        }
      end

      # GET /api/v1/tasks/stats
      def stats
        stats_data = TaskStatsService.new.calculate

        render json: stats_data
      end

      # GET /api/v1/tasks/:id
      def show
        render json: TaskSerializer.new(@task).as_json(include: [:category, :tags, :subtasks])
      end

      # POST /api/v1/tasks
      def create
        @task = Task.new
        result = Tasks::UpdateService.new(@task).call(
          task_params: task_params,
          tag_ids: params[:task][:tag_ids]
        )

        if result.success?
          render json: TaskSerializer.new(result.task).as_json(include: [:category, :tags]), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/tasks/:id
      def update
        result = Tasks::UpdateService.new(@task).call(
          task_params: task_params,
          tag_ids: params[:task][:tag_ids]
        )

        if result.success?
          render json: TaskSerializer.new(result.task).as_json(include: [:category, :tags])
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/tasks/:id
      def destroy
        @task.destroy
        head :no_content
      end

      # POST /api/v1/tasks/bulk_update
      def bulk_update
        task_ids = params[:task_ids]
        updates = params[:updates]&.permit(:status, :priority, :category_id, :due_date)

        return render json: { error: "task_ids required" }, status: :bad_request if task_ids.blank?
        return render json: { error: "updates required" }, status: :bad_request if updates.blank?

        tasks = Task.where(id: task_ids)
        updated_count = tasks.update_all(updates.to_h)

        render json: { updated_count: updated_count, task_ids: task_ids }
      end

      # DELETE /api/v1/tasks/bulk_delete
      def bulk_delete
        task_ids = params[:task_ids]

        return render json: { error: "task_ids required" }, status: :bad_request if task_ids.blank?

        deleted_count = Task.where(id: task_ids).destroy_all.count

        render json: { deleted_count: deleted_count, task_ids: task_ids }
      end

      # POST /api/v1/tasks/reorder
      def reorder
        positions = params[:positions] # Array of { id: number, position: number }

        return render json: { error: "positions required" }, status: :bad_request if positions.blank?

        Task.transaction do
          positions.each do |item|
            Task.where(id: item[:id]).update_all(position: item[:position])
          end
        end

        render json: { success: true, updated_count: positions.length }
      end

      private

      # Extract filter parameters for query
      def extract_filters
        {
          status: params[:status],
          priority: params[:priority],
          category_id: params[:category_id],
          due_before: params[:due_before],
          due_after: params[:due_after],
          search: params[:search],
          tag_ids: Array(params[:tag_ids]).reject(&:blank?)
        }
      end

      # Extract sort parameters for query
      def extract_sort
        {
          by: params[:sort_by],
          order: params[:sort_order]
        }
      end

      # Find task by ID
      def set_task
        @task = Task.find(params[:id])
      end

      # Permitted task parameters
      def task_params
        params.require(:task).permit(
          :title,
          :description,
          :priority,
          :status,
          :due_date,
          :category_id,
          :position,
          :estimated_minutes,
          :parent_id
        )
      end
    end
  end
end
