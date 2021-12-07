
#include <sourcemod>
#include <cstrike>

#define PLUGIN_VERSION "2.0"

new bool:g_bEnabled,
	bool:g_bFlash,
	bool:g_bKnife,
	bool:g_bFrag,
	bool:g_bSmoke;	

public Plugin:myinfo =
{
	name = "Drop All",
	author = "FrozDark, Mini",
	description = "You will be able to drop all undropable weapons like knife and grenades.",
	version = PLUGIN_VERSION,
	url = "http://all-stars.sytes.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_dropall_version", PLUGIN_VERSION, "Drop all Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	new Handle:conVar;

	conVar = CreateConVar("sm_dropall_enabled", "1", "Enable the plugin");
	g_bEnabled = GetConVarBool(conVar);
	HookConVarChange(conVar, OnEnableChange);

	conVar = CreateConVar("sm_dropall_flash", "1", "Enable flash grenade dropping");
	g_bFlash = GetConVarBool(conVar);
	HookConVarChange(conVar, OnFlashChange);

	conVar = CreateConVar("sm_dropall_knife", "1", "Enable knife dropping");
	g_bKnife = GetConVarBool(conVar);
	HookConVarChange(conVar, OnKnifeChange);

	conVar = CreateConVar("sm_dropall_frag", "1", "Enable frag grenade dropping");
	g_bFrag = GetConVarBool(conVar);
	HookConVarChange(conVar, OnFragChange);

	conVar = CreateConVar("sm_dropall_smoke", "1", "Enable smoke grenade dropping");
	g_bSmoke = GetConVarBool(conVar);
	HookConVarChange(conVar, OnSmokeChange);

	AddCommandListener(Command_Drop, "drop");
}

public OnEnableChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bEnabled = bool:StringToInt(newVal);
}

public OnFlashChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bFlash = bool:StringToInt(newVal);
}

public OnKnifeChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bKnife = bool:StringToInt(newVal);
}

public OnFragChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bSmoke = bool:StringToInt(newVal);
}

public OnSmokeChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bFrag = bool:StringToInt(newVal);
}

public Action:Command_Drop(client, const String:command[], args)
{
	if (IsClientInGame(client))
	{
		if (g_bEnabled)
		{
			new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if (OperateOnWeapon(client, weapon))
			{
				CS_DropWeapon(client, weapon, true);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

stock bool:OperateOnWeapon(client, weapon)
{
	decl String:entName[64];
	GetClientWeapon(client, entName, sizeof(entName));
	if (g_bFlash && !strcmp(entName, "weapon_flashbang", false))
		return true;
	else if (g_bKnife && !strcmp(entName, "weapon_knife", false))
		return true;
	else if (g_bSmoke && !strcmp(entName, "weapon_smokegrenade", false))
		return true;
	else if (g_bFrag && !strcmp(entName, "weapon_hegrenade", false))
		return true;
	return false;
}