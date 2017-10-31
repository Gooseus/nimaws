#[
  Simple example of using a nim S3Client to get a list of objects from an S3 bucket
]#

import os, tables, times, math, asyncdispatch, httpclient
import nimaws/s3client

if not existsEnv("AWS_ACCESS_ID") or not existsEnv("AWS_ACCESS_SECRET"):
  quit("No credentials found in environment.")

const credentials = (getEnv("AWS_ACCESS_ID"), getEnv("AWS_ACCESS_SECRET"))
let bucket = "gooseus-nim-api-test"

var client = newS3Client(credentials,"us-east-1")

try:
  let res = waitFor client.list_objects(bucket)
  echo waitFor res.body
except HttpRequestError:
  echo "http request error: "
  echo getCurrentExceptionMsg()
except: 
  echo "unknown request error: "
  echo getCurrentExceptionMsg()
