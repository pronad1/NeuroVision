import React from 'react'

export default function LoginForm() {
    return (
        <form className="max-w-md mx-auto p-6 bg-white rounded shadow">
            <h3 className="text-lg font-medium mb-4">Sign in</h3>
            <label className="block mb-2">
                <span className="text-sm">Email</span>
                <input className="mt-1 block w-full border px-2 py-1 rounded" type="email" />
            </label>
            <label className="block mb-4">
                <span className="text-sm">Password</span>
                <input className="mt-1 block w-full border px-2 py-1 rounded" type="password" />
            </label>
            <button className="w-full bg-blue-600 text-white py-2 rounded">Sign in</button>
        </form>
    )
}
