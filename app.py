import os
import psycopg2
import random
from flask import Flask, render_template, request, url_for, redirect, jsonify

app = Flask(__name__)

def get_db_connection():
    try:
        conn = psycopg2.connect(
            host='localhost',
            database="hospitalxyz",
            user="",
            password=""
        )
        return conn
    except psycopg2.Error as e:
        print(f"Error connecting to the database: {e}")
        return None
    except Exception as e:
        print(f"Unknown error: {e}")
        return None

@app.route('/')
def index():
    try:
        conn = get_db_connection()
        if conn is None:
            return "Error connecting to the database."
        
        cur = conn.cursor()
        cur.execute('SELECT * FROM Paciente;')
        patients = cur.fetchall()
        cur.close()
        conn.close()
        return render_template('index.html', patients=patients)

    except Exception as e:
        return f"An error occurred: {e}"

@app.route('/create/cita/', methods=('GET', 'POST'))
def create():
    try:
        if request.method == 'POST':
            dni = request.form['dni']
            fecha_cita = request.form['fecha']
            motivo = request.form['motivo']

            conn = get_db_connection()
            if conn is None:
                return "Error connecting to the database."

            cur = conn.cursor()

            # Obtener el ID del paciente a partir del dni
            cur.execute('SELECT DNI FROM Paciente WHERE DNI = %s', (dni,))
            paciente_id = cur.fetchone()

            if not paciente_id:
                return "No se encontró un paciente con ese DNI."


            cur.execute('INSERT INTO Cita (Fecha, Motivo, DNI_paciente) VALUES (%s, %s, %s)',
                        (fecha_cita, motivo, dni))
            conn.commit()
            cur.close()
            conn.close()

            return redirect(url_for('index'))

        return render_template('create.html')

    except Exception as e:
        return f"An error occurred: {e}"
    


    
    

@app.route('/delete/', methods=('GET', 'POST'))
def delete():
    try:
        if request.method == 'POST':
            codigo = int(request.form['codigo'])

            conn = get_db_connection()
            if conn is None:
                return "Error connecting to the database."

            cur = conn.cursor()
            cur.execute('DELETE FROM Cita WHERE Codigo = %s', [codigo])
            conn.commit()
            cur.close()
            conn.close()
            return redirect(url_for('index'))

        return render_template('delete.html')

    except Exception as e:
        return f"An error occurred: {e}"

@app.route('/update/', methods=['GET', 'POST'])
def update():
    try:
        if request.method == 'POST':
            codigo = int(request.form['codigo'])
            motivo = request.form['motivo']
            fecha_cita = request.form['fecha_cita']

            conn = get_db_connection()
            if conn is None:
                return "Error connecting to the database."

            cur = conn.cursor()
            cur.execute('UPDATE Cita SET Motivo = %s, Fecha = %s WHERE Codigo = %s',
                        (motivo, fecha_cita, codigo))
            conn.commit()
            cur.close()
            conn.close()
            return redirect(url_for('index'))

        return render_template('update.html')

    except Exception as e:
        return f"An error occurred: {e}"

@app.route('/about/')
def about():
    return render_template('about.html')

if __name__ == '__main__':
    app.run(debug=True)
