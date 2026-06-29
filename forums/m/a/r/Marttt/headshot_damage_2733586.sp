#include <sourcemod>
#include <sdkhooks>
#define VERSION "1.0.0"

#define TEAM_SI 3
#define TEAM_SUR 2

new Handle:l4d2_dmg_headshot_awm;
new Handle:l4d2_dmg_headshot_military;
new Handle:l4d2_dmg_headshot_hunting_rifle;
new Handle:l4d2_dmg_headshot_scout;
new Handle:l4d2_dmg_headshot_other;

public Plugin myinfo =
{
	name = "Headshot dmg",
	author = "Shady",
	description = "Thay doi damage cua sung nham",
	version = VERSION,
	url = "https://www.facebook.com/groups/l4d2steamvn"
};

public void OnPluginStart()
{
	l4d2_dmg_headshot_awm = CreateConVar("l4d2_dmg_headshot_awm","1.0", "Dmg headshot awm");
	l4d2_dmg_headshot_military = CreateConVar("l4d2_dmg_headshot_awm","1.0", "Dmg headshot sung nham 30 vien");
	l4d2_dmg_headshot_hunting_rifle = CreateConVar("l4d2_dmg_headshot_awm","1.0", "Dmg headshot cua sung nham hunting");
	l4d2_dmg_headshot_scout = CreateConVar("l4d2_dmg_headshot_awm","1.0", "Dmg headshot cua sung nham scout");
	l4d2_dmg_headshot_other = CreateConVar("l4d2_dmg_headshot_other","1.0", "Dmg headshot cua sung khac");
	AutoExecConfig(true, "headshot_damage");
	HookEvent("player_spawn", Event_Player_Spawn);
}

public Event_Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(IsPlayer(client))
	{
		if(GetClientTeam(client) == TEAM_SI)
		{
			SDKHook( client, SDKHook_TraceAttack, OnTakeDamage_SI );
		}
	}
}

public Action:OnTakeDamage_SI(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{

	// weapon_melee
	// weapon_sniper_awp
	// weapon_sniper_scout
	// weapon_hunting_rifle
	// weapon_sniper_military
	// 1 = dau, 2 = nguc, 3 = bung ,4 = tay trai, 5 = tay phai, 6 = chan trai , 7 = chan phai

	if(!IsPlayer(attacker))
		return Plugin_Continue;
	if(GetClientTeam(attacker) != TEAM_SUR)
		return Plugin_Continue;

	new indexweapon = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
	if (indexweapon == -1)
		return Plugin_Continue;
	decl String:nameweapon[32];
	GetEntityClassname(indexweapon, nameweapon, sizeof(nameweapon));

	if(StrEqual(nameweapon,"weapon_melee"))
		return Plugin_Continue;

	if(hitgroup == 1) /// neu la headshot thi doi damage sung nham
	{
		if (StrEqual(nameweapon,"weapon_sniper_awp"))
		{
			damage *= GetConVarFloat(l4d2_dmg_headshot_awm);
		}
		else if(StrEqual(nameweapon,"weapon_sniper_scout"))
		{
			damage *= GetConVarFloat(l4d2_dmg_headshot_scout);
		}
		else if(StrEqual(nameweapon,"weapon_hunting_rifle"))
		{
			damage *= GetConVarFloat(l4d2_dmg_headshot_hunting_rifle);
		}
		else if(StrEqual(nameweapon,"weapon_sniper_military"))
		{
			damage *= GetConVarFloat(l4d2_dmg_headshot_military);
		}
		else
		{
			damage *= GetConVarFloat(l4d2_dmg_headshot_other);
		}
		return Plugin_Changed;
	}

	//PrintToChatAll("\x01name:\x03%s \n\x01type:\x03%d \n\x01Dmg:\x03%d \n\x01hitgroup:\x03%d",sWeapon,damagetype,damage,hitgroup);
	return Plugin_Continue;
}

stock bool IsPlayer(client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}