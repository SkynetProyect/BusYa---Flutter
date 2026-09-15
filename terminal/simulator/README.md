# Bus simulator

Simulates every bus in the Supabase `buses` table moving over its route's `encoded_polyline`. Each cycle it:

1. Advances the bus position.
2. Changes an internal passenger count.
3. Updates `latitud_actual`, `longitud_actual`, `nivel_ocupacion`, and `ultima_actualizacion_gps` in `buses`.
4. Inserts a row into `telemetria_gps_logs` with `id_bus`, `coordenadas.latitud`, `coordenadas.longitud`, and `timestamp`.

The Flutter models currently persist an occupancy level rather than an occupant count, so the count is kept in memory and the currently valid database level (`VERDE`) is sent to Supabase.

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

Run continuously against Supabase every 10 seconds:

```bash
python -m bus_simulator --interval 10
```

Useful options are `--steps 10`, `--once`, `--bus-id 3`, and `--seed 42`.

Routes without a usable `encoded_polyline`, and buses whose `id_ruta` points to such a route, are reported and skipped.

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