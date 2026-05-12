"use client"
import React, { useState } from 'react'

export default function UploadForm({ patientId }: { patientId?: string }) {
    const [file, setFile] = useState<File | null>(null)
    const [status, setStatus] = useState<string | null>(null)

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault()
        if (!file) return setStatus('Please select a file')

        const form = new FormData()
        form.append('file', file)
        if (patientId) form.append('patientId', patientId)

        setStatus('Uploading...')
        try {
            const res = await fetch('/api/upload', { method: 'POST', body: form })
            if (!res.ok) throw new Error(await res.text())
            const json = await res.json()
            setStatus('Upload successful: ' + json.id)
        } catch (err: any) {
            setStatus('Upload failed: ' + (err.message || String(err)))
        }
    }

    return (
        <form onSubmit={handleSubmit} className="max-w-lg bg-white p-4 rounded shadow">
            <label className="block mb-2">
                <span className="text-sm text-gray-600">Select file (DICOM, PNG, JPEG)</span>
                <input type="file" className="mt-1 block w-full" onChange={(e) => setFile(e.target.files?.[0] ?? null)} />
            </label>
            <button className="px-4 py-2 bg-blue-600 text-white rounded" type="submit">Upload</button>
            {status && <div className="mt-2 text-sm text-gray-700">{status}</div>}
        </form>
    )
}
