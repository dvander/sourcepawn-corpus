#include <sourcemod>
#include <clientprefs>
#include <l4d_stocks>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define PLUGIN_VERSION "2.1"

new Handle:HasLaser;

public Plugin:myinfo =
{
	name = "[L4D2] Laser Sighted Weapons Fix",
	author = "Gowness, cravenge",
	description = "Fixes Weapons With Laser Sights By Removing Crosshairs.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("laser_sighted_weapons_fix-l4d2_version", PLUGIN_VERSION, "Laser Sighted Weapons Fix Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("upgrade_pack_added", OnUpgradePackAdded);
	HookEvent("pounce_end", OnHunterDead);
	HookEvent("pounce_stopped", OnHunterDead);
	HookEvent("player_death", OnChargerDead);
	HookEvent("charger_pummel_end", OnChargerPummelEnd);
	HookEvent("tongue_release", OnSmokerDead);
	HookEvent("choke_end", OnSmokerDead);
	HookEvent("tongue_pull_stopped", OnSmokerDead);
	HookEvent("choke_stopped", OnSmokerDead);
	HookEvent("drag_end", OnSmokerDead);
	HookEvent("jockey_ride_end", OnJockeyDead);
	HookEvent("player_afk", OnCrosshairFix);
	HookEvent("player_team", OnCrosshairFix2);
	HookEvent("player_incapacitated", OnCrosshairFix3);
	HookEvent("player_ledge_release", OnCrosshairFix3);
	HookEvent("revive_success", OnCrosshairFixEnd);
	HookEvent("player_death", OnCrosshairFixEnd2);
	HookEvent("player_hurt", OnTankPunched);
	
	HasLaser = RegClientCookie("has_laser_sight", "Does Weapon Have Laser Sights", CookieAccess_Private);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public OnPluginEnd()
{
	UnHook();
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	
	if(DoesPlayerHaveLaserWeapon(client))
	{
		SetClientCookie(client, HasLaser, "1");
	}
	else 
	{
		SetClientCookie(client, HasLaser, "0");
	}
	
	if (IsClientInGame(client))
	{
		ClientCommand(client, "crosshair 1"); 
	}
}

public OnClientCookiesCached(client)
{
	new String:cookie[5];
	GetClientCookie(client, HasLaser, cookie, 5);
}

public Action:OnHunterDead(Handle:event, const String:name[], bool:dontBroadcast)
{
	new pounced = GetClientOfUserId(GetEventInt(event, "victim"));
	if(pounced <= 0 || !IsClientInGame(pounced) || GetClientTeam(pounced) != 2 || IsFakeClient(pounced) || !IsPlayerAlive(pounced))
	{
		return;
	}
	
	CreateTimer(2.2, RecoverCrosshair, pounced);
}

public Action:OnChargerDead(Handle:event, const String:name[], bool:dontBroadcast)
{
	new charged = GetClientOfUserId(GetEventInt(event, "userid"));
	new charger = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(charger <= 0 || !IsClientInGame(charger) || GetClientTeam(charger) != 3 || GetEntProp(charger, Prop_Send, "m_zombieClass") != 6 || IsPlayerAlive(charger))
	{
		return;
	}
	
	if(charged > 0 && IsClientInGame(charged) && GetClientTeam(charged) == 2 && !IsFakeClient(charged) && IsPlayerAlive(charged))
	{
		CreateTimer(3.0, RecoverCrosshair, charged);
	}
}

public Action:OnChargerPummelEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new deadly = GetClientOfUserId(GetEventInt(event, "userid"));
	new friendly = GetClientOfUserId(GetEventInt(event, "victim"));
	if(deadly <= 0 || !IsClientInGame(deadly))
	{
		return;
	}
	
	if(friendly > 0 && IsClientInGame(friendly) && GetClientTeam(friendly) == 2 && !IsFakeClient(friendly) && IsPlayerAlive(friendly))
	{
		CreateTimer(4.0, RecoverCrosshair, friendly);
	}
}

public Action:OnSmokerDead(Handle:event, const String:name[], bool:dontBroadcast)
{
	new smoked = GetClientOfUserId(GetEventInt(event, "victim"));
	if(smoked <= 0 || !IsClientInGame(smoked) || GetClientTeam(smoked) != 2 || IsFakeClient(smoked) || !IsPlayerAlive(smoked))
	{
		return;
	}
	
	CreateTimer(1.0, RecoverCrosshair, smoked);
}

public Action:OnJockeyDead(Handle:event, const String:name[], bool:dontBroadcast)
{
	new jockeyed = GetClientOfUserId(GetEventInt(event, "victim"));
	if(jockeyed <= 0 || !IsClientInGame(jockeyed) || GetClientTeam(jockeyed) != 2 || IsFakeClient(jockeyed) || !IsPlayerAlive(jockeyed))
	{
		return;
	}
	
	CreateTimer(1.5, RecoverCrosshair, jockeyed);
}

public Action:RecoverCrosshair(Handle:timer, any:victim)
{
	new usedWeapon = GetPlayerWeaponSlot(victim, 0);
	if (IsShotgun(usedWeapon) || IsMG(usedWeapon) || IsSniper(usedWeapon) || IsBigGun(usedWeapon))
	{
		ClientCommand(victim, "crosshair 0");
	}
	else
	{
		ClientCommand(victim, "crosshair 1");
	}
	
	return Plugin_Stop;
}

public Action:OnCrosshairFix(Handle:event, const String:name[], bool:dontBroadcast)
{
	new human = GetClientOfUserId(GetEventInt(event, "player"));
	if(human <= 0 || IsFakeClient(human))
	{
		return;
	}
	
	ClientCommand(human, "crosshair 1");
}

