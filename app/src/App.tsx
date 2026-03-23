import { Suspense } from 'react'
import { RouterProvider } from 'react-router'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'sileo'
import { router } from '@/routes/router'
import DevRoleSwitcher from '@/components/DevRoleSwitcher'
import { hasTenant } from '@/lib/tenant'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 30, // 30s
      retry: 1,
    },
  },
})

function NoTenantScreen() {
  return (
    <div className="min-h-dvh bg-(--color-background) flex flex-col items-center justify-center px-6 text-center">
      <h1 className="text-3xl font-black tracking-tighter text-(--color-text-primary) uppercase mb-3">
        Two Brothers
      </h1>
      <p className="text-(--color-text-secondary) text-sm mb-8">
        Plataforma de gestión para negocios gastronómicos
      </p>
      <p className="text-(--color-text-muted) text-xs">
        Accedé desde el subdominio de tu empresa
      </p>
    </div>
  )
}

export default function App() {
  if (!hasTenant() && !import.meta.env.DEV) {
    return <NoTenantScreen />
  }

  return (
    <QueryClientProvider client={queryClient}>
      <Toaster position="bottom-right" />
      <Suspense fallback={null}>
        <RouterProvider router={router} />
      </Suspense>
      {import.meta.env.DEV && <DevRoleSwitcher />}
    </QueryClientProvider>
  )
}
