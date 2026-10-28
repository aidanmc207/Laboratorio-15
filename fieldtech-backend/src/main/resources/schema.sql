-- Script DDL para Base de Datos H2 en Memoria: fieldtechdb
-- Curso IF0009 - Desarrollo de Software IV (Laboratorio 15)

DROP TABLE IF EXISTS incidencias;

CREATE TABLE incidencias (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(120) NOT NULL,
    descripcion VARCHAR(500) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    latitud DOUBLE NOT NULL,
    longitud DOUBLE NOT NULL,
    foto_url VARCHAR(255),
    estado VARCHAR(30) NOT NULL DEFAULT 'REGISTRADA',
    fecha_reporte TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    tecnico_codigo VARCHAR(50) NOT NULL
);
