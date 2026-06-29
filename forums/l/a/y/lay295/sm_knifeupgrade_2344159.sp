#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <csgocolors>
#include <weapons>
#include <cstrike>
#undef REQUIRE_PLUGIN
#pragma semicolon 1

#define PLUGIN_VERSION "2.5.8"
#define PLUGIN_NAME "Knife Upgrade Edited By Derp"

#define MAX_KNIVES 11
#define GOLDEN_KNIFE 10

new Handle:g_cookieKnife;

new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled = true;

new Handle:g_hSpawnMessage = INVALID_HANDLE;
new bool:g_bSpawnMessage = false;

new Handle:g_hSpawnMenu = INVALID_HANDLE;
new bool:g_bSpawnMenu = false;

new Handle:g_hWelcomeMessage = INVALID_HANDLE;
new bool:g_bWelcomeMessage = true;

new Handle:g_hWelcomeMenu = INVALID_HANDLE;
new bool:g_bWelcomeMenu = false;

new Handle:g_hWelcomeMenuOnlyNoKnife = INVALID_HANDLE;
new bool:g_bWelcomeMenuOnlyNoKnife = true;

new Handle:g_hWelcomeMessageTimer = INVALID_HANDLE;
new Float:g_fWelcomeMessageTimer;

new Handle:g_hWelcomeMenuTimer = INVALID_HANDLE;
new Float:g_fWelcomeMenuTimer;

new Handle:g_hDelayedEquipTimer = INVALID_HANDLE;
new Float:g_fDelayedEquipTimer;

new Handle:g_hKnifeChosenMessage = INVALID_HANDLE;
new bool:g_bKnifeChosenMessage = true;

new Handle:g_hNoKnifeMapDisable = INVALID_HANDLE;
new bool:g_bNoKnifeMapDisable = false;

new Handle:g_hNoKnifeMenu = INVALID_HANDLE;
new bool:g_bNoKnifeMenu = false;

new Handle:g_hHideRestricted = INVALID_HANDLE;
new bool:g_bHideRestricted = false;

new Handle:g_hEndRoundCrash = INVALID_HANDLE;
new bool:g_bEndRoundCrash = false;

new Handle:g_hEnableGoldenKnife = INVALID_HANDLE;
new bool:g_bEnableGoldenKnife = true;

new knife_choice[MAXPLAYERS+1];
new knife_welcome_spawn_menu[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Klexen",
	description = "Choose and a save custom knife skin for this server.",
	version = PLUGIN_VERSION
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late){
		for (new i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				SDKHook(i, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
			}
		}
	}

	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("knifeupgrade.phrases");
	LoadTranslations("common.phrases");
	
	Create_Convars();
	Hook_Convars();
	
	AutoExecConfig(true, "sm_knifeupgrade");

	//Reg Knife Command from translation file
	decl String:knife[32];
	Format(knife, sizeof(knife), "%t", "Knife Menu Command");
	RegConsoleCmd(knife, CreateKnifeMenuTimer);
	
	AddCommandListener(Event_Say, "say");
	AddCommandListener(Event_Say, "say_team");
	
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_team",OnChangeTeam, EventHookMode_Pre);
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
}

public OnConfigsExecuted()
{
	Load_Convars();
}

