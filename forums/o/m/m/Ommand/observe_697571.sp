#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "Observe Client",
	author = "WhiteWolf",
	description = "Observe client when dead",
	version = "1.2aR",
	url = "http://www.whitewolf.us"
};

/* Credits:
	Mani - Showed me his observer code from MAP
*/

/* Globals */
new g_maxClients;
new g_offObserverTarget;
new g_clientObserveTarget[MAXPLAYERS+1];
new bool:g_useSteamBans = false;
new Handle:hTopMenu = INVALID_HANDLE;

public OnPluginStart() {
	new Handle:conVar;

	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_disconnect", EventPlayerDisconnect);

	RegConsoleCmd("sm_observe", CommandObserve, "Spectate a player when dead.");
	RegConsoleCmd("sm_endobserve", CommandEndObserve, "End spectating a player.");

	g_maxClients = GetMaxClients();

	LoadTranslations("observe.phrases");
	LoadTranslations("common.phrases");

	g_offObserverTarget = FindSendPropOffs("CBasePlayer", "m_hObserverTarget");
	if(g_offObserverTarget == -1) {
		SetFailState("Expected to find the offset to m_hObserverTarget, couldn't.");
	}


	conVar = FindConVar("sb_version");
	if(conVar != INVALID_HANDLE) {
		g_useSteamBans = true;
	}

	/* Account for late loading */
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Build the "Player Commands" category */
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, 
			"sm_observe",
			TopMenuObject_Item,
			AdminMenu_Observe,
			player_commands,
			"sm_observe",
			ADMFLAG_CHAT);
	}
}

/********************************************************************************
	Events
*********************************************************************************/

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	g_clientObserveTarget[client]=0;
	
	return true;
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	/* Suggestions for improvement, or single-shot method? */	
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	g_clientObserveTarget[target]=0; //If the person spawning is specing someone, stop them from continuing	
	for(new client = 1; client < g_maxClients; client++) {
		if(g_clientObserveTarget[client] == target && (IsClientObserver(client) || IsPlayerAlive(client))) {
			SetClientObserver(client, target, true);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_clientObserveTarget[client] > 0) {
		new target = g_clientObserveTarget[client];
		if(!isValidHumanClient(target)) {
			g_clientObserveTarget[client] = 0;
			return Plugin_Handled;
		}

		if(IsPlayerAlive(target)) {
			SetClientObserver(client, target, true);
		}
	}
	return Plugin_Handled;
}

public Action:EventPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:clientName[MAX_NAME_LENGTH];
	GetEventString(event, "name", clientName, MAX_NAME_LENGTH);

	g_clientObserveTarget[client] = 0;
	if (client!=0) {
		for(new i = 1; i < g_maxClients; i++) {
			if(g_clientObserveTarget[i] == client) {
				g_clientObserveTarget[i] = 0;
				PrintToChat(i, "%t", "Target Left", clientName);
			}
		}
	}
}

/********************************************************************************
	Commands
*********************************************************************************/

public Action:CommandEndObserve(client, args) {
	g_clientObserveTarget[client] = 0;
	PrintToChat(client, "%t", "End Observe");
	return Plugin_Handled;
}

public Action:CommandObserve(client, args) {
	decl String:targetName[MAX_NAME_LENGTH], String:targetSteamID[MAX_NAME_LENGTH];
	
	GetCmdArg(1, targetName, sizeof(targetName)); //get username part from arguments

	new targetClient = FindTarget(client, targetName, false, false);
	if(targetClient == -1) {
		PrintToChat(client, "%t", "Unknown Target");
	}

	GetClientName(targetClient, targetName, sizeof(targetName));
	GetClientAuthString(targetClient, targetSteamID, sizeof(targetSteamID));
	g_clientObserveTarget[client] = targetClient;

	if(g_useSteamBans) {
		ClientCommand(client, "sb_status");
	}

	if(IsClientObserver(client) || !IsPlayerAlive(client)) {
		if(!SetClientObserver(client, targetClient, true)) {
			PrintToChat(client, "%t", "Observe Failed", targetName);
		}
	} else {
		PrintToChat(client, "%t", "Observe on Spec", targetName, targetSteamID);
	}

	return Plugin_Handled;
}

public Action:CommandObserveFromMenu(client, targetClient) {
	decl String:targetName[MAX_NAME_LENGTH], String:targetSteamID[MAX_NAME_LENGTH];

	if(targetClient == -1) {
		PrintToChat(client, "%t", "Unknown Target");
	}
	
	if (g_clientObserveTarget[client] == targetClient) {
			CommandEndObserve(client, 0);
	}
	
	if(GetClientTeam(client)==1) {

		GetClientName(targetClient, targetName, sizeof(targetName));
		GetClientAuthString(targetClient, targetSteamID, sizeof(targetSteamID));
		g_clientObserveTarget[client] = targetClient;

		if(g_useSteamBans) {
			ClientCommand(client, "sb_status");
		}

		if(IsClientObserver(client) || !IsPlayerAlive(client)) {
			if(!SetClientObserver(client, targetClient, true)) {
				PrintToChat(client, "%t", "Observe Failed", targetName);
			}
		} else {
			PrintToChat(client, "%t", "Observe on Spec", targetName, targetSteamID);
		}
	}
	else
		PrintToChat(client, "%t", "Observe Only Spec");
	
	return Plugin_Handled;
	
}

/********************************************************************************
	Helper Methods
*********************************************************************************/

public bool:isValidHumanClient(client) {
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

public bool:SetClientObserver(client, target, bool:sendMessage) {
	if(!isValidHumanClient(client) || !isValidHumanClient(target)) {
		return false;
	}

	SetEntDataEnt2(client, g_offObserverTarget, target, true);

	if(sendMessage) {
		SendClientObserveMessage(client, target);
	}
	return true; //we assume it went through, else SM would throw a native error and we wouldn't get here anyway
}

public SendClientObserveMessage(client, target) {
	decl String:targetName[MAX_NAME_LENGTH], String:targetSteamID[65];
	GetClientName(target, targetName, MAX_NAME_LENGTH);
	GetClientAuthString(target, targetSteamID, 65);
	PrintToChat(client, "%t", "Observing", targetName, targetSteamID);
}


/********************************************************************************
	Menu Stuff
*********************************************************************************/

enum CommType
{
	CommType_Observe,
	CommType_EndObserve
};

DisplayObserveOptions(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ObserveOptions);
	
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Auto-Observe", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	if(g_clientObserveTarget[client]==0)
	{
		DisplayObservePlayerMenu(client);
	}
	else
	{
		AddMenuItem(menu, "0", "Observe Player");
		AddMenuItem(menu, "1", "End Observe");
			
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

DisplayObservePlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_ObservePlayer);
	
	decl String:title[100];
	Format(title, sizeof(title), "%T:", "Observe Player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, client, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public AdminMenu_Observe(Handle:topmenu, 
					  TopMenuAction:action,
					  TopMenuObject:object_id,
					  param,
					  String:buffer[],
					  maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Auto-Observe", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayObserveOptions(param);
	}
}

public MenuHandler_ObserveOptions(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new CommType:type;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		type = CommType:StringToInt(info);

		
		switch (type)
		{
			case CommType_Observe:
			{
				DisplayObservePlayerMenu(param1);
			}
			case CommType_EndObserve:
			{
				CommandEndObserve(param1, 0);
			}
		}
	}
}

public MenuHandler_ObservePlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] Player no longer available");
		}
		else
		{
			CommandObserveFromMenu(param1, target);
		}
	}
}