# frozen_string_literal: true

# TaskQuery is a Query Object that encapsulates all filtering, sorting, and pagination logic
# for Task records. This follows the Query Object pattern to keep business logic out of
# controllers and provides a reusable interface for task queries.
#
# Usage:
#   query = TaskQuery.new
#   results = query.call(filters: { status: 'pending' }, sort: { by: 'due_date', order: 'asc' }, page: 1, per_page: 20)
class TaskQuery
  # Configuration constants for validation
  ALLOWED_SORT_FIELDS = %w[created_at due_date priority position title].freeze
  ALLOWED_SORT_ORDERS = %w[asc desc].freeze
  DEFAULT_SORT_FIELD = 'created_at'
  DEFAULT_SORT_ORDER = 'desc'
  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  # Initialize the query builder
  def initialize
    @relation = Task.top_level
  end

  # Main entry point for the query
  #
  # @param filters [Hash] Filter criteria (status, priority, category_id, due_before, due_after, search, tag_ids)
  # @param sort [Hash] Sorting criteria (by, order)
  # @param page [Integer] Page number for pagination
  # @param per_page [Integer] Number of records per page
  # @return [Hash] Hash containing paginated results and metadata
  def call(filters: {}, sort: {}, page: 1, per_page: DEFAULT_PER_PAGE)
    apply_filters(filters)
    apply_sorting(sort)
    paginate(page, per_page)
  end

  private

  # Apply all filtering criteria to the relation
  def apply_filters(filters)
    @relation = @relation.by_status(filters[:status]) if filters[:status].present?
    @relation = @relation.by_priority(filters[:priority]) if filters[:priority].present?
    @relation = @relation.by_category(filters[:category_id]) if filters[:category_id].present?
    @relation = @relation.due_before(filters[:due_before]) if filters[:due_before].present?
    @relation = @relation.due_after(filters[:due_after]) if filters[:due_after].present?
    @relation = @relation.search(filters[:search]) if filters[:search].present?

    apply_tag_filter(filters[:tag_ids]) if filters[:tag_ids].present?
  end

  # Apply tag-based filtering with distinct to avoid duplicates
  def apply_tag_filter(tag_ids)
    @relation = @relation.joins(:tags).where(tags: { id: tag_ids }).distinct
  end

  # Apply sorting with validation
  def apply_sorting(sort)
    sort_field = normalize_sort_field(sort[:by])
    sort_order = normalize_sort_order(sort[:order])

    @relation = @relation.order(sort_field => sort_order)
  end

  # Validate and normalize sort field
  def normalize_sort_field(field)
    ALLOWED_SORT_FIELDS.include?(field) ? field : DEFAULT_SORT_FIELD
  end

  # Validate and normalize sort order
  def normalize_sort_order(order)
    order.to_s.downcase == 'asc' ? :asc : :desc
  end

  # Paginate results and return data with metadata
  def paginate(page, per_page)
    page = (page || 1).to_i
    per_page = [[per_page.to_i, 1].max, MAX_PER_PAGE].min
    total_count = @relation.count

    tasks = @relation.offset((page - 1) * per_page).limit(per_page)

    {
      data: tasks,
      meta: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end
end
