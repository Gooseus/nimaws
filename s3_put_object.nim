#[
  Simple example of using a nim S3Client to put an object into an S3 bucket
]#

import os, tables, times, math, asyncdispatch, httpclient
import streams
import nimaws/s3client

if not existsEnv("AWS_ACCESS_ID") or not existsEnv("AWS_ACCESS_SECRET"):
  quit("No credentials found in environment.")

const credentials = (getEnv("AWS_ACCESS_ID"), getEnv("AWS_ACCESS_SECRET"))
let
  bucket = "tbteroz01"
  path = "tests/test_file.txt"
  params = {
    "path": path,
    "bucket": bucket,
    "action": "PUT",
    "payload": "stdin.readAll"
  }.toTable

var client = newS3Client(credentials,"us-west-2")


try:
  var res = waitFor client.put_object(bucket,path,"some bla bla bla")
  echo  res.status
  echo "Tranfer completed"
except HttpRequestError:
  echo "http request error: "
  echo getCurrentExceptionMsg()
except:
  echo "unknown request error: "
  echo getCurrentExceptionMsg()
