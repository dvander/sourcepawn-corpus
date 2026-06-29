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

#define PLUGIN_VERSION "1.3.1"
#define MAX_FILE_LEN 80

#define GAME_CSTRIKE 1
#define GAME_CSGO 2
#define GAME_OTHER 3

// Plugin definitions
public Plugin:myinfo = 
{
	name = "LastMan",
	author = "dalto, G-Phoenix, Plock",
	description = "Last Man Sound",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=58539"
};

new g_soundPreference[MAXPLAYERS + 1];
new Handle:g_CvarChat = INVALID_HANDLE;
new Handle:g_CvarAnnounce = INVALID_HANDLE;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new Handle:g_CvarEnabled = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];
new String:g_soundNameCSGO[MAX_FILE_LEN];

new game;

public OnPluginStart()
{
	decl String:gameName[32];
	GetGameFolderName(gameName, sizeof(gameName));
	if (StrEqual(gameName, "cstrike", false))
		game = GAME_CSTRIKE;
	else if (StrEqual(gameName, "csgo", false))
		game = GAME_CSGO;
	else
		game = GAME_OTHER;
	
	// Before we do anything else lets make sure that the plugin is not disabled
	g_CvarEnabled = CreateConVar("sm_lastman_enable", "1", "Enables the LastMan plugin");

	// Create the rest of the g_Cvar's
	CreateConVar("sm_lastman_version", PLUGIN_VERSION, "Last Man Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CvarAnnounce = CreateConVar("sm_lastman_announce", "1", "Announcement preferences");
	g_CvarChat = CreateConVar("sm_lastman_chat", "1", "Chat preferences");
	g_CvarSoundName = CreateConVar("sm_lastman_sound", "lastman/oneandonly.mp3", "The sound to play");
	HookConVarChange(g_CvarSoundName, OnSoundChanged);
	
	// Execute the config file
	AutoExecConfig(true, "lastman");
	
	HookEvent("player_death", EventPlayerDeath);
	RegConsoleCmd("lastman", PanelLastman);
	LoadTranslations("lastman.phrases");
}

public OnMapStart()
{
	if (game == GAME_CSTRIKE || game == GAME_OTHER)
	{
		GetConVarString(g_CvarSoundName, g_soundName, MAX_FILE_LEN);
		decl String:buffer[MAX_FILE_LEN];
		PrecacheSound(g_soundName, true);
		Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
		AddFileToDownloadsTable(buffer);
	}
	else if (game == GAME_CSGO)
	{
		GetConVarString(g_CvarSoundName, g_soundNameCSGO, MAX_FILE_LEN);
		decl String:buffer[MAX_FILE_LEN];
		Format(g_soundName, sizeof(g_soundName), "%s", g_soundNameCSGO);
		Format(buffer, sizeof(buffer), "sound/%s", g_soundNameCSGO);
		PrecacheSound(buffer);
		AddFileToDownloadsTable(buffer);
	}
}

public OnSoundChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (game == GAME_CSTRIKE || game == GAME_OTHER)
	{
		decl String:buffer[MAX_FILE_LEN];
		strcopy(g_soundName, sizeof(g_soundName), newValue);
		PrecacheSound(g_soundName, true);
		Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
		AddFileToDownloadsTable(buffer);
	}
	else if (game == GAME_CSGO)
	{
		decl String:buffer[MAX_FILE_LEN];
		strcopy(g_soundNameCSGO, sizeof(g_soundNameCSGO), newValue);
		Format(g_soundName, sizeof(g_soundName), "%s", g_soundNameCSGO);
		Format(buffer, sizeof(buffer), "sound/%s", g_soundNameCSGO);
		PrecacheSound(buffer);
		AddFileToDownloadsTable(buffer);
	}
}
	
public Action:TimerAnnounce(Handle:timer, any:client)
{
	if(client && IsClientInGame(client) && !IsFakeClient(client))
	{
		PrintToChat(client, "%t", "Lastman Menu");
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
			PrintToChatAll("%t", "Lastman", clientname);
		}
		if(g_soundPreference[lastManId] && !IsFakeClient(lastManId))
		{
			decl String:buffer[MAX_FILE_LEN];
			Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
			EmitSoundToClient(lastManId, buffer);
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
		PrintToServer("%t", "Lastman Menu Cancelled", param1, param2);
}
 
//  This creates the lastman panel
public Action:PanelLastman(client, args)
{
	new String:LastManStandingSound[100];
	new String:Enable[100];
	new String:Disable[100];
	Format(LastManStandingSound,99, "%t", "Last Man Standing Sound");
	Format(Enable,99, "%t", "Enable");
	Format(Disable,99, "%t", "Disable");
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, LastManStandingSound);
	DrawPanelItem(panel, Enable);
	DrawPanelItem(panel, Disable);
 
	SendPanelToClient(panel, client, PanelHandlerLastMan, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}
