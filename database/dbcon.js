const { Client } = require('pg')

const client = new Client({
    host: 'localhost',
    user: 'postgres',
    password: 'prosen',
    database: 'neurovision_ai',
    port: 5432,
})

client.connect();

client.query('Select * from users', (err, res) => {
    if (err) {
        console.error(err.message);
    } else {
        console.log(res.rows);
    }
    client.end();
});
