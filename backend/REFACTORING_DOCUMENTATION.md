# Architecture Refactoring Documentation

## Overview

This document outlines the production-grade refactoring of the Task Management system, implementing SOLID principles and Clean Architecture patterns following best practices for Tier-1 SaaS companies.

## Architecture Patterns Implemented

### 1. **Query Object Pattern** (`app/queries/task_query.rb`)

**Purpose:** Encapsulates all filtering, sorting, and pagination logic.

**Benefits:**
- Separates query logic from controllers (Single Responsibility Principle)
- Makes complex queries testable and reusable
- Centralizes filter validation and security checks
- Improves code readability and maintainability

**Key Features:**
- Validates sort fields and orders against whitelists
- Handles pagination with configurable per-page limits
- Supports tag-based filtering with `DISTINCT` to prevent duplicates
- All filters are optional and composable
- Returns structured result with data and metadata

**Usage:**
```ruby
query = TaskQuery.new
result = query.call(
  filters: { status: 'pending', priority: 'high' },
  sort: { by: 'due_date', order: 'asc' },
  page: 1,
  per_page: 20
)

tasks = result[:data]
meta = result[:meta]  # pagination info
```

### 2. **Service Object Pattern**

#### 2a. TaskStatsService (`app/services/task_stats_service.rb`)

**Purpose:** Encapsulates task statistics calculations with caching optimization.

**Benefits:**
- Keeps statistics logic separate from controllers
- Improves testability of complex calculations
- Allows easy extension with additional metrics
- Caches expensive calculations within a single call

**Key Features:**
- Calculates counts by status, priority, and category
- Computes completion rate as a percentage
- Counts overdue tasks (excluding completed/archived)
- Uses efficient SQL grouping for category breakdown
- Lazy-loaded with caching to avoid redundant queries

**Usage:**
```ruby
service = TaskStatsService.new(Task.all)
stats = service.calculate

# stats structure:
{
  total: 100,
  pending: 30,
  in_progress: 20,
  completed: 40,
  archived: 10,
  by_priority: { low: 20, medium: 40, high: 30, urgent: 10 },
  by_status: { ... },
  by_category: { "Work" => 50, "Personal" => 50 },
  completion_rate: 40.0,
  overdue: 5
}
```

#### 2b. Tasks::UpdateService (`app/services/tasks/update_service.rb`)

**Purpose:** Handles atomic task creation and updates with tag association.

**Benefits:**
- Guarantees atomicity via database transactions
- Separates update logic from controller concerns
- Returns structured result objects for error handling
- Handles complex multi-step operations (save + tags)

**Key Features:**
- Transaction wrapping for atomicity
- Result object pattern for error handling
- Validates presence of errors before returning
- Supports both create and update scenarios
- Gracefully handles transaction rollback on errors

**Usage:**
```ruby
service = Tasks::UpdateService.new(task)
result = service.call(
  task_params: { title: 'New Task', due_date: '2026-02-15' },
  tag_ids: [1, 2, 3]
)

if result.success?
  task = result.task
else
  errors = result.errors
end
```

### 3. **Serializer/Presenter Pattern** (`app/serializers/task_serializer.rb`)

**Purpose:** Handles all JSON representation logic, separating presentation from models.

**Benefits:**
- Keeps models free from presentation logic
- Makes JSON structure changes easy to implement
- Improves testability of output format
- Supports multiple serialization formats (multiple vs. single)
- Ensures consistent API responses

**Key Features:**
- Serialize single tasks or collections
- Configurable inclusion of associated records (category, tags, subtasks)
- Includes computed fields (`overdue`, `days_until_due`)
- Recursively handles subtasks
- Sanitizes output to ensure only intended fields are exposed

**Usage:**
```ruby
# Single task
TaskSerializer.new(task).as_json(include: [:category, :tags])

# Multiple tasks
TaskSerializer.new(tasks).as_json(multiple: true, include: [:category, :tags])

# Without associations
TaskSerializer.new(task).as_json(include: [])
```

### 4. **Skinny Controllers**

**Purpose:** Reduce controller responsibility to HTTP concerns only.

**Changes:**
- **Before:** 150+ lines handling queries, stats, serialization
- **After:** ~140 lines focused on request routing and response formatting
- Delegates filtering/sorting → `TaskQuery`
- Delegates statistics → `TaskStatsService`
- Delegates updates with tags → `Tasks::UpdateService`
- Delegates JSON output → `TaskSerializer`

**Controller Responsibilities:**
1. Parse incoming requests
2. Route to appropriate business logic
3. Format HTTP responses
4. Handle authentication/authorization (if added)

## JSON API Response Format

All responses remain **backward compatible** with the existing frontend:

```json
// GET /api/v1/tasks
{
  "data": [
    {
      "id": 1,
      "title": "Task Title",
      "status": "pending",
      "priority": "high",
      "due_date": "2026-02-15",
      "days_until_due": 11,
      "overdue": false,
      "category": {
        "id": 1,
        "name": "Work",
        "color": "#FF5733"
      },
      "tags": [
        {
          "id": 1,
          "name": "urgent",
          "color": "#FF0000"
        }
      ],
      "created_at": "2026-01-01T12:00:00Z",
      "updated_at": "2026-02-01T12:00:00Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 20,
    "total_count": 150,
    "total_pages": 8
  }
}

// GET /api/v1/tasks/stats
{
  "total": 150,
  "pending": 50,
  "in_progress": 40,
  "completed": 50,
  "archived": 10,
  "by_priority": {
    "low": 30,
    "medium": 60,
    "high": 40,
    "urgent": 20
  },
  "by_status": { ... },
  "by_category": {
    "Work": 100,
    "Personal": 50
  },
  "completion_rate": 33.33,
  "overdue": 8
}
```

## SOLID Principles Application

### Single Responsibility Principle (SRP)
- **TaskQuery:** Only filters, sorts, and paginates
- **TaskStatsService:** Only calculates statistics
- **Tasks::UpdateService:** Only handles update logic with atomicity
- **TaskSerializer:** Only handles JSON representation
- **TasksController:** Only routes requests and formats responses

### Open/Closed Principle (OCP)
- Add new filters to `TaskQuery` without modifying controller
- Extend `TaskStatsService` with new metrics without breaking existing code
- Add new serialization formats without affecting models

### Liskov Substitution Principle (LSP)
- Service objects follow consistent interface pattern
- Query objects return predictable result structures
- Serializers can be swapped for different implementations

### Interface Segregation Principle (ISP)
- Services accept only required parameters (no unnecessary dependencies)
- Serializers accept configurable inclusion options
- Query objects accept structured filter hashes

### Dependency Inversion Principle (DIP)
- Controller depends on abstractions (services, query objects)
- Services depend on Task model abstraction
- Easy to inject test doubles or alternative implementations

## Testing Considerations

### Unit Testing Examples

```ruby
# Spec for TaskQuery
describe TaskQuery do
  it 'filters by status' do
    pending_task = create(:task, status: :pending)
    completed_task = create(:task, status: :completed)
    
    result = TaskQuery.new.call(filters: { status: :pending })
    expect(result[:data]).to include(pending_task)
    expect(result[:data]).not_to include(completed_task)
  end
end

# Spec for TaskStatsService
describe TaskStatsService do
  it 'calculates correct completion rate' do
    create(:task, status: :completed)
    create(:task, status: :completed)
    create(:task, status: :pending)
    
    stats = TaskStatsService.new.calculate
    expect(stats[:completion_rate]).to eq(66.67)
  end
end

# Spec for Tasks::UpdateService
describe Tasks::UpdateService do
  it 'atomically updates task with tags' do
    task = create(:task)
    tags = create_list(:tag, 2)
    
    result = Tasks::UpdateService.new(task).call(
      task_params: { title: 'Updated' },
      tag_ids: tags.map(&:id)
    )
    
    expect(result.success?).to be true
    expect(task.reload.title).to eq('Updated')
    expect(task.tags).to match_array(tags)
  end
end

# Spec for TaskSerializer
describe TaskSerializer do
  it 'includes overdue field' do
    task = create(:task, due_date: 1.day.ago, status: :pending)
    
    json = TaskSerializer.new(task).as_json(include: [])
    expect(json[:overdue]).to be true
  end
end
```

## Performance Optimizations

### Query Object
- Validates sort fields to prevent injection attacks
- Uses pagination limits to prevent memory exhaustion
- Supports tag filtering with efficient `DISTINCT` on joins

### Stats Service
- Caches completed_tasks count to avoid redundant queries
- Uses efficient SQL `GROUP BY` for category breakdown
- Single instance variable to track calculation state

### Serializer
- Only includes requested associations (configurable)
- Avoids N+1 queries when called with `multiple: true`

## Migration Guide

### For Frontend Teams
**No changes required!** All JSON keys remain identical.

### For Backend Teams

#### Old Pattern
```ruby
@tasks = Task.all
         .by_status(params[:status])
         .order(created_at: :desc)
         .limit(20)

render json: @tasks.as_json(include: [:category, :tags], methods: [:overdue?, :days_until_due])
```

#### New Pattern
```ruby
result = TaskQuery.new.call(
  filters: { status: params[:status] },
  sort: { by: 'created_at', order: 'desc' },
  page: 1,
  per_page: 20
)

render json: TaskSerializer.new(result[:data]).as_json(include: [:category, :tags])
```

## Directory Structure

```
app/
├── controllers/
│   └── api/
│       └── v1/
│           └── tasks_controller.rb         # Refactored - Skinny controller
├── models/
│   ├── task.rb                            # Unchanged - minimal validations
│   ├── category.rb
│   └── tag.rb
├── queries/
│   └── task_query.rb                      # NEW - Query object
├── services/
│   ├── task_stats_service.rb              # NEW - Statistics service
│   └── tasks/
│       └── update_service.rb              # NEW - Update service
└── serializers/
    └── task_serializer.rb                 # NEW - Serializer
```

## Maintenance Guidelines

### Adding a New Filter
1. Add scope to Task model (if needed)
2. Update `TaskQuery#apply_filters` method
3. Optionally add validation to `extract_filters` in controller

### Changing JSON Output
1. Modify `TaskSerializer#serialize_task` method
2. No controller changes needed
3. No model changes needed

### Adding Statistics
1. Add private method to `TaskStatsService`
2. Call from `#calculate` method
3. No controller changes needed

## Code Quality

- **Rubocop Compliant:** Follows standard Ruby style guide
- **Well Documented:** Inline documentation for all public methods
- **Testable:** Small, focused objects with clear dependencies
- **Type Safe:** Includes parameter validation
- **DRY:** No duplicated filter/sort logic
- **Security:** Validates sort fields against whitelist

## Future Enhancements

1. **Advanced Caching:** Add Rails caching to stats service
2. **Background Jobs:** Move stats calculation to ActiveJob
3. **Versioning:** Support multiple API versions with different serializers
4. **Authorization:** Add policy objects for permission checks
5. **GraphQL:** Alternative serializers for GraphQL schema
6. **Audit Logging:** Track changes via service decorators

## References

- [Service Object Pattern in Rails](https://guides.rubyonrails.org/)
- [Query Object Pattern](https://martinfowler.com/bliki/QueryObject.html)
- [Serializer Pattern](https://guides.rubyonrails.org/v6.0/active_model_serializers.html)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
