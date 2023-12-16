DROP DATABASE IF EXISTS HospitalXYZ;
DROP TABLE IF EXISTS Pacientes;
DROP TABLE IF EXISTS Citas;
DROP TABLE IF EXISTS Medico;
DROP TABLE IF EXISTS Enfermero;
DROP TABLE IF EXISTS RecetaMedica;
DROP TABLE IF EXISTS Medicamento;
DROP TABLE IF EXISTS EquiposMedicos;
DROP TABLE IF EXISTS UnidadesMedicas;

CREATE DATABASE HospitalXYZ;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Conectar a la base de datos recién creada
\c HospitalXYZ;

-- Crear la tabla de pacientes
CREATE TABLE IF NOT EXISTS Pacientes (
    NombreCompleto VARCHAR(100),
    DNI_Cifrado TEXT,
    HistorialMedico TEXT,
    Telefono1 VARCHAR(20),
    FechaNacimiento DATE,
    Edad INT
);

-- Crear la tabla de citas médicas
CREATE TABLE IF NOT EXISTS Citas (
    CodigoCita SERIAL PRIMARY KEY,
    Fecha DATE,
    Motivo VARCHAR(255)
);

-- Crear la tabla de personal médico
CREATE TABLE IF NOT EXISTS Medico (
    NumeroColegiado INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Especialidad VARCHAR(255)
);

-- Crear la tabla de Enfermero
CREATE TABLE IF NOT EXISTS Enfermero (
    DNI VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(100)
);

-- Crear la tabla de RecetaMedica
CREATE TABLE IF NOT EXISTS RecetaMedica (
    CodigoReceta SERIAL PRIMARY KEY,
    Fecha DATE
);

-- Crear la tabla de Medicamento
CREATE TABLE IF NOT EXISTS Medicamento (
    CodigoMedicamento SERIAL PRIMARY KEY,
    Tipo VARCHAR(50),
    Precio DECIMAL(10, 2),
    Nombre VARCHAR(100)
);

-- Crear la tabla de equipos médicos
CREATE TABLE IF NOT EXISTS EquiposMedicos (
    CodigoEquipo SERIAL PRIMARY KEY,
    Tipo VARCHAR(50),
    Precio DECIMAL(10, 2),
    Nombre VARCHAR(100)
);

-- Crear la tabla de unidades médicas
CREATE TABLE IF NOT EXISTS UnidadesMedicas (
    CodigoUnidad SERIAL PRIMARY KEY,
    Especialidad VARCHAR(50),
    Localizacion VARCHAR(255)
);

-------------------------------------------------------------------------------------

-- Crear la función de encriptación
CREATE OR REPLACE FUNCTION CifrarDNITriggerFunction()
RETURNS TRIGGER AS $$
BEGIN
  -- Utilizar la función de encriptación pgp_sym_encrypt con una clave secreta
  NEW.dni_cifrado := pgp_sym_encrypt(NEW.dni_cifrado, 'clave_secreta');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER CifrarDNITrigger
BEFORE INSERT ON "pacientes"
FOR EACH ROW
EXECUTE FUNCTION CifrarDNITriggerFunction();


-----------------------------------------------------------------------------------------------

INSERT INTO "pacientes" (nombrecompleto, dni_cifrado, historialmedico, telefono1, fechanacimiento)
VALUES ('Nombre Apellido', '12345678', 'Historial de prueba', '123456789', '2000-01-01');

SELECT * FROM "pacientes";
