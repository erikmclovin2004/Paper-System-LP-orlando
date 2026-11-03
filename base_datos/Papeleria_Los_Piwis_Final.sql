-- ============================================================
-- PAPELERIA LOS PIWIS - SCRIPT CONSOLIDADO DE BASE DE DATOS
-- MySQL 8.0.45
-- Crea las 18 tablas, relaciones, restricciones, indices y vistas.
-- No inserta usuarios, productos ni datos ficticios.
-- Ejecutar sobre una instancia limpia / esquema sin estas tablas.
-- Este archivo contiene exclusivamente objetos y configuracion SQL;
-- no incluye logica de aplicacion (Node.js / Prisma).
-- ============================================================


CREATE DATABASE IF NOT EXISTS papeleria_los_piwis
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE papeleria_los_piwis;



-- ============================================================
-- 1. ROLES
-- Define los tipos de usuario del sistema:
-- DUENO, EMPLEADO y CLIENTE.
-- ============================================================

CREATE TABLE IF NOT EXISTS roles (
    id_rol BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(40) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    descripcion VARCHAR(255) NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_roles_codigo UNIQUE (codigo),
    CONSTRAINT uq_roles_nombre UNIQUE (nombre)
) ENGINE=InnoDB;


-- ============================================================
-- 2. PERMISOS
-- Define las acciones que pueden realizar los usuarios.
-- ============================================================

CREATE TABLE IF NOT EXISTS permisos (
    id_permiso BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(80) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    descripcion VARCHAR(255) NULL,

    CONSTRAINT uq_permisos_codigo UNIQUE (codigo)
) ENGINE=InnoDB;


-- ============================================================
-- 3. ROL_PERMISOS
-- Relaciona los roles con los permisos.
-- Relacion muchos a muchos.
-- ============================================================

CREATE TABLE IF NOT EXISTS rol_permisos (
    id_rol BIGINT UNSIGNED NOT NULL,
    id_permiso BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (id_rol, id_permiso),

    CONSTRAINT fk_rol_permisos_rol
        FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_rol_permisos_permiso
        FOREIGN KEY (id_permiso)
        REFERENCES permisos(id_permiso)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- ============================================================
-- 4. PANTALLAS
-- Registra las pantallas disponibles en la aplicación.
-- ============================================================

CREATE TABLE IF NOT EXISTS pantallas (
    id_pantalla BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(80) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    ruta_frontend VARCHAR(190) NOT NULL,
    descripcion VARCHAR(255) NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_pantallas_codigo UNIQUE (codigo),
    CONSTRAINT uq_pantallas_ruta UNIQUE (ruta_frontend)
) ENGINE=InnoDB;


-- ============================================================
-- 5. PANTALLA_PERMISOS
-- Define qué permisos necesita cada pantalla.
-- ============================================================

CREATE TABLE IF NOT EXISTS pantalla_permisos (
    id_pantalla BIGINT UNSIGNED NOT NULL,
    id_permiso BIGINT UNSIGNED NOT NULL,

    PRIMARY KEY (id_pantalla, id_permiso),

    CONSTRAINT fk_pantalla_permisos_pantalla
        FOREIGN KEY (id_pantalla)
        REFERENCES pantallas(id_pantalla)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_pantalla_permisos_permiso
        FOREIGN KEY (id_permiso)
        REFERENCES permisos(id_permiso)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- ============================================================
-- 6. USUARIOS
-- Almacena dueño, empleados y clientes.
-- password_hash guarda el hash, nunca la contraseña original.
-- ============================================================

CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(190) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    id_rol BIGINT UNSIGNED NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    fecha_creacion TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    fecha_actualizacion TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_usuarios_correo UNIQUE (correo),

    CONSTRAINT fk_usuarios_rol
        FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_usuarios_rol_activo (id_rol, activo)
) ENGINE=InnoDB;


-- ============================================================
-- 7. CATEGORIAS
-- Clasifica los productos de la papelería.
-- ============================================================

CREATE TABLE IF NOT EXISTS categorias (
    id_categoria BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255) NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_categorias_nombre UNIQUE (nombre)
) ENGINE=InnoDB;


-- ============================================================
-- 8. UBICACIONES
-- Identifica dónde se encuentra cada producto.
-- ============================================================

