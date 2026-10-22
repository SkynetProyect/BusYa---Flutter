import polyline from '@mapbox/polyline';

/** PRNG con semilla (mulberry32) + helpers equivalentes a random.randint / shuffle. */
export function createRandom(seed) {
  let a = (seed === undefined || seed === null ? Math.random() * 2 ** 32 : seed) >>> 0;
  const next = () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  return {
    next,
    /** entero inclusivo [lo, hi] como random.randint */
    int: (lo, hi) => lo + Math.floor(next() * (hi - lo + 1)),
    shuffle(arr) {
      for (let i = arr.length - 1; i > 0; i--) {
        const j = Math.floor(next() * (i + 1));
        [arr[i], arr[j]] = [arr[j], arr[i]];
      }
      return arr;
    },
  };
}

export class Route {
  constructor({ id, name, points, durationSeconds = null }) {
    this.id = id;
    this.name = name;
    this.points = points; // [[lat, lng], ...]
    this.durationSeconds = durationSeconds;
  }

  static fromRow(row) {
    const encoded = row.encoded_polyline;
    if (!encoded) return null;
    const points = polyline.decode(encoded);
    if (points.length < 2) return null;
    const duration = row.duracion_segundos;
    return new Route({
      id: Number(row.id),
      name: String(row.nombre ?? row.id),
      points,
      durationSeconds: duration ? Number(duration) : null,
    });
  }

  /** Interpola un punto sobre la ruta y da la vuelta al llegar al destino. */
  positionAt(progress) {
    const bounded = ((progress % 1) + 1) % 1;
    const scaled = bounded * (this.points.length - 1);
    const index = Math.min(Math.floor(scaled), this.points.length - 2);
    const fraction = scaled - index;
    const [startLat, startLng] = this.points[index];
    const [endLat, endLng] = this.points[index + 1];
    return [
      startLat + (endLat - startLat) * fraction,
      startLng + (endLng - startLng) * fraction,
    ];
  }
}

export function occupancyLevel(occupants, capacity) {
  if (capacity <= 0) return 'VERDE';
  const ratio = Math.max(0, Math.min(1, occupants / capacity));
  if (ratio > 0.8) return 'ROJO';
  if (ratio > 0.5) return 'NARANJA';
  return 'VERDE';
}

export class SimulatedBus {
  constructor({ id, plate, capacity, route, progress, occupants, targetOccupants }) {
    this.id = id;
    this.plate = plate;
    this.capacity = capacity;
    this.route = route;
    this.progress = progress;
    this.occupants = occupants;
    this.targetOccupants = targetOccupants;
    this.stepResidual = 0;
    this.biasRatio = null;
  }

  static fromRow(row, route, random) {
    const capacity = Math.max(Number(row.capacidad_maxima) || 1, 1);
    const id = Number(row.id);
    return new SimulatedBus({
      id,
      plate: String(row.placa ?? id),
      capacity,
      route,
      progress: (id % 10) / 10,
      occupants: random.int(0, capacity),
      targetOccupants: random.int(0, capacity),
    });
  }

  advance(intervalSeconds, random) {
    const duration = this.route.durationSeconds || Math.max(this.route.points.length * 30, 60);
    this.progress = (this.progress + intervalSeconds / duration) % 1;

    // ~1% de la capacidad por segundo, con acumulador para intervalos cortos.
    const totalStep = 0.01 * this.capacity * intervalSeconds + this.stepResidual;
    const maxStep = Math.floor(totalStep);
    this.stepResidual = totalStep - maxStep;

    if (Math.abs(this.occupants - this.targetOccupants) <= maxStep) {
      if (this.biasRatio !== null) {
        const spread = Math.max(1, Math.round(0.07 * this.capacity));
        const center = Math.round(this.biasRatio * this.capacity);
        const low = Math.max(0, center - spread);
        const high = Math.min(this.capacity, center + spread);
        this.targetOccupants = random.int(low, high);
      } else {
        const minDiff = Math.max(1, Math.round(0.1 * this.capacity));
        let attempts = 0;
        let newTarget = this.targetOccupants;
        while (attempts < 5 && Math.abs(newTarget - this.occupants) < minDiff) {
          newTarget = random.int(0, this.capacity);
          attempts++;
        }
        this.targetOccupants = newTarget;
      }
    }

    const delta = this.targetOccupants - this.occupants;
    if (maxStep > 0) {
      if (delta > 0) this.occupants = Math.min(this.capacity, this.occupants + Math.min(maxStep, delta));
      else if (delta < 0) this.occupants = Math.max(0, this.occupants - Math.min(maxStep, -delta));
    }

    const [lat, lng] = this.route.positionAt(this.progress);
    return {
      bus_id: this.id,
      placa: this.plate,
      latitud: Number(lat.toFixed(6)),
      longitud: Number(lng.toFixed(6)),
      ocupantes: this.occupants,
      nivel_ocupacion: occupancyLevel(this.occupants, this.capacity),
      id_ruta: this.route.id,
      ruta: this.route.name,
    };
  }
}

export function buildBuses(busRows, routeRows, random) {
  const routes = new Map();
  const warnings = [];

  for (const row of routeRows) {
    const route = Route.fromRow(row);
    if (!route) {
      warnings.push(`Ruta ${row.id} no tiene un encoded_polyline utilizable`);
      continue;
    }
    routes.set(route.id, route);
  }

  const buses = [];
  for (const row of busRows) {
    const route = routes.get(Number(row.id_ruta));
    if (!route) {
      warnings.push(`Bus ${row.id} omitido: ruta ${row.id_ruta} sin geometria`);
      continue;
    }
    buses.push(SimulatedBus.fromRow(row, route, random));
  }

  // Sesgos de ocupacion: ~30% cerca de 75%, ~40% cerca de 60%.
  if (buses.length) {
    const total = buses.length;
    const count75 = Math.round(0.3 * total);
    const count60 = Math.round(0.4 * total);
    const indices = random.shuffle([...Array(total).keys()]);
    const grp75 = new Set(indices.slice(0, count75));
    const grp60 = new Set(indices.slice(count75, count75 + count60));

    buses.forEach((bus, i) => {
      const ratio = grp75.has(i) ? 0.75 : grp60.has(i) ? 0.6 : null;
      if (ratio === null) return;
      bus.biasRatio = ratio;
      const center = Math.round(ratio * bus.capacity);
      const spread = Math.max(1, Math.round(0.07 * bus.capacity));
      bus.occupants = random.int(Math.max(0, center - spread), Math.min(bus.capacity, center + spread));
      bus.targetOccupants = bus.occupants;
    });
  }

  return { buses, warnings };
}
