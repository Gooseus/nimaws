import unittest,os,httpclient,md5,osproc,strutils

import 
    nimaws/s3client,
    nimaws/awsclient

when not existsEnv("AWS_ACCESS_ID") or not existsEnv("AWS_ACCESS_SECRET") or not existsEnv("S3_BUCKET"):
    echo "To test AWS S3 export AWS_ACCESS_ID, AWS_ACCESS_SECRET and S3_BUCKET"
else:
  
  suite "Test s3Client":
    
    var
      bucket = getEnv("S3_BUCKET")
      region = if existsEnv("AWS_REGION"): getEnv("AWS_REGION") else: defRegion
      passwd = findExe("passwd")
      md5sum = execProcess("md5sum " & passwd)
      creds = (getEnv("AWS_ACCESS_ID"), getEnv("AWS_ACCESS_SECRET"))
      client:S3Client
    
    test "List Buckets":
      client = newS3Client(creds) #note for list buckets region is the default one
      let res = client.list_buckets()
      assert res.len > 0

    test "List Objects":
      client = newS3Client(creds,region)
      let res = client.list_objects(bucket)
      echo res.body
      assert res.code == Http200

    test "Put Object":
      var
        path = "files/passwd"
        payload = if fileExists(passwd): readFile(passwd) else: "some file content\nbla bla bla"
      
      client = newS3Client(creds,region)
      let res = client.put_object(bucket,path,payload)

      assert res.code == Http200

    test "Get Object":
      var
        path = "files/passwd"
        f: File

      client = newS3Client(creds,region)
      let res = client.get_object(bucket, path)
      assert res.code == Http200
      assert md5sum.find(getMD5(res.body)) > -1

    
