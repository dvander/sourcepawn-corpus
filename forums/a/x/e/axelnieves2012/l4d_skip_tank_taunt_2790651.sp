#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

ConVar g_hAnimationPlaybackRate, g_hPluginEnabled;
float g_fAnimationPlaybackRate;
bool g_bLateLoad, g_bLeft4Dead2;

#define	L4D1_TANK	5
#define	L4D2_TANK	8

public Plugin myinfo =
{
	name = "Skip Tank Taunt",
	author = "sorallll",
	description = "",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=336707"
}


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hAnimationPlaybackRate = CreateConVar("l4d_skiptanktaunt_anim_playbackrate", "5.0", "Obstacle animation playback rate", _, true, 0.0);
	g_hPluginEnabled = CreateConVar("l4d_skiptanktaunt_enable", "1", "Enable / Disable this plugin", _, true, 0.0);
	g_hAnimationPlaybackRate.AddChangeHook(vConVarChanged);
	AutoExecConfig(true);
	
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);

	if(g_bLateLoad)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
				if ( IsFakeClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && IsPlayerTank(i) )
					SDKHook(i, SDKHook_PreThink, OnPreThink);
			}
		}
	}
}

public void OnConfigsExecuted()
{
	vGetCvars();
}

void vConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	vGetCvars();
}

void vGetCvars()
{
	g_fAnimationPlaybackRate = g_hAnimationPlaybackRate.FloatValue;
}

public void OnClientPutInServer(int client)
{
	if ( !g_hPluginEnabled )
		return;
	AnimHookEnable(client, OnTankAnimPre);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if ( !g_hPluginEnabled )
		return;
		
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			SDKUnhook(i, SDKHook_PreThink, OnPreThink);
	}
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if ( !g_hPluginEnabled )
		return;
		
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client || !IsClientInGame(client) || !IsFakeClient(client))
		return;

	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if ( !g_hPluginEnabled )
		return;
		
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 3)
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if ( !g_hPluginEnabled )
		return;
		
	if(event.GetInt("oldteam") != 3)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client)
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
}

/**
* From left4dhooks.l4d2.cfg
* ACT_TERROR_CLIMB_24_FROM_STAND	718
* ACT_TERROR_CLIMB_36_FROM_STAND	719
* ACT_TERROR_CLIMB_38_FROM_STAND	720
* ACT_TERROR_CLIMB_48_FROM_STAND	721
* ACT_TERROR_CLIMB_50_FROM_STAND	722
* ACT_TERROR_CLIMB_60_FROM_STAND	723
* ACT_TERROR_CLIMB_70_FROM_STAND	724
* ACT_TERROR_CLIMB_72_FROM_STAND	725
* ACT_TERROR_CLIMB_84_FROM_STAND	726
* ACT_TERROR_CLIMB_96_FROM_STAND	727
* ACT_TERROR_CLIMB_108_FROM_STAND	728
* ACT_TERROR_CLIMB_115_FROM_STAND	729
* ACT_TERROR_CLIMB_120_FROM_STAND	730
* ACT_TERROR_CLIMB_130_FROM_STAND	731
* ACT_TERROR_CLIMB_132_FROM_STAND	732
* ACT_TERROR_CLIMB_144_FROM_STAND	733
* ACT_TERROR_CLIMB_150_FROM_STAND	734
* ACT_TERROR_CLIMB_156_FROM_STAND	735
* ACT_TERROR_CLIMB_166_FROM_STAND	736
* ACT_TERROR_CLIMB_168_FROM_STAND	737
**/
void OnPreThink(int client)
{
	if ( !g_hPluginEnabled )
		return;
		
	switch(GetClientTeam(client) == 3 && IsPlayerAlive(client) && IsPlayerTank(client) )
	{
		case true:
		{
			switch(GetEntProp(client, Prop_Send, "m_nSequence"))
			{
				case 16, 17, 18, 19, 20, 21, 22, 23:
				{
					//PrintHintTextToAll("Changed playback rate");
					SetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", g_fAnimationPlaybackRate);
				}
			}
		}

		case false:
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	}
}

/**
* From left4dhooks.l4d2.cfg
* ACT_TERROR_HULK_VICTORY 		792
* ACT_TERROR_HULK_VICTORY_B 	793
* ACT_TERROR_RAGE_AT_ENEMY 		794
* ACT_TERROR_RAGE_AT_KNOCKDOWN	795
**/
Action OnTankAnimPre(int client, int &anim)
{
	if ( !g_hPluginEnabled )
		return Plugin_Continue;
		
	if ( !IsPlayerTank(client) || GetEntProp(client, Prop_Send, "m_isGhost") == 1 )
		return Plugin_Continue;

	if ( g_bLeft4Dead2 )
	{
		if ( L4D2_ACT_TERROR_HULK_VICTORY <= anim <= L4D2_ACT_TERROR_RAGE_AT_KNOCKDOWN )
		{
			anim = 0;
			SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0);
			//PrintHintTextToAll("Anim changed l4d2");
			return Plugin_Changed;
		}
	}
	else
	{
		if ( L4D1_ACT_TERROR_HULK_VICTORY <= anim <= L4D1_ACT_TERROR_RAGE_AT_KNOCKDOWN )
		{
			anim = 0;
			SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0);
			//PrintHintTextToAll("Anim changed l4d1");
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock bool IsPlayerTank(int client)
{
	if ( !IsValidClientAlive(client) )
		return false;
	if ( GetClientTeam(client) != 3 )
		return false;
	if ( GetEntProp(client, Prop_Send, "m_zombieClass") == (g_bLeft4Dead2?L4D2_TANK:L4D1_TANK) )
		return true;
		
	return false;
}

stock bool IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return true;
	}
	return false;
}

stock bool IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return true;
	}
	return false;
}

stock bool IsValidClientAlive(int client)
{
	if ( !IsValidClientInGame(client) )
		return false;
	
	if ( !IsPlayerAlive(client) )
		return false;
	
	return true;
}