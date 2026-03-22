import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import type { User } from '@/types/users'

interface AuthState {
  user: User | null
  token: string | null
  setAuth: (user: User, token: string) => void
  clearAuth: () => void
  updateDefaultAddress: (address: string) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      setAuth: (user, token) => set({ user, token }),
      clearAuth: () => set({ user: null, token: null }),
      updateDefaultAddress: (address) =>
        set((state) => ({
          user: state.user ? { ...state.user, default_address: address } : null,
        })),
    }),
    { name: 'auth' },
  ),
)
