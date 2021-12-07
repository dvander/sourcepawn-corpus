#include <sourcemod>
#include <adminmenu>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.2.51"

new bool:g_bEnabled;
new bool:g_bHealing;
new bool:g_bRandomRound;
new bool:g_bSuddenDeath;
new g_iMeleeMode;
new String:g_szMeleeClass[32];

new Handle:g_hMeleeMode;
new Handle:g_hHealing;
new Handle:g_hFlags;
new Handle:g_hFlagsVoting;
new Handle:g_hDisabled;
new Handle:g_hArena;
new Handle:g_hSuddendeath;
new Handle:g_hClassForce;
new Handle:g_hClassForceMode;

new Handle:g_hWeaponSwitch;
new Handle:g_hWeaponReset;
new Handle:g_hTopMenu;

new g_iOffsetOwner;
new g_iVoteResults[2];

public Plugin:myinfo = 
{
	name = "Melee",
	author = "linux_lover",
	description = "Toggles melee only mode",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
}

public OnPluginStart()
{
	g_iOffsetOwner = FindSendPropOffs("CBasePlayer", "m_hActiveWeapon");
	if(g_iOffsetOwner <= 0)
	{
		SetFailState("Could not locate offsets for: %s!", "CBasePlayer::m_hActiveWeapon");
		return;
	}
	
	new Handle:hConf = LoadGameConfigFile("melee");
	if(hConf == INVALID_HANDLE)
	{
		SetFailState("Could not locate melee.txt in sourcemod/gamedata");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "Weapon_Switch");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_hWeaponSwitch = EndPrepSDKCall();
	if(g_hWeaponSwitch == INVALID_HANDLE)
	{
		SetFailState("Could not initialize call for CTFPlayer::Weapon_Switch");
		CloseHandle(hConf);
		return;
	}
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "WeaponReset");
	g_hWeaponReset = EndPrepSDKCall();
	if(g_hWeaponReset == INVALID_HANDLE)
	{
		SetFailState("Could not initialize call for CTFWeaponBase::WeaponReset");
		CloseHandle(hConf);
		return;
	}
	CloseHandle(hConf);
	
	CreateConVar("melee_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hHealing = CreateConVar("melee_healing", "0", "1 - Allow healing | 0 - Disallow healing");
	g_hFlags = CreateConVar("melee_flag", "z", "Admin flag for melee only");
	g_hFlagsVoting = CreateConVar("melee_voteflag", "z", "Admin flag fo melee votes");
	g_hDisabled = CreateConVar("melee_disabled", "0", "0 - No effect | 1 - Disable melee from being turned on");
	g_hArena = CreateConVar("melee_arena", "0.0", "Random chance for an arena melee round. Set between 0 and 1. Ex. 0 - Off, 0.25 - 25%", 0, true, 0.0, true, 1.0);
	g_hSuddendeath = CreateConVar("melee_suddendeath", "0", "0/1 - Enable melee in sudden death");
	g_hMeleeMode = CreateConVar("melee_mode", "0", "0 - Allow non-combat weapons | 1 - Only allow weapon in melee slot");
	g_hClassForce = CreateConVar("melee_class", "", "If not empty, set all players to this class depending on melee_classmode setting");
	g_hClassForceMode = CreateConVar("melee_classmode", "0", "0 - Don't force class | 1 - Force melee class on sudden death | 2 - Force melee class whenever melee mode is on");
	
	RegConsoleCmd("melee", Command_Melee);
	RegConsoleCmd("votemelee", Command_VoteMelee);
	GetConVarString(g_hClassForce, g_szMeleeClass, sizeof(g_szMeleeClass));
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("arena_win_panel", Event_ArenaRoundEnd);
	HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
	HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
	HookEvent("teamplay_round_win", Event_SuddenDeathEnd);
	HookEvent("player_spawn", player_spawn);
	
	HookConVarChange(g_hHealing, ConVarChange_Healing);
	HookConVarChange(g_hMeleeMode, ConVarChange_Mode);
}
public player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Error-checking
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	if (!IsPlayerAlive(client)) return;
	if (g_bEnabled)
	{
		if (GetConVarInt(g_hClassForceMode) == 2 || (GetConVarInt(g_hClassForceMode) == 1 && g_bSuddenDeath))
		{
			GetConVarString(g_hClassForce, g_szMeleeClass, sizeof(g_szMeleeClass));
			new TFClassType:class;
			if ((StrEqual(g_szMeleeClass, "scout", false)
				|| StrEqual(g_szMeleeClass, "soldier", false)
				|| StrEqual(g_szMeleeClass, "sniper", false)
				|| StrEqual(g_szMeleeClass, "demoman", false)
				|| StrEqual(g_szMeleeClass, "demo", false)
				|| StrEqual(g_szMeleeClass, "medic", false)
				|| StrEqual(g_szMeleeClass, "heavy", false)
				|| StrEqual(g_szMeleeClass, "hwg", false)
				|| StrEqual(g_szMeleeClass, "pyro", false)
				|| StrEqual(g_szMeleeClass, "spy", false)
				|| StrEqual(g_szMeleeClass, "engy", false)
				|| StrEqual(g_szMeleeClass, "engineer", false)) && TF2_GetPlayerClass(client) != (class = TF2_GetClass(g_szMeleeClass)))
			{
				TF2_SetPlayerClass(client, class, false, true);
				TF2_RespawnPlayer(client);
			}
		}
	}
}	
public OnPluginEnd()
{
	SetMeleeMode(false, false);
}

