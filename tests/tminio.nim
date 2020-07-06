import unittest,os,httpclient,md5,osproc,strutils,parsecfg

import nimaws/s3client

suite "Test Minio Endpoint":

  block:
    var 
      cfg = loadConfig(".env")#env file would be in the root of project as nimble test would see it
    let
      MINIO_ACCESS_ID = cfg.getSectionValue("","MINIO_ACCESS_ID")
      MINIO_ACCESS_SECRET = cfg.getSectionValue("","MINIO_ACCESS_SECRET")
      MINIO_BUCKET = cfg.getSectionValue("","MINIO_BUCKET")
      MINIO_ENDPOINT = cfg.getSectionValue("","MINIO_ENDPOINT")

    if MINIO_ACCESS_ID.len == 0 or not MINIO_ACCESS_SECRET.len == 0  or not MINIO_BUCKET.len == 0 or MINIO_ENDPOINT.len == 0:
      echo "To test a minio endpoint provide MINIO_ACCESS_ID, MINIO_ACCESS_SECRET, MINIO_BUCKET and MINIO_ENDPOINT"
    else:
      var
        passwd = findExe("passwd")
        client:S3Client
        md5sum = execProcess("md5sum " & passwd)


      let credentials = (MINIO_ACCESS_ID, MINIO_ACCESS_SECRET)
      
      client = newS3Client(credentials,host=MINIO_ENDPOINT)

        
      test "List Buckets":

        let res = client.list_buckets()
        assert res.len > 0

      
      test "Put Object":
        var
          path = "/files/passwd"
          payload = if fileExists(passwd): readFile(passwd) else: "some file content\nbla bla bla"
          res = client.put_object(MINIO_BUCKET,path,payload)

        assert res.code == Http200

      test "Get Object":
        var
          path = "/files/passwd"
       
        let res = client.get_object(MINIO_BUCKET, path)
        assert res.code == Http200
        assert md5sum.find(getMD5(res.body)) > -1
      
      test "List Objects":
        let res = client.list_objects(MINIO_BUCKET)
        assert res.len > 0
        




