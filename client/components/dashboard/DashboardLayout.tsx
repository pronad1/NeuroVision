import React from 'react'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
    return (
        <div className="flex">
            <aside className="w-60 bg-white border-r min-h-screen p-4">
                <h2 className="text-lg font-bold">NeuroVision</h2>
                <nav className="mt-6">
                    <ul className="space-y-2">
                        <li className="text-sm text-gray-700">Overview</li>
                        <li className="text-sm text-gray-700">Cases</li>
                        <li className="text-sm text-gray-700">Models</li>
                        <li className="text-sm text-gray-700">Experiments</li>
                    </ul>
                </nav>
            </aside>
            <main className="flex-1 bg-gray-50 min-h-screen">{children}</main>
        </div>
    )
}
