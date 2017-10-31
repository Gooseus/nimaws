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

## Modules

This nimble package contains a few modules that may be of use for different types of development:

### sigv4.nim

Module for creating AWS Signatures (Version 4) based on their [insanely detailed and tedious process](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).

**Exports**

#### create_canonical_request([...](./nimaws/sigv4.nim#L108)) [~source](./nimaws/sigv4.nim#L108)

Return the canonical request string which is used to create the final signature (see source links) from a whole lot of request data.  Exported mostly for testing purposes.

#### create_signing_key([...](./nimaws/sigv4.nim#L129)) [~source](./nimaws/sigv4.nim#L129)

Return an AWS Signature v4 signing key from the Access Secret Credentials and Credential Scope.  The key is valid for signing requests for 7 days, so this procedure should only need to be used one a week.

#### create_aws_authorization(id,key,[...](./nimaws/sigv4.nim#L135)) [~source](./nimaws/sigv4.nim#L135)

Return an AWS Authorization string from the Access ID, Signing Key, and the Scope/Request parameters.

#### create_aws_authorization(AwsCredentials,[...](./nimaws/sigv4.nim#L165)) [~source](./nimaws/sigv4.nim#L165)

Create and return a Signing Key while adding the AWS Authorization string to the httpClient.headers

### awsclient.nim

Module provides an inheritable AwsClient object type and constructor procedure which takes a set of AWS Credentials (Access ID and Secret) the client will be operating as and a Scope (Date, Region and Service) the client will be operating under.

A request procedure takes an AwsClient and set of request parameters, signs the request and returns a Future[AsyncResponse] like  AsyncHttpClient.request.

### s3client.nim

Helper module and example of building up a service specific using the awsclient.nim module.  Provides an S3Client (inherited from AwsClient) and constructor which takes credentials and a region.

S3Client type has methods get_object(bucket,path) and put_object(bucket,path,payload) which should do exactly what they say

## Examples

Some examples are provided with [s3_put_object.nim](./s3_put_object.nim) which uses the core AwsClient type and [s3_get_object.nim](./s3_get_object.nim), [s3_list_objects.nim](./s3_list_objects.nim), [s3_list_buckets.nim](./s3_list_buckets.nim) which utilize the S3Client helper type.

```
> git clone https://github.com/Gooseus/nimaws
> cd nimaws
> export AWS_ACCESS_ID="Your access id"
> export AWS_ACCESS_SECRET="Your access secret"

** You'll also want to change the bucket variable in the example code to a bucket you have read/write access **

> nim -c -d:ssl s3_put_object
...
> echo "Test Object." | ./s3_put_object

Transfer Complete.

> nim -c -d:ssl s3_get_object
...
> ./s3_get_object
Test Object.

```

