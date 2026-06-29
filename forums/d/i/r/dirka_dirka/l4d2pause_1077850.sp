///////////////////////////////////////////////////////////////////////////
//                                                                       //
// -Plugin:      L4D2 Pause                                              //
// -Game:        Left 4 Dead 2                                           //
// -Author:      Lee "pvtschlag" Silvey                                  //
// -Version:     0.2.1                                                   //
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
///////////////////////////////////////////////////////////////////////////

#include <sourcemod>

#define PLUGIN_VERSION "0.2.2"

new Handle:g_hPauseTimeout;
new Handle:g_hPauseAlltalk;
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
/* Added by Me */
new Handle:g_hPaused;

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
	g_hForceOnly = CreateConVar("l4d2pause_forceonly", "0", "Only allow the game to be paused by the forcepause command(Admin only).", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2pause"); //Create and/or load the plugin config

	/* Added by me */
	g_hPaused = CreateConVar("l4d2pause_enabled", "0", "Game is paused (for other plugins to detect).", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	CreateConVar("l4d2pause_version", PLUGIN_VERSION, "L4D2 Pause Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD||FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hGamemode = FindConVar("mp_gamemode");
	g_hPausable = FindConVar("sv_pausable");
	g_hAlltalk = FindConVar("sv_alltalk");
	
	SetConVarInt(g_hPausable, 0);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	RegConsoleCmd("pause", Command_Pause);
	RegConsoleCmd("setpause", Command_Setpause);
	RegConsoleCmd("unpause", Command_Unpause);
	RegConsoleCmd("sm_pause", Command_SMPause, "Pauses the game");
	RegConsoleCmd("sm_unpause", Command_SMUnpause, "Unpauses the game");
	
	RegAdminCmd("sm_forcepause", Command_SMForcePause, ADMFLAG_BAN, "Forces the game to pause/unpause");
}

public OnMapEnd()
{
	ResetPauseRequest(); //Reset any pause requests
	if (GetConVarBool(g_hPauseAlltalk))
	{
		DisablePausedAlltalk(); //Disable alltalk incase the map somehow ended while the game was paused
		/* Added by me */
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
		if (iTeam == 3)
		{
			sTeamName = "Infected";
		}
		else if (iTeam == 2)
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
		/* Added by me */
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
		/* Added by me */
		SetConVarInt(g_hPaused, 0);
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action:Command_SMPause(client, args)
{
	if (GetConVarBool(g_hForceOnly))
	{
		ReplyToCommand(client, "[SM] Only an admin can pause the game using !forcepause.");
		return Plugin_Handled;
	}
	
	if (IsCoop()) //If it is a coop game only allow admins to pause since there is only one team
	{
		ReplyToCommand(client, "[SM] Only an admin can pause the game in coop mode by using !forcepause.");
		return Plugin_Handled;
	}

	if (g_bIsPaused) //Already paused, tell them how to unpause
	{
		ReplyToCommand(client, "[SM] Game is already paused. Use !unpause to resume the game.");
		return Plugin_Handled;
	}
	
	new iTeam = GetClientTeam(client);
	if (iTeam != 2 && iTeam != 3) //Not on survior or infected team so ignore them
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
		PrintToChatAll("[SM] Both teams have agreed to pause the game. Use !unpause to resume the game.");
		Pause(client);
	}
	else if (g_bPauseRequest[0] && !g_bPauseRequest[1]) //Notify infected that the survirors want to pause
	{
		PrintToChatAll("[SM] The Survivors want to pause the game. An Infected can accept the request with the !pause command.");
		new Float:fTime = GetConVarFloat(g_hPauseTimeout);
		if (fTime > 0)
		{
			CreateTimer(fTime, PauseRequestTimeout, 2);
		}
	}
	else if (g_bPauseRequest[1] && !g_bPauseRequest[0]) //Notify survivors that the infected want to pause
	{
		PrintToChatAll("[SM] The Infected want to pause the game. A Survivor can accept the request the !pause command.");
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
		ReplyToCommand(client, "[SM] The game was paused by an admin and can only be unpaused with !forcepause.");
		return Plugin_Handled;
	}
	if (g_bIsPaused && !g_bIsUnpausing) //Is paused and not currently unpausing
	{
		if (iTeam == 2) //Surviors unpaused
		{
			PrintToChatAll("[SM] The game has been unpaused by the Survivors.");
		}
		else if (iTeam == 3) //Infected unpaused
		{
			PrintToChatAll("[SM] The game has bee unpaused by the Infected.");
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
		PrintToChatAll("[SM] The game has been unpaused by an admin.");
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
		PrintToChatAll("[SM] The game has been paused by an admin.");
		Pause(client);
	}
	return Plugin_Handled;
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
		PrintHintTextToAll("Game is Live!");
		Unpause(client);
		iCountdown = 5;
		return Plugin_Stop;
	}
	else if (iCountdown == 5) //Start of countdown
	{
		PrintToChatAll("Game will resume in %d...", iCountdown);
		iCountdown--;
		return Plugin_Continue;
	}
	else //Countdown progress
	{
		PrintToChatAll("%d...", iCountdown);
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
		if (team == 2)
		{
			PrintToChatAll("The Survivors' pause request has expired.");
		}
		else if (team == 3)
		{
			PrintToChatAll("The Infected's pause request has expired.");
		}
		ResetPauseRequest(); //Reset the pause requests
	}
}

Pause(any:client)
{
	ResetPauseRequest(); //Reset all pause requests since we are now pausing the game
	g_bAllowPause = true; //Allow the next setpause command to go through
	SetConVarInt(g_hPausable, 1); //Ensure sv_pausable is set to 1
	FakeClientCommand(client, "setpause"); //Send pause command
	SetConVarInt(g_hPausable, 0); //Rest sv_pausable back to 0
	if (GetConVarBool(g_hPauseAlltalk))
	{
		EnablePausedAlltalk(); //Enable alltalk
	}
}

Unpause(any:client)
{
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
	if (StrEqual(sGamemode, "coop") || StrEqual(sGamemode, "realism") || StrEqual(sGamemode, "survival")) //Check if it is a coop game
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
	PrintToChatAll("[SM] Paused Game Alltalk \x04Enabled");
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
		PrintToChatAll("[SM] Paused Game Alltalk \x04Disabled");
	}
}