public OnLibraryRemoved(const String:name[])
{
	if(strcmp(name, "adminmenu") == 0)
	{
		g_hTopMenu = INVALID_HANDLE;
	}
}

public OnConfigsExecuted()
{
	g_bHealing = bool:GetConVarInt(g_hHealing);
	g_iMeleeMode = GetConVarInt(g_hMeleeMode);
	
	new Handle:hTopMenu;
	if(LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}
}

public OnMapStart()
{
	SetMeleeMode(false, false);
	g_bRandomRound = false;
	g_bSuddenDeath = false;
}

public Action:Command_Melee(client, args)
{
	if(client > 0)
	{
		decl String:strFlags[5];
		GetConVarString(g_hFlags, strFlags, sizeof(strFlags));
		if(!CheckAdminFlagsByString(client, strFlags)) return Plugin_Handled;
	}
	
	if(GetConVarInt(g_hDisabled))
	{
		if(client > 0)
			PrintToChat(client, "\x04 Melee mode is disabled on this map");

		return Plugin_Handled;
	}
	
	// Toggle
	if(args == 0)
	{
		if(g_bEnabled == true)
		{
			SetMeleeMode(false);
		}else{
			SetMeleeMode(true);
		}
	}else{
		new String:strArg1[5];
		GetCmdArg(1, strArg1, sizeof(strArg1));
		
		if(StringToInt(strArg1) >= 1)
		{
			SetMeleeMode(true);
		}else{
			SetMeleeMode(false);
		}
	}
	
	return Plugin_Handled;
}

public ConVarChange_Healing(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bHealing = bool:StringToInt(newValue);
}

public ConVarChange_Mode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iMeleeMode = StringToInt(newValue);
}

