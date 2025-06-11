import { create } from 'zustand';

interface Message {
  id: string;
  content: string;
  expiresAt?: Date;
}

interface AppState {
  messages: Message[];
  currentMessage: Message | null;
  isCreatingMessage: boolean;
  isViewingMessage: boolean;
  isLoading: boolean;
  error: string | null;
  
  // Actions
  startCreatingMessage: () => void;
  cancelCreatingMessage: () => void;
  startViewingMessage: () => void;
  cancelViewingMessage: () => void;
  setCurrentMessage: (message: Message | null) => void;
  addMessage: (message: Message) => void;
  deleteMessage: (id: string) => void;
  setError: (error: string | null) => void;
  setLoading: (isLoading: boolean) => void;
}

export const useAppStore = create<AppState>((set) => ({
  messages: [],
  currentMessage: null,
  isCreatingMessage: false,
  isViewingMessage: false,
  isLoading: false,
  error: null,
  
  // Actions
  startCreatingMessage: () => set({ 
    isCreatingMessage: true, 
    isViewingMessage: false,
    currentMessage: null,
    error: null 
  }),
  
  cancelCreatingMessage: () => set({ 
    isCreatingMessage: false, 
    currentMessage: null 
  }),
  
  startViewingMessage: () => set({ 
    isViewingMessage: true, 
    isCreatingMessage: false,
    error: null 
  }),
  
  cancelViewingMessage: () => set({ 
    isViewingMessage: false, 
    currentMessage: null 
  }),
  
  setCurrentMessage: (message) => set({ currentMessage: message }),
  
  addMessage: (message) => set((state) => ({ 
    messages: [...state.messages, message],
    currentMessage: message 
  })),
  
  deleteMessage: (id) => set((state) => ({ 
    messages: state.messages.filter(msg => msg.id !== id),
    currentMessage: state.currentMessage?.id === id ? null : state.currentMessage 
  })),
  
  setError: (error) => set({ error }),
  
  setLoading: (isLoading) => set({ isLoading })
}));
