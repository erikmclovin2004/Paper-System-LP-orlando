
// Importar Express
const express = require('express');

// Importar la conexión a MySQL
const db = require('./config/db');

// Crear la aplicación
const app = express();

// Configurar el puerto
const PORT = 3000;

// Middleware para recibir JSON
app.use(express.json());

// Ruta principal
app.get('/', (req, res) => {
    res.send('Servidor Paper-System funcionando correctamente');
});

// Ruta para comprobar la conexión REAL con MySQL
app.get('/api/conexion', async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT
                DATABASE() AS base_datos,
                COUNT(*) AS total_tablas
            FROM information_schema.tables
            WHERE table_schema = DATABASE()
            AND table_type = 'BASE TABLE'
        `);

        res.json({
            mensaje: 'Conexión exitosa con MySQL',
            estado: 'Conectado',
            base_datos: rows[0].base_datos,
            total_tablas: rows[0].total_tablas
        });

    } catch (error) {
        console.error('Error en la conexión con MySQL:', error);

        res.status(500).json({
            mensaje: 'Error de conexión con MySQL',
            estado: 'Desconectado',
            error: error.message
        });
    }
});

// Iniciar el servidor
app.listen(PORT, () => {
    console.log(`Servidor iniciado en http://localhost:${PORT}`);
});
