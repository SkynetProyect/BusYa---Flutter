from __future__ import annotations

from typing import Any

from supabase import Client, create_client


class SupabaseRepository:
    def __init__(self, url: str, key: str) -> None:
        self.client: Client = create_client(url, key)

    def load_rows(self) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
        buses = self.client.table("buses").select("*").execute().data
        routes = self.client.table("rutas").select("*").execute().data
        return list(buses), list(routes)

    def publish(self, report: dict[str, Any], timestamp: str) -> None:
        self.client.table("buses").update(
            {
                "latitud_actual": report["latitud"],
                "longitud_actual": report["longitud"],
                "nivel_ocupacion": report["nivel_ocupacion"],
                "ultima_actualizacion_gps": timestamp,
            }
        ).eq("id", report["bus_id"]).execute()
        self.client.table("telemetria_gps_logs").insert(
            {
                "id_bus": report["bus_id"],
                "coordenadas": {
                    "latitud": report["latitud"],
                    "longitud": report["longitud"],
                },
                "timestamp": timestamp,
            }
        ).execute()