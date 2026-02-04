import { useTasks, useUpdateTask } from '../hooks/useTasks';
import type { Task, Status } from '../api/tasks';
import './KanbanBoard.css';

const COLUMNS: { status: Status; label: string; color: string }[] = [
  { status: 'pending', label: 'To Do', color: '#6B7280' },
  { status: 'in_progress', label: 'In Progress', color: '#3B82F6' },
  { status: 'completed', label: 'Done', color: '#22C55E' },
  { status: 'archived', label: 'Archived', color: '#9CA3AF' },
];

export function KanbanBoard() {
  const { data: response, isLoading } = useTasks({ per_page: 100 });
  const updateTask = useUpdateTask();

  const tasks: Task[] = response?.data ?? [];

  const handleDragStart = (e: React.DragEvent, taskId: number) => {
    e.dataTransfer.setData('taskId', taskId.toString());
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  const handleDrop = (e: React.DragEvent, newStatus: Status) => {
    e.preventDefault();
    const taskId = parseInt(e.dataTransfer.getData('taskId'));
    const task = tasks.find((t) => t.id === taskId);

    if (task && task.status !== newStatus) {
      updateTask.mutate({
        id: taskId,
        task: { status: newStatus },
      });
    }
  };

  const getTasksByStatus = (status: Status): Task[] => {
    return tasks.filter((task) => task.status === status);
  };

  if (isLoading) {
    return (
      <div className="kanban-board">
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Loading board...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="kanban-board">
      <header className="board-header">
        <h1>Kanban Board</h1>
        <p>Drag and drop tasks to update their status</p>
      </header>

      <div className="board-columns">
        {COLUMNS.map((column) => (
          <div
            key={column.status}
            className="board-column"
            onDragOver={handleDragOver}
            onDrop={(e) => handleDrop(e, column.status)}
          >
            <div className="column-header" style={{ borderColor: column.color }}>
              <span className="column-dot" style={{ backgroundColor: column.color }} />
              <h3>{column.label}</h3>
              <span className="column-count">{getTasksByStatus(column.status).length}</span>
            </div>

            <div className="column-tasks">
              {getTasksByStatus(column.status).map((task) => (
                <div
                  key={task.id}
                  className="kanban-card"
                  draggable
                  onDragStart={(e) => handleDragStart(e, task.id)}
                >
                  <h4 className="card-title">{task.title}</h4>
                  {task.description && (
                    <p className="card-description">{task.description}</p>
                  )}
                  <div className="card-meta">
                    {task.priority && task.priority !== 'low' && (
                      <span className={`priority-badge priority-badge--${task.priority}`}>
                        {task.priority}
                      </span>
                    )}
                    {task.category && (
                      <span className="category-badge">
                        {task.category.icon} {task.category.name}
                      </span>
                    )}
                    {task.due_date && (
                      <span className={`due-badge ${task['overdue?'] ? 'due-badge--overdue' : ''}`}>
                        📅 {new Date(task.due_date).toLocaleDateString()}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
