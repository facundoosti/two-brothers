import type { OrderStatus, AssignmentStatus } from '@/types/orders'

export const ORDER_STATUS_LABEL: Record<OrderStatus, string> = {
  pending_payment: 'Pendiente de pago',
  confirmed: 'Confirmada',
  preparing: 'Preparando',
  ready: 'Lista',
  delivering: 'En camino',
  delivered: 'Entregada',
  cancelled: 'Cancelada',
}

export const ORDER_STATUS_CLASSES: Record<OrderStatus, string> = {
  pending_payment: 'bg-(--color-accent)/15 text-(--color-accent)',
  confirmed:       'bg-(--color-status-confirmed)/15 text-(--color-status-confirmed)',
  preparing:       'bg-(--color-status-preparing)/15 text-(--color-status-preparing)',
  ready:           'bg-(--color-status-ready)/15 text-(--color-status-ready)',
  delivering:      'bg-(--color-primary)/15 text-(--color-primary)',
  delivered:       'bg-(--color-status-completed)/15 text-(--color-status-completed)',
  cancelled:       'bg-(--color-destructive)/15 text-(--color-destructive)',
}

export const ASSIGNMENT_STATUS_LABEL: Record<AssignmentStatus, string> = {
  assigned:   'Asignado',
  in_transit: 'En camino',
  delivered:  'Entregado',
}

export const ASSIGNMENT_STATUS_CLASSES: Record<AssignmentStatus, string> = {
  assigned:   'bg-(--color-status-confirmed)/15 text-(--color-status-confirmed)',
  in_transit: 'bg-(--color-primary)/15 text-(--color-primary)',
  delivered:  'bg-(--color-status-completed)/15 text-(--color-status-completed)',
}
