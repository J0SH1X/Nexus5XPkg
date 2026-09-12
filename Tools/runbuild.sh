#!/bin/bash

SCRIPTNAME="runbuild.sh"
RECONFIG=FALSE
DEVBUILD=FALSE
CIBUILD=FALSE

function HelpMsg()
{
  echo "Usage: $SCRIPTNAME [Options]"
  echo
  echo "Configure EDK2 build environment, then kicks off build for Dragonboard 410c."
  echo
  echo
  echo "Options: "
  echo "  --help, -h, -?        Print this help screen and exit."
  echo
  echo "  --development, -dev   Run development build (dirty)."
  echo
  echo "  --angler, -angler       Run build for HUAWEI NEXUS 6P."
  echo
  echo "  --bullhead, -bullhead       Run build for LG NEXUS 5X."
  echo
  echo "  --production, -ci     Run CI build (clean)."
  echo
}

function SetWorkspace()
{
  #
  # If WORKSPACE is already set, then we can return right now
  #
  if [ -n "$WORKSPACE" ]
  then
    return 0
  fi

  #
  # Check for BaseTools/BuildEnv before dirtying the user's environment.
  #
  if [ ! -f BaseTools/BuildEnv ] && [ -z "$EDK_TOOLS_PATH" ]
  then
    echo BaseTools not found in your tree, and EDK_TOOLS_PATH is not set.
    echo Please point EDK_TOOLS_PATH at the directory that contains
    echo the EDK2 BuildEnv script.
    return 1
  fi

  #
  # Set $WORKSPACE
  #
  export WORKSPACE=`pwd`

  return 0
}

function SetupEnv()
{
  if [ -n "$EDK_TOOLS_PATH" ]
  then
    . $EDK_TOOLS_PATH/BuildEnv
  elif [ -f "$WORKSPACE/BaseTools/BuildEnv" ]
  then
    . $WORKSPACE/BaseTools/BuildEnv
  elif [ -n "$PACKAGES_PATH" ]
  then 
    PATH_LIST=$PACKAGES_PATH
    PATH_LIST=${PATH_LIST//:/ }
    for DIR in $PATH_LIST
    do
      if [ -f "$DIR/BaseTools/BuildEnv" ]
      then
        export EDK_TOOLS_PATH=$DIR/BaseTools
        . $DIR/BaseTools/BuildEnv
        break
      fi
    done
  else
    echo BaseTools not found in your tree, and EDK_TOOLS_PATH is not set.
    echo Please check that WORKSPACE or PACKAGES_PATH is not set incorrectly
    echo in your shell, or point EDK_TOOLS_PATH at the directory that contains
    echo the EDK2 BuildEnv script.
    return 1
  fi
}

function FixPermission()
{
  if [ -d "Nexus5XPkg" ]; then
   chmod +x Nexus5XPkg/Tools/*.sh
  fi
}

function SourceEnv()
{
  SetWorkspace &&
  SetupEnv &&
  FixPermission
}

function DevelopmentBuild()
{
    ./Nexus5XPkg/Tools/edk2-build.sh

  if [ ! $? -eq 0 ]; then
      echo "[Builder] Build failed."
      return $?
  fi
  
}

function CIBuild()
{
    ./Nexus5XPkg/Tools/edk2-build.sh

  if [ ! $? -eq 0 ]; then
      echo "[Builder] Build failed."
      return $?
  fi
  
}

while [ $# -gt 0 ]; do
  case "$1" in
    --development|-dev)
      echo "[Builder] Configure environment and run development build."
      if [ "$CIBUILD" = TRUE ]; then
        echo "[Builder] Only one build configuration can be selected."
        exit 1
      fi
      DEVBUILD=TRUE
      shift
      ;;

    --production|-ci)
      echo "[Builder] Configure environment and run CI build (clean)."
      if [ "$DEVBUILD" = TRUE ]; then
        echo "[Builder] Only one build configuration can be selected."
        exit 1
      fi
      CIBUILD=TRUE
      shift
      ;;

    --device)
      if [ -z "$2" ]; then
        echo "[Builder] Error: --device requires a device name."
        exit 1
      fi

      case "$2" in
        angler)
          echo "[Builder] Run Nexus 6P Build."
          export BUILD_ANGLER=TRUE
          ;;

        bullhead)
          echo "[Builder] Run Nexus 5X Build."
          export BUILD_BULLHEAD=TRUE
          ;;

        *)
          echo "[Builder] Error: Unknown device '$2'."
          echo "[Builder] Supported devices: angler, bullhead"
          exit 1
          ;;
      esac

      shift 2
      ;;

    -?|-h|--help)
      HelpMsg
      exit 0
      ;;

    *)
      echo "[Builder] Error: Unknown argument '$1'."
      HelpMsg
      exit 1
      ;;
  esac
done

  echo "[Builder] Configure environment."
  SourceEnv
  if [ ! $? -eq 0 ]; then
      echo "Unable to configure EDK2 environment."
      return $?
  fi

  # Run build
  if [ "$DEVBUILD" = TRUE ]; then
    DevelopmentBuild
  elif [ "$CIBUILD" = TRUE ]; then
    CIBuild
  else
    echo "[Builder] You must specify one build option."
    return 1
  fi

  if [ ! $? -eq 0 ]; then
      echo "[Builder] Build failed."
      return $?
  fi
