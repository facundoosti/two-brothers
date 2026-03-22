export type UserRole = 'admin' | 'delivery' | 'customer'

export type UserStatus = 'active' | 'pending'

export interface User {
  id: number
  name: string
  email: string
  avatar_url: string | null
  role: UserRole
  status: UserStatus
  default_address: string | null
  created_at: string
}
