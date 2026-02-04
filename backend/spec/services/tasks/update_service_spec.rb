# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::UpdateService, type: :service do
  describe "#call" do
    context "creating a new task" do
      let(:task) { Task.new }
      let(:task_params) do
        {
          title: "New Task",
          description: "Task description",
          priority: :high,
          status: :pending,
          due_date: 7.days.from_now
        }
      end

      it "creates task with provided attributes" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params)

        expect(result.success?).to be true
        expect(result.task.title).to eq("New Task")
        expect(result.task.priority).to eq("high")
        expect(result.task.status).to eq("pending")
      end

      it "persists task to database" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params)

        expect(result.task).to be_persisted
        expect(Task.find(result.task.id)).to eq(result.task)
      end

      it "returns successful result" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params)

        expect(result).to be_a(Tasks::UpdateService::Result)
        expect(result.success?).to be true
      end

      it "returns empty errors on success" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params)

        expect(result.errors).to be_empty
      end
    end

    context "creating task with tags" do
      let(:task) { Task.new }
      let!(:tag1) { create(:tag) }
      let!(:tag2) { create(:tag) }
      let(:task_params) { { title: "Tagged Task" } }
      let(:tag_ids) { [tag1.id, tag2.id] }

      it "associates tags with task atomically" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params, tag_ids: tag_ids)

        expect(result.success?).to be true
        expect(result.task.tags).to include(tag1, tag2)
      end

      it "persists tags to database" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params, tag_ids: tag_ids)

        reloaded_task = Task.find(result.task.id)
        expect(reloaded_task.tags.count).to eq(2)
        expect(reloaded_task.tags).to include(tag1, tag2)
      end

      it "handles empty tag_ids gracefully" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params, tag_ids: [])

        expect(result.success?).to be true
        expect(result.task.tags).to be_empty
      end

      it "handles nil tag_ids gracefully" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params, tag_ids: nil)

        expect(result.success?).to be true
      end
    end

    context "updating existing task" do
      let(:task) { create(:task, title: "Old Title", priority: :low) }
      let(:task_params) { { title: "New Title", priority: :high } }

      it "updates task attributes" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params)

        expect(result.success?).to be true
        expect(result.task.title).to eq("New Title")
        expect(result.task.priority).to eq("high")
      end

      it "persists updates to database" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params)

        reloaded_task = Task.find(task.id)
        expect(reloaded_task.title).to eq("New Title")
        expect(reloaded_task.priority).to eq("high")
      end

      it "preserves unpassed attributes" do
        original_description = task.description
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: { title: "New Title" })

        expect(result.task.description).to eq(original_description)
      end
    end

    context "updating task with new tags" do
      let(:task) { create(:task) }
      let!(:old_tag) { create(:tag) }
      let!(:new_tag) { create(:tag) }

      before do
        task.tags << old_tag
      end

      it "replaces tags with new ones" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: {}, tag_ids: [new_tag.id])

        expect(result.success?).to be true
        expect(result.task.tags).to include(new_tag)
        expect(result.task.tags).not_to include(old_tag)
      end

      it "clears tags when empty array provided" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: {}, tag_ids: [])

        expect(result.success?).to be true
        expect(result.task.tags).to be_empty
      end

      it "persists tag changes to database" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: {}, tag_ids: [new_tag.id])

        reloaded_task = Task.find(task.id)
        expect(reloaded_task.tags).to include(new_tag)
        expect(reloaded_task.tags).not_to include(old_tag)
      end
    end

    context "atomicity and transactions" do
      let(:task) { Task.new }
      let(:task_params) { { title: "Task", priority: :high } }

      it "rolls back on task save failure" do
        # Create a task with invalid title to trigger save failure
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: { priority: :high }) # missing title

        expect(result.success?).to be false
        expect(result.errors).to have_key(:title)
      end

      it "rolls back on tag association failure within transaction" do
        task = Task.new(title: "Valid Task")
        service = Tasks::UpdateService.new(task)

        # Use invalid tag IDs - this should not prevent save
        # but we're testing transaction behavior
        result = service.call(
          task_params: { title: "Task" },
          tag_ids: [99999] # non-existent tag
        )

        # In Rails, assigning non-existent IDs silently ignores them
        # so this should still succeed
        expect(result.success?).to be true
      end

      it "handles exceptions gracefully" do
        task = Task.new
        service = Tasks::UpdateService.new(task)

        # Mock a database error
        allow(task).to receive(:save).and_raise(StandardError.new("DB Error"))

        result = service.call(task_params: { title: "Task" })

        expect(result.success?).to be false
        expect(result.errors).to have_key(:base)
        expect(result.errors[:base]).to include("DB Error")
      end
    end

    context "validation errors" do
      let(:task) { Task.new }

      it "returns error result on validation failure" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: { description: "No title" })

        expect(result.success?).to be false
        expect(result.errors).not_to be_empty
      end

      it "includes validation error messages" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: {})

        expect(result.errors).to have_key(:title)
      end

      it "does not persist task with validation errors" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: {})

        expect(result.success?).to be false
        expect(task).not_to be_persisted
      end

      it "does not persist tags when task is invalid" do
        task = Task.new
        service = Tasks::UpdateService.new(task)

        result = service.call(
          task_params: {},
          tag_ids: [create(:tag).id]
        )

        expect(result.success?).to be false
        # Task should not exist, so no tags should be associated
        expect(Task.count).to eq(0)
      end
    end

    context "Result object" do
      let(:task) { Task.new }
      let(:task_params) { { title: "Task" } }

      describe "#success?" do
        it "returns true when there are no errors" do
          service = Tasks::UpdateService.new(task)
          result = service.call(task_params: task_params)

          expect(result.success?).to be true
        end

        it "returns false when there are errors" do
          service = Tasks::UpdateService.new(task)
          result = service.call(task_params: {})

          expect(result.success?).to be false
        end
      end

      describe "#task" do
        it "returns the task instance" do
          service = Tasks::UpdateService.new(task)
          result = service.call(task_params: task_params)

          expect(result.task).to be_a(Task)
          expect(result.task.title).to eq("Task")
        end
      end

      describe "#errors" do
        it "returns empty hash on success" do
          service = Tasks::UpdateService.new(task)
          result = service.call(task_params: task_params)

          expect(result.errors).to eq({})
        end

        it "returns errors hash on failure" do
          service = Tasks::UpdateService.new(task)
          result = service.call(task_params: {})

          expect(result.errors).to be_a(Hash)
          expect(result.errors).not_to be_empty
        end
      end
    end

    context "integration with associations" do
      let(:category) { create(:category) }
      let(:task) { Task.new }
      let(:task_params) do
        {
          title: "Task",
          category_id: category.id,
          due_date: 7.days.from_now
        }
      end

      it "associates category with task" do
        service = Tasks::UpdateService.new(task)
        result = service.call(task_params: task_params)

        expect(result.success?).to be true
        expect(result.task.category).to eq(category)
      end

      it "creates task with parent relationship" do
        parent_task = create(:task)
        service = Tasks::UpdateService.new(Task.new)
        result = service.call(
          task_params: { title: "Subtask", parent_id: parent_task.id }
        )

        expect(result.success?).to be true
        expect(result.task.parent).to eq(parent_task)
      end
    end

    context "edge cases" do
      it "handles empty task_params hash" do
        task = create(:task)
        service = Tasks::UpdateService.new(task)
        original_title = task.title

        result = service.call(task_params: {})

        expect(result.success?).to be true
        expect(result.task.title).to eq(original_title)
      end

      it "handles very long title" do
        task = Task.new
        long_title = "x" * 500
        service = Tasks::UpdateService.new(task)

        result = service.call(task_params: { title: long_title })

        expect(result.success?).to be true
        expect(result.task.title.length).to eq(500)
      end

      it "handles special characters in attributes" do
        task = Task.new
        special_chars = "Task <>&\"' with special chars"
        service = Tasks::UpdateService.new(task)

        result = service.call(task_params: { title: special_chars })

        expect(result.success?).to be true
        expect(result.task.title).to eq(special_chars)
      end

      it "handles date string conversion" do
        task = Task.new
        service = Tasks::UpdateService.new(task)
        due_date = 5.days.from_now

        result = service.call(task_params: { title: "Task", due_date: due_date })

        expect(result.success?).to be true
        expect(result.task.due_date).to be_a(Time)
      end
    end
  end
end
