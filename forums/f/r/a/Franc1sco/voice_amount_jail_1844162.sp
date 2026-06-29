#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <voiceannounce_ex>
#include <basecomm>

new bool:pasado = true;

public Plugin:myinfo =
{
	name = "SM Voice Amount",
	author = "Franc1sco steam: franug",
	description = "Prevents lag when everyone talks at once",
	version = "v1.1 jail",
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_voiceamount_version", "v1.1 jail", _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("round_start", Event_Round_Start);
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) 
{
	pasado = false;
	CreateTimer(30.0, pasadotiempo);
}

public Action:pasadotiempo(Handle:timer)
{
	pasado = true;
}

public bool:OnClientSpeakingEx(client)
{	
		if(BaseComm_IsClientMuted(client))
			return false;

		if(pasado)
			return true;

		if(GetClientTeam(client) == 3)
			return true;

		new speaking = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && IsClientSpeaking(i) && !BaseComm_IsClientMuted(i) && GetClientTeam(i) == 3)
			{
				++speaking;
			}
		}
		if(speaking > 0)
		{
			BaseComm_SetClientMute(client, true);
			CreateTimer(1.0, desmute, client);
			PrintHintText(client, "Now your voice has been blocked because a CT is speaking");
			return false;
		}
		else 
			return true;
}

public Action:desmute(Handle:timer, any:client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) &&	BaseComm_IsClientMuted(client))
		BaseComm_SetClientMute(client, false);
}

