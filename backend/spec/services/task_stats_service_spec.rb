# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskStatsService, type: :service do
  describe "#calculate" do
    context "with empty database" do
      it "returns zero counts" do
        stats = TaskStatsService.new.calculate

        expect(stats[:total]).to eq(0)
        expect(stats[:pending]).to eq(0)
        expect(stats[:in_progress]).to eq(0)
        expect(stats[:completed]).to eq(0)
        expect(stats[:archived]).to eq(0)
      end

      it "returns zero completion_rate" do
        stats = TaskStatsService.new.calculate
        expect(stats[:completion_rate]).to eq(0.0)
      end

      it "returns empty category breakdown" do
        stats = TaskStatsService.new.calculate
        expect(stats[:by_category]).to be_empty
      end
    end

    context "with populated database" do
      let!(:pending_tasks) { create_list(:task, 5, status: :pending) }
      let!(:in_progress_tasks) { create_list(:task, 3, status: :in_progress) }
      let!(:completed_tasks) { create_list(:task, 7, status: :completed) }
      let!(:archived_tasks) { create_list(:task, 2, status: :archived) }

      it "counts tasks by status correctly" do
        stats = TaskStatsService.new.calculate

        expect(stats[:total]).to eq(17)
        expect(stats[:pending]).to eq(5)
        expect(stats[:in_progress]).to eq(3)
        expect(stats[:completed]).to eq(7)
        expect(stats[:archived]).to eq(2)
      end

      it "calculates correct completion_rate" do
        stats = TaskStatsService.new.calculate
        expected_rate = (7.to_f / 17 * 100).round(2)

        expect(stats[:completion_rate]).to eq(expected_rate)
      end

      it "includes status breakdown in response" do
        stats = TaskStatsService.new.calculate

        expect(stats[:by_status]).to include(
          pending: 5,
          in_progress: 3,
          completed: 7,
          archived: 2
        )
      end
    end

    context "with priority breakdown" do
      let!(:low_priority) { create_list(:task, 2, priority: :low) }
      let!(:medium_priority) { create_list(:task, 3, priority: :medium) }
      let!(:high_priority) { create_list(:task, 4, priority: :high) }
      let!(:urgent_priority) { create_list(:task, 1, priority: :urgent) }

      it "counts tasks by priority correctly" do
        stats = TaskStatsService.new.calculate

        expect(stats[:by_priority]).to include(
          low: 2,
          medium: 3,
          high: 4,
          urgent: 1
        )
      end

      it "includes priority breakdown in response" do
        stats = TaskStatsService.new.calculate
        expect(stats).to have_key(:by_priority)
      end
    end

    context "with category breakdown" do
      let(:category1) { create(:category) }
      let(:category2) { create(:category) }
      let!(:tasks_in_cat1) { create_list(:task, 5, category: category1) }
      let!(:tasks_in_cat2) { create_list(:task, 3, category: category2) }
      let!(:uncategorized_tasks) { create_list(:task, 2, category: nil) }

      it "counts tasks by category correctly" do
        stats = TaskStatsService.new.calculate

        expect(stats[:by_category][category1.id]).to eq(5)
        expect(stats[:by_category][category2.id]).to eq(3)
      end

      it "includes all categories in breakdown" do
        stats = TaskStatsService.new.calculate

        expect(stats[:by_category]).to have_key(category1.id)
        expect(stats[:by_category]).to have_key(category2.id)
      end

      it "does not include uncategorized tasks in category breakdown" do
        stats = TaskStatsService.new.calculate

        # Uncategorized tasks should not appear in category counts
        expect(stats[:by_category].values.sum).to eq(8)
      end
    end

    context "overdue calculation" do
      let!(:overdue_pending) { create(:task, :overdue) }
      let!(:overdue_in_progress) { create(:task, :overdue, status: :in_progress) }
      let!(:overdue_completed) { create(:task, :overdue_completed) }
      let!(:future_task) { create(:task, due_date: 10.days.from_now) }

      it "counts overdue tasks (pending and in_progress only)" do
        stats = TaskStatsService.new.calculate

        # Should count overdue pending and in_progress, NOT completed
        expect(stats[:overdue]).to eq(2)
      end

      it "does not count completed overdue tasks as overdue" do
        stats = TaskStatsService.new.calculate

        # completed overdue task should not be counted
        expect(stats[:overdue]).not_to include(overdue_completed)
      end

      it "does not count future due dates as overdue" do
        stats = TaskStatsService.new.calculate

        # future task should not be counted
        expect(stats[:overdue]).to eq(2)
      end

      it "excludes archived tasks from overdue count" do
        archived_overdue = create(:task, due_date: 1.day.ago, status: :archived)
        stats = TaskStatsService.new.calculate

        # archived overdue should not be counted
        expect(stats[:overdue]).to eq(2)
      end
    end

    context "response structure" do
      let!(:task) { create(:task, status: :pending) }

      it "returns a hash" do
        stats = TaskStatsService.new.calculate
        expect(stats).to be_a(Hash)
      end

      it "includes all required keys" do
        stats = TaskStatsService.new.calculate

        expect(stats).to have_key(:total)
        expect(stats).to have_key(:pending)
        expect(stats).to have_key(:in_progress)
        expect(stats).to have_key(:completed)
        expect(stats).to have_key(:archived)
        expect(stats).to have_key(:by_priority)
        expect(stats).to have_key(:by_status)
        expect(stats).to have_key(:by_category)
        expect(stats).to have_key(:completion_rate)
        expect(stats).to have_key(:overdue)
      end
    end

    context "with custom task relation" do
      let!(:pending_tasks) { create_list(:task, 3, status: :pending) }
      let!(:completed_tasks) { create_list(:task, 2, status: :completed) }

      it "calculates stats only for provided relation" do
        stats = TaskStatsService.new(Task.where(status: :pending)).calculate

        expect(stats[:total]).to eq(3)
        expect(stats[:pending]).to eq(3)
        expect(stats[:completed]).to eq(0)
      end

      it "calculates accurate completion_rate for filtered relation" do
        pending_only = Task.where(status: :pending)
        stats = TaskStatsService.new(pending_only).calculate

        expect(stats[:completion_rate]).to eq(0.0)
      end

      it "respects filter in category breakdown" do
        category = create(:category)
        pending_with_cat = create(:task, status: :pending, category: category)
        completed_with_cat = create(:task, status: :completed, category: category)

        stats = TaskStatsService.new(Task.where(status: :pending)).calculate

        expect(stats[:by_category][category.id]).to eq(1)
      end
    end

    context "mathematical accuracy" do
      let!(:task1) { create(:task, status: :completed) }
      let!(:task2) { create(:task, status: :completed) }
      let!(:task3) { create(:task, status: :pending) }

      it "calculates 66.67% completion rate correctly" do
        stats = TaskStatsService.new.calculate
        expect(stats[:completion_rate]).to eq(66.67)
      end

      it "rounds completion_rate to 2 decimal places" do
        # Create tasks to get a decimal completion rate
        create_list(:task, 1, status: :completed)
        create_list(:task, 2, status: :pending)
        # 2 completed out of 5 = 40%

        stats = TaskStatsService.new.calculate
        expect(stats[:completion_rate].to_s.split(".").last.length).to be <= 2
      end
    end

    context "performance optimization (caching)" do
      let!(:tasks) { create_list(:task, 10, status: :completed) }

      it "caches completed_count calculation" do
        service = TaskStatsService.new

        # First call should calculate and cache
        expect(service.instance_variable_get(:@completed_tasks)).to be_nil
        stats1 = service.calculate
        cached_value = service.instance_variable_get(:@completed_tasks)
        expect(cached_value).to eq(10)

        # Second internal call should use cached value
        # (if any method calls completed_count twice)
      end
    end

    context "edge cases" do
      it "handles zero total gracefully for completion_rate" do
        stats = TaskStatsService.new.calculate
        expect(stats[:completion_rate]).to eq(0.0)
        expect { stats[:completion_rate] / 100 }.not_to raise_error
      end

      it "returns accurate counts after task creation" do
        stats1 = TaskStatsService.new.calculate
        expect(stats1[:total]).to eq(0)

        create(:task)
        stats2 = TaskStatsService.new.calculate
        expect(stats2[:total]).to eq(1)
      end

      it "handles large dataset efficiently" do
        create_list(:task, 100)

        start_time = Time.current
        stats = TaskStatsService.new.calculate
        duration = Time.current - start_time

        expect(stats[:total]).to eq(100)
        expect(duration).to be < 5 # Should complete in reasonable time
      end
    end
  end
end
