import { useState, useEffect, useRef } from 'react';
import type { TaskFilters as TaskFiltersType, Priority, Status } from '../api/tasks';
import { useCategories } from '../hooks/useTasks';
import './TaskFilters.css';

interface TaskFiltersProps {
  filters: TaskFiltersType;
  onFiltersChange: (filters: TaskFiltersType) => void;
}

export function TaskFilters({ filters, onFiltersChange }: TaskFiltersProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [searchValue, setSearchValue] = useState(filters.search || '');
  const { data: categories } = useCategories();
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Debounce search input
  useEffect(() => {
    if (debounceRef.current) {
      clearTimeout(debounceRef.current);
    }

    debounceRef.current = setTimeout(() => {
      if (searchValue !== (filters.search || '')) {
        onFiltersChange({
          ...filters,
          search: searchValue || undefined,
        });
      }
    }, 300);

    return () => {
      if (debounceRef.current) {
        clearTimeout(debounceRef.current);
      }
    };
  }, [searchValue]);

  // Sync search value when filters are cleared externally
  useEffect(() => {
    if (!filters.search && searchValue) {
      setSearchValue('');
    }
  }, [filters.search]);

  const handleChange = (key: keyof TaskFiltersType, value: string | undefined) => {
    onFiltersChange({
      ...filters,
      [key]: value || undefined,
    });
  };

  const clearFilters = () => {
    setSearchValue('');
    onFiltersChange({});
  };

  const hasActiveFilters = Object.values(filters).some((v) => v !== undefined && v !== '');

  return (
    <div className="task-filters">
      <div className="task-filters-header">
        <button
          type="button"
          className={`filter-toggle ${isExpanded ? 'filter-toggle--active' : ''}`}
          onClick={() => setIsExpanded(!isExpanded)}
        >
          <svg viewBox="0 0 24 24" width="18" height="18">
            <path d="M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z" />
          </svg>
          Filters
          {hasActiveFilters && <span className="filter-badge">Active</span>}
        </button>

        <div className="search-container">
          <svg viewBox="0 0 24 24" width="18" height="18">
            <path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z" />
          </svg>
          <input
            type="text"
            placeholder="Search tasks..."
            value={searchValue}
            onChange={(e) => setSearchValue(e.target.value)}
            className="search-input"
          />
        </div>
      </div>

      {isExpanded && (
        <div className="task-filters-panel">
          <div className="filter-group">
            <label>Status</label>
            <select
              value={filters.status || ''}
              onChange={(e) => handleChange('status', e.target.value as Status)}
            >
              <option value="">All</option>
              <option value="pending">Pending</option>
              <option value="in_progress">In Progress</option>
              <option value="completed">Completed</option>
              <option value="archived">Archived</option>
            </select>
          </div>

          <div className="filter-group">
            <label>Priority</label>
            <select
              value={filters.priority || ''}
              onChange={(e) => handleChange('priority', e.target.value as Priority)}
            >
              <option value="">All</option>
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
              <option value="urgent">Urgent</option>
            </select>
          </div>

          <div className="filter-group">
            <label>Category</label>
            <select
              value={filters.category_id?.toString() || ''}
              onChange={(e) =>
                handleChange('category_id', e.target.value ? e.target.value : undefined)
              }
            >
              <option value="">All Categories</option>
              {categories?.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>
          </div>

          <div className="filter-group">
            <label>Sort By</label>
            <select
              value={filters.sort_by || ''}
              onChange={(e) => handleChange('sort_by', e.target.value)}
            >
              <option value="">Default</option>
              <option value="created_at">Created Date</option>
              <option value="due_date">Due Date</option>
              <option value="priority">Priority</option>
              <option value="title">Title</option>
            </select>
          </div>

          <div className="filter-group">
            <label>Order</label>
            <select
              value={filters.sort_order || 'desc'}
              onChange={(e) => handleChange('sort_order', e.target.value)}
            >
              <option value="desc">Newest First</option>
              <option value="asc">Oldest First</option>
            </select>
          </div>

          {hasActiveFilters && (
            <button type="button" className="clear-filters-btn" onClick={clearFilters}>
              Clear Filters
            </button>
          )}
        </div>
      )}
    </div>
  );
}