CREATE TABLE IF NOT EXISTS ubicaciones (
    id_ubicacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    pasillo VARCHAR(20) NOT NULL,
    anaquel VARCHAR(20) NOT NULL,
    estante VARCHAR(20) NOT NULL,
    codigo VARCHAR(60) NOT NULL,
    descripcion VARCHAR(255) NULL,
    activa BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT uq_ubicaciones_codigo UNIQUE (codigo),

    CONSTRAINT uq_ubicaciones_componentes
        UNIQUE (pasillo, anaquel, estante)
) ENGINE=InnoDB;


-- ============================================================
-- 9. PRODUCTOS
-- Almacena la información de los artículos.
-- La ubicación puede ser NULL si todavía no está asignada.
-- ============================================================

CREATE TABLE IF NOT EXISTS productos (
    id_producto BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo_producto VARCHAR(60) NOT NULL,
    nombre VARCHAR(160) NOT NULL,
    descripcion TEXT NULL,

    id_categoria BIGINT UNSIGNED NOT NULL,
    id_ubicacion BIGINT UNSIGNED NULL,

    precio DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    stock INT UNSIGNED NOT NULL DEFAULT 0,
    stock_minimo INT UNSIGNED NOT NULL DEFAULT 0,

    unidad_medida VARCHAR(30) NOT NULL DEFAULT 'pieza',
    activo BOOLEAN NOT NULL DEFAULT TRUE,

    fecha_registro TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    fecha_actualizacion TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_productos_codigo
        UNIQUE (codigo_producto),

    CONSTRAINT chk_productos_precio
        CHECK (precio >= 0),

    CONSTRAINT fk_productos_categoria
        FOREIGN KEY (id_categoria)
        REFERENCES categorias(id_categoria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_productos_ubicacion
        FOREIGN KEY (id_ubicacion)
        REFERENCES ubicaciones(id_ubicacion)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    INDEX idx_productos_nombre (nombre),
    INDEX idx_productos_stock (stock),
    INDEX idx_productos_categoria (id_categoria),
    INDEX idx_productos_ubicacion (id_ubicacion)
) ENGINE=InnoDB;

-- ============================================================
-- 10. VENTAS
-- Registra las operaciones realizadas en la papelería.
-- ============================================================

CREATE TABLE IF NOT EXISTS ventas (
    id_venta BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario BIGINT UNSIGNED NOT NULL,
    id_pedido BIGINT UNSIGNED NULL,

    fecha_venta TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    total DECIMAL(12,2) NOT NULL DEFAULT 0.00,

    estado ENUM('COMPLETADA', 'CANCELADA')
        NOT NULL DEFAULT 'COMPLETADA',

    CONSTRAINT chk_ventas_total
        CHECK (total >= 0),

    CONSTRAINT uq_ventas_pedido UNIQUE (id_pedido),

    CONSTRAINT fk_ventas_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_ventas_fecha (fecha_venta),
    INDEX idx_ventas_usuario (id_usuario),
    INDEX idx_ventas_estado (estado)
) ENGINE=InnoDB;


-- ============================================================
-- 11. DETALLE_VENTAS
-- Almacena los productos que forman parte de cada venta.
-- Una venta puede contener varios productos.
-- ============================================================

CREATE TABLE IF NOT EXISTS detalle_ventas (
    id_detalle_venta BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    id_venta BIGINT UNSIGNED NOT NULL,
    id_producto BIGINT UNSIGNED NOT NULL,

    cantidad INT UNSIGNED NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,

    CONSTRAINT chk_detalle_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_detalle_precio
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_detalle_subtotal_calculado
        CHECK (subtotal = ROUND(cantidad * precio_unitario, 2)),

    CONSTRAINT fk_detalle_ventas_venta
        FOREIGN KEY (id_venta)
        REFERENCES ventas(id_venta)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_detalle_ventas_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_detalle_venta (id_venta),
    INDEX idx_detalle_producto (id_producto)
) ENGINE=InnoDB;


-- ============================================================
-- 12. MOVIMIENTOS_INVENTARIO
-- Registra todos los cambios en las existencias.
-- ============================================================

CREATE TABLE IF NOT EXISTS movimientos_inventario (
    id_movimiento BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    id_producto BIGINT UNSIGNED NOT NULL,
    id_usuario BIGINT UNSIGNED NOT NULL,
    id_detalle_venta BIGINT UNSIGNED NULL,
    id_detalle_pedido BIGINT UNSIGNED NULL,

    tipo_movimiento ENUM(
        'ENTRADA',
        'SALIDA',
        'AJUSTE_POSITIVO',
        'AJUSTE_NEGATIVO'
    ) NOT NULL,

    cantidad INT UNSIGNED NOT NULL,

    stock_anterior INT UNSIGNED NOT NULL,
    stock_nuevo INT UNSIGNED NOT NULL,

    motivo VARCHAR(255) NULL,

    fecha_movimiento TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_movimiento_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_movimiento_stock_consistente
        CHECK (
            (
                tipo_movimiento IN ('ENTRADA', 'AJUSTE_POSITIVO')
                AND stock_nuevo = stock_anterior + cantidad
            )
            OR
            (
                tipo_movimiento IN ('SALIDA', 'AJUSTE_NEGATIVO')
                AND stock_anterior >= cantidad
                AND stock_nuevo = stock_anterior - cantidad
            )
        ),

    CONSTRAINT fk_movimiento_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_movimiento_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_movimiento_detalle_venta
        FOREIGN KEY (id_detalle_venta)
        REFERENCES detalle_ventas(id_detalle_venta)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_movimiento_producto (id_producto),
    INDEX idx_movimiento_fecha (fecha_movimiento),
    INDEX idx_movimiento_tipo (tipo_movimiento)
) ENGINE=InnoDB;


-- ============================================================
-- 13. ALERTAS_INVENTARIO
-- Registra alertas relacionadas con las existencias
-- y la demanda de los productos.
-- ============================================================

CREATE TABLE IF NOT EXISTS alertas_inventario (
    id_alerta BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    id_producto BIGINT UNSIGNED NOT NULL,

    tipo_alerta ENUM(
        'STOCK_BAJO',
        'PRODUCTO_AGOTADO',
        'ALTA_DEMANDA'
    ) NOT NULL,

    mensaje VARCHAR(255) NOT NULL,

    estado ENUM(
        'ACTIVA',
        'RESUELTA'
    ) NOT NULL DEFAULT 'ACTIVA',

    fecha_creacion TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    fecha_resolucion TIMESTAMP NULL,

    CONSTRAINT fk_alertas_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_alertas_producto (id_producto),
    INDEX idx_alertas_estado (estado),
    INDEX idx_alertas_fecha (fecha_creacion)
) ENGINE=InnoDB;


-- ============================================================
-- 14. PEDIDOS
-- Registra los pedidos realizados por los clientes.
-- ============================================================

CREATE TABLE IF NOT EXISTS pedidos (
    id_pedido BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    id_cliente BIGINT UNSIGNED NOT NULL,

    fecha_pedido TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    fecha_recoleccion DATETIME NULL,

    total DECIMAL(12,2) NOT NULL DEFAULT 0.00,

    estado ENUM(
        'PENDIENTE',
        'CONFIRMADO',
        'PREPARANDO',
        'LISTO_PARA_RECOGER',
        'ENTREGADO',
        'CANCELADO'
    ) NOT NULL DEFAULT 'PENDIENTE',

    observaciones VARCHAR(255) NULL,

    CONSTRAINT chk_pedidos_total
        CHECK (total >= 0),

    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_pedidos_cliente (id_cliente),
    INDEX idx_pedidos_fecha (fecha_pedido),
    INDEX idx_pedidos_estado (estado)
) ENGINE=InnoDB;


-- ============================================================
-- 15. DETALLE_PEDIDOS
-- Almacena los productos que contiene cada pedido.
-- Un pedido puede incluir varios productos.
-- ============================================================

CREATE TABLE IF NOT EXISTS detalle_pedidos (
    id_detalle_pedido BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    id_pedido BIGINT UNSIGNED NOT NULL,
    id_producto BIGINT UNSIGNED NOT NULL,

    cantidad INT UNSIGNED NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,

    CONSTRAINT chk_detalle_pedido_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_detalle_pedido_precio
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_detalle_pedido_subtotal_calculado
        CHECK (subtotal = ROUND(cantidad * precio_unitario, 2)),

    CONSTRAINT fk_detalle_pedido_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_detalle_pedido_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_detalle_pedido (id_pedido),
    INDEX idx_detalle_pedido_producto (id_producto)
) ENGINE=InnoDB;


-- ============================================================
-- 16. HISTORIAL_ESTADOS_PEDIDO
-- Guarda cada cambio de estado de los pedidos.
-- id_usuario puede ser NULL si el cambio lo realiza
-- automáticamente el sistema.
-- ============================================================

CREATE TABLE IF NOT EXISTS historial_estados_pedido (
    id_historial BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    id_pedido BIGINT UNSIGNED NOT NULL,
    id_usuario BIGINT UNSIGNED NULL,

    estado_anterior ENUM(
        'PENDIENTE',
        'CONFIRMADO',
        'PREPARANDO',
        'LISTO_PARA_RECOGER',
        'ENTREGADO',
        'CANCELADO'
    ) NULL,

    estado_nuevo ENUM(
        'PENDIENTE',
        'CONFIRMADO',
        'PREPARANDO',
        'LISTO_PARA_RECOGER',
        'ENTREGADO',
        'CANCELADO'
    ) NOT NULL,

    comentario VARCHAR(255) NULL,

    fecha_cambio TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_historial_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_historial_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_historial_pedido (id_pedido),
    INDEX idx_historial_fecha (fecha_cambio)
) ENGINE=InnoDB;


-- ============================================================
-- 17. SUSCRIPCIONES_DISPONIBILIDAD
-- Permite que un cliente solicite una notificación
-- cuando un producto vuelva a estar disponible.
-- ============================================================

CREATE TABLE IF NOT EXISTS suscripciones_disponibilidad (
    id_suscripcion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    id_usuario BIGINT UNSIGNED NOT NULL,
    id_producto BIGINT UNSIGNED NOT NULL,

    fecha_suscripcion TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    activa BOOLEAN NOT NULL DEFAULT TRUE,

    fecha_notificacion TIMESTAMP NULL,

    CONSTRAINT uq_suscripcion_usuario_producto
        UNIQUE (id_usuario, id_producto),

    CONSTRAINT fk_suscripcion_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_suscripcion_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_suscripciones_producto (id_producto),
    INDEX idx_suscripciones_estado (activa)
) ENGINE=InnoDB;


-- ============================================================
-- 18. NOTIFICACIONES
-- Almacena los avisos dirigidos a cada usuario.
-- Puede relacionarse con un pedido o una suscripción.
-- ============================================================

CREATE TABLE IF NOT EXISTS notificaciones (
    id_notificacion BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    id_usuario BIGINT UNSIGNED NOT NULL,
    id_pedido BIGINT UNSIGNED NULL,
    id_suscripcion BIGINT UNSIGNED NULL,

    tipo ENUM(
        'PEDIDO',
        'DISPONIBILIDAD',
        'INVENTARIO',
        'GENERAL'
    ) NOT NULL,

    titulo VARCHAR(120) NOT NULL,
    mensaje VARCHAR(255) NOT NULL,

    leida BOOLEAN NOT NULL DEFAULT FALSE,

    fecha_creacion TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    fecha_lectura TIMESTAMP NULL,

    CONSTRAINT fk_notificacion_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_notificacion_pedido
        FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_notificacion_suscripcion
        FOREIGN KEY (id_suscripcion)
        REFERENCES suscripciones_disponibilidad(id_suscripcion)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_notificaciones_usuario (id_usuario),
    INDEX idx_notificaciones_leida (leida),
    INDEX idx_notificaciones_fecha (fecha_creacion)
) ENGINE=InnoDB;



-- ============================================================
-- RELACIONES AGREGADAS PARA EL FLUJO DE PEDIDOS Y VENTAS
-- Se agregan al final porque las tablas referenciadas se crean
-- después de las tablas que contienen estas columnas.
-- ============================================================

ALTER TABLE ventas
    ADD CONSTRAINT fk_ventas_pedido
    FOREIGN KEY (id_pedido)
    REFERENCES pedidos(id_pedido)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

ALTER TABLE movimientos_inventario
    ADD CONSTRAINT fk_movimiento_detalle_pedido
    FOREIGN KEY (id_detalle_pedido)
    REFERENCES detalle_pedidos(id_detalle_pedido)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;


-- ============================================================
-- VISTAS DE CONSULTA DE INVENTARIO
-- ============================================================

CREATE OR REPLACE VIEW vw_inventario AS
SELECT
    p.id_producto,
    p.codigo_producto,
    p.nombre AS producto,
    p.descripcion,
    c.nombre AS categoria,
    p.precio,
    p.stock,
    p.stock_minimo,
    p.unidad_medida,
    p.activo,
    u.pasillo,
    u.anaquel,
    u.estante,
    u.codigo AS codigo_ubicacion
FROM productos AS p
INNER JOIN categorias AS c
    ON p.id_categoria = c.id_categoria
LEFT JOIN ubicaciones AS u
    ON p.id_ubicacion = u.id_ubicacion;

CREATE OR REPLACE VIEW vw_productos_agotados AS
SELECT *
FROM vw_inventario
WHERE stock = 0;
