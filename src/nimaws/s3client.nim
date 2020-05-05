#[
  # S3Client

  A simple object API for performing (limited) S3 operations
 ]#

import strutils except toLower
import times, unicode, tables, httpclient,streams,os,strutils,uri
import awsclient


type
  S3Client* = object of AwsClient

proc newS3Client*(credentials:(string,string),region:string=defRegion,host:string=awsEndpt):S3Client=
  let
    creds = AwsCredentials(credentials)
    # TODO - use some kind of template and compile-time variable to put the correct kernel used to build the sdk in the UA?
    httpclient = newHttpClient("nimaws-sdk/0.2.1; "&defUserAgent.replace(" ","-").toLower&"; darwin/16.7.0")
    scope = AwsScope(date:getAmzDateString(),region:region,service:"s3")
  var endpoint:string
  if not host.startsWith("http"): 
    endpoint = "https://" & host
  else:
    endpoint = host
  return S3Client(httpClient:httpclient, credentials:creds, scope:scope, endpoint:parseUri(endpoint),isAWS:endpoint.endsWith(awsEndpt),key:"", key_expires:getTime())

method get_object*(self:var S3Client,bucket,key:string) : Response {.base.} =
  var
    path = key
  let params = {
        "bucket":bucket,
        "path": path
      }.toTable

  return self.request(params)

#
## put_object
##  bucket name
##  path has to be absoloute path in the form /path/to/file
##  payload is binary string
method put_object*(self:var S3Client,bucket,path:string,payload:string) : Response {.base,gcsafe.} =
  let params = {
      "action": "PUT",
      "bucket": bucket,
      "path": path,
      "payload": payload
    }.toTable

  return self.request(params)

method list_objects*(self:var S3Client, bucket: string) : Response {.base,gcsafe.} =
  let params = {
      "bucket": bucket
    }.toTable

  return self.request(params)

method list_buckets*(self:var S3Client) : Response {.base,gcsafe.} =
  let params = {
      "action": "GET"
    }.toTable

  return self.request(params)
