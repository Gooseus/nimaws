# NimAWS

A collection of nim modules for integrating with AWS.  Hardly a full SDK by any measure, but a decent enough starting point for building one and doing simple integrations.

## Current Status

Very much a work in progress.  Sigv4 hasn't been tested extensively and so it'll certainly fail for certain requests.  I successfully tested simple S3 GETs and PUTs without any querystrings or complicated header parameters.

Also of note, this is my second toy project with the Nim language, so there are may be some anti-patterns and non-idiomatic styles as I'm still mostly muddling through.

### Todo

* Fix the one test written (sigv4_test.nim)
* Write tests for `tests/aws-sig-v4-test-suite/*`
* Generate or write more service specific modules from API definitions
* Make more examples for other common AWS tasks
* Better documentation of public API

### Install with Nimble

`> nimble install nimaws`

See below for an explanation of each module.

## Modules

This nimble package contains a few modules that may be of use for different types of development. *Everything is very alpha, help with testing and improvements welcome.*

* If you want to build your own AWS SDK development, you can use the `sigv4` module to help with the request signing.
* If you want to develop your own AWS service modules you can use the `awsclient` module which provides a general client for making signed requests to AWS.
* If you just want to integrate your own programs with specific AWS services, then use the module for that service (`s3client` for S3, that's it, but more to come hopefully).

See Examples section for how to use service specific modules.  Check the source code for other examples.

### sigv4.nim

Module for creating AWS Signatures (Version 4) based on their [insanely detailed and tedious process](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).

```
import nimaws/sigv4
```

**Public API**

#### [proc](./nimaws/sigv4.nim#L108) create_canonical_request\*(headers,action,url,payload,unsignedPayload,contentSha)

Return the canonical request string which is used to create the final signature (see source links) from a whole lot of request data.  Exported mostly for testing purposes.

#### [proc](./nimaws/sigv4.nim#L129) create_signing_key\*(secret,scope,termination)

Return an AWS Signature v4 signing key from the Access Secret Credentials and Credential Scope.  The key is valid for signing requests for 7 days, so this procedure should only need to be used one a week.

#### [proc](./nimaws/sigv4.nim#L135) create_aws_authorization\*(id,key,request,headers,scope,opts)

Return an AWS Authorization string from the Access ID, Signing Key, and the Scope/Request parameters.

#### [proc](./nimaws/sigv4.nim#L165) create_aws_authorization\*(credentials,request,headers,scope,opts)

Return a Signing Key and add the AWS Authorization string to the httpClient.headers.

### awsclient.nim

Module for generating and dispatching signed requests to the AWS platform.

```
import nimaws/awsclient
```

**Public API**

#### [type](./nimaws/awsclient.nim#L18) AwsClient* {.inheritable.} = object

Inheritable object type which holds the AsyncHttpClient, AwsCredentials, AwsScope and for signing and making the client requests.

#### [proc](./nimaws/awsclient.nim#L36) newAwsClient\*(credentials,region,service)

Return an AwsClient object configured with the credentials and scope.  The AwsClient has an httpClient property which is an AsyncHttpClient.

#### [proc](./nimaws/awsclient.nim#L45) request\*(client,params)

Return the Future[AsyncResponse] object for a signed request to the AWS endpoint specified by the passed Table of params.

#### [proc](./nimaws/awsclient.nim#L20) getAmzDateString\*()

Return a date string formatted for AWS (ISO 8601).

### s3client.nim

Helper module for generating signed requests specific for the S3 API.

```
import nimaws/s3client
```

**Public API**

#### [type](./nimaws/s3client.nim#L11) S3Client* = object of AwsClient

#### [proc](./nimaws/awsclient.nim#L14) newS3Client\*(credentials,region)

Return a S3Client object configured with the credentials and scope.  The S3Client object inherits from AwsClient

#### [method](./nimaws/s3client.nim#L23) get_object\*(self,bucket,path)

Downloads an S3 object from a bucket.

#### [method](./nimaws/s3client.nim#L30) put_object\*(self,bucket,path,payload)

Puts an object into an S3 bucket.

#### [method](./nimaws/s3client.nim#L39) list_objects\*(self,bucket)

List the objects in an S3 bucket. 

#### [method](./nimaws/s3client.nim#L46) list_buckets\*(self)

List buckets for an account.  You can't allow listing for only a specific set of buckets, [see here](https://stackoverflow.com/a/18956581).

## Examples

Some examples are provided:

### Setup

1.  Get Access Key Credentials (ID and Secret) from AWS
2.  Make sure these credentials have the correct policies for an S3 bucket
3.  Add these credentials to environment variables AWS_ACCESS_ID and AWS_ACCESS_SECRET
4.  Change the bucket variables in the example code to a bucket you have read/write access to

**AwsClient**

* [s3_put_object.nim](./s3_put_object.nim)

**S3Client**

* [s3_get_object.nim](./s3_get_object.nim)
* [s3_list_objects.nim](./s3_list_objects.nim)
* [s3_list_buckets.nim](./s3_list_buckets.nim)

```
> git clone https://github.com/Gooseus/nimaws
> cd nimaws
> export AWS_ACCESS_ID="Your access id"
> export AWS_ACCESS_SECRET="Your access secret"
>
> vi s3_put_object.nim; /* change bucket :wq */
> nim -c -d:ssl s3_put_object.nim
...

> echo "Test Object." | ./s3_put_object

Transfer Complete.

> vi s3_get_object.nim; /* change bucket :wq */
> nim -c -d:ssl s3_get_object.nim
...

> ./s3_get_object
Test Object.

```

