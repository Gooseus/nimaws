#[ 
  # AwsClient

  The core library for building AWS service APIs
  implements:
    * an AwsClient which using an AsyncHttpClient for comm
    * a contructor function for the AwsClient that takes credentials and service scope
    * a request proc which takes an AwsClient and the request params to handle Sigv4 signing and async dispatch
 ]#

import times, tables, unicode
import strutils except toLower
import httpclient, asyncdispatch
import sigv4

export sigv4.AwsCredentials, sigv4.AwsScope

const iso_8601_aws = "yyyyMMdd'T'HHmmss'Z'"

proc getAmzDateString*():string=
  return format(getGMTime(getTime()), iso_8601_aws)

type
  AwsClient* {.inheritable.} = object
    httpClient*: AsyncHttpClient
    credentials*: AwsCredentials
    scope*: AwsScope
    key*: string
    key_expires*: TimeInfo

proc newAwsClient*(credentials:(string,string),region,service:string):AwsClient=
  let
    creds = AwsCredentials(credentials)
    httpclient = newAsyncHttpClient("aws-sdk-nim/0.0.1; "&defUserAgent.replace(" ","-").toLower&"; darwin/16.7.0")
    scope = AwsScope(date:getAmzDateString(),region:region,service:service)
  
  return AwsClient(httpClient:httpclient, credentials:creds, scope:scope,key:"",key_expires:getGMTime(getTime()))

proc request*(client:var AwsClient,params:Table):Future[AsyncResponse]=
  let url = ("https://$1.amazonaws.com/" % client.scope.service) & params["uri"]
  var payload = ""
    
  if params.hasKey("payload"):
    payload = params["payload"]

  let req = (params["action"], url, payload)

  client.key = create_aws_authorization(req, client.httpClient.headers.table, client.credentials, client.scope)
  client.key_expires = getGmTime(getTime()) + initInterval(days=7)

  return client.httpClient.request(url,params["action"],payload)

