#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name		= "Player Jingle Notifier",
	author		= "FlaminSarge",
	description	= "Notifies players of those who have cl_customsounds enabled",	//Notifies clients with cl_customsounds set to 1 of other clients with the same, and prints the path of clients' custom sounds.
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?t=234354"
};

#define CANTHEAR 0
#define CANHEAR 1
#define WILLHEAR 2

#define PLUGINLOAD 0
#define SPAWN 0
#define MAPSTART 1
#define JOINED 2

new QueryCookie:qryCk[MAXPLAYERS + 1];
new String:clFile[MAXPLAYERS+1][16];
new canHearMine[MAXPLAYERS + 1][MAXPLAYERS + 1];
new bool:getjingleavailable = false;
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:err[], err_max)
{
	MarkNativeAsOptional("GetPlayerJingleFile");
	return APLRes_Success;
}
public OnAllPluginsLoaded()
{
	getjingleavailable = GetFeatureStatus(FeatureType_Native, "GetPlayerJingleFile") == FeatureStatus_Available;
}
public OnPluginStart()
{
	CreateConVar("jinglenotify_version", PLUGIN_VERSION, "Player Jingle Notifier version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	RegConsoleCmd("sm_playerjingles", Cmd_CustomSounds, "List players w/ cl_customsounds enabled. Add 'help' for more info on player jingles.");
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (IsFakeClient(client)) continue;
		if (qryCk[client] != QUERYCOOKIE_FAILED) continue;
		qryCk[client] = QueryClientConVar(client, "cl_customsounds", CustomSoundsQuery, PLUGINLOAD);
	}
	HookEvent("player_spawn", Event_player_spawn);
}
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!getjingleavailable) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client)) return Plugin_Continue;
	if (qryCk[client] != QUERYCOOKIE_FAILED) return Plugin_Continue;
	qryCk[client] = QueryClientConVar(client, "cl_customsounds", CustomSoundsQuery, SPAWN);
	return Plugin_Continue;
}
public OnMapStart()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (IsFakeClient(client)) continue;
		if (qryCk[client] != QUERYCOOKIE_FAILED) continue;
		qryCk[client] = QueryClientConVar(client, "cl_customsounds", CustomSoundsQuery, MAPSTART);
	}
}
public OnClientPutInServer(client)
{
	if (qryCk[client] == QUERYCOOKIE_FAILED) qryCk[client] = QueryClientConVar(client, "cl_customsounds", CustomSoundsQuery, JOINED);
}
public OnClientDisconnect_Post(client)
{
	qryCk[client] = QUERYCOOKIE_FAILED;
	clFile[client] = "";
}
public CustomSoundsQuery(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:value)
{
	qryCk[client] = QUERYCOOKIE_FAILED;
	if (result != ConVarQuery_Okay) return;
	new bool:on = !!StringToInt(cvarValue);
	if (!on)
	{
		NoteClientHearsJingles(client, false);
	}
	else
	{
		NoteClientHearsJingles(client, true);
		if (!getjingleavailable) return;
		if (value == MAPSTART || value == JOINED)	//update a client's file on mapchange or join only
		{
			GetPlayerJingleFile(client, clFile[client], 16);
			if (StrEqual(clFile[client], "c12cc55b", false)) clFile[client] = "";	//sound/player/jingle.wav is the "default" cl_soundfile
		}
		if (value == JOINED && clFile[client][0] != '\0')	//notify this client and others on join
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i)) continue;
				if (IsFakeClient(i)) continue;
				if (!canHearMine[client][i]) continue;	//one of these two should probably disappear, or not.
				if (!canHearMine[i][client]) continue;
				PrintToChat(i, "[SM] %N has a player jingle file (tf/sound/temp/%s.wav).", client, clFile[client]);
				if (client != i && clFile[i][0] != '\0')
				{
					PrintToChat(client, "[SM] %N has a player jingle file (tf/sound/temp/%s.wav).", i, clFile[i]);
				}
			}
		}
	}
}
stock NoteClientHearsJingles(client, bool:hears)
{
	//canHearMine[0][client] = hears ? CANHEAR : CANTHEAR;
	for (new i = 1; i <= MaxClients; i++)
	{
		canHearMine[i][client] = (hears ? CANHEAR : CANTHEAR);	//eventually detect mid-game changes and only change it once the client is supposed to have downloaded the player's sound.
	}
}
public Action:Cmd_CustomSounds(client, args)
{
	new bool:self = !!canHearMine[client][client];
	if (args > 0)	//let's assume it's "help"
	{
		ReplyToCommand(client, "[SM] Player jingles are enabled using cl_customsounds 1 in console.\ncl_soundfile \"path_to_file\" (relative to the tf/ folder) will set your jingle, which will apply on mapchange or rejoin.\nimpulse 202 will play the file. Use Source-compatible .wav files under 512KB.");
	}
	if (client != 0 || !IsDedicatedServer())
	{
		ReplyToCommand(client, "[SM] You currently have player jingles (sound sprays) %s.\nUse cl_customsounds to toggle them.", self ? "enabled" : "disabled");
	}
	if (self && clFile[client][0] != '\0')
	{
		ReplyToCommand(client, "[SM] Your jingle filename is %s.", clFile[client]);
	}
	new bool:exist = false;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == client) continue;
		if (!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		if (!canHearMine[i][i]) continue;	//used to use canHearMine[client][i], will change it back when I get to tracking who can specifically hear whose
		if (!exist)
		{
			ReplyToCommand(client, "[SM] Clients with player jingles enabled:");
			exist = true;
		}
		ReplyToCommand(client, "%N%s%s", i, clFile[i][0] != '\0' ? " - " : "", clFile[i]);
	}
	if (!exist) ReplyToCommand(client, "[SM] No clients with player jingles enabled.");
	return Plugin_Handled;
}
