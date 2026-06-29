#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "Reflect team damage",
	author = "mad_hamster",
	description = "A very simple plugint to reflect team damage (hp and armor)",
	version = PLUGIN_VERSION,
	url = "http://pro-css.co.il"
};

new Handle:slap = INVALID_HANDLE;
new Handle:slapdamage = INVALID_HANDLE;
public OnPluginStart() {
	HookEvent("player_hurt", Event_PlayerHurt);
	slap = CreateConVar("sm_reflect_slap","1","Whether or not to slap TKers")
	slapdamage = CreateConVar("sm_reflect_slap_damage","1","If 1, it will slap users for however much damage they did. Otherwise, it will slap for the amount specified in the convar.")
}


public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim   = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));

	if(   attacker > 0
	   && victim > 0
	   && IsClientInGame(attacker)
	   && IsClientInGame(victim)
	   && GetClientTeam(attacker) == GetClientTeam(victim)
	   && IsPlayerAlive(attacker)
	   && victim != attacker)
	{
		new curr_hp    = GetClientHealth(attacker);
		new dmg_hp     = GetEventInt(event, "dmg_health");
		if (dmg_hp >= curr_hp)
			ForcePlayerSuicide(attacker);
		else if (GetConVarInt(slap) == 1 && GetConVarInt(slapdamage) == 1){
		SlapPlayer(attacker, dmg_hp, true);
		}else if (GetConVarInt(slap) == 0 && GetConVarInt(slapdamage) == 1){
		SetEntityHealth(attacker, curr_hp - dmg_hp);
		}
		else if(GetConVarInt(slap) == 1 && GetConVarInt(slapdamage) != 1){
		SlapPlayer(attacker, GetConVarInt(slapdamage), true);
		}
		else if(GetConVarInt(slap) == 0 && GetConVarInt(slapdamage) != 1){
		if(GetConVarInt(slapdamage) >= curr_hp){
		ForcePlayerSuicide(attacker);
		}else{
		SetEntityHealth(attacker, curr_hp - GetConVarInt(slapdamage))
		}}

		new curr_armor = GetClientArmor(attacker);
		new dmg_armor  = GetEventInt(event, "dmg_armor");
		if (dmg_armor >= curr_armor)
			SetEntProp(attacker, Prop_Send, "m_ArmorValue", 0, 1);
		else SetEntProp(attacker, Prop_Send, "m_ArmorValue", curr_armor - dmg_armor, 1);
		
		PrintToChat(attacker, "\x01BEWARE! \x03You're attacking a teammate! Reduced \x01%d\x03 HP and \x01%d\x03 armor.", dmg_hp, dmg_armor);	}
}
