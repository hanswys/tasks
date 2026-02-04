import { useMutation, useQueryClient } from '@tanstack/react-query';
import { tasksApi, type Status, type Priority } from '../api/tasks';
import { useSelectionStore } from '../stores/selectionStore';
import { TASKS_QUERY_KEY, TASK_STATS_QUERY_KEY } from '../hooks/useTasks';
import './BulkActionBar.css';

const STATUS_OPTIONS: { value: Status; label: string }[] = [
  { value: 'pending', label: 'Pending' },
  { value: 'in_progress', label: 'In Progress' },
  { value: 'completed', label: 'Completed' },
  { value: 'archived', label: 'Archived' },
];

const PRIORITY_OPTIONS: { value: Priority; label: string }[] = [
  { value: 'low', label: 'Low' },
  { value: 'medium', label: 'Medium' },
  { value: 'high', label: 'High' },
  { value: 'urgent', label: 'Urgent' },
];

export function BulkActionBar() {
  const { selectedIds, clearSelection, isSelectionMode, setSelectionMode } = useSelectionStore();
  const queryClient = useQueryClient();

  const bulkUpdateMutation = useMutation({
    mutationFn: ({ updates }: { updates: { status?: Status; priority?: Priority } }) =>
      tasksApi.bulkUpdate(Array.from(selectedIds), updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: TASKS_QUERY_KEY });
      queryClient.invalidateQueries({ queryKey: TASK_STATS_QUERY_KEY });
      clearSelection();
    },
  });

  const bulkDeleteMutation = useMutation({
    mutationFn: () => tasksApi.bulkDelete(Array.from(selectedIds)),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: TASKS_QUERY_KEY });
      queryClient.invalidateQueries({ queryKey: TASK_STATS_QUERY_KEY });
      clearSelection();
    },
  });

  const handleStatusChange = (status: Status) => {
    bulkUpdateMutation.mutate({ updates: { status } });
  };

  const handlePriorityChange = (priority: Priority) => {
    bulkUpdateMutation.mutate({ updates: { priority } });
  };

  const handleDelete = () => {
    if (confirm(`Delete ${selectedIds.size} task(s)?`)) {
      bulkDeleteMutation.mutate();
    }
  };

  if (!isSelectionMode) {
    return (
      <button
        type="button"
        className="enable-selection-btn"
        onClick={() => setSelectionMode(true)}
      >
        ☑️ Select Tasks
      </button>
    );
  }

  return (
    <div className="bulk-action-bar">
      <div className="selection-info">
        <span className="selection-count">{selectedIds.size} selected</span>
        <button type="button" className="cancel-btn" onClick={() => setSelectionMode(false)}>
          Cancel
        </button>
      </div>

      {selectedIds.size > 0 && (
        <div className="bulk-actions">
          <div className="action-group">
            <label>Set Status:</label>
            <div className="action-buttons">
              {STATUS_OPTIONS.map((s) => (
                <button
                  key={s.value}
                  type="button"
                  className="action-btn"
                  onClick={() => handleStatusChange(s.value)}
                  disabled={bulkUpdateMutation.isPending}
                >
                  {s.label}
                </button>
              ))}
            </div>
          </div>

          <div className="action-group">
            <label>Set Priority:</label>
            <div className="action-buttons">
              {PRIORITY_OPTIONS.map((p) => (
                <button
                  key={p.value}
                  type="button"
                  className="action-btn"
                  onClick={() => handlePriorityChange(p.value)}
                  disabled={bulkUpdateMutation.isPending}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          <button
            type="button"
            className="delete-btn"
            onClick={handleDelete}
            disabled={bulkDeleteMutation.isPending}
          >
            🗑️ Delete Selected
          </button>
        </div>
      )}
    </div>
  );
}
