import { useState } from 'react';
import { useCategories, useCreateCategory } from '../hooks/useTasks';
import type { Category } from '../api/tasks';
import './CategoryManager.css';

interface CategoryManagerProps {
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

const PRESET_ICONS = ['📁', '💼', '🏠', '💡', '⭐', '🎯', '📚', '🔧', '🎨', '🏃'];

export function CategoryManager({ onClose }: CategoryManagerProps) {
  const { data: categories, isLoading } = useCategories();
  const createCategory = useCreateCategory();

  const [name, setName] = useState('');
  const [color, setColor] = useState(PRESET_COLORS[5]);
  const [icon, setIcon] = useState(PRESET_ICONS[0]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (name.trim()) {
      createCategory.mutate(
        { name: name.trim(), color, icon },
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
          <h2>Manage Categories</h2>
          <button type="button" className="modal-close" onClick={onClose}>
            ×
          </button>
        </div>

        <form className="category-form" onSubmit={handleSubmit}>
          <div className="form-row">
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="New category name..."
              className="category-input"
            />
            <button
              type="submit"
              className="btn btn--primary"
              disabled={!name.trim() || createCategory.isPending}
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

          <div className="form-row">
            <label>Icon:</label>
            <div className="icon-picker">
              {PRESET_ICONS.map((i) => (
                <button
                  key={i}
                  type="button"
                  className={`icon-option ${icon === i ? 'icon-option--selected' : ''}`}
                  onClick={() => setIcon(i)}
                >
                  {i}
                </button>
              ))}
            </div>
          </div>
        </form>

        <div className="category-list">
          <h3>Existing Categories</h3>
          {isLoading ? (
            <p className="loading-text">Loading...</p>
          ) : categories && categories.length > 0 ? (
            <ul>
              {categories.map((cat: Category) => (
                <li key={cat.id} className="category-item">
                  <span className="category-icon">{cat.icon}</span>
                  <span className="category-name">{cat.name}</span>
                  <span
                    className="category-color"
                    style={{ backgroundColor: cat.color }}
                  />
                </li>
              ))}
            </ul>
          ) : (
            <p className="empty-text">No categories yet</p>
          )}
        </div>
      </div>
    </div>
  );
}
