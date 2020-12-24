# terraform-aws-alb-lambda-nginx
For security reasons, when running this you need to create your key pair manually inside AWS on the EC2 dashboard and name it "ubuntu".

Use the following command to work inside the path of your visual studio code while also using a container to run commands, essentially working on Linux while on your regular desktop:
docker run -it --rm -v ${PWD}:/work -w /work --entrypoint /bin/sh amazon/aws-cli:2.0.43
You can install the things you usually work with and then commit that image and work with that.

# some handy tools
sudo apt install -y jq gzip nano tar git unzip wget docker.io epel-release ansible

Use aws configure to configure your access key and secret key, and region (mine is ap-southeast-2)

If you are setting up a container to work in with the image given above, you'll need to install terraform in it (after installing all the essentials I used docker commit so I can continously set up and rm the container when I'm working)

# Get Terraform

curl -o /tmp/terraform.zip -LO https://releases.hashicorp.com/terraform/0.14.3/terraform_0.14.3_linux_amd64.zip
unzip /tmp/terraform.zip
chmod +x terraform && mv terraform /usr/local/bin/


terraform init
terraform plan
terraform apply