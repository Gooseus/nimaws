#[
  Simple example of using a nim S3Client to get a list of S3 buckets
]#

import os, tables, times, math, asyncdispatch, httpclient
import ../s3client

if not existsEnv("AWS_ACCESS_ID") or not existsEnv("AWS_ACCESS_SECRET"):
  quit("No credentials found in environment.")

const credentials = (getEnv("AWS_ACCESS_ID"), getEnv("AWS_ACCESS_SECRET"))

var client = newS3Client(credentials, "us-east-1")

try:
  let res = waitFor client.list_buckets()
  echo waitFor res.body
except HttpRequestError:
  echo "http request error: "
  echo getCurrentExceptionMsg()
except:
  echo "unknown request error: "
  echo getCurrentExceptionMsg()
