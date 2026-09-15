import unittest
from random import Random

from bus_simulator.simulation import Route, build_buses, occupancy_level


class SimulationTests(unittest.TestCase):
    def test_position_wraps_and_interpolates(self):
        route = Route(id=1, name="test", points=((0.0, 0.0), (10.0, 20.0)), duration_seconds=100)
        self.assertEqual(route.position_at(0.25), (2.5, 5.0))
        self.assertEqual(route.position_at(1.25), (2.5, 5.0))

    def test_build_buses_ignores_routes_without_geometry(self):
        buses, warnings = build_buses(
            [{"id": 7, "placa": "ABC", "capacidad_maxima": 30, "id_ruta": 9}],
            [{"id": 9, "nombre": "missing", "encoded_polyline": None}],
            Random(1),
        )
        self.assertEqual(buses, [])
        self.assertTrue(warnings)

    def test_advance_creates_supabase_compatible_report(self):
        buses, _ = build_buses(
            [{"id": 1, "placa": "ABC", "capacidad_maxima": 30, "id_ruta": 9}],
            [{"id": 9, "nombre": "test", "encoded_polyline": "_p~iF~ps|U_ulLnnqC_mqNvxq@", "duracion_segundos": 100}],
            Random(1),
        )
        report = buses[0].advance(10, Random(2))
        self.assertEqual(set(("bus_id", "latitud", "longitud", "nivel_ocupacion")), set(report) & {"bus_id", "latitud", "longitud", "nivel_ocupacion"})
        self.assertEqual(report["nivel_ocupacion"], "VERDE")

    def test_occupancy_levels(self):
        self.assertEqual(occupancy_level(1, 10), "VERDE")
        self.assertEqual(occupancy_level(5, 10), "VERDE")
        self.assertEqual(occupancy_level(9, 10), "VERDE")


if __name__ == "__main__":
    unittest.main()