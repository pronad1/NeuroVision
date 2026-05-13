import './globals.css'
import React from 'react'

export const metadata = {
    title: 'NeuroVision AI',
    description: 'Clinical imaging intelligence',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
    return (
        <html lang="en">
            <body className="bg-gray-50 text-gray-900">
                <div className="min-h-screen">
                    {children}
                </div>
            </body>
        </html>
    )
}
