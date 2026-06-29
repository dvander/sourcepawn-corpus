/*
* Fire Arrows (TF2) (SDKHooks version)
* Author(s): retsam
* File: firearrows.sp
* Description: Gives huntsman users flaming arrows!
*
*
*
* 0.2 - Added root flag check.
*
* 0.1	- Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.2"

new Handle:Cvar_Firearrow_Enabled = INVALID_HANDLE;
new Handle:Cvar_Firearrow_AdminFlag = INVALID_HANDLE;
new Handle:Cvar_Firearrow_AdminOnly = INVALID_HANDLE;

new g_cvarAdminOnly;

new bool:g_bIsPlayerAdmin[MAXPLAYERS + 1] = { false, ... };
new bool:g_bIsEnabled = true;

new String:g_sCharAdminFlag[32];

public Plugin:myinfo = 
{
	name = "Fire Arrows",
	author = "retsam",
	description = "Gives huntsman users flaming arrows!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=133698"
}

public OnPluginStart()
{
	CreateConVar("sm_firearrows_version", PLUGIN_VERSION, "Version of Fire Arrows", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Firearrow_Enabled = CreateConVar("sm_firearrows_enabled", "1", "Enable firearrows plugin?(1/0 = yes/no)");
	Cvar_Firearrow_AdminOnly = CreateConVar("sm_firearrows_adminonly", "0", "Enable firearrows for admins only? (1/0 = yes/no)");
	Cvar_Firearrow_AdminFlag = CreateConVar("sm_firearrows_adminflag", "b", "Admin flag to use if adminonly is enabled (only one).  Must be a in char format.");

	HookConVarChange(Cvar_Firearrow_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_Firearrow_AdminOnly, Cvars_Changed);

	//AutoExecConfig(true, "plugin.firearrows");
}

public OnClientPostAdminCheck(client)
{
	if(IsValidAdmin(client, g_sCharAdminFlag))
	{
		g_bIsPlayerAdmin[client] = true;
	}
	else
	{
		g_bIsPlayerAdmin[client] = false;
	}
}

public OnClientDisconnect(client)
{
	g_bIsPlayerAdmin[client] = false;
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_Firearrow_Enabled);
	GetConVarString(Cvar_Firearrow_AdminFlag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));

	g_cvarAdminOnly = GetConVarInt(Cvar_Firearrow_AdminOnly);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(!g_bIsEnabled)
	return;

	//PrintToChatAll("created %s", classname);
	if(StrEqual(classname, "tf_projectile_arrow"))
	{
		SDKHook(entity, SDKHook_Spawn, FlameArrow);
	}
}

public FlameArrow(entity)
{
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	//PrintToChatAll("Owner is: %d", owner);
	if(owner < 1)
	return;
	
	if(g_cvarAdminOnly && !g_bIsPlayerAdmin[owner])
	return;

	//PrintToChatAll("Setting arrow on fire!");  
	SetEntProp(entity, Prop_Send, "m_bArrowAlight", 1);
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if(!IsClientConnected(client))
	return false;
	
	new ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if((GetUserFlagBits(client) & ibFlags) == ibFlags)
		{
			return true;
		}
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT) 
	{
		return true;
	}
	
	return false;
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Firearrow_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_Firearrow_AdminOnly)
	{
		g_cvarAdminOnly = StringToInt(newValue);
	}
}

/*
public Hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client < 1 || !IsPlayerAlive(client))
	return;

	if(g_cvarAdminOnly && !g_bIsPlayerAdmin[client])
	return;

	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		new weapon = GetPlayerWeaponSlot(client, 0);
		if(IsValidEntity(weapon))
		{
			if(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 56)
			{
				if(g_FirearrowHandle[client] == INVALID_HANDLE)
				{
					g_FirearrowHandle[client] = CreateTimer(1.0, Timer_FireArrows, client, TIMER_REPEAT);
				}
			}
			else if(g_FirearrowHandle[client] != INVALID_HANDLE)
			{
				CloseHandle(g_FirearrowHandle[client]);
				g_FirearrowHandle[client] = INVALID_HANDLE;
			}
		}
	}
}

public Hook_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bIsEnabled)
	return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client < 1)
	return;
	
	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	new TFClassType:oldclass = TF2_GetPlayerClass(client);
	
	if(class == oldclass)
	return;
	
	if(class != TFClass_Sniper)
	{
		if(g_FirearrowHandle[client] != INVALID_HANDLE)
		{
	CloseHandle(g_FirearrowHandle[client]);
			g_FirearrowHandle[client] = INVALID_HANDLE;
			
			new weapon = GetPlayerWeaponSlot(client, 0);
			if(IsValidEntity(weapon))
			{
		PrintToChatAll("m_bArrowAlight is 1: disabling!");
		SetEntData(weapon, g_iArrowOffset, 0, 1, true);

	}
		}
	}
}

public Action:Timer_FireArrows(Handle:timer, any:client)
{
if(IsClientInGame(client))
	{
		if(!IsPlayerAlive(client))
		return Plugin_Continue;
		
		new weapon = GetPlayerWeaponSlot(client, 0);
		if(IsValidEntity(weapon))
		{
			//new flamed = GetEntProp(weapon, Prop_Send, "m_bArrowAlight");
			
			decl String:sWeapon[32];
			GetClientWeapon(client, sWeapon, sizeof(sWeapon));
			PrintToChatAll("Client weapon is: %s", sWeapon);
			if(StrEqual(sWeapon, "tf_weapon_compound_bow", false))
			{
				//PrintToChatAll("m_bArrowAlight is: %d", flamed);
				//if(flamed == 0)
				//if(offset == 0)
				//{
					PrintToChatAll("Setting arrow on fire!");
          //SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 1, 1);
          SetEntData(weapon, g_iArrowOffset, 1, 1, true);
				//}   
			}
			else
			{
				PrintToChatAll("Weapon not huntsman!");
        //if(offset == 1)
				//{
					PrintToChatAll("m_bArrowAlight is 1: disabling!");
          //SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 0, 1);
          //PrintToChatAll("m_bArrowAlight is: %d", flamed);
          SetEntData(weapon, g_iArrowOffset, 0, 1, true);
				//}
			}
		}
	}
	else
	{
		g_FirearrowHandle[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
*/
