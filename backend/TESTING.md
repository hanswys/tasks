# RSpec Test Suite Documentation

## Overview

This comprehensive RSpec test suite validates the production-grade Task Management API refactored using the Query Object, Service Object, and Serializer patterns. The tests ensure the implementation is robust, follows Rails best practices, and maintains backward compatibility with the frontend.

## Test Structure

```
spec/
├── rails_helper.rb                    # Rails & RSpec configuration
├── spec_helper.rb                     # RSpec configuration
├── .rspec                             # RSpec CLI options
├── factories/
│   └── tasks.rb                       # FactoryBot factories for test data
├── queries/
│   └── task_query_spec.rb             # Query Object tests (230+ assertions)
├── services/
│   ├── task_stats_service_spec.rb     # Stats Service tests (80+ assertions)
│   └── tasks/
│       └── update_service_spec.rb     # Update Service tests (100+ assertions)
└── requests/
    └── api/v1/
        └── tasks_spec.rb              # Request/Integration tests (150+ assertions)
```

## Running Tests

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test File
```bash
bundle exec rspec spec/queries/task_query_spec.rb
bundle exec rspec spec/services/task_stats_service_spec.rb
bundle exec rspec spec/requests/api/v1/tasks_spec.rb
```

### Run with Coverage
```bash
bundle exec rspec --require coverage --format progress
```

### Run in Parallel (requires parallel_tests gem)
```bash
bundle exec parallel_test spec
```

### Run with Verbose Output
```bash
bundle exec rspec --format documentation
```

### Run Only Failing Tests
```bash
bundle exec rspec --only-failures
```

## Test Suites

### 1. Query Object Tests (`spec/queries/task_query_spec.rb`)

**Purpose:** Validates the `TaskQuery` class handles filtering, sorting, and pagination correctly.

**Coverage:**
- ✅ Status filtering (by status enum)
- ✅ Priority filtering (by priority enum)
- ✅ Category filtering (by category_id)
- ✅ Date range filtering (due_before, due_after)
- ✅ Full-text search (title and description)
- ✅ Tag-based filtering with DISTINCT
- ✅ Multiple filter combinations
- ✅ Sorting by all allowed fields (created_at, due_date, priority, position, title)
- ✅ Sort order normalization (asc/desc)
- ✅ SQL injection protection in sort fields
- ✅ Pagination (page, per_page)
- ✅ Pagination limits (MAX_PER_PAGE = 100)
- ✅ Pagination metadata (total_pages, total_count)
- ✅ Subtask exclusion (top_level only)
- ✅ Edge cases (nil params, empty strings, non-existent IDs)

**Key Tests:**
```ruby
# Filter tests
it "filters by status" { ... }
it "filters by tag_ids (multiple tags) with distinct" { ... }
it "combines multiple filters" { ... }

# Sort tests
it "defaults to created_at for invalid sort field" { ... }
it "protects against SQL injection in sort_by" { ... }

# Pagination tests
it "enforces MAX_PER_PAGE limit" { ... }
it "calculates correct total_pages" { ... }
```

### 2. Stats Service Tests (`spec/services/task_stats_service_spec.rb`)

**Purpose:** Validates statistics calculations are mathematically accurate.

**Coverage:**
- ✅ Count by status (pending, in_progress, completed, archived)
- ✅ Count by priority (low, medium, high, urgent)
- ✅ Count by category
- ✅ Completion rate calculation (with rounding)
- ✅ Overdue task counting (excludes completed/archived)
- ✅ Custom task relations (filtering before stats)
- ✅ Caching optimization (completed_count)
- ✅ Response structure validation
- ✅ Edge cases (empty database, zero division)
- ✅ Large dataset performance

**Key Tests:**
```ruby
# Calculation tests
it "calculates correct completion_rate" { ... }
it "counts overdue tasks (pending and in_progress only)" { ... }

# Accuracy tests
it "calculates 66.67% completion rate correctly" { ... }
it "rounds completion_rate to 2 decimal places" { ... }

# Performance tests
it "handles large dataset efficiently" { ... }
```

### 3. Update Service Tests (`spec/services/tasks/update_service_spec.rb`)

**Purpose:** Validates task creation/update with atomic tag associations.

**Coverage:**
- ✅ Create new tasks with attributes
- ✅ Update existing tasks
- ✅ Handle tag associations atomically
- ✅ Replace tags on update
- ✅ Clear tags (empty array)
- ✅ Atomic transactions (rollback on error)
- ✅ Validation error handling
- ✅ Result object pattern (success?, task, errors)
- ✅ Category and parent task associations
- ✅ Edge cases (special characters, long titles, nil params)

