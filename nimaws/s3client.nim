#[
  # S3Client

  A simple object API for performing (limited) S3 operations
 ]#

import strutils except toLower
import times, unicode, tables, asyncdispatch, httpclient,streams,os,strutils
import awsclient


type
  S3Client* = object of AwsClient


proc newS3Client*(credentials:(string,string),region:string,endpoint:string="amazonaws.com"):S3Client=
  let
    creds = AwsCredentials(credentials)
    # TODO - use some kind of template and compile-time variable to put the correct kernel used to build the sdk in the UA?
    httpclient = newAsyncHttpClient("nimaws-sdk/0.1.1; "&defUserAgent.replace(" ","-").toLower&"; darwin/16.7.0")
    scope = AwsScope(date:getAmzDateString(),region:region,service:"s3")

  return S3Client(httpClient:httpclient, credentials:creds, scope:scope, endpoint:endpoint,key:"", key_expires:getTime())

method get_object*(self:var S3Client,bucket,key:string) : Future[AsyncResponse] {.base.} =
  var
    path = key
  path.removePrefix({'/'})
  let params = {
        "bucket":bucket,
        "path": path
      }.toTable

  return self.request(params)

discard """ method get_file*(self:var S3Client,bucket,key,filename:string):Future[bool]{.async,base.} =
  var
    client:S3Client = self
  var res =  waitFor client.get_object(bucket,key) """

method put_object*(self:var S3Client,bucket,path:string,payload:string) : Future[AsyncResponse] {.base.} =
  let params = {
      "action": "PUT",
      "bucket": bucket,
      "path": path,
      "payload": payload
    }.toTable

  return self.request(params)

method list_objects*(self:var S3Client, bucket: string) : Future[AsyncResponse] {.base.} =
  let params = {
      "bucket": bucket
    }.toTable

  return self.request(params)

method list_buckets*(self:var S3Client) : Future[AsyncResponse] {.base.} =
  let params = {
      "action": "GET"
    }.toTable

  return self.request(params)
