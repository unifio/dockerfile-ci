FROM ruby:2.3

ENV PACKER_VERSION 0.10.1
ENV TERRAFORM_VERSION 0.6.16

RUN apt-get update && \
    apt-get -y install unzip && \
    curl https://keybase.io/hashicorp/key.asc | gpg --import

RUN wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" && \
    wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS" && \
    wget -q "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_SHA256SUMS.sig" && \
    gpg --batch --verify packer_${PACKER_VERSION}_SHA256SUMS.sig packer_${PACKER_VERSION}_SHA256SUMS && \
    grep packer_${PACKER_VERSION}_linux_amd64.zip packer_${PACKER_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /bin && \
    wget -q "https://circle-artifacts.com/gh/unifio/packer-post-processor-vagrant-s3/22/artifacts/0/home/ubuntu/.go_workspace/bin/packer-post-processor-vagrant-s3" && \
    wget -q "https://circle-artifacts.com/gh/unifio/packer-provisioner-serverspec/26/artifacts/0/home/ubuntu/.go_workspace/bin/packer-provisioner-serverspec" && \
    chmod +x packer-post-processor-vagrant-s3 packer-provisioner-serverspec && \
    mv packer-post-processor-vagrant-s3 packer-provisioner-serverspec /bin

RUN wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" && \
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig" && \
    gpg --batch --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS && \
    grep terraform_${TERRAFORM_VERSION}_linux_amd64.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /bin

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /packer* /terraform*

VOLUME ["/data"]
WORKDIR /data

ENTRYPOINT ["/bin/bash"]

CMD ["--help"]
