/*
	Simple Player Counter
	Written by almostagreatcoder (almostagreatcoder@web.de)

	Licensed under the GPLv3
	
	This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/
	
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.5.3"

new String:countPlayersFile[PLATFORM_MAX_PATH];
new String:listPlayersFile[PLATFORM_MAX_PATH];
new String:idleFile[PLATFORM_MAX_PATH];
new Handle:countPlayersFileCvar = INVALID_HANDLE;
new Handle:listPlayersFileCvar = INVALID_HANDLE;
new Handle:idleFileCvar = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "Simple Player Counter and Idle Indicator",
	author      = "almostagreatcoder",
	description = "Writes information about connected players to configurable files",
	version     = PLUGIN_VERSION,
	url 		= "https://github.com/almostagreatcoder/simple_player_counter"
};

public OnPluginStart() {
	CreateConVar("sm_spc_version", PLUGIN_VERSION, "Simple Player Counter version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	countPlayersFileCvar = CreateConVar("sm_spc_countplayersfile", "numberofplayers.txt", "Name of the file that keeps track of the number of current players. Leave empty if no file should be written.");
	listPlayersFileCvar = CreateConVar("sm_spc_listplayersfile", "listofplayers.txt", "Name of the file that will list the current player names. Leave empty if no file should be written.");
	idleFileCvar = CreateConVar("sm_spc_idlefile", "idlenow.txt", "Name of the file that indicates that there are no players on the server. Leave empty if no file should be written.");
	HookConVarChange(countPlayersFileCvar, CvarChanged);
	HookConVarChange(listPlayersFileCvar, CvarChanged);
	HookConVarChange(idleFileCvar, CvarChanged);
	AutoExecConfig(true);
	CvarChanged(null, NULL_STRING, NULL_STRING);
}

/* Read CVars to plugin vars and erase old file */
public CvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	GetConVarString(countPlayersFileCvar, countPlayersFile, PLATFORM_MAX_PATH);
	GetConVarString(listPlayersFileCvar, listPlayersFile, PLATFORM_MAX_PATH);
	GetConVarString(idleFileCvar, idleFile, PLATFORM_MAX_PATH);
	if (strlen(oldVal) > 0) DeleteFile(oldVal);
	ProcessNoOfClients();
}

public OnClientPutInServer(client)
{
	ProcessNoOfClients();
}

public OnClientDisconnect(client)
{
	ProcessNoOfClients(client);
}

public OnPluginEnd()
{
	CleanUpFiles();
}

/* Store number of players and idle indicator file */
ProcessNoOfClients(DisconnectClient = 0)
{
	// determine number of players
	new NoOfPlayers = 0;
	for (new i = 1; i <= MaxClients; i++) {
		if (i != DisconnectClient && IsClientConnected(i) && !IsFakeClient(i)) {
			NoOfPlayers++;
		}
	}
	
	// write number of clients to file if there is a file name
	if (strlen(countPlayersFile) > 0) {
		new String:NoOfPlayersString[10];
		IntToString(NoOfPlayers, NoOfPlayersString, sizeof(NoOfPlayersString));
		new Handle:countPlayersFileHandle = OpenFile(countPlayersFile, "w");
		WriteFileLine(countPlayersFileHandle, NoOfPlayersString);
		CloseHandle(countPlayersFileHandle);
	}
	
	// list player names to file if there is a file name
	if (strlen(listPlayersFile) > 0) {
		new Handle:listPlayersFileHandle = OpenFile(listPlayersFile, "w");
		new String:FileLine[74];
		new Counter = 1;
		for (new i = 1; i <= MaxClients; i++) {
			if (i != DisconnectClient && IsClientConnected(i) && !IsFakeClient(i)) {
				Format(FileLine, sizeof(FileLine), "%d. %L", Counter, i);
				WriteFileLine(listPlayersFileHandle, FileLine);
				Counter++;
			}
		}
		CloseHandle(listPlayersFileHandle);
	}
	
	// handle idle indicator file 
	if (strlen(idleFile) > 0) {
		if (NoOfPlayers > 0) {
			DeleteFile(idleFile);
		} else {
			new Handle:idleFileHandle = OpenFile(idleFile, "w");
			WriteFileLine(idleFileHandle, "0");
			CloseHandle(idleFileHandle);
		}
	}

}

/* Erases all files */
CleanUpFiles()
{
	DeleteFile(countPlayersFile);
	DeleteFile(listPlayersFile);
	DeleteFile(idleFile);
}


