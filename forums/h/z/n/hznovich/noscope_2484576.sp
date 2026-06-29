#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required

#define NOSCOPE_VERSION  "2.0.0"

ConVar g_cEnablePlugin = null;
ConVar g_cEnableOneShot = null;
ConVar g_cAllowGrenade = null;
ConVar g_cAllowWorld = null;
ConVar g_cAllowMelee = null;
ConVar g_cAllowedWeapons = null;

int m_flNextSecondaryAttack = -1;

public Plugin myinfo = 
{
	name = "NoScope", 
	author = "Bara", 
	description = "", 
	version = NOSCOPE_VERSION, 
	url = "www.bara.in"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSS && GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Only CSS and CSGO Support");
	}
	
	CreateConVar("noscope_version", NOSCOPE_VERSION, "NoScope", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	g_cEnablePlugin = CreateConVar("noscope_enable", "1", "Enable / Disalbe NoScope Plugin", _, true, 0.0, true, 1.0);
	g_cEnableOneShot = CreateConVar("noscope_oneshot", "0", "Enable / Disable kill enemy with one shot", _, true, 0.0, true, 1.0);
	g_cAllowGrenade = CreateConVar("noscope_allow_grenade", "0", "Enable / Disalbe Grenade Damage", _, true, 0.0, true, 1.0);
	g_cAllowWorld = CreateConVar("noscope_allow_world", "0", "Enable / Disalbe World Damage", _, true, 0.0, true, 1.0);
	g_cAllowMelee = CreateConVar("noscope_allow_knife", "0", "Enable / Disalbe Knife Damage", _, true, 0.0, true, 1.0);
	g_cAllowedWeapons = CreateConVar("noscope_allow_weapons", "awp;scout", "What weapon should the player get back after it has zoomed?");
	
	AutoExecConfig();
	
	m_flNextSecondaryAttack = FindSendPropOffs("CBaseCombatWeapon", "m_flNextSecondaryAttack");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(i, SDKHook_PreThink, OnPreThink);
		}
	}
}

public void OnClientPutInServer(int i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(i, SDKHook_PreThink, OnPreThink);
}

public Action OnPreThink(int client)
{
	int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	SetNoScope(iWeapon);
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (g_cEnablePlugin.BoolValue)
	{
		if (IsClientValid(victim))
		{
			if (damagetype & DMG_FALL || attacker == 0)
			{
				if (g_cAllowWorld.BoolValue)
					return Plugin_Continue;
				else
					return Plugin_Handled;
			}

			if (IsClientValid(attacker))
			{
				char sGrenade[32];
				char sWeapon[32];
				
				GetEdictClassname(inflictor, sGrenade, sizeof(sGrenade));
				GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
				
				if ((StrContains(sWeapon, "knife", false) != -1) || (StrContains(sWeapon, "bayonet", false) != -1))
					if (g_cAllowMelee.BoolValue)
						return Plugin_Continue;
				
				if (StrContains(sGrenade, "_projectile", false) != -1)
					if (g_cAllowGrenade.BoolValue)
						return Plugin_Continue;
				
				char sBuffer[256], sWeapons[24][64];
				g_cAllowedWeapons.GetString(sBuffer, sizeof(sBuffer));
				
				int iCount = ExplodeString(sBuffer, ";", sWeapons, sizeof(sWeapons), sizeof(sWeapons[]));
				
				for (int i = 0; i < iCount; i++)
				{
					if (StrContains(sWeapon[7], sWeapons[i], false) != -1)
					{
						if (g_cEnableOneShot.BoolValue)
						{
							damage = float(GetClientHealth(victim) + GetClientArmor(victim));
							return Plugin_Changed;
						}
						return Plugin_Continue;
					}
				}
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

stock void SetNoScope(int weapon)
{
	if (IsValidEdict(weapon))
	{
		char classname[MAX_NAME_LENGTH];
		GetEdictClassname(weapon, classname, sizeof(classname));
		
		if (StrEqual(classname[7], "ssg08") || StrEqual(classname[7], "aug") || StrEqual(classname[7], "sg550") || StrEqual(classname[7], "sg552") || StrEqual(classname[7], "sg556") || StrEqual(classname[7], "awp") || StrEqual(classname[7], "scar20") || StrEqual(classname[7], "g3sg1"))
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 2.0);
	}
}

stock bool IsClientValid(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}
