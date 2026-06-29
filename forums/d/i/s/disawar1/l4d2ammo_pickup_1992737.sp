#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#undef REQUIRE_EXTENSIONS
#include <mempatch>

new Handle:hGLAmmo = INVALID_HANDLE;
new Handle:hM60Ammo = INVALID_HANDLE;
new Handle:hM60Patch = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Ammo Pickup",
	author = "Dr!fter",
	description = "Allow ammo pickup for m60 and grenade launcher",
	version = "1.0.1"
}
public OnPluginStart()
{
	hGLAmmo = FindConVar("ammo_grenadelauncher_max");
	hM60Ammo = FindConVar("ammo_m60_max");
	HookEvent("ammo_pile_weapon_cant_use_ammo", OnWeaponDosntUseAmmo, EventHookMode_Pre);
	if(LibraryExists("mempatch"))
	{
		PatchM60Drop();
    }
}
public Action:OnWeaponDosntUseAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new weaponIndex = GetPlayerWeaponSlot(client, 0);
	
	if(weaponIndex == -1)
		return Plugin_Continue;
	
	new String:classname[64];
	
	GetEdictClassname(weaponIndex, classname, sizeof(classname));
	
	if(StrEqual(classname, "weapon_rifle_m60") || StrEqual(classname, "weapon_grenade_launcher"))
	{
		new iClip1 = GetEntProp(weaponIndex, Prop_Send, "m_iClip1");
		new iPrimType = GetEntProp(weaponIndex, Prop_Send, "m_iPrimaryAmmoType");
		
		if(StrEqual(classname, "weapon_rifle_m60"))
		{
			SetEntProp(client, Prop_Send, "m_iAmmo", ((GetConVarInt(hM60Ammo)+150)-iClip1), _, iPrimType);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iAmmo", ((GetConVarInt(hGLAmmo)+1)-iClip1), _, iPrimType);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public OnLibraryAdded(const String:name[])
{
	if(strcmp(name, "mempatch") == 0)
		PatchM60Drop();
}
public OnLibraryRemoved(const String:name[])
{
	if(strcmp(name, "mempatch") == 0) 
		UnPatchM60Drop();
}
public OnPluginEnd()
{
	UnPatchM60Drop();
}
stock PatchM60Drop()
{
	if(hM60Patch == INVALID_HANDLE)
	{
		new Handle:conf = LoadGameConfigFile("l4d2m60-patch.games");
		
		if(conf == INVALID_HANDLE)
		{
			LogError("Could not locate l4d2m60-patch.games gamedata");
			return;
		}
		
		hM60Patch = SetupMemoryPatchBytes(conf, "CRifleM60::PrimaryAttack", "PrimaryAttackOffset", "PrimaryAttackPatch");
		
		if(hM60Patch != INVALID_HANDLE)
			MemoryPatchBytes(hM60Patch);
		else
			LogError("Failed to create CRifleM60 drop patch");
		
		CloseHandle(conf);
	}
}
stock UnPatchM60Drop()
{
	if(hM60Patch != INVALID_HANDLE)
	{
		RestoreMemoryPatch(hM60Patch);
		CloseHandle(hM60Patch);
	}
	
	hM60Patch = INVALID_HANDLE;
}