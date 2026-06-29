///////////////////////////////////////////////////////////////////////////
//                                                                       //
// -Plugin:      L4D2 Pause                                              //
// -Game:        Left 4 Dead 2                                           //
// -Author:      Lee "pvtschlag" Silvey                                  //
//               v.3 authors: -999-, n3wton, dirka_dirka                 //
// -Version:     0.3                                                     //
// -URL:         http://forums.alliedmods.net/showthread.php?p=997585    //
// -Description: Allows teams to pause the game when agreed on, and      //
//               allows admins to force the game to pause.               //
//                                                                       //
// -Changelog:                                                           //
//     * Version 0.1.0:                                                  //
//         -Initial Release                                              //
//     * Version 0.1.1:                                                  //
//         -Fixed typo                                                   //
//         -Added a timeout for pause requests                           //
//         -Pause requests now get reset when map ends                   //
//     * Version 0.2.0:                                                  //
//         -Chat is now forced to display during pause                   //
//         -Added option for enabling alltalk while game is paused       //
//         -Added cvar to configure how long a pause request takes to    //
//          timeout.                                                     //
//     * Version 0.2.1:                                                  //
//         -Fixed some more chat that didn't show                        //
//         -Added option for only allowing the !forcepause command       //
//                                                                       //
//     * Version 0.3:                                                    //
//         -Fixed AllTalk                                                //
//         -Added cvar to allow other plugins to detect when paused      //
//         -Added timers to allow for people to (dis)connect             //
//         -Added fix for chat flooding                                  //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

#include <sourcemod>

#define PLUGIN_VERSION "0.3"

#define L4D_TEAM_UNASSIGNED 0
#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3

new Handle:g_hPaused;
new Handle:g_hPauseAlltalk;
new Handle:g_hPauseTimeout;
new Handle:g_hPauseFlood;
new Handle:g_hFloodTime;
new Handle:g_hGamemode;
new Handle:g_hPausable;
new Handle:g_hAlltalk;
new Handle:g_hForceOnly;
new bool:g_bIsPaused = false;
new bool:g_bIsUnpausing = false;
new bool:g_bAllowPause = false;
new bool:g_bAllowUnpause = false;
new bool:g_bWasForced = false;
new bool:g_bPauseRequest[2] = { false, false };
new Float:g_fFloodValue;

public Plugin:myinfo =
{
	name = "L4D2 Pause",
	author = "pvtschlag & Dirka_Dirka",
	description = "Allows teams to pause the game when agreed on, and allows admins to force the game to pause.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=997585"
};

public OnPluginStart()
{
	g_hPauseTimeout = CreateConVar("l4d2pause_timeout", "30.0", "The amount of time it takes an unaccepted pause request to expire.", FCVAR_PLUGIN, true, 0.0, false);
	g_hPauseAlltalk = CreateConVar("l4d2pause_alltalk", "0", "Enables alltalk while the game is paused.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hPauseFlood = CreateConVar("l4d2pause_stopchatflood", "1", "Makes it impossible to flood the chat whilst paused", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hForceOnly = CreateConVar("l4d2pause_forceonly", "0", "Only allow the game to be paused by the forcepause command(Admin only).", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2pause"); //Create and/or load the plugin config

	g_hPaused = CreateConVar("l4d2pause_enabled", "0", "Game is paused (for other plugins to detect).", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);

	CreateConVar("l4d2pause_version", PLUGIN_VERSION, "L4D2 Pause Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD||FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hGamemode = FindConVar("mp_gamemode");
	g_hPausable = FindConVar("sv_pausable");
	g_hAlltalk = FindConVar("sv_alltalk");
	g_hFloodTime = FindConVar("sm_flood_time");
	
	SetConVarInt(g_hPausable, 0);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	RegConsoleCmd("pause", Command_Pause);
	RegConsoleCmd("setpause", Command_Setpause);
	RegConsoleCmd("unpause", Command_Unpause);
	RegConsoleCmd("sm_pause", Command_SMPause, "Pauses the game");
	RegConsoleCmd("sm_unpause", Command_SMUnpause, "Unpauses the game");
	
	RegAdminCmd("sm_forcepause", Command_SMForcePause, ADMFLAG_BAN, "Forces the game to pause/unpause");
	
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Pre);
}

public OnMapEnd()
{
	ResetPauseRequest(); //Reset any pause requests
	if (GetConVarBool(g_hPauseAlltalk))
	{
		DisablePausedAlltalk(); //Disable alltalk incase the map somehow ended while the game was paused
		SetConVarInt(g_hPaused, 0);
	}
}

