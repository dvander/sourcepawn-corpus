#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required

#define ONLYHS_VERSION "2.0.2"

ConVar g_cEnablePlugin = null;
ConVar g_cEnableOneShot = null;
ConVar g_cAllowGrenade = null;
ConVar g_cAllowWorld = null;
ConVar g_cAllowKnife = null;
ConVar g_cAllowedWeapons = null;
ConVar g_cEnableBloodSplatter = null;
ConVar g_cEnableBloodSplash = null;
ConVar g_cEnableNoBlood = null;

public Plugin myinfo = 
{
	name = "Only Headshot",
	author = "Bara",
	description = "Only Headshot Plugin for CSS and CSGO",
	version = ONLYHS_VERSION,
	url = "www.bara.in"
}

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSS && GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("Only CSS and CSGO Support");
	}

	CreateConVar("onlyhs_version", ONLYHS_VERSION, "Only Headshot", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	LoadTranslations("common.phrases");
	
	g_cEnablePlugin = CreateConVar("onlyhs_enable", "1", "Enable / Disalbe Only HeadShot Plugin", _, true, 0.0, true, 1.0);
	g_cEnableOneShot = CreateConVar("onlyhs_oneshot", "0", "Enable / Disable kill enemy with one shot", _, true, 0.0, true, 1.0);
	g_cAllowGrenade = CreateConVar("onlyhs_allow_grenade", "0", "Enable / Disalbe No Grenade Damage", _, true, 0.0, true, 1.0);
	g_cAllowWorld = CreateConVar("onlyhs_allow_world", "0", "Enable / Disalbe No World Damage", _, true, 0.0, true, 1.0);
	g_cAllowKnife = CreateConVar("onlyhs_allow_knife", "0", "Enable / Disalbe No Knife Damage", _, true, 0.0, true, 1.0);
	g_cAllowedWeapons = CreateConVar("onlyhs_allow_weapons", "deagle;elite", "Which weapon should be permitted ( Without 'weapon_' )?");
	g_cEnableNoBlood = CreateConVar("onlyhs_allow_blood", "0", "Enable / Disable No Blood", _, true, 0.0, true, 1.0);
	g_cEnableBloodSplatter = CreateConVar("onlyhs_allow_blood_splatter", "0", "Enable / Disable No Blood Splatter", _, true, 0.0, true, 1.0);
	g_cEnableBloodSplash = CreateConVar("onlyhs_allow_blood_splash", "0", "Enable / Disable No Blood Splash", _, true, 0.0, true, 1.0);

	AutoExecConfig();

	AddTempEntHook("EffectDispatch", TE_OnEffectDispatch);
	AddTempEntHook("World Decal", TE_OnWorldDecal);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnClientPutInServer(int i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(g_cEnablePlugin.BoolValue)
	{
		if(IsClientValid(victim))
		{
			if(
				damagetype == DMG_FALL
				|| damagetype == DMG_GENERIC
				|| damagetype == DMG_CRUSH
				|| damagetype == DMG_SLASH
				|| damagetype == DMG_BURN
				|| damagetype == DMG_VEHICLE
				|| damagetype == DMG_FALL
				|| damagetype == DMG_BLAST
				|| damagetype == DMG_SHOCK
				|| damagetype == DMG_SONIC
				|| damagetype == DMG_ENERGYBEAM
				|| damagetype == DMG_DROWN
				|| damagetype == DMG_PARALYZE
				|| damagetype == DMG_NERVEGAS
				|| damagetype == DMG_POISON
				|| damagetype == DMG_ACID
				|| damagetype == DMG_AIRBOAT
				|| damagetype == DMG_PLASMA
				|| damagetype == DMG_RADIATION
				|| damagetype == DMG_SLOWBURN
				|| attacker == 0
			)
			{
				if(g_cAllowWorld.BoolValue)
					return Plugin_Continue;
				else
					return Plugin_Handled;
			}

			if(IsClientValid(attacker))
			{
				char sGrenade[32];
				char sWeapon[32];
				
				GetEdictClassname(inflictor, sGrenade, sizeof(sGrenade));
				GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
				
				if ((StrContains(sWeapon, "knife", false) != -1) || (StrContains(sWeapon, "bayonet", false) != -1))
					if(g_cAllowKnife.BoolValue)
						return Plugin_Continue;

				if (StrContains(sGrenade, "_projectile", false) != -1)
					if(g_cAllowGrenade.BoolValue)
						return Plugin_Continue;
				
				char sBuffer[256], sWeapons[32][64];
				g_cAllowedWeapons.GetString(sBuffer, sizeof(sBuffer));
				
				int iCount = ExplodeString(sBuffer, ";", sWeapons, sizeof(sWeapons), sizeof(sWeapons[]));

				for (int i = 0; i < iCount; i++)
				{
					if (StrContains(sWeapon[7], sWeapons[i], false) != -1)
					{
						if(damagetype & CS_DMG_HEADSHOT)
						{
							if(g_cEnableOneShot.BoolValue)
							{
								damage = float(GetClientHealth(victim) + GetClientArmor(victim));
								return Plugin_Changed;
							}
		
							return Plugin_Continue;
						}
					}
				}
			}
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action TE_OnEffectDispatch(const char[] te_name, const Players[], int numClients, float delay)
{
	int iEffectIndex = TE_ReadNum("m_iEffectName");
	int nHitBox = TE_ReadNum("m_nHitBox");
	char sEffectName[64];

	GetEffectName(iEffectIndex, sEffectName, sizeof(sEffectName));
	
	if(g_cEnableNoBlood.BoolValue)
	{
		if(StrEqual(sEffectName, "csblood"))
		{
			if(g_cEnableBloodSplatter.BoolValue)
				return Plugin_Handled;
		}
		if(StrEqual(sEffectName, "ParticleEffect"))
		{
			if(g_cEnableBloodSplash.BoolValue)
			{
				char sParticleEffectName[64];
				GetParticleEffectName(nHitBox, sParticleEffectName, sizeof(sParticleEffectName));
				
				if(StrEqual(sParticleEffectName, "impact_helmet_headshot") || StrEqual(sParticleEffectName, "impact_physics_dust"))
					return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action TE_OnWorldDecal(const char[] te_name, const Players[], int numClients, float delay)
{
	float vecOrigin[3];
	int nIndex = TE_ReadNum("m_nIndex");
	char sDecalName[64];

	TE_ReadVector("m_vecOrigin", vecOrigin);
	GetDecalName(nIndex, sDecalName, sizeof(sDecalName));
	
	if(g_cEnableNoBlood.BoolValue)
	{
		if(StrContains(sDecalName, "decals/blood") == 0 && StrContains(sDecalName, "_subrect") != -1)
			if(g_cEnableBloodSplash.BoolValue)
				return Plugin_Handled;
	}

	return Plugin_Continue;
}

stock bool IsClientValid(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}

stock int GetParticleEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("ParticleEffectNames");
	
	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetEffectName(int index, char[] sEffectName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("EffectDispatch");
	
	return ReadStringTable(table, index, sEffectName, maxlen);
}

stock int GetDecalName(int index, char[] sDecalName, int maxlen)
{
	int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
		table = FindStringTable("decalprecache");
	
	return ReadStringTable(table, index, sDecalName, maxlen);
}