SetMeleeMode(bool:bEnabled, bool:bVerbose=true)
{
	if(GetConVarInt(g_hDisabled)) return;
	
	if(bEnabled)
	{
		g_bEnabled = true;
		
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				new iWeapon = GetActiveWeapon(i);
				new iSlot3 = GetPlayerWeaponSlot(i, 2);
				
				if(iWeapon && IsValidEntity(iWeapon) && iSlot3 && IsValidEntity(iSlot3) && iWeapon != iSlot3)
				{		
					ResetWeapon(iWeapon);
				}
				if (GetConVarInt(g_hClassForceMode) == 2 || (GetConVarInt(g_hClassForceMode) == 1 && g_bSuddenDeath))
				{
					GetConVarString(g_hClassForce, g_szMeleeClass, sizeof(g_szMeleeClass));
					new TFClassType:class;
					if ((StrEqual(g_szMeleeClass, "scout", false)
						|| StrEqual(g_szMeleeClass, "soldier", false)
						|| StrEqual(g_szMeleeClass, "sniper", false)
						|| StrEqual(g_szMeleeClass, "demoman", false)
						|| StrEqual(g_szMeleeClass, "demo", false)
						|| StrEqual(g_szMeleeClass, "medic", false)
						|| StrEqual(g_szMeleeClass, "heavy", false)
						|| StrEqual(g_szMeleeClass, "hwg", false)
						|| StrEqual(g_szMeleeClass, "pyro", false)
						|| StrEqual(g_szMeleeClass, "spy", false)
						|| StrEqual(g_szMeleeClass, "engy", false)
						|| StrEqual(g_szMeleeClass, "engineer", false)) && TF2_GetPlayerClass(i) != (class = TF2_GetClass(g_szMeleeClass)))
					{
						TF2_SetPlayerClass(i, class, false, true);
						TF2_RespawnPlayer(i);
					}
				}
			}
		}
		
		SetSentryDisable(true);
	}else{
		g_bEnabled = false;
		SetSentryDisable(false);
	}
	
	if(bVerbose)
		PrintToChatAll("\x04 Melee only is: \x01%s", g_bEnabled ? "On" : "Off");
}

public OnGameFrame()
{
	if(g_bEnabled)
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				new iWeapon = GetPlayerWeaponSlot(i, 2);
				new iActive = GetActiveWeapon(i);
				
				if(iWeapon && IsValidEntity(iWeapon) && iActive && IsValidEntity(iActive) && iWeapon != iActive)
				{
					if(g_iMeleeMode > 0) // Strict melee mode
					{
						SetActiveWeapon(i, iWeapon);
					}else{
						new TFClassType:class = TF2_GetPlayerClass(i);
						if(class == TFClass_Engineer)
						{
							new bool:bAllow = true;
							new iSlot1 = GetPlayerWeaponSlot(i, 0);
							new iSlot2 = GetPlayerWeaponSlot(i, 1);
							
							if((iSlot1 && IsValidEntity(iSlot1) && iActive == iSlot1) || (iSlot2 && IsValidEntity(iSlot2) && iActive == iSlot2 && GetItemDefinition(iSlot2) != 140)) // The Wrangler
							{
								bAllow = false;
							}

							if(!bAllow)
							{
								SetActiveWeapon(i, iWeapon);
							}
						}else if(class == TFClass_Sniper)
						{
							new bool:bAllow;
							new iSlot2 = GetPlayerWeaponSlot(i, 1);
							
							if(iSlot2 && IsValidEntity(iSlot2) && iActive == iSlot2 && GetItemDefinition(iSlot2) == 58) // Jarate
							{
								bAllow = true;
							}
							
							if(!bAllow)
							{
								SetActiveWeapon(i, iWeapon);
							}
						}else if(class == TFClass_Heavy)
						{
							new bool:bAllow;
							new iSlot2 = GetPlayerWeaponSlot(i, 1);
							
							if(iSlot2 && IsValidEntity(iSlot2) && iActive == iSlot2)
							{
								new iItemDef = GetItemDefinition(iSlot2);
								if(iItemDef == 42 || iItemDef == 159) // Sandwich / Chocolate Bar
								{
									bAllow = true;
								}
							}
							
							if(!bAllow)
							{
								SetActiveWeapon(i, iWeapon);
							}
						}else if(class == TFClass_Scout)
						{
							new bool:bAllow;
							new iSlot2 = GetPlayerWeaponSlot(i, 1);
							
							if(iSlot2 && IsValidEntity(iSlot2) && iActive == iSlot2)
							{
								new iItemDef = GetItemDefinition(iSlot2);
								if(iItemDef == 46 || iItemDef == 163 || iItemDef == 222) // Bonk / Crit-a-cola / Mad Milk
								{
									bAllow = true;
								}
							}
							
							if(!bAllow)
							{
								SetActiveWeapon(i, iWeapon);
							}
						}else if(class == TFClass_Spy)
						{
							new bool:bAllow;
							new iSlot2 = GetPlayerWeaponSlot(i, 1);
							new iSlot4 = GetPlayerWeaponSlot(i, 3);
							
							if(iSlot4 && IsValidEntity(iSlot4) && iActive == iSlot4)
							{
								bAllow = true;
							}else if(iSlot2 && IsValidEntity(iSlot2) && iActive == iSlot2) // Sapper
							{
								bAllow = true;
							}
							
							if(!bAllow)
							{
								SetActiveWeapon(i, iWeapon);
							}
						}else if(class == TFClass_Soldier)
						{
							new bool:bAllow;
							new iSlot2 = GetPlayerWeaponSlot(i, 1);
							
							if(iSlot2 && IsValidEntity(iSlot2) && iActive == iSlot2)
							{
								new iItemDef = GetItemDefinition(iSlot2);
								if(iItemDef == 129 || iItemDef == 226) // The Buff Banner / The Battalion's Backup
								{
									bAllow = true;
								}
							}
							
							if(!bAllow)
							{
								SetActiveWeapon(i, iWeapon);
							}
						}else if(class == TFClass_Medic && g_bHealing)
						{
							new bool:bAllow;
							new iSlot2 = GetPlayerWeaponSlot(i, 1);
							
							if(iSlot2 && IsValidEntity(iSlot2) && iActive == iSlot2)
							{
								bAllow = true;
							}
							
							if(!bAllow)
							{
								SetActiveWeapon(i, iWeapon);
							}
						}else{
							SetActiveWeapon(i, iWeapon);
						}
					}
				}
			}
		}
	}
}

