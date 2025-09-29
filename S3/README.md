
## 1. What is S3?

S3 = a big online storage on AWS.

You can keep your files (photos, videos, documents, backups, logs) in S3.

Think of it like Google Drive or Dropbox, but for AWS cloud.

## 2. Important Words

Bucket → like a folder. You put files inside.
Example: A bucket called my-bucket-photos.

Object → a file inside the bucket.
Example: cat.png, resume.pdf.

Key → the name of the file in S3.
Example: images/cat.png.

## 3. Storage Classes (Cost Options)

S3 gives different "plans" depending on how often you need the file:

STANDARD → for files you use every day. (fast, but more expensive)

INFREQUENT ACCESS (IA) → for files you rarely use. (cheaper)

GLACIER → for archives, very cheap, but takes hours to download.