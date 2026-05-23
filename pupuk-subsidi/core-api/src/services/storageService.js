const { bucket } = require('../config/storage');
const logger = require('../utils/logger');

const uploadToGCS = async (file, folder, id) => {
  try {
    const ext = file.mimetype.split('/')[1];
    const filename = `${folder}/${id}-${Date.now()}.${ext}`;
    const blob = bucket.file(filename);

    await blob.save(file.buffer, {
      contentType: file.mimetype,
      resumable: false
    });

    const publicUrl = `https://storage.googleapis.com/${process.env.GCS_BUCKET}/${filename}`;
    logger.info('File uploaded ke GCS', { filename });
    return publicUrl;
  } catch (err) {
    logger.error('GCS upload error', { error: err.message });
    throw err;
  }
};

module.exports = { uploadToGCS };
