#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define DEFAULT_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"

ConVar UnlimitReloadPluginOn, AssaultAmmoCVAR, SMGAmmoCVAR, ShotgunAmmoCVAR, AutoShotgunAmmoCVAR, HRAmmoCVAR, SniperRifleAmmoCVAR, GrenadeLauncherAmmoCVAR;
int iAssaultAmmoCVAR = 0, iSMGAmmoCVAR = 0, iShotgunAmmoCVAR = 0, iAutoShotgunAmmoCVAR = 0, iHRAmmoCVAR = 0, iSniperRifleAmmoCVAR = 0, iGrenadeLauncherAmmoCVAR = 0;
bool bHooked = false;

public Plugin myinfo =
{
	name = "Unlimit Reload",
	author = "Lumiere/亮晶晶",
	description = "Dont ever need to reload again!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}
 
public void OnPluginStart()
{
	CreateConVar("l4d2_unlimitreload_version", PLUGIN_VERSION, " Version of L4D2 Unlimit Reload on this server ", DEFAULT_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	UnlimitReloadPluginOn = CreateConVar("l4d2_unlimitreload_on", "1", "Plugin On/Off", DEFAULT_FLAGS);
	AssaultAmmoCVAR = CreateConVar("l4d2_unlimitreload_assaultreload", "30", "Reload amont for Assault Rifles", DEFAULT_FLAGS);
	SMGAmmoCVAR = CreateConVar("l4d2_unlimitreload_smgreload", "50", "Reload amount for SMG gun types", DEFAULT_FLAGS);
	ShotgunAmmoCVAR = CreateConVar("l4d2_unlimitreload_shotgunreload", "8", "Reload amount for Shotgun and Chrome Shotgun", DEFAULT_FLAGS);
	AutoShotgunAmmoCVAR = CreateConVar("l4d2_unlimitreload_autoshotgunreload", "10", "Reload amount for Autoshottie and SPAS", DEFAULT_FLAGS);
	HRAmmoCVAR = CreateConVar("l4d2_unlimitreload_huntingrifleareload", "30", "Reload amount for the Hunting Rifle", DEFAULT_FLAGS);
	SniperRifleAmmoCVAR = CreateConVar("l4d2_unlimitreload_sniperrifleareload", "30", "Reload amount for the Military Sniper Rifle, AWP, and Scout", DEFAULT_FLAGS);	
	GrenadeLauncherAmmoCVAR = CreateConVar("l4d2_unlimitreload_grenadelauncherreload", "1", "Reload amount for the Grenade Launcher", DEFAULT_FLAGS);
	
	UnlimitReloadPluginOn.AddChangeHook(ConVarPluginOnChanged);
	AssaultAmmoCVAR.AddChangeHook(ConVarsChanged);
	SMGAmmoCVAR.AddChangeHook(ConVarsChanged);
	ShotgunAmmoCVAR.AddChangeHook(ConVarsChanged);
	AutoShotgunAmmoCVAR.AddChangeHook(ConVarsChanged);
	HRAmmoCVAR.AddChangeHook(ConVarsChanged);
	SniperRifleAmmoCVAR.AddChangeHook(ConVarsChanged);
	GrenadeLauncherAmmoCVAR.AddChangeHook(ConVarsChanged);

	AutoExecConfig(true, "l4d2_unlimitreload");
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    GetCvars();
}

void IsAllowed()
{
	bool bPluginOn = UnlimitReloadPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		GetCvars();
		HookEvent("weapon_fire", Event_Weapon_fire);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("weapon_fire", Event_Weapon_fire);
	}
}

void GetCvars()
{
	iAssaultAmmoCVAR = AssaultAmmoCVAR.IntValue;
	iSMGAmmoCVAR = SMGAmmoCVAR.IntValue;
	iShotgunAmmoCVAR = ShotgunAmmoCVAR.IntValue;
	iAutoShotgunAmmoCVAR = AutoShotgunAmmoCVAR.IntValue;
	iHRAmmoCVAR = HRAmmoCVAR.IntValue;
	iSniperRifleAmmoCVAR = SniperRifleAmmoCVAR.IntValue;	
	iGrenadeLauncherAmmoCVAR = GrenadeLauncherAmmoCVAR.IntValue;
}

Action Event_Weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        char weaponName[20];
        event.GetString("weapon", weaponName, sizeof(weaponName));
        if (IsValidEntity(client))
        {
            int weapon = GetPlayerWeaponSlot(client, 0); 
            if (IsValidEntity(weapon))
        	{
        		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 0) * 4;
        		int iAmmoTable = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
        		int clipammo = GetEntProp(weapon, Prop_Send, "m_iClip1");
        		int allAmmo = GetEntData(client, iAmmoTable + iOffset);
        		PrintToServer("GetAmmo  %d,%d %s %", clipammo, allAmmo, weaponName);
        		if(clipammo <= 1)
        		{
        			if (StrEqual(weaponName, "pumpshotgun") || StrEqual(weaponName, "shotgun_chrome"))
        			{
        				if(allAmmo >= iShotgunAmmoCVAR)
        				{
        					SetAmmo(client, weapon, iAmmoTable, iOffset, allAmmo, iShotgunAmmoCVAR);
        				}
        			}
        			if (StrEqual(weaponName, "autoshotgun") || StrEqual(weaponName, "shotgun_spas"))
        			{
        				if(allAmmo >= iAutoShotgunAmmoCVAR)
        				{
        					SetAmmo(client, weapon, iAmmoTable, iOffset, allAmmo, iAutoShotgunAmmoCVAR);
        				}
        			}
        			if (StrEqual(weaponName, "smg") || StrEqual(weaponName, "smg_silenced") || StrEqual(weaponName, "smg_mp5"))
        			{
        				if(allAmmo >= iSMGAmmoCVAR)
        				{
        					SetAmmo(client, weapon, iAmmoTable, iOffset, allAmmo, iSMGAmmoCVAR);
        				}
        			}
        			if (StrEqual(weaponName, "rifle") || StrEqual(weaponName, "rifle_ak47") || StrEqual(weaponName, "rifle_ak47") || StrEqual(weaponName, "rifle_sg552") || StrEqual(weaponName, "rifle_desert"))
        			{
        				if(allAmmo >= iAssaultAmmoCVAR)
        				{
        					SetAmmo(client, weapon, iAmmoTable, iOffset, allAmmo, iAssaultAmmoCVAR);
        				}
        			}
        			if (StrEqual(weaponName, "hunting_rifle"))
        			{
        				if(allAmmo >= iHRAmmoCVAR)
        				{
        					SetAmmo(client, weapon, iAmmoTable, iOffset, allAmmo, iHRAmmoCVAR);
        				}
        			}
        			if (StrEqual(weaponName, "sniper_military") || StrEqual(weaponName, "sniper_awp") || StrEqual(weaponName, "sniper_scout"))
        			{
        				if(allAmmo >= iSniperRifleAmmoCVAR)
        				{
        					SetAmmo(client, weapon, iAmmoTable, iOffset, allAmmo, iSniperRifleAmmoCVAR);
        				}
        			}
        			if (StrEqual(weaponName, "grenade_launcher"))
        			{
        				if(allAmmo >= iGrenadeLauncherAmmoCVAR)
        				{
        					SetAmmo(client, weapon, iAmmoTable, iOffset, allAmmo, iGrenadeLauncherAmmoCVAR);
        				}
        			}
        		}
        	}
        }
    }
    return Plugin_Continue;
}

stock void SetAmmo(int client, int weapon, int iAmmoTable, int iOffset, int allAmmo, int ammo)
{
    if (IsValidEntity(weapon))
    {
		SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
		SetEntData(client, iAmmoTable + iOffset, allAmmo - ammo, 4, true);
    }
}
