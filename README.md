# terraform-aws-alb-lambda-nginx
For security reasons, when running this you need to create your key pair manually inside AWS on the EC2 dashboard and name it "ubuntu".

Use the following command to work inside the path of your visual studio code while also using a container to run commands, essentially working on Linux while on your regular desktop:
docker run -it --rm -v ${PWD}:/work -w /work --entrypoint /bin/sh amazon/aws-cli:2.0.43
You can install the things you usually work with and then commit that image and work with that.

# some handy tools
sudo apt install -y jq gzip nano tar git unzip wget docker.io epel-release ansible