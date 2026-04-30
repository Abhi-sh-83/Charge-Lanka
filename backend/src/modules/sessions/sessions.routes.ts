import { Router } from 'express';
import { prisma } from '../../config/database';
import { authMiddleware, AuthenticatedRequest } from '../../middlewares/auth.middleware';
import { AppError } from '../../middlewares/error.middleware';

export const sessionsRouter: Router = Router();

// POST /api/v1/sessions/start – Start a charging session
sessionsRouter.post('/start', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user!.uid } });
    if (!user) throw new AppError('User not found', 404);

    const { booking_id } = req.body;

    const booking = await prisma.booking.findUnique({ where: { id: booking_id } });
    if (!booking) throw new AppError('Booking not found', 404);
    if (!booking.qrVerified) throw new AppError('QR verification required', 400);

    const session = await prisma.chargingSession.create({
      data: {
        bookingId: booking_id,
        userId: user.id,
        status: 'CHARGING',
        startedAt: new Date(),
      },
    });

    // Update booking status
    await prisma.booking.update({
      where: { id: booking_id },
      data: { status: 'IN_PROGRESS' },
    });

    res.status(201).json({ status: 'success', data: session });
  } catch (error) {
    next(error);
  }
});

// POST /api/v1/sessions/:id/stop – Stop a charging session
sessionsRouter.post('/:id/stop', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const session = await prisma.chargingSession.update({
      where: { id: req.params.id as string },
      data: {
        status: 'COMPLETED',
        endedAt: new Date(),
      },
    });

    // Update booking status
    await prisma.booking.update({
      where: { id: session.bookingId },
      data: { status: 'COMPLETED' },
    });

    res.json({ status: 'success', data: session });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/sessions/:id
sessionsRouter.get('/:id', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const session = await prisma.chargingSession.findUnique({
      where: { id: req.params.id as string },
      include: {
        booking: {
          include: {
            listing: { select: { title: true, address: true } },
            package: { select: { name: true, pricePerKwh: true, sessionFee: true } },
          },
        },
      },
    });
    res.json({ status: 'success', data: session });
  } catch (error) {
    next(error);
  }
});
