const mongoose = require('mongoose');

const TicketSchema = new mongoose.Schema({
  title: { 
    type: String, 
    required: [true, 'Please add a subject for the fault'] 
  },
  description: { 
    type: String, 
    required: [true, 'Please describe the issue'] 
  },
  status: { 
    type: String, 
    enum: ['open', 'assigned', 'in-progress', 'resolved', 'closed'], 
    default: 'open' 
  },
  priority: { 
    type: String, 
    enum: ['low', 'medium', 'high', 'urgent'], 
    default: 'medium' 
  },
  // Location for the electrician
  address: String,
  coordinates: {
    lat: Number,
    lng: Number
  },
  // Relations
  reportedBy: { type: String, required: true }, // Resident name/ID
  assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Electrician
  createdAt: { type: Date, default: Date.now },
  resolvedAt: { type: Date }
});

module.exports = mongoose.model('Ticket', TicketSchema);