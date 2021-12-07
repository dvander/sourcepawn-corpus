#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Your Eternal BOMBONOMICON",
	author = "FlaminSarge",
	description = "Fixes YER with Bombonomicon",
	version = PLUGIN_VERSION,
	url = ""
}
new bool:damagecustominotd;
public OnPluginStart()
{
	CreateConVar("yerbomb_version", PLUGIN_VERSION, "[TF2] YERBombonomicon Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client)) OnClientPutInServer(client);
	}
	damagecustominotd = (GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD") == FeatureStatus_Available);
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	new custom = -1;
	if (damagecustominotd) custom = damagecustom;
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!IsValidClient(attacker)) return Plugin_Continue;
	if (weapon <= MaxClients || !IsValidEntity(weapon)) return Plugin_Continue;
	new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (index != 225 && index != 574) return Plugin_Continue;
	new health = GetClientHealth(client);
	if (damage >= health) RemoveBombonomicon(client);
	if (custom == TF_CUSTOM_BACKSTAB) RemoveBombonomicon(client);
	return Plugin_Continue;
}
stock RemoveBombonomicon(client)
{
	new edict = MaxClients+1;
	while ((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx == 583 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
/*		decl String:adminname[32];
	//	decl String:auth[32];
		decl String:name[32];
		new AdminId:admin;
		GetClientName(client, name, sizeof(name));
	//	GetClientAuthString(client, auth, sizeof(auth));
		if (strcmp(name, "replay", false) == 0 && IsFakeClient(client)) return false;
		if ((admin = GetUserAdmin(client)) != INVALID_ADMIN_ID)
		{
			GetAdminUsername(admin, adminname, sizeof(adminname));
			if (strcmp(adminname, "Replay", false) == 0 || strcmp(adminname, "SourceTV", false) == 0) return false;
		}*/
	}
	return true;
}