stock Create_Convars()
{
	CreateConVar("sm_knifeupgrade_version", PLUGIN_VERSION, "Knife Upgrade Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cookieKnife = RegClientCookie("knife_choice", "", CookieAccess_Private);
	g_hEnabled = CreateConVar("sm_knifeupgrade_on", "1", "Enable / Disable Plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnMessage = CreateConVar("sm_knifeupgrade_spawn_message", "0", "Show Plugin Message on Spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnMenu = CreateConVar("sm_knifeupgrade_spawn_menu", "0", "Show Knife Menu on Spawn", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMessage = CreateConVar("sm_knifeupgrade_welcome_message", "1", "Show Plugin Message on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMenu = CreateConVar("sm_knifeupgrade_welcome_menu", "0", "Show Knife Menu on player connect.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMenuOnlyNoKnife = CreateConVar("sm_knifeupgrade_welcome_menu_only_no_knife", "1", "Show Knife Menu on player Spawn ONCE and only if they haven't already chosen a knife before.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hWelcomeMessageTimer = CreateConVar("sm_knifeupgrade_welcome_message_timer", "25.0", "When (in seconds) the message should be displayed after the player joins the server.", FCVAR_NONE, true, 25.0, true, 90.0);
	g_hWelcomeMenuTimer = CreateConVar("sm_knifeupgrade_welcome_menu_timer", "8.5", "When (in seconds) AFTER SPAWNING THE FIRST TIME the knife menu should be displayed.", FCVAR_NONE, true, 1.0, true, 90.0);
	g_hDelayedEquipTimer = CreateConVar("sm_knifeupgrade_equip_delay", "0.1", "How long (in seconds with MAX of 3.0 seconds) to delay knife equip. *Increase small amounts if you experience crashes on round end / start.*", FCVAR_NONE, true, 0.1, true, 3.0);
	g_hKnifeChosenMessage = CreateConVar("sm_knifeupgrade_chosen_message", "1", "Show message to player when player chooses a knife.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hNoKnifeMapDisable = CreateConVar("sm_knifeupgrade_map_disable", "0", "Set to 1 to disable knife on maps not meant to have knives", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hNoKnifeMenu = CreateConVar("sm_knifeupgrade_no_menu", "0", "Set to 1 to disable the knife menu.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hHideRestricted = CreateConVar("sm_knifeupgrade_hide_restricted", "0", "Set to 1 to hide restricted knives from the menu. 0 Shows the knives as disabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hEndRoundCrash = CreateConVar("sm_knifeupgrade_round_crash", "0", "Set to 1 to fix crash crashes with end of round **if you have them**.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hEnableGoldenKnife = CreateConVar("sm_knifeupgrade_enable_golden_knife", "0", "Set to 1 to enable the golden knife.", FCVAR_NONE, true, 0.0, true, 1.0);
}

stock Load_Convars()
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_bSpawnMessage = GetConVarBool(g_hSpawnMessage);
	g_bSpawnMenu = GetConVarBool(g_hSpawnMenu);
	g_bWelcomeMessage = GetConVarBool(g_hWelcomeMessage);
	g_bWelcomeMenu = GetConVarBool(g_hWelcomeMenu);
	g_bWelcomeMenuOnlyNoKnife = GetConVarBool(g_hWelcomeMenuOnlyNoKnife);
	g_fWelcomeMessageTimer = GetConVarFloat(g_hWelcomeMessageTimer);
	g_fWelcomeMenuTimer = GetConVarFloat(g_hWelcomeMenuTimer);
	g_fDelayedEquipTimer = GetConVarFloat(g_hDelayedEquipTimer);
	g_bKnifeChosenMessage = GetConVarBool(g_hKnifeChosenMessage);
	g_bNoKnifeMapDisable = GetConVarBool(g_hNoKnifeMapDisable);
	g_bNoKnifeMenu = GetConVarBool(g_hNoKnifeMenu);
	g_bHideRestricted = GetConVarBool(g_hHideRestricted);
	g_bEndRoundCrash = GetConVarBool(g_hEndRoundCrash);
	g_bEnableGoldenKnife = GetConVarBool(g_hEnableGoldenKnife);
}

stock Hook_Convars()
{
	HookConVarChange(g_hEnabled, OnConVarChanged);
	HookConVarChange(g_hSpawnMessage, OnConVarChanged);
	HookConVarChange(g_hSpawnMenu, OnConVarChanged);
	HookConVarChange(g_hWelcomeMessage, OnConVarChanged);
	HookConVarChange(g_hWelcomeMenu, OnConVarChanged);
	HookConVarChange(g_hWelcomeMenuOnlyNoKnife, OnConVarChanged);
	HookConVarChange(g_hWelcomeMessageTimer, OnConVarChanged);
	HookConVarChange(g_hWelcomeMenuTimer, OnConVarChanged);
	HookConVarChange(g_hDelayedEquipTimer, OnConVarChanged);
	HookConVarChange(g_hKnifeChosenMessage, OnConVarChanged);
	HookConVarChange(g_hNoKnifeMapDisable, OnConVarChanged);
	HookConVarChange(g_hNoKnifeMenu, OnConVarChanged);
	HookConVarChange(g_hEndRoundCrash, OnConVarChanged);
	HookConVarChange(g_hEnableGoldenKnife, OnConVarChanged);
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hEnabled)
		g_bEnabled = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hSpawnMessage)
		g_bSpawnMessage = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hSpawnMenu)
		g_bSpawnMenu = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hWelcomeMessage)
		g_bWelcomeMessage = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hWelcomeMenuOnlyNoKnife)
		g_bWelcomeMenuOnlyNoKnife = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hWelcomeMessageTimer)
		g_fWelcomeMessageTimer = StringToFloat(newValue);
	else if (convar == g_hWelcomeMenuTimer)
		g_fWelcomeMenuTimer = StringToFloat(newValue);
	else if (convar == g_hDelayedEquipTimer)
		g_fDelayedEquipTimer = StringToFloat(newValue);
	else if (convar == g_hKnifeChosenMessage)
		g_bKnifeChosenMessage = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hNoKnifeMapDisable)
		g_bNoKnifeMapDisable = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hNoKnifeMenu)
		g_bNoKnifeMenu = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hHideRestricted)
		g_bHideRestricted = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hEndRoundCrash)
		g_bEndRoundCrash = StringToInt(newValue) == 1 ? true : false;
	else if (convar == g_hEnableGoldenKnife)
		g_bEnableGoldenKnife = StringToInt(newValue) == 1 ? true : false;
}

