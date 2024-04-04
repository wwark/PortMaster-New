#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
source $controlfolder/device_info.txt
get_controls

GAMEDIR=/$directory/ports/gravitycircuit

export XDG_DATA_HOME="$GAMEDIR/saves"
mkdir "$XDG_DATA_HOME"

export DEVICE_ARCH="${DEVICE_ARCH:-aarch64}"
export LD_LIBRARY_PATH="$GAMEDIR/libs.$DEVICE_ARCH:$LD_LIBRARY_PATH"

cd $GAMEDIR

if [ ! -f "$GAMEDIR/gamedata/GravityCircuitFinal.exe" ]; then

	mkdir -p "$GAMEDIR/gravitycircuitpatch"


	if [ -f "$GAMEDIR/gamedata/GravityCircuit.exe" ]; then

		# Use 7zip to extract the .exe file to the destination directory
		"$GAMEDIR/utils/unzip" "$GAMEDIR/gamedata/GravityCircuit.exe" -d "$GAMEDIR/gravitycircuitpatch/" & pid=$!

		# Wait for the extraction process to complete
		wait $pid
		
		# Remove Platform directory
		rm -rf "$GAMEDIR/gravitycircuitpatch/platform"
		
		# Remove Steam platform on Build_information_lua
		sed 's/USE_PLATFORM=*.*,//' "$GAMEDIR/gravitycircuitpatch/BUILD_INFORMATION.lua"
		
		cd "$GAMEDIR/gravitycircuitpatch/"
		"$GAMEDIR/utils/zip" -r -0 "$GAMEDIR/gamedata/GravityCircuitFinal.exe" * & pid=$!
		
		# Wait for the archive process to complete
		wait $pid
	fi

	# Delete the redundant .exe files
	rm "$GAMEDIR/gamedata/GravityCircuit.exe"

	# Delete patch directory
	rm -r "$GAMEDIR/gravitycircuitpatch"

fi

cd $GAMEDIR

exec > >(tee "$GAMEDIR/log.txt") 2>&1

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
$GPTOKEYB "love.$DEVICE_ARCH" &
./love.$DEVICE_ARCH "./gamedata/GravityCircuitFinal.exe"

$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty0
