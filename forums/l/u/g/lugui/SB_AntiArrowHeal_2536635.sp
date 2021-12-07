#include <sdkhooks>
#include <sourcebans>

public Plugin myinfo = 
{
	name = "Anti-HealingArrows",
	author = "lugui",
	description = "Ban or kick players who use this cheat based healing arrow exploit",
	version = "1.0.1",
	url = ""
};

new Handle: bantime
int sb;

public OnPluginStart(){

bantime =  CreateConVar("sm_aha_bantime", "0", "Amount of time to ban. Default: 0. -1: kick.", 0, true, -1.0, false, 0.0);
}

public OnAllPluginsLoaded()
{
	if (FindConVar("sb_version") != INVALID_HANDLE)
		 sb = 1;
	else
	sb = 0;
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnEntityCreated(Ent, const char[] cls)//Hooks damage taken for buildings
{
	if(StrEqual(cls, "obj_sentrygun") || StrEqual(cls, "obj_dispenser") || StrEqual(cls, "obj_teleporter")){
		SDKHook(Ent, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(victim, &attacker, &inflictor, float &damage, &damagetype)
{
	
	if (damage < 0){
		char sWeapon[32];
		GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, " tf_weapon_compound_bow "))
			HandlePlayer(attacker);
	}
	return Plugin_Continue;
}

HandlePlayer(int client)
{
	int time = GetConVarInt(bantime);
	if(time < 0)
		KickClient(client, "Healing Arrow exploit");
	else{
	if(sb)
		SourceBans_BanPlayer(0, client, time, "Healing Arrow exploit");
	else
		BanClient(client, time, BANFLAG_AUTO, "Healing Arrow exploit", "Healing Arrow exploit", "HealingAroow", client); // just to be sure
	}
}






