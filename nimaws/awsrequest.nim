#[ 
  # aws_request method

  Uses a slightly different approach than the AwsClient
 ]#

import os, times, math
import strutils except toLower
import sequtils, algorithm, tables, nimSHA2, unicode, uri
import httpclient, asyncdispatch, asyncfile
import securehash, hmac, base64
import sigv4

# export these Types for use in the aws_request method
export sigv4.AwsCredentials, sigv4.AwsCredentialScope

# also exports the aws time format string since it expect this format in the scope
const iso_8601_aws = "yyyyMMdd'T'HHmmss'Z'"
proc getAmzDateString*():string=
  return format(getGMTime(getTime()), iso_8601_aws)

# takes an AwsCredentialScope and a set of request params, creates the client and dispatches the signed request in one go
proc aws_request*(scope: var AWSCredentialScope, params: Table):Future[AsyncResponse]=
  var client = newAsyncHttpClient("aws-sdk-nim/0.0.1; "&defUserAgent.replace(" ","-").toLower&"; darwin/16.7.0")

  let 
    url = ("https://$1.amazonaws.com/" % scope.service ) & params["uri"]
    req = (params["action"], url, params["payload"])

  scope.signed_key = create_aws_authorization(req, client.headers.table, scope)
  scope.expires = getGmTime(getTime()) + initInterval(days=7)

  return client.request(url,params["action"],params["payload"])
