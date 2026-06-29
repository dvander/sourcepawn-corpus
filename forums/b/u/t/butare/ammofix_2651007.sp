#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Ammo fix",
	author = "GAMMA CASE",
	description = "Fixes ammo cvars",
	version = "1.0.4",
	url = "http://steamcommunity.com/id/_GAMMACASE_/"
}

#define AMMO_CVARS_COUNT 14
#define WEAPON_AMMOTYPE_P250 20
#define WEAPON_AMMOTYPE_REVOLVER 1
#define WEAPON_INDEX_REVOLVER 64

ConVar g_cvAmmo[AMMO_CVARS_COUNT],
	g_cvAmmoRevolver;

Handle g_hTimers[MAXPLAYERS + 1];

char g_sAmmoCvars[][] =
{
	"ammo_50AE_max", //weapon_deagle
	"ammo_762mm_max", //weapon_ak47, weapon_ssg08, weapon_aug, weapon_scar20, weapon_g3sg1
	"ammo_556mm_max", //weapon_galilar, weapon_famas, weapon_m4a1, weapon_sg556
	"ammo_556mm_small_max", //weapon_m4a1_silencer
	"ammo_556mm_box_max", //weapon_m249, weapon_negev
	"ammo_338mag_max", //weapon_awp
	"ammo_9mm_max", //weapon_glock, weapon_elite, weapon_tec9, weapon_mp9, weapon_mp7, weapon_bizon
	"ammo_buckshot_max", //weapon_nova, weapon_xm1014, weapon_sawedoff, weapon_mag7
	"ammo_45acp_max", //weapon_mac10, weapon_ump45
	"ammo_357sig_max", //weapon_hkp2000
	"ammo_357sig_small_max", //weapon_usp_silencer
	"ammo_357sig_min_max", //weapon_cz75a
	"ammo_57mm_max", //weapon_fiveseven, weapon_p90
	"ammo_357sig_p250_max", //weapon_p250
};

public void OnPluginStart()
{
	g_cvAmmoRevolver = CreateConVar("ammo_50AE_revolver_max", "8", "", FCVAR_REPLICATED);
	
	for(int i = 0; i < AMMO_CVARS_COUNT; i++)
	{
		g_cvAmmo[i] = FindConVar(g_sAmmoCvars[i]);
	}
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i))
			continue;
		
		if(!IsClientInGame(i))
			continue;
		
		SDKHook(i, SDKHook_WeaponDrop, WeaponDrop_Hook);
		SDKHook(i, SDKHook_WeaponEquip, WeaponEquip_Hook);
	}
	
	HookEvent("player_spawn", PlayerSpawn_Hook);
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_WeaponDrop, WeaponDrop_Hook);
	SDKHook(client, SDKHook_WeaponEquip, WeaponEquip_Hook);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_WeaponDrop, WeaponDrop_Hook);
	SDKUnhook(client, SDKHook_WeaponEquip, WeaponEquip_Hook);
}

public Action WeaponDrop_Hook(int client, int weapon)
{
	if(weapon != -1)
	{
		int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		
		if(ammotype != -1)
		{
			int ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
			
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
		}
	}
}

public Action WeaponEquip_Hook(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	if(ammotype != -1 && (ammotype < AMMO_CVARS_COUNT || ammotype == WEAPON_AMMOTYPE_P250))
		if(GetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner") != -1)
			SetEntProp(client, Prop_Send, "m_iAmmo", GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount"), _, ammotype);
		else if(weaponindex == WEAPON_INDEX_REVOLVER)
			CreateTimer(0.1, DelayedFrame_CallBack, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		else
			SetEntProp(client, Prop_Send, "m_iAmmo", (ammotype == WEAPON_AMMOTYPE_P250 ? g_cvAmmo[AMMO_CVARS_COUNT - 1].IntValue : g_cvAmmo[ammotype - 1].IntValue), _, ammotype);
}

public void PlayerSpawn_Hook(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
		if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == WEAPON_INDEX_REVOLVER)
		{
			delete g_hTimers[client];
			CreateTimer(0.1, DelayedFrame_CallBack, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
}

public Action DelayedFrame_CallBack(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	SetEntProp(client, Prop_Send, "m_iAmmo", g_cvAmmoRevolver.IntValue, _, WEAPON_AMMOTYPE_REVOLVER);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "weapon_deagle") || StrEqual(classname, "weapon_revolver"))
		RequestFrame(NextFrameSpawn, EntIndexToEntRef(entity));
}

public void NextFrameSpawn(int entref)
{
	int weapon = EntRefToEntIndex(entref);
	
	if(weapon != INVALID_ENT_REFERENCE && IsValidEntity(weapon))
		if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == WEAPON_INDEX_REVOLVER)
			SDKHook(weapon, SDKHook_ReloadPost, ReloadPost_Hook);
}

public void ReloadPost_Hook(int weapon, bool bSuccessful)
{
	int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");
	if(client != -1)
	{
		DataPack dp = new DataPack();
		g_hTimers[client] = CreateDataTimer(2.3, ReloadEnds_CallBack, dp, TIMER_DATA_HNDL_CLOSE);
		dp.WriteCell(client);
		dp.WriteCell(EntIndexToEntRef(weapon));
		dp.WriteCell(GetEntProp(weapon, Prop_Send, "m_iClip1"));
		dp.WriteCell(GetEntProp(client, Prop_Send, "m_iAmmo", _, WEAPON_AMMOTYPE_REVOLVER));
	}
}

public Action ReloadEnds_CallBack(Handle timer, DataPack dp)
{
	dp.Reset();
	int client = dp.ReadCell();
	
	g_hTimers[client] = null;
	
	if(!IsClientConnected(client))
		return Plugin_Stop;
	
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	int weapon = EntRefToEntIndex(dp.ReadCell());
	if(weapon == -1)
		return Plugin_Stop;
	
	int clipsize = dp.ReadCell();
	if (clipsize == GetEntProp(weapon, Prop_Send, "m_iClip1"))
		return Plugin_Stop;
	
	int ammo = dp.ReadCell() - (8 - clipsize);
	SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, WEAPON_AMMOTYPE_REVOLVER);
	
	return Plugin_Stop;
}