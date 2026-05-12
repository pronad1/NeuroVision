import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
    console.log('Running seed...')

    const adminPwd = await bcrypt.hash('admin123', 10)
    const admin = await prisma.user.upsert({
        where: { email: 'admin@neurovision.ai' },
        update: {},
        create: {
            name: 'Admin User',
            email: 'admin@neurovision.ai',
            password: adminPwd,
            role: 'SUPER_ADMIN'
        }
    })

    const patientPwd = await bcrypt.hash('patient123', 10)
    const patientUser = await prisma.user.upsert({
        where: { email: 'patient1@neurovision.ai' },
        update: {},
        create: {
            name: 'Jane Patient',
            email: 'patient1@neurovision.ai',
            password: patientPwd,
            role: 'PATIENT'
        }
    })

    const patient = await prisma.patient.upsert({
        where: { userId: patientUser.id },
        update: {},
        create: {
            userId: patientUser.id,
            age: 45,
            gender: 'Female',
            bloodGroup: 'A+'
        }
    })

    const image = await prisma.medicalImage.create({
        data: {
            patientId: patient.id,
            uploadedById: admin.id,
            imageUrl: 'https://example.com/sample-image.dcm',
            modality: 'BRAIN_MRI'
        }
    })

    await prisma.aIPrediction.create({
        data: {
            imageId: image.id,
            modelName: 'dernNet-v1',
            prediction: 'No acute abnormality detected',
            confidence: 0.92,
            severity: 'LOW'
        }
    })

    console.log('Seed complete')
}

main()
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })
