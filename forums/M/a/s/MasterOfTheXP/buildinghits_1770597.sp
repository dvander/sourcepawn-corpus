#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "Hitsounds for Buildings",
	author = "MasterOfTheXP",
	description = "Let's do the fork in the garbage disposal!",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

public OnEntityCreated(Ent, const String:cls[])
{
	if (StrEqual(cls, "obj_sentrygun") || StrEqual(cls, "obj_dispenser") || StrEqual(cls, "obj_teleporter")/* || StrEqual(cls, "obj_attachment_sapper")*/)
		SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(Ent, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (!IsValidClient(attacker)) return Plugin_Continue;
	if (IsFakeClient(attacker)) return Plugin_Continue;
	new Handle:fakeEvent = CreateEvent("npc_hurt", true);
	SetEventInt(fakeEvent, "attacker_player", GetClientUserId(attacker));
	SetEventInt(fakeEvent, "entindex", Ent);
	new dmg = RoundFloat(damage), activeWep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"), idx;
	if (IsValidEntity(activeWep)) idx = GetEntProp(activeWep, Prop_Send, "m_iItemDefinitionIndex");
	if (idx == 153) dmg *= 2;
	if (idx == 441 || idx == 442 || idx == 588) dmg = RoundFloat(float(dmg) * 0.2);
	SetEventInt(fakeEvent, "damageamount", dmg);
	FireEvent(fakeEvent);
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}