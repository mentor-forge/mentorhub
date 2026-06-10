```sh
mikestorey@m5max ~ % aws codeartifact create-domain \
  --domain mentor-forge \
  --profile mentorhub-shared \
  --region us-east-1
{
    "domain": {
        "name": "mentor-forge",
        "owner": "560167829275",
        "arn": "arn:aws:codeartifact:us-east-1:560167829275:domain/mentor-forge",
        "status": "Active",
        "createdTime": "2026-06-10T11:24:25.763000-04:00",
        "encryptionKey": "arn:aws:kms:us-east-1:560167829275:key/1cccc7d9-0b63-45e3-8ca8-655a755bf295",
        "repositoryCount": 0,
        "assetSizeBytes": 0,
        "s3BucketArn": "arn:aws:s3:::assets-193858265520-us-east-1"
    }
}
mikestorey@m5max ~ % aws codeartifact create-repository \
  --domain mentor-forge \
  --repository mentorhub-pypi \
  --description "MentorHub internal PyPI + PyPI upstream" \
  --profile mentorhub-shared \
  --region us-east-1
{
    "repository": {
        "name": "mentorhub-pypi",
        "administratorAccount": "560167829275",
        "domainName": "mentor-forge",
        "domainOwner": "560167829275",
        "arn": "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-pypi",
        "description": "MentorHub internal PyPI + PyPI upstream",
        "upstreams": [],
        "externalConnections": [],
        "createdTime": "2026-06-10T11:24:52.290000-04:00"
    }
}
mikestorey@m5max ~ % aws codeartifact create-repository \
  --domain mentor-forge \
  --repository mentorhub-npm \
  --description "MentorHub internal npm + npmjs upstream" \
  --profile mentorhub-shared \
  --region us-east-1
{
    "repository": {
        "name": "mentorhub-npm",
        "administratorAccount": "560167829275",
        "domainName": "mentor-forge",
        "domainOwner": "560167829275",
        "arn": "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-npm",
        "description": "MentorHub internal npm + npmjs upstream",
        "upstreams": [],
        "externalConnections": [],
        "createdTime": "2026-06-10T11:25:03.918000-04:00"
    }
}
mikestorey@m5max ~ % aws codeartifact associate-external-connection \
  --domain mentor-forge \
  --repository mentorhub-pypi \
  --external-connection public:pypi \
  --profile mentorhub-shared \
  --region us-east-1
{
    "repository": {
        "name": "mentorhub-pypi",
        "administratorAccount": "560167829275",
        "domainName": "mentor-forge",
        "domainOwner": "560167829275",
        "arn": "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-pypi",
        "description": "MentorHub internal PyPI + PyPI upstream",
        "upstreams": [],
        "externalConnections": [
            {
                "externalConnectionName": "public:pypi",
                "packageFormat": "pypi",
                "status": "AVAILABLE"
            }
        ],
        "createdTime": "2026-06-10T11:24:52.290000-04:00"
    }
}
mikestorey@m5max ~ % aws codeartifact associate-external-connection \
  --domain mentor-forge \
  --repository mentorhub-npm \
  --external-connection public:npmjs \
  --profile mentorhub-shared \
  --region us-east-1
{
    "repository": {
        "name": "mentorhub-npm",
        "administratorAccount": "560167829275",
        "domainName": "mentor-forge",
        "domainOwner": "560167829275",
        "arn": "arn:aws:codeartifact:us-east-1:560167829275:repository/mentor-forge/mentorhub-npm",
        "description": "MentorHub internal npm + npmjs upstream",
        "upstreams": [],
        "externalConnections": [
            {
                "externalConnectionName": "public:npmjs",
                "packageFormat": "npm",
                "status": "AVAILABLE"
            }
        ],
        "createdTime": "2026-06-10T11:25:03.918000-04:00"
    }
}
```