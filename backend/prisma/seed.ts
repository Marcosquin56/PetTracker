import { PrismaClient } from '@prisma/client';

// Lista curada a mano a partir de lo que nos van pasando por chat — no hay
// pantalla de administración para esto. `id` es un slug fijo (no un uuid
// random) para que correr el seed de nuevo actualice el mismo registro en
// vez de duplicarlo.
//
// `photoUrl` guarda la KEY del objeto en MinIO (no una URL absoluta) —
// mismo patrón que `PetReport.photoUrls`, ver StorageService.uploadPhoto/
// resolvePhotoUrl. Se subieron una sola vez a mano con un script temporal;
// si hace falta resubir/agregar otra, subir a `adoption-centers/<slug>.png`.
const adoptionCenters = [
  {
    id: 'olfateando-huellas',
    name: 'Olfateando Huellas',
    phone: '981266016',
    // El link corto de Maps resuelve a un plus code (sin dirección de calle
    // ni lat/lng exactos disponibles); se deja como fallback de "Cómo llegar".
    mapsUrl: 'https://maps.app.goo.gl/1iv8Hs2nobnCSGoc7',
  },
  {
    id: 'dame-una-pata',
    name: 'Dame una Pata',
    address:
      'Eusebio Lillo 675 entre Mayor Infante Rivarola y Casianoff - Barrio Villa Morra, Asunción',
    phone: '0971 111939',
    // Aproximado a nivel de calle (Eusebio Lillo, Villa Morra) vía OpenStreetMap;
    // no se pudo geocodificar el número de puerta exacto.
    latitude: -25.287488,
    longitude: -57.5794926,
    photoUrl: 'adoption-centers/dame-una-pata.png',
  },
  {
    id: 'pata-patrulla',
    name: 'Pata patrulla',
    phone: '981423153',
    photoUrl: 'adoption-centers/pata-patrulla.png',
  },
];

const prisma = new PrismaClient();

async function main() {
  for (const center of adoptionCenters) {
    await prisma.adoptionCenter.upsert({
      where: { id: center.id },
      create: center,
      update: center,
    });
  }
  console.log(`Seed OK: ${adoptionCenters.length} casas de adopción.`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
