"use client"
import React, { useState } from 'react'
import { signIn } from 'next-auth/react'

export default function LoginForm() {
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault()
        setLoading(true)
        setError(null)
        const res = await signIn('credentials', { redirect: false, email, password })
        setLoading(false)
        if (res?.error) setError(res.error)
        if (res?.ok) window.location.href = '/dashboard'
    }

    return (
        <form onSubmit={handleSubmit} className="max-w-md mx-auto p-6 bg-white rounded shadow">
            <h2 className="text-lg font-semibold mb-4">Sign in</h2>
            {error && <div className="text-red-600 mb-2">{error}</div>}
            <label className="block mb-2">
                <span className="text-sm text-gray-600">Email</span>
                <input className="mt-1 block w-full border rounded px-2 py-1" value={email} onChange={(e) => setEmail(e.target.value)} />
            </label>
            <label className="block mb-4">
                <span className="text-sm text-gray-600">Password</span>
                <input type="password" className="mt-1 block w-full border rounded px-2 py-1" value={password} onChange={(e) => setPassword(e.target.value)} />
            </label>
            <button disabled={loading} className="w-full bg-blue-600 text-white py-2 rounded">
                {loading ? 'Signing in...' : 'Sign in'}
            </button>
        </form>
    )
}
