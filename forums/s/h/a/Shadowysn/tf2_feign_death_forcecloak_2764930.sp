#define PLUGIN_NAME "[TF2] Force Feign Death"
#define PLUGIN_AUTHOR "Leonardo, Shadowysn"
#define PLUGIN_DESC "Force your Dead Ringer to activate for a TFC style feign death."
#define PLUGIN_VERSION "1.4"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=1536049"
#define PLUGIN_NAME_SHORT "Force Feign Death"
#define PLUGIN_NAME_TECH "ffd"

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_TF2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
	return APLRes_SilentFailure;
}

bool bFeignDeath[MAXPLAYERS+1] = { false, ... };

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	RegConsoleCmd("sm_ffd", Command_FeignDeath, "Force feign death (Dead Ringer only)");
}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return Plugin_Continue;
	
	if ( bFeignDeath[client] && ( GetEventInt( event, "death_flags" ) & TF_DEATHFLAG_DEADRINGER ) )
	{
		SetEventInt( event, "attacker", GetEventInt(event, "userid") );
		SetEventString( event, "weapon_logclassname", "world" );
		SetEventString( event, "weapon", "world" );
		SetEventInt( event, "customkill", TF_CUSTOM_SUICIDE );
	}
	
	return Plugin_Continue;
}

Action Command_FeignDeath(int client, int args)
{
	if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bFeignDeathReady")))
		DoTheWork(client);
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int& iButtons, int& iImpulse, float fVelocity[3], float fAngles[3], int& iWeapon)
{
	static bool bPressed[MAXPLAYERS+1];
	if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bFeignDeathReady")) && (iButtons & IN_ATTACK))
	{
		if (!bPressed[client])
			DoTheWork(client);
		bPressed[client] = true;
	}
	else
		bPressed[client] = false;
	return Plugin_Continue;
}

stock bool DoTheWork(int client)
{
	if (IsValidClient(client) && IsPlayerAliveNotGhost(client) && 
	TF2_GetPlayerClass(client) == TFClass_Spy && 
	view_as<bool>(GetEntProp(client, Prop_Send, "m_bFeignDeathReady")) && 
	!TF2_IsPlayerInCondition(client, TFCond_Cloaked))
	{
		int iHealth = GetClientHealth(client);
		SetEntityHealth(client, iHealth+125);
		
		// TF_DMG_CUSTOM_SUICIDE is 6
		int suicide_flags = GetEntProp(client, Prop_Data, "m_iSuicideCustomKillFlags");
		bFeignDeath[client] = true;
		SetEntProp(client, Prop_Data, "m_iSuicideCustomKillFlags", 6);
		DealDamage( client, 1, client, (1 << 11) ); // DMG_PREVENT_PHYSICS_FORCE
		SetEntProp(client, Prop_Data, "m_iSuicideCustomKillFlags", suicide_flags);
		bFeignDeath[client] = false;
		
		//if (iHealth > GetClientHealth(client))
			// He did a boo boo
		SetEntityHealth(client, iHealth);
		
		return true;
	}
	return false;
}

// Thanks to pimpinjuice
// http://forums.alliedmods.net/showthread.php?t=111684
void DealDamage(int victim, int damage, int attacker = 0, int dmg_type = 0)
{
	//if (!IsValidClient(victim) || !IsPlayerAliveNotGhost(victim) || damage <= 0) return;
	
	static char dmg_str[16];
	IntToString(damage, dmg_str, sizeof(dmg_str));

	int pointHurt = CreateEntityByName("point_hurt");
	if (RealValidEntity(pointHurt))
	{
		//DispatchKeyValue(victim, "targetname", "wall_hurtme");
		DispatchKeyValue(pointHurt, "DamageTarget", "!activator");
		DispatchKeyValue(pointHurt, "Damage", dmg_str);
		IntToString(dmg_type, dmg_str, sizeof(dmg_str));
		DispatchKeyValue(pointHurt, "DamageType", dmg_str);

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", (attacker > 0) ? attacker : -1, victim);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		//DispatchKeyValue(victim, "targetname", "wall_donthurtme");
		//RemoveEdict(pointHurt);
		AcceptEntityInput(pointHurt, "Kill");
	}
}

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && 
	!GetEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

bool IsPlayerAliveNotGhost(int client)
{ return (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)); }