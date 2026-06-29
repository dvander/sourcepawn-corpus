#include <sdkhooks>

new CantKill[MAXPLAYERS+1] = false

new Handle:CantKill_cooldown_cvar
new Float:CantKill_Cooldown = 5.0

public Plugin:myinfo = 
{
	name = "[TF2] Kill After Spawn Cooldown",
	author = "Oshizu / Sena™ ¦",
	description = "Gives you ability to set cooldown for kills after players spawn.",
	version = "1.0",
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)
	CantKill_cooldown_cvar = CreateConVar("sm_karc_cooldown", "5.0", "How much seconds after player spawns should be able to kill again?", FCVAR_PLUGIN|FCVAR_REPLICATED)
	HookConVarChange(CantKill_cooldown_cvar, CVR_CHNG)
}

public CVR_CHNG(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue)
	CantKill_Cooldown = value
}

public OnClientPutInServer(client)
{
	CantKill[client] = false
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)  
{
	if(CantKill[attacker])
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue; 
}  

public Action:Inventory(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(CantKill_Cooldown > 0.0)
	{
		CantKill_Mode(client)
	}
	else
	{
		CantKill[client] = false
	}
}

stock CantKill_Mode(client)
{
	CantKill[client] = true
	CreateTimer(CantKill_Cooldown, ResetNoKill, client)
}

public Action:ResetNoKill(Handle:timer, any:client)
{
	CantKill[client] = false;
}