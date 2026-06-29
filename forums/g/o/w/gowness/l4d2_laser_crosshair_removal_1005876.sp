#include <sourcemod>
#include <clientprefs>

#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#define PLUGIN_VERSION "1.2"
#define DEBUG 0

new LaserWeaponsKnown;
new LaserWeapons[128];
new LaserNeeded[33];
new Handle:HasLaser;


public Plugin:myinfo =
{
	name = "[L4D2] laser sight crosshair removal",
	author = "Gowness",
	description = "removes crosshair while holding a laser-equiped weapon",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{
	CreateConVar("l4d2_laser_crosshair_remover_version", PLUGIN_VERSION, "[L4D2] laser sight crosshair removal version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	HookEvent("upgrade_pack_added", Event_upgrade_pack_added);	
	//HookEvent("pounce_end", Survivor_Release);
	//HookEvent("tongue_release", Survivor_Release);
	//HookEvent("jockey_ride_end", Survivor_Release);
	//HookEvent("charger_carry_end", Survivor_Release);
	
	HasLaser = RegClientCookie("has_laser_sight", "Does the client have lasersights", CookieAccess_Private);
	
	RegConsoleCmd("upgrade_add", Command_Upgrade_Add);
	RegConsoleCmd("upgrade_remove", Command_Upgrade_Remove);
}

public OnMapStart()
{
	#if DEBUG
	PrintToChatAll("map start");
	#endif

}

public OnClientPutInServer(client)
{
	#if DEBUG
	PrintToChatAll("hooked %i",client);
	#endif
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public OnClientConnected(client)
{
	#if DEBUG
	LogMessage("%i joined",client);
	#endif
}

public OnPluginEnd()
{
	UnHook();
}

public OnMapEnd()
{
	#if DEBUG
	PrintToChatAll("map end");
	#endif
	for(new i = 0; i<33;i++)
		LaserNeeded[i] = 0;
	for(new i = 0; i < 128; i++)
		LaserWeapons[i] = 0;
}

public OnClientDisconnect(client)
{
	#if DEBUG
	LogMessage("unhooked %i",client);
	#endif
	SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);

	if(DoesPlayerHaveLaserWeapon(client))
		SetClientCookie(client,HasLaser,"1");
	else 
		SetClientCookie(client,HasLaser,"0");
		
	if (IsClientInGame(client))
	{
		ClientCommand(client, "crosshair 1"); 
	}
}

public OnClientCookiesCached(client)
{
	#if DEBUG
	LogMessage("Loaded Cookie state: %s", AreClientCookiesCached(client) ? "YES" : "NO");
	#endif
	
	new String:cookie[5];
	GetClientCookie(client,HasLaser,cookie,5);
	LogMessage("give %i lasersight?: %s", client,cookie);
	if(StringToInt(cookie[0])) AddPlayerToArray(client) ;
	
}

public Action:Event_upgrade_pack_added(Handle:event, const String:name[], bool:dontBroadcast)
{
	new id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(id);
	new upgrade = GetEventInt(event, "upgradeid");
	new String:class[256];
	/* upgrade_ammo_explosive, upgrade_ammo_incendiary, upgrade_laser_sight */
	GetEdictClassname(upgrade, class, sizeof(class));
	#if DEBUG
	PrintToChatAll("upgrade %s added",class);
	#endif
	//Laser Sight
	if (StrContains(class, "upgrade_laser_sight") > -1)
	{
		AddWeaponToArray(GetPlayerWeaponSlot(client,0));
		new String:weapon[32];
		GetClientWeapon(client,weapon, sizeof(weapon));
		if (isWeaponPrimary(weapon))
		{
			ClientCommand(client, "crosshair 0");
		}
	}
}

public Action:OnWeaponSwitch(client, weapon)
{
	decl String:sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if(DoesPlayerNeedLaser(client))
	{
		AddWeaponToArray(GetPlayerWeaponSlot(client,0));
	}
	
	
	#if DEBUG
	PrintToChatAll("switched to %s. id: %i",sWeapon,weapon);
	#endif
		
    if(isWeaponPrimary(sWeapon))
	{
		new newWeapon = GetPlayerWeaponSlot(client,0);
		if (DoesWeaponHaveLaser(newWeapon))
			ClientCommand(client, "crosshair 0");
		else
			ClientCommand(client, "crosshair 1");
	}
	else
			ClientCommand(client, "crosshair 1");
    return Plugin_Continue;
}

public Action:Command_Upgrade_Add(client,args)
{	
	new String:text[192];
	
	GetCmdArgString(text, sizeof(text));
	
	#if DEBUG
	PrintToChatAll("upgrade_add %s used",text);
	#endif

	//Laser Sight
	if (StrContains(text, "LASER_SIGHT") > -1)
	{
		AddWeaponToArray(GetPlayerWeaponSlot(client,0));
		new String:weapon[32];
		GetClientWeapon(client,weapon, sizeof(weapon));
		if (isWeaponPrimary(weapon))
		{
			ClientCommand(client, "crosshair 0");
		}
	}
}

public Action:Command_Upgrade_Remove(client,args)
{
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	#if DEBUG
	PrintToChatAll("upgrade_remove %s used",text);
	#endif

	//Laser Sight
	if (StrContains(text, "LASER_SIGHT") > -1)
	{
		RemoveWeaponFromArray(GetPlayerWeaponSlot(client,0));
		ClientCommand(client, "crosshair 1"); 
	}
	
}

public Action:Survivor_Release(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*new victim = GetEventInt(event, "victim");
	new victimid = GetClientOfUserId(victim);
	#if DEBUG
	new string:VictimName[MAX_NAME_LENGTH];
	GetVictimName(victimid,VictimName,MAX_NAME_LENGTH);
	PrintToChatAll("survivor %s released",VictimName);
	#endif
	new string:VictimWeapon = GetClientWeapon(victim);
	if(isWeaponPrimary(VictimWeapon) && DoesWeaponHaveLaser(GetPlayerWeaponSlot(client,0)))
		ClientCommand(client, "crosshair 0"); */
}

bool:isWeaponPrimary(String:weapon[])
{
	if ((StrContains(weapon, "shotgun") > -1) ||
		(StrContains(weapon, "grenade_launcher") > -1) ||
		(StrContains(weapon, "rifle") > -1) ||
		(StrContains(weapon, "smg") > -1) ||
		(StrContains(weapon, "sniper_scout") > -1) ||
		(StrContains(weapon, "sniper_military") > -1))
		return true;
	else
		return false;
}

AddWeaponToArray(weapon)
{
	#if DEBUG
	PrintToChatAll("added %i to weapons with lasers",weapon);
	#endif
	
	LaserWeapons[LaserWeaponsKnown] = weapon;
	LaserWeaponsKnown += 1;
}

RemoveWeaponFromArray(weapon)
{
	#if DEBUG
	PrintToChatAll("attempting to remove %i from weapons with lasers",weapon);
	#endif
	for( new i = 0; i < LaserWeaponsKnown;i++)
	{
		if (LaserWeapons[i] == weapon)
		{
			#if DEBUG
			PrintToChatAll("found %i, removing from weapons with lasers",weapon);
			#endif
			for( new j = i; j < LaserWeaponsKnown;j++)
			{
				LaserWeapons[j] = LaserWeapons[j+1];
			}
			LaserWeaponsKnown -=1;
			break;
		}
	}
	
}

AddPlayerToArray(client)
{
	#if DEBUG
	PrintToChatAll("added %i to players needing lasers",client);
	#endif
	if(IsClientInGame(client))
	{	
		if(!IsFakeClient(client))
		{
			new id = GetClientOfUserId(client);
			LaserNeeded[id] = 1;
		}
	}
}

bool:DoesWeaponHaveLaser(weapon)
{	
	new bool:found = false;
	for(new i = 0; i <= LaserWeaponsKnown; i++)
	{
		if(weapon == LaserWeapons[i])
		{
			found = true;
			break;
		}
	}
	#if DEBUG
	if(found) PrintToChatAll("looking for %i... found",weapon);
	else PrintToChatAll("looking for %i... not found",weapon);
	#endif
	return found;
}

bool:DoesPlayerHaveLaserWeapon(client)
{
	new weapon = GetPlayerWeaponSlot(client,0);
	new bool:found;
	if(DoesWeaponHaveLaser(weapon))
		found = true;
	else
		found = false;
	#if DEBUG
	if(found) LogMessage("player %i has a laser sight",client);
	else LogMessage("player %i does not have a laser sight",client);
	#endif
	return found;
}

bool:DoesPlayerNeedLaser(client)
{	
	new bool:found = false;
	new id = GetClientOfUserId(client);
	if(LaserNeeded[id])
	{
		found = true;
		if(GetPlayerWeaponSlot(client,0) > 0)
			LaserNeeded[id] = 0;
	}
	#if DEBUG
	if(found) PrintToChatAll("looking for %i... found",client);
	else PrintToChatAll("looking for %i... not found",client);
	#endif
	return found;
}

UnHook()
{
	for(new i = 1; i < 18; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i))
		{
			
			#if DEBUG
			new client = GetClientUserId(i);
			PrintToChatAll("unhooked %i",client);
			#endif
			SDKUnhook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
		}
	}
}

