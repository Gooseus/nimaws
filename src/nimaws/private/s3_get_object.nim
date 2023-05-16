#[
  Simple example of using a nim S3Client to get an object from an S3 bucket
]#

import os, tables, times, math, asyncdispatch, httpclient
import ../s3client

if not existsEnv("AWS_ACCESS_ID") or not existsEnv("AWS_ACCESS_SECRET"):
  quit("No credentials found in environment.")

const credentials = (getEnv("AWS_ACCESS_ID"), getEnv("AWS_ACCESS_SECRET"))
let
  bucket = "tbteroz01"
  path = "/files/s3_put_object"

var client = newS3Client(credentials, "us-west-2")

try:
  let res = waitFor client.get_object(bucket, path)
  var f: File
  if open(f, "/tmp/s3_put_object", fmWrite):
    f.write(waitFor res.body)
    f.close()
except HttpRequestError:
  echo "http request error: "
  echo getCurrentExceptionMsg()
except:
  echo "unknown request error: "
  echo getCurrentExceptionMsg()
