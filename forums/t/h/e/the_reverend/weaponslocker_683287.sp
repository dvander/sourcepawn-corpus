/*
weaponslocker.sp

Description:
	Commands that allow players or admins to simulate weapon lockers on TF2 players.
	
Versions:
 	1.1.0 - 9.26.2008 
 		* Cleaned up plugin error handling
 		* Fixed a bug that sets sniper SMG ammo to zero on sm_giveammo
 		* Added the requirement for SLAY access to admin commands
 		* Added logging of admin commands
 		* Added Convar to disable user console & chat commands
 
	1.0.0 - 9.8.2008
 		* Initial Release
 
Convars: 
	sm_weaponslocker_enable - Enables/Disables players abilities to use console or chat commands
		
Player Commands: ** Using ! or / substitutes in chat provides an easier method for execution
	
	sm_ammo - Fully reloads ammo & clip on a per class basis
	sm_health - Restores 100% health on a per class basis
	sm_metal - Gives Engineers 200 metal
	sm_uber - Gives Medics an immediate ubercharge
	
	
Admin Commands:

	sm_giveammo <target> - Fully reloads the targets ammo & clip
	sm_givehealth <target> <amount> - Sets the targets health to the specified amount (1-500)
	sm_givemetal <target> <amount> - Sets the targeted Engi's metal to the specified amount (1-200)
	sm_giveuber <target> <amount> - Sets the targeted Medic's ubercharge meter to the specified amount (1-100)
	
*/	

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

#define PL_VERSION "1.1.0"

public Plugin:myinfo = 
{
	name = "Weapons Locker OTG",
	author = "-<MisFits>-reverend",
	description = "Provides ammo, health, metal, and uber commands ",
	version = PL_VERSION,
	url = "http://www.misfitsclan.com"
}

new g_EngiMetal[MAXPLAYERS+1];
new g_TF_ChargeLevelOffset;
new Handle:cvarEnable;



static const TFClass_MaxAmmo[TFClassType][3] =
{
  {-1, -1, -1}, {32, 36, -1},
  {25, 75, -1}, {20, 32, -1},
  {20, 32, -1}, {150, -1, -1},
  {200, 32, -1}, {200, 32, -1},
  {24, -1, -1}, {32, 200, 200}
};

static const TFClass_MaxClip[TFClassType][2] = 
{
  {-1, -1}, {6, 12}, {25, 25}, {5, 6}, {5, 8}, 
  {40, -1}, {-1, 6}, {-1, 6}, {6, -1}, {6, 12}
};

static const TFClass_MaxHealth[TFClassType][1] = 
{
  {50}, {125}, {125}, {200}, {175}, 
  {150}, {300}, {175}, {125}, {125}
};

public OnPluginStart()
{
	
	CreateConVar("sm_weaponslocker_version", PL_VERSION, "Weapons Locker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_weaponslocker_enable", "1", "Enables/Disables players abilities to use console or chat commands", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_TF_ChargeLevelOffset = FindSendPropOffs("CWeaponMedigun", "m_flChargeLevel");
	
	RegConsoleCmd("sm_ammo", Command_ammo, "Fully reloads ammo and clip on a per class basis");
	RegConsoleCmd("sm_health", Command_health, "Restores 100 percent health on a per class basis");
	RegConsoleCmd("sm_metal", Command_metal, "Gives Engineers 200 metal");
	RegConsoleCmd("sm_uber", Command_uber, "Gives Medics an immediate ubercharge");
	RegAdminCmd("sm_giveammo", Command_GiveAmmo, ADMFLAG_SLAY, "sm_giveammo <name>");
	RegAdminCmd("sm_givehealth", Command_GiveHealth, ADMFLAG_SLAY, "sm_givehealth <name> [1-500]");
	RegAdminCmd("sm_givemetal", Command_GiveMetal, ADMFLAG_SLAY, "sm_givemetal <name> [1-200]");
	RegAdminCmd("sm_giveuber", Command_GiveUber, ADMFLAG_SLAY, "sm_giveuber <name> [1-100]");

}

public Action:Command_ammo(client, args)
{
	if (GetConVarInt(cvarEnable))
	{
		ReloadPlayer(client);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] WeaponsLocker commands are disabled");
		return Plugin_Handled;
	}
}

public Action:Command_health(client, args)
{
	if (GetConVarInt(cvarEnable))
	{
		HealPlayer(client);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] WeaponsLocker commands are disabled");
		return Plugin_Handled;
	}
}	

public Action:Command_metal(client, args)
{
	if (GetConVarInt(cvarEnable))
	{
		TF_SetMetalAmount(client, 200);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] WeaponsLocker commands are disabled");
		return Plugin_Handled;
	}
}

public Action:Command_uber(client, args)
{
	if (GetConVarInt(cvarEnable))
	{
		TF_SetUberLevel(client, 100);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] WeaponsLocker commands are disabled");
		return Plugin_Handled;
	}
}

