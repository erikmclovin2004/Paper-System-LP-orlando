// Importar Express
const express = require('express');

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

// Ruta de conexión
app.get('/api/conexion', async (req, res) => {
    try {
        res.json({
            mensaje: 'Conexión exitosa con el servidor',
            estado: 'Conectado'
        });

    } catch (error) {
        console.error('Error en la conexión:', error);

        res.status(500).json({
            mensaje: 'Error al conectar con el servidor',
            error: error.message
        });
    }
});

// Iniciar el servidor
app.listen(PORT, () => {
    console.log(`Servidor iniciado en http://localhost:${PORT}`);
});