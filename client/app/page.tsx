import React from 'react'
import DashboardLayout from '../components/dashboard/DashboardLayout'
import OverviewCard from '../components/dashboard/OverviewCard'

export default function Page() {
    return (
        <DashboardLayout>
            <div className="p-6">
                <h1 className="text-2xl font-semibold mb-4">Dashboard</h1>
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <OverviewCard title="Cases" value="0" />
                    <OverviewCard title="Models" value="0" />
                    <OverviewCard title="Experiments" value="0" />
                </div>
            </div>
        </DashboardLayout>
    )
}
