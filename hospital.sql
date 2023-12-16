
--DROP DATABASE IF EXISTS hospitalxyz;
DROP TABLE IF EXISTS Citas;

DROP TABLE IF EXISTS Enfermero;

DROP TABLE IF EXISTS Medicamento;
DROP TABLE IF EXISTS EquiposMedicos;
DROP TABLE IF EXISTS UnidadesMedicas;
DROP TABLE IF EXISTS Pacientes;

DROP TABLE IF EXISTS RecetaMedica;
DROP TABLE IF EXISTS Medico;

--CREATE DATABASE hospitalxyz;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Conectar a la base de datos recién creada
\c hospitalxyz;


-- Crear la tabla de personal médico
CREATE TABLE IF NOT EXISTS Medico (
    NumeroColegiado INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Especialidad VARCHAR(255)
);
-- Crear la tabla de pacientes
CREATE TABLE IF NOT EXISTS Pacientes (
    NombreCompleto VARCHAR(100),
    DNI_Cifrado TEXT,
    DNI TEXT PRIMARY KEY,
    HistorialMedico TEXT,
    Telefono1 VARCHAR(20),
    FechaNacimiento DATE,
    Edad INT,
    NumeroColegiado INT REFERENCES medico(NumeroColegiado)


);

-- Crear la tabla de citas médicas
CREATE TABLE IF NOT EXISTS Citas (
    CodigoCita SERIAL PRIMARY KEY,
    Fecha DATE,
    Motivo VARCHAR(255),
    DNI TEXT REFERENCES Pacientes(DNI)
);



-- Crear la tabla de Enfermero
CREATE TABLE IF NOT EXISTS Enfermero (
    DNI VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(100)
);

-- Crear la tabla de RecetaMedica
CREATE TABLE IF NOT EXISTS RecetaMedica (
    CodigoReceta SERIAL PRIMARY KEY,
    Fecha DATE,
    NumeroColegiado INT REFERENCES Medico(NumeroColegiado)
);

-- Crear la tabla de Medicamento
CREATE TABLE IF NOT EXISTS Medicamento (
    CodigoMedicamento SERIAL PRIMARY KEY,
    Tipo VARCHAR(50),
    Precio DECIMAL(10, 2),
    Nombre VARCHAR(100),
    Codigo_receta SERIAL REFERENCES RecetaMedica(CodigoReceta)

);

-- Crear la tabla de equipos médicos
CREATE TABLE IF NOT EXISTS EquiposMedicos (
    CodigoEquipo SERIAL PRIMARY KEY,
    Tipo VARCHAR(50),
    Precio DECIMAL(10, 2),
    Nombre VARCHAR(100)
);
-- Crear la tabla de hospitales
CREATE TABLE IF NOT EXISTS Hospital (
    Nombre TEXT,
    Localizacion TEXT,
    PRIMARY KEY (Nombre, Localizacion),
    UNIQUE(Nombre),
    UNIQUE(Localizacion)
);

-- Crear la tabla de unidades médicas
CREATE TABLE IF NOT EXISTS UnidadesMedicas (
    CodigoUnidad SERIAL PRIMARY KEY,
    Especialidad VARCHAR(50),
    Localizacion VARCHAR(255),
    Nombre_hospital TEXT,
    Localizacion_hospital TEXT,
    FOREIGN KEY (Nombre_hospital, Localizacion_hospital) REFERENCES Hospital(Nombre, Localizacion)
);



-------------------------------------------------------------------------------------

-- Crear la función de encriptación
CREATE OR REPLACE FUNCTION CifrarDNITriggerFunction()
RETURNS TRIGGER AS $$
BEGIN
  -- Utilizar la función de encriptación pgp_sym_encrypt con una clave secreta
  NEW.dni_cifrado := pgp_sym_encrypt(NEW.dni, 'clave_secreta');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER CifrarDNITrigger
BEFORE INSERT ON "pacientes"
FOR EACH ROW
EXECUTE FUNCTION CifrarDNITriggerFunction();


CREATE OR REPLACE FUNCTION DescifrarDNI(dni_cifrado TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Utilizar la función de descifrado pgp_sym_decrypt_bytea con la clave secreta
    BEGIN
        RETURN encode(pgp_sym_decrypt_bytea(dni_cifrado::bytea, 'clave_secreta'), 'escape')::text;
    EXCEPTION
        WHEN OTHERS THEN
            -- Manejar cualquier excepción que pueda surgir al descifrar
            RAISE EXCEPTION 'Error al descifrar el DNI_Cifrado (%): %', dni_cifrado, SQLSTATE;
    END;
END;
$$ LANGUAGE plpgsql;


-- Crear un procedimiento almacenado que utiliza la función de descifrado
CREATE OR REPLACE FUNCTION ConsultarPaciente()
RETURNS TABLE (
  nombrecompleto VARCHAR(100),
  dni TEXT,
  historialmedico TEXT,
  telefono1 VARCHAR(20),
  fechanacimiento DATE
) AS $$
BEGIN
  RETURN QUERY
    SELECT
      "pacientes".nombrecompleto,
      DescifrarDNI("pacientes".dni_cifrado) AS dni,
      "pacientes".historialmedico,
      "pacientes".telefono1,
      "pacientes".fechanacimiento
    FROM "pacientes";
END;
$$ LANGUAGE plpgsql;


-- Crear el trigger
CREATE OR REPLACE FUNCTION validar_medico_existente()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Medico WHERE NumeroColegiado = NEW.NumeroColegiado) THEN
        RAISE EXCEPTION 'El médico con el número colegiado % no existe.', NEW.NumeroColegiado;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Asociar el trigger a la tabla Pacientes
CREATE TRIGGER tr_validar_medico_existente
BEFORE INSERT ON Pacientes
FOR EACH ROW
EXECUTE FUNCTION validar_medico_existente();

-----------------------------------------------------------------------------------------------
-- Insertar médicos
INSERT INTO Medico (NumeroColegiado, Nombre, Especialidad) VALUES
(1, 'Dr. Juan Pérez', 'Cardiología'),
(2, 'Dra. María García', 'Pediatría'),
(3, 'Dr. Carlos Rodríguez', 'Cirugía General');

-- Insertar pacientes
INSERT INTO Pacientes (NombreCompleto, DNI, HistorialMedico, Telefono1, FechaNacimiento, Edad, NumeroColegiado) VALUES
('Ana Martínez', '12345678A', 'Historial de Ana', '123-456-7890', '1990-05-15', 32, 1);


INSERT INTO Citas (Fecha, Motivo, DNI) VALUES
('2023-12-20', 'Consulta rutinaria', '12345678A');

-- Intentar insertar una cita con DNI_Cifrado no existente (debería lanzar una excepción)

SELECT * FROM Pacientes;
SELECT * FROM ConsultarPaciente();
