CREATE DATABASE HospitalXYZ;

-- Conectar a la base de datos recién creada
\c HospitalXYZ;

-- Crear la tabla de pacientes
CREATE TABLE IF NOT EXISTS Pacientes (
    NombreCompleto VARCHAR(100),
    DNI_Cifrado BYTEA PRIMARY KEY,
    HistorialMedico TEXT,
    Telefono1 VARCHAR(20),
    FechaNacimiento DATE,
    Edad INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM FechaNacimiento)) STORED
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


-- trigger para comprobar si un medicamento de una receta existe --
DELIMITER //

CREATE TRIGGER VerificarExistenciaMedicamento
BEFORE INSERT ON RecetaMedica
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Medicamento WHERE CodigoMedicamento = NEW.CodigoMedicamento) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El medicamento especificado en la receta no existe.';
    END IF;
END;

//

DELIMITER ;

DELIMITER //

CREATE TRIGGER VerificarExistenciaMedicoEnfermero
BEFORE INSERT ON Citas
FOR EACH ROW
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Medico WHERE NumeroColegiado = NEW.NumeroColegiado) AND NOT EXISTS (SELECT 1 FROM Enfermero WHERE DNI = NEW.DNIEnfermero) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El médico o enfermero especificado en la cita no existe.';
    END IF;
END;

//

DELIMITER ;
-- Fin del script
