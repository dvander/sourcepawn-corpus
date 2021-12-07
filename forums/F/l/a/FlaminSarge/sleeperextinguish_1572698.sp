#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"
public Plugin:myinfo = 
{
	name = "[TF2] Sydney Sleeper Extinguish",
	author = "FlaminSarge",
	description = "The Sleeper will Extinguish teammates where it normally adds Jarate to enemies",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1572698"
};

public OnPluginStart()
{
	CreateConVar("tf2_slprxtngsh_version", PLUGIN_VERSION, "[TF2] Sydney Sleeper Extinguish version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

stock IsValidClient(client, bool:replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		decl String:adminname[32];
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
		}
	}
	return true;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (IsValidClient(client, false) && IsValidEntity(weapon) && weapon > MaxClients) DoSniperSleeperCheck(client, weapon, weaponname);
}

stock DoSniperSleeperCheck(client, weapon, String:weaponname[])
{
	if (strncmp(weaponname, "tf_weapon_sniperrifle", 21, false) != 0) return;
	new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (index != 230) return;
	new Float:chargelevel = GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage");
	if (chargelevel < 40.0) return;
	new target = GetClientAimTarget(client, true);
	if (!IsValidClient(target, false) || !IsPlayerAlive(target)) return;
	if (GetClientTeam(target) != GetClientTeam(client)) return;
	if (TF2_IsPlayerInCondition(target, TFCond_OnFire)) TF2_RemoveCondition(target, TFCond_OnFire);
}