#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define VERSION ""
#define NAME "Observe client"

#define ADMINFLAG ADMFLAG_KICK



/* Credits:
	Mani - Showed me his observer code from MAP
*/

/* Globals */
new g_offObserverTarget;
new g_clientObserveTarget[MAXPLAYERS+1];
new bool:g_useSteamBans = false;

//CSGO-related
new bool:g_isCSGO;
new Handle:g_hSpec_freeze_time;
new Handle:g_hSpec_freeze_traveltime;
new Handle:g_hSpec_freeze_deathanim_time;
new Handle:g_PlayerMenu = INVALID_HANDLE;

public OnPluginStart() {
	new Handle:conVar;
	
	CreateConVar("observe_version", VERSION, NAME, FCVAR_SPONLY|FCVAR_NOTIFY);
	
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_death", EventPlayerDeath);
	
	RegConsoleCmd("sm_observe", CommandObserve, "Spectate a player when dead.");
	RegConsoleCmd("sm_endobserve", CommandEndObserve, "End spectating a player.");
     RegConsoleCmd("sm_observe2", Menu_swspec);
	
	LoadTranslations("common.phrases");
	LoadTranslations("observe.phrases");
	
	g_offObserverTarget = FindSendPropOffs("CBasePlayer", "m_hObserverTarget");
	if(g_offObserverTarget == -1) {
		SetFailState("Expected to find the offset to m_hObserverTarget, couldn't.");
	}
	
	conVar = FindConVar("sbsrc_version");
	if(conVar != INVALID_HANDLE) {
		g_useSteamBans = true;
	}
	
	decl String:szBuffer[ 8 ];
	
	GetGameFolderName(szBuffer, sizeof(szBuffer));
	
	g_isCSGO = StrEqual(szBuffer, "csgo", false);
	if (g_isCSGO)
	{
		g_hSpec_freeze_time = FindConVar("spec_freeze_time");
		g_hSpec_freeze_traveltime = FindConVar("spec_freeze_traveltime");
		g_hSpec_freeze_deathanim_time = FindConVar("spec_freeze_deathanim_time");
	}
}

