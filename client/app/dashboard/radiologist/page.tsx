"use client"
import React from 'react'
import DashboardLayout from '../../../components/dashboard/DashboardLayout'

export default function RadiologistDashboard() {
    return (
        <DashboardLayout>
            <div className="p-6">
                <h1 className="text-2xl font-semibold">Radiologist Dashboard</h1>
                <p className="mt-4 text-gray-600">Radiologist tools, DICOM viewer and annotation will be integrated here.</p>
            </div>
        </DashboardLayout>
    )
}
