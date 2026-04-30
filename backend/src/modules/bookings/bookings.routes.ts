import { Router } from 'express';
import { prisma } from '../../config/database';
import { authMiddleware, AuthenticatedRequest } from '../../middlewares/auth.middleware';
import { AppError } from '../../middlewares/error.middleware';
import { config } from '../../config/env';

export const bookingsRouter: Router = Router();

// POST /api/v1/bookings – Create a booking with commission calculation
bookingsRouter.post('/', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user!.uid } });
    if (!user) throw new AppError('User not found', 404);

    const { listing_id, package_id, scheduled_start, scheduled_end } = req.body;

    // Get package for pricing
    const pkg = await prisma.chargingPackage.findUnique({ where: { id: package_id } });
    if (!pkg) throw new AppError('Package not found', 404);

    // Estimate cost (based on scheduled duration)
    const durationHrs = (new Date(scheduled_end).getTime() - new Date(scheduled_start).getTime()) / 3600000;
    const estimatedKwh = durationHrs * 7.2; // assume average 7.2 kW charger
    const totalEstimate = Number(pkg.pricePerKwh) * estimatedKwh + Number(pkg.sessionFee);
    const platformFee = totalEstimate * config.platformCommissionRate;
    const hostPayout = totalEstimate - platformFee;

    // Race Condition Protection: Use serializable transaction with advisory lock
    const booking = await prisma.$transaction(async (tx) => {
      // Advisory lock on the listing to prevent double-booking
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${listing_id}))`;

      // Check for overlapping bookings
      const overlap = await tx.booking.findFirst({
        where: {
          listingId: listing_id,
          status: { in: ['PENDING', 'CONFIRMED', 'IN_PROGRESS'] },
          scheduledStart: { lt: new Date(scheduled_end) },
          scheduledEnd: { gt: new Date(scheduled_start) },
        },
      });

      if (overlap) {
        throw new AppError('Time slot already booked', 409);
      }

      return tx.booking.create({
        data: {
          userId: user.id,
          listingId: listing_id,
          packageId: package_id,
          scheduledStart: new Date(scheduled_start),
          scheduledEnd: new Date(scheduled_end),
          totalEstimate,
          platformFee,
          hostPayout,
        },
        include: { listing: true, package: true },
      });
    });

    res.status(201).json({ status: 'success', data: booking });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/bookings/history – Get user's booking history
bookingsRouter.get('/history', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user!.uid } });
    if (!user) throw new AppError('User not found', 404);

    const bookings = await prisma.booking.findMany({
      where: { userId: user.id },
      include: {
        listing: { select: { title: true, address: true, city: true } },
        package: { select: { name: true, tier: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ status: 'success', data: bookings });
  } catch (error) {
    next(error);
  }
});

// POST /api/v1/bookings/:id/verify-qr – Verify QR code for booking
bookingsRouter.post('/:id/verify-qr', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const { qr_token } = req.body;
    const bookingId = req.params.id as string;
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      include: { listing: true },
    });

    if (!booking) throw new AppError('Booking not found', 404);
    if ((booking as any).listing.qrCodeToken !== qr_token) {
      throw new AppError('Invalid QR code', 400);
    }

    const updated = await prisma.booking.update({
      where: { id: bookingId },
      data: { qrVerified: true, status: 'CONFIRMED' },
    });

    res.json({ status: 'success', data: updated });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/v1/bookings/:id/cancel
bookingsRouter.patch('/:id/cancel', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const updated = await prisma.booking.update({
      where: { id: req.params.id as string },
      data: { status: 'CANCELLED' },
    });
    res.json({ status: 'success', data: updated });
  } catch (error) {
    next(error);
  }
});
