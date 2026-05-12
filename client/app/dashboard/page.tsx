"use client"
import React, { useEffect, useState } from 'react'
import DashboardLayout from '../../components/dashboard/DashboardLayout'
import OverviewCard from '../../components/dashboard/OverviewCard'

type Overview = {
    patients: number
    images: number
    predictions: number
}

export default function DashboardPage() {
    const [data, setData] = useState<Overview | null>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)

    useEffect(() => {
        let mounted = true
        async function fetchOverview() {
            try {
                const res = await fetch('/api/dashboard')
                if (!res.ok) throw new Error('Network error')
                const json = await res.json()
                if (mounted) setData(json)
            } catch (err: any) {
                setError(err.message || 'Fetch error')
            } finally {
                if (mounted) setLoading(false)
            }
        }
        fetchOverview()
        return () => {
            mounted = false
        }
    }, [])

    return (
        <DashboardLayout>
            <div className="p-6 space-y-6">
                <h1 className="text-2xl font-semibold">Dashboard</h1>

                {loading && <div>Loading overview...</div>}
                {error && <div className="text-red-600">{error}</div>}

                {data && (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                        <OverviewCard title="Patients" value={String(data.patients)} />
                        <OverviewCard title="Images" value={String(data.images)} />
                        <OverviewCard title="Predictions" value={String(data.predictions)} />
                    </div>
                )}
            </div>
        </DashboardLayout>
    )
}
