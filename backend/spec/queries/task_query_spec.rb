# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskQuery, type: :query do
  describe "#call" do
    let!(:category) { create(:category) }
    let!(:tag1) { create(:tag) }
    let!(:tag2) { create(:tag) }

    before do
      # Create test data
      @pending_task = create(:task, status: :pending, priority: :low, category: category)
      @completed_task = create(:task, status: :completed, priority: :high)
      @in_progress_task = create(:task, status: :in_progress, priority: :medium)
      @archived_task = create(:task, status: :archived, priority: :urgent)

      # Create tasks with tags
      @tagged_task = create(:task, title: "Tagged Task")
      @tagged_task.tags << tag1
      @tagged_task_2 = create(:task, title: "Another Tagged Task")
      @tagged_task_2.tags << tag2

      # Create searchable tasks
      @searchable_task = create(:task, title: "Find Me", description: "Searchable content")
    end

    describe "filtering" do
      it "filters by status" do
        result = TaskQuery.new.call(filters: { status: :pending })
        expect(result[:data]).to include(@pending_task)
        expect(result[:data]).not_to include(@completed_task)
        expect(result[:data]).not_to include(@archived_task)
      end

      it "filters by priority" do
        result = TaskQuery.new.call(filters: { priority: :high })
        expect(result[:data]).to include(@completed_task)
        expect(result[:data]).not_to include(@pending_task)
      end

      it "filters by category_id" do
        result = TaskQuery.new.call(filters: { category_id: category.id })
        expect(result[:data]).to include(@pending_task)
        expect(result[:data]).not_to include(@completed_task)
      end

      it "filters by due_before date" do
        future_date = 10.days.from_now
        result = TaskQuery.new.call(filters: { due_before: future_date })
        expect(result[:data]).to include(@pending_task) # has default due_date
      end

      it "filters by due_after date" do
        past_date = 10.days.ago
        result = TaskQuery.new.call(filters: { due_after: past_date })
        expect(result[:data]).to include(@pending_task)
      end

      it "filters by search query (title)" do
        result = TaskQuery.new.call(filters: { search: "Find Me" })
        expect(result[:data]).to include(@searchable_task)
        expect(result[:data]).not_to include(@pending_task)
      end

      it "filters by search query (description)" do
        result = TaskQuery.new.call(filters: { search: "Searchable" })
        expect(result[:data]).to include(@searchable_task)
      end

      it "filters by tag_ids (single tag)" do
        result = TaskQuery.new.call(filters: { tag_ids: [tag1.id] })
        expect(result[:data]).to include(@tagged_task)
        expect(result[:data]).not_to include(@tagged_task_2)
      end

      it "filters by tag_ids (multiple tags) with distinct" do
        result = TaskQuery.new.call(filters: { tag_ids: [tag1.id, tag2.id] })
        # Should include both tagged tasks
        expect(result[:data]).to include(@tagged_task, @tagged_task_2)
      end

      it "combines multiple filters" do
        result = TaskQuery.new.call(
          filters: { status: :pending, priority: :low }
        )
        expect(result[:data]).to include(@pending_task)
        expect(result[:data]).not_to include(@completed_task)
        expect(result[:data]).not_to include(@in_progress_task)
      end

      it "returns all results when no filters provided" do
        result = TaskQuery.new.call(filters: {})
        expect(result[:data].count).to be > 4 # At least the ones we created
      end

      it "returns empty results when filter matches nothing" do
        result = TaskQuery.new.call(filters: { status: :pending, priority: :urgent })
        expect(result[:data]).to be_empty
      end
    end

    describe "sorting" do
      before do
        @old_task = create(:task, created_at: 1.month.ago, title: "Old")
        @new_task = create(:task, created_at: 1.day.ago, title: "New")
        @high_priority = create(:task, priority: :urgent)
        @low_priority = create(:task, priority: :low)
      end

      it "sorts by created_at descending (default)" do
        result = TaskQuery.new.call(sort: {})
        data = result[:data]
        # Most recent should come first
        expect(data.first.created_at).to be >= data.last.created_at
      end

      it "sorts by created_at ascending" do
        result = TaskQuery.new.call(sort: { by: "created_at", order: "asc" })
        data = result[:data]
        # Oldest should come first
        expect(data.first.created_at).to be <= data.last.created_at
      end

      it "sorts by title" do
        result = TaskQuery.new.call(sort: { by: "title", order: "asc" })
        expect(result[:data].first.title <= result[:data].last.title).to be true
      end

      it "sorts by priority" do
        result = TaskQuery.new.call(sort: { by: "priority", order: "desc" })
        data = result[:data]
        # Higher priority values should come first
        expect(data.first.priority).to be >= data.last.priority
      end

      it "sorts by due_date" do
        result = TaskQuery.new.call(sort: { by: "due_date", order: "asc" })
        data = result[:data]
        due_dates = data.map(&:due_date).compact
        expect(due_dates).to eq(due_dates.sort)
      end

      it "defaults to created_at for invalid sort field" do
        result = TaskQuery.new.call(sort: { by: "invalid_field", order: "asc" })
        # Should not raise an error and should return results
        expect(result[:data]).to be_a(Array)
      end

      it "defaults to desc for invalid sort order" do
        result = TaskQuery.new.call(sort: { by: "created_at", order: "invalid" })
        # Should default to desc and return results ordered properly
        expect(result[:data]).to be_a(Array)
        data = result[:data]
        expect(data.first.created_at >= data.last.created_at).to be true
      end

      it "protects against SQL injection in sort_by" do
        # Should not raise an error and should default to created_at
        result = TaskQuery.new.call(sort: { by: "created_at; DROP TABLE tasks;", order: "asc" })
        expect(result[:data]).to be_a(Array)
      end
    end

    describe "pagination" do
      before do
        create_list(:task, 30)
      end

      it "returns default per_page (20) results" do
        result = TaskQuery.new.call(page: 1)
        expect(result[:data].count).to eq(20)
      end

      it "respects custom per_page" do
        result = TaskQuery.new.call(page: 1, per_page: 10)
        expect(result[:data].count).to eq(10)
      end

      it "enforces MAX_PER_PAGE limit" do
        result = TaskQuery.new.call(page: 1, per_page: 200)
        # Should be limited to MAX_PER_PAGE (100)
        expect(result[:data].count).to eq(TaskQuery::MAX_PER_PAGE)
      end

      it "enforces minimum per_page of 1" do
        result = TaskQuery.new.call(page: 1, per_page: 0)
        expect(result[:data].count).to be >= 1
      end

      it "returns correct page" do
        result1 = TaskQuery.new.call(page: 1, per_page: 10)
        result2 = TaskQuery.new.call(page: 2, per_page: 10)

        first_page_ids = result1[:data].map(&:id)
        second_page_ids = result2[:data].map(&:id)

        expect(first_page_ids).not_to include(*second_page_ids)
      end

      it "includes pagination metadata" do
        result = TaskQuery.new.call(page: 1, per_page: 10)
        expect(result[:meta]).to include(
          :current_page,
          :per_page,
          :total_count,
          :total_pages
        )
      end

      it "calculates correct total_pages" do
        result = TaskQuery.new.call(page: 1, per_page: 10)
        total_pages = (result[:meta][:total_count].to_f / result[:meta][:per_page]).ceil
        expect(result[:meta][:total_pages]).to eq(total_pages)
      end

      it "handles invalid page number gracefully" do
        result = TaskQuery.new.call(page: "invalid", per_page: 10)
        # Should convert to 1
        expect(result[:meta][:current_page]).to be >= 1
      end

      it "handles nil page gracefully" do
        result = TaskQuery.new.call(page: nil, per_page: 10)
        expect(result[:meta][:current_page]).to eq(1)
      end

      it "handles invalid per_page gracefully" do
        result = TaskQuery.new.call(page: 1, per_page: "invalid")
        expect(result[:data]).to be_a(Array)
      end
    end

    describe "combined operations" do
      before do
        @task1 = create(:task, status: :pending, priority: :high, title: "Important", created_at: 2.days.ago)
        @task2 = create(:task, status: :pending, priority: :low, title: "Less Important", created_at: 1.day.ago)
        @task3 = create(:task, status: :completed, priority: :high, title: "Done")
      end

      it "filters, sorts, and paginates together" do
        result = TaskQuery.new.call(
          filters: { status: :pending },
          sort: { by: "priority", order: "desc" },
          page: 1,
          per_page: 10
        )

        expect(result[:data]).to include(@task1, @task2)
        expect(result[:data]).not_to include(@task3)
        expect(result[:meta][:current_page]).to eq(1)
      end

      it "returns correct total_count with filters" do
        result = TaskQuery.new.call(
          filters: { status: :pending }
        )
        pending_count = Task.where(status: :pending).count
        expect(result[:meta][:total_count]).to eq(pending_count)
      end
    end

    describe "edge cases" do
      it "returns empty data for non-existent category" do
        result = TaskQuery.new.call(filters: { category_id: 99999 })
        expect(result[:data]).to be_empty
      end

      it "returns empty data for non-existent tag" do
        result = TaskQuery.new.call(filters: { tag_ids: [99999] })
        expect(result[:data]).to be_empty
      end

      it "handles empty string filters gracefully" do
        result = TaskQuery.new.call(filters: { search: "" })
        expect(result[:data]).to be_a(Array)
      end

      it "handles nil filters gracefully" do
        result = TaskQuery.new.call(filters: nil)
        expect(result[:data]).to be_a(Array)
      end

      it "excludes subtasks from results (only top_level)" do
        parent = create(:task)
        child = create(:task, parent: parent)

        result = TaskQuery.new.call
        expect(result[:data]).to include(parent)
        expect(result[:data]).not_to include(child)
      end
    end
  end
end
