# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Tasks", type: :request do
  let(:api_version) { "v1" }
  let(:content_type) { "application/json" }

  describe "GET /api/v1/tasks" do
    context "without filters" do
      let!(:tasks) { create_list(:task, 5) }

      it "returns all top-level tasks" do
        get "/api/v1/tasks"

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include(content_type)
        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(5)
      end

      it "returns task with correct schema" do
        task = create(:task)
        get "/api/v1/tasks"

        json = JSON.parse(response.body)
        first_task = json["data"].first

        expect(first_task).to have_key("id")
        expect(first_task).to have_key("title")
        expect(first_task).to have_key("status")
        expect(first_task).to have_key("priority")
        expect(first_task).to have_key("due_date")
        expect(first_task).to have_key("overdue")
        expect(first_task).to have_key("days_until_due")
        expect(first_task).to have_key("created_at")
        expect(first_task).to have_key("updated_at")
      end

      it "returns pagination metadata" do
        create_list(:task, 5)
        get "/api/v1/tasks"

        json = JSON.parse(response.body)
        expect(json).to have_key("meta")
        expect(json["meta"]).to have_key("current_page")
        expect(json["meta"]).to have_key("per_page")
        expect(json["meta"]).to have_key("total_count")
        expect(json["meta"]).to have_key("total_pages")
      end

      it "returns meta with correct pagination values" do
        get "/api/v1/tasks"

        json = JSON.parse(response.body)
        meta = json["meta"]
        expect(meta["current_page"]).to eq(1)
        expect(meta["per_page"]).to eq(20)  # default per_page
        expect(meta["total_count"]).to eq(5)  # from let!(:tasks)
        expect(meta["total_pages"]).to eq(1)  # 5 tasks / 20 per_page = 1 page
      end
    end

    context "filtering by status" do
      let!(:pending_task) { create(:task, status: :pending) }
      let!(:completed_task) { create(:task, status: :completed) }
      let!(:in_progress_task) { create(:task, status: :in_progress) }

      it "filters tasks by status=pending" do
        get "/api/v1/tasks", params: { status: "pending" }

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(1)
        expect(json["data"][0]["status"]).to eq("pending")
      end

      it "filters tasks by status=completed" do
        get "/api/v1/tasks", params: { status: "completed" }

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(1)
        expect(json["data"][0]["status"]).to eq("completed")
      end

      it "returns total_count for filtered results" do
        get "/api/v1/tasks", params: { status: "pending" }

        json = JSON.parse(response.body)
        expect(json["meta"]["total_count"]).to eq(1)
      end
    end

    context "filtering by priority" do
      let!(:low_priority) { create(:task, priority: :low) }
      let!(:high_priority) { create(:task, priority: :high) }
      let!(:urgent) { create(:task, priority: :urgent) }

      it "filters tasks by high priority" do
        get "/api/v1/tasks", params: { priority: "high" }

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(1)
        expect(json["data"][0]["priority"]).to eq("high")
      end
    end

    context "filtering by category" do
      let(:category) { create(:category) }
      let!(:task_with_category) { create(:task, category: category) }
      let!(:task_without_category) { create(:task, category: nil) }

      it "filters tasks by category_id" do
        get "/api/v1/tasks", params: { category_id: category.id }

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(1)
        expect(json["data"][0]["category"]["id"]).to eq(category.id)
      end
    end

    context "filtering by tag_ids" do
      let!(:tag1) { create(:tag) }
      let!(:tag2) { create(:tag) }
      let!(:task_with_tag1) { create(:task) }
      let!(:task_with_tag2) { create(:task) }
      let!(:task_without_tags) { create(:task) }

      before do
        task_with_tag1.tags << tag1
        task_with_tag2.tags << tag2
      end

      it "filters tasks by single tag_id" do
        get "/api/v1/tasks", params: { tag_ids: [tag1.id] }

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(1)
        expect(json["data"][0]["tags"].map { |t| t["id"] }).to include(tag1.id)
      end

      it "filters tasks by multiple tag_ids" do
        get "/api/v1/tasks", params: { tag_ids: [tag1.id, tag2.id] }

        json = JSON.parse(response.body)
        # Should return both tasks that have either tag (using OR logic)
        expect(json["data"].count).to eq(2)
      end
    end

    context "filtering by search query" do
      before do
        @task_matching_title = create(:task, title: "Find Me", description: "Other")
        @task_matching_description = create(:task, title: "Other", description: "Find Me")
        @task_not_matching = create(:task, title: "Nope", description: "Nothing")
      end

      it "filters by title search" do
        get "/api/v1/tasks", params: { search: "Find Me" }

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(2)
      end

      it "returns only matching tasks" do
        get "/api/v1/tasks", params: { search: "Find Me" }

        json = JSON.parse(response.body)
        titles_and_descriptions = json["data"].map { |t| "#{t['title']} #{t['description']}" }
        expect(titles_and_descriptions.all? { |x| x.include?("Find Me") }).to be true
      end
    end

    context "sorting" do
      let!(:new_task) { create(:task, created_at: 1.day.ago, title: "New") }
      let!(:old_task) { create(:task, created_at: 1.month.ago, title: "Old") }
      let!(:high_priority) { create(:task, priority: :urgent) }
      let!(:low_priority) { create(:task, priority: :low) }

      it "sorts by created_at descending by default" do
        get "/api/v1/tasks"

        json = JSON.parse(response.body)
        data = json["data"]
        expect(data.first["created_at"] >= data.last["created_at"]).to be true
      end

      it "sorts by created_at ascending" do
        get "/api/v1/tasks", params: { sort_by: "created_at", sort_order: "asc" }

        json = JSON.parse(response.body)
        data = json["data"]
        expect(data.first["created_at"] <= data.last["created_at"]).to be true
      end

      it "sorts by priority" do
        get "/api/v1/tasks", params: { sort_by: "priority", sort_order: "desc" }

        json = JSON.parse(response.body)
        data = json["data"]
        # Higher priority values first
        expect(data.first["priority"]).to eq("urgent")
      end

      it "sorts by title" do
        get "/api/v1/tasks", params: { sort_by: "title", sort_order: "asc" }

        json = JSON.parse(response.body)
        data = json["data"]
        titles = data.map { |t| t["title"] }
        expect(titles).to eq(titles.sort)
      end

      it "defaults to created_at for invalid sort_by" do
        get "/api/v1/tasks", params: { sort_by: "invalid_field" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]).to be_a(Array)
      end

      it "defaults to desc for invalid sort_order" do
        get "/api/v1/tasks", params: { sort_by: "created_at", sort_order: "invalid" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]).to be_a(Array)
      end

      it "prevents SQL injection in sort_by" do
        malicious_sort = "created_at; DROP TABLE tasks;"
        get "/api/v1/tasks", params: { sort_by: malicious_sort }

        expect(response).to have_http_status(:ok)
        expect(Task.count).to be > 0 # Table should still exist
      end
    end

    context "pagination" do
      before { create_list(:task, 25) }

      it "returns default 20 items per page" do
        get "/api/v1/tasks"

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(20)
        expect(json["meta"]["per_page"]).to eq(20)
      end

      it "respects per_page parameter" do
        get "/api/v1/tasks", params: { per_page: 10 }

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(10)
        expect(json["meta"]["per_page"]).to eq(10)
      end

      it "limits per_page to MAX_PER_PAGE (100)" do
        get "/api/v1/tasks", params: { per_page: 200 }

        json = JSON.parse(response.body)
        expect(json["meta"]["per_page"]).to eq(100)
      end

      it "respects page parameter" do
        get "/api/v1/tasks", params: { page: 2, per_page: 10 }

        json = JSON.parse(response.body)
        expect(json["meta"]["current_page"]).to eq(2)
        expect(json["data"].count).to eq(10)
      end

      it "calculates correct total_pages" do
        get "/api/v1/tasks", params: { per_page: 10 }

        json = JSON.parse(response.body)
        expected_pages = (25.to_f / 10).ceil
        expect(json["meta"]["total_pages"]).to eq(expected_pages)
      end

      it "returns different data for different pages" do
        get "/api/v1/tasks", params: { page: 1, per_page: 10 }
        page1_ids = JSON.parse(response.body)["data"].map { |t| t["id"] }

        get "/api/v1/tasks", params: { page: 2, per_page: 10 }
        page2_ids = JSON.parse(response.body)["data"].map { |t| t["id"] }

        expect(page1_ids).not_to include(*page2_ids)
      end
    end

    context "combined filters and pagination" do
      before do
        @pending = create_list(:task, 25, status: :pending)
        @completed = create_list(:task, 10, status: :completed)
      end

      it "filters and paginates together" do
        get "/api/v1/tasks", params: {
          status: "pending",
          page: 1,
          per_page: 10
        }

        json = JSON.parse(response.body)
        expect(json["data"].count).to eq(10)
        expect(json["meta"]["total_count"]).to eq(25)
        expect(json["data"].all? { |t| t["status"] == "pending" }).to be true
      end
    end

    context "includes associated data" do
      let(:category) { create(:category) }
      let(:tag) { create(:tag) }
      let!(:task) { create(:task, category: category) }

      before do
        task.tags << tag
      end

      it "includes category in response" do
        get "/api/v1/tasks"

        json = JSON.parse(response.body)
        first_task = json["data"].first
        expect(first_task).to have_key("category")
        expect(first_task["category"]["id"]).to eq(category.id)
        expect(first_task["category"]).to have_key("name")
      end

      it "includes tags in response" do
        get "/api/v1/tasks"

        json = JSON.parse(response.body)
        first_task = json["data"].first
        expect(first_task).to have_key("tags")
        expect(first_task["tags"].map { |t| t["id"] }).to include(tag.id)
      end
    end

    context "excludes subtasks from results" do
      let!(:parent) { create(:task, title: "Parent") }
      let!(:child) { create(:task, parent: parent, title: "Child") }

      it "returns only top-level tasks" do
        get "/api/v1/tasks"

        json = JSON.parse(response.body)
        titles = json["data"].map { |t| t["title"] }
        expect(titles).to include("Parent")
        expect(titles).not_to include("Child")
      end
    end
  end

  describe "GET /api/v1/tasks/:id" do
    let!(:task) { create(:task, :with_category) }

    context "with valid id" do
      it "returns the task" do
        get "/api/v1/tasks/#{task.id}"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(task.id)
        expect(json["title"]).to eq(task.title)
      end

      it "includes category and tags" do
        tag = create(:tag)
        task.tags << tag

        get "/api/v1/tasks/#{task.id}"

        json = JSON.parse(response.body)
        expect(json).to have_key("category")
        expect(json).to have_key("tags")
      end

      it "includes computed fields" do
        get "/api/v1/tasks/#{task.id}"

        json = JSON.parse(response.body)
        expect(json).to have_key("overdue")
        expect(json).to have_key("days_until_due")
      end

      it "includes subtasks" do
        subtask = create(:task, parent: task)

        get "/api/v1/tasks/#{task.id}"

        json = JSON.parse(response.body)
        expect(json).to have_key("subtasks")
        expect(json["subtasks"].map { |st| st["id"] }).to include(subtask.id)
      end
    end

    context "with invalid id" do
      it "returns 404" do
        get "/api/v1/tasks/99999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/tasks" do
    let(:tag1) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:category) { create(:category) }

    context "with valid params" do
      let(:valid_params) do
        {
          task: {
            title: "New Task",
            description: "Task description",
            priority: "high",
            status: "pending",
            due_date: 7.days.from_now
          }
        }
      end

      it "creates a task" do
        expect {
          post "/api/v1/tasks", params: valid_params
        }.to change(Task, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns the created task" do
        post "/api/v1/tasks", params: valid_params

        json = JSON.parse(response.body)
        expect(json["id"]).to be_present
        expect(json["title"]).to eq("New Task")
        expect(json["priority"]).to eq("high")
      end

      it "includes category in response" do
        valid_params[:task][:category_id] = category.id
        post "/api/v1/tasks", params: valid_params

        json = JSON.parse(response.body)
        expect(json).to have_key("category")
        expect(json["category"]["id"]).to eq(category.id)
      end
    end

    context "with tag_ids" do
      let(:valid_params) do
        {
          task: {
            title: "Tagged Task",
            tag_ids: [tag1.id, tag2.id]
          }
        }
      end

      it "associates tags with task" do
        post "/api/v1/tasks", params: valid_params

        json = JSON.parse(response.body)
        expect(json).to have_key("tags")
        tag_ids = json["tags"].map { |t| t["id"] }
        expect(tag_ids).to include(tag1.id, tag2.id)
      end

      it "persists tags atomically" do
        post "/api/v1/tasks", params: valid_params

        created_task = Task.last
        expect(created_task.tags.count).to eq(2)
        expect(created_task.tags).to include(tag1, tag2)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          task: {
            description: "No title provided"
          }
        }
      end

      it "does not create a task" do
        expect {
          post "/api/v1/tasks", params: invalid_params
        }.not_to change(Task, :count)
      end

      it "returns 422 unprocessable_entity" do
        post "/api/v1/tasks", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error messages" do
        post "/api/v1/tasks", params: invalid_params

        json = JSON.parse(response.body)
        expect(json).to have_key("errors")
        expect(json["errors"]).not_to be_empty
      end
    end
  end

  describe "PATCH/PUT /api/v1/tasks/:id" do
    let!(:task) { create(:task) }
    let(:tag1) { create(:tag) }
    let(:tag2) { create(:tag) }

    context "with valid params" do
      let(:update_params) do
        {
          task: {
            title: "Updated Title",
            priority: "high"
          }
        }
      end

      it "updates the task" do
        patch "/api/v1/tasks/#{task.id}", params: update_params

        expect(response).to have_http_status(:ok)
        task.reload
        expect(task.title).to eq("Updated Title")
        expect(task.priority).to eq("high")
      end

      it "returns the updated task" do
        patch "/api/v1/tasks/#{task.id}", params: update_params

        json = JSON.parse(response.body)
        expect(json["id"]).to eq(task.id)
        expect(json["title"]).to eq("Updated Title")
      end
    end

    context "with tag_ids" do
      before do
        task.tags << tag1
      end

      let(:update_params) do
        {
          task: {
            title: "Updated",
            tag_ids: [tag2.id]
          }
        }
      end

      it "replaces tags" do
        patch "/api/v1/tasks/#{task.id}", params: update_params

        json = JSON.parse(response.body)
        tag_ids = json["tags"].map { |t| t["id"] }
        expect(tag_ids).to include(tag2.id)
        expect(tag_ids).not_to include(tag1.id)
      end

      it "clears tags when empty array" do
        update_params[:task][:tag_ids] = []
        patch "/api/v1/tasks/#{task.id}", params: update_params

        json = JSON.parse(response.body)
        expect(json["tags"]).to be_empty
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          task: {
            title: ""
          }
        }
      end

      it "returns 422 unprocessable_entity" do
        patch "/api/v1/tasks/#{task.id}", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not update the task" do
        original_title = task.title
        patch "/api/v1/tasks/#{task.id}", params: invalid_params

        task.reload
        expect(task.title).to eq(original_title)
      end
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    let!(:task) { create(:task) }

    it "deletes the task" do
      expect {
        delete "/api/v1/tasks/#{task.id}"
      }.to change(Task, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for non-existent task" do
      delete "/api/v1/tasks/99999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/tasks/stats" do
    context "with task data" do
      before do
        create_list(:task, 3, status: :pending)
        create_list(:task, 2, status: :completed)
        create_list(:task, 1, status: :in_progress)
        create_list(:task, 1, status: :archived)
      end

      it "returns stats" do
        get "/api/v1/tasks/stats"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to have_key("total")
        expect(json).to have_key("pending")
        expect(json).to have_key("completed")
      end

      it "returns correct total count" do
        get "/api/v1/tasks/stats"

        json = JSON.parse(response.body)
        expect(json["total"]).to eq(7)
      end

      it "returns correct status breakdown" do
        get "/api/v1/tasks/stats"

        json = JSON.parse(response.body)
        expect(json["pending"]).to eq(3)
        expect(json["completed"]).to eq(2)
        expect(json["in_progress"]).to eq(1)
        expect(json["archived"]).to eq(1)
      end

      it "includes priority breakdown" do
        get "/api/v1/tasks/stats"

        json = JSON.parse(response.body)
        expect(json).to have_key("by_priority")
        expect(json["by_priority"]).to have_key("low")
        expect(json["by_priority"]).to have_key("high")
      end

      it "includes category breakdown" do
        get "/api/v1/tasks/stats"

        json = JSON.parse(response.body)
        expect(json).to have_key("by_category")
      end

      it "calculates completion_rate" do
        get "/api/v1/tasks/stats"

        json = JSON.parse(response.body)
        expected_rate = (2.to_f / 7 * 100).round(2)
        expect(json["completion_rate"]).to eq(expected_rate)
      end

      it "counts overdue tasks" do
        create(:task, :overdue)
        get "/api/v1/tasks/stats"

        json = JSON.parse(response.body)
        expect(json["overdue"]).to be >= 1
      end
    end

    context "with empty database" do
      it "returns all zeros" do
        get "/api/v1/tasks/stats"

        json = JSON.parse(response.body)
        expect(json["total"]).to eq(0)
        expect(json["completion_rate"]).to eq(0.0)
      end
    end
  end

  describe "POST /api/v1/tasks/bulk_update" do
    let!(:task1) { create(:task, status: :pending) }
    let!(:task2) { create(:task, status: :pending) }

    context "with valid params" do
      let(:bulk_params) do
        {
          task_ids: [task1.id, task2.id],
          updates: { status: "completed" }
        }
      end

      it "updates multiple tasks" do
        post "/api/v1/tasks/bulk_update", params: bulk_params

        task1.reload
        task2.reload
        expect(task1.status).to eq("completed")
        expect(task2.status).to eq("completed")
      end

      it "returns updated count" do
        post "/api/v1/tasks/bulk_update", params: bulk_params

        json = JSON.parse(response.body)
        expect(json["updated_count"]).to eq(2)
      end
    end

    context "without task_ids" do
      it "returns 400" do
        post "/api/v1/tasks/bulk_update", params: { updates: { status: "completed" } }
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without updates" do
      it "returns 400" do
        post "/api/v1/tasks/bulk_update", params: { task_ids: [task1.id] }
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "DELETE /api/v1/tasks/bulk_delete" do
    let!(:task1) { create(:task) }
    let!(:task2) { create(:task) }

    context "with valid params" do
      it "deletes multiple tasks" do
        expect {
          delete "/api/v1/tasks/bulk_delete", params: { task_ids: [task1.id, task2.id] }
        }.to change(Task, :count).by(-2)
      end

      it "returns deleted count" do
        delete "/api/v1/tasks/bulk_delete", params: { task_ids: [task1.id, task2.id] }

        json = JSON.parse(response.body)
        expect(json["deleted_count"]).to eq(2)
      end
    end

    context "without task_ids" do
      it "returns 400" do
        delete "/api/v1/tasks/bulk_delete", params: {}
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "POST /api/v1/tasks/reorder" do
    let!(:task1) { create(:task, position: 1) }
    let!(:task2) { create(:task, position: 2) }

    context "with valid params" do
      let(:reorder_params) do
        {
          positions: [
            { id: task1.id, position: 2 },
            { id: task2.id, position: 1 }
          ]
        }
      end

      it "reorders tasks" do
        post "/api/v1/tasks/reorder", params: reorder_params

        task1.reload
        task2.reload
        expect(task1.position).to eq(2)
        expect(task2.position).to eq(1)
      end

      it "returns success" do
        post "/api/v1/tasks/reorder", params: reorder_params

        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["updated_count"]).to eq(2)
      end
    end

    context "without positions" do
      it "returns 400" do
        post "/api/v1/tasks/reorder", params: {}
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
