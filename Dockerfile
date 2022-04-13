FROM node:14

LABEL "com.github.actions.name"="GitHub action for deploying AWS Amplify project"
LABEL "com.github.actions.description"="This action builds and deploys your AWS Amplify project"
LABEL "com.github.actions.icon"="git-commit"
LABEL "com.github.actions.color"="orange"

LABEL "repository"="https://github.com/ixxiyourworld/amplify-cli-action"
LABEL "homepage"="https://github.com/ixxiyourworld/amplify-cli-action.git"

RUN wget "http://stedolan.github.io/jq/download/linux64/jq" && chmod 755 jq

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
