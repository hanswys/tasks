# Prompt: Expand Tasks Application for Complex Operations

## Current State Summary

### Backend (Ruby on Rails API)
- **Model**: Simple `Task` model with: `id`, `title`, `description`, `completed`, `created_at`, `updated_at`
- **Controller**: Basic CRUD operations in `Api::V1::TasksController`
- **Routes**: RESTful `/api/v1/tasks` endpoints

### Frontend (React + Vite + TanStack Query)
- **API Layer**: `tasksApi.ts` with `getAll`, `create`, `update`, `delete` methods
- **Hooks**: TanStack Query hooks for data fetching and mutations
- **Components**: `TaskList`, `TaskItem`, `TaskForm`

---

## 🚀 Expansion Request: Make This Production-Ready

Transform this simple task manager into a robust, full-featured application by implementing the following enhancements across both Frontend and Backend:

---

## Backend Enhancements (Ruby on Rails)

### 1. Enhanced Data Model

Expand the `Task` model and add supporting models:

```ruby
# New fields for Task:
# - priority: integer (0=low, 1=medium, 2=high, 3=urgent)
# - due_date: datetime
# - category_id: references Category
# - user_id: references User (for future auth)
# - status: enum (pending, in_progress, completed, archived)
# - position: integer (for drag-drop ordering)
# - estimated_minutes: integer
# - tags: has_many through TaskTags

# New Models:
# - Category (name, color, icon)
# - Tag (name, color)
# - TaskTag (join table)
# - User (email, name, password_digest - for authentication)
```

### 2. Advanced Querying & Filtering

Add controller actions and scopes for:

```ruby
# Query Parameters:
# - status: filter by status
# - priority: filter by priority  
# - category_id: filter by category
# - due_before: tasks due before date
# - due_after: tasks due after date
# - search: full-text search on title/description
# - tags[]: filter by tag IDs
# - sort_by: field to sort by (due_date, priority, created_at, position)
# - sort_order: asc/desc
# - page, per_page: pagination

# Example: GET /api/v1/tasks?status=pending&priority=high&sort_by=due_date&page=1&per_page=20
```

### 3. Batch Operations

Add bulk action endpoints:

```ruby
# POST /api/v1/tasks/bulk_update
# Body: { task_ids: [1,2,3], updates: { status: "completed" } }

# POST /api/v1/tasks/bulk_delete
# Body: { task_ids: [1,2,3] }

# PATCH /api/v1/tasks/reorder
# Body: { task_ids: [3,1,2] } # new order
```

### 4. Statistics & Analytics

Add analytics endpoints:

```ruby
# GET /api/v1/tasks/stats
# Returns: { total, completed, pending, by_priority, by_category, completion_rate, avg_completion_time }

# GET /api/v1/tasks/timeline
# Returns grouped by week/month with completion trends
```

### 5. Subtasks & Dependencies

```ruby
# Task has_many :subtasks, class_name: "Task", foreign_key: "parent_id"
# Task belongs_to :parent, class_name: "Task", optional: true
# Task has_many :dependencies, through: :task_dependencies
```

### 6. Background Jobs

Implement Sidekiq jobs for:
- Sending due date reminders (email notifications)
- Archiving old completed tasks
- Generating weekly summary reports

### 7. Authentication & Authorization

```ruby
# Use Devise + JWT for API authentication
# Implement:
# - User registration, login, logout
# - Password reset flow
# - Token refresh mechanism
# - User-scoped tasks (users only see their own tasks)
```

### 8. Serializers

Use Active Model Serializers or Blueprinter for consistent JSON responses:

```ruby
# TaskSerializer with:
# - nested category, tags
# - computed fields (is_overdue, days_until_due)
# - conditional includes (?include=category,tags,subtasks)
```

### 9. Error Handling

Implement consistent error responses:

```ruby
# { error: { code: "VALIDATION_ERROR", message: "...", details: {...} } }
# { error: { code: "NOT_FOUND", message: "Task not found" } }
# { error: { code: "UNAUTHORIZED", message: "..." } }
```

### 10. API Versioning & Rate Limiting

- Proper v1/v2 versioning structure
- Rate limiting with Rack::Attack

---

## Frontend Enhancements (React + TypeScript)

### 1. Enhanced Type System

```typescript
// Expanded interfaces
interface Task {
  id: number;
  title: string;
  description: string;
  completed: boolean;
  priority: 'low' | 'medium' | 'high' | 'urgent';
  status: 'pending' | 'in_progress' | 'completed' | 'archived';
  due_date: string | null;
  estimated_minutes: number | null;
  position: number;
  category: Category | null;
  tags: Tag[];
  subtasks: Task[];
  parent_id: number | null;
  created_at: string;
  updated_at: string;
}

interface TaskFilters {
  status?: string;
  priority?: string;
  category_id?: number;
  tags?: number[];
  search?: string;
  due_before?: string;
  due_after?: string;
}

interface PaginatedResponse<T> {
  data: T[];
  meta: {
    current_page: number;
    total_pages: number;
    total_count: number;
    per_page: number;
  };
}
```

### 2. Advanced API Layer

```typescript
// Enhanced tasksApi with:
// - getAll(filters: TaskFilters, pagination: PaginationParams)
// - bulkUpdate(ids: number[], updates: Partial<Task>)
// - bulkDelete(ids: number[])
// - reorder(orderedIds: number[])
// - getStats()
// - getTimeline(range: 'week' | 'month' | 'year')
```

### 3. State Management

```typescript
// Add Zustand or Context for:
// - Filter state
// - Selected tasks (for bulk operations)
// - View preferences (list/grid/kanban)
// - Sidebar collapse state
```