public Action:OnCrosshairFix2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new player = GetClientOfUserId(GetEventInt(event, "userid"));
	if(player <= 0 || IsFakeClient(player))
	{
		return;
	}
	
	new cTeam = GetEventInt(event, "team");
	new oTeam = GetEventInt(event, "oldteam");
	if(oTeam == 2 && (cTeam == 1 || cTeam == 3))
	{
		ClientCommand(player, "crosshair 1");
	}
	else if((oTeam == 1 || oTeam == 3) && cTeam == 2)
	{
		CreateTimer(2.0, RecoverCrosshair, player);
	}
}

public Action:OnCrosshairFix3(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(victim <= 0 || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || IsFakeClient(victim))
	{
		return;
	}
	
	ClientCommand(victim, "crosshair 1");
}

public Action:OnCrosshairFixEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new revived = GetClientOfUserId(GetEventInt(event, "subject"));
	if(revived <= 0 || !IsClientInGame(revived) || GetClientTeam(revived) != 2 || IsFakeClient(revived))
	{
		return;
	}
	
	CreateTimer(0.5, RecoverCrosshair, revived);
}

public Action:OnCrosshairFixEnd2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new died = GetClientOfUserId(GetEventInt(event, "userid"));
	if(died <= 0 || !IsClientInGame(died) || GetClientTeam(died) != 2 || IsFakeClient(died))
	{
		return;
	}
	
	ClientCommand(died, "crosshair 1");
}

public Action:OnTankPunched(Handle:event, const String:name[], bool:dontBroadcast)
{
	new punched = GetClientOfUserId(GetEventInt(event, "userid"));
	if(punched <= 0 || !IsClientInGame(punched) || GetClientTeam(punched) != 2 || IsFakeClient(punched))
	{
		return;
	}
	
	new puncher = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(puncher > 0 && IsClientInGame(puncher) && GetClientTeam(puncher) == 3 && GetEntProp(puncher, Prop_Send, "m_zombieClass") == 8)
	{
		decl String:pWeapon[32];
		GetEventString(event, "weapon", pWeapon, 32);
		if(StrEqual(pWeapon, "tank_claw", true))
		{
			CreateTimer(2.5, RecoverCrosshair, punched);
		}
	}
}

public Action:OnUpgradePackAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(id);
	
	new upgrade = GetEventInt(event, "upgradeid");
	
	new String:class[256];
	GetEdictClassname(upgrade, class, sizeof(class));
	if (StrContains(class, "upgrade_laser_sight") > -1)
	{
		new weapon = GetPlayerWeaponSlot(client, 0);
		if(weapon <= 0 || !IsValidEntity(weapon))
		{
			ClientCommand(client, "crosshair 1");
		}
		
		if (IsShotgun(weapon) || IsMG(weapon) || IsSniper(weapon) || IsBigGun(weapon))
		{
			ClientCommand(client, "crosshair 0");
		}
	}
}

public Action:OnWeaponSwitch(client, weapon)
{
	if(IsShotgun(weapon) || IsMG(weapon) || IsSniper(weapon) || IsBigGun(weapon))
	{
		ClientCommand(client, "crosshair 0");
	}
	else
	{
		ClientCommand(client, "crosshair 1");
	}
	return Plugin_Continue;
}

bool:DoesPlayerHaveLaserWeapon(client)
{
	if(!IsClientInGame(client))
	{
		return false;
	}
	
	new weapon = GetPlayerWeaponSlot(client, 0);
	new bool:found;
	if(weapon > 0 && IsValidEntity(weapon))
	{
		decl String:netclass[128];
		GetEntityNetClass(weapon, netclass, 128);
		if (FindSendPropInfo(netclass, "m_upgradeBitVec") > -1)
		{
			new upgrades = L4D2_GetWeaponUpgrade(weapon);
			if(L4D2_CanWeaponUpgrade(weapon))
			{
				if(upgrades & L4D2_WEPUPGFLAG_LASER)
				{
					found = true;
				}
				else
				{
					found = false;
				}
			}
			else
			{
				found = false;
			}
		}
	}
	
	return found;
}

stock bool:L4D2_CanWeaponUpgrade(weapon)
{
	return (GetEntSendPropOffs(weapon, "m_upgradeBitVec") > -1);
}

stock L4D2_GetWeaponUpgrade(weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

stock bool:IsShotgun(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			if (StrEqual(classname, "weapon_autoshotgun") || StrEqual(classname, "weapon_pumpshotgun") || StrEqual(classname, "weapon_shotgun_chrome") || StrEqual(classname, "weapon_shotgun_spas"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsMG(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			if (StrEqual(classname, "weapon_smg") || StrEqual(classname, "weapon_smg_silenced") || StrEqual(classname, "weapon_smg_mp5") || StrEqual(classname, "weapon_rifle") || StrEqual(classname, "weapon_rifle_ak47") || StrEqual(classname, "weapon_rifle_desert") || StrEqual(classname, "weapon_rifle_sg552"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsSniper(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			if (StrEqual(classname, "weapon_hunting_rifle") || StrEqual(classname, "weapon_sniper_military") || StrEqual(classname, "weapon_sniper_scout"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsBigGun(entity)
{
	if (entity > 0 || entity < 2048)
	{
		new String:classname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			if (StrEqual(classname, "weapon_rifle_m60") || StrEqual(classname, "weapon_grenade_launcher"))
			{
				return true;
			}
		}
	}
	return false;
}

UnHook()
{
	for(new i = 1; i < 18; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
		}
	}
}

