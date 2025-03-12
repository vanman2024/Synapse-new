import 'dotenv/config';
import app from './api/server';
import config from './config';

// Get port from environment variables
const PORT = config.SERVER.PORT;

// Start the server
app.listen(PORT, () => {
  console.log(`
  ┌───────────────────────────────────────────────────┐
  │                                                   │
  │   🚀 Synapse API Server running                   │
  │                                                   │
  │   🌎 Environment: ${config.SERVER.NODE_ENV.padEnd(27)} │
  │   🔌 Port:        ${String(PORT).padEnd(27)} │
  │   🔗 URL:         http://localhost:${PORT}${' '.repeat(17 - String(PORT).length)} │
  │                                                   │
  └───────────────────────────────────────────────────┘
  `);
});