from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from supabase import Client, create_client


COMPANIES: dict[str, tuple[str, ...]] = {
    "Coonatra": (
        "242 - Floresta / San Juan",
        "243 - Floresta / San Juan",
        "300 - Circular Coonatra",
        "301 - Circular Coonatra",
        "303 - Circular Coonatra",
    ),
    "Conducciones América": (
        "200",
        "201",
        "202",
        "203",
        "204",
    ),
    "Rápido San Cristóbal": (
        "255",
        "255 V1",
        "255 V4",
        "255 V5",
    ),
    "Conducciones Palenque Robledal": (
        "250A - La Campiña / Pajarito",
        "250A Ramal - La Huerta / La Campiña / Moravia",
        "250 II - Las Hamacas / Estación La Aurora",
        "250 III - Estación La Aurora / La Campiña / Tulipanes / La Huerta",
        "251 - Santa Margarita / Carretera al Mar",
    ),
}

MIN_FARE = 2700.0
MAX_FARE = 3400.0
BUSES_PER_ROUTE = 3

ROUTE_POLYLINES: dict[str, str] = {
    "242": "_xhe@nuqlMwQwcAfw@w|A~iAo}@~p@_cBnKgw@wj@n}@g^fpA_jAfiBwj@v|AvQnd@",
    "243": "_xhe@nuqlMod@wcAvj@w|Av|Ao}@n}@_cBf^ovAwj@~iAgpAnoBgpA~{BnK~bB",
    "300": "odie@nuqlMfpA_cBv|A_|B~p@_|BgpA_|B_|B~p@w|AfiBf^f{Cvj@naD",
    "301": "odie@nuqlM~p@_cBnoBw|Avj@_|Bw|A_|B_|Bf^w|A~{BvQf{CnvAfbC",
    "303": "odie@nuqlM~p@oaDv|A_|Bn}@_|B_|Bw|Ag{Cv|Ao}@f{Cn}@f{C~iA~bB",
    "200": "_~`e@~`klMgw@~p@o}@o}@wQw|A~p@w|Ao}@_jAw|Avj@o}@v|Avj@~{BnoBn}@~tC_q@",
    "201": "_~`e@~`klMgw@noBo}@o}@o}@_|Bv|Aw|Af^w|A_|Bg^_|Bn}@wj@~{BnhC~{BnsEwQ",
    "202": "w_ge@fyllMfw@wcA~p@w|Af^w|Ao}@o}@w|Af^o}@v|AnK~{BvcAvcA",
    "203": "_~`e@~`klMod@noB_q@w|A_q@_|B~p@w|Ao}@_jA_|Bvj@_jA~{BfiB~{BvrFwQ",
    "204": "_~`e@~`klMgw@fpAo}@w|Ao}@_|Bv|Aw|A_|Bwj@_|B~iAg^~{B~{B~{BvrF_q@",
    "255": "wjie@~sslMwQwcA~Wo}@~p@w|A~iAo}@~p@w|Af^w|A",
    "255 V1": "wjie@~sslMod@wcAg^o}@n}@w|Av|Ao}@v|Aw|Af^w|A",
    "255 V4": "wjie@~sslMfw@wcAn}@w|An}@w|Af^w|Avj@w|Awj@w|A",
    "255 V5": "wjie@~sslMod@_cBg^w|An}@w|Av|Aw|Av|Aw|Af^w|A",
    "250A": "w|je@~wvlMvj@oKvQwj@nKwj@wj@wcA_q@g^o}@o}@f^~{B~p@nhC",
    "250A Ramal": "w|je@vjwlMwQo}@vQo}@fw@o}@~p@w|AnK_|BgE_uCgw@nvAgw@~{B?vvI",
    "250 II": "ovje@~wvlM~WoKf^_XnK_Xf^oK~Wg^",
    "250 III": "wqhe@nrulMwQ_Xod@oK_XnKfEnd@?vj@",
    "251": "_|ke@vtrlMnKfw@f^n}@vj@n}@~p@n}@vj@n}@~p@n}@",
}


def route_code(route_name: str) -> str:
    return route_name.split(" - ", 1)[0]


def repository_from_env() -> Client:
    project_root = Path(__file__).resolve().parents[3]
    load_dotenv(project_root / ".env")
    load_dotenv()
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_ANON_KEY")
    if not url or not key:
        raise SystemExit("Faltan SUPABASE_URL y una clave Supabase en el entorno")
    return create_client(url, key)


