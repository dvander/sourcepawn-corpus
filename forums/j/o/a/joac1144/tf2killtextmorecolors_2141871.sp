#include <sourcemod>
#include <morecolors>

public Plugin:myinfo =
{
	name = "Kill Text",
	author = "joac1144/Zyanthius",
	description = "Kill text",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:clientName[MAX_NAME_LENGTH];
	new String:killerName[MAX_NAME_LENGTH];
	new String:sWeapon[32];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientName(killer, killerName, sizeof(killerName));
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon)); //Get's the weapon that was used to kill
	
	if(StrEqual(sWeapon, "tf_weapon_flamethrower"))  // if(StrEqual(sWeapon, "-weapon name-"))
	{
		CPrintToChatAll("{green}%s {lightgreen}was burned to death by {green}%s", clientName, killerName);
	}
	else if(StrEqual(sWeapon, "tf_weapon_bat"))
	{
		CPrintToChatAll("{green}%s {lightgreen}was smashed down with a bat by {green}%s", clientName, killerName);
	}
	else if(StrEqual(sWeapon, "tf_weapon_grenadelauncher"))
	{
		CPrintToChatAll("{green}%s {lightgreen}got blowed up by {green}%s", clientName, killerName);
	}
}




