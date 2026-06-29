/*
	v1.3.1
	------
	- Applied a coding style to entire plugin for future updates.
		- All Translations have been renamed and are not compatible with prior.
	- Added cvar zprop_config, which lets you change the zprop configuration file whenever you wish.
		- Lets you create zprop files for each map, to help balance or whatever you fancy.
	- Added cvar zprop_team_restrict, which allows you to restrict the !zprop command to humans and/or zombies.
	- Added cvar zprop_commands, which lets you define which commands access the ZProp feature.
		- Removes the hardcoded !zprop access.
	- Added zprop_enabled, which allows you to enable/disable the entire plugin.
	- Optimized aspects of the plugin where possible.
	- Cached contents pf prop defines to remove unnecessary load.
	- Added support for morecolors.inc and Zombie:Reloaded natives.
	- Replaced zprop_credits_spawn with zprop_credits_spawn_human and zprop_credits_spawn_zombie.
	- Added support for updating cvars in-game.

	v1.3.3
	------
	- Fixed a logic snafu that wasn't resolved in public version where props were only pre-cached once.
	- Assigned each prop a unique targetname for other plugins to target them, if desired
		- "ZProp UserId UniqueIndex

	v1.3.4
	------
	- Disables ZProp during Round End
	- Fixed random bugs that were causing errors.
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <morecolors>
#include <zombiereloaded>

#define PLUGIN_VERSION "1.3.5"

#define MAXIMUM_PROP_CONFIGS 128

new String:g_sPropPaths[MAXIMUM_PROP_CONFIGS][PLATFORM_MAX_PATH];
new String:g_sPropTypes[MAXIMUM_PROP_CONFIGS][32];
new String:g_sPropNames[MAXIMUM_PROP_CONFIGS][64];
new Float:g_iHeightOffsets[MAXIMUM_PROP_CONFIGS];
new Float:g_iBufferOffsets[MAXIMUM_PROP_CONFIGS];
new g_iPropCosts[MAXIMUM_PROP_CONFIGS];
new g_iCredits[MAXPLAYERS + 1];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;
new Handle:g_hVerbose = INVALID_HANDLE;
new Handle:g_hCreditsMax = INVALID_HANDLE;
new Handle:g_hCreditsConnect = INVALID_HANDLE;
new Handle:g_hCreditsHuman = INVALID_HANDLE;
new Handle:g_hCreditsZombie = INVALID_HANDLE;
new Handle:g_hCreditsInfect = INVALID_HANDLE;
new Handle:g_hCreditsKill = INVALID_HANDLE;
new Handle:g_hCreditsRound = INVALID_HANDLE;
new Handle:g_hCreditsMode = INVALID_HANDLE;
new Handle:g_hLocation = INVALID_HANDLE;
new Handle:g_hRestrict = INVALID_HANDLE;

new g_iEnabled;
new g_iNumProps;
new g_iVerbose;
new g_iCreditsMax;
new g_iCreditsConnect;
new g_iCreditsHuman;
new g_iCreditsZombie;
new g_iCreditsInfect;
new g_iCreditsKill;
new g_iCreditsRound;
new g_iCreditsMode;
new g_iRestrict;
new g_iNumCommands;
new g_iUnique;
new g_iPropSelection = -1;
new g_iOffsetAccount = -1;
new g_bInfection = false;
new bool:g_bLateLoad;
new bool:g_bEnding;
new String:g_sLocation[PLATFORM_MAX_PATH];
new String:g_sChatCommands[16][32];

public Plugin:myinfo =
{
	name = "Z-Prop",
	author = "Oats, Darkthrone, Greyscale, Twisted|Panda",
	description = "Enhanced version of the original !zprop plugin",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	g_iOffsetAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (g_iOffsetAccount == -1) SetFailState("[ZProp] Failed to find offset for m_iAccount!");

	LoadTranslations("zprop.phrases");
	CreateConVar("sm_zprop_version", PLUGIN_VERSION, "[ZProp]: Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hEnabled = CreateConVar("zprop_enabled", "1", "Enables / disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hVerbose = CreateConVar("zprop_verbose", "1", "Enables / disables zprop announcement of events through chat or hints.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCreditsMax = CreateConVar("zprop_credits_max", "15", "Max credits that can be attained (0: No limit).", FCVAR_NONE, true, 0.0);
	g_hCreditsConnect = CreateConVar("zprop_credits_connect", "4", "The number of free credits a player received when they join the game.", FCVAR_NONE, true, 0.0);
	g_hCreditsHuman = CreateConVar("zprop_credits_spawn_human", "1", "The number of free credits when spawning as a Human.", FCVAR_NONE, true, 0.0);
	g_hCreditsZombie = CreateConVar("zprop_credits_spawn_zombie", "1", "The number of free credits when spawning as a Zombie.", FCVAR_NONE, true, 0.0);
	g_hCreditsInfect = CreateConVar("zprop_credits_infect", "1", "The number of credits given for infecting a human as zombie.", FCVAR_NONE, true, 0.0);
	g_hCreditsKill = CreateConVar("zprop_credits_kill", "5", "The number of credits given for killing a zombie as human.", FCVAR_NONE, true, 0.0);
	g_hCreditsRound = CreateConVar("zprop_credits_roundstart", "2", "The number of free credits given on start of the round.", FCVAR_NONE, true, 0.0);
	g_hCreditsMode = CreateConVar("zprop_credits_mode", "0", "Whether to use a credit system or player cash for prop pricing. 0 = Credits, 1 = Cash", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hLocation = CreateConVar("zprop_config", "configs/zprop.defines.txt", "The desired configuration file to use.", FCVAR_NONE);
	g_hRestrict = CreateConVar("zprop_team_restrict", "0", "Restricts zprop to a specific team. 0 = Either, 1 = Humans Only, 2 = Zombies Only", FCVAR_NONE, true, 0.0, true, 2.0);
	g_hChatCommands = CreateConVar("zprop_commands", "!prop,/prop", "The chat triggers available to clients to access zprop.", FCVAR_NONE);
	AutoExecConfig(true, "zprop");

	HookConVarChange(g_hEnabled, OnCVarChange);
	HookConVarChange(g_hVerbose, OnCVarChange);
	HookConVarChange(g_hCreditsMax, OnCVarChange);
	HookConVarChange(g_hCreditsConnect, OnCVarChange);
	HookConVarChange(g_hCreditsHuman, OnCVarChange);
	HookConVarChange(g_hCreditsZombie, OnCVarChange);
	HookConVarChange(g_hCreditsInfect, OnCVarChange);
	HookConVarChange(g_hCreditsKill, OnCVarChange);
	HookConVarChange(g_hCreditsRound, OnCVarChange);
	HookConVarChange(g_hCreditsMode, OnCVarChange);
	HookConVarChange(g_hLocation, OnCVarChange);
	HookConVarChange(g_hRestrict, OnCVarChange);
	HookConVarChange(g_hChatCommands, OnCVarChange);

	decl String:sTemp[512];
	g_iEnabled = GetConVarBool(g_hEnabled);
	g_iVerbose = GetConVarBool(g_hVerbose);
	g_iCreditsMax = GetConVarInt(g_hCreditsMax);
	g_iCreditsConnect = GetConVarInt(g_hCreditsConnect);
	g_iCreditsHuman = GetConVarInt(g_hCreditsHuman);
	g_iCreditsZombie = GetConVarInt(g_hCreditsZombie);
	g_iCreditsInfect = GetConVarInt(g_hCreditsInfect);
	g_iCreditsKill = GetConVarInt(g_hCreditsKill);
	g_iCreditsRound = GetConVarInt(g_hCreditsRound);
	g_iCreditsMode = GetConVarInt(g_hCreditsMode);
	g_iRestrict = GetConVarInt(g_hRestrict);
	GetConVarString(g_hLocation, g_sLocation, sizeof(g_sLocation));
	GetConVarString(g_hChatCommands, sTemp, sizeof(sTemp));
	g_iNumCommands = ExplodeString(sTemp, ",", g_sChatCommands, sizeof(g_sChatCommands), sizeof(g_sChatCommands[]));

	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_start", Event_OnRoundEnd);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("prop_physics_create", SpawnCommand);
	SetCommandFlags("prop_physics_create", GetCommandFlags("prop_physics_create")^FCVAR_CHEAT);
}

public OnPluginEnd()
{
	SetCommandFlags("prop_physics_create", GetCommandFlags("prop_physics_create")|FCVAR_CHEAT);
}

public Action:SpawnCommand(client, args)
{
	if(g_iPropSelection == -1)
	{
		CPrintToChat(client, "%tUnable to spawn prop", "Prefix_Chat");
		return Plugin_Handled;
	}

	new iCash = GetEntData(client, g_iOffsetAccount);

	if((g_iCreditsMode == 0 && g_iCredits[client] < g_iPropCosts[g_iPropSelection]) || (g_iCreditsMode == 1 && iCash < g_iPropCosts[g_iPropSelection]))
	{
		CPrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Insufficient_Funds", g_iCreditsMode == 0 ? "credits" : "cash");
		Menu_ZProp(client);
		return Plugin_Handled;
	}

	// Deduct credits if using credits mode
	if(g_iCreditsMode == 0) g_iCredits[client] -= g_iPropCosts[g_iPropSelection];
	// Deduct cash if using cash mode
	else SetEntData(client, g_iOffsetAccount, iCash - g_iPropCosts[g_iPropSelection]);

	if(g_iCreditsMode == 0) PrintHintText(client, "%t%t", "Prefix_Hint", "Hint_Credits_Buy", g_iPropCosts[g_iPropSelection], g_iCredits[client]);
	if(g_iVerbose == 1) CPrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Spawn_Prop", g_sPropNames[g_iPropSelection]);
	g_iUnique++;

	if(StrEqual(g_sPropTypes[g_iPropSelection], "prop_physics_override", false))
	{
		new iEntity = CreateEntityByName("prop_physics_override");
		new Float:VecOrigin[3];
		new Float:VecAngles[3];
		decl String:sPropPath[PLATFORM_MAX_PATH];
		Format(sPropPath, PLATFORM_MAX_PATH, "models/%s", g_sPropPaths[g_iPropSelection]);
		SetEntityModel(iEntity, sPropPath);
		GetClientEyePosition(client, VecOrigin);
		GetClientEyeAngles(client, VecAngles);
		TR_TraceRayFilter(VecOrigin, VecAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
		TR_GetEndPosition(VecOrigin);
		AddInFrontOf(VecOrigin, VecAngles, -g_iBufferOffsets[g_iPropSelection], VecOrigin);
		VecAngles[0] = 0.0;
		VecOrigin[2] += g_iHeightOffsets[g_iPropSelection];
		DispatchKeyValue(iEntity, "StartDisabled", "false");
		DispatchKeyValue(iEntity, "Solid", "6");
		AcceptEntityInput(iEntity, "TurnOn", iEntity, iEntity, 0);
	 	SetEntProp(iEntity, Prop_Data, "m_CollisionGroup", 5);
		SetEntityMoveType(iEntity, MOVETYPE_VPHYSICS);
		DispatchSpawn(iEntity);
		TeleportEntity(iEntity, VecOrigin, VecAngles, NULL_VECTOR);
		AcceptEntityInput(iEntity, "EnableCollision");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public OnMapStart()
{
	if(!g_iEnabled)
		return;

	g_bInfection = false;
}

public OnConfigsExecuted()
{
	if(g_iEnabled)
	{
		if(g_bLateLoad)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) >= CS_TEAM_SPECTATOR)
						g_iCredits[i] = g_iCreditsConnect;
				}
			}

			g_bLateLoad = false;
		}

		CheckConfig();
	}
}

public OnCVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_iEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ",", g_sChatCommands, sizeof(g_sChatCommands), sizeof(g_sChatCommands[]));
	else if(cvar == g_hVerbose)
		g_iVerbose = StringToInt(newvalue);
	else if(cvar == g_hCreditsMax)
		g_iCreditsMax = StringToInt(newvalue);
	else if(cvar == g_hCreditsConnect)
		g_iCreditsConnect = StringToInt(newvalue);
	else if(cvar == g_hCreditsHuman)
		g_iCreditsHuman = StringToInt(newvalue);
	else if(cvar == g_hCreditsZombie)
		g_iCreditsZombie = StringToInt(newvalue);
	else if(cvar == g_hCreditsInfect)
		g_iCreditsInfect = StringToInt(newvalue);
	else if(cvar == g_hCreditsKill)
		g_iCreditsKill = StringToInt(newvalue);
	else if(cvar == g_hCreditsRound)
		g_iCreditsRound = StringToInt(newvalue);
	else if(cvar == g_hCreditsMode)
		g_iCreditsMode = StringToInt(newvalue);
	else if(cvar == g_hRestrict)
		g_iRestrict = StringToInt(newvalue);
	else if(cvar == g_hLocation)
		CheckConfig();
}

CheckConfig()
{
	g_iNumProps = 0;
	decl String:sPath[PLATFORM_MAX_PATH];
	new Handle:hTemp = CreateKeyValues("zprops.defines");
	BuildPath(Path_SM, sPath, sizeof(sPath), g_sLocation);
	if(!FileToKeyValues(hTemp, sPath))
		SetFailState("[ZPROP] - Configuration '%s' missing from server!", g_sLocation);
	else
	{
		KvGotoFirstSubKey(hTemp);
		do
		{
			KvGetSectionName(hTemp, g_sPropNames[g_iNumProps], sizeof(g_sPropNames[]));
			KvGetString(hTemp, "model", g_sPropPaths[g_iNumProps], sizeof(g_sPropPaths[]));
			KvGetString(hTemp, "type", g_sPropTypes[g_iNumProps], sizeof(g_sPropTypes[]), "prop_physics");
			g_iPropCosts[g_iNumProps] = KvGetNum(hTemp, "cost");
			g_iHeightOffsets[g_iNumProps] = KvGetFloat(hTemp, "height");
			g_iBufferOffsets[g_iNumProps] = KvGetFloat(hTemp, "buffer");

			decl String:sPropPath[PLATFORM_MAX_PATH];
			Format(sPropPath, PLATFORM_MAX_PATH, "models/%s", g_sPropPaths[g_iNumProps]);
			PrecacheModel(sPropPath);
			g_iNumProps++;
		}
		while (KvGotoNextKey(hTemp));
		CloseHandle(hTemp);
	}
}

public Action:Command_Say(client, argc)
{
	if(g_iEnabled && client)
	{
		decl String:sBuffer[192];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		StripQuotes(sBuffer);

		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(sBuffer, g_sChatCommands[i], false))
			{
				if(g_bEnding || !IsPlayerAlive(client))
					return Plugin_Handled;
				else if(g_iRestrict == 1 && !ZR_IsClientHuman(client))
					return Plugin_Handled;
				else if(g_iRestrict == 2 && !ZR_IsClientZombie(client))
					return Plugin_Handled;

				Menu_ZProp(client);
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if (entity == data)
	{
		return false;
	}
	return true;
}

Menu_ZProp(client, pos = 0)
{
	decl String:sTemp[8], String:sBuffer[128];
	new Handle:hMenu = CreateMenu(Menu_ZPropHandle);
	if(g_iCreditsMode == 0) Format(sBuffer, sizeof(sBuffer), "%t", "Menu_Title_Credits", g_iCredits[client]);
	else Format(sBuffer, sizeof(sBuffer), "%t", "Menu_Title_Cash");
	SetMenuTitle(hMenu, sBuffer);

	for(new i = 0; i < g_iNumProps; i++)
	{
		IntToString(i, sTemp, sizeof(sTemp));
		decl String:sCostUnit[2];
		sCostUnit = g_iCreditsMode == 0 ? "" : "$";
		if(g_iCreditsMode == 0)
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "Menu_Prop_Credits", g_sPropNames[i], g_iPropCosts[i]);
			AddMenuItem(hMenu, sTemp, sBuffer, (g_iCredits[client] >= g_iPropCosts[i]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		else
		{
			Format(sBuffer, sizeof(sBuffer), "%t", "Menu_Prop_Cash", g_sPropNames[i], g_iPropCosts[i]);
			AddMenuItem(hMenu, sTemp, sBuffer, (GetEntData(client, g_iOffsetAccount) >= g_iPropCosts[i]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
	}

	DisplayMenuAtItem(hMenu, client, pos, MENU_TIME_FOREVER);
}

public Menu_ZPropHandle(Handle:hMenu, MenuAction:action, client, selection)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(hMenu);
		case MenuAction_Select:
		{
			decl String:sChoice[8];
			GetMenuItem(hMenu, selection, sChoice, sizeof(sChoice));
			g_iPropSelection = StringToInt(sChoice);
			FakeClientCommand(client, "prop_physics_create %s", g_sPropPaths[g_iPropSelection]);
			g_iPropSelection = -1;
			Menu_ZProp(client, GetMenuSelectionPosition());
		}
	}
}

AddInFrontOf(Float:vecOrigin[3], Float:angForward[3], Float:distance, Float:output[3])
{
	decl Float:vecView[3];
	GetViewVector(angForward, vecView);

	output[0] = vecView[0] * distance + vecOrigin[0];
	output[1] = vecView[1] * distance + vecOrigin[1];
	output[2] = vecView[2] * distance + vecOrigin[2];
}

GetViewVector(Float:angForward[3], Float:output[3])
{
	output[0] = Cosine(angForward[1] / (180 / FLOAT_PI));
	output[1] = Sine(angForward[1] / (180 / FLOAT_PI));
	output[2] = -Sine(angForward[0] / (180 / FLOAT_PI));
}

public OnClientDisconnect(client)
{
	if(g_iEnabled)
	{
		g_iCredits[client] = 0;
	}
}

CheckCredits(client, amount)
{
	if(g_iCreditsMode == 0)
	{
		new bool:bValid;
		if(!g_iRestrict || !g_bInfection && g_iRestrict == 1)
			bValid = true;
		else if(g_bInfection && ((GetClientTeam(client) == CS_TEAM_CT && g_iRestrict == 1) || (GetClientTeam(client) == CS_TEAM_T && g_iRestrict == 2)))
			bValid = true;

		if(bValid)
		{
			g_iCredits[client] += amount;
			if(g_iCredits[client] < g_iCreditsMax && g_iCreditsMode == 1)
				PrintHintText(client, "%t%t", "Prefix_Hint", "Hint_Credits_Gain", amount, g_iCredits[client]);
			else if(g_iCredits[client] > g_iCreditsMax)
			{
				g_iCredits[client] = g_iCreditsMax;
				if(g_iVerbose == 1 && g_iCreditsMode == 1)
				{
					PrintHintText(client, "%t%t", "Prefix_Hint", "Hint_Credits_Maximum", g_iCreditsHuman, g_iCredits[client]);
				}
			}
		}
	}
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			return Plugin_Continue;

		if(!g_bInfection || ZR_IsClientHuman(client))
			CheckCredits(client, g_iCreditsHuman);
	}

	return Plugin_Continue;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(g_iEnabled)
	{
		if(motherInfect)
			g_bInfection = true;

		CheckCredits(client, g_iCreditsZombie);
		if(attacker >= 1 && attacker <= MaxClients)
			CheckCredits(attacker, g_iCreditsInfect);
	}
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;

		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(attacker <= 0 || !IsClientInGame(attacker) || attacker == client)
			return Plugin_Continue;

		if(!g_bInfection)
			return Plugin_Continue;

		if(GetClientTeam(client) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT)
			CheckCredits(attacker, g_iCreditsKill);
	}

	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;

		if(GetEventInt(event, "oldteam") == 0)
		{
			g_iCredits[client] = g_iCreditsConnect;
			CPrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Join");
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		g_iUnique = 0;
		g_bInfection = false;

		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i) || GetClientTeam(i) <= CS_TEAM_SPECTATOR)
				continue;

			CheckCredits(i, g_iCreditsRound);
		}
	}

	return Plugin_Continue;
}

public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iEnabled)
	{
		g_bInfection = false;
	}

	return Plugin_Continue;
}
