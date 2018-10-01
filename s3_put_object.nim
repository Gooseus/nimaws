#[
  Simple example of using a nim S3Client to put an object into an S3 bucket
]#

import os, tables, times, math, asyncdispatch, httpclient
import streams
import nimaws/awsclient

if not existsEnv("AWS_ACCESS_ID") or not existsEnv("AWS_ACCESS_SECRET"):
  quit("No credentials found in environment.")

const credentials = (getEnv("AWS_ACCESS_ID"), getEnv("AWS_ACCESS_SECRET"))
let
  bucket = "tbteroz01"
  path = "/testing/path/test_file.txt"
  params = {
    "path": path,
    "bucket": bucket,
    "action": "PUT",
    "payload": "stdin.readAll"
  }.toTable

var client = newAwsClient(credentials,"us-east-1","s3")

try:
  let response = waitFor client.request(params)
  echo waitFor response.body
  echo "Transfer Complete!\n"
except HttpRequestError:
  echo "http request error: "
  echo getCurrentExceptionMsg()
except:
  echo "unknown request error: "
  echo getCurrentExceptionMsg()
