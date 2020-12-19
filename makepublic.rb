require 'aws-sdk-s3'

Aws.config.update({
  region: 'us-east-2',
  credentials: Aws::Credentials.new(
    'AKIAQVNJDSASOPLR55E4',
    'lPyHhorRuk+znFiqe2S0pmNkGL4wJ2Xqf7xI8IMv'
  )
})
bucket_name = 'greasyfork'

s3 = Aws::S3::Resource.new
s3.bucket(bucket_name).objects.each do |object|
  puts object.key
  object.acl.put({ acl: 'public-read' })
end