GetItemDefinition(weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

GetActiveWeapon(client)
{
	return GetEntDataEnt2(client, g_iOffsetOwner);
}

SetActiveWeapon(client, weapon)
{
	SDKCall(g_hWeaponSwitch, client, weapon, 0);
}

ResetWeapon(weapon)
{
	SDKCall(g_hWeaponReset, weapon);
}

SetSentryDisable(bool:bEnabled)
{
	new Handle:hTarget = FindConVar("tf_sentrygun_notarget");
	SetConVarBool(hTarget, bEnabled);
	CloseHandle(hTarget);
}

stock bool:CheckAdminFlagsByString(client, const String:flagString[])
{
	if(!StrEqual(flagString, ""))
	{
		new iFlags = ReadFlagString(flagString);
		return bool:(GetUserFlagBits(client) & iFlags);
	}
	
	return bool:(GetUserFlagBits(client) & ADMFLAG_ROOT);
}

public OnAdminMenuReady(Handle:hTopMenu)
{	
	if(hTopMenu == g_hTopMenu)
	{
		return;
	}
	
	new String:strFlags[5];
	GetConVarString(g_hFlags, strFlags, sizeof(strFlags));
	new iFlags = ADMFLAG_ROOT;
	if(!StrEqual(strFlags, ""))
	{
		iFlags = ReadFlagString(strFlags);
	}
	
	g_hTopMenu = hTopMenu;
	
	new TopMenuObject:TopMenuServerCommands = FindTopMenuCategory(g_hTopMenu, ADMINMENU_SERVERCOMMANDS);
	if(TopMenuServerCommands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hTopMenu, "melee", TopMenuObject_Item, AdminMenu_Melee, TopMenuServerCommands, "melee", iFlags);
	}
	
	GetConVarString(g_hFlagsVoting, strFlags, sizeof(strFlags));
	iFlags = ADMFLAG_ROOT;
	if(!StrEqual(strFlags, ""))
	{
		iFlags = ReadFlagString(strFlags);
	}
	
	new TopMenuObject:TopMenuServerVoting = FindTopMenuCategory(g_hTopMenu, ADMINMENU_VOTINGCOMMANDS);
	if(TopMenuServerVoting != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hTopMenu, "votemelee", TopMenuObject_Item, AdminMenu_VoteMelee, TopMenuServerVoting, "votemelee", iFlags);
	}
}

public AdminMenu_Melee(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    if(action == TopMenuAction_DisplayOption && !IsVoteInProgress())
    {
        Format(buffer, maxlength, "Toggle melee: %s", g_bEnabled ? "Off" : "On");
    }else if(action == TopMenuAction_SelectOption)
    {
		Command_Melee(param, 0);
		DisplayTopMenu(g_hTopMenu, param, TopMenuPosition_LastCategory);
    }
}

