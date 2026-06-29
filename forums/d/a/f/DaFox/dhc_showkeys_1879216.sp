#include <sourcemod>
#include <cstrike>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1a"

#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5
#define SPECMODE_FREELOOK	 		6

#define UPDATE_DISABLED 0
#define UPDATE_ONGAMEFRAME 1
#define UPDATE_TIMER 2

new g_iButtonsPressed[MAXPLAYERS+1] = {0,...};
new g_iJumps[MAXPLAYERS+1] = {0,...};

new bool:g_bShowKeys[MAXPLAYERS+1] = {true,...};

new Handle:g_hUpdateKeyDisplay = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "DHC | Show Keys",
	author = "Zipcore | Credits: GoD-Tony [Speclist] & Peace-Maker[ShowKeys]",
	description = "Shows the keys a player presses",
	version = PLUGIN_VERSION,
	url = "zipcore#googlemail.com"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_showkeys_version", PLUGIN_VERSION, "Show Keys version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(hVersion, PLUGIN_VERSION);
	
	RegConsoleCmd("keys", Cmd_ShowKeys, "Toggle showing your own pressed keys.");
	
	HookEvent("player_jump", Event_PlayerJump);
	
	HookEvent("player_death", Event_ResetJumps);
	HookEvent("player_team", Event_ResetJumps);
	HookEvent("player_spawn", Event_ResetJumps);
	HookEvent("player_disconnect", Event_ResetJumps);
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_iJumps[client]++;

	return Plugin_Continue;
}

public Action:Event_ResetJumps(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_iJumps[client] = 0;
	
	return Plugin_Continue;
}

