# Bus simulator

Simulates every bus in the Supabase `buses` table moving over its route's `encoded_polyline`. Each cycle it:

1. Advances the bus position.
2. Changes an internal passenger count.
3. Updates `latitud_actual`, `longitud_actual`, `nivel_ocupacion`, and `ultima_actualizacion_gps` in `buses`.
4. Inserts a row into `telemetria_gps_logs` with `id_bus`, `coordenadas.latitud`, `coordenadas.longitud`, and `timestamp`.

The Flutter client consumes an occupancy level string as a ratio. The simulator keeps a per-bus occupant count in memory and publishes `nivel_ocupacion` as a decimal ratio (e.g., `0.50`, `0.75`, `1.00`) computed from occupants vs. capacity. Changes are smoothed to avoid abrupt jumps and trend gradually across the full range.

## Run

```bash
cd simulator
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
cp .env.example .env
```

Set `SUPABASE_URL` and `SUPABASE_KEY` in `.env`. A service-role key is normally required when the simulator writes without a logged-in Supabase user. Keep that key private.

Run one local cycle without Supabase:

```bash
python -m bus_simulator --dry-run --once --seed 42
```

Run continuously against Supabase. You can control speed with either `--hz` or `--rate-multiplier`:

```bash
python -m bus_simulator --interval 10
```

Speed options:

- `--hz 10` sends ~10 updates per second (effective interval ≈ 0.1s).
- `--rate-multiplier 3.0` publishes 3× faster than `--interval`.
- Example: `--interval 9 --rate-multiplier 3` ⇒ effective interval ≈ 3s.

Useful options are `--steps 10`, `--once`, `--bus-id 3`, and `--seed 42`.

Routes without a usable `encoded_polyline`, and buses whose `id_ruta` points to such a route, are reported and skipped.

If your `buses.nivel_ocupacion` column has a restrictive check constraint, update it to allow ratio strings (0.00–1.00):

```sql
ALTER TABLE public.buses
	DROP CONSTRAINT IF EXISTS buses_nivel_ocupacion_check;

ALTER TABLE public.buses
	ADD CONSTRAINT buses_nivel_ocupacion_check
	CHECK (
		nivel_ocupacion ~ '^(0(\\.\\d{1,4})?|1(\\.0{1,4})?)$'
	);
```

## Seed companies and routes

The requested companies and route names can be loaded idempotently:

```bash
python3 -m bus_simulator.seed_data --dry-run
python3 -m bus_simulator.seed_data
```

The seed uses `0.0` as a placeholder fare because no fares were provided, and leaves route geometry, distance, and duration empty. Add official `encoded_polyline` values before assigning these routes to simulated buses.

## Tests

```bash
python -m unittest discover -s tests
```