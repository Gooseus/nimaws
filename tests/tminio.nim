import unittest,os,asyncdispatch,httpclient,md5,osproc,strutils

import s3client

echo "erer"

suite "Test minio Endpoint":

  when existsEnv("MINIO_ACCESS_ID") and existsEnv("MINIO_ACCESS_SECRET"):
    var
      bucket = "tbteroz01"
      passwd = findExe("passwd")
      client:S3Client
      md5sum = execProcess("md5sum " & passwd)


    const credentials = (getEnv("MINIO_ACCESS_ID"), getEnv("MINIO_ACCESS_SECRET"))
    client = newMinioClient(credentials,"http://localhost:9000")


    test "List Buckets":

      let res = waitFor client.list_buckets
      echo res.status
      echo waitFor res.body

    discard """ test "Put Object":
      client.httpClient.headers.clear()
      var
        path = "files/passwd"
        payload = if fileExists(passwd): readFile(passwd) else: "some file content\nbla bla bla"
        res = waitFor client.put_object(bucket,path,payload)

      assert res.status == "200 OK"

    test "Get Object":
      client.httpClient.headers.clear()
      var
        path = "files/passwd"
        f: File

      let res = waitFor client.get_object(bucket, path)
      assert md5sum.find(getMD5(waitFor res.body)) > -1 """




