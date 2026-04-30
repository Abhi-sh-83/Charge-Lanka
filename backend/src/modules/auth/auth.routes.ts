import { Router } from 'express';
import { prisma } from '../../config/database';
import { authMiddleware, AuthenticatedRequest } from '../../middlewares/auth.middleware';

export const authRouter: Router = Router();

// POST /api/v1/auth/register – Create user profile after Firebase registration
authRouter.post('/register', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const { full_name, phone, role } = req.body;
    const user = await prisma.user.create({
      data: {
        firebaseUid: req.user!.uid,
        email: req.user!.email,
        fullName: full_name,
        phone,
        role: role || 'USER',
      },
    });
    // Create wallet for user
    await prisma.wallet.create({
      data: { userId: user.id },
    });
    res.status(201).json({ status: 'success', data: user });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/auth/me – Get current user profile
authRouter.get('/me', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { firebaseUid: req.user!.uid },
      include: { wallet: true },
    });
    res.json({ status: 'success', data: user });
  } catch (error) {
    next(error);
  }
});
