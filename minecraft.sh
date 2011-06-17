#!/bin/bash
# Minecraft launcher script
# Written by Barret Rennie

# Begin configuration

#Path to java executable
java=""

# Name of Minecraft JAR relative to this script
jar=""

# End configuration


cd "${0%/*}"

if [ -e pidfile ]
then
	echo "The pidfile already exists, halting." >&2
	echo "Is the server already running or a backup in progress?" >&2
	exit 1
fi

echo $$ > pidfile

"$java" -Xincgc -Xmx4G -jar "$jar"

rm pidfile