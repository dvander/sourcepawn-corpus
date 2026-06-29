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
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <morecolors>
#include <zombiereloaded>

#define PLUGIN_VERSION "1.3.3"

#define MAXIMUM_PROP_CONFIGS 128

new String:g_sPropPaths[MAXIMUM_PROP_CONFIGS][PLATFORM_MAX_PATH];
new String:g_sPropTypes[MAXIMUM_PROP_CONFIGS][32];
new String:g_sPropNames[MAXIMUM_PROP_CONFIGS][64];
new g_iPropCosts[MAXIMUM_PROP_CONFIGS];
new g_iPropHealth[MAXIMUM_PROP_CONFIGS];

new g_iCredits[MAXPLAYERS + 1];

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hChatCommands = INVALID_HANDLE;
new Handle:g_hCreditsMax = INVALID_HANDLE;
new Handle:g_hCreditsConnect = INVALID_HANDLE;
new Handle:g_hCreditsHuman = INVALID_HANDLE;
new Handle:g_hCreditsZombie = INVALID_HANDLE;
new Handle:g_hCreditsInfect = INVALID_HANDLE;
new Handle:g_hCreditsKill = INVALID_HANDLE;
new Handle:g_hCreditsRound = INVALID_HANDLE;
new Handle:g_hLocation = INVALID_HANDLE;
new Handle:g_hRestrict = INVALID_HANDLE;

new bool:g_bEnabled, bool:g_bLateLoad;
new g_iNumProps, g_iCreditsMax, g_iCreditsConnect, g_iCreditsHuman, g_iCreditsZombie, g_iCreditsInfect, g_iCreditsKill, g_iCreditsRound, g_iRestrict = -2, g_iNumCommands, g_iUnique;
new String:g_sLocation[PLATFORM_MAX_PATH], String:g_sChatCommands[16][32];

public Plugin:myinfo =
{
	name = "Z-Prop",
	author = "Darkthrone, Greyscale, Twisted|Panda",
	description = "A redux of the original !zprop plugin.",
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
	LoadTranslations("zprop.phrases");
	CreateConVar("sm_zprop_version", PLUGIN_VERSION, "[ZProp]: Vesrion", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("zprop_enabled", "1", "Enables / disables all features of the plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCreditsMax = CreateConVar("zprop_credits_max", "15", "Max credits that can be attained (0: No limit).", FCVAR_PLUGIN, true, 0.0);
	g_hCreditsConnect = CreateConVar("zprop_credits_connect", "4", "The number of free credits a player received when they join the game.", FCVAR_PLUGIN, true, 0.0);
	g_hCreditsHuman = CreateConVar("zprop_credits_spawn_human", "1", "The number of free credits when spawning as a Human.", FCVAR_PLUGIN, true, 0.0);
	g_hCreditsZombie = CreateConVar("zprop_credits_spawn_zombie", "1", "The number of free credits when spawning as a Zombie.", FCVAR_PLUGIN, true, 0.0);
	g_hCreditsInfect = CreateConVar("zprop_credits_infect", "1", "The number of credits given for infecting a human as zombie.", FCVAR_PLUGIN, true, 0.0);
	g_hCreditsKill = CreateConVar("zprop_credits_kill", "5", "The number of credits given for killing a zombie as human.", FCVAR_PLUGIN, true, 0.0);
	g_hCreditsRound = CreateConVar("zprop_credits_roundstart", "2", "The number of free credits given on start of the round.", FCVAR_PLUGIN, true, 0.0);
	g_hLocation = CreateConVar("zprop_config", "configs/zprop.defines.txt", "The desired configuration file to use.", FCVAR_PLUGIN);
	g_hRestrict = CreateConVar("zprop_team_restrict", "0", "Restricts zprop to a specific team. 0 = Either, 1 = Humans Only, 2 = Zombies Only", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hChatCommands = CreateConVar("zprop_commands", "!zprop,/zprop,!prop,/prop,!props,/props,!zprops,/zprops", "The chat triggers available to clients to access zprop.", FCVAR_NONE);
	AutoExecConfig(true, "zprop");

	HookConVarChange(g_hEnabled, OnSettingsChange); 
	HookConVarChange(g_hCreditsMax, OnSettingsChange); 
	HookConVarChange(g_hCreditsConnect, OnSettingsChange); 
	HookConVarChange(g_hCreditsHuman, OnSettingsChange); 
	HookConVarChange(g_hCreditsZombie, OnSettingsChange); 
	HookConVarChange(g_hCreditsInfect, OnSettingsChange); 
	HookConVarChange(g_hCreditsKill, OnSettingsChange); 
	HookConVarChange(g_hCreditsRound, OnSettingsChange); 
	HookConVarChange(g_hLocation, OnSettingsChange); 
	HookConVarChange(g_hRestrict, OnSettingsChange); 
	HookConVarChange(g_hChatCommands, OnSettingsChange);

	decl String:sTemp[512];
	g_bEnabled = GetConVarBool(g_hEnabled);
	g_iCreditsMax = GetConVarInt(g_hCreditsMax);
	g_iCreditsConnect = GetConVarInt(g_hCreditsConnect);
	g_iCreditsHuman = GetConVarInt(g_hCreditsHuman);
	g_iCreditsZombie = GetConVarInt(g_hCreditsZombie);
	g_iCreditsInfect = GetConVarInt(g_hCreditsInfect);
	g_iCreditsKill = GetConVarInt(g_hCreditsKill);
	g_iCreditsRound = GetConVarInt(g_hCreditsRound);
	g_iRestrict = GetConVarInt(g_hRestrict);
	GetConVarString(g_hLocation, g_sLocation, sizeof(g_sLocation));
	GetConVarString(g_hChatCommands, sTemp, sizeof(sTemp));
	g_iNumCommands = ExplodeString(sTemp, ",", g_sChatCommands, sizeof(g_sChatCommands), sizeof(g_sChatCommands[]));

	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("round_start", Event_OnRoundStart);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public OnConfigsExecuted()
{
	if(g_bEnabled)
	{
		if(g_bLateLoad)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) >= CS_TEAM_SPECTATOR)
				{
					g_iCredits[i] = g_iCreditsConnect;
				}
			}

			g_bLateLoad = false;
		}

		CheckConfig();
	}
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = bool:StringToInt(newvalue);
	else if(cvar == g_hChatCommands)
		g_iNumCommands = ExplodeString(newvalue, ",", g_sChatCommands, sizeof(g_sChatCommands), sizeof(g_sChatCommands[]));
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
	if (!FileToKeyValues(hTemp, sPath))
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
			g_iPropHealth[g_iNumProps] = KvGetNum(hTemp, "health");

			PrecacheModel(g_sPropPaths[g_iNumProps]);
			g_iNumProps++;
		}
		while (KvGotoNextKey(hTemp));
		CloseHandle(hTemp);
	}
}

