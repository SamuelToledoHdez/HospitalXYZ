# README - Sistema de Base de Datos para Hospital XYZ

## Descripción del Sistema

Este repositorio contiene la estructura básica de una base de datos para el sistema de información de un hospital llamado "Hospital XYZ". La base de datos está diseñada para gestionar información relacionada con pacientes, citas médicas, médicos, enfermeros, recetas médicas, medicamentos, equipos médicos y unidades médicas.

## Triggers y Procedimientos Almacenados

### Trigger para Cifrado del DNI de Pacientes

Cuando se inserta un nuevo paciente en la tabla `Pacientes`, se utiliza un trigger para cifrar automáticamente su DNI antes de almacenarlo en la base de datos. Esto ayuda a garantizar la confidencialidad de la información del paciente.

```sql
-- Trigger para cifrar el DNI al insertar un nuevo paciente
CREATE TRIGGER CifrarDNITrigger BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    SET NEW.DNI_Cifrado = AES_ENCRYPT(NEW.DNI, 'clave_secreta');
END;
```

### Procedimiento Almacenado para Descifrar el DNI de Pacientes

Se ha creado un procedimiento almacenado para facilitar la recuperación del DNI descifrado de los pacientes. Esto permite a los usuarios autorizados obtener la información del paciente de manera segura.

```sql
-- Procedimiento almacenado para descifrar el DNI de un paciente
CREATE PROCEDURE DescifrarDNI()
BEGIN
    SELECT NombreCompleto, AES_DECRYPT(DNI_Cifrado, 'clave_secreta') AS DNI
    FROM Pacientes;
END;
```

### Trigger para fecha de las citas

Además existe un trigger para poder descartar todas las citas que no han sido creadas con una fecha válida, es decir una fecha menor al día actual.

```sql
-- Crear la función y el trigger para comprobar la fecha de la cita
CREATE OR REPLACE FUNCTION VerificarFechaCita()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Fecha <= CURRENT_DATE THEN
        RAISE EXCEPTION 'La fecha de la cita debe ser posterior a hoy';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER VerificarFechaCitaTrigger
BEFORE INSERT OR UPDATE ON "cita"
FOR EACH ROW
EXECUTE FUNCTION VerificarFechaCita();
```

## Consideraciones de Seguridad

Es importante destacar que la implementación del cifrado y descifrado del DNI tiene como objetivo proteger la confidencialidad de la información del paciente. Se debe gestionar de manera segura la clave secreta utilizada en el proceso de cifrado para garantizar la integridad del sistema.

