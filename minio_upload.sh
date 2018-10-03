#!/bin/bash -e
#
# Copyright 2014 Tony Burns
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


# Upload a file to AWS S3.

file="${1}"
bucket="${2}"
prefix="${3}"
region="us-east-1"
timestamp=$(date -u "+%Y-%m-%d %H:%M:%S")
signed_headers="date;host;x-amz-acl;x-amz-content-sha256;x-amz-date"

if [[ $(uname) == "Darwin" ]]; then
  iso_timestamp=$(date -ujf "%Y-%m-%d %H:%M:%S" "${timestamp}" "+%Y%m%dT%H%M%SZ")
  date_scope=$(date -ujf "%Y-%m-%d %H:%M:%S" "${timestamp}" "+%Y%m%d")
  date_header=$(date -ujf "%Y-%m-%d %H:%M:%S" "${timestamp}" "+%a, %d %h %Y %T %Z")
else
  iso_timestamp=$(date -ud "${timestamp}" "+%Y%m%dT%H%M%SZ")
  date_scope=$(date -ud "${timestamp}" "+%Y%m%d")
  date_header=$(date -ud "${timestamp}" "+%a, %d %h %Y %T %Z")
fi

payload_hash() {
  local output=$(shasum -ba 256 "$file")
  echo "${output%% *}"
}

canonical_request() {
  echo "PUT"
  echo "/${prefix}/${file}"
  echo ""
  echo "date:${date_header}"
  echo "host:${bucket}.s3.amazonaws.com"
  echo "x-amz-acl:public-read"
  echo "x-amz-content-sha256:$(payload_hash)"
  echo "x-amz-date:${iso_timestamp}"
  echo ""
  echo "${signed_headers}"
  printf "$(payload_hash)"
}

canonical_request_hash() {
  local output=$(canonical_request | shasum -a 256)
  echo "${output%% *}"
}

string_to_sign() {
  echo "AWS4-HMAC-SHA256"
  echo "${iso_timestamp}"
  echo "${date_scope}/${region}/s3/aws4_request"
  printf "$(canonical_request_hash)"
}

signature_key() {
  local secret=$(printf "AWS4${AWS_SECRET_ACCESS_KEY?}" | hex_key)
  local date_key=$(printf ${date_scope} | hmac_sha256 "${secret}" | hex_key)
  local region_key=$(printf ${region} | hmac_sha256 "${date_key}" | hex_key)
  local service_key=$(printf "s3" | hmac_sha256 "${region_key}" | hex_key)
  printf "aws4_request" | hmac_sha256 "${service_key}" | hex_key
}

hex_key() {
  xxd -p -c 256
}

hmac_sha256() {
  local hexkey=$1
  openssl dgst -binary -sha256 -mac HMAC -macopt hexkey:${hexkey}
}

signature() {
  string_to_sign | hmac_sha256 $(signature_key) | hex_key | sed "s/^.* //"
}

curl \
  -v\
  -T "${file}" \
  -H "Authorization: AWS4-HMAC-SHA256 Credential=${AWS_ACCESS_KEY_ID?}/${date_scope}/${region}/s3/aws4_request,SignedHeaders=${signed_headers},Signature=$(signature)" \
  -H "Date: ${date_header}" \
  -H "x-amz-acl: public-read" \
  -H "x-amz-content-sha256: $(payload_hash)" \
  -H "x-amz-date: ${iso_timestamp}" \
  "http://sandbox.6lines.com:9000/${bucket}/${prefix}/${file}"
