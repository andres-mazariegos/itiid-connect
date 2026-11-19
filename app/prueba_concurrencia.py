"""Caso de complejidad: dos estudiantes intentan agendar con el MISMO
docente a la MISMA hora, al mismo tiempo (dos conexiones distintas).

Resultado esperado: uno queda registrado y el otro recibe
"Conflicto: el docente ya tiene una cita en ese horario".

Uso:  python app/prueba_concurrencia.py
"""
import threading
import time

import psycopg

from conexion import conectar

salida = threading.Lock()
arranque = threading.Barrier(2)


def intentar(matricula, espera):
    conn = conectar()
    arranque.wait()                     # los dos salen al mismo tiempo
    inicio = time.time()
    try:
        with conn.transaction():
            fila = conn.execute(
                "SELECT registrar_cita(%s, 2, proximo(5), '16:00', '16:30', 'Prueba de concurrencia')",
                (matricula,)).fetchone()
            time.sleep(espera)          # simulamos que esta transacción tarda en terminar
        with salida:
            print(f"[{matricula}] REGISTRADA cita {fila[0]}  ({time.time() - inicio:.1f} s)")
    except psycopg.Error as e:
        with salida:
            print(f"[{matricula}] RECHAZADA: {e.diag.message_primary}  ({time.time() - inicio:.1f} s)")
    finally:
        conn.close()


if __name__ == "__main__":
    # Limpia la cita de una corrida anterior para poder repetir la prueba
    conn = conectar()
    conn.execute("DELETE FROM citas WHERE motivo = 'Prueba de concurrencia'")
    conn.commit()
    conn.close()

    print("Dos estudiantes piden al docente 2, el próximo viernes de 16:00 a 16:30...\n")
    a = threading.Thread(target=intentar, args=("243702", 2))
    b = threading.Thread(target=intentar, args=("243691", 2))
    a.start(); b.start()
    a.join(); b.join()
    print("\nEl que llegó segundo esperó a que el primero terminara (FOR UPDATE) y,")
    print("al revisar de nuevo, encontró el horario ocupado.")
