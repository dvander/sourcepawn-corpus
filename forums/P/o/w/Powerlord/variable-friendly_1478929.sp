/* Plugin Template generated by Pawn Studio */

#pragma semicolon 1
#include <sourcemod>

new Handle:g_Cvar_FriendlyFire = INVALID_HANDLE;
new Handle:g_Cvar_DmgTaken = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Variable Friendly Fire for SM",
	author = "Powerlord, =(GrG)= Doc Holiday",
	description = "This plugin adjusts how much damage teammates take from Friendly Fire.",
	version = "1.0",
	url = "http://www.rbemrose.com/sourcemod/"
}

public OnPluginStart()
{
	g_Cvar_FriendlyFire = FindConVar("mp_friendlyfire");
	g_Cvar_DmgTaken = CreateConVar("vf_dmgtaken", "0.1", "The percentage of damage done to a teammate, expressed as a decimal. Ex: 1.0 is 100%, 0.25 is 25%. Defaults to 0.1 (10%)", _, true, 0.1, true, 1.0);
	
	HookEvent("player_hurt", PlayerHurt, EventHookMode_Pre);
	AutoExecConfig(true, "variable-friendly");
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_FriendlyFire))
	{
		new attacker = GetEventInt(event, "attacker");
		new victim = GetEventInt(event, "userid");
		
		if (IsClientInGame(attacker) && IsClientInGame(victim) && GetClientTeam(attacker) == GetClientTeam(victim))
		{
			new damage = GetEventInt(event, "dmg_health");
			new health = GetEventInt(event, "health");
			
			health += damage;
			damage = RoundToNearest(damage * GetConVarFloat(g_Cvar_DmgTaken));
			health -= damage;
			
			SetEventInt(event, "dmg_health", damage);
			SetEventInt(event, "health", health);
			
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}