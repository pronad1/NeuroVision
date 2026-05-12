import './styles/globals.css'
import React from 'react'

export const metadata = {
    title: 'NeuroVision AI',
    description: 'Enterprise medical AI platform'
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="en">
            <body>
                {children}
            </body>
        </html>
    )
}
