import express, { type Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { config } from './config/env';
import { errorMiddleware } from './middlewares/error.middleware';

// Import route modules
import { authRouter } from './modules/auth/auth.routes';
import { chargersRouter } from './modules/chargers/chargers.routes';
import { bookingsRouter } from './modules/bookings/bookings.routes';
import { sessionsRouter } from './modules/sessions/sessions.routes';
import { paymentsRouter } from './modules/payments/payments.routes';
import { usersRouter } from './modules/users/users.routes';

const app: Express = express();

// ── Middlewares ──
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// ── Routes ──
app.use('/api/v1/auth', authRouter);
app.use('/api/v1/chargers', chargersRouter);
app.use('/api/v1/bookings', bookingsRouter);
app.use('/api/v1/sessions', sessionsRouter);
app.use('/api/v1/payments', paymentsRouter);
app.use('/api/v1/users', usersRouter);

// ── Health Check ──
app.get('/api/v1/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ── Error Handler ──
app.use(errorMiddleware);

export default app;
