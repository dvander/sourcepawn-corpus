#pragma semicolon 1

#define PLUGIN_AUTHOR "DeathChaos25"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "[L4D2] Incap Survivor Tank Punch FLY", 
	author = PLUGIN_AUTHOR, 
	description = "Allows survivors to be sent flying if punched by a tank while incapped", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=264599"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_tank_incap_fix", PLUGIN_VERSION, "[L4D2] Incap Tank Punch Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	HookEvent("player_hurt", PlayerHurt_Event);
}

public PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsSurvivor(victim))
	{
		return;
	}
	
	new String:Weapon[256];
	GetEventString(event, "weapon", Weapon, 256);
	if (StrEqual(Weapon, "tank_claw"))
	{
		if (IsIncaped(victim))
		{
			new incaps = GetEntProp(victim, Prop_Send, "m_currentReviveCount");
			new damage = GetEventInt(event, "health");
			SetIncapState(victim, 0);
			SetEntProp(victim, Prop_Send, "m_currentReviveCount", incaps);
			SetHealth(victim, 1);
			new Handle:pack = CreateDataPack();
			WritePackCell(pack, incaps);
			WritePackCell(pack, damage);
			WritePackCell(pack, GetClientUserId(victim));
			CreateTimer(0.1, DamageDelay, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		}
	}
}

public Action:DamageDelay(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new incaps = ReadPackCell(pack);
	new damage = ReadPackCell(pack);
	new victim = GetClientOfUserId(ReadPackCell(pack));
	if (!IsSurvivor(victim))
	{
		return;
	}
	SetIncapState(victim, 1);
	SetEntProp(victim, Prop_Send, "m_currentReviveCount", incaps);
	SetHealth(victim, damage);
	SetEntProp(victim, Prop_Send, "m_bIsOnThirdStrike", 0);
}

// stock bools
stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

stock bool:IsInfected(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1)
	{
		return true;
	}
	return false;
}

stock bool:IsIncaped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}

stock SetIncapState(client, isIncapacitated)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", isIncapacitated);
}

stock SetHealth(client, health)
{
	SetEntProp(client, Prop_Send, "m_iHealth", health);
} 