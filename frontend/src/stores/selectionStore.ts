import { create } from 'zustand';

interface SelectionState {
    selectedIds: Set<number>;
    isSelectionMode: boolean;
    toggleSelection: (id: number) => void;
    selectAll: (ids: number[]) => void;
    clearSelection: () => void;
    toggleSelectionMode: () => void;
    setSelectionMode: (enabled: boolean) => void;
}

export const useSelectionStore = create<SelectionState>((set) => ({
    selectedIds: new Set(),
    isSelectionMode: false,

    toggleSelection: (id) =>
        set((state) => {
            const newSet = new Set(state.selectedIds);
            if (newSet.has(id)) {
                newSet.delete(id);
            } else {
                newSet.add(id);
            }
            return { selectedIds: newSet };
        }),

    selectAll: (ids) =>
        set(() => ({
            selectedIds: new Set(ids),
        })),

    clearSelection: () =>
        set(() => ({
            selectedIds: new Set(),
            isSelectionMode: false,
        })),

    toggleSelectionMode: () =>
        set((state) => ({
            isSelectionMode: !state.isSelectionMode,
            selectedIds: state.isSelectionMode ? new Set() : state.selectedIds,
        })),

    setSelectionMode: (enabled) =>
        set(() => ({
            isSelectionMode: enabled,
            selectedIds: enabled ? new Set() : new Set(),
        })),
}));
