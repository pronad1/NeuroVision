"use client"
import React, { ReactNode } from 'react'
import Sidebar from './Sidebar'

type Props = {
    children: ReactNode
}

export default function DashboardLayout({ children }: Props) {
    return (
        <div className="min-h-screen flex bg-gray-50">
            <aside className="w-64 bg-white border-r">
                <Sidebar />
            </aside>
            <main className="flex-1">
                {children}
            </main>
        </div>
    )
}
