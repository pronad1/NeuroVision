import prisma from '../prismaClient'

async function main() {
    console.log('Testing DB connection...')
    const patients = await prisma.patient.count()
    const images = await prisma.medicalImage.count()
    const predictions = await prisma.aIPrediction.count()

    console.log({ patients, images, predictions })
}

main()
    .catch((e) => {
        console.error(e)
        process.exit(1)
    })
    .finally(async () => {
        await prisma.$disconnect()
    })