### 4. New Components

```text
Components to build:
├── TaskBoard/           # Kanban-style board by status
├── TaskCalendar/        # Calendar view with due dates
├── TaskFilters/         # Advanced filter panel
├── TaskStats/           # Dashboard with charts
├── CategoryManager/     # CRUD for categories
├── TagManager/          # CRUD for tags
├── BulkActionBar/       # Floating bar when tasks selected
├── TaskDetail/          # Full task detail modal/drawer
├── SubtaskList/         # Nested subtask management
├── DragDropList/        # Reorderable task list
├── SearchBar/           # Global search with autocomplete
├── DatePicker/          # Custom date picker with presets
├── PrioritySelector/    # Visual priority selection
└── TimerWidget/         # Pomodoro timer for tasks
```

### 5. Views & Routing

```typescript
// React Router routes:
// / - Dashboard with stats overview
// /tasks - Task list with filters
// /tasks/:id - Task detail view
// /board - Kanban board
// /calendar - Calendar view
// /categories - Category management
// /settings - User preferences
// /auth/login - Login page
// /auth/register - Registration page
```

### 6. Advanced Hooks

```typescript
// New hooks:
// - useTaskFilters() - filter state management
// - useTaskSelection() - multi-select for bulk ops
// - useBulkActions() - bulk update/delete mutations
// - useTaskStats() - fetch and cache stats
// - useTaskSearch(query) - debounced search
// - useInfiniteTaskList() - infinite scroll pagination
// - useTaskDragDrop() - drag-drop ordering
// - useOptimisticUpdate() - optimistic UI updates
```

### 7. Real-time Updates

```typescript
// Implement WebSocket or SSE for:
// - Real-time task updates across tabs/devices
// - Notification toasts for reminders
// - Collaborative features (show who's viewing)
```

### 8. Offline Support

```typescript
// Service Worker + IndexedDB for:
// - Offline task viewing
// - Queue mutations when offline
// - Sync when back online
// - Background sync
```

### 9. Accessibility & UX

```text
Implement:
- Full keyboard navigation
- ARIA labels and roles
- Focus management
- Screen reader announcements
- Reduced motion support
- Dark/light mode toggle
- Toast notifications (react-hot-toast)
- Skeleton loaders
- Error boundaries
```

### 10. Performance Optimizations

```text
Implement:
- React.memo for list items
- Virtual scrolling for large lists (react-window)
- Image lazy loading
- Route-based code splitting
- Prefetching on hover
- Service worker caching
```

---

## Implementation Priority

### Phase 1: Core Data Enhancements
1. Backend: Expand Task model, add migrations
2. Backend: Add filtering & sorting to index action
3. Frontend: Update types and API layer
4. Frontend: Build filter components

### Phase 2: Organization Features
1. Backend: Add Category and Tag models
2. Backend: Implement associations
3. Frontend: Category/Tag management UI
4. Frontend: Task assignment UI

### Phase 3: Views & UX
1. Frontend: Kanban board view
2. Frontend: Calendar view
3. Frontend: Dashboard with stats
4. Backend: Stats endpoint

### Phase 4: Collaboration & Auth
1. Backend: User model and authentication
2. Backend: Scope tasks to users
3. Frontend: Auth flows
4. Frontend: Real-time updates

### Phase 5: Advanced Features
1. Backend: Subtasks and dependencies
2. Backend: Background jobs
3. Frontend: Offline support
4. Frontend: Performance optimizations

---

## Quick Start Commands

### Backend
```bash
cd backend

# Generate models
rails g model Category name:string color:string icon:string
rails g model Tag name:string color:string
rails g model TaskTag task:references tag:references

# Add columns to Task
rails g migration AddFieldsToTasks priority:integer status:integer due_date:datetime category:references position:integer estimated_minutes:integer parent:references

# Install gems
bundle add devise-jwt rack-attack sidekiq blueprinter

# Run migrations
rails db:migrate
```

### Frontend
```bash
cd frontend

# Install dependencies
npm install zustand react-router-dom @dnd-kit/core @dnd-kit/sortable react-hot-toast date-fns recharts
npm install -D @types/react-router-dom
```

---

## Example Expanded Task Response

```json
{
  "id": 1,
  "title": "Complete project proposal",
  "description": "Write the Q1 project proposal document",
  "status": "in_progress",
  "priority": "high",
  "completed": false,
  "due_date": "2026-01-25T17:00:00Z",
  "estimated_minutes": 120,
  "position": 0,
  "is_overdue": false,
  "days_until_due": 3,
  "category": {
    "id": 1,
    "name": "Work",
    "color": "#3B82F6",
    "icon": "briefcase"
  },
  "tags": [
    { "id": 1, "name": "Q1", "color": "#10B981" },
    { "id": 2, "name": "Important", "color": "#EF4444" }
  ],
  "subtasks": [
    { "id": 2, "title": "Research competitors", "completed": true },
    { "id": 3, "title": "Draft outline", "completed": false }
  ],
  "created_at": "2026-01-20T10:00:00Z",
  "updated_at": "2026-01-22T14:30:00Z"
}
```

---

## Notes for Implementation

1. **Keep API backward compatible** - existing endpoints should still work
2. **Use feature flags** for gradual rollout
3. **Write tests** - RSpec for backend, Vitest for frontend
4. **Document API** - Consider adding Swagger/OpenAPI
5. **Monitor performance** - Add logging and metrics
6. **Security** - CORS, CSRF, SQL injection prevention, rate limiting

---

Use this prompt to guide the transformation of the simple task manager into a production-ready application with complex operations handling!
