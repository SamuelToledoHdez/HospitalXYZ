-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS HospitalXYZ;
USE HospitalXYZ;

-- Crear la tabla de pacientes
CREATE TABLE IF NOT EXISTS Pacientes (
    NombreCompleto VARCHAR(100),
    DNI_Cifrado VARBINARY(255) PRIMARY KEY,
    HistorialMedico TEXT,
    Telefono1 VARCHAR(20),
    FechaNacimiento DATE,
    Edad INT GENERATED ALWAYS AS (YEAR(CURDATE()) - YEAR(FechaNacimiento)) STORED
);

-- Crear la tabla de citas médicas
CREATE TABLE IF NOT EXISTS Citas (
    
);

-- Crear la tabla de personal médico
CREATE TABLE IF NOT EXISTS Medico (
    
);
-- Crear la tabla de Enfermero
CREATE TABLE IF NOT EXISTS Enfermero (
    
);

-- Crear la tabla de RecetaMedica
CREATE TABLE IF NOT EXISTS RecetaMedica (
    
);

-- Crear la tabla de Medicamento
CREATE TABLE IF NOT EXISTS Medicamento (
    
);


-- Crear la tabla de equipos médicos
CREATE TABLE IF NOT EXISTS EquiposMedicos (
    
);

-- Crear la tabla de unidades médicas
CREATE TABLE IF NOT EXISTS UnidadesMedicas (
    
);


-------------------------------------------------------------------------------------

DELIMITER //

-- Trigger para cifrar el DNI al insertar un nuevo paciente
CREATE TRIGGER CifrarDNITrigger BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    SET NEW.DNI_Cifrado = AES_ENCRYPT(NEW.DNI, 'clave_secreta');
END //
    

DELIMITER ;


DELIMITER //
CREATE PROCEDURE DescifrarDNI()
BEGIN
    SELECT PacienteID, NombreCompleto, AES_DECRYPT(DNI_Cifrado, 'clave_secreta') AS DNI
    FROM Pacientes;
END //
DELIMITER ;
-- Fin del script
