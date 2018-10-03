import unittest,os,asyncdispatch,httpclient

import nimaws/s3client

suite "Test s3Client":
  var
    bucket = "tbteroz01"
    region = "us-west-2"
    file = "/tmp/cookie.jar"#findExe("passwd")

  test "put_file":
    if not existsEnv("AWS_ACCESS_ID") or not existsEnv("AWS_ACCESS_SECRET"):
      quit("No credentials found in environment.")

    const credentials = (getEnv("AWS_ACCESS_ID"), getEnv("AWS_ACCESS_SECRET"))
    var
      client = newS3Client(credentials,"us-west-2")
      res  = waitFor client.put_file(bucket,"tests/passwd",file)

    echo waitFor res.body
    assert res.status == "200 OK"


  
