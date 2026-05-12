import { NextResponse } from 'next/server'
import prisma from '../../../../database/prismaClient'

export async function GET() {
    try {
        const patients = await prisma.patient.count()
        const images = await prisma.medicalImage.count()
        const predictions = await prisma.aIPrediction.count()

        return NextResponse.json({ patients, images, predictions })
    } catch (err) {
        console.error('API /api/dashboard error', err)
        return new Response('Internal error', { status: 500 })
    }
}
