import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { tasksApi, categoriesApi, tagsApi } from '../api/tasks';
import type { CreateTaskInput, UpdateTaskInput, TaskFilters } from '../api/tasks';

export const TASKS_QUERY_KEY = ['tasks'];
export const CATEGORIES_QUERY_KEY = ['categories'];
export const TAGS_QUERY_KEY = ['tags'];
export const TASK_STATS_QUERY_KEY = ['task-stats'];

// ==================
// Tasks Hooks
// ==================

export function useTasks(filters: TaskFilters = {}) {
    return useQuery({
        queryKey: [...TASKS_QUERY_KEY, filters],
        queryFn: () => tasksApi.getAll(filters),
    });
}

export function useTaskStats() {
    return useQuery({
        queryKey: TASK_STATS_QUERY_KEY,
        queryFn: tasksApi.getStats,
    });
}

export function useCreateTask() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (task: CreateTaskInput) => tasksApi.create(task),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: TASKS_QUERY_KEY });
            queryClient.invalidateQueries({ queryKey: TASK_STATS_QUERY_KEY });
        },
    });
}

export function useUpdateTask() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: ({ id, task }: { id: number; task: UpdateTaskInput }) =>
            tasksApi.update(id, task),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: TASKS_QUERY_KEY });
            queryClient.invalidateQueries({ queryKey: TASK_STATS_QUERY_KEY });
        },
    });
}

export function useDeleteTask() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (id: number) => tasksApi.delete(id),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: TASKS_QUERY_KEY });
            queryClient.invalidateQueries({ queryKey: TASK_STATS_QUERY_KEY });
        },
    });
}

// ==================
// Categories Hooks
// ==================

export function useCategories() {
    return useQuery({
        queryKey: CATEGORIES_QUERY_KEY,
        queryFn: categoriesApi.getAll,
    });
}

export function useCreateCategory() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (category: { name: string; color?: string; icon?: string }) =>
            categoriesApi.create(category),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: CATEGORIES_QUERY_KEY });
        },
    });
}

// ==================
// Tags Hooks
// ==================

export function useTags() {
    return useQuery({
        queryKey: TAGS_QUERY_KEY,
        queryFn: tagsApi.getAll,
    });
}

export function useCreateTag() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (tag: { name: string; color?: string }) => tagsApi.create(tag),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: TAGS_QUERY_KEY });
        },
    });
}