def seed(client: Client, dry_run: bool = False) -> tuple[int, int, int, int]:
    existing_companies = {
        row["nombre"]: row["id"]
        for row in client.table("empresas").select("id,nombre").execute().data
    }
    route_rows = client.table("rutas").select("id,id_empresa,nombre,precio_pasaje,encoded_polyline").execute().data
    existing_routes = {(row["id_empresa"], row["nombre"]): row for row in route_rows}
    bus_rows = client.table("buses").select("id,id_ruta,placa").execute().data
    buses_by_route: dict[int, list[dict[str, Any]]] = {}
    for row in bus_rows:
        buses_by_route.setdefault(row["id_ruta"], []).append(row)
    companies_added = 0
    routes_added = 0
    fares_updated = 0
    buses_added = 0

    for company_name, route_names in COMPANIES.items():
        company_id = existing_companies.get(company_name)
        if company_id is None:
            if dry_run:
                company_id = f"new:{company_name}"
            else:
                company_id = (
                    client.table("empresas")
                    .insert({"nombre": company_name})
                    .select("id")
                    .execute()
                    .data[0]["id"]
                )
            existing_companies[company_name] = company_id
            companies_added += 1
            print(f"Empresa {'preparada' if dry_run else 'creada'}: {company_name}")
        else:
            print(f"Empresa existente: {company_name}")

        for route_name in route_names:
            route_key = (company_id, route_name)
            encoded_polyline = ROUTE_POLYLINES.get(route_code(route_name))
            route = existing_routes.get(route_key)
            if route is None:
                payload: dict[str, Any] = {
                    "id_empresa": company_id,
                    "nombre": route_name,
                    "precio_pasaje": MIN_FARE,
                    "encoded_polyline": encoded_polyline,
                    "distancia_metros": None,
                    "duracion_segundos": None,
                }
                if dry_run:
                    route = {"id": f"new:{company_name}:{route_name}", **payload}
                else:
                    route = (
                        client.table("rutas")
                        .insert(payload)
                        .select("id,id_empresa,nombre,precio_pasaje,encoded_polyline")
                        .execute()
                        .data[0]
                    )
                existing_routes[route_key] = route
                routes_added += 1
                print(f"  Ruta {'preparada' if dry_run else 'creada'}: {route_name}")
            else:
                print(f"  Ruta existente: {route_name}")
                if encoded_polyline and route.get("encoded_polyline") != encoded_polyline:
                    if not dry_run:
                        client.table("rutas").update({"encoded_polyline": encoded_polyline}).eq("id", route["id"]).execute()
                    route["encoded_polyline"] = encoded_polyline
                    print(f"    Polyline {'preparada' if dry_run else 'actualizada'}")

            fare = float(route.get("precio_pasaje") or 0)
            if fare < MIN_FARE or fare > MAX_FARE:
                new_fare = MIN_FARE + (abs(hash(route_name)) % int(MAX_FARE - MIN_FARE + 1))
                if not dry_run:
                    client.table("rutas").update({"precio_pasaje": new_fare}).eq("id", route["id"]).execute()
                fares_updated += 1
                print(f"    Precio {'preparado' if dry_run else 'actualizado'}: {new_fare:.0f}")

            route_id = route["id"]
            current_buses = buses_by_route.get(route_id, [])
            missing_buses = max(BUSES_PER_ROUTE - len(current_buses), 0)
            for bus_number in range(missing_buses):
                plate = f"SIM-{route_id}-{len(current_buses) + bus_number + 1:02d}"
                bus_payload = {
                    "id_ruta": route_id,
                    "placa": plate,
                    "capacidad_maxima": 40,
                }
                if not dry_run:
                    created_bus = client.table("buses").insert(bus_payload).select("id,id_ruta,placa").execute().data[0]
                    buses_by_route.setdefault(route_id, []).append(created_bus)
                else:
                    buses_by_route.setdefault(route_id, []).append(bus_payload)
                buses_added += 1
                print(f"    Bus {'preparado' if dry_run else 'creado'}: {plate}")

    return companies_added, routes_added, fares_updated, buses_added


def main() -> None:
    parser = argparse.ArgumentParser(description="Carga empresas y rutas base en Supabase")
    parser.add_argument("--dry-run", action="store_true", help="Muestra cambios sin escribir en Supabase")
    args = parser.parse_args()
    client = repository_from_env()
    companies_added, routes_added, fares_updated, buses_added = seed(client, dry_run=args.dry_run)
    action = "preparadas" if args.dry_run else "creadas"
    print(f"Resumen: {companies_added} empresas y {routes_added} rutas {action}.")
    print(f"Precios ajustados: {fares_updated}. Buses {'preparados' if args.dry_run else 'creados'}: {buses_added}.")


if __name__ == "__main__":
    main()