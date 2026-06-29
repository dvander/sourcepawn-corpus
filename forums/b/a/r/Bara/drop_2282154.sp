#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PL_VERSION "1.0.0"

#pragma semicolon 1
#pragma newdecls required

ConVar g_cEnable;
ConVar g_cTaser;
ConVar g_cHEGrenade;
ConVar g_cFlash;
ConVar g_cSmoke;
ConVar g_cIncGrenade;
ConVar g_cMolotov;
ConVar g_cDecoy;
ConVar g_cKnife;

public Plugin myinfo =
{
	name = "Drop",
	author = "Bara",
	version = PL_VERSION,
	description = "",
	url = "www.bara.in"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSS && GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Only CSS and CSGO Support");
		return ;
	}
	
	CreateConVar("cs_drop_version", PL_VERSION, "With this Plugin you can drop your grenades and knives.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_cEnable = CreateConVar("drop_enable", "1", "Should be enabled this plugin?");
	g_cTaser = CreateConVar("drop_taser", "1", "Enable \"taser\" drop?");
	g_cHEGrenade = CreateConVar("drop_hegrenade", "1", "Enable \"hegrenade\" drop?");
	g_cFlash = CreateConVar("drop_flashbang", "1", "Enable \"flashbang\" drop?");
	g_cSmoke = CreateConVar("drop_smokegrenade", "1", "Enable \"smokegrenade\" drop?");
	g_cIncGrenade = CreateConVar("drop_incgrenace", "1", "Enable \"incgrenade\" drop?");
	g_cMolotov = CreateConVar("drop_molotov", "1", "Enable \"molotov\" drop?");
	g_cDecoy = CreateConVar("drop_decoy", "1", "Enable \"decoy\" drop?");
	g_cKnife = CreateConVar("drop_knife", "1", "Enable \"knife\" drop?");
	
	AutoExecConfig();

	AddCommandListener(Command_Drop, "drop");
}

public Action Command_Drop(int client, const char[] command, int args)
{
	if(!g_cEnable.BoolValue)
		return Plugin_Continue;
	
	if (IsClientInGame(client))
	{
		char sName[32];
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon))
		{
			return Plugin_Stop;
		}

		GetEdictClassname(weapon, sName, sizeof(sName));

		if (StrEqual("weapon_taser", sName, false) && g_cTaser.BoolValue)
		{
			if (GetEntProp(weapon, Prop_Data, "m_iClip1") > 0)
			{
				int iSequence = GetEntProp(weapon, Prop_Data, "m_nSequence");
				if((GetEngineVersion() == Engine_CSS && iSequence != 5) || (GetEngineVersion() == Engine_CSGO && iSequence != 2))
				{
					SDKHooks_DropWeapon(client, weapon);
					return Plugin_Handled;
				}
			}
		}
		else if (StrEqual("weapon_hegrenade", sName, false) && g_cHEGrenade.BoolValue ||
				StrEqual("weapon_flashbang", sName, false) && g_cFlash.BoolValue ||
				StrEqual("weapon_smokegrenade", sName, false) && g_cSmoke.BoolValue ||
				StrEqual("weapon_incgrenade", sName, false) && g_cIncGrenade.BoolValue ||
				StrEqual("weapon_molotov", sName, false) && g_cMolotov.BoolValue ||
				StrEqual("weapon_decoy", sName, false) && g_cDecoy.BoolValue)
		{
			int iSequence = GetEntProp(weapon, Prop_Data, "m_nSequence");
			if((GetEngineVersion() == Engine_CSS && iSequence != 5) || (GetEngineVersion() == Engine_CSGO && iSequence != 2))
			{
				SDKHooks_DropWeapon(client, weapon);
				return Plugin_Handled;
			}
		}
		else if ((StrContains(sName, "knife", false) != -1) || (StrContains(sName, "bayonet", false) != -1) && g_cKnife.BoolValue)
		{
			SDKHooks_DropWeapon(client, weapon);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
