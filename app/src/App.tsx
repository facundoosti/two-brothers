import { Suspense } from 'react'
import { RouterProvider } from 'react-router'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { GoogleOAuthProvider } from '@react-oauth/google'
import { Toaster } from 'sileo'
import { router } from '@/routes/router'
import DevRoleSwitcher from '@/components/DevRoleSwitcher'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 30, // 30s
      retry: 1,
    },
  },
})

export default function App() {
  return (
    <GoogleOAuthProvider clientId={import.meta.env.VITE_GOOGLE_CLIENT_ID}>
      <QueryClientProvider client={queryClient}>
        <Toaster position="bottom-right" />
        <Suspense fallback={null}>
          <RouterProvider router={router} />
        </Suspense>
        {import.meta.env.DEV && <DevRoleSwitcher />}
      </QueryClientProvider>
    </GoogleOAuthProvider>
  )
}
