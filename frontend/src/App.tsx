import { Routes, Route } from 'react-router-dom';
import { Layout } from './components/Layout';
import { Dashboard } from './components/Dashboard';
import { TaskList } from './components/TaskList';
import { KanbanBoard } from './components/KanbanBoard';
import { CalendarView } from './components/CalendarView';

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/tasks" element={<TaskList />} />
        <Route path="/board" element={<KanbanBoard />} />
        <Route path="/calendar" element={<CalendarView />} />
      </Routes>
    </Layout>
  );
}

export default App;