public AdminMenu_VoteMelee(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Melee vote");
	}else if(action == TopMenuAction_SelectOption)
	{
		Command_VoteMelee(param, 0);
	}
}

public Action:Command_VoteMelee(client, args)
{
	if(client > 0)
	{
		decl String:strFlags[5];
		GetConVarString(g_hFlagsVoting, strFlags, sizeof(strFlags));
		if(!CheckAdminFlagsByString(client, strFlags)) return Plugin_Handled;
	}
	
	if(!g_bEnabled)
	{
		if(GetConVarInt(g_hDisabled))
		{
			if(client > 0)
				PrintToChat(client, "\x04 Melee only is disabled on this map.");
			
			return Plugin_Handled;
		}
		if(IsVoteInProgress())
		{
			if(client > 0)
				PrintToChat(client, "\x01[SM] Vote is already in progress.");
			
			return Plugin_Handled;
		}
		g_iVoteResults[0] = 0;
		g_iVoteResults[1] = 0;
		ShowActivity(client, "Started vote to enable melee only.");

		new Handle:hMenu = CreateMenu(MenuHandler_VoteMelee);

		SetMenuTitle(hMenu, "Enable melee only mode?");
		AddMenuItem(hMenu, "", "Let's do it!");
		AddMenuItem(hMenu, "", "No way!");

		SetMenuExitButton(hMenu, false);
		VoteMenuToAll(hMenu, 20);	

		return Plugin_Handled;
	}
	if(g_bEnabled)
	{
		if(IsVoteInProgress())
		{
			if(client > 0)
				PrintToChat(client, "\x01[SM] Vote is already in progress.");
			
			return Plugin_Handled;
		}
		g_iVoteResults[0] = 0;
		g_iVoteResults[1] = 0;
		ShowActivity(client, "Started vote to disable melee only.");

		new Handle:hMenu = CreateMenu(MenuHandler_VoteMelee);

		SetMenuTitle(hMenu, "Disable melee only mode?");
		AddMenuItem(hMenu, "", "Fine.");
		AddMenuItem(hMenu, "", "Nuh-uh!");

		SetMenuExitButton(hMenu, false);
		VoteMenuToAll(hMenu, 20);	

		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public MenuHandler_VoteMelee(Handle:menu, MenuAction:action, client, menu_item)
{
	if(action == MenuAction_Select)
	{
		g_iVoteResults[menu_item]++;
		PrintHintTextToAll("Vote results: Yes: %d No: %d", g_iVoteResults[0], g_iVoteResults[1]);
	}else if(action == MenuAction_VoteEnd)
	{
		if(client == 0)
		{
			PrintToChatAll("\x01[SM] Melee toggle vote successful!");
			SetMeleeMode(!g_bEnabled);
		}else{
			PrintToChatAll("\x01[SM] Failed to get enough votes to toggle melee only.");
		}
	}else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Event_ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnabled && !GetConVarInt(g_hDisabled) && GetConVarFloat(g_hArena) > GetRandomFloat())
	{
		g_bRandomRound = true;
		SetMeleeMode(true, false);
		
		PrintToChatAll("\x04 Randomly chose melee for this round!")
	}
	
	return Plugin_Continue;
}

public Action:Event_ArenaRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled && g_bRandomRound)
	{
		g_bRandomRound = false;
		SetMeleeMode(false);
	}
	
	return Plugin_Continue;
}

public Action:Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:hHandle = FindConVar("mp_stalemate_enable");
	new bool:bStalemate = GetConVarBool(hHandle);
	CloseHandle(hHandle);
	
	if(!g_bEnabled && bStalemate && GetConVarInt(g_hSuddendeath) && !GetConVarInt(g_hDisabled))
	{
		g_bSuddenDeath = true;
		SetMeleeMode(true);
	}

	return Plugin_Continue;
}

public Action:Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled && g_bSuddenDeath)
	{
		g_bSuddenDeath = false;
		SetMeleeMode(false);
	}
	
	return Plugin_Continue;
}