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

Procedimiento Almacenado para Descifrar el DNI de Pacientes
Se ha creado un procedimiento almacenado para facilitar la recuperación del DNI descifrado de los pacientes. Esto permite a los usuarios autorizados obtener la información del paciente de manera segura.

```sql
-- Procedimiento almacenado para descifrar el DNI de un paciente
CREATE PROCEDURE DescifrarDNI()
BEGIN
    SELECT NombreCompleto, AES_DECRYPT(DNI_Cifrado, 'clave_secreta') AS DNI
    FROM Pacientes;
END;
```

Consideraciones de Seguridad
Es importante destacar que la implementación del cifrado y descifrado del DNI tiene como objetivo proteger la confidencialidad de la información del paciente. Se debe gestionar de manera segura la clave secreta utilizada en el proceso de cifrado para garantizar la integridad del sistema.

