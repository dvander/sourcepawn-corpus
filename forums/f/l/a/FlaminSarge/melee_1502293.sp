#include <sourcemod>
#include <adminmenu>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.3"

new bool:g_bEnabled;
new bool:g_bHealing;
new bool:g_bRandomRound;
new g_iMeleeMode;
new bool:g_bJumper;

new Handle:g_hMeleeMode;
new Handle:g_hHealing;
new Handle:g_hFlags;
new Handle:g_hFlagsVoting;
new Handle:g_hDisabled;
new Handle:g_hArena;
new Handle:g_hJumper;

new Handle:g_hWeaponSwitch;
new Handle:g_hWeaponReset;

new Handle:g_hTopMenu;

new g_iOffsetOwner;
new g_iOffsetDef;
new g_iOffsetState;

new bool:g_bVoting;
new g_iVoteResults[2];

new String:g_strOn[15];
new String:g_strOff[15];

new bool:g_bBotMelee;

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
		SetFailState("Could not locate offset for: %s!", "CBasePlayer::m_hActiveWeapon");
		return;
	}
	g_iOffsetDef = FindSendPropInfo("CBaseCombatWeapon", "m_iItemDefinitionIndex");
	if(g_iOffsetDef <= 0)
	{
		SetFailState("Could not locate offset for: %s!", "CBaseCombatWeapon::m_iItemDefinitionIndex");
		return;
	}
	g_iOffsetState = FindSendPropInfo("CTFMinigun", "m_iWeaponState");
	if(g_iOffsetState <= 0)
	{
		SetFailState("Could not locate offset for: %s!", "CTFMinigun::m_iWeaponState");
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
	g_hMeleeMode = CreateConVar("melee_mode", "0", "0 - Allow non-combat weapons | 1 - Only allow weapon in melee slot");
	g_hJumper = CreateConVar("melee_jumper", "0", "1 - Allow sticky/rocket jumper | 0 - Disallow these weapons");
	
	RegConsoleCmd("melee", Command_Melee);
	RegConsoleCmd("votemelee", Command_VoteMelee);
	
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("arena_win_panel", Event_ArenaRoundEnd);
	
	HookConVarChange(g_hHealing, ConVarChange_Healing);
	HookConVarChange(g_hMeleeMode, ConVarChange_Mode);
	HookConVarChange(g_hJumper, ConVarChange_Jumper);
	
	LoadTranslations("melee.phrases.txt");
	
	Format(g_strOn, sizeof(g_strOn), "%T", "On", LANG_SERVER);
	Format(g_strOff, sizeof(g_strOff), "%T", "Off", LANG_SERVER);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SetMeleeMode", Native_SetMeleeMode);
	CreateNative("GetMeleeMode", Native_GetMeleeMode);
	
	return APLRes_Success;
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
	g_bJumper = bool:GetConVarInt(g_hJumper);
	
	new Handle:hTopMenu;
	if(LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}
	g_bBotMelee = GetConVarBool(FindConVar("tf_bot_melee_only"));
}

public OnMapStart()
{
	SetMeleeMode(false, false);
	g_bRandomRound = false;
	g_bVoting = false;
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
		ReplyToCommand(client, "\x04 %T", "Melee_Disabled", LANG_SERVER);	
		return Plugin_Handled;
	}
	
	// A melee vote is currently taking place
	if(IsVoteInProgress() && g_bVoting)
	{
		CancelVote();
		PrintToChatAll("\x04 %T", "Vote_Canceled", LANG_SERVER);
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

public ConVarChange_Jumper(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bJumper = bool:StringToInt(newValue);
}

SetMeleeMode(bool:bEnabled, bool:bVerbose=true)
{
	if(GetConVarInt(g_hDisabled)) return;
	new Handle:cv_BotMelee = FindConVar("tf_bot_melee_only");
	if(bEnabled)
	{
		g_bEnabled = true;

		if (!GetConVarBool(cv_BotMelee))
			SetConVarBool(cv_BotMelee, true);

		for(new i=1; i<=MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				new iWeapon = GetActiveWeapon(i);
				new iSlot3 = GetPlayerWeaponSlot(i, 2);
				
				if(iWeapon && IsValidEntity(iWeapon) && iSlot3 && IsValidEntity(iSlot3) && iWeapon != iSlot3)
				{
					decl String:strClass[40];
					GetEdictClassname(iWeapon, strClass, sizeof(strClass));
					if(strcmp(strClass, "tf_weapon_minigun") == 0)
					{
						ResetMinigun(iWeapon, 0);
						TF2_RemoveCondition(i, TFCond_Slowed);
					}
					
					ResetWeapon(iWeapon);
				}
			}
		}
		
		SetSentryDisable(true);
	}else{
		g_bEnabled = false;
		SetSentryDisable(false);
		if (GetConVarBool(cv_BotMelee) && !g_bBotMelee)
			SetConVarBool(cv_BotMelee, g_bBotMelee);
	}
	
	if(bVerbose)
		PrintToChatAll("\x04 %T", "Melee_Action", LANG_SERVER, 0x01, g_bEnabled ? g_strOn : g_strOff);
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
					if(g_iMeleeMode) // Strict melee mode
					{
						SetActiveWeapon(i, iWeapon);
					}else{
						if(!CanUseWeapon(GetItemDefinition(iActive)))
						{
							SetActiveWeapon(i, iWeapon);
						}
					}
				}
			}
		}
	}
}

