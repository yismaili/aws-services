#create a bucket

aws s3 mb s3://unique-bucket-1337 --region us-east-1

#list all buckets

aws s3 ls

#delete a bucket

aws s3 rb s3://unique-bucket-1337 --region us-east-1

#upload a file to a bucket

aws s3 cp mimi.txt s3://unique-bucket-1337/mimi.txt

#download a file from a bucket

aws s3 cp s3://unique-bucket-1337/mimi.txt mimi.txt

#delete a file from a bucket

aws s3 rm s3://unique-bucket-1337/mimi.txt

#sync a local directory to a bucket

aws s3 sync ./local-directory s3://unique-bucket-1337

#sync a bucket to a local directory

aws s3 sync s3://unique-bucket-1337 ./local-directory

#make a bucket public
aws s3api put-bucket-policy --bucket unique-bucket-1337 --policy file://bucket-policy.json

#make a bucket private
aws s3api delete-bucket-policy --bucket unique-bucket-1337


#List Objects in a Bucket

aws s3 ls s3://unique-bucket-1337

# delete a single file

aws s3 rm s3://unique-bucket-1337 --recursive

# delete a folder

aws s3 rm s3://nique-bucket-1337/folder/ --recursive

# delete an empty bucket

aws s3 rb s3://unique-bucket-1337

# delete a non-empty bucket

aws s3 rb s3://unique-bucket-1337 --force