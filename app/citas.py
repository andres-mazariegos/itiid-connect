"""ITIID Connect · CRUD de citas en la terminal.

No es una aplicación completa (el proyecto es la base de datos); es un
cliente sencillo para probar que la base funciona desde un programa:

  C  Agendar una cita       -> llama a la función registrar_cita (con transacción)
  R  Ver citas / horarios   -> consulta las vistas
  U  Cambiar estado         -> UPDATE
  D  Eliminar una cita      -> DELETE

Uso:  python app/citas.py
"""
import psycopg

from conexion import conectar


def imprimir_tabla(columnas, filas):
    if not filas:
        print("  (sin resultados)\n")
        return
    anchos = [max(len(str(c)), *(len(str(f[i] if f[i] is not None else "")) for f in filas))
              for i, c in enumerate(columnas)]
    print("  " + " | ".join(str(c).ljust(a) for c, a in zip(columnas, anchos)))
    print("  " + "-+-".join("-" * a for a in anchos))
    for f in filas:
        print("  " + " | ".join(str(v if v is not None else "").ljust(a) for v, a in zip(f, anchos)))
    print()


def consultar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        cols = [d.name for d in cur.description]
        filas = cur.fetchall()
    conn.commit()
    return cols, filas


def ver_citas(conn):
    filtro = input("Matrícula (Enter para ver todas): ").strip()
    sql = "SELECT id_cita, fecha, horario, docente, estudiante, estado FROM vw_citas"
    if filtro:
        cols, filas = consultar(conn, sql + " WHERE matricula = %s ORDER BY fecha, horario", (filtro,))
    else:
        cols, filas = consultar(conn, sql + " ORDER BY fecha, horario")
    imprimir_tabla(cols, filas)


def ver_horarios(conn):
    cols, filas = consultar(conn, "SELECT id_docente, docente, dia, horario, materia, grupo "
                                  "FROM vw_carga_docente ORDER BY id_docente, num_dia, hora_inicio")
    imprimir_tabla(cols, filas)


def agendar(conn):
    print("Datos de la cita (la hora va como 13:00):")
    matricula = input("  Matrícula: ").strip()
    id_docente = input("  Id del docente: ").strip()
    fecha = input("  Fecha (AAAA-MM-DD): ").strip()
    inicio = input("  Hora de inicio: ").strip()
    fin = input("  Hora de fin: ").strip()
    motivo = input("  Motivo: ").strip()
    try:
        with conn.transaction():                       # BEGIN ... COMMIT / ROLLBACK
            fila = conn.execute("SELECT registrar_cita(%s, %s, %s, %s, %s, %s)",
                                (matricula, id_docente, fecha, inicio, fin, motivo)).fetchone()
        print(f"\n  Cita registrada con el número {fila[0]}.\n")
    except psycopg.Error as e:                         # la transacción ya se deshizo sola
        print(f"\n  No se registró: {e.diag.message_primary}\n")


def cambiar_estado(conn):
    id_cita = input("Número de cita: ").strip()
    estado = input("Nuevo estado (pendiente/confirmada/cancelada/atendida): ").strip().lower()
    nota = input("Observaciones (opcional): ").strip() or None
    try:
        with conn.transaction():
            cur = conn.execute("UPDATE citas SET estado = %s, observaciones = COALESCE(%s, observaciones) "
                               "WHERE id_cita = %s", (estado, nota, id_cita))
        print("\n  Listo.\n" if cur.rowcount else "\n  No existe esa cita (o no es tuya).\n")
    except psycopg.Error as e:
        print(f"\n  No se pudo: {e.diag.message_primary}\n")


def eliminar(conn):
    id_cita = input("Número de cita a eliminar: ").strip()
    if input(f"¿Seguro que quieres borrar la cita {id_cita}? (s/n): ").strip().lower() != "s":
        print("\n  Cancelado.\n")
        return
    try:
        with conn.transaction():
            cur = conn.execute("DELETE FROM citas WHERE id_cita = %s", (id_cita,))
        print("\n  Cita eliminada.\n" if cur.rowcount else "\n  No existe esa cita.\n")
    except psycopg.Error as e:
        print(f"\n  No se pudo: {e.diag.message_primary}\n")


MENU = {
    "1": ("Ver citas", ver_citas),
    "2": ("Ver horarios de docentes", ver_horarios),
    "3": ("Agendar cita", agendar),
    "4": ("Cambiar estado de una cita", cambiar_estado),
    "5": ("Eliminar cita", eliminar),
}


def main():
    conn = conectar()
    usuario = conn.execute("SELECT current_user").fetchone()[0]
    conn.commit()
    print(f"\nITIID Connect · conectado como {usuario}\n")
    while True:
        for k, (texto, _) in MENU.items():
            print(f"  {k}. {texto}")
        print("  0. Salir")
        opcion = input("\nOpción: ").strip()
        if opcion == "0":
            break
        if opcion in MENU:
            print()
            try:
                MENU[opcion][1](conn)
            except psycopg.errors.InsufficientPrivilege:
                conn.rollback()
                print("\n  Tu usuario no tiene permiso para eso.\n")
        else:
            print("  Opción no válida.\n")
    conn.close()


if __name__ == "__main__":
    main()
