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
    # Objetivo de ocupantes hacia el cual nos movemos suavemente
    target_occupants: int
    # Acumulador fraccional para calcular pasos de cambio subenteros por tick
    step_residual: float = 0.0
    # Si se define, sesga los objetivos hacia este ratio [0..1] (ej. 0.75)
    bias_ratio: float | None = None

    @classmethod
    def from_row(cls, row: dict[str, Any], route: Route, random: Random) -> "SimulatedBus":
        capacity = max(int(row.get("capacidad_maxima") or 1), 1)
        bus_id = int(row["id"])
        initial_occupants = random.randint(0, capacity)
        initial_target = random.randint(0, capacity)
        return cls(
            id=bus_id,
            plate=str(row.get("placa", bus_id)),
            capacity=capacity,
            route=route,
            progress=(bus_id % 10) / 10,
            occupants=initial_occupants,
            target_occupants=initial_target,
            step_residual=0.0,
            bias_ratio=None,
        )

    def advance(self, interval_seconds: float, random: Random) -> dict[str, Any]:
        duration = self.route.duration_seconds or max(len(self.route.points) * 30, 60)
        self.progress = (self.progress + interval_seconds / duration) % 1.0
        # Suavizar los cambios de ocupacion: avanzamos gradualmente hacia un objetivo.
        # Definimos un paso maximo proporcional a la capacidad y al tiempo real transcurrido.
        # ~1% de la capacidad por segundo. Se usa acumulador para intervalos cortos (p.ej. 0.1s).
        desired_step = 0.01 * self.capacity * interval_seconds
        total_step = desired_step + self.step_residual
        max_step = int(total_step)
        self.step_residual = total_step - max_step

        # Si ya estamos cerca del objetivo, elegir uno nuevo en todo el rango para
        # recorrer distintos niveles a lo largo del tiempo.
        if abs(self.occupants - self.target_occupants) <= max_step:
            # Elige un nuevo objetivo. Si hay sesgo, mantente cerca del sesgo con pequeña variación.
            if self.bias_ratio is not None:
                # Variación de ±7% de la capacidad alrededor del sesgo.
                spread = max(1, round(0.07 * self.capacity))
                center = int(round(self.bias_ratio * self.capacity))
                low = max(0, center - spread)
                high = min(self.capacity, center + spread)
                self.target_occupants = random.randint(low, high)
            else:
                # Sin sesgo: objetivo aleatorio pero con diferencia mínima del 10% de la capacidad
                attempts = 0
                min_diff = max(1, round(0.10 * self.capacity))
                new_target = self.target_occupants
                while attempts < 5 and abs(new_target - self.occupants) < min_diff:
                    new_target = random.randint(0, self.capacity)
                    attempts += 1
                self.target_occupants = new_target

        # Avanzar hacia el objetivo con paso limitado
        delta = self.target_occupants - self.occupants
        if max_step > 0:
            if delta > 0:
                self.occupants = min(self.capacity, self.occupants + min(max_step, delta))
            elif delta < 0:
                self.occupants = max(0, self.occupants - min(max_step, -delta))
        # si delta == 0, nos mantenemos

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
    """Devuelve la ocupación como etiqueta de color según el ratio."""
    if capacity <= 0:
        return "VERDE"
    ratio = max(0.0, min(1.0, occupants / float(capacity)))
    if ratio > 0.8:
        return "ROJO"
    elif ratio > 0.5:
        return "NARANJA"
    else:
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

    # Asignar sesgos de ocupación: ~30% cerca de 75%, ~40% cerca de 60%.
    if buses:
        total = len(buses)
        count_75 = max(0, round(0.30 * total))
        count_60 = max(0, round(0.40 * total))
        indices = list(range(total))
        random.shuffle(indices)
        grp75 = set(indices[:count_75])
        grp60 = set(indices[count_75:count_75 + count_60])
        for i, bus in enumerate(buses):
            if i in grp75:
                bus.bias_ratio = 0.75
                center = int(round(0.75 * bus.capacity))
                spread = max(1, round(0.07 * bus.capacity))
                bus.occupants = random.randint(max(0, center - spread), min(bus.capacity, center + spread))
                bus.target_occupants = bus.occupants
            elif i in grp60:
                bus.bias_ratio = 0.60
                center = int(round(0.60 * bus.capacity))
                spread = max(1, round(0.07 * bus.capacity))
                bus.occupants = random.randint(max(0, center - spread), min(bus.capacity, center + spread))
                bus.target_occupants = bus.occupants
    return buses, warnings