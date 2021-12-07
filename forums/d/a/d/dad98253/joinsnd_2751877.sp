/**
 * AutoExecConfig 
 *
 * Copyright (C) 2013-2019 Impact
 * No indicated copyright on the original join sound pligin (see https://forums.alliedmods.net/showthread.php?p=552491)
 * The indicated original author is Allied Modder user r5053 (from Germany, "Send a message via Skype™ to r5053 raphael.hehl")
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>
 */

#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#include <sdktools>
#include <sdktools_sound>

#include "autoexecconfig"

#define MAX_FILE_LEN 80
Handle g_CvarSoundName = INVALID_HANDLE;
char g_soundName[MAX_FILE_LEN];

#define PLUGIN_VERSION "0.0.2"

public Plugin myinfo = 
{
	name = "Welcome Sound",
	author = "R-Hehl",
	description = "Plays Welcome Sound to connecting Players",
	version = PLUGIN_VERSION,
	url = "http://www.compactaim.de/"
}

public void OnPluginStart()
{
	bool appended;
	bool error;
	
	// Order of this is important, the setting has to be known before we set the file path
	AutoExecConfig_SetCreateDirectory(true);
	
	// We want to let the include file create the file if it doesnt exists already, otherwise we let sourcemod create it
	AutoExecConfig_SetCreateFile(true);
	
	// Set file, extension is optional aswell as the second parameter which defaults to sourcemod
	AutoExecConfig_SetFile("sm_joinsnd", "sourcemod");
	
	// Create the version cvar
	CreateConVar("sm_welcome_snd_version", PLUGIN_VERSION, "Welcome Sound Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Create the rest of the cvar's
	g_CvarSoundName = AutoExecConfig_CreateConVar("sm_join_sound", "consnd/joinserver.mp3", "The sound to play");
	SetAppend(appended);
	SetError(error);
		
	// Execute the given config
	AutoExecConfig_ExecuteFile();
		
	// Cleaning is an relatively expensive file operation
	if (appended)
	{
		PrintToServer("Some convars were appended to the config, clean it up");
		AutoExecConfig_CleanFile();
	}
	
	if (error)
	{
		PrintToServer("Non successfull result occured, last find/append result: %d, %d", AutoExecConfig_GetFindResult(), AutoExecConfig_GetAppendResult());
	}

}

public void OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	char buffer[MAX_FILE_LEN];
	if (PrecacheSound(g_soundName, true)) {
		PrintToServer("Precache of %s succesful",g_soundName);	
	} else {
		PrintToServer("Precache of %s FAILED ----",g_soundName);
	}
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	// 	PrintToServer("Adding %s to Downloads Table",buffer);
	AddFileToDownloadsTable(buffer);
}

public void OnClientPostAdminCheck(int client)
{
	EmitSoundToClient(client,g_soundName);
}

void SetAppend(bool &appended)
{
	if (AutoExecConfig_GetAppendResult() == AUTOEXEC_APPEND_SUCCESS)
	{
		appended = true;
	}
}

void SetError(bool &error)
{
	int findRes = AutoExecConfig_GetAppendResult();
	int appendRes = AutoExecConfig_GetFindResult();
	
	if ( (findRes != -1 && findRes != AUTOEXEC_APPEND_SUCCESS) ||
	     (appendRes != -1 && appendRes != AUTOEXEC_FIND_SUCCESS) )
	{
		error = true;
	}
}

