# AWS Signature v4 Tests

## Write the tests

# Get Vanilla
#[ Request
    GET / HTTP/1.1
    Host:example.amazonaws.com
    X-Amz-Date:20150830T123600Z
]#
# Payload:"" ->Hash-> e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
#[ Canonical Request
GET
/

host:example.amazonaws.com
x-amz-date:20150830T123600Z

host;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
]#
# Hash -> bb579772317eb040ac9ed261061d46c1f17a8133879d6129b6e1c25292927e63
#[ String to Sign
AWS4-HMAC-SHA256
20150830T123600Z
20150830/us-east-1/service/aws4_request
bb579772317eb040ac9ed261061d46c1f17a8133879d6129b6e1c25292927e63
]#
# Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31
#[ Signed Request
    GET / HTTP/1.1
    Host:example.amazonaws.com
    X-Amz-Date:20150830T123600Z
    Authorization: AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31
 ]#
import nimaws/sigv4
import tables

type
  Test = tuple
    c_request: string
    to_sign: string
    signature: string
    authorization: string

const test_vanilla_get : Test = ("""GET
/

host:example.amazonaws.com
x-amz-date:20150830T123600Z

host;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855""",
    """AWS4-HMAC-SHA256
20150830T123600Z
20150830/us-east-1/service/aws4_request
bb579772317eb040ac9ed261061d46c1f17a8133879d6129b6e1c25292927e63""",
    "5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31",
    "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31"
  )

const
  # All tests
  protocol = "https"
  credentials = (id:"AKIDEXAMPLE", secret:"wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY")

var
  # test specific
  date = "20150830T123600Z"
  region = "us-east-1"
  service = "service"
  meth = "GET"
  url = "https://example.amazonaws.com/"
  payload = ""

var
  headers = { "X-Amz-Date": date }.newTable
  scope:AwsScope = AwsScope(date:date[0..7], region:region, service:service)
  signed_head:string
  canonical_request:string

#(signed_head,canonical_request) = create_canonical_request(headers, meth, url, payload, false, false)

discard """ let
  to_sign = create_string_to_sign(date,scope,canonical_request)
  signing_key = create_signing_key(credentials.secret,date,region,service)
  signature = create_sigv4(signing_key, to_sign)
  authorization = create_aws_authorization(credentials.id,scope,signed_head,signature)

try:
  assert(canonical_request==test_vanilla_get.c_request, "Canonical Request Incorrect.")
  assert(test_vanilla_get.to_sign==to_sign, "String to Sign Incorrect.")
  assert(signature==test_vanilla_get.signature, "Signature Incorrect.")
  assert(authorization==test_vanilla_get.authorization, "Authorization Incorrect.")
except AssertionError:
  quit("Test failed: " & getCurrentExceptionMsg())
except:
  quit("Unknown testing error: " & getCurrentExceptionMsg())
 """
echo "Tests passed!"

