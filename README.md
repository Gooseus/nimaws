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
* Cache the signing key on the client and check for signing key expiration to recreate key

## Modules

This nimble package contains a few modules that may be of use for different types of development:

### sigv4.nim

Module for creating AWS Signatures (Version 4) based on their [insanely detailed and tedious process](http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).

Provides procedures for creating a signing key and for adding the full AWS authorization (and other required keys) to a table of headers.

The key used for signing requests uses the region, service, date and access secret can be cached for 7 days after creation.

### awsclient.nim

Module provides an inheritable AwsClient object type and constructor procedure which takes a set of AWS Credentials (Access ID and Secret) the client will be operating as and a Scope (Date, Region and Service) the client will be operating under.

A request procedure takes an AwsClient and set of request parameters, signs the request and returns a Future[AsyncResponse] like  AsyncHttpClient.request.

### s3client.nim

Helper module and example of building up a service specific using the awsclient.nim module.  Provides an S3Client (inherited from AwsClient) and constructor which takes credentials and a region.

S3Client type has methods get_object(bucket,path) and put_object(bucket,path,payload) which should do exactly what they say

## Examples

Some examples are provided with [s3_put_object.nim](./s3_put_object.nim) which uses the core AwsClient type and [s3_get_object.nim](s3_get_object.nim),[s3_list_objects.nim](s3_list_objects.nim),[s3_list_buckets.nim](s3_list_buckets.nim) which utilize the S3Client helper type.

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

