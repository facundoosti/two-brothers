import { createBrowserRouter } from 'react-router'

// Lazy imports
import { lazy } from 'react'

const LoginPage = lazy(() => import('@/features/auth/LoginPage'))

// Customer
const CustomerMenuPage = lazy(() => import('@/features/customer/MenuPage'))
const CustomerCartPage = lazy(() => import('@/features/customer/CartPage'))
const CustomerOrderPage = lazy(() => import('@/features/customer/OrderPage'))
const CustomerHistoryPage = lazy(() => import('@/features/customer/HistoryPage'))

// Admin
const AdminDashboardPage = lazy(() => import('@/features/admin/DashboardPage'))
const AdminOrdersPage = lazy(() => import('@/features/admin/OrdersPage'))
const AdminOrderDetailPage = lazy(() => import('@/features/admin/OrderDetailPage'))
const AdminDeliveryStaffPage = lazy(() => import('@/features/admin/DeliveryStaffPage'))
const AdminTrackingPage = lazy(() => import('@/features/admin/TrackingPage'))
const AdminMenuPage = lazy(() => import('@/features/admin/MenuPage'))
const AdminReportsPage = lazy(() => import('@/features/admin/ReportsPage'))
const AdminUsersPage = lazy(() => import('@/features/admin/UsersPage'))
const AdminSettingsPage = lazy(() => import('@/features/admin/SettingsPage'))

// Delivery
const DeliveryHomePage = lazy(() => import('@/features/delivery/DeliveryHomePage'))
const DeliveryCurrentPage = lazy(() => import('@/features/delivery/DeliveryCurrentPage'))

// Layouts
import CustomerLayout from '@/features/customer/CustomerLayout'
import AdminLayout from '@/features/admin/AdminLayout'
import DeliveryLayout from '@/features/delivery/DeliveryLayout'

export const router = createBrowserRouter([
  {
    path: '/login',
    element: <LoginPage />,
  },

  // Customer routes (protected: customer, admin)
  {
    element: <CustomerLayout />,
    children: [
      { index: true, element: <CustomerMenuPage /> },
      { path: 'carrito', element: <CustomerCartPage /> },
      { path: 'pedido/:id', element: <CustomerOrderPage /> },
      { path: 'historial', element: <CustomerHistoryPage /> },
    ],
  },

  // Admin routes (protected: admin)
  {
    path: 'admin',
    element: <AdminLayout />,
    children: [
      { index: true, element: <AdminDashboardPage /> },
      { path: 'ordenes', element: <AdminOrdersPage /> },
      { path: 'ordenes/:id', element: <AdminOrderDetailPage /> },
      { path: 'repartidores', element: <AdminDeliveryStaffPage /> },
      { path: 'trackeo/:id', element: <AdminTrackingPage /> },
      { path: 'menu', element: <AdminMenuPage /> },
      { path: 'reportes', element: <AdminReportsPage /> },
      { path: 'usuarios', element: <AdminUsersPage /> },
      { path: 'configuracion', element: <AdminSettingsPage /> },
    ],
  },

  // Delivery routes (protected: delivery)
  {
    path: 'delivery',
    element: <DeliveryLayout />,
    children: [
      { index: true, element: <DeliveryHomePage /> },
      { path: 'actual', element: <DeliveryCurrentPage /> },
    ],
  },
])