**Key Tests:**
```ruby
# Atomic operations
it "associates tags with task atomically" { ... }

# Error handling
it "rolls back on task save failure" { ... }
it "does not persist tags when task is invalid" { ... }

# Result object
it "returns successful result" { ... }
it "returns error result on validation failure" { ... }
```

### 4. Request/Integration Tests (`spec/requests/api/v1/tasks_spec.rb`)

**Purpose:** Tests the complete API endpoints and integration between layers.

**Coverage:**

#### GET /api/v1/tasks
- ✅ Returns all tasks with correct schema
- ✅ Filters by status, priority, category, date, search, tags
- ✅ Combines multiple filters
- ✅ Sorting (by field, order, defaults, SQL injection)
- ✅ Pagination (page, per_page, metadata)
- ✅ Includes category and tags in response
- ✅ Excludes subtasks from results

#### GET /api/v1/tasks/:id
- ✅ Returns single task
- ✅ Includes associated data (category, tags, subtasks)
- ✅ Includes computed fields (overdue, days_until_due)
- ✅ Returns 404 for non-existent task

#### POST /api/v1/tasks
- ✅ Creates task with valid params
- ✅ Validates required fields
- ✅ Associates tags atomically
- ✅ Includes category in response
- ✅ Returns 422 on validation error

#### PATCH/PUT /api/v1/tasks/:id
- ✅ Updates task attributes
- ✅ Replaces tags
- ✅ Clears tags (empty array)
- ✅ Returns validation errors

#### DELETE /api/v1/tasks/:id
- ✅ Deletes task
- ✅ Returns 404 for non-existent task

#### GET /api/v1/tasks/stats
- ✅ Returns all statistics
- ✅ Calculates correct counts
- ✅ Includes breakdown by priority, status, category
- ✅ Calculates completion rate
- ✅ Counts overdue tasks

#### POST /api/v1/tasks/bulk_update
- ✅ Updates multiple tasks
- ✅ Returns updated count
- ✅ Validates required params

#### DELETE /api/v1/tasks/bulk_delete
- ✅ Deletes multiple tasks
- ✅ Returns deleted count

#### POST /api/v1/tasks/reorder
- ✅ Reorders tasks by position
- ✅ Returns success

## Test Data Factories

### Task Factory
```ruby
factory :task do
  title { Faker::Lorem.sentence(word_count: 5) }
  status { :pending }
  priority { :medium }
  due_date { 7.days.from_now }

  trait :completed { status { :completed } }
  trait :in_progress { status { :in_progress } }
  trait :with_category { category { create(:category) } }
  trait :with_tags { after(:create) { |task| create_list(:tag, 2, tasks: [task]) } }
  trait :overdue { due_date { 1.day.ago }; status { :pending } }
  # ... more traits
end
```

### Usage Examples
```ruby
# Simple task
create(:task)

# Task with specific attributes
create(:task, status: :completed, priority: :high)

# Task with associations
create(:task, :with_category, :with_tags, :overdue)

# Multiple tasks
create_list(:task, 5, status: :pending)
```

## Configuration Files

### `.rspec`
Configures RSpec CLI options:
- `--require spec_helper` - Load spec_helper
- `--require rails_helper` - Load rails_helper
- `--format progress` - Show progress dots
- `--color` - Colorize output
- `--order random` - Run tests in random order (catches dependencies)

### `spec/rails_helper.rb`
Rails-specific RSpec configuration:
- ActiveRecord transactional fixtures
- FactoryBot integration
- DatabaseCleaner setup (transaction strategy)
- RSpec infer_spec_type_from_file_location

