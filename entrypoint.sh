#!/bin/bash -l

echo "project_dir:$1
source_dir:$2
distribution_dir:$3
build_command:$4
amplify_command:$5
env-name:$6
delete_lock:$7
amplify_cli_version:$8
amplify_arguments:$9
"

set -e

if [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$AWS_SECRET_ACCESS_KEY" ] ; then
  echo "You must provide the action with both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables in order to deploy"
  exit 1
fi

if [ -z "$AWS_REGION" ] ; then
  echo "You must provide AWS_REGION environment variable in order to deploy"
  exit 1
fi

if [ -z "$5" ] ; then
  echo "You must provide amplify_command input parameter in order to deploy"
  exit 1
fi

if [ -z "$6" ] ; then
  echo "You must provide amplify_env input parameter in order to deploy"
  exit 1
fi

if [ -z "$8" ] ; then
  echo "You must provide amplify_cli_version input parameter in order to deploy"
  exit 1
fi

# cd to project_dir if custom subfolder is specified
if [ -n "$1" ] ; then
  cd "$1"
fi

# Install amplify globally,
if [ -z $(which amplify) ] || [ -n "$8" ] ; then
  echo "Installing amplify globally"
  npm install -g @aws-amplify/cli@${8}
fi

which amplify
echo "amplify version $(amplify --version)"

case $5 in
  import)
    echo "# Start initializing Amplify environment: ${ENV}"
    ls -l ./amplify
    echo "-----"
    echo $(pwd)
echo "-----"
    STACKINFO=`cat ./amplify/team-provider-info.json | jq ".$6"`

    echo $STACKINFO

#    echo "# Importing Amplify environment: ${ENV} (amplify env import)"
#    amplify env import --name ${ENV} --config "${STACKINFO}" --awsInfo ${AWSCONFIG} --yes;
#    echo "# Initializing existing Amplify environment: ${ENV} (amplify init)"
#    [[ -z ${CATEGORIES} ]] && amplify init --amplify ${AMPLIFY} --providers ${PROVIDERS} --codegen ${CODEGEN} --yes || amplify init --amplify ${AMPLIFY} --providers ${PROVIDERS} --codegen ${CODEGEN} --categories ${CATEGORIES} --yes
#    echo "# Environment ${ENV} details:"
#    amplify env get --name ${ENV}
#    echo "# Done initializing Amplify environment: ${ENV}"
    ;;

  push)
    amplify push $9 --yes
    ;;

  publish)
    amplify publish $9 --yes
    ;;

  status)
    amplify status $9
    ;;

  configure)
    echo "Setting up environment"

    if [[ ! -e "./amplify/.config/" ]]; then
        mkdir -p ./amplify/.config/
    elif [[ ! -d "./amplify/.config/" ]]; then
        echo "'./amplify/.config/' already exists but is not a directory" 1>&2
    fi

    aws_credentials_path="$(pwd)credentials.json"
    sh -c "echo '{\"accessKeyId\":\"'$AWS_ACCESS_KEY_ID'\",\"secretAccessKey\":\"'$AWS_SECRET_ACCESS_KEY'\",\"region\":\"'$AWS_REGION'\"}' > $aws_credentials_path"
    sh -c "echo '{\"projectPath\": \"'\"$(pwd)\"'\",\"defaultEditor\":\"code\",\"envName\":\"'$6'\"}' > ./amplify/.config/local-env-info.json"
    sh -c "echo '{\"'$6'\":{\"configLevel\":\"project\",\"useProfile\":false,\"awsConfigFilePath\":\"'$aws_credentials_path'\"}}' > ./amplify/.config/local-aws-info.json"


    if [ -z "$(amplify env get --name $6 | grep 'No environment found')" ] ; then
      echo "found existing environment $6"
      amplify env pull --yes $9
    else
      echo "$6 environment does not exist, consider using add_env command instead";
      exit 1
    fi

    amplify status
    ;;

  add_env)
    AMPLIFY="{\
    \"envName\":\"$6\"\
    }"

    AWSCLOUDFORMATIONCONFIG="{\
    \"configLevel\":\"project\",\
    \"useProfile\":false,\
    \"accessKeyId\":\"$AWS_ACCESS_KEY_ID\",\
    \"secretAccessKey\":\"$AWS_SECRET_ACCESS_KEY\",\
    \"region\":\"$AWS_REGION\"\
    }"

    PROVIDERS="{\
    \"awscloudformation\":$AWSCLOUDFORMATIONCONFIG\
    }"

    amplify env add $9 --amplify "$AMPLIFY" --providers "$PROVIDERS" --yes
    amplify status
    ;;

  delete_env)
    # ACCIDENTAL DELETION PROTECTION #0: delete_lock
    if [ "$7" = true ] ; then
      echo "ACCIDENTAL DELETION PROTECTION: You must unset delete_lock input parameter for delete to work"
      exit 1
    fi

    # ACCIDENTAL DELETION PROTECTION #1: environment to be deleted cannot contain prod/release/master in its name
    if [[ ${6,,} =~ prod|release|master ]] ; then
      echo "ACCIDENTAL DELETION PROTECTION: delete command is unsupported for environments that contain prod/release/master in its name"
      exit 1
    fi

    # fill in dummy env in local-env-info so we delete current environment
    # without switch to another one (amplify restriction)
    echo '{"projectPath": "'"$(pwd)"'","defaultEditor":"code","envName":"dummyenvfordeletecurrentowork"}' > ./amplify/.config/local-env-info.json
    echo "Y" | amplify env remove "$6" $9
    ;;

  *)
    echo "amplify command $5 is invalid or not supported"
    exit 1
    ;;
esac
