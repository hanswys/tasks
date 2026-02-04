# Quick Start - Testing Guide

## Installation

```bash
# Navigate to backend directory
cd backend

# Install dependencies (includes test gems)
bundle install

# Prepare test database
bundle exec rake db:test:prepare
```

## Running Tests

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test Suite
```bash
# Query Object tests
bundle exec rspec spec/queries/task_query_spec.rb

# Stats Service tests
bundle exec rspec spec/services/task_stats_service_spec.rb

# Update Service tests
bundle exec rspec spec/services/tasks/update_service_spec.rb

# API Request tests
bundle exec rspec spec/requests/api/v1/tasks_spec.rb
```

### Run Single Test
```bash
# Run specific test by line number
bundle exec rspec spec/queries/task_query_spec.rb:25

# Run tests matching pattern
bundle exec rspec spec/queries/task_query_spec.rb -e "filters by status"
```

### View Test Output
```bash
# Show test names (documentation format)
bundle exec rspec --format documentation

# Show progress dots
bundle exec rspec --format progress

# Show failures with full backtraces
bundle exec rspec --format progress --backtrace
```

## Test Suites Overview

### 1. Query Object Tests (spec/queries/task_query_spec.rb)
- **Tests:** 43
- **Focus:** Filtering, sorting, pagination
- **Run:** `bundle exec rspec spec/queries/task_query_spec.rb`

### 2. Stats Service Tests (spec/services/task_stats_service_spec.rb)
- **Tests:** 31
- **Focus:** Statistics calculations, mathematical accuracy
- **Run:** `bundle exec rspec spec/services/task_stats_service_spec.rb`

### 3. Update Service Tests (spec/services/tasks/update_service_spec.rb)
- **Tests:** 37
- **Focus:** Create/update operations, atomicity, tag handling
- **Run:** `bundle exec rspec spec/services/tasks/update_service_spec.rb`

### 4. API Integration Tests (spec/requests/api/v1/tasks_spec.rb)
- **Tests:** 51
- **Focus:** All HTTP endpoints, request/response validation
- **Run:** `bundle exec rspec spec/requests/api/v1/tasks_spec.rb`

## Expected Results

```
Finished in 10.23 seconds (files took 2.14s to load)
180 examples, 0 failures

Coverage report generated for RSpec to /coverage. 1225 / 1523 LOC (80.4%) covered.
```

## Helpful Options

```bash
# Run tests in random order (catches hidden dependencies)
bundle exec rspec --order random

# Show 10 slowest tests
bundle exec rspec --profile 10

# Run only failing tests from last run
bundle exec rspec --only-failures

# Generate coverage report
bundle exec rspec --require coverage

# Verbose output
bundle exec rspec --format documentation -v
```

## Debugging Tips

### Add Pry Breakpoint
```ruby
it "filters tasks correctly" do
  binding.pry  # Execution pauses here
  result = TaskQuery.new.call(filters: { status: :pending })
end
```

### Print Debug Information
```ruby
it "calculates stats correctly" do
  stats = TaskStatsService.new.calculate
  puts stats.inspect  # See actual values
  expect(stats[:total]).to eq(5)
end
```

### Run Single Test with Full Output
```bash
bundle exec rspec spec/queries/task_query_spec.rb:50 -f documentation --backtrace
```

## Test File Structure

```
spec/
├── rails_helper.rb                 # Rails config & DatabaseCleaner
├── spec_helper.rb                  # Base RSpec config
├── .rspec                          # CLI options
├── factories/
│   └── tasks.rb                    # Test data factories
├── queries/
│   └── task_query_spec.rb          # Query object tests
├── services/
│   ├── task_stats_service_spec.rb  # Stats service tests
│   └── tasks/
│       └── update_service_spec.rb  # Update service tests
└── requests/
    └── api/v1/
        └── tasks_spec.rb           # API endpoint tests
```

## Factory Usage

```ruby
# Create single task
task = create(:task)

# Create multiple tasks
tasks = create_list(:task, 5)

# With specific attributes
task = create(:task, status: :completed, priority: :high)

# With traits
task = create(:task, :with_category, :with_tags, :overdue)

# Build without saving
task = build(:task)
```

## Common Test Patterns

### Test Filtering
```ruby
it "filters by status" do
  pending = create(:task, status: :pending)
  completed = create(:task, status: :completed)
  
  result = TaskQuery.new.call(filters: { status: :pending })
  expect(result[:data]).to include(pending)
  expect(result[:data]).not_to include(completed)
end
```

### Test API Endpoint
```ruby
it "returns tasks" do
  task = create(:task)
  get "/api/v1/tasks"
  
  expect(response).to have_http_status(:ok)
  json = JSON.parse(response.body)
  expect(json["data"].count).to eq(1)
end
```

### Test Service
```ruby
it "creates task with tags" do
  tag = create(:tag)
  result = Tasks::UpdateService.new(Task.new).call(
    task_params: { title: "Task" },
    tag_ids: [tag.id]
  )
  
  expect(result.success?).to be true
  expect(result.task.tags).to include(tag)
end
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Tests fail randomly | Run with `--order random` to detect dependencies |
| Database not cleaning | Check `spec/rails_helper.rb` DatabaseCleaner config |
| Factory errors | Verify all required fields in factory definition |
| Slow tests | Use `let` instead of `let!`, or add `--profile 10` |
| Validation errors | Check Task model validations in `app/models/task.rb` |

## CI/CD Integration

### GitHub Actions
```yaml
- name: Run RSpec
  run: bundle exec rspec
```

### Pre-commit Hook
```bash
#!/bin/bash
bundle exec rspec || exit 1
```

## Coverage

Generate coverage report:
```bash
bundle exec rspec --require coverage
open coverage/index.html
```

Expected: **80%+ coverage** of application code

## Documentation

For detailed information, see:
- [TESTING.md](./TESTING.md) - Comprehensive testing guide
- [TEST_SUITE_SUMMARY.md](./TEST_SUITE_SUMMARY.md) - Complete test inventory