bool:CanUseWeapon(iItemDef)
{
	switch(iItemDef)
	{
		case 25,26,140: return true; // Build / Destroy PDAs / Wrangler
		case 58: return true; // Jarate
		case 42,159,311: return true; // Sandvich / Chocolate Bar / Buffalo Steak
		case 46,163,222: return true; // Bonk / Crit-a-Cola / Mad Milk
		case 27,28: return true; // Spy PDA
		case 129,226,354: return true; // The Buff Banner / The Battalion's Backup / The Concheror
		case 29,35,411: return g_bHealing; // Medigun / Kritzcrieg / The Quick-Fix
		case 237,265: return g_bJumper; // Rocket/Sticky Jumper
	}
	
	return false;
}

GetItemDefinition(weapon)
{
	return GetEntData(weapon, g_iOffsetDef);
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

ResetMinigun(weapon, iState)
{
	// 0 - idle | 1 - lowering | 2 - shooting | 3 - reving | 4 - click click
	SetEntData(weapon, g_iOffsetState, iState);
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
	
	new TopMenuObject:TopMenuVoting = FindTopMenuCategory(g_hTopMenu, ADMINMENU_VOTINGCOMMANDS);
	if(TopMenuVoting != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(g_hTopMenu, "votemelee", TopMenuObject_Item, AdminMenu_VoteMelee, TopMenuVoting, "votemelee", iFlags);
	}
}

public AdminMenu_Melee(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
    if(action == TopMenuAction_DisplayOption)
    {
        Format(buffer, maxlength, "Toggle melee: %s", g_bEnabled ? g_strOff : g_strOn);
    }else if(action == TopMenuAction_SelectOption)
    {
		Command_Melee(param, 0);
		DisplayTopMenu(g_hTopMenu, param, TopMenuPosition_LastCategory);
    }
}

public AdminMenu_VoteMelee(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption && !IsVoteInProgress())
	{
		Format(buffer, maxlength, "Melee vote: %s", g_bEnabled ? g_strOff : g_strOn);
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
	
	if(GetConVarInt(g_hDisabled))
	{
		ReplyToCommand(client, "\x04 %T", "Melee_Disabled", LANG_SERVER);
		return Plugin_Handled;
	}
	
	if(IsVoteInProgress())
	{
		ReplyToCommand(client, "\x01[SM] Vote is already in progress.");
		return Plugin_Handled;
	}
	
	g_bVoting = true;
	g_iVoteResults[0] = 0;
	g_iVoteResults[1] = 0;
	ShowActivity(client, "Started vote for melee only.");
	
	new Handle:hMenu = CreateMenu(MenuHandler_VoteMelee);
	
	SetMenuTitle(hMenu, "%T", "Vote_Title", LANG_SERVER, g_bEnabled ? g_strOff : g_strOn);
	
	decl String:strTemp[25];
	Format(strTemp, sizeof(strTemp), "%T", "Yes", LANG_SERVER);
	AddMenuItem(hMenu, "", strTemp);
	Format(strTemp, sizeof(strTemp), "%T", "No", LANG_SERVER);
	AddMenuItem(hMenu, "", strTemp);
	
	SetMenuExitButton(hMenu, false);
	VoteMenuToAll(hMenu, 20);	
	
	return Plugin_Handled;
}

public MenuHandler_VoteMelee(Handle:menu, MenuAction:action, client, menu_item)
{
	if(action == MenuAction_Select)
	{
		g_iVoteResults[menu_item]++;
		PrintHintTextToAll("%T", "Vote_Results", LANG_SERVER, g_iVoteResults[0], g_iVoteResults[1]);
	}else if(action == MenuAction_VoteEnd)
	{
		g_bVoting = false;
		if(client == 0)
		{
			PrintToChatAll("\x04 %T", "Vote_Success", LANG_SERVER);
			Command_Melee(0, 0);
		}else{
			PrintToChatAll("\x04 %T", "Vote_Failed", LANG_SERVER);
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
		
		PrintToChatAll("\x04 %T", "Arena_Melee", LANG_SERVER, 0x01, 0x04);
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

public Native_SetMeleeMode(Handle:plugin, numParams)
{
	new bool:bEnabled = bool:GetNativeCell(1);
	new bool:bVerbose = bool:GetNativeCell(2);
	
	SetMeleeMode(bEnabled, bVerbose);
}

public Native_GetMeleeMode(Handle:plugin, numParams)
{
	return _:g_bEnabled;
}
