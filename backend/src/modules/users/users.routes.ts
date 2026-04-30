import { Router } from 'express';
import { prisma } from '../../config/database';
import { authMiddleware, AuthenticatedRequest } from '../../middlewares/auth.middleware';
import { AppError } from '../../middlewares/error.middleware';

export const usersRouter: Router = Router();

// GET /api/v1/users/profile
usersRouter.get('/profile', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { firebaseUid: req.user!.uid },
      include: {
        wallet: true,
        chargerListings: { where: { isActive: true } },
      },
    });
    if (!user) throw new AppError('User not found', 404);
    res.json({ status: 'success', data: user });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/v1/users/profile – Update profile
usersRouter.patch('/profile', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const { full_name, phone, avatar_url } = req.body;
    const user = await prisma.user.update({
      where: { firebaseUid: req.user!.uid },
      data: {
        ...(full_name && { fullName: full_name }),
        ...(phone && { phone }),
        ...(avatar_url && { avatarUrl: avatar_url }),
      },
    });
    res.json({ status: 'success', data: user });
  } catch (error) {
    next(error);
  }
});

// PATCH /api/v1/users/role – Toggle role (USER ↔ HOST)
usersRouter.patch('/role', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user!.uid } });
    if (!user) throw new AppError('User not found', 404);

    const newRole = user.role === 'USER' ? 'HOST' : 'USER';
    const updated = await prisma.user.update({
      where: { id: user.id },
      data: { role: newRole },
    });

    res.json({ status: 'success', data: updated });
  } catch (error) {
    next(error);
  }
});
