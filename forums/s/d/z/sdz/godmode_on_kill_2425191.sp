#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Godmode on kill",
	author = "Sidezz",
	description = "Gives godmode for one second upon killing a player",
	version = "1.0",
	url = "www.coldcommunity.com"
}

new bool:g_Enabled = true;
new bool:g_Godmode[MAXPLAYERS + 1] = false;
new Float:g_Length = 1.0;

new Handle:g_cvEnable = INVALID_HANDLE;
new Handle:g_cvTimer = INVALID_HANDLE;

public OnPluginStart()
{
	g_cvEnable = CreateConVar("sm_godmode_on_kill", "1", "Enables and Disabled the plugin", FCVAR_PLUGIN);
	g_cvTimer = CreateConVar("sm_godmode_on_kill_duration", "1.0", "Change how long a player should get god mode for", FCVAR_PLUGIN);
	HookEvent("player_death", playerDeath, EventHookMode_Post);
	HookConVarChange(g_cvEnable, onConfigChanged);
	HookConVarChange(g_cvTimer, onConfigChanged);
}

public onConfigChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_Enabled = GetConVarBool(g_cvEnable);
	g_Length = GetConVarFloat(g_cvTimer);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, onTakeDamage);
}

public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker")); //Alive Guy
	if(g_Enabled)
	{
		g_Godmode[client] = true;
		SetEntityRenderColor(client, 255, 0, 0, 255);
		SetEntityRenderMode(client, RENDER_GLOW);
		SetEntityRenderFx(client, RENDERFX_GLOWSHELL);
		CreateTimer(g_Length, resetGodmode, client);
	}
}

public Action:resetGodmode(Handle:timer, any:client)
{
	g_Godmode[client] = false;
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderFx(client, RENDERFX_NONE);
}

public Action:onTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(victim > 0 && victim <= MaxClients && victim != attacker && attacker > 0 && attacker <= MaxClients)
	{
		if(g_Godmode[victim])
		{
			damage = 0.0;
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}

	return Plugin_Continue;
}