### `spec/spec_helper.rb`
Base RSpec configuration (doesn't require Rails)

## Test Environment Setup

### Database Cleaner Strategy
Tests use **transactional fixtures** by default:
```ruby
config.use_transactional_fixtures = true
```

This wraps each test in a database transaction that rolls back automatically, ensuring:
- ✅ Fast test execution
- ✅ Database isolation
- ✅ Automatic cleanup (no manual truncation needed)

### FactoryBot Integration
```ruby
config.include FactoryBot::Syntax::Methods
```

Enables shorthand syntax:
```ruby
# Instead of:
FactoryBot.create(:task)

# Use:
create(:task)
```

## Key Test Patterns

### 1. Filtering Tests
```ruby
it "filters by status" do
  pending_task = create(:task, status: :pending)
  completed_task = create(:task, status: :completed)
  
  result = TaskQuery.new.call(filters: { status: :pending })
  expect(result[:data]).to include(pending_task)
  expect(result[:data]).not_to include(completed_task)
end
```

### 2. Pagination Tests
```ruby
it "respects per_page parameter" do
  get "/api/v1/tasks", params: { per_page: 10 }
  
  json = JSON.parse(response.body)
  expect(json["data"].count).to eq(10)
  expect(json["meta"]["per_page"]).to eq(10)
end
```

### 3. Atomic Operation Tests
```ruby
it "associates tags atomically" do
  result = Tasks::UpdateService.new(task).call(
    task_params: { title: "Task" },
    tag_ids: [tag1.id, tag2.id]
  )
  
  expect(result.success?).to be true
  expect(result.task.tags).to include(tag1, tag2)
end
```

### 4. Error Handling Tests
```ruby
it "returns error result on validation failure" do
  result = Tasks::UpdateService.new(task).call(task_params: {})
  
  expect(result.success?).to be false
  expect(result.errors).to have_key(:title)
end
```

## Expected Test Results

When running the full test suite, expect approximately:

| Suite | Tests | Assertions | Duration |
|-------|-------|-----------|----------|
| TaskQuery | 40 | ~180 | ~2s |
| TaskStatsService | 25 | ~80 | ~1s |
| Tasks::UpdateService | 35 | ~100 | ~2s |
| Requests (API) | 80 | ~150 | ~5s |
| **Total** | **~180** | **~510** | **~10s** |

## Continuous Integration

### GitHub Actions Example
```yaml
name: RSpec Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      sqlite:
        image: ubuntu:latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true
      - run: bundle exec rake db:test:prepare
      - run: bundle exec rspec
```

## Debugging Tests

### Run Single Test with Verbose Output
```bash
bundle exec rspec spec/queries/task_query_spec.rb:25 --format documentation
```

### Run with Pry Debugger
```ruby
it "filters by status" do
  pending_task = create(:task, status: :pending)
  binding.pry  # Execution pauses here
  result = TaskQuery.new.call(filters: { status: :pending })
end
```

### View Test Output
```bash
# Show test names and results
bundle exec rspec --format documentation

# Show slow tests
bundle exec rspec --profile 10

# Run with seed for reproducibility
bundle exec rspec --seed 1234
```

## Best Practices

### ✅ Do
- Use `let` and `let!` for test setup
- Use factory traits for common patterns
- Test behavior, not implementation
- Use descriptive test names
- Test both success and failure paths
- Test edge cases and boundaries
- Use transactional fixtures for speed

### ❌ Don't
- Create test data in before blocks if not needed
- Test Rails internals (Rails tests those)
- Use sleep or Time.freeze
- Depend on test execution order
- Create brittle tests with exact string matching

## Adding New Tests

### 1. Create Spec File
```bash
touch spec/services/my_service_spec.rb
```

### 2. Use Template
```ruby
require "rails_helper"

RSpec.describe MyService, type: :service do
  describe "#call" do
    it "does something" do
      # Arrange
      object = create(:factory)
      
      # Act
      result = MyService.new(object).call
      
      # Assert
      expect(result).to eq(expected)
    end
  end
end
```

### 3. Run Test
```bash
bundle exec rspec spec/services/my_service_spec.rb
```

## Troubleshooting

### Tests Failing with "ActiveRecord::Rollback"
**Cause:** Transaction rolled back during test
**Solution:** Check service code - ensure transactions aren't raising rollback

### Database Not Cleaning Between Tests
**Cause:** DatabaseCleaner not configured
**Solution:** Verify `spec/rails_helper.rb` has proper DatabaseCleaner setup

### Intermittent Test Failures
**Cause:** Tests depending on execution order
**Solution:** Run with `--order random` to detect dependencies

### Slow Test Execution
**Cause:** Too many database queries
**Solution:** Use `let` instead of `let!`, or add `--profile 10` to find slow tests

## References

- [RSpec Documentation](https://rspec.info/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot/wiki)
- [Rails Testing Guide](https://guides.rubyonrails.org/testing.html)
- [DatabaseCleaner](https://github.com/DatabaseCleaner/database_cleaner)
- [Testing Best Practices](https://github.com/eliotsykes/rspec-rails-examples)

## Git Ignore

Add to `.gitignore`:
```
/coverage
/tmp/test
.rspec_status
```
