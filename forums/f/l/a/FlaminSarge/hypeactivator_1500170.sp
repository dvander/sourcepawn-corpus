#pragma semicolon 1 // Force strict semicolon mode.

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_NAME		"[TF2] Hype Activator"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.04"
#define PLUGIN_CONTACT		"http://forums.alliedmods.net/"

public Plugin:myinfo =
{
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description	= PLUGIN_NAME,
	version		= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};
new Handle:hud;
new bool:bShown[MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("hypeactivator_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	LoadTranslations("common.phrases");
	hud = CreateHudSynchronizer();
}
public OnGameFrame()
{
	decl String:classname[64];
	decl String:classname2[64];
	for (new client = 1; client <= MaxClients; client++)
	{
		new bool:show = false;
		if (!IsValidClient(client)) continue;
		if (IsFakeClient(client)) continue;
		new Float:hype = GetEntPropFloat(client, Prop_Send, "m_flHypeMeter");
		if (hype >= 96.5)
		{
			strcopy(classname, sizeof(classname), "");	//clear it in case the next call fails
			GetClientWeapon(client, classname, sizeof(classname));
//			new active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
//			new primary = GetPlayerWeaponSlot(client, 0);
//			if (!(primary > MaxClients && IsValidEntity(primary) && GetEntityClassname(primary, classname, sizeof(classname)) && StrEqual(classname, "tf_weapon_soda_popper", false))) continue;
//			if (primary == active && (GetClientButtons(client) & IN_ATTACK2) && !TF2_IsPlayerInCondition(client, TFCond_CritHype))
			if (StrEqual(classname, "tf_weapon_soda_popper", false) && (GetClientButtons(client) & IN_ATTACK2) && !TF2_IsPlayerInCondition(client, TFCond_CritHype))
			{
				SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", 100.0);
				bShown[client] = true;
			}
			else
			{
				new primary = GetPlayerWeaponSlot(client, 0);
				if (!(primary > MaxClients && IsValidEntity(primary) && GetEntityClassname(primary, classname2, sizeof(classname2)) && StrEqual(classname2, "tf_weapon_soda_popper", false))) continue;
				if (hype != 96.5) SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", 96.5);
				if (StrEqual(classname, "tf_weapon_soda_popper", false) && !TF2_IsPlayerInCondition(client, TFCond_CritHype))
				{
					show = true;
				}
			}
		}
		else
		{
			bShown[client] = false;
		}
		if (show && !bShown[client])
		{
			SetHudTextParams(-1.0, 0.83, 1000.0, 255, 255, 255, 255,0,0.2,0.0,0.1);
			ShowSyncHudText(client, hud, "Press Alt-Fire to activate your Hype");
			bShown[client] = true;
		}
		else if (!show && bShown[client])
		{
			ClearSyncHud(client, hud);
			bShown[client] = false;
		}
	}
}

stock bool:IsValidClient(client)
{
	if (client < 1 || client > MaxClients)
		return false;
	return IsClientInGame(client);
}