import { useState } from 'react';
import { useTasks } from '../hooks/useTasks';
import type { Task } from '../api/tasks';
import './CalendarView.css';

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export function CalendarView() {
  const [currentDate, setCurrentDate] = useState(new Date());
  const { data: response, isLoading } = useTasks({ per_page: 100 });

  const tasks: Task[] = response?.data ?? [];

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const firstDayOfMonth = new Date(year, month, 1);
  const lastDayOfMonth = new Date(year, month + 1, 0);
  const startingDayOfWeek = firstDayOfMonth.getDay();
  const daysInMonth = lastDayOfMonth.getDate();

  const prevMonth = () => {
    setCurrentDate(new Date(year, month - 1, 1));
  };

  const nextMonth = () => {
    setCurrentDate(new Date(year, month + 1, 1));
  };

  const goToToday = () => {
    setCurrentDate(new Date());
  };

  const getTasksForDay = (day: number): Task[] => {
    const dateStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    return tasks.filter((task) => {
      if (!task.due_date) return false;
      return task.due_date.startsWith(dateStr);
    });
  };

  const isToday = (day: number): boolean => {
    const today = new Date();
    return (
      today.getFullYear() === year &&
      today.getMonth() === month &&
      today.getDate() === day
    );
  };

  const renderCalendarDays = () => {
    const days = [];

    // Empty cells for days before the first day of month
    for (let i = 0; i < startingDayOfWeek; i++) {
      days.push(<div key={`empty-${i}`} className="calendar-day calendar-day--empty" />);
    }

    // Days of the month
    for (let day = 1; day <= daysInMonth; day++) {
      const dayTasks = getTasksForDay(day);
      days.push(
        <div
          key={day}
          className={`calendar-day ${isToday(day) ? 'calendar-day--today' : ''} ${dayTasks.length > 0 ? 'calendar-day--has-tasks' : ''}`}
        >
          <span className="day-number">{day}</span>
          {dayTasks.length > 0 && (
            <div className="day-tasks">
              {dayTasks.slice(0, 3).map((task) => (
                <div
                  key={task.id}
                  className={`day-task ${task.status === 'completed' ? 'day-task--completed' : ''} ${task['overdue?'] ? 'day-task--overdue' : ''}`}
                  title={task.title}
                >
                  {task.title}
                </div>
              ))}
              {dayTasks.length > 3 && (
                <div className="day-task day-task--more">
                  +{dayTasks.length - 3} more
                </div>
              )}
            </div>
          )}
        </div>
      );
    }

    return days;
  };

  if (isLoading) {
    return (
      <div className="calendar-view">
        <div className="loading-state">
          <div className="loading-spinner" />
          <p>Loading calendar...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="calendar-view">
      <header className="calendar-header">
        <div className="header-title">
          <h1>Calendar</h1>
          <p>View tasks by due date</p>
        </div>
        <div className="calendar-nav">
          <button type="button" className="nav-btn" onClick={prevMonth}>
            ←
          </button>
          <span className="current-month">
            {MONTHS[month]} {year}
          </span>
          <button type="button" className="nav-btn" onClick={nextMonth}>
            →
          </button>
          <button type="button" className="btn btn--secondary" onClick={goToToday}>
            Today
          </button>
        </div>
      </header>

      <div className="calendar-grid">
        <div className="calendar-weekdays">
          {WEEKDAYS.map((day) => (
            <div key={day} className="weekday">{day}</div>
          ))}
        </div>
        <div className="calendar-days">
          {renderCalendarDays()}
        </div>
      </div>
    </div>
  );
}
