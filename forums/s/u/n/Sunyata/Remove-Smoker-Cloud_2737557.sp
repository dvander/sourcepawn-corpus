#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>

ConVar g_hCvarAllow, g_hFakeplayer, g_hRealplayer;
bool g_bCvarAllow, g_bMapStarted, g_bFakeplayer, g_bRealplayer;

public Plugin myinfo = 
{
	name = "[L4D1/2] teleport Smoker Cloud",
	author = "Harry Potter + edit by sunyata",
	description = "teleport Smoker into ground when dead",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?t=318285"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2  )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	g_hCvarAllow =	CreateConVar("l4d_teleport_smokecloud_allow",	"1", "0=Plugin off, 1=Plugin on.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hFakeplayer = CreateConVar("l4d_teleport_smokecloud_ai_player", "1", "If 1, plugin will teleport Ai smoker.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hRealplayer = CreateConVar("l4d_teleport_smokecloud_real_player", "1", "If 1, plugin will teleport real smoker player too.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hFakeplayer.AddChangeHook(ConVarChanged_Cvars);
	g_hRealplayer.AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "l4d_teleport_smokecloud");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	GetCvars();
	if( g_bCvarAllow == false && bCvarAllow == true)
	{
		g_bCvarAllow = true;
		HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	}

	else if( g_bCvarAllow == true && bCvarAllow == false )
	{
		g_bCvarAllow = false;
		UnhookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	}
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bFakeplayer = g_hFakeplayer.BoolValue;
	g_bRealplayer = g_hRealplayer.BoolValue;
}

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public Action PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_bMapStarted)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!client || !IsClientInGame(client) || GetClientTeam(client) !=3 || GetEntProp(client,Prop_Send,"m_zombieClass") != 1)
		{
			return Plugin_Continue;
		}

		if( (g_bFakeplayer && IsFakeClient(client)) || (g_bRealplayer && !IsFakeClient(client)) )
		{
			float Origin[3];
			GetClientAbsOrigin(client, Origin);
			//Origin[2] += 10000.0; //to the sky - original code
			Origin[2] -=20.0; //into the ground - this mostly stops Smoker clouds and keeps all ragdolls and loot drops above ground level
			TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
					
		}
	}
	return Plugin_Continue;
}