# Test Suite Validation Checklist

Use this checklist to verify the test suite is properly installed and working.

## ✅ Pre-Installation Checks

- [ ] Ruby version 3.0+ is installed
  ```bash
  ruby --version
  ```

- [ ] Bundler is installed
  ```bash
  bundler --version
  ```

- [ ] Working in correct directory
  ```bash
  cd /Users/hans/Desktop/ruby-apps/tasks/backend
  ```

## ✅ Installation Steps

- [ ] Gemfile updated with test gems
  ```bash
  grep "rspec-rails" Gemfile
  grep "factory_bot" Gemfile
  grep "database_cleaner" Gemfile
  grep "faker" Gemfile
  ```

- [ ] Gems installed
  ```bash
  bundle install
  ```

- [ ] Verify rspec-rails is installed
  ```bash
  bundle exec rspec --version
  ```

## ✅ File Structure Verification

### Test Configuration Files
- [ ] `spec/rails_helper.rb` exists
- [ ] `spec/spec_helper.rb` exists
- [ ] `.rspec` exists in project root

### Test Spec Files
- [ ] `spec/queries/task_query_spec.rb` exists
- [ ] `spec/services/task_stats_service_spec.rb` exists
- [ ] `spec/services/tasks/update_service_spec.rb` exists
- [ ] `spec/requests/api/v1/tasks_spec.rb` exists

### Factory Files
- [ ] `spec/factories/tasks.rb` exists
- [ ] `spec/support/.keep` exists

### Documentation Files
- [ ] `TESTING.md` exists
- [ ] `TEST_SUITE_SUMMARY.md` exists
- [ ] `QUICK_START_TESTING.md` exists
- [ ] `REFACTORING_DOCUMENTATION.md` exists (from previous refactoring)

## ✅ Database Setup

- [ ] Test database exists
  ```bash
  bundle exec rake db:test:prepare
  ```

- [ ] Database is clean
  ```bash
  bundle exec rake db:test:load
  ```

- [ ] Migrations are up to date
  ```bash
  bundle exec rake db:migrate RAILS_ENV=test
  ```

## ✅ Application Code Verification

### Controllers
- [ ] `app/controllers/api/v1/tasks_controller.rb` exists
- [ ] Controller uses TaskQuery, TaskStatsService, Tasks::UpdateService, TaskSerializer

### Query Objects
- [ ] `app/queries/task_query.rb` exists
- [ ] Has ALLOWED_SORT_FIELDS constant
- [ ] Has MAX_PER_PAGE constant
- [ ] Has #call method with filters, sort, page, per_page

### Service Objects
- [ ] `app/services/task_stats_service.rb` exists
- [ ] Has #calculate method
- [ ] `app/services/tasks/update_service.rb` exists
- [ ] Has Result class with #success? method

### Serializers
- [ ] `app/serializers/task_serializer.rb` exists
- [ ] Has #as_json method with include parameter

### Models
- [ ] `app/models/task.rb` has required scopes
- [ ] Has associations: category, tags, parent, subtasks
- [ ] Has methods: overdue?, days_until_due

## ✅ Test Execution

### Run Full Test Suite
```bash
bundle exec rspec
```

Expected output:
```
Finished in ~10 seconds (files took ~2s to load)
~180 examples, 0 failures
```

- [ ] All tests pass
- [ ] No pending tests
- [ ] No skipped tests
- [ ] Execution time < 15 seconds

### Run Individual Suites
```bash
bundle exec rspec spec/queries/task_query_spec.rb
```
- [ ] Query tests pass (43 tests)

```bash
bundle exec rspec spec/services/task_stats_service_spec.rb
```
- [ ] Stats service tests pass (31 tests)

```bash
bundle exec rspec spec/services/tasks/update_service_spec.rb
```
- [ ] Update service tests pass (37 tests)

```bash
bundle exec rspec spec/requests/api/v1/tasks_spec.rb
```
- [ ] Request tests pass (51 tests)

## ✅ Specific Feature Tests

### Query Object
- [ ] Run: `bundle exec rspec spec/queries/task_query_spec.rb -e "filters"`
  - [ ] All filtering tests pass

- [ ] Run: `bundle exec rspec spec/queries/task_query_spec.rb -e "sorting"`
  - [ ] All sorting tests pass

- [ ] Run: `bundle exec rspec spec/queries/task_query_spec.rb -e "pagination"`
  - [ ] All pagination tests pass

### Stats Service
- [ ] Run: `bundle exec rspec spec/services/task_stats_service_spec.rb -e "status"`
  - [ ] Status breakdown tests pass

- [ ] Run: `bundle exec rspec spec/services/task_stats_service_spec.rb -e "completion_rate"`
  - [ ] Completion rate calculations correct

- [ ] Run: `bundle exec rspec spec/services/task_stats_service_spec.rb -e "overdue"`
  - [ ] Overdue counting excludes completed/archived

### Update Service
- [ ] Run: `bundle exec rspec spec/services/tasks/update_service_spec.rb -e "creates"`
  - [ ] Create operations work

