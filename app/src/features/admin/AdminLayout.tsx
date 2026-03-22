import { Outlet } from 'react-router'
import AdminSidebar from './components/AdminSidebar'
import ProtectedRoute from '@/features/auth/ProtectedRoute'

export default function AdminLayout() {
  return (
    <ProtectedRoute allowedRoles={['admin']}>
      <div className="flex min-h-dvh bg-(--color-background)">
        <AdminSidebar />
        <div className="flex flex-col flex-1 min-w-0">
          <Outlet />
        </div>
      </div>
    </ProtectedRoute>
  )
}
