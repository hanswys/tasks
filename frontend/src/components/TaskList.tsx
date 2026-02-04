import { useState } from 'react';
import { useTasks } from '../hooks/useTasks';
import { TaskItem } from './TaskItem';
import { TaskForm } from './TaskForm';
import { TaskFilters } from './TaskFilters';
import { CategoryManager } from './CategoryManager';
import { TagManager } from './TagManager';
import { BulkActionBar } from './BulkActionBar';
import { useSelectionStore } from '../stores/selectionStore';
import type { Task, TaskFilters as TaskFiltersType } from '../api/tasks';
import './TaskList.css';

export function TaskList() {
  const [filters, setFilters] = useState<TaskFiltersType>({});
  const [showCategoryManager, setShowCategoryManager] = useState(false);
  const [showTagManager, setShowTagManager] = useState(false);
  const { data: response, isLoading, error } = useTasks(filters);
  const { isSelectionMode, selectedIds, selectAll, clearSelection } = useSelectionStore();

  // Extract tasks array from paginated response
  const tasks: Task[] = response?.data ?? [];
  const meta = response?.meta;

  if (isLoading) {
    return (
      <div className="task-list-container">
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Loading tasks...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="task-list-container">
        <div className="error-state">
          <svg viewBox="0 0 24 24" width="48" height="48">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-2h2v2zm0-4h-2V7h2v6z" />
          </svg>
          <p>Failed to load tasks</p>
          <p className="error-detail">Make sure the Rails API is running on port 3000</p>
        </div>
      </div>
    );
  }

  const completedCount = tasks.filter((t) => t.status === 'completed').length;
  const totalCount = meta?.total_count ?? tasks.length;
  const taskIds = tasks.map((t) => t.id);
  const allSelected = taskIds.length > 0 && taskIds.every((id) => selectedIds.has(id));

  const handleSelectAll = () => {
    if (allSelected) {
      clearSelection();
    } else {
      selectAll(taskIds);
    }
  };

  return (
    <div className="task-list-container">
      <header className="task-list-header">
        <div className="header-content">
          <h1 className="header-title">
            <span className="header-icon">✨</span>
            My Tasks
          </h1>
          <p className="header-subtitle">Stay organized, get things done</p>
        </div>
        <div className="header-actions">
          <BulkActionBar />
          <button
            type="button"
            className="btn btn--secondary"
            onClick={() => setShowCategoryManager(true)}
          >
            📁 Categories
          </button>
          <button
            type="button"
            className="btn btn--secondary"
            onClick={() => setShowTagManager(true)}
          >
            🏷️ Tags
          </button>
          {totalCount > 0 && (
            <span className="stat-badge">
              {completedCount}/{totalCount} completed
            </span>
          )}
        </div>
      </header>

      <TaskForm />

      <TaskFilters filters={filters} onFiltersChange={setFilters} />

      {isSelectionMode && tasks.length > 0 && (
        <div className="select-all-row">
          <label className="select-all-label">
            <input
              type="checkbox"
              checked={allSelected}
              onChange={handleSelectAll}
            />
            Select All ({taskIds.length})
          </label>
        </div>
      )}

      <div className="task-list">
        {tasks.length > 0 ? (
          tasks.map((task) => <TaskItem key={task.id} task={task} />)
        ) : (
          <div className="empty-state">
            <div className="empty-icon">📝</div>
            <p>No tasks yet</p>
            <p className="empty-hint">Add your first task above!</p>
          </div>
        )}
      </div>

      {meta && meta.total_pages > 1 && (
        <div className="pagination-info">
          Page {meta.current_page} of {meta.total_pages} ({meta.total_count} total tasks)
        </div>
      )}

      {showCategoryManager && (
        <CategoryManager onClose={() => setShowCategoryManager(false)} />
      )}

      {showTagManager && (
        <TagManager onClose={() => setShowTagManager(false)} />
      )}
    </div>
  );
}

