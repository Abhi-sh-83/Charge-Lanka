import { Router } from 'express';
import { prisma } from '../../config/database';
import { authMiddleware, AuthenticatedRequest } from '../../middlewares/auth.middleware';
import { AppError } from '../../middlewares/error.middleware';
import { config } from '../../config/env';

export const paymentsRouter: Router = Router();

// GET /api/v1/wallet – Get user's wallet
paymentsRouter.get('/wallet', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user!.uid } });
    if (!user) throw new AppError('User not found', 404);

    const wallet = await prisma.wallet.findUnique({ where: { userId: user.id } });
    res.json({ status: 'success', data: wallet });
  } catch (error) {
    next(error);
  }
});

// POST /api/v1/wallet/top-up – Add funds to wallet
paymentsRouter.post('/wallet/top-up', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user!.uid } });
    if (!user) throw new AppError('User not found', 404);

    const { amount } = req.body;
    if (!amount || amount <= 0) throw new AppError('Invalid amount', 400);

    const wallet = await prisma.wallet.update({
      where: { userId: user.id },
      data: { balance: { increment: amount } },
    });

    // Record transaction
    await prisma.paymentTransaction.create({
      data: {
        walletId: wallet.id,
        userId: user.id,
        type: 'TOP_UP',
        amount,
        status: 'COMPLETED',
        description: 'Wallet top-up',
      },
    });

    res.json({ status: 'success', data: wallet });
  } catch (error) {
    next(error);
  }
});

// GET /api/v1/wallet/transactions – Get transaction history
paymentsRouter.get('/wallet/transactions', authMiddleware, async (req: AuthenticatedRequest, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { firebaseUid: req.user!.uid } });
    if (!user) throw new AppError('User not found', 404);

    const transactions = await prisma.paymentTransaction.findMany({
      where: { userId: user.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    res.json({ status: 'success', data: transactions });
  } catch (error) {
    next(error);
  }
});
