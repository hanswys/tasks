import { useState } from 'react';
import { useCreateTask, useCategories, useTags } from '../hooks/useTasks';
import type { Priority } from '../api/tasks';
import './TaskForm.css';

const PRIORITIES: { value: Priority; label: string; color: string }[] = [
  { value: 'low', label: 'Low', color: '#6B7280' },
  { value: 'medium', label: 'Medium', color: '#3B82F6' },
  { value: 'high', label: 'High', color: '#F97316' },
  { value: 'urgent', label: 'Urgent', color: '#EF4444' },
];

export function TaskForm() {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState<Priority>('low');
  const [categoryId, setCategoryId] = useState<number | undefined>();
  const [dueDate, setDueDate] = useState('');
  const [selectedTagIds, setSelectedTagIds] = useState<number[]>([]);
  const [isExpanded, setIsExpanded] = useState(false);

  const createTask = useCreateTask();
  const { data: categories } = useCategories();
  const { data: tags } = useTags();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (title.trim()) {
      createTask.mutate(
        {
          title: title.trim(),
          description: description.trim(),
          priority,
          category_id: categoryId,
          due_date: dueDate || undefined,
          tag_ids: selectedTagIds.length > 0 ? selectedTagIds : undefined,
        },
        {
          onSuccess: () => {
            setTitle('');
            setDescription('');
            setPriority('low');
            setCategoryId(undefined);
            setDueDate('');
            setSelectedTagIds([]);
            setIsExpanded(false);
          },
        }
      );
    }
  };

  const toggleTag = (tagId: number) => {
    setSelectedTagIds((prev) =>
      prev.includes(tagId) ? prev.filter((id) => id !== tagId) : [...prev, tagId]
    );
  };

  return (
    <form className="task-form" onSubmit={handleSubmit}>
      <div className="task-form-main">
        <input
          type="text"
          className="task-form-input"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onFocus={() => setIsExpanded(true)}
          placeholder="Add a new task..."
        />
        <button
          type="submit"
          className="btn btn--primary"
          disabled={!title.trim() || createTask.isPending}
        >
          {createTask.isPending ? (
            <span className="spinner" />
          ) : (
            <>
              <svg viewBox="0 0 24 24" width="18" height="18">
                <path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z" />
              </svg>
              Add
            </>
          )}
        </button>
      </div>

      <div className={`task-form-extra ${isExpanded ? 'task-form-extra--visible' : ''}`}>
        <textarea
          className="task-form-textarea"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Add a description (optional)"
          rows={2}
        />

        <div className="task-form-options">
          <div className="form-field">
            <label>Priority</label>
            <div className="priority-buttons">
              {PRIORITIES.map((p) => (
                <button
                  key={p.value}
                  type="button"
                  className={`priority-btn ${priority === p.value ? 'priority-btn--selected' : ''}`}
                  style={{
                    '--priority-color': p.color,
                  } as React.CSSProperties}
                  onClick={() => setPriority(p.value)}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          <div className="form-field">
            <label>Category</label>
            <select
              value={categoryId ?? ''}
              onChange={(e) => setCategoryId(e.target.value ? Number(e.target.value) : undefined)}
              className="form-select"
            >
              <option value="">No category</option>
              {categories?.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.icon} {cat.name}
                </option>
              ))}
            </select>
          </div>

          <div className="form-field">
            <label>Due Date</label>
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              className="form-input"
            />
          </div>

          {tags && tags.length > 0 && (
            <div className="form-field form-field--tags">
              <label>Tags</label>
              <div className="tag-selector">
                {tags.map((tag) => (
                  <button
                    key={tag.id}
                    type="button"
                    className={`tag-option ${selectedTagIds.includes(tag.id) ? 'tag-option--selected' : ''}`}
                    style={{
                      '--tag-color': tag.color,
                    } as React.CSSProperties}
                    onClick={() => toggleTag(tag.id)}
                  >
                    {tag.name}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </form>
  );
}
