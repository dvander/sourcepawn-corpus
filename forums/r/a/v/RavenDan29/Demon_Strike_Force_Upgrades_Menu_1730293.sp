#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"

public Plugin:myinfo = 
{
	name = "Demon Strike Force L4D2 Automatic Main Menu Opener",
	author = "WeAreBorg",
	description = "Prompts and opens any main menu",
	version = PLUGIN_VERSION,
	url = "www.maximumonlinegaming.com"
}

new Handle:hEnableFST = INVALID_HANDLE;
new Handle:hEnableCRT = INVALID_HANDLE;
new Handle:hEnableEST = INVALID_HANDLE;
new Handle:hFSTimer = INVALID_HANDLE;
new Handle:hCRTimer = INVALID_HANDLE;
new Handle:hCommand = INVALID_HANDLE;
new Handle:hRCount = INVALID_HANDLE;
new Handle:hMenu = INVALID_HANDLE;
new Handle:hServer = INVALID_HANDLE;

new TimerCount[MAXPLAYERS+1];

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{		
		SetFailState("[SM] Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("AMMOpener_version", PLUGIN_VERSION, "Installed version of Automatic Main Menu Opener on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hEnableFST = CreateConVar("AMMOpener_firstspawn", "1", "Enable Auto Main Menu Open for First Spawn?",FCVAR_PLUGIN|FCVAR_NOTIFY);
	hEnableCRT = CreateConVar("AMMOpener_enablechat", "1", "Enable Chat Reminder To Open Main Menu?",FCVAR_PLUGIN|FCVAR_NOTIFY);
	hEnableEST = CreateConVar("AMMOpener_everyspawn", "1", "Enable Auto Main Menu Open for Every Spawn?",FCVAR_PLUGIN|FCVAR_NOTIFY);
	hFSTimer = CreateConVar("AMMOpener_FSTimer", "15.0", "Time Duration till Menu is opened on player's spawn",FCVAR_PLUGIN|FCVAR_NOTIFY);
	hCRTimer = CreateConVar("AMMOpener_CRTimer", "10.0", "On First Spawn, player will be reminded in chat every <this many seconds>", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hRCount = CreateConVar("AMMOpener_ChatRemindCount", "20", "Number of times to remind player to open the menu on first spawn", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hCommand = CreateConVar("AMMOpener_Command", "sm_upgrades", "Command, minus !, used to open main menu. 'sm_' will be removed when announced to players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hMenu = CreateConVar("AMMOpener_MenuName", "=Survivor Upgrades Menu=", "Menu Title",FCVAR_PLUGIN|FCVAR_NOTIFY);
	hServer = CreateConVar("AMMOpener_Server", "MTMS-Server", "Server Description used when annoucing to players",FCVAR_PLUGIN|FCVAR_NOTIFY);
	hTeams = CreateConVar("AMMOpener_Teams", "2", "Announce to.. 1=spec only 2=survivors only 3=infected only 4=non spec only 5=all",FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookEvent("player_first_spawn", RunOnPlayerSpawnFirst);
	HookEvent("player_spawn", RunOnPlayerSpawn);
	
	AutoExecConfig(true, "l4d2_AMMOpener");
}

/* Player's First Spawn */
public Action:RunOnPlayerSpawnFirst(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	TimerCount[target] = 0;
	if(target > 0)
	{
		if(!IsFakeClient(target))
		{
			// Create First Announce Timer //
			if(GetConVarInt(hEnableFST) == 1)
				CreateTimer(GetConVarFloat(hFSTimer), TimerAnnounceFirst, target);

			// Create Chat Remind Timer //
			if(GetConVarInt(hEnableCRT) == 1)
				CreateTimer(GetConVarFloat(hCRTimer), TimerChatRemind, target, TIMER_REPEAT);
		}
	}
}

/* Player Spawn */
public Action:RunOnPlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	TimerCount[target] = 0;
	if(target > 0)
	{
		/* Create First Announce Timer */
		if(!IsFakeClient(target) && GetConVarInt(hEnableEST) == 1)
		{
			decl String:command[24];
			GetConVarString(hCommand, command, sizeof(command));
			FakeClientCommand(target, command); // Open Main Menu
			CreateTimer(GetConVarFloat(hCRTimer), TimerChatRemind, target);
		}
	}
}

/* First Announce Timer */
public Action:TimerAnnounceFirst(Handle:timer, any:client)
{
	if(client > 0)
	{
		if(!IsFakeClient(client))
		{
			WelcomeMsg(client); // Announce Server
			decl String:command[24];
			GetConVarString(hCommand, command, sizeof(command));
			FakeClientCommand(client, command); // Open Main Menu
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/* Remind Job Timer */
public Action:TimerChatRemind(Handle:timer, any:client)
{
	if(client > 0)
	{
		if(TimerCount[client] < GetConVarInt(hRCount) && !IsFakeClient(client))
		{
			TimerCount[client]++;
			OpenMainMenuMsg(client); //Remind player to open Main Menu and Switch on Notifications Option 2
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


/* Message: remind to open menu */
OpenMainMenuMsg(client)
{
	decl String:command[24], String:menu[24];
	GetConVarString(hCommand, command, sizeof(command));
	ReplaceStringEx(command, sizeof(command), "sm_", "");
	GetConVarString(hMenu, menu, sizeof(menu));
	PrintToChat(client, "\x04 Type \x04!%s\x03 in chat to bring up the %s and Switch on Noifications Option 2", command, menu);
}

/* Message: welcome */
WelcomeMsg(client)
{
	decl String:command[24], String:server[64], String:menu[24];
	GetConVarString(hCommand, command, sizeof(command));
	ReplaceStringEx(command, sizeof(command), "sm_", "");
	GetConVarString(hServer, server, sizeof(server));
	GetConVarString(hMenu, menu, sizeof(menu));
	PrintToChat(client, "\x03Hello %N! Welcome to \x04%s \x03", client, server);
	PrintToChat(client, "\x03Type \x04!%s\x03 in chat to bring up the \x04%s\x03 and Switch on Noifications Option 2", command, menu);
}