#pragma semicolon 1
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <voiceannounce_ex>

IsSpeaking[MAXPLAYERS+1] = 0;
HLDJ[MAXPLAYERS+1] = 0;

public Plugin myinfo = 
{
	name = "HLDJ Vote Mute",
	author = "Mr.Derp",
	description = "Votemutes HLDJ Players",
	version = PLUGIN_VERSION,
	url = "skynetgaming.net"
};

public void OnPluginStart()
{
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Post);
	CreateConVar("hldjvote_version", PLUGIN_VERSION, "HLDJ Vote Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnMapEnd()
{
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		HLDJ[i] = 0;
	}
}

public Action:PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new clientid = GetEventInt(event,"userid"); 
	new client = GetClientOfUserId(clientid); 
	IsSpeaking[client] = 0;
	HLDJ[client] = 0;
}

public bool:OnClientSpeakingEx(client)
{
	if (HLDJ[client] != -1)
	{
		if (IsSpeaking[client] == 0)
		{
			QueryClientConVar(client, "voice_inputfromfile", ConVarQueryFinished:ClientConVar, client);
			IsSpeaking[client] = 1;
		} else if (HLDJ[client] == 0) {
			if (GetRandomInt(0,100) == 100)
			{
				QueryClientConVar(client, "voice_inputfromfile", ConVarQueryFinished:ClientConVar, client);
			}
		}
	}
	return true;
}

public OnClientSpeakingEnd(client)
{
	if (IsValidClient(client))
	{
		IsSpeaking[client] = 0;
	}
}

public ClientConVar(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[]) {    
	
	decl String:nick[64];
	GetClientName(client, nick, sizeof(nick));
	new Value = StringToInt(cvarValue);
	if (Value == 1 && IsClientSpeaking(client))
    {
    	if (HLDJ[client] == 0)
    	{
    		//Set 5 Second Timer
    		CreateTimer(10.0, ReCheck, client);
    		PrintToChat(client, " \x01\x0B\x07We've detected you're playing HLDJ, you have 10 seonds to stop.");
    		HLDJ[client] = 1;
    	} else if (HLDJ[client] == 1) {
			HLDJ[client] = 2;
			new clientid = GetClientUserId(client);
			ServerCommand("sm_mute #%i", clientid);
			PrintToChat(client," \x01\x0B\x07You've been muted.", clientid);
			HLDJ[client] = 3;
    	}
	}
}

public Action ReCheck(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		QueryClientConVar(client, "voice_inputfromfile", ConVarQueryFinished:ClientConVar, client);
	}
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  