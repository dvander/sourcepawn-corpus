#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {

	name = "Headshot only with restock",
	author = "johan123jo",
	description = "Can only kill on headshot, and restock ammo when done.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

#define NUM_WEAPONS 24

new const String:g_sWeaponNames[NUM_WEAPONS][32] = {

	"weapon_ak47", "weapon_m4a1", "weapon_sg552",
	"weapon_aug", "weapon_galil", "weapon_famas",
	"weapon_scout", "weapon_m249", "weapon_mp5navy",
	"weapon_p90", "weapon_ump45", "weapon_mac10",
	"weapon_tmp", "weapon_m3", "weapon_xm1014",
	"weapon_glock", "weapon_usp", "weapon_p228",
	"weapon_deagle", "weapon_elite", "weapon_fiveseven",
	"weapon_awp", "weapon_g3sg1", "weapon_sg550"
};

new const g_AmmoData[NUM_WEAPONS][2] = {

	{2, 90}, {3, 90}, {3, 90},
	{2, 90}, {3, 90}, {3, 90},
	{2, 90}, {4, 200}, {6, 120},
	{10, 100}, {8, 100}, {8, 100},
	{6, 120}, {7, 32}, {7, 32},
	{6, 120}, {8, 100}, {9, 52},
	{1, 35}, {6, 120}, {10, 100},
	{5, 30}, {2, 90}, {3, 90}
};

new const g_ClipData[NUM_WEAPONS][2] = {

	{2, 30}, {3, 30}, {3, 30},
	{2, 30}, {3, 35}, {3, 25},
	{2, 10}, {4, 100}, {6, 30},
	{10, 50}, {8, 25}, {8, 30},
	{6, 30}, {7, 8}, {7, 7},
	{6, 20}, {8, 12}, {9, 13},
	{1, 7}, {6, 30}, {10, 20},
	{5, 10}, {2, 20}, {3, 30}
};

new Handle:gH_Cvar_Enabled;
new Handle:gH_Cvar_Restock;

new gShadow_Enabled;
new gShadow_Restock;

public OnPluginStart()
{
	gH_Cvar_Enabled = CreateConVar("sm_hso_enabled", "1", "1/0 Enable/Disable plugin.");
	gH_Cvar_Restock = CreateConVar("sm_hso_restock", "1", "1/0 Restock clip and ammo on headshot.");
	CreateConVar("sm_hso_version", PLUGIN_VERSION, "Headshot only plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookConVarChange(gH_Cvar_Enabled, ConVarChange);
	HookConVarChange(gH_Cvar_Restock, ConVarChange);

	AutoExecConfig(true, "headshotonly");

	
	//Late Load
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_TraceAttack, TraceAttack);
		}
	}
}

//Convar Change
public ConVarChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new nval = StringToInt(newValue);
	
	if(cvar == gH_Cvar_Enabled)
	{
		if(nval == 1)
		{
			gShadow_Enabled = 1;
		}
		else
		{
			gShadow_Enabled = 0;
		}
	}
	else if(cvar == gH_Cvar_Restock)
	{
		
		if(nval == 1)
		{
			gShadow_Restock = 1;
		}
		else
		{
			gShadow_Restock = 0;
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
}

public Action:TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(gShadow_Enabled == 1)
	{
		if (hitgroup == 1)
		{
			damage *= 1337.0;

			if(gShadow_Restock == 1)
				RestockClientAmmo(attacker);
		}
		else
		{
			damage = 0.0;
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

RestockClientAmmo(client)
{

	new weaponIndex, dataIndex, ammoOffset;
	decl String:sClassName[32];
	
	for (new i = 0; i <= 1; i++)
	{
		if (((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1) && 
		GetEdictClassname(weaponIndex, sClassName, 32) &&
		((dataIndex = GetAmmoDataIndex(sClassName)) != -1) &&
		((ammoOffset = FindDataMapOffs(client, "m_iAmmo")+(g_AmmoData[dataIndex][0]*4)) != -1))
		{
			SetEntData(client, ammoOffset, g_AmmoData[dataIndex][1]);
			SetEntProp(weaponIndex, Prop_Send, "m_iClip1", g_ClipData[dataIndex][1]);
		}
	}
}

GetAmmoDataIndex(const String:weapon[]) {

	for (new i = 0; i < NUM_WEAPONS; i++)
		if (StrEqual(weapon, g_sWeaponNames[i]))
			return i;
	return -1;
}