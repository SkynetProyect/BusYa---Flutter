from __future__ import annotations

import argparse
import os
import time
from datetime import datetime, timezone
from random import Random
from typing import Any

from dotenv import load_dotenv

from .simulation import build_buses


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Simula buses y publica GPS en Supabase")
    parser.add_argument("--interval", type=float, default=10, help="Segundos entre reportes (antes de aplicar velocidad)")
    parser.add_argument(
        "--rate-multiplier",
        type=float,
        default=3.0,
        help="Multiplicador de velocidad: >1.0 envia mas rapido (ej. 3.0 = 3x)",
    )
    parser.add_argument(
        "--hz",
        type=float,
        default=None,
        help="Frecuencia de publicaciones por segundo (ej. 10 = 10 Hz). Tiene prioridad sobre interval/multiplier",
    )
    parser.add_argument("--steps", type=int, help="Cantidad de ciclos; por defecto, infinito")
    parser.add_argument("--once", action="store_true", help="Publica un ciclo y termina")
    parser.add_argument("--dry-run", action="store_true", help="Simula sin leer ni escribir Supabase")
    parser.add_argument("--seed", type=int, help="Semilla para reproducir los cambios de ocupacion")
    parser.add_argument("--bus-id", type=int, action="append", dest="bus_ids", help="Limita la simulacion a un bus")
    return parser.parse_args()


def demo_rows() -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    return (
        [{"id": 1, "placa": "SIM-001", "capacidad_maxima": 40, "id_ruta": 1}],
        [{"id": 1, "nombre": "Ruta demo", "encoded_polyline": "_p~iF~ps|U_ulLnnqC_mqNvxq@", "duracion_segundos": 120}],
    )

def main() -> None:
    args = parse_args()
    random = Random(args.seed)
    if args.dry_run:
        bus_rows, route_rows = demo_rows()
        repository = None
    else:
        load_dotenv()
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_ANON_KEY")
        if not url or not key:
            raise SystemExit("Faltan SUPABASE_URL y SUPABASE_KEY en el entorno o archivo .env")
        from .supabase_repository import SupabaseRepository

        repository = SupabaseRepository(url, key)
        bus_rows, route_rows = repository.load_rows()

    if args.bus_ids:
        bus_rows = [row for row in bus_rows if row.get("id") in args.bus_ids]
    buses, warnings = build_buses(bus_rows, route_rows, random)
    for warning in warnings:
        print(f"Aviso: {warning}")
    if not buses:
        raise SystemExit("No hay buses simulables: revisa id_ruta y encoded_polyline")

    # Calcular intervalo efectivo segun hz (si se provee) o rate multiplier.
    if args.hz and args.hz > 0:
        effective_interval = max(1.0 / args.hz, 0.01)
    else:
        rate = args.rate_multiplier if args.rate_multiplier and args.rate_multiplier > 0 else 1.0
        effective_interval = max(args.interval / rate, 0.01)

    steps = 1 if args.once else args.steps
    completed = 0
    last_tick = time.monotonic()
    while steps is None or completed < steps:
        now = time.monotonic()
        real_elapsed = now - last_tick
        last_tick = now

        timestamp = datetime.now(timezone.utc).isoformat()
        for bus in buses:
            report = bus.advance(real_elapsed, random)
            if repository is not None:
                repository.publish(report, timestamp)
            print(
                f"[{timestamp}] bus={report['bus_id']} placa={report['placa']} "
                f"ruta={report['id_ruta']} lat={report['latitud']} lon={report['longitud']} "
                f"ocupantes={report['ocupantes']}/{bus.capacity} nivel={report['nivel_ocupacion']}"
            )
        completed += 1
        if steps is None or completed < steps:
            time.sleep(effective_interval)


if __name__ == "__main__":
    main()