public Action:Command_Say(client, args)
{
	if (g_bIsPaused) //Do our own chat output when the game is paused
	{
		decl String:sText[256];
		GetCmdArg(1, sText, sizeof(sText));
		if (client == 0 || (IsChatTrigger() && sText[0] == '/')) //Ignore if it is a server message or a silent chat trigger
		{
			return Plugin_Continue;
		}
		
		PrintToChatAll("\x03%N\x01 : %s", client, sText); //Display the users message
		return Plugin_Handled; //Since the issue only occurs sometimes we need to block default output to prevent showing text twice
	}
	return Plugin_Continue;
}

public Action:Command_SayTeam(client, args)
{
	if (g_bIsPaused) //Do our own chat output when the game is paused
	{
		decl String:sText[256];
		GetCmdArg(1, sText, sizeof(sText));
		if (client == 0 || (IsChatTrigger() && sText[0] == '/')) //Ignore if it is a server message or a silent chat trigger
		{
			return Plugin_Continue;
		}
		
		decl String:sTeamName[16];
		new iTeam = GetClientTeam(client);
		if (iTeam == L4D_TEAM_INFECTED)
		{
			sTeamName = "Infected";
		}
		else if (iTeam == L4D_TEAM_SURVIVOR)
		{
			sTeamName = "Survivor";
		}
		else
		{
			sTeamName = "Spectator";
		}
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				if (GetClientTeam(i) == iTeam) //Is teamchat so only display it to people on the same team
				{
					PrintToChat(i, "\x01(%s) \x03%N\x01 : %s", sTeamName, client, sText); //Display the users message
				}
			}
		}
		return Plugin_Handled; //Since the issue only occurs sometimes we need to block default output to prevent showing text twice
	}
	return Plugin_Continue;
}

public Action:Command_Pause(client, args)
{
	return Plugin_Handled; //We don't want the pause command doing anything
}