public OnClientCookiesCached(client)
{
	new String:value[16];
	GetClientCookie(client, g_cookieKnife, value, sizeof(value));
	if(strlen(value) > 0) {
		knife_choice[client] = StringToInt(value);
	}
	if (knife_choice[client] < 0 || knife_choice[client] > MAX_KNIVES) {
		knife_choice[client] = 0;
	}
}

public OnClientAuthorized(client)
{
	knife_welcome_spawn_menu[client] = 0;
}

public Action:OnChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEndRoundCrash || g_bEnableGoldenKnife)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if (!IsValidClient(client)) return Plugin_Continue;
		if (knife_choice[client] < 1) return Plugin_Continue;
		
		new team = GetEventInt(event, "team");
		new oldteam = GetClientTeam(client);

		if (team == oldteam && team > CS_TEAM_SPECTATOR) return Plugin_Continue;
		
		if (IsPlayerAlive(client)){
			CreateTimer(1.5, TeamSwapKnifeCheck, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
			Client_RemoveWeaponKnife(client, "weapon_knife", true);
		}
		if (IsClientInGame(client)){
			CS_SwitchTeam(client, CS_TEAM_NONE);
		}
	}
	return Plugin_Continue;
}

public Action:TeamSwapKnifeCheck(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!IsPlayerAlive(client)) return Plugin_Handled;
	
	if (!Client_HasWeaponKnife(client,"weapon_knife", true) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Handled;
}

