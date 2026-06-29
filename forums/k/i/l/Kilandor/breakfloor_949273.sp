#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"
public Plugin:myinfo = 
{
	name = "[TF2]Breakfloor",
	author = "Kilandor",
	description = "Restricts players to scout only, but provides unlimted scout ammo.",
	version = PLUGIN_VERSION,
	url = "http://www.lankillers.com/"
};
//Sounds
#define SOUND_RELOAD "items/gunpickup2.wav"

//CVars
new Handle:g_Cvar_BreakfloorEnabled, Handle:g_Cvar_BreakfloorSoundEnabled;

public OnPluginStart()
{
	CreateConVar("sm_breakfloor_version", PLUGIN_VERSION, "[TF2]Breakfloor version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_BreakfloorEnabled = CreateConVar("sm_breakfloor_enabled", "1", "Enables the breakfloor plugin", 0, false, 0.0, false, 0.0);
	g_Cvar_BreakfloorSoundEnabled = CreateConVar("sm_breakfloor_sound_enabled", "1", "Enables the reload sound", 0, false, 0.0, false, 0.0);
	if(GetConVarBool(g_Cvar_BreakfloorEnabled))
	{
		HookEvent("player_changeclass", Event_PlayerClass);
		HookEvent("player_spawn", Event_PlayerSpawn);
		CreateTimer(30.0, Timer_BreakfloorReload, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnMapStart()
{
	PrecacheSound(SOUND_RELOAD, true);
}

public Action:Timer_BreakfloorReload(Handle:timer, any:breakfloor)
{
	if(!GetConVarBool(g_Cvar_BreakfloorEnabled))
	{
		return Plugin_Handled;
	}
	BreakfloorReload();
	return Plugin_Handled;
}

public Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_Cvar_BreakfloorEnabled))
	{
		return;
	}
	new breakfloor_user = GetClientOfUserId(GetEventInt(event, "userid"));
	new breakfloor_user_class  = GetEventInt(event, "class");
	if(breakfloor_user_class != 1)
	{
		TF2_SetPlayerClass(breakfloor_user, TFClassType:1);
	}
	BreakfloorReload();
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_Cvar_BreakfloorEnabled))
	{
		return;
	}
	new breakfloor_user = GetClientOfUserId(GetEventInt(event, "userid"));
	if(TF2_GetPlayerClass(breakfloor_user) != TFClassType:1)
	{
		TF2_SetPlayerClass(breakfloor_user, TFClassType:1);
		if(IsPlayerAlive(breakfloor_user))
		{
			TF2_RespawnPlayer(breakfloor_user);
		}
	}
	BreakfloorReload();
}

public BreakfloorReload()
{
	new breakfloor_sound_enabled = GetConVarBool(g_Cvar_BreakfloorSoundEnabled);
	for (new i = 1; i < MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}
		SetEntData(i, FindDataMapOffs(i, "m_iAmmo") + 4, 400);
		//SetEntData(i, FindDataMapOffs(i "m_iAmmo") + 8, 400);
		if(breakfloor_sound_enabled)
		{
			EmitSoundToClient(i, SOUND_RELOAD, i);
		}
	}
}