public Action:Command_Setpause(client, args)
{
	if (g_bAllowPause) //Only allow the command to go through if we have said it could previously
	{
		g_bIsPaused = true; //Game is now paused
		g_bIsUnpausing = false; //Game was just paused and can no longer be unpausing if it was
		g_bAllowPause = false; //Don't allow this command to be used again untill we say
		SetConVarInt(g_hPaused, 1);
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:Command_Unpause(client, args)
{
	if (g_bAllowUnpause) //Only allow the command to go through if we have said it could previously
	{
		g_bIsPaused = false; //Game is now active
		g_bIsUnpausing = false; //Game is active so it is no longer in the unpausing state
		g_bAllowUnpause = false; //Don't allow this command to be used again untill we say
		SetConVarInt(g_hPaused, 0);
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:Command_SMPause(client, args)
{
	if (GetConVarBool(g_hForceOnly))
	{
		ReplyToCommand(client, "\x03[Pause]\x01 Only an Admin can pause the game using \x04!forcepause\x01.");
		return Plugin_Handled;
	}
	
	if (IsCoop()) //If it is a coop game only allow admins to pause since there is only one team
	{
		ReplyToCommand(client, "\x03[Pause]\x01 Only an Admin can pause the game in coop mode by using \x04!forcepause\x01.");
		return Plugin_Handled;
	}

	if (g_bIsPaused) //Already paused, tell them how to unpause
	{
		ReplyToCommand(client, "\x03[Pause]\x01 Game is already paused. Use \x04!unpause\x01 to resume the game.");
		return Plugin_Handled;
	}
	
	new iTeam = GetClientTeam(client);
	if (iTeam != L4D_TEAM_SURVIVOR && iTeam != L4D_TEAM_INFECTED) //Not on survior or infected team so ignore them
	{
		return Plugin_Handled;
	}
	else if (g_bPauseRequest[iTeam-2]) //This team has already requested a pause so ignore them
	{
		return Plugin_Handled;
	}
	else //New pause request for this team
	{
		g_bPauseRequest[iTeam-2] = true;
	}
	
	if (g_bPauseRequest[0] && g_bPauseRequest[1]) //Both teams want to pause
	{
		PrintToChatAll("\x03[Pause]\x01 Both teams have agreed to pause the game. Use \x04!unpause\x01 to resume the game.");
		if (GetConVarBool(g_hPauseAlltalk))
		{
			EnablePausedAlltalk(); //Enable alltalk
		}
		CreateTimer(1.0, TimerPause, client);
	}
	else if (g_bPauseRequest[0] && !g_bPauseRequest[1]) //Notify infected that the survirors want to pause
	{
		PrintToChatAll("\x03[Pause]\x01 The Survivors want to pause the game. An Infected can accept the request with the \x04!pause\x01 command.");
		new Float:fTime = GetConVarFloat(g_hPauseTimeout);
		if (fTime > 0)
		{
			CreateTimer(fTime, PauseRequestTimeout, 2);
		}
	}
	else if (g_bPauseRequest[1] && !g_bPauseRequest[0]) //Notify survivors that the infected want to pause
	{
		PrintToChatAll("\x03[Pause]\x01 The Infected want to pause the game. A Survivor can accept the request the \x04!pause\x01 command.");
		new Float:fTime = GetConVarFloat(g_hPauseTimeout);
		if (fTime > 0)
		{
			CreateTimer(fTime, PauseRequestTimeout, 3);
		}
	}
	return Plugin_Handled;
}

public Action:Command_SMUnpause(client, args)
{
	new iTeam = GetClientTeam(client);
	if (g_bWasForced) //An admin forced the game to pause so only an admin can unpause it
	{
		ReplyToCommand(client, "\x03[Pause]\x01 The game was paused by an admin and can only be unpaused with \x04!forcepause\x01.");
		return Plugin_Handled;
	}
	if (g_bIsPaused && !g_bIsUnpausing) //Is paused and not currently unpausing
	{
		if (iTeam == L4D_TEAM_SURVIVOR) //Surviors unpaused
		{
			PrintToChatAll("\x03[Pause]\x01 The game has been unpaused by the Survivors.");
		}
		else if (iTeam == L4D_TEAM_INFECTED) //Infected unpaused
		{
			PrintToChatAll("\x03[Pause]\x01 The game has bee unpaused by the Infected.");
		}
		else //Don't allow spectators to unpause
		{
			return Plugin_Handled;
		}
		g_bIsUnpausing = true; //Set unpausing state
		if (GetConVarBool(g_hPauseAlltalk))
		{
			DisablePausedAlltalk(); //Disable alltalk
		}
		CreateTimer(1.0, UnpauseCountdown, client, TIMER_REPEAT); //Start unpause countdown
	}
	return Plugin_Handled;
}

public Action:Command_SMForcePause(client, args)
{
	if (g_bIsPaused && !g_bIsUnpausing) //Is paused and not currently unpausing
	{
		g_bWasForced = false;
		PrintToChatAll("\x03[Pause]\x01 The game has been unpaused by an Admin.");
		g_bIsUnpausing = true; //Set unpausing state
		if (GetConVarBool(g_hPauseAlltalk))
		{
			DisablePausedAlltalk(); //Disable alltalk
		}
		CreateTimer(1.0, UnpauseCountdown, client, TIMER_REPEAT); //Start unpause countdown
	}
	else if (!g_bIsPaused) //Is not paused
	{
		g_bWasForced = true; //Pause was forced so only allow admins to unpause
		PrintToChatAll("\x03[Pause]\x01 The game has been paused by an Admin.");
		if (GetConVarBool(g_hPauseAlltalk))
		{
			EnablePausedAlltalk(); //Enable alltalk
		}
		CreateTimer(1.0, TimerPause, client);
	}
	return Plugin_Handled;
}

public Action:TimerPause(Handle:timer, any:client)
{
	Pause(client);
}

public Action:UnpauseCountdown(Handle:timer, any:client)
{
	if (!g_bIsUnpausing) //Server was repaused/unpaused before the countdown finished
	{
		return Plugin_Stop;
	}
	static iCountdown = 5;
	if(iCountdown == 0) //Resume game when countdown hits 0
	{
		PrintHintTextToAll("\x03[Pause]\x01 Game is Live!");
		Unpause(client);
		iCountdown = 5;
		return Plugin_Stop;
	}
	else if (iCountdown == 5) //Start of countdown
	{
		PrintToChatAll("\x03[Pause]\x01 Game will resume in \x04%d\x01...", iCountdown);
		iCountdown--;
		return Plugin_Continue;
	}
	else //Countdown progress
	{
		PrintToChatAll("\x03[Pause]\x01 \x04%d\x01...", iCountdown);
		iCountdown--;
		return Plugin_Continue;
	}
}

public Action:PauseRequestTimeout(Handle:timer, any:team)
{
	if (g_bIsPaused) //Game was paused so do nothing
	{
		return;
	}
	else if (!g_bPauseRequest[0] && !g_bPauseRequest[1]) //Neither team has an active pause request so do nothing. Caused when the game is paused for only a short duration
	{
		return;
	}
	else
	{
		if (team == L4D_TEAM_SURVIVOR)
		{
			PrintToChatAll("\x03[Pause]\x01 The Survivors' pause request has expired.");
		}
		else if (team == L4D_TEAM_INFECTED)
		{
			PrintToChatAll("\x03[Pause]\x01 The Infected's pause request has expired.");
		}
		ResetPauseRequest(); //Reset the pause requests
	}
}

Pause(any:client)
{
	if (GetConVarBool(g_hPauseAlltalk))
	{
		g_fFloodValue = GetConVarFloat( g_hFloodTime ); //Store the current flood value
		SetConVarFloat( g_hFloodTime, 0.01 ); // change it to a tiny number
	}
	ResetPauseRequest(); //Reset all pause requests since we are now pausing the game
	g_bAllowPause = true; //Allow the next setpause command to go through
	SetConVarInt(g_hPausable, 1); //Ensure sv_pausable is set to 1
	FakeClientCommand(client, "setpause"); //Send pause command
	SetConVarInt(g_hPausable, 0); //Rest sv_pausable back to 0
}

Unpause(any:client)
{
	if (GetConVarBool(g_hPauseFlood))
	{
		SetConVarFloat( g_hFloodTime, g_fFloodValue ); //change flooding back to original value
	}
	ResetPauseRequest(); //Reset all pause requests since we are now pausing the game
	g_bAllowUnpause = true; //Allow the next unpause command to go through
	SetConVarInt(g_hPausable, 1); //Ensure sv_pausable is set to 1
	FakeClientCommand(client, "unpause"); //Send unpause command
	SetConVarInt(g_hPausable, 0); //Rest sv_pausable back to 0
}

ResetPauseRequest()
{
	g_bPauseRequest[0] = false; //Survivors request
	g_bPauseRequest[1] = false; //Infected request
}

bool:IsCoop()
{
	decl String:sGamemode[64];
	GetConVarString(g_hGamemode, sGamemode, 64);
	// added bleed out - mutation3, and vip gnome - mutation9
	if (StrEqual(sGamemode, "coop") || StrEqual(sGamemode, "realism") || StrEqual(sGamemode, "survival") || StrEqual(sGamemode, "mutation3") || StrEqual(sGamemode, "mutation9")) //Check if it is a coop game
	{
		return true; //Is coop
	}
	return false; //Is not coop
}

EnablePausedAlltalk()
{
	if (IsCoop())
	{
		return; //No need for alltalk in coop
	}
	
	new Flags = GetConVarFlags(g_hAlltalk); //Save current flags
	SetConVarFlags(g_hAlltalk, (Flags & ~FCVAR_NOTIFY)); //Remove notify flag
	SetConVarInt(g_hAlltalk, 1); //Enable alltalk
	SetConVarFlags(g_hAlltalk, Flags); //Restore flags
	PrintToChatAll("\x03[Pause]\x01 Paused Game Alltalk \x04Enabled\x01.");
}

DisablePausedAlltalk()
{
	if (IsCoop())
	{
		return; //No need for alltalk in coop
	}
	
	new Flags = GetConVarFlags(g_hAlltalk); //Save current flags
	SetConVarFlags(g_hAlltalk, (Flags & ~FCVAR_NOTIFY)); //Remove notify flag
	SetConVarInt(g_hAlltalk, 0); //Disable alltalk
	SetConVarFlags(g_hAlltalk, Flags); //Restore flags
	if (g_bIsPaused) //Only show this if alltalk was actually on
	{
		PrintToChatAll("\x03[Pause]\x01 Paused Game Alltalk \x04Disabled\x01.");
	}
}

public OnClientDisconnect(client)
{
	if(g_bIsPaused && !g_bIsUnpausing && !IsFakeClient(client))
    {
		decl InGameClient;
		Unpause(client);
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(client) && !IsFakeClient(client))
			{
				InGameClient = i;
				break;
			}
		}
		CreateTimer(1.0, TimerPause, InGameClient);
    }
}

public OnClientPutInServer(client)
{
    if (g_bIsPaused && !g_bIsUnpausing && !IsFakeClient(client))
    {
        Unpause(client);
        CreateTimer(1.0, TimerPause, client);
    }
}

public OnClientConnected(client)
{
    if (g_bIsPaused && !g_bIsUnpausing && !IsFakeClient(client))
    {
        Unpause(client);
        CreateTimer(1.0, TimerPause, client);
    }
}

public Action:Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bIsPaused && !g_bIsUnpausing && !IsFakeClient(client))
    {
        Unpause(client);
        CreateTimer(1.0, TimerPause, client);
    }	
}
