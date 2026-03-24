export type OrderStatus =
  | 'pending_payment'
  | 'confirmed'
  | 'preparing'
  | 'ready'
  | 'delivering'
  | 'delivered'
  | 'cancelled'

export type OrderModality = 'delivery' | 'pickup'

export type PaymentMethod = 'cash' | 'transfer'

export interface Category {
  id: number
  name: string
  position: number
}

export interface CategoryWithItems extends Category {
  menu_items: MenuItem[]
}

export interface MenuItem {
  id: number
  category_id: number
  name: string
  description: string | null
  price: number
  available: boolean
  daily_stock: number | null
  image_url: string | null
}

export interface OrderItem {
  id: number
  menu_item_id: number
  name: string
  quantity: number
  unit_price: number
  notes: string | null
  image_url: string | null
}

export interface Order {
  id: number
  status: OrderStatus
  modality: OrderModality
  payment_method: PaymentMethod
  total: number
  delivery_fee: number
  delivery_address: string | null
  cancellation_reason: string | null
  created_at: string
  confirmed_at: string | null
  preparing_at: string | null
  ready_at: string | null
  delivering_at: string | null
  delivered_at: string | null
  cancelled_at: string | null
  paid: boolean
  delivery_assignment_id: number | null
  user: { name: string; email: string }
  order_items: OrderItem[]
}

export type AssignmentStatus = 'assigned' | 'in_transit' | 'delivered'

export interface DeliveryAssignment {
  id: number
  status: AssignmentStatus
  assigned_at: string
  departed_at: string | null
  delivered_at: string | null
  order_id: number
  user_id: number
}

export interface AssignmentOrderItem {
  id: number
  name: string
  quantity: number
  unit_price: number
  notes: string | null
}

export interface DeliveryAssignmentWithOrder extends DeliveryAssignment {
  user_name: string
  order: {
    id: number
    status: string
    modality: string
    delivery_address: string | null
    latitude: number | null
    longitude: number | null
    total: number
    payment_method: string
    user: { name: string }
    order_items: AssignmentOrderItem[]
  }
}

export interface DailyStock {
  id: number
  menu_item_id: number
  menu_item_name: string
  date: string
  total: number
  used: number
  available: number
}

export interface DeliveryLocation {
  latitude: number
  longitude: number
  recorded_at: string
}
