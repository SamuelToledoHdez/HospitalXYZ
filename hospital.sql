--DROP DATABASE IF EXISTS hospitalxyz;
DROP TABLE IF EXISTS Cita;
DROP TABLE IF EXISTS Paciente;
DROP TABLE IF EXISTS Telefono;
DROP TABLE IF EXISTS Medico;
DROP TABLE IF EXISTS Equipo_medico;
DROP TABLE IF EXISTS Enfermero;
DROP TABLE IF EXISTS Ayuda;
DROP TABLE IF EXISTS Utiliza;
DROP TABLE IF EXISTS Atendido_por;
DROP TABLE IF EXISTS Receta_medica;
DROP TABLE IF EXISTS Medicamento;
DROP TABLE IF EXISTS Unidad_medica;
DROP TABLE IF EXISTS Unidad_psiquiatria;
DROP TABLE IF EXISTS Unidad_respiratoria;
DROP TABLE IF EXISTS Unidad_cardiaca;
DROP TABLE IF EXISTS Hospital;

--CREATE DATABASE hospitalxyz;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Conectar a la base de datos recién creada
\c hospitalxyz;

-- Crear la tabla de las citas médicas
CREATE TABLE IF NOT EXISTS Cita (
    Codigo SERIAL,
    Fecha DATE,
    Motivo VARCHAR(255),
    DNI_paciente TEXT REFERENCES Pacientes(DNI),
    PRIMARY KEY (Codigo, DNI_paciente)
);

-- Crear la tabla de los pacientes
CREATE TABLE IF NOT EXISTS Paciente (
    DNI TEXT PRIMARY KEY,
    DNI_cifrado TEXT,
    Nombre VARCHAR(100),
    Historial_medico TEXT,
    Fecha_nacimiento DATE,
    Edad INT -- Debe ser derivado 
);

-- Crear la tabla de los teléfonos de los pacientes
CREATE TABLE IF NOT EXISTS Telefono (
    DNI_paciente TEXT REFERENCES Pacientes(DNI),
    Telefono INT,
);

-- Crear la tabla del personal médico
CREATE TABLE IF NOT EXISTS Medico (
    Numero_colegiado INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Especialidad VARCHAR(255),
    Codigo_unidad_medica SERIAL REFERENCES Unidad_medica(Codigo)
);

-- Crear la tabla de equipos médicos
CREATE TABLE IF NOT EXISTS Equipo_medico (
    Codigo SERIAL PRIMARY KEY,
    Tipo VARCHAR(50),
    Precio DECIMAL(10, 2),
    Nombre VARCHAR(100),
    Codigo_unidad_medica SERIAL REFERENCES Unidad_medica(Codigo)
);

-- Crear la tabla de los enfermeros
CREATE TABLE IF NOT EXISTS Enfermero (
    DNI VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(100)
);

-- Crear la tabla de los enfermeros y médicos
CREATE TABLE IF NOT EXISTS Ayuda (
    DNI_enfermero TEXT REFERENCES Enfermero(DNI),,
    Numero_colegiado INT REFERENCES Medico(Numero_colegiado),
    PRIMARY KEY (DNI_enfermero, Numero_colegiado)
);

-- Crear la tabla de los médicos y equipos médicos
CREATE TABLE IF NOT EXISTS Utiliza (
    Codigo_equipo_medico SERIAL REFERENCES Equipo_medico(Codigo),
    Numero_colegiado INT REFERENCES Medico(Numero_colegiado),
    PRIMARY KEY (Codigo_equipo_medico, Numero_colegiado)
);

-- Crear la tabla de los médicos, enferemos y pacientes
CREATE TABLE IF NOT EXISTS Atendido_por (
    DNI_Paciente TEXT REFERENCES Paciente(DNI),
    Numero_colegiado INT REFERENCES Medico(Numero_colegiado),
    DNI_enfermero TEXT REFERENCES Enfermero(DNI)
    PRIMARY KEY (DNI_Paciente, Numero_colegiado, DNI_enfermero)
);

-- Crear la tabla de las recetas médicas
CREATE TABLE IF NOT EXISTS Receta_medica (
    Codigo SERIAL PRIMARY KEY,
    Fecha DATE,
    Numero_colegiado INT REFERENCES Medico(Numero_colegiado)
);

-- Crear la tabla de los medicamentos
CREATE TABLE IF NOT EXISTS Medicamento (
    Codigo SERIAL PRIMARY KEY,
    Tipo VARCHAR(50),
    Precio DECIMAL(10, 2),
    Nombre VARCHAR(100),
    Cantidad INT,
    Codigo_receta SERIAL REFERENCES Receta_medica(Codigo)
);

-- Crear la tabla de las unidades médicas
CREATE TABLE IF NOT EXISTS Unidad_medica (
    Codigo SERIAL,
    Localizacion_hospital VARCHAR(255) REFERENCES Hospital(Localizacion),
    Nombre_hospital TEXT REFERENCES Hospital(Nombre),
    Localizacion TEXT,
    Tipo VARCHAR(50),
    PRIMARY KEY (Codigo, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de la unidad de psiquiatría
CREATE TABLE IF NOT EXISTS Unidad_psiquiatria (
    Código_unidad SERIAL REFERENCES Unidad_medica(Codigo),
    Localizacion_hospital VARCHAR(255) REFERENCES Hospital(Localizacion),
    Nombre_hospital TEXT REFERENCES Hospital(Nombre),
    PRIMARY KEY (Código_unidad, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de la unidad respiratoria
CREATE TABLE IF NOT EXISTS Unidad_respiratoria (
    Código_unidad SERIAL REFERENCES Unidad_medica(Codigo),
    Localizacion_hospital VARCHAR(255) REFERENCES Hospital(Localizacion),
    Nombre_hospital TEXT REFERENCES Hospital(Nombre),
    PRIMARY KEY (Código_unidad, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de la unidad cardíaca
CREATE TABLE IF NOT EXISTS Unidad_cardiaca (
    Código_unidad SERIAL REFERENCES Unidad_medica(Codigo),
    Localizacion_hospital VARCHAR(255) REFERENCES Hospital(Localizacion),
    Nombre_hospital TEXT REFERENCES Hospital(Nombre),
    PRIMARY KEY (Código_unidad, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de los hospitales
CREATE TABLE IF NOT EXISTS Hospital (
    Nombre TEXT,
    Localizacion TEXT,
    PRIMARY KEY (Nombre, Localizacion),
    UNIQUE(Nombre),
    UNIQUE(Localizacion)
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
