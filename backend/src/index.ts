import app from './app';
import { config } from './config/env';
import { prisma } from './config/database';

const PORT = config.port;

async function main() {
  try {
    // Test database connection
    await prisma.$connect();
    console.log('✅ Database connected');

    app.listen(PORT, () => {
      console.log(`⚡ VoltShare SL API running on port ${PORT}`);
      console.log(`📍 Health check: http://localhost:${PORT}/api/v1/health`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

main();

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
