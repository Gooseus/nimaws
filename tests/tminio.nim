import unittest,os,httpclient,md5,osproc,strutils

import nimaws/s3client

suite "Test Minio Endpoint":

  when not existsEnv("MINIO_ACCESS_ID") or not existsEnv("MINIO_ACCESS_SECRET") or not existsEnv("S3_BUCKET"):
    echo "To test a minio endpoint export MINIO_ACCESS_ID, MINIO_ACCESS_SECRET, S3_BUCKET and optionally MINIO_ENDPOINT if not the default http://localhost:9000"
  else:
    var
      bucket = getEnv("S3_BUCKET")
      passwd = findExe("passwd")
      client:S3Client
      md5sum = execProcess("md5sum " & passwd)


    const credentials = (getEnv("MINIO_ACCESS_ID"), getEnv("MINIO_ACCESS_SECRET"))
    const endpoint = getEnv("MINIO_ENDPOINT")
    const host = if endpoint.len == 0: "http://localhost:9000" else: endpoint
    client = newS3Client(credentials,host)

    echo endpoint

    test "List Buckets":

      let res = client.list_buckets()
      echo res.code
      assert res.code == Http200

    test "List Objects":
      let res = client.list_objects(bucket)
      echo res.body
      assert res.code == Http200

    test "Put Object":
      var
        path = "/files/passwd"
        payload = if fileExists(passwd): readFile(passwd) else: "some file content\nbla bla bla"
        res = client.put_object(bucket,path,payload)

      assert res.code == Http200

    test "Get Object":
      var
        path = "/files/passwd"
        f: File

      let res = client.get_object(bucket, path)
      assert res.code == Http200
      assert md5sum.find(getMD5(res.body)) > -1




