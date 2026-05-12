"use client"
import React from 'react'
import DashboardLayout from '../../../../components/dashboard/DashboardLayout'
import UploadForm from '../../../../components/upload/UploadForm'

export default function PatientUploadPage() {
    return (
        <DashboardLayout>
            <div className="p-6">
                <h1 className="text-2xl font-semibold">Upload Medical Image</h1>
                <p className="mt-2 text-gray-600">Upload DICOM or image files for AI processing.</p>
                <div className="mt-4">
                    <UploadForm />
                </div>
            </div>
        </DashboardLayout>
    )
}