public Action:Command_Say(client, argc)
{
	if(g_bEnabled && client)
	{
		decl String:sBuffer[192];
		GetCmdArgString(sBuffer, sizeof(sBuffer));
		StripQuotes(sBuffer);

		for(new i = 0; i < g_iNumCommands; i++)
		{
			if(StrEqual(sBuffer, g_sChatCommands[i], false))
			{
				if (!IsPlayerAlive(client))
					return Plugin_Stop;
				else if(g_iRestrict == 1 && !ZR_IsClientHuman(client))
					return Plugin_Stop;
				else if(g_iRestrict == 2 && !ZR_IsClientZombie(client))
					return Plugin_Stop;

				Menu_ZProp(client);
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}

Menu_ZProp(client, pos = 0)
{
	decl String:sTemp[8], String:sBuffer[128];
	new Handle:hMenu = CreateMenu(Menu_ZPropHandle);
	Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Title", client, g_iCredits[client]);
	SetMenuTitle(hMenu, sBuffer);

	for(new i = 0; i < g_iNumProps; i++)
	{
		IntToString(i, sTemp, sizeof(sTemp));
		Format(sBuffer, sizeof(sBuffer), "%T", "Menu_Prop", client, g_sPropNames[i], g_iPropCosts[i]);
		AddMenuItem(hMenu, sTemp, sBuffer,(g_iCredits[client] >= g_iPropCosts[i]) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	}

	DisplayMenuAtItem(hMenu, client, pos, MENU_TIME_FOREVER);
}

public Menu_ZPropHandle(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
			CloseHandle(hMenu);
		case MenuAction_Select:
		{
			decl String:sChoice[8];
			GetMenuItem(hMenu, param2, sChoice, sizeof(sChoice));
			new iIndex = StringToInt(sChoice);
		
			if(g_iCredits[param1] < g_iPropCosts[iIndex])
			{
				CPrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Insufficient_Credits", g_iCredits[param1], g_iPropCosts[iIndex]);
				Menu_ZProp(param1);
				
				return;
			}

			new iEntity = CreateEntityByName(g_sPropTypes[iIndex]);
			if(iEntity >= 0)
			{
				decl Float:fLocation[3], Float:fAngles[3], Float:fOrigin[3], Float:fTemp[3];
				GetClientEyeAngles(param1, fTemp);
				GetClientAbsOrigin(param1, fLocation);
				GetClientAbsAngles(param1, fAngles);

				fAngles[0] = fTemp[0];
				fLocation[2] += 50;
				AddInFrontOf(fLocation, fAngles, 35, fOrigin);

				decl String:sBuffer[24];
				Format(sBuffer, sizeof(sBuffer), "ZProp %d %d", GetClientUserId(param1), g_iUnique);
				DispatchKeyValue(iEntity, "targetname", sBuffer);

				SetEntityModel(iEntity, g_sPropPaths[iIndex]);
				DispatchSpawn(iEntity);
				TeleportEntity(iEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);
				g_iCredits[param1] -= g_iPropCosts[iIndex];

				if(g_iPropHealth[iIndex])
				{
					SetEntProp(iEntity, Prop_Data, "m_takedamage", 2, 1);
					SetEntProp(iEntity, Prop_Data, "m_iHealth", g_iPropHealth[iIndex]);
				}
				
				PrintHintText(param1, "%t%t", "Prefix_Hint", "Hint_Credits_Buy", g_iPropCosts[iIndex], g_iCredits[param1]);
				CPrintToChat(param1, "%t%t", "Prefix_Chat", "Phrase_Spawn_Prop", g_sPropNames[iIndex]);
				g_iUnique++;
			}
			
			Menu_ZProp(param1, GetMenuSelectionPosition());
		}
	}
}

AddInFrontOf(Float:vecOrigin[3], Float:vecAngle[3], units, Float:output[3])
{
	decl Float:vecView[3];
	GetViewVector(vecAngle, vecView);

	output[0] = vecView[0] * units + vecOrigin[0];
	output[1] = vecView[1] * units + vecOrigin[1];
	output[2] = vecView[2] * units + vecOrigin[2];
}

GetViewVector(Float:vecAngle[3], Float:output[3])
{
	output[0] = Cosine(vecAngle[1] / (180 / FLOAT_PI));
	output[1] = Sine(vecAngle[1] / (180 / FLOAT_PI));
	output[2] = -Sine(vecAngle[0] / (180 / FLOAT_PI));
}

public OnClientDisconnect(client)
{
	if(g_bEnabled)
	{
		g_iCredits[client] = 0;
	}
}

CheckCredits(client, amount)
{
	if(!g_iRestrict || (g_iRestrict == 1 && ZR_IsClientHuman(client)) || (g_iRestrict == 2 && ZR_IsClientZombie(client)))
	{
		g_iCredits[client] += amount;
		if(g_iCredits[client] < g_iCreditsMax)
			PrintHintText(client, "%t%t", "Prefix_Hint", "Hint_Credits_Gain", amount, g_iCredits[client]);
		else if(g_iCredits[client] > g_iCreditsMax)
		{
			g_iCredits[client] = g_iCreditsMax;
			PrintHintText(client, "%t%t", "Prefix_Hint", "Hint_Credits_Maximum", g_iCreditsHuman, g_iCredits[client]);
		}
	}
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			return Plugin_Continue;

		if(ZR_IsClientHuman(client))
			CheckCredits(client, g_iCreditsHuman);
		else
			CheckCredits(client, g_iCreditsZombie);
	}
	
	return Plugin_Continue;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(g_bEnabled)
	{
		if(attacker >= 0)
			CheckCredits(attacker, g_iCreditsInfect);
	}
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;

		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if(attacker <= 0 || !IsClientInGame(attacker) || attacker == client)
			return Plugin_Continue;

		if(GetClientTeam(client) != GetClientTeam(attacker))
			CheckCredits(attacker, g_iCreditsKill);
	}
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || !IsClientInGame(client))
			return Plugin_Continue;
			
		new iTeam = GetEventInt(event, "oldteam");
		if(!iTeam)
		{
			g_iCredits[client] = g_iCreditsConnect;
			CPrintToChat(client, "%t%t", "Prefix_Chat", "Phrase_Join");
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_iUnique = 0;

		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
			{
				CheckCredits(i, g_iCreditsRound);
			}
		}
	}
	
	return Plugin_Continue;
}