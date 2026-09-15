from __future__ import annotations

from dataclasses import dataclass
from random import Random
from typing import Any, Iterable

import polyline


@dataclass(frozen=True)
class Route:
    id: int
    name: str
    points: tuple[tuple[float, float], ...]
    duration_seconds: int | None = None

    @classmethod
    def from_row(cls, row: dict[str, Any]) -> "Route | None":
        encoded = row.get("encoded_polyline")
        if not encoded:
            return None
        points = tuple(polyline.decode(encoded))
        if len(points) < 2:
            return None
        duration = row.get("duracion_segundos")
        return cls(
            id=int(row["id"]),
            name=str(row.get("nombre", row["id"])),
            points=points,
            duration_seconds=int(duration) if duration else None,
        )

    def position_at(self, progress: float) -> tuple[float, float]:
        """Interpolate a point over the route and wrap at the destination."""
        bounded = progress % 1.0
        scaled = bounded * (len(self.points) - 1)
        index = min(int(scaled), len(self.points) - 2)
        fraction = scaled - index
        start_lat, start_lng = self.points[index]
        end_lat, end_lng = self.points[index + 1]
        return (
            start_lat + (end_lat - start_lat) * fraction,
            start_lng + (end_lng - start_lng) * fraction,
        )


@dataclass
class SimulatedBus:
    id: int
    plate: str
    capacity: int
    route: Route
    progress: float
    occupants: int

    @classmethod
    def from_row(cls, row: dict[str, Any], route: Route, random: Random) -> "SimulatedBus":
        capacity = max(int(row.get("capacidad_maxima") or 1), 1)
        bus_id = int(row["id"])
        return cls(
            id=bus_id,
            plate=str(row.get("placa", bus_id)),
            capacity=capacity,
            route=route,
            progress=(bus_id % 10) / 10,
            occupants=random.randint(0, capacity),
        )

    def advance(self, interval_seconds: float, random: Random) -> dict[str, Any]:
        duration = self.route.duration_seconds or max(len(self.route.points) * 30, 60)
        self.progress = (self.progress + interval_seconds / duration) % 1.0
        change = random.choice((-3, -2, -1, 0, 1, 2, 3))
        self.occupants = max(0, min(self.capacity, self.occupants + change))
        latitude, longitude = self.route.position_at(self.progress)
        return {
            "bus_id": self.id,
            "placa": self.plate,
            "latitud": round(latitude, 6),
            "longitud": round(longitude, 6),
            "ocupantes": self.occupants,
            "nivel_ocupacion": occupancy_level(self.occupants, self.capacity),
            "id_ruta": self.route.id,
            "ruta": self.route.name,
        }


def occupancy_level(occupants: int, capacity: int) -> str:
    # Supabase actualmente restringe buses.nivel_ocupacion al valor VERDE.
    return "VERDE"


def build_buses(
    bus_rows: Iterable[dict[str, Any]],
    route_rows: Iterable[dict[str, Any]],
    random: Random,
) -> tuple[list[SimulatedBus], list[str]]:
    routes = {}
    warnings = []
    for row in route_rows:
        route = Route.from_row(row)
        if route is None:
            warnings.append(f"Ruta {row.get('id')} no tiene un encoded_polyline utilizable")
            continue
        routes[route.id] = route

    buses = []
    for row in bus_rows:
        route_id = row.get("id_ruta")
        route = routes.get(route_id)
        if route is None:
            warnings.append(f"Bus {row.get('id')} omitido: ruta {route_id} sin geometria")
            continue
        buses.append(SimulatedBus.from_row(row, route, random))
    return buses, warnings