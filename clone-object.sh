#!/bin/bash

typeset -rx SSH_OPTS='
  -o CheckHostIP=no
  -o StrictHostKeyChecking=no
  -o ConnectTimeout=5
  -o ConnectionAttempts=3
  -o PasswordAuthentication=no
'

function die () { 
  printf "\nERROR: %s\n\n" "$@"
  exit 1
}

# Usage Funtion
function printUsage () {
   printf "\nUsage: $(basename $0) -o {data-group,rule} -s <SOURCE_OBJECT> -d <DEST_OBJECT> -S <SOURCE_F5> -D <DEST_F5>\n\n"
   printf "\t-d destination object name\n"
   printf "\t-D destination F5\n"
   printf "\t-o object type\n"
   printf "\t-s source object name\n"
   printf "\t-S source F5\n"
   printf "\n\tAll arguments are REQUIRED\n"
   printf "\n"
}

# Parse options
while getopts ":d:D:o:s:S:" Option ; do
  case $Option in
    d ) destName=${OPTARG} ;;
    D ) destF5=${OPTARG} ;;
    o ) objType=${OPTARG} ;;
    s ) sourceName=${OPTARG} ;;
    S ) sourceF5=${OPTARG} ;;
    * ) printUsage && exit ;;
  esac
done

# Verify options were passed, and valid
[[ -z $destName ]]   && printUsage && die "Missing destination object"
[[ -z $sourceName ]] && printUsage && die "Missing source object"
[[ -z $sourceF5 ]]   && printUsage && die "Missing source F5"
[[ -z $destF5 ]]     && printUsage && die "Missing destination F5"
[[ ! $objType =~ 'data-group|rule' ]] && printUsage && die "Invalid object type: $objType"

# Build tmsh list command
if [ "$objType" == "data-group" ] ; then
  listCmd="tmsh list ltm data-group internal $sourceName"
elif [ "$objType" == "rule" ] ; then
  listCmd="tmsh list ltm rule $sourceName"
else printUsage && exit
fi


# Get object from LTM
ssh $SSH_OPTS $sourceF5 "$listCmd" > /tmp/$destName || \
  die "Failed to get $sourceName from $sourceF5"

# Rename object
sed -i "s/${sourceName}/${destName}/g" /tmp/$destName || \
  die "Failed to replace $sourceName with $destName in /tmp/$destName"

# Upload new object to F5
rsync -a /tmp/${destName} ${destF5}:/tmp/ || \
  die "Failed to upload /tmp/${destName} to ${destF5}:/tmp/"

# Verify object syntax
ssh $SSH_OPTS $destF5 "tmsh load sys config merge file /tmp/$destName verify" || \
  die "Failed to verify $destName syntax on $destF5"

# Merge object into destination F5
ssh $SSH_OPTS $destF5 "tmsh load sys config merge file /tmp/$destName" || \
  die "Failed to merge $destName into config on $destF5"

# Cleanup
rm /tmp/$destName
ssh $SSH_OPTS $destF5 "rm /tmp/$destName"
