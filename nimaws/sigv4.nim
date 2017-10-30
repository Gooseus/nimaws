#[ 
  # AWS SignatureV4 Authorization Library

  Implements functions to handle the AWS Signature v4 request signing
  http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
 ]#
import os, times
import strutils except toLower
import sequtils, algorithm, tables, nimSHA2
import securehash, hmac, base64, re, unicode
from uri import parseUri

type
  AwsCredentials* = tuple
    id: string
    secret: string

  AwsScope* = object
    date*: string
    region*: string
    service*: string

  AwsCredentialScope* = object
    credentials*: AWSCredentials
    date*: string
    region*: string
    service*: string
    signed_key*: string
    expires*: TimeInfo

# Our AWS4 constants, not quite sure how to handle these, so they act as defaults
# TODO - Support more just SHA256 hashing for sigv4
const 
  alg = "AWS4-HMAC-SHA256"
  term = "aws4_request"

# Some convenience operators, for fun and aesthetics
proc `$`(s:AwsScope):string=
  return s.date[0..7]&"/"&s.region&"/"&s.service

proc `!$`(s:string):string=
  return toLowerASCII(hex(computeSHA256(s)))

proc `!$`(k,s:string):string=
  return toLowerASCII(hex(hmac_sha256(k,s)))

proc `?$`(k,s:string):string=
  return $hmac_sha256(k,s)

# Copied from cgi library and modified to fit the AWS-approved uri_encode
# http://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
proc uri_encode(s:string, encSlash:bool):string=
  result = newStringOfCap(s.len + s.len shr 2) # assume 12% non-alnum-chars
  for i in 0..s.len-1:
    case s[i]
    of 'a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_', '~': add(result, s[i])
    of '/': 
      if encSlash: add(result, "%2F")
      else: add(result,s[i])
    else:
      add(result, '%')
      add(result, toHex(ord(s[i]), 2).toUpperASCII)

# Overloading so we can use in map without an error
proc uri_encode(s:string):string=
  return uri_encode(s,true)

# trim leading and trailing, as well as collapse multiple into single
proc condense_whitespace(x:string):string=
  return strip(x).replace(re"\s+"," ")

# don't encode the slashes in the path
proc create_canonical_path(path:string):string=
  return uri_encode(path,false)

# create the canonical querystring string
# TODO - Test sigv4 with query string parameters to sign
proc create_canonical_qs(query:string):string=
  if query.len<1:return ""
  var qs = query.split("&")
  sort(qs, cmp[string])
  qs = qs.map(proc (x:string):string=x.split("=").map(uri_encode).join("="))
  return qs.join("&")

# create the canonical and signed headers strings
proc create_canonical_and_signed_headers(headers:TableRef):(string,string)=
  var 
    canonical = ""
    signed = ""
    heads : seq[string] = @[]
    lhead = {"host": heads }.newTable

  for k in keys(headers):
    lhead[k.toLower()] = headers[k]
    heads.add(k.toLower())
  
  sort(heads, cmp[string])
  signed = heads.join(";")
  
  var val = ""
  for name in heads:
    val = lhead[name].map(condense_whitespace).join("")
    canonical &= name&":"&val&"\n"
  return (canonical,signed)

# create the canonical request string
# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
proc create_canonical_request(headers: var TableRef, action: string, url: string, payload: string="", unsignedPayload:bool=true, contentSha:bool=true): (string,string)=
  let 
    uri = parseUri(url)
    cpath = create_canonical_path(uri.path)
    cquery = create_canonical_qs(uri.query)

  var hashload = "UNSIGNED-PAYLOAD"
  if payload.len>0 or not unsignedPayload:
    # !$a => toLowerASCII(hex(computeSHA256(a)))
    hashload = !$payload

  # add the host header for signing, will remove later so we don't have 2
  headers["Host"] = @[uri.hostname]
  # sometimes we don't want/need this, like for the AWS test suite
  if contentSha:
    headers["X-Amz-Content-Sha256"] = @[hashload]

  let (chead, signed) = create_canonical_and_signed_headers(headers)
  return (signed, ("$1\n$2\n$3\n$4\n$5\n$6" % [action,cpath,cquery,chead,signed,hashload]))

# create a signing key with a lot of hashing of the credential scope
proc create_signing_key*(creds:AwsCredentials,scope:AwsScope,termination:string=term): string =
  # (a ?$ b) => $hmac_sha256(a,b)
  return ("AWS4"&creds[1]) ?$ scope.date[0..7] ?$ scope.region ?$ scope.service ?$ termination
  # ? cleaner than $hmac_sha256($hmac_sha256($hmac_sha256($hmac_sha256("AWS4"&secret, date[0..7]),region),service),termination) ?

# add AWS headers, including Authorization, to the header table, return our signing key (good for 7 days withi scope)
proc create_aws_authorization*(request:(string,string,string),
                              headers:var TableRef,
                              creds:AwsCredentials,
                              scope:AwsScope,
                              opts:(string,string)=(alg,term)):string=

  # add our AWS date header
  headers["X-Amz-Date"] = @[scope.date]

  # create signed headers and canonical request string
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  let (signed_head, canonical_request) = create_canonical_request(headers, request[0], request[1], request[2])

  # create string to sign
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
  let to_sign = "$1\n$2\n$3/$4\n$5" % [opts[0], scope.date, $scope, opts[1], !$canonical_request]
  
  # create signing key and export for caching
  # sign the string with our key
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
  result = create_signing_key(creds,scope,opts[1])
  let sig = result !$ to_sign

  # add AWS authorization header
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-add-signature-to-request.html
  headers["Authorization"] = @[("$1 Credential=$2/$3/$4, SignedHeaders=$5, Signature=$6" % [opts[0],creds[0],$scope,opts[1],signed_head,sig])]
  
  # delete host header since it's added by the the httpclient.request later and having 2 Host headers is Forbidden
  headers.del("Host")
