import NextAuth from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { PrismaAdapter } from '@next-auth/prisma-adapter'
import prisma from '../../../../database/prismaClient'
import bcrypt from 'bcryptjs'

export const authOptions = {
    adapter: PrismaAdapter(prisma as any),
    session: { strategy: 'jwt' },
    providers: [
        CredentialsProvider({
            name: 'Credentials',
            credentials: {
                email: { label: 'Email', type: 'text' },
                password: { label: 'Password', type: 'password' }
            },
            async authorize(credentials) {
                if (!credentials) return null
                const user = await prisma.user.findUnique({ where: { email: credentials.email } })
                if (!user) return null
                const valid = await bcrypt.compare(credentials.password, user.password)
                if (!valid) return null
                // return lightweight user object
                return { id: user.id, name: user.name, email: user.email, role: user.role }
            }
        })
    ],
    callbacks: {
        async jwt({ token, user }) {
            if (user) token.user = user
            return token
        },
        async session({ session, token }) {
            // @ts-ignore
            session.user = token.user
            return session
        }
    },
    secret: process.env.NEXTAUTH_SECRET
}

const handler = NextAuth(authOptions)
export { handler as GET, handler as POST }
