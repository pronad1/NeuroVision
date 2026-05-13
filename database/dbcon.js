const { Client } = require('pg')

const client = new Client({
    host: process.env.PGHOST || 'localhost',
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || 'prosen',
    database: process.env.PGDATABASE || 'neurovision_ai',
    port: process.env.PGPORT ? parseInt(process.env.PGPORT, 10) : 5432,
});

(async () => {
    try {
        await client.connect()
        const res = await client.query('SELECT * FROM users LIMIT 5')
        console.log('Connected to DB — sample rows:')
        console.log(res.rows)
    } catch (err) {
        console.error('DB connection error:', err.message)
    } finally {
        try { await client.end() } catch (e) { }
    }
})()
