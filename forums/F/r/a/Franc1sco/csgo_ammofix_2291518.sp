#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

//new Handle:cvar1,Handle:cvar2,Handle:cvar3,Handle:cvar4,Handle:cvar5,Handle:cvar6,Handle:cvar7,Handle:cvar8,Handle:cvar9,Handle:cvar10,Handle:cvar11,Handle:cvar12,Handle:cvar13,Handle:cvar14;

#define DEFAULT_AMMO 9999 // AMMO VALUE FOR ALL WEAPONS

public Plugin:myinfo =
{
	name = "SM Franug CSGO Ammo fix",
	author = "Franc1sco franug",
	description = "",
	version = "1.1",
	url = "http://www.zeuszombie.com"
};

new Handle:array_armas;
new Handle:array_ammo;

public OnPluginStart() 
{
	array_armas = CreateArray();
	array_ammo = CreateArray();
	HookEvent("round_prestart", roundStart);
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
	
// IN PROCESS FOR SET AMMO TO WEAPONS OBEYING HIS RESPECTIVE OLD CVARS
/* 	cvar1 = FindConVar("ammo_50AE_max");
	cvar2 = FindConVar("ammo_762mm_max");
	cvar3 = FindConVar("ammo_556mm_box_max");
	cvar4 = FindConVar("ammo_556mm_max");
	cvar5 = FindConVar("ammo_338mag_max");
	cvar6 = FindConVar("ammo_9mm_max");
	cvar7 = FindConVar("ammo_buckshot_max");
	cvar8 = FindConVar("ammo_45acp_max");
	cvar9 = FindConVar("ammo_357sig_max");
	cvar10 = FindConVar("ammo_57mm_max");
	cvar11 = FindConVar("ammo_357sig_small_max");
	cvar12 = FindConVar("ammo_556mm_small_max");
	cvar13 = FindConVar("ammo_357sig_min_max");
	cvar14 = FindConVar("ammo_357sig_p250_max");
	
	SetTrieValue(arbol, "weapon_deagle", GetConVarInt(cvar1));
	SetTrieValue(arbol, "weapon_scout", GetConVarInt(cvar2));
	SetTrieValue(arbol, "weapon_ak47", GetConVarInt(cvar2));
	SetTrieValue(arbol, "weapon_g3sg1", GetConVarInt(cvar2));
	SetTrieValue(arbol, "weapon_aug", GetConVarInt(cvar2));
	SetTrieValue(arbol, "weapon_m249", GetConVarInt(cvar3));
	SetTrieValue(arbol, "weapon_galilar", GetConVarInt(cvar4));
	SetTrieValue(arbol, "weapon_sg552", GetConVarInt(cvar4));
	SetTrieValue(arbol, "weapon_famas", GetConVarInt(cvar4));
	SetTrieValue(arbol, "weapon_m4a1", GetConVarInt(cvar4));
	SetTrieValue(arbol, "weapon_sg550", GetConVarInt(cvar4));
	SetTrieValue(arbol, "weapon_awp", GetConVarInt(cvar5));
	SetTrieValue(arbol, "weapon_sg550", GetConVarInt(cvar4));
	
	HookConVarChange(cvar1, OnConVarChanged);
	HookConVarChange(cvar2, OnConVarChanged);
	HookConVarChange(cvar3, OnConVarChanged);
	HookConVarChange(cvar4, OnConVarChanged);
	HookConVarChange(cvar5, OnConVarChanged);
	HookConVarChange(cvar6, OnConVarChanged);
	HookConVarChange(cvar7, OnConVarChanged);
	HookConVarChange(cvar8, OnConVarChanged);
	HookConVarChange(cvar9, OnConVarChanged);
	HookConVarChange(cvar10, OnConVarChanged);
	HookConVarChange(cvar11, OnConVarChanged);
	HookConVarChange(cvar12, OnConVarChanged);
	HookConVarChange(cvar13, OnConVarChanged);
	HookConVarChange(cvar14, OnConVarChanged); */

}

public Action:roundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	ClearArray(array_armas);
	ClearArray(array_ammo);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

public Action:CS_OnCSWeaponDrop(client, weapon)
{
	new ref = EntIndexToEntRef(weapon);
	new buscado = FindValueInArray(array_armas, ref);
	if(buscado != -1)
	{
		SetArrayCell(array_ammo, buscado, GetReserveAmmo(client, weapon));
	}
}

public Action:OnPostWeaponEquip(client, iWeapon)
{
	decl String:Classname[64];
	new index = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
	if(!GetEdictClassname(iWeapon, Classname, 64) || StrContains(Classname, "weapon_knife", false) == 0 || (index > 42 && index < 50))
	{
		return;
	}
	new ammo = GetReserveAmmo(client, iWeapon);
	
	if(ammo == -1 || ammo > 100) return;
	
	new ref = EntIndexToEntRef(iWeapon);
	new buscado = FindValueInArray(array_armas, ref);
	if(buscado != -1)
	{
		SetReserveAmmo(client, iWeapon, GetArrayCell(array_ammo, buscado));
		return;
	}
	
	SetReserveAmmo(client, iWeapon, DEFAULT_AMMO);
	
	PushArrayCell(array_armas, ref);
	PushArrayCell(array_ammo, DEFAULT_AMMO);
}

stock GetReserveAmmo(client, weapon)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return -1;
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

stock SetReserveAmmo(client, weapon, ammo)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return;
    
    SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
} 
	