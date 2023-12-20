-- Drop dependent objects first
DROP TABLE IF EXISTS Equipo_medico CASCADE ;
DROP TABLE IF EXISTS Enfermero CASCADE;
DROP TABLE IF EXISTS Ayuda CASCADE;
DROP TABLE IF EXISTS Utiliza CASCADE;
DROP TABLE IF EXISTS Atendido_por CASCADE;
DROP TABLE IF EXISTS Receta_medica CASCADE;
DROP TABLE IF EXISTS Medicamento CASCADE;
DROP TABLE IF EXISTS Unidad_medica CASCADE;
DROP TABLE IF EXISTS Unidad_psiquiatria CASCADE;
DROP TABLE IF EXISTS Unidad_respiratoria CASCADE;
DROP TABLE IF EXISTS Unidad_cardiaca CASCADE;


-- Now you can drop the main tables
DROP TABLE IF EXISTS Medico CASCADE;
DROP TABLE IF EXISTS Hospital CASCADE;
DROP TABLE IF EXISTS Cita CASCADE;
DROP TABLE IF EXISTS Paciente CASCADE;
DROP TABLE IF EXISTS Telefono CASCADE;

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

DROP FUNCTION IF EXISTS ConsultarPaciente();
--CREATE DATABASE hospitalxyz;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Conectar a la base de datos recién creada
\c hospitalxyz;

-- Crear la tabla de los hospitales
CREATE TABLE Hospital (
    Nombre TEXT,
    Localizacion TEXT,
    PRIMARY KEY (Nombre, Localizacion),
    UNIQUE(Nombre),
    UNIQUE(Localizacion)
);

-- Crear la tabla de los pacientes
CREATE TABLE Paciente (
    DNI TEXT PRIMARY KEY,
    DNI_cifrado TEXT,
    Nombre VARCHAR(100),
    Historial_medico TEXT,
    Fecha_nacimiento DATE,
    Edad INT -- Debe ser derivado 
);

-- Crear la tabla de las citas médicas
CREATE TABLE Cita (
    Codigo SERIAL,
    Fecha DATE,
    Motivo VARCHAR(255),
    DNI_paciente TEXT REFERENCES Paciente(DNI),
    PRIMARY KEY (Codigo, DNI_paciente)
);



-- Crear la tabla de los teléfonos de los pacientes
CREATE TABLE Telefono (
    DNI_paciente TEXT REFERENCES Paciente(DNI),
    Telefono INT
);



-- Crear la tabla de los enfermeros
CREATE TABLE Enfermero (
    DNI VARCHAR(20) PRIMARY KEY,
    Nombre VARCHAR(100)
);


