import { Router } from 'express';
import { prisma } from '../../config/database';
import { authMiddleware, AuthenticatedRequest } from '../../middlewares/auth.middleware';
import { Prisma } from '@prisma/client';

export const chargersRouter: Router = Router();

// GET /api/v1/chargers/nearby – PostGIS spatial query
chargersRouter.get('/nearby', async (req, res, next) => {
  try {
    const { lat, lng, radius = '5000', connector } = req.query;

    const latitude = parseFloat(lat as string);
    const longitude = parseFloat(lng as string);
    const radiusMeters = parseFloat(radius as string);

    // PostGIS spatial query using ST_DWithin
    const chargers = await prisma.$queryRaw`
      SELECT
        cl.*,
        ST_Distance(cl.location::geography, ST_MakePoint(${longitude}, ${latitude})::geography) as distance_meters,
        json_agg(
          json_build_object(
            'id', cp.id,
            'listing_id', cp.listing_id,
            'name', cp.name,
            'tier', cp.tier,
            'price_per_kwh', cp.price_per_kwh,
            'session_fee', cp.session_fee,
            'max_duration_mins', cp.max_duration_mins,
            'description', cp.description,
            'is_active', cp.is_active
          )
        ) FILTER (WHERE cp.id IS NOT NULL) as charging_packages
      FROM charger_listings cl
      LEFT JOIN charging_packages cp ON cp.listing_id = cl.id AND cp.is_active = true
      WHERE cl.is_active = true
        AND ST_DWithin(
          cl.location::geography,
          ST_MakePoint(${longitude}, ${latitude})::geography,
          ${radiusMeters}
        )
        ${connector ? Prisma.sql`AND cl.connector_type = ${connector as string}` : Prisma.empty}
      GROUP BY cl.id
      ORDER BY distance_meters ASC
      LIMIT 50
    `;

    res.json({ status: 'success', data: chargers });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/chargers/:id – Get charger details
chargersRouter.get('/:id', async (req, res, next) => {
  try {
    const charger = await prisma.chargerListing.findUnique({
      where: { id: req.params.id },
      include: {
        chargingPackages: { where: { isActive: true } },
        host: { select: { id: true, fullName: true, avatarUrl: true } },
        availability: true,
        reviews: {
          take: 10,
          orderBy: { createdAt: 'desc' },
          include: { author: { select: { fullName: true, avatarUrl: true } } },
        },
      },
    });
    res.json({ status: 'success', data: charger });
  } catch (error) {
    next(error);
  }
});

// POST /api/v1/chargers – Create a new charger listing (Host only)
chargersRouter.post('/', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user!.uid } });
    if (!user) { res.status(404).json({ error: 'User not found' }); return; }

    const { title, description, connector_type, power_output_kw, address, city, province, latitude, longitude, photos, amenities } = req.body;

    const qrCodeToken = `vs_${user.id}_${Date.now()}`;

    const charger = await prisma.$executeRaw`
      INSERT INTO charger_listings (id, host_id, title, description, connector_type, power_output_kw, address, city, province, location, photos, amenities, qr_code_token, created_at, updated_at)
      VALUES (gen_random_uuid(), ${user.id}, ${title}, ${description}, ${connector_type}::"ConnectorType", ${power_output_kw}, ${address}, ${city}, ${province}, ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326), ${photos || []}, ${amenities || []}, ${qrCodeToken}, NOW(), NOW())
    `;

    res.status(201).json({ status: 'success', data: { qr_code_token: qrCodeToken } });
  } catch (error) {
    next(error);
  }
});