public Action:Command_GiveAmmo(client, args)
{
	/* Show usage */
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_giveammo <name>");
		return Plugin_Handled;
	}
 
	/* Get the arguments */
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
 
	/* Try and find a matching player */
	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		/* FindTarget() automatically replies with the 
		 * failure reason.
		 */
		return Plugin_Handled;
	}
	
	new String:name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	new bool:alive = IsPlayerAlive(target);
	if (!alive)
	{
		return Plugin_Handled;
	}
		 
	ReloadPlayer(target);
	LogAction(client, target, "\"%L\" gave ammo to \"%L\"", client, target);
	
	return Plugin_Handled;
}

public Action:Command_GiveHealth(client, args)
{
	/* Show usage */
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givehealth <name> [amount]");
		return Plugin_Handled;
	}
 
	/* Get the arguments */
	new String:arg1[32], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
 
	/* Try and find a matching player */
	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		/* FindTarget() automatically replies with the 
		 * failure reason.
		 */
		return Plugin_Handled;
	}
	
	new String:name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	new bool:alive = IsPlayerAlive(target);
	if (!alive)
	{
		return Plugin_Handled;
	}
	
	new health = 200;
	/* Validate health amount */
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		health = StringToInt(arg2);
		if (health < 0 || health > 500)
		{
			return Plugin_Handled;
		}
	}
 
	SetEntityHealth(target, health);
	LogAction(client, target, "\"%L\" set health level on \"%L\"", client, target);
	
	return Plugin_Handled;
}

public Action:Command_GiveMetal(client, args)
{
	/* Show usage */
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_givemetal <name> [amount]");
		return Plugin_Handled;
	}
 
	/* Get the arguments */
	new String:arg1[32], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
 
	/* Try and find a matching player */
	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		/* FindTarget() automatically replies with the 
		 * failure reason.
		 */
		return Plugin_Handled;
	}
	
	new String:name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	new bool:alive = IsPlayerAlive(target);
	if (!alive)
	{
		return Plugin_Handled;
	}
	
	new TFClassType:class = TF2_GetPlayerClass(target);
	if (class != TFClass_Engineer)
	{
		return Plugin_Handled;
	}
	
	new metal = 200;
	/* Validate charge amount */
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		metal = StringToInt(arg2);
		if (metal < 0 || metal > 200)
		{
			return Plugin_Handled;
		}
	}
 
	TF_SetMetalAmount(target, metal);
	LogAction(client, target, "\"%L\" set metal level on \"%L\"", client, target);
	
	return Plugin_Handled;
}

public Action:Command_GiveUber(client, args)
{
	/* Show usage */
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_giveuber <name> [amount]");
		return Plugin_Handled;
	}
 
	/* Get the arguments */
	new String:arg1[32], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1));
 
	/* Try and find a matching player */
	new target = FindTarget(client, arg1);
	if (target == -1)
	{
		/* FindTarget() automatically replies with the 
		 * failure reason.
		 */
		return Plugin_Handled;
	}
	
	new String:name[MAX_NAME_LENGTH];
	GetClientName(target, name, sizeof(name));
	
	new bool:alive = IsPlayerAlive(target);
	if (!alive)
	{
		return Plugin_Handled;
	}
	
	new uber = 100;
	/* Validate uber amount */
	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		uber = StringToInt(arg2);
		if (uber < 0 || uber > 101)
		{
			return Plugin_Handled;
		}
	}
 
	TF_SetUberLevel(target, uber);
	LogAction(client, target, "\"%L\" set uber level on \"%L\"", client, target);
	
	return Plugin_Handled;
}

stock TF_SetMetalAmount(client, metal)
{
	g_EngiMetal[client] = metal;
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), metal, 4);  
}

stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
	{
		SetEntDataFloat(index, g_TF_ChargeLevelOffset, uberlevel*0.01, true);
	}
}

stock ReloadPlayer(client)
{
  if (!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
    return;

  new TFClassType:class = TF2_GetPlayerClass(client);

  GivePlayerAmmo(client, class);
  GivePlayerClip(client, class);
}

stock HealPlayer(client)
{
	if (!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
    	return;

	new TFClassType:class = TF2_GetPlayerClass(client);
 
	GivePlayerHealth(client, class);
}
 
stock GivePlayerAmmo(client, TFClassType:class)
{
  for (new i=0 ; i<sizeof(TFClass_MaxAmmo[]) ; i++)
  {
    if (TFClass_MaxAmmo[class][i] == -1) continue;

    SetEntData(
        client,
        FindSendPropInfo("CTFPlayer", "m_iAmmo") + ((i+1)*4),
        TFClass_MaxAmmo[class][i]);
  }
}

stock GivePlayerClip(client, TFClassType:class)
{
  for (new i=0 ; i<sizeof(TFClass_MaxClip[]) ; i++)
  {
    if (TFClass_MaxClip[class][i] == -1) continue;

    SetEntData(
      GetPlayerWeaponSlot(client, i),
      FindSendPropInfo("CTFWeaponBase", "m_iClip1"), 
      TFClass_MaxClip[class][i]);
  }
}

stock GivePlayerHealth(client, TFClassType:class)
{
	for (new i=0 ; i<sizeof(TFClass_MaxHealth[]) ; i++)
	{
		if (TFClass_MaxHealth[class][i] == -1) continue;
		
		SetEntityHealth(
			client,
			TFClass_MaxHealth[class][i]);
	}
}