FROM node:14

LABEL "com.github.actions.name"="GitHub action for deploying AWS Amplify project"
LABEL "com.github.actions.description"="This action builds and deploys your AWS Amplify project"
LABEL "com.github.actions.icon"="git-commit"
LABEL "com.github.actions.color"="orange"

LABEL "repository"="https://github.com/ixxiyourworld/amplify-cli-action"
LABEL "homepage"="https://github.com/ixxiyourworld/amplify-cli-action.git"

RUN chmod 777 /usr/local/bin
RUN yarn global add @aws-amplify/cli@latest

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

