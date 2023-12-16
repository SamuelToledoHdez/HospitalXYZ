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
        cur.execute('SELECT * FROM pacientes;')
        books = cur.fetchall()
        cur.close()
        conn.close()
        return render_template('index.html', books=books)

    except Exception as e:
        return f"An error occurred: {e}"

@app.route('/create/', methods=('GET', 'POST'))
def create():
    try:
        if request.method == 'POST':
            dni_cifrado = request.form['dni']
            fecha_cita = request.form['fecha_cita']
            motivo = request.form['motivo']

            conn = get_db_connection()
            if conn is None:
                return "Error connecting to the database."

            cur = conn.cursor()

            # Obtener el ID del paciente a partir del DNI_Cifrado
            cur.execute('SELECT Paciente_ID FROM Pacientes WHERE dni = %s', (dni_cifrado,))
            paciente_id = cur.fetchone()

            if not paciente_id:
                return "No se encontró un paciente con ese DNI."

            codigo_cita = random.randint(1, 100)
            cur.execute('INSERT INTO Citas (CodigoCita, Fecha, Motivo, Paciente_ID) VALUES (%s, %s, %s, %s)',
                        (codigo_cita, fecha_cita, motivo, paciente_id[0]))
            conn.commit()
            cur.close()
            conn.close()

            return redirect(url_for('index'))

        return render_template('create_cita.html')

    except Exception as e:
        return f"An error occurred: {e}"

@app.route('/delete/', methods=('GET', 'POST'))
def delete():
    try:
        if request.method == 'POST':
            id = int(request.form['id'])

            conn = get_db_connection()
            if conn is None:
                return "Error connecting to the database."

            cur = conn.cursor()
            cur.execute('DELETE FROM books WHERE id = %s', [id])
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
            id = int(request.form['id'])
            title = request.form['title']
            author = request.form['author']
            pages_num = int(request.form['pages_num'])
            review = request.form['review']

            conn = get_db_connection()
            if conn is None:
                return "Error connecting to the database."

            cur = conn.cursor()
            cur.execute('UPDATE books SET title = %s, author = %s, pages_num = %s, review = %s WHERE id = %s',
                        (title, author, pages_num, review, id))
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
