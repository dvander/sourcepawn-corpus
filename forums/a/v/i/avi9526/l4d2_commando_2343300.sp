//──────────────────────────────────────────────────────────────────────────────
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//──────────────────────────────────────────────────────────────────────────────
#define	STR_LEN		64
//──────────────────────────────────────────────────────────────────────────────
#define	LOG_PREFIX	"[L4D2 Commando]"
//──────────────────────────────────────────────────────────────────────────────
public Plugin:myinfo = 
{
	name = "Using two main gun",
	author = "Ca sĩ lệ rơi, avi9526",
	description = "Using two main gun",
	version = "2.0.1",
	url = "/dev/null",
};
//──────────────────────────────────────────────────────────────────────────────
// Store information about second primary gun
enum PlrData
{
	String:	PlrWeap[STR_LEN],	// internal weapon name
			PlrAmmo,			// currently available ammo
			PlrClip,			// ammo loaded to gun - clip size
			PlrUpg,
			PlrUpgAmmo,
	bool:	PlrLock				// prevent one hook while working on another one
}
//──────────────────────────────────────────────────────────────────────────────
// Store data of all players
new Players[MAXPLAYERS+1][PlrData];
//──────────────────────────────────────────────────────────────────────────────
new String:	Game[STR_LEN];
//──────────────────────────────────────────────────────────────────────────────
public OnPluginStart()
{
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("player_death", Player_Death);
	HookEvent("player_team", Player_Team);
	
	InitAllClientData();
	
	GetGameFolderName(Game, sizeof(Game));
	
// 	HookEvent("ammo_pickup", HookAmmoPickup);
	
}
//──────────────────────────────────────────────────────────────────────────────
public OnClientPutInServer(Client)
{
	InitClientData(Client);
	SDKHook(Client, SDKHook_WeaponEquip, HookWeaponEquip);
	SDKHook(Client, SDKHook_WeaponEquipPost, HookWeaponEquipPost);
	SDKHook(Client, SDKHook_WeaponDropPost, HookWeaponDropPost);
	SDKHook(Client, SDKHook_WeaponSwitchPost, HookWeaponSwitchPost);
}
//──────────────────────────────────────────────────────────────────────────────
public OnClientDisconnect(Client)
{
	FreeClientData(Client);
	if (IsClientInGame(Client))  
	{  
		SDKUnhook(Client, SDKHook_WeaponEquip, HookWeaponEquip);
		SDKUnhook(Client, SDKHook_WeaponEquipPost, HookWeaponEquipPost);
		SDKUnhook(Client, SDKHook_WeaponDropPost, HookWeaponDropPost);
		SDKUnhook(Client, SDKHook_WeaponSwitchPost, HookWeaponSwitchPost);
	}
}
//──────────────────────────────────────────────────────────────────────────────
InitClientData(Client)
{
	ResetPlrData(Players[Client]);
}
//──────────────────────────────────────────────────────────────────────────────
InitAllClientData()
{
	for (new Client = 1; Client <= MAXPLAYERS; Client ++)
	{
		InitClientData(Client);
		if (IsValidAlivePlayer(Client))  
		{
			SDKHook(Client, SDKHook_WeaponEquip, HookWeaponEquip);
			SDKHook(Client, SDKHook_WeaponEquipPost, HookWeaponEquipPost);
			SDKHook(Client, SDKHook_WeaponDropPost, HookWeaponDropPost);
			SDKHook(Client, SDKHook_WeaponSwitchPost, HookWeaponSwitchPost);
		}
	}
}
//──────────────────────────────────────────────────────────────────────────────
FreeClientData(Client)
{
	ResetPlrData(Players[Client]);
}
//──────────────────────────────────────────────────────────────────────────────
FreeAllClientData()
{
	for (new Client = 1; Client <= MAXPLAYERS; Client ++)
	{
		FreeClientData(Client);
	}
}
//──────────────────────────────────────────────────────────────────────────────
ResetPlrData(Plr[PlrData])
{
	Format(Plr[PlrWeap], STR_LEN, "weapon_none");
	Plr[PlrAmmo]	= 0;
	Plr[PlrClip]	= 0;
	Plr[PlrUpg]		= 0;
	Plr[PlrUpgAmmo]	= 0;
	Plr[PlrLock]	= false;
}
//──────────────────────────────────────────────────────────────────────────────
CopyPlrData(PlrSrc[PlrData], PlrDst[PlrData])
{
	Format(PlrDst[PlrWeap], STR_LEN, PlrSrc[PlrWeap])
	PlrDst[PlrAmmo]		= PlrSrc[PlrAmmo];
	PlrDst[PlrClip]		= PlrSrc[PlrClip];
	PlrDst[PlrUpg]		= PlrSrc[PlrUpg];
	PlrDst[PlrUpgAmmo]	= PlrSrc[PlrUpgAmmo];
	PlrDst[PlrLock]		= PlrSrc[PlrLock];
}
//──────────────────────────────────────────────────────────────────────────────
// Is client have second primary gun
bool: Is2Weap(Client)
{
	new bool: Result;
	Result = !StrEqual(Players[Client][PlrWeap], "weapon_none");
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
// Is client holding primary gun
bool: IsPrimActive(Client)
{
	new bool: Result;
	new WeapActEnt = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
	new WeapPrimEnt = GetPlayerWeaponSlot(Client, 0);
	Result = (WeapActEnt == WeapPrimEnt && WeapActEnt > 0);
	return Result
}
//──────────────────────────────────────────────────────────────────────────────
// Is client have primary gun
bool: IsHavePrim(Client)
{
	new bool: Result;
	new WeapEnt = GetPlayerWeaponSlot(Client, 0);
	Result = (WeapEnt > 0 && IsValidEntity(WeapEnt))
	// LogAction(-1, -1, "%s [%s] WeapEnt = %i for '%L'", LOG_PREFIX, "IsHavePrim", WeapEnt, Client);
	return Result
}
//──────────────────────────────────────────────────────────────────────────────
// Is weapon for primary slot
// This function does not check input arguments
bool: IsWeapPrim(WeapEnt)
{
	new bool: Result = false;
	
	if (WeapEnt > 0 && IsValidEntity(WeapEnt))
	{
		decl String: WeapName[STR_LEN]; 
		GetEdictClassname(WeapEnt, WeapName, STR_LEN);
		Result = (StrEqual(WeapName, "weapon_rifle") || StrEqual(WeapName, "weapon_rifle_sg552") ||
			StrEqual(WeapName, "weapon_rifle_desert") || StrEqual(WeapName, "weapon_rifle_ak47") ||
			StrEqual(WeapName, "weapon_smg") || StrEqual(WeapName, "weapon_smg_silenced") ||
			StrEqual(WeapName, "weapon_smg_mp5") || StrEqual(WeapName, "weapon_pumpshotgun") ||
			StrEqual(WeapName, "weapon_shotgun_chrome") || StrEqual(WeapName, "weapon_autoshotgun") ||
			StrEqual(WeapName, "weapon_shotgun_spas") || StrEqual(WeapName, "weapon_hunting_rifle") ||
			StrEqual(WeapName, "weapon_sniper_scout") || StrEqual(WeapName, "weapon_sniper_military") ||
			StrEqual(WeapName, "weapon_sniper_awp") || StrEqual(WeapName, "weapon_grenade_launcher") ||
			StrEqual(WeapName, "weapon_rifle_m60"))
	}
	
	return Result;
}
//──────────────────────────────────────────────────────────────────────────────
CreateWeaponEnt(String:classname[])
{
	if(StrEqual(classname, ""))return 0;
	if(StrContains(classname, "weapon_melee_")<0)
	{
		new ent=CreateEntityByName(classname);
		DispatchSpawn(ent); 
		return ent;
	}
	else
	{
		new ent=CreateEntityByName("weapon_melee"); 
		if(StrEqual(classname, "weapon_melee_fireaxe"))DispatchKeyValue( ent, "melee_script_name",  "fireaxe" ); 
		else if(StrEqual(classname, "weapon_melee_baseball_bat"))DispatchKeyValue( ent, "melee_script_name",  "baseball_bat" );
		else if(StrEqual(classname, "weapon_melee_crowbar"))DispatchKeyValue( ent, "melee_script_name",  "crowbar" );		
		else if(StrEqual(classname, "weapon_melee_electric_guitar"))DispatchKeyValue( ent, "melee_script_name",  "electric_guitar" );		
		else if(StrEqual(classname, "weapon_melee_cricket_bat"))DispatchKeyValue( ent, "melee_script_name",  "cricket_bat" );		
		else if(StrEqual(classname, "weapon_melee_frying_pan"))DispatchKeyValue( ent, "melee_script_name",  "frying_pan" );		
		else if(StrEqual(classname, "weapon_melee_golfclub"))DispatchKeyValue( ent, "melee_script_name",  "golfclub" );		
		else if(StrEqual(classname, "weapon_melee_machete"))DispatchKeyValue( ent, "melee_script_name",  "machete" );	
		else if(StrEqual(classname, "weapon_melee_katana"))DispatchKeyValue( ent, "melee_script_name",  "katana" );		
		else if(StrEqual(classname, "weapon_melee_tonfa"))DispatchKeyValue( ent, "melee_script_name",  "tonfa" ); 
		else if(StrEqual(classname, "weapon_melee_riotshield"))DispatchKeyValue( ent, "melee_script_name",  "riotshield" );
		else if(StrEqual(classname, "weapon_melee_hunting_knife"))DispatchKeyValue( ent, "melee_script_name",  "hunting_knife" );
		DispatchSpawn(ent);
		return ent;
	}
	
}
//──────────────────────────────────────────────────────────────────────────────
GiveWeapon(Client, String: WeapName[])
{
	// LogAction(-1, -1, "%s [%s] Give weapon '%s' to '%L'", LOG_PREFIX, "GiveWeapon", WeapName, Client);
	new WeapEnt = CreateWeaponEnt(WeapName);
	if (WeapEnt > 0)
	{
		EquipPlayerWeapon(Client, WeapEnt);
		SetEntPropEnt(Client, Prop_Data, "m_hActiveWeapon", WeapEnt);		
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Give saved weapon to player
GiveSavedWeap(Client)
{
	// LogAction(-1, -1, "%s [%s] Give saved weapon to '%L'", LOG_PREFIX, "GiveSavedWeap", Client);
	GiveWeapon(Client, Players[Client][PlrWeap]);
	new SlotEnt = GetPlayerWeaponSlot(Client, 0);
	if (SlotEnt != -1)
	{
		SetClientWeaponInfo(Client, Players[Client][PlrAmmo], Players[Client][PlrClip]);
		SetEntProp(SlotEnt, Prop_Send, "m_upgradeBitVec", Players[Client][PlrUpg]);
		SetEntProp(SlotEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded",  Players[Client][PlrUpgAmmo]);
	}
	else
	{
		// LogAction(-1, -1, "%s [%s] GetPlayerWeaponSlot return wrong entity for '%L'", LOG_PREFIX, "GiveSavedWeap", Client);
	}
}
//──────────────────────────────────────────────────────────────────────────────
// Replace client weapon with stored in variable weapon and save previous weapon to that variable
// This function does not do much data checks, make sure data is correct or be ready for failure
SwitchWeap(Client, GiveWeap = true)
{
	// LogAction(-1, -1, "%s [%s] [BEGIN] Weapon %s saved for '%L'", LOG_PREFIX, "SwitchWeap", Players[Client][PlrWeap], Client);
	new SlotEnt = GetPlayerWeaponSlot(Client, 0);
	new Data[PlrData];
	if (SlotEnt > 0 && IsValidEntity(SlotEnt))
	{
		GetEdictClassname(SlotEnt, Data[PlrWeap], STR_LEN);
		GetClientWeaponInfo(Client, Data[PlrAmmo], Data[PlrClip]);
		Data[PlrUpg] = GetEntProp(SlotEnt, Prop_Send, "m_upgradeBitVec");
		Data[PlrUpgAmmo] = GetEntProp(SlotEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
		RemovePlayerItem(Client, SlotEnt);
		AcceptEntityInput(SlotEnt, "kill");
	}
	else
	{
		Format(Data[PlrWeap], STR_LEN, "weapon_none");
	}
	if (GiveWeap)
	{
		GiveSavedWeap(Client)
	}
	CopyPlrData(Data, Players[Client]);
	// LogAction(-1, -1, "%s [%s] [END] Weapon %s saved for '%L'", LOG_PREFIX, "SwitchWeap", Players[Client][PlrWeap], Client);
}
//──────────────────────────────────────────────────────────────────────────────
// Check if client is normal player that already in game
stock IsValidAlivePlayer(Client)
{
	if ((Client <= 0) || (Client > MaxClients) || (!IsClientInGame(Client)))
	{
		return false;
	}
	
	if (IsFakeClient(Client) || GetClientTeam(Client) != 2 || !IsPlayerAlive(Client))
	{
		return false;
	}
	
	return true;
}
//──────────────────────────────────────────────────────────────────────────────
public Action: RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	FreeAllClientData();
}
//──────────────────────────────────────────────────────────────────────────────
public Action: Player_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid")); 
	ResetPlrData(Players[Client]);
}
//──────────────────────────────────────────────────────────────────────────────
public Action: Player_Team(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new NewTeam = GetEventInt(event, "team");
	if (NewTeam == 3)	// player joined spectator - clear his data
	{
		new Client = GetClientOfUserId(GetEventInt(event, "userid"));
		ResetPlrData(Players[Client]);
	}
}
//──────────────────────────────────────────────────────────────────────────────
public Action: HookWeaponEquip(Client, Weapon)  
{
	if (IsValidAlivePlayer(Client) && !Players[Client][PlrLock])
	{
		Players[Client][PlrLock] = true;
		if (IsWeapPrim(Weapon))	// check if weapon is for primary slot
		{
			// LogAction(-1, -1, "%s [%s] Player '%L' tries to take another primary weapon", LOG_PREFIX, "HookWeaponEquip", Client);
			if (IsHavePrim(Client))
			{
				if (!Is2Weap(Client))	// check if player don't have second primary gun already and don't have primary weapon at all
				{
					// LogAction(-1, -1, "%s [%s] Save current primary weapon before '%L' takes new one", LOG_PREFIX, "HookWeaponEquip", Client);
					SwitchWeap(Client, false);	// save current weapon, but don't give one that stored in variable (it must be empty btw)
// 					PrintHintText(Client, "You now have two primary guns")
				}
				else
				{
					// LogAction(-1, -1, "%s [%s] Second primary weapon '%s' already saved for '%L'", LOG_PREFIX, "HookWeaponEquip", Players[Client][PlrWeap], Client);
				}
			}
			else
			{
				// LogAction(-1, -1, "%s [%s] No primary weapon at all for '%L'", LOG_PREFIX, "HookWeaponEquip", Client);
			}
		}
		else
		{
			// LogAction(-1, -1, "%s [%s] Weapon not for primary slot taken by '%L'", LOG_PREFIX, "HookWeaponEquip", Client);
		}
		// 		Players[Client][PlrLock] = false;	// unlock in hook HookWeaponEquipPost to prevent HookWeaponSwitchPost called before this finished
	}
	return Plugin_Continue;
}
//──────────────────────────────────────────────────────────────────────────────
public Action: HookWeaponEquipPost(Client, Weapon)  
{
	if (IsValidAlivePlayer(Client) && Players[Client][PlrLock])
	{
		Players[Client][PlrLock] = false;
	}
	return Plugin_Continue;
}
//──────────────────────────────────────────────────────────────────────────────
public Action: HookWeaponDropPost(Client, Weapon)  
{
	if (IsValidAlivePlayer(Client) && !Players[Client][PlrLock])
	{
		Players[Client][PlrLock] = true;
		if (!IsHavePrim(Client))	// check if client have no weapon in primary slot now
		{
			// LogAction(-1, -1, "%s [%s] Player '%L' has dropped his primary weapon", LOG_PREFIX, "HookWeaponDropPost", Client);
			if (Is2Weap(Client))	// check if player have second primary gun
			{
				// LogAction(-1, -1, "%s [%s] Give saved weapon to '%L' because he has dropped one of his primary weapon", LOG_PREFIX, "HookWeaponDropPost", Client);
				SwitchWeap(Client);
			}
			else
			{
				// LogAction(-1, -1, "%s [%s] Client '%L' dropped his primary weapon, but he don't have another one", LOG_PREFIX, "HookWeaponDropPost", Client);
			}
		}
		else
		{
			// LogAction(-1, -1, "%s [%s] Client has dropped not primary gun '%L'", LOG_PREFIX, "HookWeaponDropPost", Client);
		}
		Players[Client][PlrLock] = false;
	}
	return Plugin_Continue;
}
//──────────────────────────────────────────────────────────────────────────────
// Need to support plugins that remove weapon from players like drop item plugin
public Action: HookWeaponSwitchPost(Client, Weapon)  
{
	if (IsValidAlivePlayer(Client) && !Players[Client][PlrLock])
	{
		Players[Client][PlrLock] = true;
		if (!IsHavePrim(Client))	// check if client have no weapon in primary slot now
		{
			// LogAction(-1, -1, "%s [%s] Player '%L' don't have primary weapon", LOG_PREFIX, "HookWeaponSwitch", Client);
			if (Is2Weap(Client))	// check if player have second primary gun
			{
				// LogAction(-1, -1, "%s [%s] Give saved weapon to '%L' because he has dropped one of his primary weapon", LOG_PREFIX, "HookWeaponSwitch", Client);
				SwitchWeap(Client);
			}
			else
			{
				// LogAction(-1, -1, "%s [%s] Client '%L' don't have another primary gun", LOG_PREFIX, "HookWeaponSwitch", Client);
			}
		}
		else
		{
			// Check if player don't have ammo in primary gun - try give second primary
			new Ammo = 0;
			new Clip = 0;
			GetClientWeaponInfo(Client, Ammo, Clip);
			if ((Ammo + Clip) <= 0 && Is2Weap(Client) && (Players[Client][PlrAmmo] + Players[Client][PlrClip]) > 0)
			{
				SwitchWeap(Client);
				Players[Client][PlrClip] = 0;
				Players[Client][PlrAmmo] = 1;
				if (StrEqual(Players[Client][PlrWeap], "weapon_grenade_launcher"))
				{
					Format(Players[Client][PlrWeap], STR_LEN, "weapon_none");
				}
			}
		}
		Players[Client][PlrLock] = false;
	}
	return Plugin_Continue;
}
//──────────────────────────────────────────────────────────────────────────────
// Hard way to get hook on client side 'slot1' command
public Action: OnPlayerRunCmd(Client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (weapon != 0)
	{
		if (IsValidAlivePlayer(Client) && !Players[Client][PlrLock])
		{
			Players[Client][PlrLock] = true;
			new SlotEnt = GetPlayerWeaponSlot(Client, 0);
			if (SlotEnt > 0 && SlotEnt == weapon)
			{
				if (IsPrimActive(Client))
				{
					if (Is2Weap(Client))	// check if player have second primary gun
					{
						// LogAction(-1, -1, "%s [%s] Slot1 by '%L'", LOG_PREFIX, "OnPlayerRunCmd", Client);
 						SwitchWeap(Client);
					}
				}
			}
			Players[Client][PlrLock] = false;
		}
	}
 	return Plugin_Continue;
}
//──────────────────────────────────────────────────────────────────────────────
GetClientWeaponInfo(client, &ammo, &clip)
{
	new slot=0;
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		new String:weapon[32]; 
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), weapon, 32);
		new bool:set=false;
		if (slot == 0)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
			if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
			{
				ammo = GetEntData(client, ammoOffset+(12));
				if(set)SetEntData(client, ammoOffset+(12), 0);
			}
			else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
			{
				ammo = GetEntData(client, ammoOffset+(20));
				if(set)SetEntData(client, ammoOffset+(20), 0);
			}
			else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
			{
				ammo = GetEntData(client, ammoOffset+(28));
				if(set)SetEntData(client, ammoOffset+(28), 0);
			}
			else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
			{
				ammo = GetEntData(client, ammoOffset+(32));
				if(set)SetEntData(client, ammoOffset+(32), 0);
			}
			else if (StrEqual(weapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(36));
				if(set)SetEntData(client, ammoOffset+(36), 0);
			}
			else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
			{
				ammo = GetEntData(client, ammoOffset+(40));
				if(set)SetEntData(client, ammoOffset+(40), 0);
			}
			else if (StrEqual(weapon, "weapon_grenade_launcher"))
			{
				ammo = GetEntData(client, ammoOffset+(68));
				if(set)SetEntData(client, ammoOffset+(68), 0);
			}
		}
	}
}

SetClientWeaponInfo(client, ammo, clip)
{ 
	new slot=0;
	new ent=GetPlayerWeaponSlot(client, slot);
	if (ent>0)
	{
		new String:weapon[32];  
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(ent, weapon, 32);
		new bool:set=true;

		SetEntProp(ent, Prop_Send, "m_iClip1", clip); 
		if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
		{
			if(set)SetEntData(client, ammoOffset+(12), ammo);
		}
		else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
		{
			if(set)SetEntData(client, ammoOffset+(20), ammo);
		}
		else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
		{
			if(set)SetEntData(client, ammoOffset+(28), ammo);
		}
		else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
		{
			if(set)SetEntData(client, ammoOffset+(32), ammo);
		}
		else if (StrEqual(weapon, "weapon_hunting_rifle"))
		{
			if(set)SetEntData(client, ammoOffset+(36), ammo);
		}
		else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
		{
			if(set)SetEntData(client, ammoOffset+(40), ammo);
		}
		else if (StrEqual(weapon, "weapon_grenade_launcher"))
		{
			if(set)SetEntData(client, ammoOffset+(68), ammo);
		}
	} 
}