- [ ] Run: `bundle exec rspec spec/services/tasks/update_service_spec.rb -e "atomic"`
  - [ ] Transaction rollback works correctly

- [ ] Run: `bundle exec rspec spec/services/tasks/update_service_spec.rb -e "validation"`
  - [ ] Validation errors handled properly

### API Requests
- [ ] Run: `bundle exec rspec spec/requests/api/v1/tasks_spec.rb -e "GET /api/v1/tasks"`
  - [ ] Index endpoint works with filters, sort, pagination

- [ ] Run: `bundle exec rspec spec/requests/api/v1/tasks_spec.rb -e "POST /api/v1/tasks"`
  - [ ] Create endpoint works with tags

- [ ] Run: `bundle exec rspec spec/requests/api/v1/tasks_spec.rb -e "stats"`
  - [ ] Stats endpoint returns correct data

## ✅ Advanced Verification

### Test Isolation
```bash
bundle exec rspec --order random
```
- [ ] All tests pass in random order (no hidden dependencies)

### Test Coverage
```bash
bundle exec rspec --require coverage
```
- [ ] Coverage report generated
- [ ] Application code coverage >= 80%

### Performance
```bash
bundle exec rspec --profile 10
```
- [ ] No test takes more than 1 second
- [ ] Full suite completes in < 15 seconds

### Code Quality
```bash
bundle exec rubocop spec
```
- [ ] No RuboCop style violations in spec files
- [ ] RuboCop passes on application code

## ✅ Factory Verification

Test factories work correctly:
```bash
bundle exec rspec -c -f documentation spec/factories/tasks.rb 2>/dev/null || true
```

Or manually verify:
```ruby
# In Rails console
bundle exec rails console --sandbox
Task.new
create(:task)
create(:task, :with_category)
create_list(:task, 5, status: :pending)
```

- [ ] All factory definitions work
- [ ] All traits are functional
- [ ] No validation errors on creation

## ✅ DatabaseCleaner Setup

Verify transaction cleaning works:
```ruby
# spec/rails_helper.rb should have:
# - config.use_transactional_fixtures = true
# - DatabaseCleaner.strategy = :transaction
# - DatabaseCleaner.cleaning block
```

- [ ] Each test runs in clean transaction
- [ ] Database is clean between tests
- [ ] No test pollution between runs

## ✅ Documentation Verification

- [ ] [TESTING.md](./TESTING.md) is comprehensive
  - [ ] Contains setup instructions
  - [ ] Documents all test patterns
  - [ ] Includes troubleshooting guide

- [ ] [TEST_SUITE_SUMMARY.md](./TEST_SUITE_SUMMARY.md) is accurate
  - [ ] Test counts match actual tests
  - [ ] Coverage descriptions accurate
  - [ ] Factory examples work

- [ ] [QUICK_START_TESTING.md](./QUICK_START_TESTING.md) is helpful
  - [ ] Installation steps are clear
  - [ ] Common commands listed
  - [ ] Troubleshooting helpful

- [ ] [REFACTORING_DOCUMENTATION.md](./REFACTORING_DOCUMENTATION.md) explains architecture
  - [ ] Query Object pattern explained
  - [ ] Service Object pattern explained
  - [ ] Serializer pattern explained

## ✅ Integration Checks

### With Application Controller
- [ ] TasksController works with refactored code
- [ ] All endpoints respond correctly
- [ ] JSON responses match expected schema

### With Models
- [ ] Task model associations work
- [ ] Validations work correctly
- [ ] Scopes work as expected

### With Database
- [ ] Migrations are applied
- [ ] Database schema is correct
- [ ] All table relationships intact

## ✅ CI/CD Ready

For GitHub Actions or similar:
- [ ] All tests pass locally with `bundle exec rspec`
- [ ] No gems need manual setup
- [ ] Database is auto-initialized
- [ ] No environment variables required

## 📝 Sign-Off

Once all checkboxes are checked:

- [ ] Test suite is fully installed and operational
- [ ] All 180+ tests pass consistently
- [ ] Documentation is complete and accurate
- [ ] Architecture is properly tested
- [ ] Ready for production use

**Date Verified:** _____________
**Verified By:** _____________

## 🆘 Troubleshooting

If any checks fail, see:
1. [QUICK_START_TESTING.md](./QUICK_START_TESTING.md) - Troubleshooting section
2. [TESTING.md](./TESTING.md) - Detailed documentation
3. [TEST_SUITE_SUMMARY.md](./TEST_SUITE_SUMMARY.md) - Edge cases & fixes
4. Run: `bundle exec rspec --format documentation --backtrace`

## 📞 Support Commands

```bash
# List all tests
bundle exec rspec --dry-run

# Run tests with full output
bundle exec rspec --format documentation

# Run with backtrace
bundle exec rspec --backtrace

# Run specific test with debugging
bundle exec rspec spec/queries/task_query_spec.rb:50 -f documentation

# Check gem versions
bundle show rspec-rails
bundle show factory_bot_rails
bundle show database_cleaner-active_record
```
