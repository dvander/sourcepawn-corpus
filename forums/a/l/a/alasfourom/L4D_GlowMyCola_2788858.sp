#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "L4D Glow My Cola",
	author = "alasfourom",
	description = "Glowing The Cola",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2788693#post2788693"
};

public void OnPluginStart()
{
	HookEvent("weapon_drop", Event_OnWeaponDrop);
}

void Event_OnWeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
	int entity = -1;
	entity = FindEntityByClassname(entity, "weapon_cola_bottles");
	
	if (!IsValidEntity(entity))return;
	
	AcceptEntityInput(entity, "StartGlowing");
	SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
	SetEntProp(entity, Prop_Send, "m_nGlowRange", 10000);
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (255 * 65536));
	SetEntProp(entity, Prop_Send, "m_bFlashing", true);
	return;
}