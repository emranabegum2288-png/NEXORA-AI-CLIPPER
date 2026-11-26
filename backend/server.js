
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    app: 'NEXORA AI CLIPPER',
    status: 'Backend is running',
    version: '1.0.0'
  });
});

app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'NEXORA Backend is healthy'
  });
});

app.post('/generate', (req, res) => {
  res.status(501).json({
    success: false,
    message: 'AI video processing is not connected yet.'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`NEXORA Backend running on port ${PORT}`);
});
