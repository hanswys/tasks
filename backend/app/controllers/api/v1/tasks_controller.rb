class Api::V1::TasksController < ApplicationController
  before_action :set_task, only: [:show, :update, :destroy]

  # GET /api/v1/tasks
  # Supports filtering: status, priority, category_id, due_before, due_after, search
  # Supports sorting: sort_by (field), sort_order (asc/desc)
  # Supports pagination: page, per_page
  def index
    @tasks = Task.top_level
                 .by_status(params[:status])
                 .by_priority(params[:priority])
                 .by_category(params[:category_id])
                 .due_before(params[:due_before])
                 .due_after(params[:due_after])
                 .search(params[:search])

    # Filter by tags if provided
    if params[:tag_ids].present?
      @tasks = @tasks.joins(:tags).where(tags: { id: params[:tag_ids] }).distinct
    end

    # Sorting
    sort_by = %w[created_at due_date priority position title].include?(params[:sort_by]) ? params[:sort_by] : "created_at"
    sort_order = params[:sort_order] == "asc" ? :asc : :desc
    @tasks = @tasks.order(sort_by => sort_order)

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = params[:per_page].present? ? [[params[:per_page].to_i, 1].max, 100].min : 20
    total_count = @tasks.count
    @tasks = @tasks.offset((page - 1) * per_page).limit(per_page)

    render json: {
      data: @tasks.as_json(include: [:category, :tags], methods: [:overdue?, :days_until_due]),
      meta: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  # GET /api/v1/tasks/stats
  def stats
    tasks = Task.all
    completed_tasks = tasks.where(status: :completed)

    render json: {
      total: tasks.count,
      pending: tasks.where(status: :pending).count,
      in_progress: tasks.where(status: :in_progress).count,
      completed: completed_tasks.count,
      archived: tasks.where(status: :archived).count,
      by_priority: {
        low: tasks.where(priority: :low).count,
        medium: tasks.where(priority: :medium).count,
        high: tasks.where(priority: :high).count,
        urgent: tasks.where(priority: :urgent).count
      },
      by_status: {
        pending: tasks.where(status: :pending).count,
        in_progress: tasks.where(status: :in_progress).count,
        completed: completed_tasks.count,
        archived: tasks.where(status: :archived).count
      },
      by_category: Category.left_joins(:tasks).group(:id, :name).count("tasks.id"),
      completion_rate: tasks.count > 0 ? (completed_tasks.count.to_f / tasks.count * 100).round(2) : 0,
      overdue: tasks.where("due_date < ? AND status NOT IN (?)", Time.current, [2, 3]).count
    }
  end

  # GET /api/v1/tasks/:id
  def show
    render json: @task.as_json(include: [:category, :tags, :subtasks], methods: [:overdue?, :days_until_due])
  end

  # POST /api/v1/tasks
  def create
    @task = Task.new(task_params)

    if @task.save
      # Handle tag associations
      if params[:task][:tag_ids].present?
        @task.tag_ids = params[:task][:tag_ids]
      end
      render json: @task.as_json(include: [:category, :tags], methods: [:overdue?, :days_until_due]), status: :created
    else
      render json: { errors: @task.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/tasks/:id
  def update
    if @task.update(task_params)
      # Handle tag associations
      if params[:task].key?(:tag_ids)
        @task.tag_ids = params[:task][:tag_ids] || []
      end
      render json: @task.as_json(include: [:category, :tags], methods: [:overdue?, :days_until_due])
    else
      render json: { errors: @task.errors }, status: :unprocessable_entity
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

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(
      :title,
      :description,
      :completed,
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
