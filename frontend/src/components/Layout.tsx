import { NavLink } from 'react-router-dom';
import './Layout.css';

interface LayoutProps {
  children: React.ReactNode;
}

export function Layout({ children }: LayoutProps) {
  return (
    <div className="app-layout">
      <nav className="sidebar">
        <div className="sidebar-brand">
          <span className="brand-icon">✨</span>
          <span className="brand-text">Tasks</span>
        </div>

        <ul className="nav-links">
          <li>
            <NavLink to="/" end className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}>
              <svg viewBox="0 0 24 24" width="20" height="20">
                <path d="M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z" />
              </svg>
              Dashboard
            </NavLink>
          </li>
          <li>
            <NavLink to="/tasks" className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}>
              <svg viewBox="0 0 24 24" width="20" height="20">
                <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-9 14l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
              </svg>
              Tasks
            </NavLink>
          </li>
          <li>
            <NavLink to="/board" className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}>
              <svg viewBox="0 0 24 24" width="20" height="20">
                <path d="M20 2H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM8 20H4V4h4v16zm6 0h-4V4h4v16zm6 0h-4V4h4v16z" />
              </svg>
              Board
            </NavLink>
          </li>
          <li>
            <NavLink to="/calendar" className={({ isActive }) => (isActive ? 'nav-link active' : 'nav-link')}>
              <svg viewBox="0 0 24 24" width="20" height="20">
                <path d="M19 3h-1V1h-2v2H8V1H6v2H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H5V8h14v11zM9 10H7v2h2v-2zm4 0h-2v2h2v-2zm4 0h-2v2h2v-2z" />
              </svg>
              Calendar
            </NavLink>
          </li>
        </ul>
      </nav>

      <main className="main-content">
        {children}
      </main>
    </div>
  );
}