public Action:OnPostWeaponEquip(client, weapon)
{ 
	new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	if (weaponindex != 42 && weaponindex != 59) // standard knife || knife t *Thank you Neuro Toxin*
		return Plugin_Continue;

	new m_iEntityQuality = GetEntProp(weapon, Prop_Send, "m_iEntityQuality");
	new m_iItemIDHigh = GetEntProp(weapon, Prop_Send, "m_iItemIDHigh");
	new m_iItemIDLow = GetEntProp(weapon, Prop_Send, "m_iItemIDLow");
	new check = m_iEntityQuality + m_iItemIDHigh + m_iItemIDLow;
	
	decl String:nameTag[64];
	GetEntPropString(weapon, Prop_Send, "m_szCustomName", nameTag, sizeof(nameTag));

	if (!StrEqual(nameTag, "", false)) {
		knife_choice[client] = 0;
		return Plugin_Continue;
	}

	if (check >= 4)
		return Plugin_Continue;
	
	if (knife_choice[client] < 1) 
		return Plugin_Continue;
	
	CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
		SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

public OnClientDisconnect(client) 
{ 
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

public Action:CreateKnifeMenuTimer(client, args) {
	
	if (IsValidClient(client)) {
		CreateTimer(0.1, KnifeMenu, GetClientSerial(client));
	} else {
		CPrintToChat(client, "%t","Command Access Denied Message");
	}
	return Plugin_Handled;
}

public Action:Event_Say(client, const String:command[], arg)
{
	if (g_bEnabled)
	{
		static String:menuTriggers[][] = { "!knief", "!knifes", "!knfie", "!knifw", "!knifew", "!kinfe", "!kinfes", "knife", "/knif", "/knifes", "/knfie", "/knifw", "/knives", "/kinfe", "/kinfes" };
		
		decl String:text[192];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		TrimString(text);
		
		for(new i = 0; i < sizeof(menuTriggers); i++)
		{
			if (StrEqual(text, menuTriggers[i], false) || StrEqual(text, "!KNIFE", true))
			{
				if (IsValidClient(client))
				{
					if (HasPluginAccess(client)) {
						CreateTimer(0.1, KnifeMenu, GetClientSerial(client));
					} else {
						CPrintToChat(client, "%t","Command Access Denied Message");
					}
				}
				return Plugin_Handled;
			}
		}

		//Knife Shortcut Triggers
		//Bayonet
		decl String:Bayonet[32];
		Format(Bayonet, sizeof(Bayonet), "%t", "Knife Trigger Bayonet");
		if (StrEqual(text, Bayonet, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetBayonet(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Gut
		decl String:Gut[32];
		Format(Gut, sizeof(Gut), "%t", "Knife Trigger Gut");
		if (StrEqual(text, Gut, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetGut(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Flip
		decl String:Flip[32];
		Format(Flip, sizeof(Flip), "%t", "Knife Trigger Flip");
		if (StrEqual(text, Flip, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetFlip(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//M9
		decl String:M9[32];
		Format(M9, sizeof(M9), "%t", "Knife Trigger M9");
		if (StrEqual(text, M9, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetM9(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Karambit
		decl String:Karambit[32];
		Format(Karambit, sizeof(Karambit), "%t", "Knife Trigger Karambit");
		if (StrEqual(text, Karambit, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetKarambit(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Huntsman
		decl String:Huntsman[32];
		Format(Huntsman, sizeof(Huntsman), "%t", "Knife Trigger Huntsman");
		if (StrEqual(text, Huntsman, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetHuntsman(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Butterfly
		decl String:Butterfly[32];
		Format(Butterfly, sizeof(Butterfly), "%t", "Knife Trigger Butterfly");
		if (StrEqual(text, Butterfly, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetButterfly(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Falchion Knife
		decl String:Falchion[32];
		Format(Falchion, sizeof(Falchion), "%t", "Knife Trigger Falchion");
		if (StrEqual(text, Falchion, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetFalchion(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Golden Knife
		decl String:Golden[32];
		Format(Golden, sizeof(Golden), "%t", "Knife Trigger Golden");
		if (StrEqual(text, Golden, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetGolden(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Dagger
		decl String:Dagger[32];
		Format(Dagger, sizeof(Dagger), "%t", "Knife Trigger Dagger");
		if (StrEqual(text, Dagger, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetDagger(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
		//Default
		decl String:Default[32];
		Format(Default, sizeof(Default), "%t", "Knife Trigger Default");
		if (StrEqual(text, Default, false))
		{
			if (IsValidClient(client))
			{
				if (HasPluginAccess(client)) {
					SetDefault(client);
				} else {
					CPrintToChat(client, "%t","Command Access Denied Message");
				}
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client)) return;
	
	if (g_bSpawnMessage)
	{
		CPrintToChat(client, "%t","Spawn and Welcome Message");
		CPrintToChat(client, "%t", "Chat Triggers Message");
	}
	
	if (g_bSpawnMenu && IsValidClient(client))
		CreateTimer(0.1, KnifeMenu, GetClientSerial(client));
	
	if (g_bWelcomeMenu && IsValidClient(client))
		CreateTimer(g_fWelcomeMenuTimer, AfterSpawn, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientPostAdminCheck(client)
{
	if (g_bWelcomeMessage)
		CreateTimer(g_fWelcomeMessageTimer, Timer_Welcome_Message, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Welcome_Message(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (g_bWelcomeMessage && IsValidClient(client))
	{
		CPrintToChat(client, "%t","Spawn and Welcome Message");
		CPrintToChat(client, "%t", "Chat Triggers Message");
	}              
}

public Action:AfterSpawn(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (g_bWelcomeMenu && IsValidClient(client) && knife_welcome_spawn_menu[client] == 0)
	{
		if (g_bWelcomeMenuOnlyNoKnife)
		{
			if (knife_choice[client] < 1)
				CreateTimer(0.1, KnifeMenu, GetClientSerial(client)); //Only show Knife Welcome Message if a custom knife hasn't been selected yet.
		} else {
			CreateTimer(0.1, KnifeMenu, GetClientSerial(client));
		}
	}
	if (knife_welcome_spawn_menu[client] == 0) 
		knife_welcome_spawn_menu[client] = 1;
}

public Action:CheckKnife(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if(IsValidClient(client) && IsPlayerAlive(client) && g_bEnabled)
	{
		if(Client_RemoveWeaponKnife(client, "weapon_knife", true)) {
			Equipknife(client);
		} else {
			if (g_bNoKnifeMapDisable) {
				return Plugin_Handled;
			} else {
				Equipknife(client);
			}
		}
	} else {
		return Plugin_Stop;
	}
	return Plugin_Handled;
}

public Action:Equipknife(client)
{      
	if (knife_choice[client] < 0 || knife_choice[client] > MAX_KNIVES)
		knife_choice[client] = 0;
	
	if (knife_choice[client] == 8)
		knife_choice[client] = 0; //Set Default Knife to 0 so default knife users bypass extra strip / equip
	
	if (knife_choice[client] == GOLDEN_KNIFE && !g_bEnableGoldenKnife)
		knife_choice[client] = 0;

	//If the player has selected and saved a knife before access to the knife was restricted to player, 
	//the player would still get the knife until they selected a new one. This sets the knife to default in this scenario.
	if (knife_choice[client] > 0) 
	{
		if (!CheckCommandAccess(client, "sm_knifeupgrade_bayonet", 0, true) && knife_choice[client] == 1) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_gut", 0, true) && knife_choice[client] == 2) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_flip", 0, true) && knife_choice[client] == 3) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_m9", 0, true) && knife_choice[client] == 4) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_karambit", 0, true) && knife_choice[client] == 5) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_huntsman", 0, true) && knife_choice[client] == 6) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
		
		if (!CheckCommandAccess(client, "sm_knifeupgrade_butterfly", 0, true) && knife_choice[client] == 7) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
	
		if (!CheckCommandAccess(client, "sm_knifeupgrade_falchion", 0, true) && knife_choice[client] == 9) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}

		if (!CheckCommandAccess(client, "sm_knifeupgrade_golden", 0, true) && knife_choice[client] == 10) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
		if (!CheckCommandAccess(client, "sm_knifeupgrade_dagger", 0, true) && knife_choice[client] == 11) {
			knife_choice[client] = 0;
			CPrintToChat(client, "%t","No Longer Has Access to Current Knife");
		}
	}
	new iItem;
	switch(knife_choice[client]) {
		case 0:iItem = GivePlayerItem(client, "weapon_knife");
		case 1:iItem = GivePlayerItem(client, "weapon_bayonet");
		case 2:iItem = GivePlayerItem(client, "weapon_knife_gut");
		case 3:iItem = GivePlayerItem(client, "weapon_knife_flip");
		case 4:iItem = GivePlayerItem(client, "weapon_knife_m9_bayonet");
		case 5:iItem = GivePlayerItem(client, "weapon_knife_karambit");
		case 6:iItem = GivePlayerItem(client, "weapon_knife_tactical");
		case 7:iItem = GivePlayerItem(client, "weapon_knife_butterfly");
		case 8:iItem = GivePlayerItem(client, "weapon_knife");
		case 9:iItem = GivePlayerItem(client, "weapon_knife_falchion");
		case 10:iItem = GivePlayerItem(client, "weapon_knifegg");
		case 11:iItem = GivePlayerItem(client, "weapon_knife_push");
		default: return;
	}
	if (iItem > 0) 
		EquipPlayerWeapon(client, iItem);
}

SetBayonet(client)
{
	if (knife_choice[client] == 1) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_bayonet", 0, true))
	{
		knife_choice[client] = 1;
		SetClientCookie(client, g_cookieKnife, "1");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);   
		if (g_bKnifeChosenMessage) 
			CPrintToChat(client, "%t","Bayonet Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetDagger(client)
{
	if (knife_choice[client] == 11) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_dagger", 0, true))
	{
		knife_choice[client] = 11;
		SetClientCookie(client, g_cookieKnife, "11");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		if (g_bKnifeChosenMessage)
			CPrintToChat(client, "%t","Dagger Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetGut(client)
{
	if (knife_choice[client] == 2) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_gut", 0, true))
	{
		knife_choice[client] = 2;
		SetClientCookie(client, g_cookieKnife, "2");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);    
		if (g_bKnifeChosenMessage) 
			CPrintToChat(client, "%t","Gut Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetFlip(client)
{
	if (knife_choice[client] == 3) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_flip", 0, true))
	{
		knife_choice[client] = 3;
		SetClientCookie(client, g_cookieKnife, "3");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);   
		if (g_bKnifeChosenMessage) 
			CPrintToChat(client, "%t","Flip Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetM9(client)
{
	if (knife_choice[client] == 4) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_m9", 0, true))
	{
		knife_choice[client] = 4;
		SetClientCookie(client, g_cookieKnife, "4");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		if (g_bKnifeChosenMessage)
			 CPrintToChat(client, "%t","M9 Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetKarambit(client)
{
	if (knife_choice[client] == 5) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_karambit", 0, true))
	{
		knife_choice[client] = 5;
		SetClientCookie(client, g_cookieKnife, "5");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		if (g_bKnifeChosenMessage) 
			CPrintToChat(client, "%t","Karambit Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetHuntsman(client)
{
	if (knife_choice[client] == 6) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_huntsman", 0, true))
	{
		knife_choice[client] = 6;
		SetClientCookie(client, g_cookieKnife, "6");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		if (g_bKnifeChosenMessage)
			CPrintToChat(client, "%t","Huntsman Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetButterfly(client)
{
	if (knife_choice[client] == 7) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_butterfly", 0, true))
	{
		knife_choice[client] = 7;
		SetClientCookie(client, g_cookieKnife, "7");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		if (g_bKnifeChosenMessage)
			CPrintToChat(client, "%t","Butterfly Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetFalchion(client)
{
	if (knife_choice[client] == 9) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_falchion", 0, true))
	{
		knife_choice[client] = 9;
		SetClientCookie(client, g_cookieKnife, "9");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		if (g_bKnifeChosenMessage)
			CPrintToChat(client, "%t","Falchion Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetGolden(client)
{
	if (knife_choice[client] == 10) return;
	if (CheckCommandAccess(client, "sm_knifeupgrade_golden", 0, true) && g_bEnableGoldenKnife)
	{
		knife_choice[client] = 10;
		SetClientCookie(client, g_cookieKnife, "10");
		CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
		if (g_bKnifeChosenMessage)
			CPrintToChat(client, "%t","Golden Given Message");
	} else {
		CPrintToChat(client, "%t", "Knife Access Denied Message");
	}
}

SetDefault(client)
{
	if (knife_choice[client] == 0) return;
	knife_choice[client] = 0;
	SetClientCookie(client, g_cookieKnife, "0");
	CreateTimer(g_fDelayedEquipTimer, CheckKnife, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
	if (g_bKnifeChosenMessage)
		CPrintToChat(client, "%t","Default Given Message");
}

public Action:KnifeMenu(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	
	if (IsValidClient(client) && g_bEnabled && !g_bNoKnifeMenu)
	{
		ShowKnifeMenu(client);
	} 
	else if (IsValidClient(client) && g_bEnabled && g_bNoKnifeMenu) 
	{
		CPrintToChat(client, "%t","Knife Menu Disabled Message");
	}
	else if (g_bEnabled && IsValidClient(client) && !HasPluginAccess(client))
	{
		CPrintToChat(client, "%t","Command Access Denied Message");
	}
	return Plugin_Handled;
}

public Action:ShowKnifeMenu(client)
{
	decl String:Dagger[32];
	decl String:Bayonet[32];
	decl String:Gut[32];
	decl String:Flip[32];
	decl String:M9[32];
	decl String:Karambit[32];
	decl String:Huntsman[32];
	decl String:Butterfly[32];
	decl String:Falchion[32];
	decl String:Golden[32];
	decl String:Default[32];
	
	Format(Dagger, sizeof(Dagger), "%t", "Menu Knife Dagger");
	Format(Bayonet, sizeof(Bayonet), "%t", "Menu Knife Bayonet");
	Format(Gut, sizeof(Gut), "%t", "Menu Knife Gut");
	Format(Flip, sizeof(Flip), "%t", "Menu Knife Flip");
	Format(M9, sizeof(M9), "%t", "Menu Knife M9");
	Format(Karambit, sizeof(Karambit), "%t", "Menu Knife Karambit");
	Format(Huntsman, sizeof(Huntsman), "%t", "Menu Knife Huntsman");
	Format(Butterfly, sizeof(Butterfly), "%t", "Menu Knife Butterfly");
	Format(Falchion, sizeof(Falchion), "%t", "Menu Knife Falchion");
	Format(Golden, sizeof(Golden), "%t", "Menu Knife Golden");
	Format(Default, sizeof(Default), "%t", "Menu Knife Default");
	
	new Handle:menu = CreateMenu(ShowKnifeMenuHandler);
	SetMenuTitle(menu, "%t", "Knife Menu Title");
	
	//Dagger
	if (CheckCommandAccess(client, "sm_knifeupgrade_dagger", 0, true)) {
		AddMenuItem(menu, "option2", Dagger);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option2", Dagger,ITEMDRAW_DISABLED);
	}

	//Bayonet
	if (CheckCommandAccess(client, "sm_knifeupgrade_bayonet", 0, true)) {
		AddMenuItem(menu, "option3", Bayonet);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option3", Bayonet,ITEMDRAW_DISABLED);
	}
	//Gut
	if (CheckCommandAccess(client, "sm_knifeupgrade_gut", 0, true)) {
		AddMenuItem(menu, "option4", Gut);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option4", Gut,ITEMDRAW_DISABLED);
	}
	//Flip
	if (CheckCommandAccess(client, "sm_knifeupgrade_flip", 0, true)) {
		AddMenuItem(menu, "option5", Flip);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option5", Flip,ITEMDRAW_DISABLED);
	}
	//M9-Bayonet
	if (CheckCommandAccess(client, "sm_knifeupgrade_m9", 0, true)) {
		AddMenuItem(menu, "option6", M9);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option6", M9,ITEMDRAW_DISABLED);
	}
	//Karambit
	if (CheckCommandAccess(client, "sm_knifeupgrade_karambit", 0, true)) {
		AddMenuItem(menu, "option7", Karambit);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option7", Karambit,ITEMDRAW_DISABLED);
	}
	//Huntsman
	if (CheckCommandAccess(client, "sm_knifeupgrade_huntsman", 0, true)) {
		AddMenuItem(menu, "option8", Huntsman);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option8", Huntsman,ITEMDRAW_DISABLED);
	}
	//Butterfly
	if (CheckCommandAccess(client, "sm_knifeupgrade_butterfly", 0, true)) {
		AddMenuItem(menu, "option9", Butterfly);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option9", Butterfly,ITEMDRAW_DISABLED);
	}
	//Falchion
	if (CheckCommandAccess(client, "sm_knifeupgrade_falchion", 0, true)) {
		AddMenuItem(menu, "option10", Falchion);
	} else {
		if(!g_bHideRestricted)
			AddMenuItem(menu, "option10", Falchion,ITEMDRAW_DISABLED);
	}
	//Golden
	if (CheckCommandAccess(client, "sm_knifeupgrade_golden", 0, true) && g_bEnableGoldenKnife) {
		AddMenuItem(menu, "option11", Golden);
	} else {
		if(!g_bHideRestricted) 
		{
			if (g_bEnableGoldenKnife)
				AddMenuItem(menu, "option11", Golden,ITEMDRAW_DISABLED);
		}
	}
	//Default
	AddMenuItem(menu, "option12", Default);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public ShowKnifeMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action){
		case MenuAction_Select: 
		{
			new String:info[32];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			//Dagger
			if (strcmp(info,"option2") == 0) SetDagger(client);
			//Bayonet
			else if (strcmp(info,"option3") == 0) SetBayonet(client);
			//Gut
			else if (strcmp(info,"option4") == 0) SetGut(client);     
			//Flip
			else if (strcmp(info,"option5") == 0) SetFlip(client);
			//M9-Bayonet
			else if (strcmp(info,"option6") == 0) SetM9(client);
			//Karambit
			else if (strcmp(info,"option7") == 0) SetKarambit(client);
			//Huntsman
			else if (strcmp(info,"option8") == 0) SetHuntsman(client);
			//Butterfly
			else if (strcmp(info,"option9") == 0) SetButterfly(client);
			//Falchion
			else if (strcmp(info,"option10") == 0) SetFalchion(client);
			//Golden
			else if (strcmp(info,"option11") == 0) SetGolden(client);
			//Default
			else if (strcmp(info,"option12") == 0) SetDefault(client);
		}
		case MenuAction_End:{CloseHandle(menu);}
	}
}

stock bool:HasPluginAccess(client)
{
	if (!CheckCommandAccess(client, "sm_knifeupgrade", 0, true)) return false;
	return true;
}

stock bool:IsValidClient(client)
{
	if (!(1 <= client <= MaxClients)) return false; 
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}