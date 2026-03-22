type ClassValue = string | undefined | null | false | ClassValue[]

export function cn(...args: ClassValue[]): string {
  return args
    .flat(Infinity as 10)
    .filter(Boolean)
    .join(' ')
}
