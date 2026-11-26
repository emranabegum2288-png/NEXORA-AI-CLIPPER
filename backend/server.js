
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const ffmpeg = require('fluent-ffmpeg');
const ffmpegPath = require('ffmpeg-static');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

ffmpeg.setFfmpegPath(ffmpegPath);

app.use(cors());
app.use(express.json());

const uploadDir = path.join(__dirname, 'uploads');
const outputDir = path.join(__dirname, 'outputs');

fs.mkdirSync(uploadDir, { recursive: true });
fs.mkdirSync(outputDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const safeName = Date.now() + '-' +
      file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    cb(null, safeName);
  }
});

const upload = multer({
  storage,
  limits: {
    fileSize: 50 * 1024 * 1024
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Only video files are allowed.'));
    }
  }
});

app.get('/', (req, res) => {
  res.json({
    app: 'NEXORA AI CLIPPER',
    status: 'Backend is running',
    version: '2.0.0'
  });
});

app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'NEXORA Backend is healthy'
  });
});

app.post('/generate', upload.single('video'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: 'Please upload a video file.'
    });
  }

  const duration = req.body.duration;

  const allowedDurations = {
    '15s': 15,
    '30s': 30,
    '60s': 60,
    '2 Min': 120,
    '5 Min': 300,
    '10 Min': 600
  };

  const seconds = allowedDurations[duration];

  if (!seconds) {
    fs.unlinkSync(req.file.path);

    return res.status(400).json({
      success: false,
      message: 'Invalid video duration.'
    });
  }

  const outputName = `nexora-${Date.now()}.mp4`;
  const outputPath = path.join(outputDir, outputName);

  ffmpeg(req.file.path)
    .setStartTime(0)
    .duration(seconds)
    .videoCodec('libx264')
    .audioCodec('aac')
    .outputOptions([
      '-vf scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2',
      '-preset ultrafast',
      '-movflags +faststart'
    ])
    .on('end', () => {
      fs.unlink(req.file.path, () => {});

      res.json({
        success: true,
        message: 'Video processing completed.',
        filename: outputName,
        downloadUrl: `/download/${outputName}`
      });
    })
    .on('error', (error) => {
      fs.unlink(req.file.path, () => {});
      fs.unlink(outputPath, () => {});

      console.error(error);

      if (!res.headersSent) {
        res.status(500).json({
          success: false,
          message: 'Video processing failed.'
        });
      }
    })
    .save(outputPath);
});

app.get('/download/:filename', (req, res) => {
  const filename = path.basename(req.params.filename);
  const filePath = path.join(outputDir, filename);

  if (!fs.existsSync(filePath)) {
    return res.status(404).json({
      success: false,
      message: 'Video not found.'
    });
  }

  res.download(filePath);
});

app.use((error, req, res, next) => {
  console.error(error);

  res.status(400).json({
    success: false,
    message: error.message || 'Upload error.'
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`NEXORA Backend running on port ${PORT}`);
});
