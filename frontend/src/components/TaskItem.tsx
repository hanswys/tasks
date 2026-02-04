import { useState } from 'react';
import type { Task } from '../api/tasks';
import { useUpdateTask, useDeleteTask } from '../hooks/useTasks';
import { useSelectionStore } from '../stores/selectionStore';
import './TaskItem.css';

interface TaskItemProps {
  task: Task;
}

export function TaskItem({ task }: TaskItemProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState(task.title);
  const [editDescription, setEditDescription] = useState(task.description || '');

  const updateTask = useUpdateTask();
  const deleteTask = useDeleteTask();
  const { isSelectionMode, selectedIds, toggleSelection } = useSelectionStore();
  const isSelected = selectedIds.has(task.id);

  const handleToggleComplete = () => {
    const newStatus = task.status === 'completed' ? 'pending' : 'completed';
    updateTask.mutate({
      id: task.id,
      task: { status: newStatus, completed: newStatus === 'completed' },
    });
  };

  const handleSaveEdit = () => {
    if (editTitle.trim()) {
      updateTask.mutate({
        id: task.id,
        task: { title: editTitle.trim(), description: editDescription.trim() },
      });
      setIsEditing(false);
    }
  };

  const handleCancelEdit = () => {
    setEditTitle(task.title);
    setEditDescription(task.description || '');
    setIsEditing(false);
  };

  const handleDelete = () => {
    deleteTask.mutate(task.id);
  };

  if (isEditing) {
    return (
      <div className="task-item task-item--editing">
        <input
          type="text"
          className="task-edit-input"
          value={editTitle}
          onChange={(e) => setEditTitle(e.target.value)}
          placeholder="Task title"
          autoFocus
        />
        <textarea
          className="task-edit-textarea"
          value={editDescription}
          onChange={(e) => setEditDescription(e.target.value)}
          placeholder="Description (optional)"
          rows={2}
        />
        <div className="task-edit-actions">
          <button className="btn btn--save" onClick={handleSaveEdit} disabled={updateTask.isPending}>
            Save
          </button>
          <button className="btn btn--cancel" onClick={handleCancelEdit}>
            Cancel
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className={`task-item ${task.status === 'completed' ? 'task-item--completed' : ''} ${isSelected ? 'task-item--selected' : ''}`}>
      {isSelectionMode && (
        <div className="selection-checkbox-wrapper">
          <input
            type="checkbox"
            className="selection-checkbox"
            checked={isSelected}
            onChange={() => toggleSelection(task.id)}
            id={`select-${task.id}`}
          />
        </div>
      )}
      <div className="task-checkbox-wrapper">
        <input
          type="checkbox"
          className="task-checkbox"
          checked={task.status === 'completed'}
          onChange={handleToggleComplete}
          id={`task-${task.id}`}
        />
        <label htmlFor={`task-${task.id}`} className="task-checkbox-label">
          <svg className="checkmark" viewBox="0 0 24 24">
            <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" />
          </svg>
        </label>
      </div>
      <div className="task-content">
        <h3 className="task-title">{task.title}</h3>
        {task.description && <p className="task-description">{task.description}</p>}
      </div>
      <div className="task-actions">
        <button className="btn btn--icon" onClick={() => setIsEditing(true)} title="Edit">
          <svg viewBox="0 0 24 24" width="18" height="18">
            <path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z" />
          </svg>
        </button>
        <button
          className="btn btn--icon btn--danger"
          onClick={handleDelete}
          disabled={deleteTask.isPending}
          title="Delete"
        >
          <svg viewBox="0 0 24 24" width="18" height="18">
            <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" />
          </svg>
        </button>
      </div>
    </div>
  );
}

