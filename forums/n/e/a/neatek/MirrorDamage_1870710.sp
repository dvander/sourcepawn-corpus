// thx Sheepdude for advice
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Handle:cvar_Multiplier = INVALID_HANDLE;
new Handle:cvar_SlapPlayer = INVALID_HANDLE;
new Handle:cvar_NoticeFF = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "MirrorDamage",
	author = "Neatek",
	description = "Simple plugin for mirror friendlyfire",
	version = "1.1rc",
	url = "http://www.neatek.ru/"
};

public OnPluginStart()
{
	CreateConVar("sm_mirrordamage_version", "1.1rc", "Version of MirrorDamage plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_Multiplier = CreateConVar("sm_mirrordamage_multiplier", "0.7", "Amount of damage to inflict to attacker, def 70%", FCVAR_PLUGIN, true, 0.1);
	cvar_SlapPlayer = CreateConVar("sm_mirrordamage_slap", "0", "Slap attacker?! or just subtraction health", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_NoticeFF = CreateConVar("sm_mirrordamage_annonce", "0", "Type in chat about friendlyfire?!", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	for(new x = 1; x<=MaxClients ; x++) // updated, thx Sheepdude
	{
		if(ValidClient(x))
			SDKHook(x, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnPluginEnd() // updated, thx Sheepdude
{
	for(new x = 1; x<=MaxClients ; x++)
	{
		if(ValidClient(x))
			SDKUnhook(x, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

// try to check ;)
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!ValidClient(client) || !ValidClient(attacker) || client == attacker)
		return Plugin_Continue;

	if(GetClientTeam(client) == GetClientTeam(attacker))
	{
		if(damage > 100.0) CreateTimer(0.0, SlayTimer, attacker); // updated, thx Sheepdude
		else
		{
			new mirrordamage = (GetClientHealth(attacker)-RoundFloat((damage * GetConVarFloat(cvar_Multiplier))));
			if(mirrordamage < 0) CreateTimer(0.0, SlayTimer, attacker); // updated, thx Sheepdude
			else 
			{
				if(!GetConVarBool(cvar_SlapPlayer))
					SetEntityHealth(attacker, mirrordamage);
				else
					SlapPlayer(attacker,mirrordamage,true);
			}
		}
		
		if(GetConVarBool(cvar_NoticeFF))
			PrintToChatAll("%N attacked a teammate",attacker);

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

stock ValidClient(ok)
{
	if(0 < ok <= MaxClients && IsClientConnected(ok) && IsClientInGame(ok))
		return true;
	else return false;
}

public Action:SlayTimer(Handle:timer, any:data)
{
	ForcePlayerSuicide(data);
}