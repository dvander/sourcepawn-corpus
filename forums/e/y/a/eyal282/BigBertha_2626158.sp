#include <sourcemod>
#include <sdkhooks> 
#include <sdktools>
#include <cstrike>

new Float:CurrentFireRate[MAXPLAYERS+1], bool:DisableNextAmmo[MAXPLAYERS+1];
new Handle:hcv_MinFireRate = INVALID_HANDLE;
new Handle:hcv_MaxFireRate = INVALID_HANDLE;
new Handle:hcv_IncreaseFireRate = INVALID_HANDLE;
new Handle:hcv_MaxAmmo = INVALID_HANDLE;
new Handle:hcv_IncreaseAmmo = INVALID_HANDLE;
new Handle:hcv_IncreaseAmmoTime = INVALID_HANDLE;


new Float:cv_MinFireRate, Float:cv_MaxFireRate, Float:cv_IncreaseFireRate, cv_MaxAmmo, cv_IncreaseAmmo, Float:cv_IncreaseAmmoTime;

new Float:M249ROFDelay = -1.0 // Rate of fire of m249, but as a small float that indicates how long the next shot will take.

public Plugin:myinfo = 
{
	name = "Big Bertha",
	author = "Eyal282",
	description = "She's a little slow but once you get her going, nothing can stop her.",
	version = "1.0",
	url = "None."
}
public OnPluginStart() 
{ 
	// 0.5 = 50%, 2.0 = 200%, 0.02 = 2%
	HookConVarChange(hcv_MinFireRate = CreateConVar("big_bertha_min_firerate", "0.5", "Minimum fire rate the big bertha starts with relative to the m249."), OnConVarChange); // 50%
	HookConVarChange(hcv_MaxFireRate = CreateConVar("big_bertha_max_firerate", "2.0", "Maximum fire rate the big bertha ends with relative to the m249."), OnConVarChange); // 50%
	HookConVarChange(hcv_IncreaseFireRate = CreateConVar("big_bertha_increase_firerate", "0.02", "Fire rate increase per shot."), OnConVarChange); // 50%
	HookConVarChange(hcv_MaxAmmo = CreateConVar("big_bertha_max_ammo", "150", "Maximum ammo of Big Bertha."), OnConVarChange);
	HookConVarChange(hcv_IncreaseAmmo = CreateConVar("big_bertha_increase_ammo", "2", "Ammo increase per period of time."), OnConVarChange); // 50%
	HookConVarChange(hcv_IncreaseAmmoTime = CreateConVar("big_bertha_increase_ammo_time", "0.5", "Period of time for the ammo to increase.."), OnConVarChange); // Half a second.
	
	cv_MinFireRate = GetConVarFloat(hcv_MinFireRate);
	cv_MaxFireRate = GetConVarFloat(hcv_MaxFireRate);
	cv_IncreaseFireRate = GetConVarFloat(hcv_IncreaseFireRate);
	cv_MaxAmmo = GetConVarInt(hcv_MaxAmmo);
	cv_IncreaseAmmo = GetConVarInt(hcv_IncreaseAmmo);
	cv_IncreaseAmmoTime = GetConVarFloat(hcv_IncreaseAmmoTime);
	
	HookEvent("weapon_fire", Event_WeaponFirePre, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFirePost, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("item_pickup", Event_ItemPickup, EventHookMode_Post);

} 

public OnEntityCreated(entity, const String:Classname[])
{
	if(StrEqual(Classname, "weapon_m249"))
	{	
		SDKHook(entity, SDKHook_SpawnPost, Event_SpawnPost);
	}
}

public Event_SpawnPost(entity)
{
	SDKUnhook(entity, SDKHook_SpawnPost, Event_SpawnPost);
	RequestFrame(FullClip, EntIndexToEntRef(entity));
	CreateTimer(cv_IncreaseAmmoTime, ReplenishAmmo, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public FullClip(Ref)
{
	new weapon = EntRefToEntIndex(Ref);
	
	if(weapon == INVALID_ENT_REFERENCE)
		return;
		
	SetWeaponClip(weapon, cv_MaxAmmo);
}

public Action:ReplenishAmmo(Handle:hTimer, Ref)
{
	new weapon = EntRefToEntIndex(Ref);
	
	if(weapon == INVALID_ENT_REFERENCE)
		return Plugin_Stop;
		
	new client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1)
		return Plugin_Continue;
	
	else if(DisableNextAmmo[client])
	{
		DisableNextAmmo[client] = false;
		return Plugin_Continue;
	}
	else if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != weapon)
		return Plugin_Continue;
	
	new NewClip = GetWeaponClip(weapon) + cv_IncreaseAmmo;
	
	if(NewClip > cv_MaxAmmo)
		NewClip = cv_MaxAmmo;
		
	SetWeaponClip(weapon, NewClip);
	
	return Plugin_Continue;
	
}

public OnConVarChange(ConVar:convar, const String:oldValue[], const String:newValue[])
{
	cv_MinFireRate = GetConVarFloat(hcv_MinFireRate);
	cv_MaxFireRate = GetConVarFloat(hcv_MaxFireRate);
	cv_IncreaseFireRate = GetConVarFloat(hcv_IncreaseFireRate);
	cv_MaxAmmo = GetConVarInt(hcv_MaxAmmo);
	cv_IncreaseAmmo = GetConVarInt(hcv_IncreaseAmmo);
	cv_IncreaseAmmoTime = GetConVarFloat(hcv_IncreaseAmmoTime);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if(!(buttons & IN_ATTACK))
		CurrentFireRate[client] = cv_MinFireRate;
}

public OnConfigsExecuted()
{
	M249ROFDelay = BB_GetM249ROF();
	
	if(M249ROFDelay < 0.0)
		M249ROFDelay = 0.08;
}

public Action:Event_WeaponFirePre(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return Plugin_Continue;
		
	SetEventInt(hEvent, "EWS_inflictorRef", EntIndexToEntRef(GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon")));
	return Plugin_Changed;
}
public Action:Event_WeaponFirePost(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new String:WeaponName[50];
	
	GetEventString(hEvent, "weapon", WeaponName, sizeof(WeaponName));
	
	if(!StrEqual(WeaponName, "weapon_m249"))
		return;
	
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, GetEventInt(hEvent, "userid"));
	WritePackCell(DP, GetEventInt(hEvent, "EWS_inflictorRef", -1));
	
	RequestFrame(UpdateWeaponNextFire, DP);
	
}

public UpdateWeaponNextFire(Handle:DP)
{	
	ResetPack(DP);
	
	new client = GetClientOfUserId(ReadPackCell(DP));
	
	new inflictor = EntRefToEntIndex(ReadPackCell(DP));
	
	CloseHandle(DP);
	
	if(client == 0 || inflictor == INVALID_ENT_REFERENCE)
		return;
	
	DisableNextAmmo[client] = true;
	new Float:NextAttack = GetGameTime() + M249ROFDelay / CurrentFireRate[client];
	SetEntPropFloat(inflictor, Prop_Send, "m_flNextPrimaryAttack", NextAttack);
	SetEntPropFloat(inflictor, Prop_Send, "m_flNextSecondaryAttack", NextAttack);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", NextAttack);
	
	CurrentFireRate[client] += cv_IncreaseFireRate;
	
	if(CurrentFireRate[client] > cv_MaxFireRate)
		CurrentFireRate[client] = cv_MaxFireRate;
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
		
			
	DisableNextAmmo[client] = false;
	
	CurrentFireRate[client] = cv_MinFireRate;
	
	new weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	
	if(weapon == -1)
		return;
	
	new String:Classname[50];
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	if(!StrEqual(Classname, "weapon_m249"))
		return;
		
	RequestFrame(FullClipZeroBPAmmo, EntRefToEntIndex(weapon));
}

public FullClipZeroBPAmmo(Ref)
{
	new weapon = EntRefToEntIndex(Ref);
	
	if(weapon == INVALID_ENT_REFERENCE)
		return;
	
	new client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1)
		return;
	
	SetClientAmmo(client, weapon, 0);
	
	SetWeaponClip(weapon, cv_MaxAmmo);
}

public Action:Event_ItemPickup(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;

	new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if(weapon == -1)
		return;
	
	
	new String:WeaponName[64], String:Classname[64];
	GetEventString(hEvent, "item", WeaponName, sizeof(WeaponName));
	
	GetEdictClassname(weapon, Classname, sizeof(Classname));
	
	ReplaceStringEx(Classname, sizeof(Classname), "weapon_", "");

	if(!StrEqual(WeaponName, Classname))
		return;
	
	
	if(!StrEqual(WeaponName, "m249"))
		return;
	
	RequestFrame(ZeroBPAmmo, EntIndexToEntRef(weapon));
}

public ZeroBPAmmo(Ref)
{
	new weapon = EntRefToEntIndex(Ref);
	
	if(weapon == INVALID_ENT_REFERENCE)
		return;
	
	new client = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1)
		return;
	
	SetClientAmmo(client, weapon, 0);
	
	if(GetWeaponClip(weapon) > cv_MaxAmmo)
		SetWeaponClip(weapon, cv_MaxAmmo);
}
stock Float:BB_GetM249ROF()
{
	new Handle:keyValues = CreateKeyValues("items_game")
	if(!FileToKeyValues(keyValues, "scripts/items/items_game.txt"))
		return -1.0;
	
	if(!KvGotoFirstSubKey(keyValues))
		return -1.0;
	
	new String:WhatToFind[3][] = { "prefabs", "weapon_m249_prefab", "attributes" };
	
	new WhatToFindIndex, bool:Found;
	while(KvGotoNextKey(keyValues))
	{
		new String:buffer[64];
		KvGetSectionName(keyValues, buffer, sizeof(buffer));
	
		if(StrEqual(buffer, WhatToFind[WhatToFindIndex]))
		{
			WhatToFindIndex++;
			KvGotoFirstSubKey(keyValues);
			
			if(WhatToFindIndex == sizeof(WhatToFind))
			{	
				Found = true;
				break;
			}
		}
	}
	
	if(!Found)
		return -1.0;
	
	new Float:CycleTime = KvGetFloat(keyValues, "cycletime", -1.0);
	CloseHandle(keyValues);
	
	return CycleTime;
}

stock SetWeaponClip(weapon, clip)
{
	SetEntProp(weapon, Prop_Data, "m_iClip1", clip);
}

stock GetWeaponClip(weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

stock SetClientAmmo(client, weapon, ammo)
{
  SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo); // I have no idea what that does since I forgot lol.
    
  new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
  if(ammotype == -1) return;
  
  SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
}

stock GetClientAmmo(client, weapon)
{
  new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
  
  if(ammotype == -1) return -1;
  
  return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}