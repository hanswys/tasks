import { useTaskStats, useCategories } from '../hooks/useTasks';
import './Dashboard.css';

export function Dashboard() {
  const { data: stats, isLoading: statsLoading } = useTaskStats();
  const { data: categories } = useCategories();

  if (statsLoading) {
    return (
      <div className="dashboard">
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Loading dashboard...</p>
        </div>
      </div>
    );
  }

  const priorityData = [
    { label: 'Low', value: stats?.by_priority?.low ?? 0, color: '#6B7280' },
    { label: 'Medium', value: stats?.by_priority?.medium ?? 0, color: '#3B82F6' },
    { label: 'High', value: stats?.by_priority?.high ?? 0, color: '#F97316' },
    { label: 'Urgent', value: stats?.by_priority?.urgent ?? 0, color: '#EF4444' },
  ];

  const statusData = [
    { label: 'Pending', value: stats?.by_status?.pending ?? 0, color: '#6B7280' },
    { label: 'In Progress', value: stats?.by_status?.in_progress ?? 0, color: '#3B82F6' },
    { label: 'Completed', value: stats?.by_status?.completed ?? 0, color: '#22C55E' },
    { label: 'Archived', value: stats?.by_status?.archived ?? 0, color: '#9CA3AF' },
  ];

  const completionRate = stats?.total && stats.total > 0
    ? Math.round(((stats.completed ?? 0) / stats.total) * 100)
    : 0;

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>Dashboard</h1>
        <p>Overview of your tasks and productivity</p>
      </header>

      <div className="stats-grid">
        <div className="stat-card stat-card--total">
          <div className="stat-icon">📊</div>
          <div className="stat-content">
            <span className="stat-value">{stats?.total ?? 0}</span>
            <span className="stat-label">Total Tasks</span>
          </div>
        </div>

        <div className="stat-card stat-card--completed">
          <div className="stat-icon">✅</div>
          <div className="stat-content">
            <span className="stat-value">{stats?.completed ?? 0}</span>
            <span className="stat-label">Completed</span>
          </div>
        </div>

        <div className="stat-card stat-card--overdue">
          <div className="stat-icon">⚠️</div>
          <div className="stat-content">
            <span className="stat-value">{stats?.overdue ?? 0}</span>
            <span className="stat-label">Overdue</span>
          </div>
        </div>

        <div className="stat-card stat-card--rate">
          <div className="stat-icon">🎯</div>
          <div className="stat-content">
            <span className="stat-value">{completionRate}%</span>
            <span className="stat-label">Completion Rate</span>
          </div>
        </div>
      </div>

      <div className="charts-row">
        <div className="chart-card">
          <h3>By Priority</h3>
          <div className="bar-chart">
            {priorityData.map((item) => (
              <div key={item.label} className="bar-item">
                <span className="bar-label">{item.label}</span>
                <div className="bar-track">
                  <div
                    className="bar-fill"
                    style={{
                      width: `${Math.min((item.value / (stats?.total || 1)) * 100, 100)}%`,
                      backgroundColor: item.color,
                    }}
                  />
                </div>
                <span className="bar-value">{item.value}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="chart-card">
          <h3>By Status</h3>
          <div className="bar-chart">
            {statusData.map((item) => (
              <div key={item.label} className="bar-item">
                <span className="bar-label">{item.label}</span>
                <div className="bar-track">
                  <div
                    className="bar-fill"
                    style={{
                      width: `${Math.min((item.value / (stats?.total || 1)) * 100, 100)}%`,
                      backgroundColor: item.color,
                    }}
                  />
                </div>
                <span className="bar-value">{item.value}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {categories && categories.length > 0 && (
        <div className="chart-card">
          <h3>Categories</h3>
          <div className="category-grid">
            {categories.map((cat) => (
              <div key={cat.id} className="category-stat" style={{ borderColor: cat.color }}>
                <span className="category-icon">{cat.icon}</span>
                <span className="category-name">{cat.name}</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
