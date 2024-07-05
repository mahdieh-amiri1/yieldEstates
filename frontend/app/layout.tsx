import { Exo } from 'next/font/google'
import './globals.css'
import ClientRootLayout from './layoutClient'

const exo_font = Exo({ weight: ['400'], subsets: ['latin'] })
export const metadata = {
  title: 'Yield Estates',
  description: 'Easily get your real estate yield token'
}

export default function RootLayout({
  children
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <ClientRootLayout>{children}</ClientRootLayout>
    </html>
  )
}
