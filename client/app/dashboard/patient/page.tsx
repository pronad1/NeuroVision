"use client"
import React from 'react'
import DashboardLayout from '../../../components/dashboard/DashboardLayout'

export default function PatientDashboard() {
    return (
        <DashboardLayout>
            <div className="p-6">
                <h1 className="text-2xl font-semibold">Patient Dashboard</h1>
                <p className="mt-4 text-gray-600">Patient-specific views, uploads, and reports will appear here.</p>
            </div>
        </DashboardLayout>
    )
}
