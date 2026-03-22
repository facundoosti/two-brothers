import { create } from 'zustand'

export interface CartItem {
  id: number
  name: string
  price: number
  quantity: number
}

interface CartState {
  items: CartItem[]
  modality: 'delivery' | 'pickup'
  address: string
  paymentMethod: 'cash' | 'transfer'
  addItem: (item: Omit<CartItem, 'quantity'>) => void
  removeItem: (id: number) => void
  setQuantity: (id: number, qty: number) => void
  setModality: (m: 'delivery' | 'pickup') => void
  setAddress: (a: string) => void
  setPaymentMethod: (m: 'cash' | 'transfer') => void
  clearCart: () => void
}

export const useCartStore = create<CartState>((set) => ({
  items: [],
  modality: 'delivery',
  address: '',
  paymentMethod: 'cash',

  addItem: (item) =>
    set((state) => {
      const existing = state.items.find((i) => i.id === item.id)
      if (existing) {
        return {
          items: state.items.map((i) =>
            i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i,
          ),
        }
      }
      return { items: [...state.items, { ...item, quantity: 1 }] }
    }),

  removeItem: (id) =>
    set((state) => ({ items: state.items.filter((i) => i.id !== id) })),

  setQuantity: (id, qty) =>
    set((state) => {
      if (qty <= 0) return { items: state.items.filter((i) => i.id !== id) }
      return { items: state.items.map((i) => (i.id === id ? { ...i, quantity: qty } : i)) }
    }),

  setModality: (modality) => set({ modality }),
  setAddress: (address) => set({ address }),
  setPaymentMethod: (paymentMethod) => set({ paymentMethod }),
  clearCart: () => set({ items: [], address: '' }),
}))
