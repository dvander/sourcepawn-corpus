// Version 1.0 is the release.
// Version 1.1 I added the cvar of version and FCVAR_NOTIFY for both cvars.

#include <sourcemod>
#include <sdkhooks>

new bool:Hooked[MAXPLAYERS];

new const String:PLUGIN_VERSION[] = "1.0";

public Plugin:myinfo = {
	name = "Invincible Ghosts",
	author = "Eyal282 ( FuckTheSchool )",
	description = "Ghosts are immune to death",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=304043"
};

new Handle:hConVar = INVALID_HANDLE;

new propinfoGhost;

public OnPluginStart()
{
	propinfoGhost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	hConVar = CreateConVar("invincible_ghosts_enabled", "1", "Enables / disables the plugin which stops ghosts from receiving damage", FCVAR_NOTIFY);
	CreateConVar("invincible_ghosts_version", PLUGIN_VERSION, "Version of the plugin Invincible Ghosts", FCVAR_NOTIFY);
}

public OnClientConnected(client)
{
	Hooked[client] = false;
}
public OnClientPostAdminCheck(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, Event_Hurt);
		Hooked[client] = true;
	}
}

public OnClientDisconnect(client)
{
	if(Hooked[client])
		SDKUnhook(client, SDKHook_OnTakeDamage, Event_Hurt);
}

public Action:Event_Hurt(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(victim > MaxClients || victim < 1)
		return Plugin_Continue;
		
	else if(!GetConVarBool(hConVar))
		return Plugin_Continue;
	
	else if(GetClientTeam(victim) != 3)
		return Plugin_Continue;
	
	else if(!IsClientGhost(victim))
		return Plugin_Continue;

	damage = 0.0;
	return Plugin_Changed;
}
stock IsClientGhost(client)
	return bool:GetEntData(client, propinfoGhost, 1);