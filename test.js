var Minio = require('minio')

var minioClient = new Minio.Client({
    endPoint: 'localhost',
    port: 9000,
    useSSL: false,
    accessKey: 'QD7MTFCO7TEM7N5KA8BT',
    secretKey: 'wXoJMaXYn7wc5n4EE+FncvVRyA6eXBsz2L5iapYC'
});


minioClient.listBuckets(function(err, buckets) {
  if (err) return console.log(err)
  console.log('buckets :', buckets)
})
