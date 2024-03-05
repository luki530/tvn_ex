FROM jenkins/jenkins:lts

USER root

RUN apt-get update && apt-get install jq -y && apt-get install gettext-base -y && apt-get install maven -y

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install