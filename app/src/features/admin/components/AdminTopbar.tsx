import { Bell } from 'lucide-react'

interface AdminTopbarProps {
  title: string
  subtitle?: React.ReactNode
  actions?: React.ReactNode
}

export default function AdminTopbar({ title, subtitle, actions }: AdminTopbarProps) {
  return (
    <header className="flex items-center justify-between h-16 px-8 bg-(--color-sidebar) border-b border-(--color-border) shrink-0">
      <div>
        <h1 className="text-lg font-semibold text-(--color-text-primary)">{title}</h1>
        {subtitle && (
          <p className="text-xs text-(--color-text-secondary)">{subtitle}</p>
        )}
      </div>
      <div className="flex items-center gap-3">
        {actions}
        <button className="flex items-center justify-center w-8 h-8 rounded-lg text-(--color-text-secondary) hover:text-(--color-text-primary) hover:bg-(--color-surface) transition-colors">
          <Bell size={16} />
        </button>
        <div className="w-8 h-8 rounded-full bg-(--color-primary) flex items-center justify-center text-xs font-semibold text-black">
          JO
        </div>
      </div>
    </header>
  )
}