/********************************************************************************
	Events
*********************************************************************************/

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	/* Suggestions for improvement, or single-shot method? */
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	for(new client = 1; client <= MaxClients; client++) {
		if(g_clientObserveTarget[client] == target && (IsClientObserver(client) || !IsPlayerAlive(client))) {
			SetClientObserver(client, target, true);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	
	new userId = GetEventInt(event, "userid");
	
	if (!g_isCSGO)
	{
		Timer_Death(INVALID_HANDLE, userId);
	}
	else
	{
		CreateTimer(GetConVarFloat(g_hSpec_freeze_time) + 
			GetConVarFloat(g_hSpec_freeze_traveltime) + 
			GetConVarFloat(g_hSpec_freeze_deathanim_time) +
			0.1, Timer_Death, userId ); //0.1 is needed; tested
	}
	
	return Plugin_Handled;
}

public Action:Timer_Death(Handle:timer, any:userId)
{
	new client = GetClientOfUserId(userId);
	
	if (g_isCSGO && client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		return Plugin_Handled;//prevent late kill messages
	}
	
	//Won't be a real Timer
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

public OnClientDisconnect(client) {
	new String:clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, MAX_NAME_LENGTH);
	
	g_clientObserveTarget[client] = 0;
	for(new i = 1; i <= MaxClients; i++) {
		if(g_clientObserveTarget[i] == client) {
			g_clientObserveTarget[i] = 0;
			if (IsClientInGame(i) && IsClientConnected(i)) {
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
	if(GetCmdArgs() < 1) {
		ReplyToCommand(client, "Usage: sm_observe <name or #userid>");
		return Plugin_Handled;
	}
	
	decl String:targetName[MAX_NAME_LENGTH], String:targetSteamID[MAX_NAME_LENGTH];
	
	GetCmdArg(1, targetName, sizeof(targetName)); //get username part from arguments
	
	new targetClient = FindTarget(client, targetName, false, false);
	if(targetClient == -1) {
		PrintToChat(client, "%t", "Unknown Target");
		return Plugin_Handled;
	}
	
	GetClientName(targetClient, targetName, sizeof(targetName));
	GetClientAuthString(targetClient, targetSteamID, sizeof(targetSteamID));
	g_clientObserveTarget[client] = targetClient;
	
	if(IsClientObserver(client) || !IsPlayerAlive(client)) {
		if(!SetClientObserver(client, targetClient, true)) {
			PrintToChat(client, "%t", "Observe Failed", targetName);
		}
	} else {
		PrintToChat(client, "%t", "Observe on Spec", targetName, targetSteamID);
	}
	
	return Plugin_Handled;
}

/********************************************************************************
	Helper Methods
*********************************************************************************/

public bool:isValidHumanClient(client) {
	if(client > 0 && IsClientInGame(client) && IsClientConnected(client)) {
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
	
	if(g_useSteamBans) {
		ClientCommand(client, "sb_status");
	}
		
	return true; //we assume it went through, else SM would throw a native error and we wouldn't get here anyway
}

public SendClientObserveMessage(client, target) {
	decl String:targetName[MAX_NAME_LENGTH], String:targetSteamID[65];
	GetClientName(target, targetName, MAX_NAME_LENGTH);
	GetClientAuthString(target, targetSteamID, 65);
	PrintToChat(client, "%t", "Observing", targetName, targetSteamID);
}

public Action:Command_ListPlayers(client, args)
{
    g_PlayerMenu = BuildPlayerMenu(client);
    DisplayMenu(g_PlayerMenu, client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

Handle:BuildPlayerMenu(client)
{
    new Handle:menu = CreateMenu(Menu_toObserve);
    new String:name[32];
    new String:nameuid[32];
    new String:id;
    for(new i = 1; i <= MaxClients; i++)
    if (IsClientInGame(i) && !IsFakeClient(i) && i != client)
    {
        GetClientName(i, name, 31);
        id = GetClientUserId(i);
        Format(nameuid, sizeof(nameuid),"%s (%i)", name, id);
        //PrintToChat(client, "id:%i int:%i name:%s idob:%i", id, i, name, g_clientObserveTarget[client]);
        if(i != g_clientObserveTarget[client])
        {
        AddMenuItem(menu, name, nameuid);
        }else{
        new String:observenameuid[32];
        Format(observenameuid, sizeof(observenameuid),"%s", nameuid);
        AddMenuItem(menu, name, observenameuid);
        }
    }
    SetMenuTitle(menu, "Auto observe player:");
    SetMenuExitBackButton(menu , true);
    return menu;
}

public Action:Menu_swspec(client, args)
{
	new Handle:menu = CreateMenu(Menu_toObserve);
	SetMenuTitle(menu, "Observe a player:");
	new maxClients = GetMaxClients();
	for (new i=1; i<=maxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			decl String:name[65];
			GetClientName(i, name, sizeof(name));
			AddMenuItem(menu, name, name);
		}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

public Menu_toObserve(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        new String:info[32];

        GetMenuItem(menu, param2, info, sizeof(info));
        new targetClientid = FindTarget(client, info, false, false);
        if(targetClientid == -1){
            PrintToChat(client, "%t", "Unknown Target");
        }
        if(g_clientObserveTarget[client] != targetClientid)
		{
        CommandObserveMenu(client, info);
        g_PlayerMenu = BuildPlayerMenu(client);
        DisplayMenu(g_PlayerMenu, client, MENU_TIME_FOREVER);
        }else{
        g_clientObserveTarget[client] = 0;
        PrintToChat(client, "%t", "End Observe");
        g_PlayerMenu = BuildPlayerMenu(client);
        DisplayMenu(g_PlayerMenu, client, MENU_TIME_FOREVER);
        }
    }
}

/********************************************************************************
	Commands
*********************************************************************************/
public CommandObserveMenu(client, String:targetClientname[]) {

    //GetClientName(zielid, targetClient, MAX_NAME_LENGTH);
    new targetClientid = FindTarget(client, targetClientname, false, false);
    if(targetClientid == -1){
        PrintToChat(client, "%t", "Unknown Target");
    }else{
    new String:targetSteamID[MAX_NAME_LENGTH];
    g_clientObserveTarget[client] = targetClientid;
    GetClientAuthString(targetClientid, targetSteamID, sizeof(targetSteamID));
    if(IsClientObserver(client) || !IsPlayerAlive(client)) {
        if(!SetClientObserver(client, targetClientid, true)) {
            PrintToChat(client, "%t", "Observe Failed", targetClientname[0]);
        }
    } else {
        PrintToChat(client, "%t", "Observe on Spec", targetClientname[0], targetSteamID);
    }
    }
}