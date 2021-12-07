/*
LastMan.sp

Description:
	Plays the lastman sound when you are the last player on your team.

Versions:
	1.0
		* Initial Release
	
	1.1
		* Changed To EmitSound
		* Added a g_Cvar for removing the chat messages
		* Added a g_Cvar for removing the announcements
		* Added a g_Cvar for the filename to play
		
	1.1.1
		* Lots of code cleanup
		* Added a g_Cvar to disable the plugin
		
	1.2
		* Changed the way sound loading is managed
		* Changed the enable preference
		* Changed naming conventions
		* Removed IsAlive()
		
	1.2.1
		* Moved sound setup to OnConfigsExecuted
		* Made config file autoloaded

*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2.1"
#define MAX_FILE_LEN 80

// Plugin definitions
public Plugin:myinfo = 
{
	name = "LastMan",
	author = "dalto",
	description = "Last Man Sound",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new g_soundPreference[MAXPLAYERS + 1];
new Handle:g_CvarChat = INVALID_HANDLE;
new Handle:g_CvarAnnounce = INVALID_HANDLE;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new Handle:g_CvarEnabled = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

public OnPluginStart()
{
	// Before we do anything else lets make sure that the plugin is not disabled
	g_CvarEnabled = CreateConVar("sm_lastman_enable", "1", "Enables the LastMan plugin");

	// Create the rest of the g_Cvar's
	CreateConVar("sm_lastman_version", PLUGIN_VERSION, "Last Man Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarAnnounce = CreateConVar("sm_lastman_announce", "1", "Announcement preferences");
	g_CvarChat = CreateConVar("sm_lastman_chat", "1", "Chat preferences");
	g_CvarSoundName = CreateConVar("sm_lastman_sound", "lastman/oneandonly.wav", "The sound to play");
	HookConVarChange(g_CvarSoundName, OnSoundChanged);
	
	// Execute the config file
	AutoExecConfig(true, "lastman");
	
	HookEvent("player_death", EventPlayerDeath);
	RegConsoleCmd("lastman", PanelLastman);
}

public OnConfigsExecuted()
{
	GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
	decl String:buffer[MAX_FILE_LEN];
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}

public OnSoundChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:buffer[MAX_FILE_LEN];
	strcopy(g_soundName, sizeof(g_soundName), newValue);
	PrecacheSound(g_soundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	AddFileToDownloadsTable(buffer);
}
	
public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		PrintToChat(client, "Say !lastman or /lastman to configure the last man standing sound");
	}
}

// When a new client is authorized we reset sound preferences
// and let them know how to turn the sounds on and off
public OnClientAuthorized(client, const String:auth[])
{
	if(client && !IsFakeClient(client))
	{
		g_soundPreference[client] = 1;
		if(GetConVarBool(g_CvarAnnounce))
		{
			CreateTimer(30.0, TimerAnnounce, client);
		}
	}
}

// The death event
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_CvarEnabled))
	{
		return;
	}
	
	new victimId = GetEventInt(event, "userid");

	new victimClient = GetClientOfUserId(victimId);

	new killedTeam = GetClientTeam(victimClient);

	new playersConnected = GetMaxClients();

	// We check to see if there is only one person left.
	new lastManId = 0;
	for (new i = 1; i < playersConnected; i++)
	{
		if(IsClientInGame(i))
		{
			if(killedTeam==GetClientTeam(i) && IsPlayerAlive(i))
			{
				if(lastManId)
				{
					lastManId = -1;
				} else {
					lastManId = i;
				}
			}
		}
	}
	
	// If there is only person left than we play a sound and print a message
	if(lastManId > 0)
	{
		new String:clientname[64];
		GetClientName(lastManId, clientname, sizeof(clientname));
		if(GetConVarBool(g_CvarChat))
		{
         if (GetClientTeam(lastManId) == 3)
         {
            PrintToChatAll("%s is the last CT standing", clientname);
            PrintCenterTextAll("%s is Last CT", clientname);
         }
         else if (GetClientTeam(lastManId) == 2)
         {
            PrintToChatAll("%s is the last T standing", clientname);
            PrintCenterTextAll("%s is Last T", clientname);
         }
		}
		if(g_soundPreference[lastManId] && !IsFakeClient(lastManId))
		{
			EmitSoundToClient(lastManId, g_soundName);
		}
	}

}

//  This sets enables or disables the sounds
public PanelHandlerLastMan(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
		if(param2 == 2)
			g_soundPreference[param1] = 0;
		else
			g_soundPreference[param1] = param2;
	else if(action == MenuAction_Cancel)
		PrintToServer("Client %d's Last Man menu was cancelled.  Reason: %d", param1, param2);
}
 
//  This creates the lastman panel
public Action:PanelLastman(client, args)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Last Man Standing Sound");
	DrawPanelItem(panel, "Enable");
	DrawPanelItem(panel, "Disable");
 
	SendPanelToClient(panel, client, PanelHandlerLastMan, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}