-- Crear la tabla de las unidades médicas
CREATE TABLE Unidad_medica (
    Codigo SERIAL,
    Localizacion_hospital VARCHAR(255) REFERENCES Hospital(Localizacion),
    Nombre_hospital TEXT REFERENCES Hospital(Nombre),
    Localizacion TEXT,
    Tipo VARCHAR(50),
    PRIMARY KEY (Codigo, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla del médico
CREATE TABLE Medico (
    Numero_colegiado INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Especialidad VARCHAR(255),
    Codigo_unidad_medica SERIAL, 
    Nombre_hospital TEXT,
    Localizacion_hospital TEXT,
    FOREIGN KEY (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital) REFERENCES Unidad_medica(Codigo, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de los enfermeros y médicos
CREATE TABLE Ayuda (
    DNI_enfermero TEXT REFERENCES Enfermero(DNI),
    Numero_colegiado INT REFERENCES Medico(Numero_colegiado),
    PRIMARY KEY (DNI_enfermero, Numero_colegiado)
);



-- Crear la tabla de los médicos, enferemos y pacientes
CREATE TABLE Atendido_por (
    DNI_Paciente TEXT REFERENCES Paciente(DNI),
    Numero_colegiado INT REFERENCES Medico(Numero_colegiado),
    DNI_enfermero TEXT REFERENCES Enfermero(DNI),
    PRIMARY KEY (DNI_Paciente, Numero_colegiado, DNI_enfermero)
);

-- Crear la tabla de las recetas médicas
CREATE TABLE Receta_medica (
    Codigo SERIAL PRIMARY KEY,
    Fecha DATE,
    Numero_colegiado INT REFERENCES Medico(Numero_colegiado)
);

-- Crear la tabla de los medicamentos
CREATE TABLE Medicamento (
    Codigo SERIAL PRIMARY KEY,
    Tipo VARCHAR(50),
    Precio DECIMAL(10, 2),
    Nombre VARCHAR(100),
    Cantidad INT,
    Codigo_receta SERIAL REFERENCES Receta_medica(Codigo)
);

-- Crear la tabla de equipos médicos
CREATE TABLE Equipo_medico (
    Codigo SERIAL PRIMARY KEY,
    Tipo VARCHAR(50),
    Precio DECIMAL(10, 2),
    Nombre VARCHAR(100),
    Codigo_unidad_medica SERIAL, 
    Nombre_hospital TEXT,
    Localizacion_hospital TEXT,
    FOREIGN KEY (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital) REFERENCES Unidad_medica(Codigo, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de la unidad de psiquiatría
CREATE TABLE Unidad_psiquiatria (
    Codigo_unidad_medica SERIAL,
    Localizacion_hospital TEXT,
    Nombre_hospital TEXT,
    PRIMARY KEY (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital),
    FOREIGN KEY (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital) REFERENCES Unidad_medica(Codigo, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de la unidad respiratoria
CREATE TABLE Unidad_respiratoria (
   Codigo_unidad_medica SERIAL,
    Localizacion_hospital TEXT,
    Nombre_hospital TEXT,
    PRIMARY KEY (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital),
    FOREIGN KEY (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital) REFERENCES Unidad_medica(Codigo, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de la unidad cardíaca
CREATE TABLE Unidad_cardiaca (
    Codigo_unidad_medica SERIAL,
    Localizacion_hospital TEXT,
    Nombre_hospital TEXT,
    PRIMARY KEY (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital),
    FOREIGN KEY (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital) REFERENCES Unidad_medica(Codigo, Localizacion_hospital, Nombre_hospital)
);

-- Crear la tabla de los médicos y equipos médicos
CREATE TABLE Utiliza (
    Codigo_equipo_medico SERIAL REFERENCES Equipo_medico(Codigo),
    Numero_colegiado INT REFERENCES Medico(Numero_colegiado),
    PRIMARY KEY (Codigo_equipo_medico, Numero_colegiado)
);

-------------------------------------------------------------------------------------

-- -- Crear la función de encriptación
CREATE OR REPLACE FUNCTION CifrarDNITriggerFunction()
RETURNS TRIGGER AS $$
    BEGIN
--   -- Utilizar la función de encriptación pgp_sym_encrypt con una clave secreta
NEW.dni_cifrado := pgp_sym_encrypt(NEW.DNI, 'clave_secreta');
 RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -- Crear el trigger
CREATE TRIGGER CifrarDNITrigger
BEFORE INSERT ON "paciente"
FOR EACH ROW
EXECUTE FUNCTION CifrarDNITriggerFunction();


CREATE OR REPLACE FUNCTION DescifrarDNI(dni_cifrado TEXT)
RETURNS TEXT AS $$
BEGIN
--     -- Utilizar la función de descifrado pgp_sym_decrypt_bytea con la clave secreta
 BEGIN
     RETURN encode(pgp_sym_decrypt_bytea(dni_cifrado::bytea, 'clave_secreta'), 'escape')::text;
   EXCEPTION
       WHEN OTHERS THEN
--             -- Manejar cualquier excepción que pueda surgir al descifrar
           RAISE EXCEPTION 'Error al descifrar el DNI_Cifrado (%): %', dni_cifrado, SQLSTATE;
  END;
END;
$$ LANGUAGE plpgsql;


-- -- Crear un procedimiento almacenado que utiliza la función de descifrado
CREATE OR REPLACE FUNCTION ConsultarPaciente()
RETURNS TABLE (
nombrecompleto VARCHAR(100),
dni TEXT,
historialmedico TEXT,

fechanacimiento DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
    "paciente".nombre,
    DescifrarDNI("paciente".dni_cifrado) AS dni,
    "paciente".historial_medico,

    "paciente".fecha_nacimiento
   FROM "paciente";
 END;
$$ LANGUAGE plpgsql;


-----------------------------------------------------------------------------------------------
-- Insertar valores en la tabla Hospital
INSERT INTO Hospital (Nombre, Localizacion) VALUES
('Hospital XYZ', 'Ciudad A');


INSERT INTO Paciente (DNI, DNI_cifrado, Nombre, Historial_medico, Fecha_nacimiento, Edad) VALUES
('11111111C', 'cifrado111', 'Ana Sánchez', 'Historial de Ana', '1988-03-20', 34),
('22222222D', 'cifrado222', 'Carlos Rodríguez', 'Historial de Carlos', '1995-11-10', 26),
('33333333E', 'cifrado333', 'Sofía Martínez', 'Historial de Sofía', '1980-08-05', 42),
('44444444F', 'cifrado444', 'Alejandro Gómez', 'Historial de Alejandro', '1992-07-15', 29),
('55555555G', 'cifrado555', 'Laura Pérez', 'Historial de Laura', '1987-09-30', 35),
('66666666H', 'cifrado666', 'Miguel Torres', 'Historial de Miguel', '1983-12-25', 39),
('77777777I', 'cifrado777', 'Elena Ruiz', 'Historial de Elena', '1998-04-18', 24),
('88888888J', 'cifrado888', 'David López', 'Historial de David', '1982-06-08', 40);



-- Insertar más valores en la tabla Telefono
INSERT INTO Telefono (DNI_paciente, Telefono) VALUES
('11111111C', 111111111),
('22222222D', 222222222),
('33333333E', 333333333),
('44444444F', 444444444),
('55555555G', 555555555),
('66666666H', 666666666),
('77777777I', 777777777),
('88888888J', 888888888);

-- Insertar más valores en la tabla Enfermero
INSERT INTO Enfermero (DNI, Nombre) VALUES
('C1111111', 'Enfermero 3'),
('D2222222', 'Enfermero 4'),
('E3333333', 'Enfermero 5'),
('F4444444', 'Enfermero 6'),
('G5555555', 'Enfermero 7'),
('H6666666', 'Enfermero 8'),
('I7777777', 'Enfermero 9'),
('J8888888', 'Enfermero 10');

-- Insertar valores en la tabla Unidad_medica
INSERT INTO Unidad_medica (Localizacion_hospital, Nombre_hospital, Localizacion, Tipo) VALUES
('Ciudad A', 'Hospital XYZ', 'Planta 1', 'Unidad_psiquiatria'),
('Ciudad A', 'Hospital XYZ', 'Planta 2', 'Unidad_respiratoria'),
('Ciudad A', 'Hospital XYZ', 'Planta 2', 'Unidad_cardiaca');

-- Insertar más valores en la tabla Medico
INSERT INTO Medico (Numero_colegiado, Nombre, Especialidad, Codigo_unidad_medica, Nombre_hospital, Localizacion_hospital) VALUES
(987654, 'Dr. Ramírez', 'Oncología', 1, 'Hospital XYZ', 'Ciudad A'),
(654321, 'Dra. Castro', 'Dermatología', 2, 'Hospital XYZ', 'Ciudad A'),
(333777, 'Dr. González', 'Neurología', 1, 'Hospital XYZ', 'Ciudad A'),
(111999, 'Dra. Soto', 'Endocrinología', 2, 'Hospital XYZ', 'Ciudad A'),
(777333, 'Dr. Morales', 'Urología', 1, 'Hospital XYZ', 'Ciudad A'),
(222444, 'Dra. Ríos', 'Gastroenterología', 2, 'Hospital XYZ', 'Ciudad A'),
(666000, 'Dr. Vargas', 'Nefrología', 1, 'Hospital XYZ', 'Ciudad A'),
(888111, 'Dra. Díaz', 'Oftalmología', 2, 'Hospital XYZ', 'Ciudad A');


-- Insertar más valores en la tabla Ayuda
INSERT INTO Ayuda (DNI_enfermero, Numero_colegiado) VALUES
('C1111111', 987654),
('D2222222', 654321),
('E3333333', 333777),
('F4444444', 111999),
('G5555555', 777333),
('H6666666', 222444),
('I7777777', 666000),
('J8888888', 888111);

-- Insertar más valores en la tabla Atendido_por
INSERT INTO Atendido_por (DNI_Paciente, Numero_colegiado, DNI_enfermero) VALUES
('11111111C', 987654, 'C1111111'),
('22222222D', 654321, 'D2222222'),
('33333333E', 333777, 'E3333333'),
('44444444F', 111999, 'F4444444'),
('55555555G', 777333, 'G5555555'),
('66666666H', 222444, 'H6666666'),
('77777777I', 666000, 'I7777777'),
('88888888J', 888111, 'J8888888');
-- Insertar más valores en la tabla Receta_medica
INSERT INTO Receta_medica (Fecha, Numero_colegiado) VALUES
('2023-03-10', 654321),
('2023-04-05', 987654),
('2023-05-20', 111999),
('2023-06-15', 333777),
('2023-07-25', 222444),
('2023-08-30', 777333),
('2023-09-12', 888111),
('2023-10-18', 666000);

-- Insertar más valores en la tabla Medicamento
INSERT INTO Medicamento (Tipo, Precio, Nombre, Cantidad, Codigo_receta) VALUES
('Antiinflamatorio', 12.75, 'Ibuprofeno', 30, 1),
('Analgésico', 8.50, 'Aspirina', 25, 2),
('Antihistamínico', 18.25, 'Loratadina', 15, 3),
('Antibiótico', 25.00, 'Ciprofloxacino', 20, 4),
('Antihipertensivo', 30.50, 'Losartán', 10, 5),
('Antipirético', 9.99, 'Ibuprofeno', 15, 6),
('Antiemético', 15.75, 'Ondansetrón', 12, 7),
('Antiulceroso', 22.00, 'Omeprazol', 18, 8);

-- Insertar valores en la tabla Equipo_medico
INSERT INTO Equipo_medico (Tipo, Precio, Nombre, Codigo_unidad_medica, Nombre_hospital, Localizacion_hospital) VALUES
('Rayos X', 3000.00, 'Equipo de Rayos X', 1, 'Hospital XYZ', 'Ciudad A'),
('Ecógrafo', 2500.00, 'Ecógrafo portátil', 2, 'Hospital XYZ', 'Ciudad A'),
('Desfibrilador', 2000.00, 'Desfibrilador automático', 3, 'Hospital XYZ', 'Ciudad A'),
('Respirador', 5000.00, 'Respirador avanzado', 1, 'Hospital XYZ', 'Ciudad A'),
('Laboratorio Móvil', 7000.00, 'Laboratorio de análisis móvil', 2, 'Hospital XYZ', 'Ciudad A'),
('Endoscopio', 1800.00, 'Endoscopio flexible', 3, 'Hospital XYZ', 'Ciudad A'),
('Monitor de signos vitales', 1200.00, 'Monitor de signos vitales', 1, 'Hospital XYZ', 'Ciudad A'),
('Bomba de Infusión', 900.00, 'Bomba de Infusión programable', 2, 'Hospital XYZ', 'Ciudad A');


-- Insertar valores en la tabla Unidad_psiquiatria
INSERT INTO Unidad_psiquiatria (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital) VALUES
(1, 'Ciudad A', 'Hospital XYZ');

-- Insertar valores en la tabla Unidad_respiratoria
INSERT INTO Unidad_respiratoria (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital) VALUES
(2, 'Ciudad A', 'Hospital XYZ');

-- Insertar valores en la tabla Unidad_cardiaca
INSERT INTO Unidad_cardiaca (Codigo_unidad_medica, Localizacion_hospital, Nombre_hospital) VALUES
(3, 'Ciudad A', 'Hospital XYZ');

-- Insertar valores en la tabla Utiliza
INSERT INTO Utiliza (Codigo_equipo_medico, Numero_colegiado) VALUES
(1, 987654),
(2, 654321),
(3, 333777),
(4, 111999),
(5, 777333),
(6, 222444),
(7, 666000),
(8, 888111);

SELECT * FROM Paciente;
SELECT * FROM ConsultarPaciente();
-- Hospital
SELECT * FROM Hospital;

-- Cita
SELECT * FROM Cita;

-- Telefono
SELECT * FROM Telefono;

-- Enfermero
SELECT * FROM Enfermero;

-- Unidad_medica
SELECT * FROM Unidad_medica;

-- Medico
SELECT * FROM Medico;

-- Ayuda
SELECT * FROM Ayuda;

-- Atendido_por
SELECT * FROM Atendido_por;

-- Receta_medica
SELECT * FROM Receta_medica;

-- Medicamento
SELECT * FROM Medicamento;

-- Equipo_medico
SELECT * FROM Equipo_medico;

-- Unidad_psiquiatria
SELECT * FROM Unidad_psiquiatria;

-- Unidad_respiratoria
SELECT * FROM Unidad_respiratoria;

-- Unidad_cardiaca
SELECT * FROM Unidad_cardiaca;

-- Utiliza
SELECT * FROM Utiliza;