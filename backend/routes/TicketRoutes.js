const express = require('express');
const router = express.Router();
const Ticket = require('../models/Ticket');

// @route   POST /api/tickets
// @desc    Create a new fault report
router.post('/', async (req, res) => {
  try {
    const newTicket = new Ticket(req.body);
    const savedTicket = await newTicket.save();
    res.status(201).json(savedTicket);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// @route   GET /api/tickets
// @desc    Get all tickets (for Admin view)
router.get('/', async (req, res) => {
  try {
    const tickets = await Ticket.find().sort({ createdAt: -1 });
    res.json(tickets);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// @route   PUT /api/tickets/assign/:id
// @desc    Assign a ticket to an electrician
router.put('/assign/:id', async (req, res) => {
  try {
    const { electricianId } = req.body;
    
    const updatedTicket = await Ticket.findByIdAndUpdate(
      req.params.id,
      { 
        assignedTo: electricianId,
        status: 'assigned'
      },
      { new: true }
    );

    res.json(updatedTicket);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

module.exports = router;