#[
  # AWS SignatureV4 Authorization Library

  Implements functions to handle the AWS Signature v4 request signing
  http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html
 ]#
import times
import strutils except toLower
import algorithm, tables, nimSHA2
import hmac, re
import unicode except strip
from uri import parseUri


type
  AwsCredentials* = tuple
    id: string
    secret: string

  AwsScope* = object
    date*: string
    region*: string
    service*: string


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
# Varriount + Yardanico method
proc uri_encode(s: string, notEncode: set[char]): string =
  result = newStringOfCap(s.len + s.len shr 2) # assume 12% non-alnum-chars
  for i in 0..(s.len - 1):
    if s[i] in notEncode+{'a'..'z', 'A'..'Z', '0'..'9', '-', '.', '_', '~'}:
      add(result, s[i])
    else:
      add(result, '%')
      add(result, toHex(ord(s[i]), 2).toUpperASCII)

# trim leading and trailing, as well as collapse multiple into single
proc condense_whitespace(x:string):string=
  return strip(x).replace(re"\s+"," ")

# don't encode the slashes in the path
proc create_canonical_path(path:string):string=
  return uri_encode(path, {'/'})

# TODO - Test sigv4 with query string parameters to sign
# create the canonical querystring string
# Varriount method
proc create_canonical_qs(query: string): string =
  result = ""
  if query.len < 1:
    return result

  var queryParts = query.split("&")
  sort(queryParts, cmp[string])

  for part in queryParts:
    result.add(uri_encode(part, {'='}))

# create string to sign
# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
proc  create_string_to_sign*(scope:AwsScope,request:string):string=
  result = "$1\n$2\n$3/$4\n$5" % [alg, scope.date, $scope, term, !$request]

# create the canonical and signed headers strings
# Varriount method
proc create_canonical_and_signed_headers(headers: TableRef): (string, string) =
  # First create an ordered list of the header names
  var
    headerNames = newSeq[string](len(headers))
    index = 0

  for headerName in keys(headers):
    shallowCopy(headerNames[index], headerName)
    inc index

  sort(headerNames, cmp[string])

  # Next, create the canonical headers string and the signed headers string
  var
    canonicalHeaders = ""
    signedHeaders = ""
  for name in headerNames:
    let loweredName = toLower(name)

    signedHeaders.add(loweredName)
    canonicalHeaders.add(loweredName)
    canonicalHeaders.add(':')

    let values = headers[name]
    for value in values:
      canonicalHeaders.add(condenseWhitespace(value))

    canonicalHeaders.add("\n")
    signedHeaders.add(';')

  return (canonicalHeaders, signedHeaders[0..<signedHeaders.high])

# create the canonical request string
# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
proc create_canonical_request*(headers: var TableRef, action: string, url: string, payload: string="", unsignedPayload:bool=true, contentSha:bool=true): (string,string)=
  let
    uri = parseUri(url)
    cpath = create_canonical_path(uri.path)
    cquery = create_canonical_qs(uri.query)

  var hashload = "UNSIGNED-PAYLOAD"
  if payload.len>0 or not unsignedPayload:
    # !$a => toLowerASCII(hex(computeSHA256(a)))
    hashload = !$payload

  # add the host header for signing, will remove later so we don't have 2
  if uri.port.len > 0:
    headers["Host"] = @["$1:$2" % [uri.hostname,uri.port]]
  else:
    headers["Host"] = @[uri.hostname]
  # sometimes we don't want/need this, like for the AWS test suite
  if contentSha:
    headers["X-Amz-Content-Sha256"] = @[hashload]

  let (chead, signed) = create_canonical_and_signed_headers(headers)
  return (signed, ("$1\n$2\n$3\n$4\n$5\n$6" % [action,cpath,cquery,chead,signed,hashload]))

# create signature
proc create_signature*(key:string,sts:string):string=
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
  result = key !$ sts


# create a signing key with a lot of hashing of the credential scope
proc create_signing_key*(secret:string,scope:AwsScope,termination:string=term): string =
  # (a ?$ b) => $hmac_sha256(a,b)
  return ("AWS4"&secret) ?$ scope.date[0..7] ?$ scope.region ?$ scope.service ?$ termination
  # ? cleaner than $hmac_sha256($hmac_sha256($hmac_sha256($hmac_sha256("AWS4"&secret, date[0..7]),region),service),termination) ?

proc create_authorization_header*(id:string,scope:AwsScope,signed_head:string,sig:string,opts:(string,string)=(alg,term)):string=
  return ("$1 Credential=$2/$3/$4, SignedHeaders=$5, Signature=$6" % [opts[0],id,$scope,opts[1],signed_head,sig])

# add AWS headers, including Authorization, to the header table, return our signing key (good for 7 days with scope)
proc create_aws_authorization*(id:string,
                              key:string,
                              request:(string,string,string),
                              headers:var TableRef,
                              scope:AwsScope,
                              opts:(string,string)=(alg,term)):string=

  # add our AWS date header
  # TODO - Check for existing Date or X-Amz-Date header and use that instead
  # mostly useful for testing I think
  # check for correct format or let them fail on their own?
  headers["X-Amz-Date"] = @[scope.date]

  # create signed headers and canonical request string
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  let (signed_head, canonical_request) = create_canonical_request(headers, request[0], request[1], request[2],unsignedPayload=false,true)
  # delete host header since it's added by the the httpclient.request later and having 2 Host headers is Forbidden
  headers.del("Host")

  # create string to sign
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
  #let to_sign = "$1\n$2\n$3/$4\n$5" % [opts[0], scope.date, $scope, opts[1], !$canonical_request]
  let to_sign  = create_string_to_sign(scope,canonical_request)
  # create signing key and export for caching
  # sign the string with our key
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
  let sig = create_signature(key,to_sign)

  # create AWS authorization header to add to request
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-add-signature-to-request.html
  return create_authorization_header(id,scope,signed_head,sig,opts)

# add AWS headers, including Authorization, to the header table, return our signing key (good for 7 days withi scope)
proc create_aws_authorization*(creds:AwsCredentials,
                              request:(string,string,string),
                              headers:var TableRef,
                              scope:AwsScope,
                              opts:(string,string)=(alg,term)):string=

  result = create_signing_key(creds[1],scope,opts[1])
  # add AWS authorization header
  # http://docs.aws.amazon.com/general/latest/gr/sigv4-add-signature-to-request.html
  headers["Authorization"] = @[create_aws_authorization(creds[0],result,request,headers,scope,opts)]
  
