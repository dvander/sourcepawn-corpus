#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2"

new Handle:g_cvVersion = INVALID_HANDLE;
new bool:bFeignDeath[MAXPLAYERS+1] = { false, ... };

public Plugin:myinfo = {
	name = "[TF2] Force Feign Death",
	author = "Leonardo",
	description = "TFC style feign death",
	version = PLUGIN_VERSION,
	url = "http://xpenia.org"
};

public OnPluginStart()
{
	g_cvVersion = CreateConVar("sm_ffd_version", PLUGIN_VERSION, "Force Feign Death version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);
	HookConVarChange(g_cvVersion, OnConVarChanged_PluginVersion);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	RegConsoleCmd("sm_ffd", Command_FeignDeath, "Force feign death (Dead Ringer only)");
}

public OnMapStart()
	if(GuessSDKVersion()==SOURCE_SDK_EPISODE2VALVE)
		SetConVarString(g_cvVersion, PLUGIN_VERSION, true, true);

public Action:Event_PlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient))
		return Plugin_Continue;
	
	if( bFeignDeath[iClient] && ( GetEventInt( hEvent, "death_flags" ) & TF_DEATHFLAG_DEADRINGER ) )
	{
		SetEventInt( hEvent, "attacker", GetEventInt(hEvent, "userid") );
		SetEventString( hEvent, "weapon_logclassname", "world" );
		SetEventString( hEvent, "weapon", "world" );
		SetEventInt( hEvent, "customkill", TF_CUSTOM_SUICIDE );
	}
	
	return Plugin_Continue;
}

public Action:Command_FeignDeath(iClient, iArgs)
	if(DoTheWork(iClient))
		return Plugin_Handled;
	else
		return Plugin_Continue;

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	static bool:bPressed[MAXPLAYERS+1];
	if(iButtons & IN_ATTACK)
	{
		if(!bPressed[iClient])
			DoTheWork(iClient);
		bPressed[iClient] = true;
	}
	else
		bPressed[iClient] = false;
	return Plugin_Continue;
}

public OnConVarChanged_PluginVersion(Handle:hConVar, const String:sOldValue[], const String:sNewValue[])
	if(!StrEqual(sNewValue, PLUGIN_VERSION, false))
		SetConVarString(hConVar, PLUGIN_VERSION, true, true);

stock bool:DoTheWork(iClient)
{
	if(iClient>0 && iClient<=MaxClients && IsClientInGame(iClient) && IsPlayerAlive(iClient) && TF2_GetPlayerClass(iClient)==TFClass_Spy && !TF2_IsPlayerInCondition(iClient,TFCond_Cloaked))
	{
		new iHealth = GetClientHealth(iClient);
		
		bFeignDeath[iClient] = true;
		DealDamage( iClient, 1, iClient );
		bFeignDeath[iClient] = false;
		
		if(iHealth>GetClientHealth(iClient))
			// He did a boo boo
			SetEntityHealth(iClient, iHealth);
		
		return true;
	}
	return false;
}

// Thanks to pimpinjuice
// http://forums.alliedmods.net/showthread.php?t=111684
DealDamage(victim, damage, attacker = 0, dmg_type = 0)
{
	if(victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage > 0)
	{
		new String:dmg_str[16];
		IntToString(damage, dmg_str, 16);
		
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);

		new pointHurt = CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim, "targetname", "wall_hurtme");
			DispatchKeyValue(pointHurt, "DamageTarget", "wall_hurtme");
			DispatchKeyValue(pointHurt, "Damage", dmg_str);
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str);

			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt, "classname", "point_hurt");
			DispatchKeyValue(victim, "targetname", "wall_donthurtme");
			//RemoveEdict(pointHurt);
			AcceptEntityInput(pointHurt, "Kill");
		}
	}
}