public OnMapStart()
{
	g_hUpdateKeyDisplay = CreateTimer(0.1, Timer_UpdateKeyDisplay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public OnMapEnd()
{
	if(g_hUpdateKeyDisplay != INVALID_HANDLE)
	{
		KillTimer(g_hUpdateKeyDisplay);
		g_hUpdateKeyDisplay = INVALID_HANDLE;
	}
}

public OnClientDisconnect(client)
{
	g_iButtonsPressed[client] = 0;
	g_bShowKeys[client] = true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	g_iButtonsPressed[client] = buttons;
}

public Action:Cmd_ShowKeys(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Showkeys > You have to be ingame to use this command.");
		return Plugin_Handled;
	}
	
	if(g_bShowKeys[client])
	{
		g_bShowKeys[client] = false;
		PrintToChat(client, "\x04Showkeys \x01> \x03Stopped showing pressed keys.");
	}
	else
	{
		g_bShowKeys[client] = true;
		PrintToChat(client, "\x04Showkeys \x01> \x03Showing pressed keys.");
	}
	
	return Plugin_Handled;
}

public Action:Timer_UpdateKeyDisplay(Handle:timer, any:data)
{
	UpdateKeyDisplay();
	return Plugin_Continue;
}

UpdateKeyDisplay()
{
	new iClientToShow, iButtons, iObserverMode;
	
	for(new i=1;i<=MaxClients;i++)
	{
		decl String:sOutput[256];
		sOutput[0] = '\0';
		
		if(IsClientInGame(i) && g_bShowKeys[i])
		{
			// Show own buttons by default
			iClientToShow = i;
			
			// Get target he's spectating
			if(g_bShowKeys[i] && (!IsPlayerAlive(i) || IsClientObserver(i)))
			{
				iObserverMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				if(iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
				{
					iClientToShow = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
					
					// Check client index
					if(iClientToShow <= 0 || iClientToShow > MaxClients)
						continue;
				}
				else
				{
					continue; // don't proceed, if in freelook..
				}
			}
			decl String:auth[32];
			decl String:client_tag[32];
			GetClientAuthString(iClientToShow, auth, sizeof(auth));
			CS_GetClientClanTag(iClientToShow, client_tag, sizeof(client_tag));
			Format(sOutput, sizeof(sOutput), "%sSteamID: %s\n", sOutput, auth);
			Format(sOutput, sizeof(sOutput), "%sName: %N\n", sOutput, iClientToShow);
			Format(sOutput, sizeof(sOutput), "%sClantag: %s\n", sOutput, client_tag);
			Format(sOutput, sizeof(sOutput), "%sJumps: %d\n", sOutput, g_iJumps[iClientToShow]);
			
			iButtons = g_iButtonsPressed[iClientToShow];
			
			Format(sOutput, sizeof(sOutput), "%s___________Keys___________\n\n", sOutput);
			
			// Is he pressing "w"?
			if(iButtons & IN_FORWARD)
				Format(sOutput, sizeof(sOutput), "%sW;", sOutput);
			// Is he pressing "a"?
			if(iButtons & IN_MOVELEFT)
				Format(sOutput, sizeof(sOutput), "%sA;", sOutput);
			// Is he pressing "s"?
			if(iButtons & IN_BACK)
				Format(sOutput, sizeof(sOutput), "%sS;", sOutput);
			// Is he pressing "d"?
			if(iButtons & IN_MOVERIGHT)
				Format(sOutput, sizeof(sOutput), "%sD;", sOutput);
			
			// Is he pressing "space"?
			if(iButtons & IN_JUMP)
				Format(sOutput, sizeof(sOutput), "%sJUMP;", sOutput);
			
			// Is he pressing "ctrl"?
			if(iButtons & IN_DUCK)
				Format(sOutput, sizeof(sOutput), "%sDUCK;", sOutput);
				
			// Is he pressing "shift"?
			if(iButtons & IN_SPEED)
				Format(sOutput, sizeof(sOutput), "%sWALK;", sOutput);
				
			// Is he pressing "e"?
			if(iButtons & IN_USE)
				Format(sOutput, sizeof(sOutput), "%sUSE;", sOutput);
			
			// Is he pressing "tab"?
			if(iButtons & IN_SCORE)
				Format(sOutput, sizeof(sOutput), "%sSCORE;", sOutput);
				
			// Is he pressing "mouse1"?
			if(iButtons & IN_ATTACK)
				Format(sOutput, sizeof(sOutput), "%sMOUSE1;", sOutput);
			
			// Is he pressing "mouse1"?
			if(iButtons & IN_ATTACK2)
				Format(sOutput, sizeof(sOutput), "%sMOUSE2;", sOutput);
				
			
			Format(sOutput, sizeof(sOutput), "%s\n__________________________\n", sOutput);
			
			if (iClientToShow == i)
			{
				Format(sOutput, sizeof(sOutput), "%s\nSpectator List:\n", sOutput);
				for(new j = 1; j <= MaxClients; j++) 
				{
					if (!IsClientInGame(j) || !IsClientObserver(j))
						continue;
						
					new iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");
					
					// The client isn't spectating any one person, so ignore them.
					if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
						continue;
					
					// Find out who the client is spectating.
					new iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");
					
					// Are they spectating our player?
					if (iTarget == i)
					{
						Format(sOutput, sizeof(sOutput), "%s%N\n", sOutput, j);
					}
				}
			}
			else if (iObserverMode == SPECMODE_FIRSTPERSON || iObserverMode == SPECMODE_3RDPERSON)
			{
				// Find out who the User is spectating.
				new iTargetUser = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
				
				if (iTargetUser > 0)
					Format(sOutput, sizeof(sOutput), "%s\nSpectating %N:\n", sOutput, iTargetUser);
				
				for(new j = 1; j <= MaxClients; j++) 
				{
					if (!IsClientInGame(j) || !IsClientObserver(j))
						continue;
						
					new iSpecMode = GetEntProp(j, Prop_Send, "m_iObserverMode");
					
					// The client isn't spectating any one person, so ignore them.
					if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
						continue;
					
					// Find out who the client is spectating.
					new iTarget = GetEntPropEnt(j, Prop_Send, "m_hObserverTarget");
					
					// Are they spectating the same player as User?
					if (iTarget == iTargetUser)
						Format(sOutput, sizeof(sOutput), "%s%N\n", sOutput, j);
				}
			}
			
			PrintHintText(i, sOutput);
		}
	}
}