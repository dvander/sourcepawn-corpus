#include <sourcemod>
#include <sdktools>
#include <cstrike>

new Handle:enabled;

public Plugin:myinfo = 
{
	name = "Muter",
	description = "Mutes the T's.",
	author = "The Terminator",
	version = "1.4",
	url = "www.theoutsiderz.net"
};

public OnPluginStart()
{
	enabled = CreateConVar("sm_muter_enabled", "1", "Sets the Muter plugin.");

	//Hook events
	HookEvent("round_start", Round_Start);
	HookEvent("player_death", Player_Death);
	HookEvent("player_spawn", Player_Spawn);
}

stock bool:IsEnabled(client)
{
	new num = GetConVarInt(enabled);
	
	if (num == 1) //enabled
		return true;
	else
		return false;
}

public Action:Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
			SetClientListeningFlags(i, VOICE_MUTED);
		
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
			SetClientListeningFlags(i, VOICE_NORMAL);
		
		if (IsClientConnected(i) && IsClientInGame(i) && IsClientObserver(i))
			SetClientListeningFlags(i, VOICE_MUTED);
	}
	
	PrintToChatAll("\x03 [SM] \x04 All T's have been muted!");
}

public Action:Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetClientListeningFlags(client, VOICE_MUTED);
	
	PrintToChat(client, "\x03 [SM] \x04 You have been muted!");
}

public Action:Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(client) == CS_TEAM_T) //T
		SetClientListeningFlags(client, VOICE_MUTED);
	
	if (GetClientTeam(client) == CS_TEAM_CT) //CT
		SetClientListeningFlags(client, VOICE_NORMAL);
}