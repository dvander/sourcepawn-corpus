#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:g_hCheckTimer[MAXPLAYERS + 1];		// Handle with timer for each player

new Handle:g_blockmicenabled = INVALID_HANDLE;
new Handle:g_blockmicunmute = INVALID_HANDLE;

static bool Mutedmic[MAXPLAYERS + 1]  = false;

public Plugin:myinfo =
{
	name = "Mute non-push to talker players",
	author = "Magical",
	description = "Mutes players who have always turned on microphone",
	version = "1.1",
	url = ""
};

public OnPluginStart()
{
	g_blockmicenabled = CreateConVar("sm_blockmic_enabled", "1", "Blocks all players microphones who not set to push to talk mode.", FCVAR_PLUGIN,true,0.00,true,1.00);
	g_blockmicunmute = CreateConVar("sm_blockmic_unmute", "1", "Unmute players' microphone if they changed to push-to-talk mode style.", FCVAR_PLUGIN,true,0.00,true,1.00);
}

public OnClientPutInServer(client) {
	if ((IsFakeClient(client) || (GetConVarInt(g_blockmicenabled)) == 0 ))
		return;
	if (Mutedmic[client])
		Mutedmic[client] = false;
	if (g_hCheckTimer[client] == INVALID_HANDLE)
		g_hCheckTimer[client] = CreateTimer(10.0, Recheck, client, TIMER_REPEAT);
	QueryClientConVar(client, "voice_vox", ConVarQueryFinished:CheckMicrophone);
}

public Action:Recheck(Handle:timer, any:client)
{
	if ((GetConVarInt(g_blockmicenabled) > 0) && (IsValidClient(client)))
	{
		QueryClientConVar(client, "voice_vox", ConVarQueryFinished:CheckMicrophone);
	}
	else
	{
		g_hCheckTimer[client] = INVALID_HANDLE;
		KillTimer(timer);
	}
}
public CheckMicrophone(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (GetConVarInt(g_blockmicenabled))
	{
		if (!StrEqual(cvarValue, "0", false))
		{
			if (!Mutedmic[client])
			{
				ServerCommand("sm_mute #%i", GetClientUserId(client));
				PrintToServer("Muted Player's Microphone.");
				PrintToChatAll("Muted Player's Microphone.");
				PrintToChat(client, "Your microphone is muted. Please make your microphone push to talk to use it!");
				Mutedmic[client] = true;
			}
		}
		else
		{
			if (GetConVarInt(g_blockmicunmute))
			{
				if (Mutedmic[client])
				{
					ServerCommand("sm_unmute #%i", GetClientUserId(client));
					PrintToServer("Unmuted Player's Microphone.");
					PrintToChatAll("Unmuted Player's Microphone.");
					PrintToChat(client, "Your microphone is not unmuted.");
					Mutedmic[client] = false;
				}
			}		
		}
	}
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	//if (!IsPlayerAlive(client))
		//return false;

	if (!IsValidEntity(client))
		return false;

	return true;
}

