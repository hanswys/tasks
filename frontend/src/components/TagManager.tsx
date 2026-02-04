import { useState } from 'react';
import { useTags, useCreateTag } from '../hooks/useTasks';
import type { Tag } from '../api/tasks';
import './TagManager.css';

interface TagManagerProps {
  onClose: () => void;
}

const PRESET_COLORS = [
  '#EF4444', // Red
  '#F97316', // Orange
  '#EAB308', // Yellow
  '#22C55E', // Green
  '#14B8A6', // Teal
  '#3B82F6', // Blue
  '#8B5CF6', // Purple
  '#EC4899', // Pink
  '#6B7280', // Gray
];

export function TagManager({ onClose }: TagManagerProps) {
  const { data: tags, isLoading } = useTags();
  const createTag = useCreateTag();

  const [name, setName] = useState('');
  const [color, setColor] = useState(PRESET_COLORS[5]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (name.trim()) {
      createTag.mutate(
        { name: name.trim(), color },
        {
          onSuccess: () => {
            setName('');
          },
        }
      );
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Manage Tags</h2>
          <button type="button" className="modal-close" onClick={onClose}>
            ×
          </button>
        </div>

        <form className="tag-form" onSubmit={handleSubmit}>
          <div className="form-row">
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="New tag name..."
              className="tag-input"
            />
            <button
              type="submit"
              className="btn btn--primary"
              disabled={!name.trim() || createTag.isPending}
            >
              Add
            </button>
          </div>

          <div className="form-row">
            <label>Color:</label>
            <div className="color-picker">
              {PRESET_COLORS.map((c) => (
                <button
                  key={c}
                  type="button"
                  className={`color-swatch ${color === c ? 'color-swatch--selected' : ''}`}
                  style={{ backgroundColor: c }}
                  onClick={() => setColor(c)}
                />
              ))}
            </div>
          </div>
        </form>

        <div className="tag-list">
          <h3>Existing Tags</h3>
          {isLoading ? (
            <p className="loading-text">Loading...</p>
          ) : tags && tags.length > 0 ? (
            <div className="tag-chips">
              {tags.map((tag: Tag) => (
                <span
                  key={tag.id}
                  className="tag-chip"
                  style={{ backgroundColor: tag.color + '20', borderColor: tag.color, color: tag.color }}
                >
                  {tag.name}
                </span>
              ))}
            </div>
          ) : (
            <p className="empty-text">No tags yet</p>
          )}
        </div>
      </div>
    </div>
  );
}
