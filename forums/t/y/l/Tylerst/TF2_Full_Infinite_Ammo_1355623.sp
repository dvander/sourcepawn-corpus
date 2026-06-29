#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "2.2.6_Final"


public Plugin:myinfo = 
{
	
	name = "TF2 Full Infinite Ammo",
	
	author = "Tylerst",

	description = "Infinite use for just about everything",

	version = PLUGIN_VERSION,
	
	url = "None"

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

new bool:g_fiammo[MAXPLAYERS+1];
new bool:g_roundwin;

new Handle:hChat = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;
new Handle:hBatAmmo = INVALID_HANDLE;
new Handle:hAll = INVALID_HANDLE;
new Handle:hAdminOnly = INVALID_HANDLE;
new Handle:hRoundWin = INVALID_HANDLE;
new Handle:hWaitingForPlayers = INVALID_HANDLE;

new offset_ammo;
new offset_clip;

public OnPluginStart()

{

	LoadTranslations("common.phrases");

	CreateConVar("sm_fia_version", PLUGIN_VERSION, "Full Infinite Ammo TF2", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	hChat = CreateConVar("sm_fia_chat", "1", "Enable/Disable Showing ammo changes in chat");
	hLog = CreateConVar("sm_fia_log", "1", "Enable/Disable Logging ammo changes");
	hBatAmmo = CreateConVar("sm_fia_batammo", "1", "AdminOnly/All/Disable '2/1/0' infinite sandman/wrap assassin balls");
	hAll = CreateConVar("sm_fia_all", "0", "Enable/Disable '1/0' Infinite Ammo for everyone");
	hAdminOnly = CreateConVar("sm_fia_adminonly", "0", "Enable/Disable '1/0' admin only for infinite ammo");
	hRoundWin = CreateConVar("sm_fia_roundwin", "0", "Enable/Disable '1/0' Infinite Ammo on round win");
	hWaitingForPlayers = CreateConVar("sm_fia_waitingforplayers", "0", "Enable/Disable '1/0' Infinite Ammo during waiting for players phase");

	RegAdminCmd("sm_fia", Command_SetFia, ADMFLAG_SLAY, "Give Infinite Ammo to a target - Usage: sm_fia \"target\" \"1/0\"");
	RegAdminCmd("sm_fia2", Command_SetFiaTimed, ADMFLAG_SLAY, "Give Infinite Ammo to target(s) for a limited time - Usage: sm_fia2 \"target\" \"duration(in seconds)\"");
	RegAdminCmd("sm_full_infinite_ammo", Command_SetFia, ADMFLAG_SLAY, "Give Infinite Ammo to a target - Usage: sm_full_infinite_ammo \"target\" \"1/0\"");
	RegAdminCmd("sm_full_infinite_ammo_timed", Command_SetFiaTimed, ADMFLAG_SLAY, "Give Infinite Ammo to target(s) for a limited time - Usage: sm_full_infinite_ammo_timed \"target\" \"duration(in seconds)\"");

	HookConVarChange(hAll, FiaAllChange);
	HookConVarChange(hBatAmmo, ResetBalls);
	HookConVarChange(hAdminOnly, AdminOnlyChange);

	HookEvent("teamplay_round_start", RoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", RoundEnd, EventHookMode_Post);

	offset_ammo = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	offset_clip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
}

public OnClientPutInServer(client)
{
	if(GetConVarBool(hAll)) 
	{
		g_fiammo[client] = true;
	}
	else 
	{
		g_fiammo[client] = false;
	}
}
public OnClientDisconnect_Post(client)
{
	g_fiammo[client] = false;
}

public OnGameFrame()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if((IsClientInGame(i) && IsPlayerAlive(i)) && (g_fiammo[i] || g_roundwin))
		{
			if(GetConVarBool(hAdminOnly) && !CheckCommandAccess(i, "sm_fia_adminflag", ADMFLAG_GENERIC)) continue;		
			new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if(!IsValidEntity(weapon)) continue;
			new String:weaponclassname[32];
			GetEntityClassname(weapon, weaponclassname, sizeof(weaponclassname));
			new TFClassType:playerclass = TF2_GetPlayerClass(i);
			switch(playerclass)
			{
				case TFClass_Scout:
				{
					SetEntPropFloat(i, Prop_Send, "m_flHypeMeter", 100.0);					
					SetEntPropFloat(i, Prop_Send, "m_flEnergyDrinkMeter", 100.0);
					if(GetClientButtons(i) & IN_ATTACK2)
					{
						TF2_RemoveCondition(i, TFCond_Bonked); 
					}
				}
				case TFClass_Soldier:
				{
					if(!GetEntPropFloat(i, Prop_Send, "m_flRageMeter"))
					{

						SetEntPropFloat(i, Prop_Send, "m_flRageMeter", 100.0);
					}
				}
				case TFClass_DemoMan:
				{
					if(!TF2_IsPlayerInCondition(i, TFCond_Charging)) 
					{
						SetEntPropFloat(i, Prop_Send, "m_flChargeMeter", 100.0);
					}
					SetEntProp(i, Prop_Send, "m_iDecapitations", 99);
				}
				case TFClass_Engineer:
				{
					SetEntData(i, FindDataMapOffs(i, "m_iAmmo")+12, 200, 4);
					InfiniteSentryAmmo(i);
					
				}
				case TFClass_Medic:
				{
					if((StrEqual(weaponclassname, "tf_weapon_medigun", false)) && !GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel"))
					{
						SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 1.00);
					}
				}
				case TFClass_Sniper:
				{
					SetEntProp(i, Prop_Send, "m_iDecapitations", 99);
				}
				case TFClass_Spy:
				{
					SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 100.0);
					new knife = GetPlayerWeaponSlot(i, TFWeaponSlot_Melee);
					if(!IsValidEntity(knife)) continue;
					if(GetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex") == 649)
					{
						SetEntPropFloat(knife, Prop_Send, "m_flKnifeRegenerateDuration", 0.0);
					}
				}

			}
			if((StrEqual(weaponclassname, "tf_weapon_bat_wood", false))||(StrEqual(weaponclassname, "tf_weapon_bat_giftwrap", false)))
			{
				switch(GetConVarInt(hBatAmmo))
				{
					case 0:
					{
						continue;
					}
					case 2:
					{
						if(!CheckCommandAccess(i, "sm_fia_adminflag", ADMFLAG_GENERIC)) continue;
					}
				}	
			}
			new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(weaponindex)
			{
				case 441,442,588:
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", 100.0);
					continue;
				}
				case 141,525,595:
				{
					SetEntProp(i, Prop_Send, "m_iRevengeCrits", 10);
				}
				case 307:
				{
					SetEntProp(weapon, Prop_Send, "m_bBroken", 0);

					SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);					
				}
				case 527:
				{
					continue;
				}
				case 594:
				{
					if(!GetEntPropFloat(i, Prop_Send, "m_flRageMeter"))
					{

						SetEntPropFloat(i, Prop_Send, "m_flRageMeter", 100.0);
					}					
				}
				case 752:
				{
					if(GetEntPropFloat(i, Prop_Send, "m_flRageMeter") == 0.00)
					{

						SetEntPropFloat(i, Prop_Send, "m_flRageMeter", 100.0);
					}		
				}
			}
			new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType")*4;
			SetEntData(weapon, offset_clip, 99, 4, true);
			SetEntData(i, ammotype+offset_ammo, 99, 4, true);
		}
	}	
}

