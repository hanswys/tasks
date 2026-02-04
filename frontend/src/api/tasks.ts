// ==================
// Types
// ==================

export type Priority = 'low' | 'medium' | 'high' | 'urgent';
export type Status = 'pending' | 'in_progress' | 'completed' | 'archived';

export interface Category {
  id: number;
  name: string;
  color: string;
  icon: string;
  created_at: string;
  updated_at: string;
}

export interface Tag {
  id: number;
  name: string;
  color: string;
  created_at: string;
  updated_at: string;
}

export interface Task {
  id: number;
  title: string;
  description: string;
  completed: boolean;
  priority: Priority;
  status: Status;
  due_date: string | null;
  estimated_minutes: number | null;
  position: number;
  category_id: number | null;
  category: Category | null;
  tags: Tag[];
  subtasks?: Task[];
  parent_id: number | null;
  'overdue?': boolean;
  days_until_due: number | null;
  created_at: string;
  updated_at: string;
}

export interface CreateTaskInput {
  title: string;
  description?: string;
  priority?: Priority;
  status?: Status;
  due_date?: string;
  category_id?: number;
  estimated_minutes?: number;
  parent_id?: number;
  tag_ids?: number[];
}

export interface UpdateTaskInput {
  title?: string;
  description?: string;
  completed?: boolean;
  priority?: Priority;
  status?: Status;
  due_date?: string | null;
  category_id?: number | null;
  position?: number;
  estimated_minutes?: number | null;
  parent_id?: number | null;
  tag_ids?: number[];
}

export interface TaskFilters {
  status?: Status;
  priority?: Priority;
  category_id?: number;
  tag_ids?: number[];
  search?: string;
  due_before?: string;
  due_after?: string;
  sort_by?: 'created_at' | 'due_date' | 'priority' | 'position' | 'title';
  sort_order?: 'asc' | 'desc';
  page?: number;
  per_page?: number;
}

export interface PaginationMeta {
  current_page: number;
  per_page: number;
  total_count: number;
  total_pages: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  meta: PaginationMeta;
}

export interface TaskStats {
  total: number;
  pending: number;
  in_progress: number;
  completed: number;
  archived: number;
  by_priority: {
    low: number;
    medium: number;
    high: number;
    urgent: number;
  };
  by_status: {
    pending: number;
    in_progress: number;
    completed: number;
    archived: number;
  };
  by_category: Record<string, number>;
  completion_rate: number;
  overdue: number;
}

// ==================
// API
// ==================

const API_BASE_URL = 'http://localhost:3000/api/v1';

function buildQueryString(filters: TaskFilters): string {
  const params = new URLSearchParams();

  if (filters.status) params.append('status', filters.status);
  if (filters.priority) params.append('priority', filters.priority);
  if (filters.category_id) params.append('category_id', filters.category_id.toString());
  if (filters.search) params.append('search', filters.search);
  if (filters.due_before) params.append('due_before', filters.due_before);
  if (filters.due_after) params.append('due_after', filters.due_after);
  if (filters.sort_by) params.append('sort_by', filters.sort_by);
  if (filters.sort_order) params.append('sort_order', filters.sort_order);
  if (filters.page) params.append('page', filters.page.toString());
  if (filters.per_page) params.append('per_page', filters.per_page.toString());
  if (filters.tag_ids?.length) {
    filters.tag_ids.forEach((id) => params.append('tag_ids[]', id.toString()));
  }

  const queryString = params.toString();
  return queryString ? `?${queryString}` : '';
}

export const tasksApi = {
  async getAll(filters: TaskFilters = {}): Promise<PaginatedResponse<Task>> {
    const response = await fetch(`${API_BASE_URL}/tasks${buildQueryString(filters)}`);
    if (!response.ok) throw new Error('Failed to fetch tasks');
    return response.json();
  },

  async getById(id: number): Promise<Task> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`);
    if (!response.ok) throw new Error('Failed to fetch task');
    return response.json();
  },

  async getStats(): Promise<TaskStats> {
    const response = await fetch(`${API_BASE_URL}/tasks/stats`);
    if (!response.ok) throw new Error('Failed to fetch stats');
    return response.json();
  },

  async create(task: CreateTaskInput): Promise<Task> {
    const response = await fetch(`${API_BASE_URL}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task }),
    });
    if (!response.ok) throw new Error('Failed to create task');
    return response.json();
  },

  async update(id: number, task: UpdateTaskInput): Promise<Task> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task }),
    });
    if (!response.ok) throw new Error('Failed to update task');
    return response.json();
  },

  async delete(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/tasks/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) throw new Error('Failed to delete task');
  },

  async bulkUpdate(taskIds: number[], updates: UpdateTaskInput): Promise<{ updated_count: number }> {
    const response = await fetch(`${API_BASE_URL}/tasks/bulk_update`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task_ids: taskIds, updates }),
    });
    if (!response.ok) throw new Error('Failed to bulk update tasks');
    return response.json();
  },

  async bulkDelete(taskIds: number[]): Promise<{ deleted_count: number }> {
    const response = await fetch(`${API_BASE_URL}/tasks/bulk_delete`, {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ task_ids: taskIds }),
    });
    if (!response.ok) throw new Error('Failed to bulk delete tasks');
    return response.json();
  },

  async reorder(positions: { id: number; position: number }[]): Promise<{ success: boolean }> {
    const response = await fetch(`${API_BASE_URL}/tasks/reorder`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ positions }),
    });
    if (!response.ok) throw new Error('Failed to reorder tasks');
    return response.json();
  },
};

export const categoriesApi = {
  async getAll(): Promise<Category[]> {
    const response = await fetch(`${API_BASE_URL}/categories`);
    if (!response.ok) throw new Error('Failed to fetch categories');
    return response.json();
  },

  async create(category: { name: string; color?: string; icon?: string }): Promise<Category> {
    const response = await fetch(`${API_BASE_URL}/categories`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ category }),
    });
    if (!response.ok) throw new Error('Failed to create category');
    return response.json();
  },

  async update(id: number, category: Partial<Category>): Promise<Category> {
    const response = await fetch(`${API_BASE_URL}/categories/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ category }),
    });
    if (!response.ok) throw new Error('Failed to update category');
    return response.json();
  },

  async delete(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/categories/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) throw new Error('Failed to delete category');
  },
};

export const tagsApi = {
  async getAll(): Promise<Tag[]> {
    const response = await fetch(`${API_BASE_URL}/tags`);
    if (!response.ok) throw new Error('Failed to fetch tags');
    return response.json();
  },

  async create(tag: { name: string; color?: string }): Promise<Tag> {
    const response = await fetch(`${API_BASE_URL}/tags`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tag }),
    });
    if (!response.ok) throw new Error('Failed to create tag');
    return response.json();
  },

  async update(id: number, tag: Partial<Tag>): Promise<Tag> {
    const response = await fetch(`${API_BASE_URL}/tags/${id}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ tag }),
    });
    if (!response.ok) throw new Error('Failed to update tag');
    return response.json();
  },

  async delete(id: number): Promise<void> {
    const response = await fetch(`${API_BASE_URL}/tags/${id}`, {
      method: 'DELETE',
    });
    if (!response.ok) throw new Error('Failed to delete tag');
  },
};
