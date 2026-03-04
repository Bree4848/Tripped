const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

// 1. IMPORT ROUTES FIRST
const authRoutes = require('./routes/authRoutes');
const ticketRoutes = require('./routes/TicketRoutes');

const app = express();

// 2. MIDDLEWARE
app.use(cors());
app.use(express.json());

// 3. USE ROUTES (After they are imported)
app.use('/api/auth', authRoutes);
app.use('/api/tickets', ticketRoutes);

// Basic Route for Testing
app.get('/', (req, res) => {
  res.send('Electricity Department API is running...');
});

// 4. CONNECT TO MONGODB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch(err => console.error('❌ MongoDB Connection Error:', err));

// 5. START SERVER
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});