public InfiniteSentryAmmo(client)
{
	new sentrygun = -1; 
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(sentrygun))
		{
			if(GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)
			{
				if(GetEntProp(sentrygun, Prop_Send, "m_bMiniBuilding"))
				{
					SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 150); 
				}
				else
				{
					switch (GetEntProp(sentrygun, Prop_Send, "m_iUpgradeLevel"))
					{
						case 1:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 150);
						}
						case 2:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 200);
						}
						case 3:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 200);
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoRockets", 20);
						}
					}
				}
			}
		}
	}
}

public Action:Command_SetFia(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fia \"target\" \"1/0\"\n or sm_full_infinite_ammo \"target\" \"1/0\"");
		return Plugin_Handled;
	}
	new String:fiatarget[MAX_NAME_LENGTH], String:str_fiaswitch[2], String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, fiatarget, sizeof(fiatarget));
	GetCmdArg(2, str_fiaswitch, sizeof(str_fiaswitch));

	if((target_count = ProcessTargetString(
			fiatarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new fiaswitch = StringToInt(str_fiaswitch);
	for(new i=0;i<target_count;i++)
	{
		if(fiaswitch) 
		{
			g_fiammo[target_list[i]] = true;
		}
		else
		{
			g_fiammo[target_list[i]] = false;
			if(IsClientInGame(target_list[i]) && IsPlayerAlive(target_list[i]))
			{
				new health = GetClientHealth(target_list[i]);
				SetEntProp(target_list[i], Prop_Send, "m_iRevengeCrits", 0);
				TF2_RegeneratePlayer(target_list[i]);
				SetEntityHealth(target_list[i], health);
			}
		}
		if(GetConVarBool(hLog)) LogAction(client, target_list[i], "\"%L\" Set Infinite Ammo for  \"%L\" to (%i)", client, target_list[i], fiaswitch);
	}

	if(GetConVarBool(hChat))
	{
		if(fiaswitch) ShowActivity2(client, "[SM] ","Enabled Infinite Ammo for %s", target_name);
		else ShowActivity2(client, "[SM] ","Disabled Infinite Ammo for %s", target_name);
	}
	return Plugin_Handled;	
}


public Action:Command_SetFiaTimed(client, args)
{
	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fia2 \"target\" \"duration(in seconds)\"\n or sm_full_infinite_ammo_timed \"target\" \"duration(in seconds)\"");
		return Plugin_Handled;
	}
	new String:fiatarget[MAX_NAME_LENGTH], String:str_fiaduration[32], String:target_name[MAX_TARGET_LENGTH],target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, fiatarget, sizeof(fiatarget));
	GetCmdArg(2, str_fiaduration, sizeof(str_fiaduration));
	new Float:fiaduration = StringToFloat(str_fiaduration);

	if(fiaduration <= 0.0)
	{
		ReplyToCommand(client, "[SM] Duration must be greater than 0");
		return Plugin_Handled;
	}

	if((target_count = ProcessTargetString(
			fiatarget,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}


	for(new i=0;i<target_count;i++)
	{
		g_fiammo[target_list[i]] = true;
		CreateTimer(fiaduration, SetFiaTimed_Removal, target_list[i]);
		if(GetConVarBool(hLog)) LogAction(client, target_list[i], "\"%L\" Enabled Infinite Ammo for  \"%L\" for %f Seconds", client, target_list[i], fiaduration); 
	}

	if(GetConVarBool(hChat)) ShowActivity2(client, "[SM] ","Enabled Infinite Ammo for %s for %-.2f seconds", target_name, fiaduration);

	return Plugin_Handled;	
}

public Action:SetFiaTimed_Removal(Handle:timer, any:client)
{
	g_fiammo[client] = false;
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new health = GetClientHealth(client);
		SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
		TF2_RegeneratePlayer(client);
		SetEntityHealth(client, health);
	}
}

public FiaAllChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new oldint = StringToInt(oldValue);
	new newint = StringToInt(newValue);

	if (newint != 0 && oldint == 0)

	{
		for (new i=1;i<=MaxClients;i++)

		{
			g_fiammo[i] = true;
		}
		if(GetConVarBool(hChat)) 
		{
			if(GetConVarBool(hAdminOnly))
			{
				PrintToChatAll("[SM] Infinite Ammo for admins enabled");
			}
			else
			{
				PrintToChatAll("[SM] Infinite Ammo for everyone enabled");
			}
		}
		
	}
	if (newint == 0 && oldint != 0)

	{		
		for (new i=1;i<=MaxClients;i++)

		{
			g_fiammo[i] = false;
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				new health = GetClientHealth(i);
				SetEntProp(i, Prop_Send, "m_iRevengeCrits", 0);
				TF2_RegeneratePlayer(i);
				SetEntityHealth(i, health);
			}
		}
		if(GetConVarBool(hChat)) PrintToChatAll("[SM] Infinite Ammo for everyone disabled");
	}
}

public ResetBalls(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new oldint = StringToInt(oldValue);
	new newint = StringToInt(newValue);
	if ((newint == 0 && oldint != 0) || (newint == 2 && oldint == 1))

	{	
		for (new i=1;i<=MaxClients;i++)

		{
			if(g_fiammo[i])
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					new health = GetClientHealth(i);
					TF2_RegeneratePlayer(i);
					SetEntityHealth(i, health);
				}
			}
		}
	}
}

public AdminOnlyChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new oldint = StringToInt(oldValue);
	new newint = StringToInt(newValue);
	if ((newint == 1 && oldint != 1))

	{	
		for (new i=1;i<=MaxClients;i++)

		{
			if(g_fiammo[i])
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					new health = GetClientHealth(i);
					SetEntProp(i, Prop_Send, "m_iRevengeCrits", 0);
					TF2_RegeneratePlayer(i);
					SetEntityHealth(i, health);
				}
			}
		}
	}
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	g_roundwin = false;
	if (!GetConVarBool(hAll) && GetConVarBool(hRoundWin))

	{			
		PrintToChatAll("[SM] Round Start - Infinite Ammo Disabled");
	}
}

public RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(hAll) && GetConVarBool(hRoundWin))

	{
		g_roundwin = true;	
		PrintToChatAll("[SM] Round Win - Infinite Ammo Enabled");
	}
}

public TF2_OnWaitingForPlayersStart()
{
	if(GetConVarBool(hWaitingForPlayers))
	{
		g_roundwin = true;
		PrintToChatAll("[SM] Waiting For Players Started - Infinite Ammo Enabled");
	}	
}

public TF2_OnWaitingForPlayersEnd()
{
	if(GetConVarBool(hWaitingForPlayers))
	{
		g_roundwin = false;
		PrintToChatAll("[SM] Waiting For Players Ended - Infinite Ammo Disabled");
	}
}