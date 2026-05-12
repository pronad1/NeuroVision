import { NextResponse } from 'next/server'
import fs from 'fs'
import path from 'path'
import prisma from '../../../../database/prismaClient'

export const runtime = 'nodejs'

export async function POST(req: Request) {
    try {
        const form = await req.formData()
        const file = form.get('file') as File | null
        const patientId = form.get('patientId') as string | null

        if (!file) return new Response('No file provided', { status: 400 })

        const uploadsDir = path.join(process.cwd(), 'storage', 'uploads')
        await fs.promises.mkdir(uploadsDir, { recursive: true })

        const filename = `${Date.now()}-${(file as any).name}`
        const filepath = path.join(uploadsDir, filename)

        const arrayBuffer = await file.arrayBuffer()
        await fs.promises.writeFile(filepath, Buffer.from(arrayBuffer))

        // try to find a user to attribute upload; fallback to first user
        let uploadedBy = await prisma.user.findFirst({ where: { email: 'admin@neurovision.ai' } })
        if (!uploadedBy) uploadedBy = await prisma.user.findFirst()

        // create medical image record
        const image = await prisma.medicalImage.create({
            data: {
                patientId: patientId ?? (await prisma.patient.findFirst())?.id ?? '',
                uploadedById: uploadedBy?.id ?? '',
                imageUrl: `/storage/uploads/${filename}`,
                modality: 'BRAIN_MRI'
            }
        })

        return NextResponse.json({ id: image.id, path: image.imageUrl })
    } catch (err: any) {
        console.error('Upload error', err)
        return new Response(String(err?.message ?? 'Upload failed'), { status: 500 })
    }
}
