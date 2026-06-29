#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"
new g_TF_ChargeLevelOffset

public Plugin:myinfo = 
{
	name = "TF2 Medic Update",
	author = "R-Hehl",
	description = "TF2 Medic Update",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
}
public OnPluginStart()
{
	CreateConVar("sm_tf2_medic_version", PLUGIN_VERSION, "TF2 Medic Update", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_hurt", Event_Playerhurt)
	g_TF_ChargeLevelOffset = FindSendPropOffs("CWeaponMedigun", "m_flChargeLevel");
}

public Action:Event_Playerhurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weapon[16];
	new userid = GetClientOfUserId(GetEventInt(event, "attacker"))
	GetClientWeapon(userid,weapon[0],sizeof(weapon))
	if (strcmp(weapon[0], "tf_weapon_syrin", false) == 0)
	{
	ClientCommand(userid, "play player/crit_hit5");
	new health
	health = GetClientHealth(userid)
	if (health <= 147)
	{
		SetEntityHealth(userid, health + 3)
	}
	else if(health <= 149)
	{
		SetEntityHealth(userid, 150)
	}
	}
	else if (strcmp(weapon[0], "tf_weapon_bones", false) == 0)
	{
	
	new ueber
	ueber = TF_GetUberLevel(userid)
	if (ueber <= 75)
	{
		TF_SetUberLevel(userid, ueber + 25)
	}
	else
	{
		TF_SetUberLevel(userid, 100)
	}
	}
}

stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
	{
		SetEntDataFloat(index, g_TF_ChargeLevelOffset, uberlevel*0.01, true);
	}
}

stock TF_GetUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		return RoundFloat(GetEntDataFloat(index, g_TF_ChargeLevelOffset)*100);
	return 0;
}



