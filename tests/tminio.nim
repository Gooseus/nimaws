import unittest,os,asyncdispatch,httpclient,md5,osproc,strutils

import nimaws/s3client

suite "Test Minio Endpoint":

  when not existsEnv("MINIO_ACCESS_ID") and not existsEnv("MINIO_ACCESS_SECRET"):
    echo "To test a minio endpoint export MINIO_ACCESS_ID and MINIO_ACCESS_SECRET and optionally MINIO_ENDPOINT if not the default http://localhost:9000"
  else:
    var
      bucket = "sandbox01"
      passwd = findExe("passwd")
      client:S3Client
      md5sum = execProcess("md5sum " & passwd)


    const credentials = (getEnv("MINIO_ACCESS_ID"), getEnv("MINIO_ACCESS_SECRET"))
    const endpoint = getEnv("MINIO_ENDPOINT")
    const host = if endpoint.len == 0: "http://localhost:9000" else: endpoint
    client = newS3Client(credentials,"local",host)


    test "List Buckets":

      let res = waitFor client.list_buckets()
      assert res.code == Http200

    test "List Objects":
      let res = waitFor client.list_objects(bucket)
      echo waitFor res.body
      assert res.code == Http200

    test "Put Object":
      var
        path = "/files/passwd"
        payload = if fileExists(passwd): readFile(passwd) else: "some file content\nbla bla bla"
        res = waitFor client.put_object(bucket,path,payload)

      assert res.code == Http200

    test "Get Object":
      var
        path = "/files/passwd"
        f: File

      let res = waitFor client.get_object(bucket, path)
      assert res.code == Http200
      assert md5sum.find(getMD5(waitFor res.body)) > -1




