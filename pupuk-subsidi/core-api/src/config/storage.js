const { Storage } = require('@google-cloud/storage');

const storage = new Storage({ projectId: process.env.PROJECT_ID });
const bucket = storage.bucket(process.env.GCS_BUCKET);

module.exports = { storage, bucket };
