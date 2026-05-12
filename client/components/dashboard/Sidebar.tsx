"use client"
import React from 'react'

export default function Sidebar() {
    return (
        <div className="p-6">
            <h2 className="text-lg font-semibold mb-4">NeuroVision</h2>
            <nav className="space-y-2">
                <a className="block px-3 py-2 rounded hover:bg-gray-100" href="/dashboard">Overview</a>
                <a className="block px-3 py-2 rounded hover:bg-gray-100" href="/dashboard/patients">Patients</a>
                <a className="block px-3 py-2 rounded hover:bg-gray-100" href="/dashboard/models">Models</a>
                <a className="block px-3 py-2 rounded hover:bg-gray-100" href="/dashboard/reports">Reports</a>
            </nav>
        </div>
    )
}
