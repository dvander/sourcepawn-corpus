#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5
#define SPECMODE_FREELOOK	 		6

#define UPDATE_DISABLED 0
#define UPDATE_ONGAMEFRAME 1
#define UPDATE_TIMER 2

new g_iButtonsPressed[MAXPLAYERS+1] = {0,...};

new bool:g_bShowOwnKeys[MAXPLAYERS+1] = {false,...};
new bool:g_bShowPlayerKeys[MAXPLAYERS+1] = {false,...};

new Handle:g_hCVUpdateMode;
new Handle:g_hCVUpdateRate;
new Handle:g_hCVFrameSkip;

new g_iUpdateMode;
new g_iFrameSkip;

new Handle:g_hUpdateKeyDisplay = INVALID_HANDLE;

new g_iCurrentFrame = 0;

public Plugin:myinfo = 
{
	name = "Show Keys",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Shows the keys a player presses",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_showkeys_version", PLUGIN_VERSION, "Show Keys version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVUpdateMode = CreateConVar("sm_showkeys_updatemode", "1", "How should we update the key display? 0: Disabled, 1: OnGameFrame (most accurate, high load with many players), 2: Repeated timer (less accurate, low load)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hCVUpdateRate = CreateConVar("sm_showkeys_updaterate", "0.1", "How often in seconds should we update the key display when using updatemode 2?", FCVAR_PLUGIN, true, 0.01, true, 1.0);
	g_hCVFrameSkip = CreateConVar("sm_showkeys_frameskip", "1", "Update the keys each x frames when using updatemode 1?", FCVAR_PLUGIN, true, 1.0);
	
	HookConVarChange(g_hCVUpdateMode, ConVarChanged_UpdateMode);
	HookConVarChange(g_hCVUpdateRate, ConVarChanged_UpdateRepeat);
	HookConVarChange(g_hCVFrameSkip, ConVarChanged_FrameSkip);
	
	RegConsoleCmd("showmykeys", Cmd_ShowMyKeys, "Toggle showing your own pressed keys.");
	RegConsoleCmd("showkeys", Cmd_ShowKeys, "Toggle showing your own pressed keys.");
}

public OnConfigsExecuted()
{
	g_iUpdateMode = GetConVarInt(g_hCVUpdateMode);
	g_iFrameSkip = GetConVarInt(g_hCVFrameSkip);
}

public OnMapStart()
{
	if(g_iUpdateMode != UPDATE_TIMER)
		return;
	
	g_hUpdateKeyDisplay = CreateTimer(GetConVarFloat(g_hCVUpdateRate), Timer_UpdateKeyDisplay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
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
	g_bShowOwnKeys[client] = false;
	g_bShowPlayerKeys[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	g_iButtonsPressed[client] = buttons;
}

public Action:Cmd_ShowMyKeys(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Showkeys > You have to be ingame to use this command.");
		return Plugin_Handled;
	}
	
	if(g_iUpdateMode == UPDATE_DISABLED)
	{
		g_bShowOwnKeys[client] = false;
		PrintToChat(client, "\x04Showkeys \x01> \x03Key showing is currently disabled.");
		return Plugin_Handled;
	}
	
	if(g_bShowOwnKeys[client])
	{
		g_bShowOwnKeys[client] = false;
		PrintToChat(client, "\x04Showkeys \x01> \x03Stopped showing your own pressed keys.");
	}
	else
	{
		g_bShowOwnKeys[client] = true;
		PrintToChat(client, "\x04Showkeys \x01> \x03Showing your own pressed keys.");
	}
	
	return Plugin_Handled;
}

public Action:Cmd_ShowKeys(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "Showkeys > You have to be ingame to use this command.");
		return Plugin_Handled;
	}
	
	if(g_iUpdateMode == UPDATE_DISABLED)
	{
		g_bShowPlayerKeys[client] = false;
		PrintToChat(client, "\x04Showkeys \x01> \x03Key showing is currently disabled.");
		return Plugin_Handled;
	}
	
	if(g_bShowPlayerKeys[client])
	{
		g_bShowPlayerKeys[client] = false;
		PrintToChat(client, "\x04Showkeys \x01> \x03Stopped showing target's pressed keys.");
	}
	else
	{
		g_bShowPlayerKeys[client] = true;
		PrintToChat(client, "\x04Showkeys \x01> \x03Showing target's pressed keys.");
	}
	
	return Plugin_Handled;
}

public ConVarChanged_UpdateMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iUpdateMode = StringToInt(newValue);
	
	if(StrEqual(oldValue, newValue))
		return;
	
	// Stop the currently running timer
	if(g_hUpdateKeyDisplay != INVALID_HANDLE)
	{
		KillTimer(g_hUpdateKeyDisplay);
		g_hUpdateKeyDisplay = INVALID_HANDLE;
	}
	
	if(g_iUpdateMode == UPDATE_TIMER)
	{
		// Start the timer
		g_hUpdateKeyDisplay = CreateTimer(GetConVarFloat(g_hCVUpdateRate), Timer_UpdateKeyDisplay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}

public ConVarChanged_UpdateRepeat(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(g_iUpdateMode != UPDATE_TIMER)
		return;
	
	// Stop the currently running timer
	if(g_hUpdateKeyDisplay != INVALID_HANDLE)
	{
		KillTimer(g_hUpdateKeyDisplay);
		g_hUpdateKeyDisplay = INVALID_HANDLE;
	}
	
	// Start the timer with changed interval
	g_hUpdateKeyDisplay = CreateTimer(GetConVarFloat(g_hCVUpdateRate), Timer_UpdateKeyDisplay, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public ConVarChanged_FrameSkip(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iFrameSkip = StringToInt(newValue);
}

public Action:Timer_UpdateKeyDisplay(Handle:timer, any:data)
{
	UpdateKeyDisplay();
	return Plugin_Continue;
}

public OnGameFrame()
{
	// Don't do anything, if not set so.
	if(g_iUpdateMode != UPDATE_ONGAMEFRAME)
		return;
	
	g_iCurrentFrame++;
	
	// Skip this frame
	if(g_iCurrentFrame < g_iFrameSkip)
		return;
	
	// Start again, when updating
	if(g_iCurrentFrame >= g_iFrameSkip)
		g_iCurrentFrame = 0;
	
	UpdateKeyDisplay();
}

UpdateKeyDisplay()
{
	new iClientToShow, iButtons, iObserverMode;
	decl String:sOutput[256];
	
	for(new i=1;i<=MaxClients;i++)
	{
		// Ignore that player, if he's not using this plugin at all
		if(!g_bShowOwnKeys[i] && !g_bShowPlayerKeys[i])
			continue;
		
		if(IsClientInGame(i) && 
		  ((g_bShowOwnKeys[i] && IsPlayerAlive(i)) ||
		  ((g_bShowPlayerKeys[i] &&  !IsPlayerAlive(i) || IsClientObserver(i) ))))
		{
			// Show own buttons by default
			iClientToShow = i;
			
			// Get target he's spectating
			if(g_bShowPlayerKeys[i] && (!IsPlayerAlive(i) || IsClientObserver(i)))
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
			
			
			iButtons = g_iButtonsPressed[iClientToShow];
			
			// Is he pressing "w"?
			if(iButtons & IN_FORWARD)
				Format(sOutput, sizeof(sOutput), "     W     ");
			else
				Format(sOutput, sizeof(sOutput), "     -     ");
			
			// Is he pressing "space"?
			if(iButtons & IN_JUMP)
				Format(sOutput, sizeof(sOutput), "%s     JUMP\n", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s     _   \n", sOutput);
			
			// Is he pressing "a"?
			if(iButtons & IN_MOVELEFT)
				Format(sOutput, sizeof(sOutput), "%s  A", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s  -", sOutput);
				
			// Is he pressing "s"?
			if(iButtons & IN_BACK)
				Format(sOutput, sizeof(sOutput), "%s  S", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s  -", sOutput);
				
			// Is he pressing "d"?
			if(iButtons & IN_MOVERIGHT)
				Format(sOutput, sizeof(sOutput), "%s  D", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s  -", sOutput);
			
			// Is he pressing "ctrl"?
			if(iButtons & IN_DUCK)
				Format(sOutput, sizeof(sOutput), "%s       DUCK\n", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s       _   \n", sOutput);
				
			// Is he pressing "shift"?
			if(iButtons & IN_SPEED)
				Format(sOutput, sizeof(sOutput), "%sWALK", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s_   ", sOutput);
				
			// Is he pressing "e"?
			if(iButtons & IN_USE)
				Format(sOutput, sizeof(sOutput), "%s    USE", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s    _  ", sOutput);
			
			// Is he pressing "tab"?
			if(iButtons & IN_SCORE)
				Format(sOutput, sizeof(sOutput), "%s    SCORE\n", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s    _    \n", sOutput);
				
			// Is he pressing "mouse1"?
			if(iButtons & IN_ATTACK)
				Format(sOutput, sizeof(sOutput), "%sMOUSE1", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s_     ", sOutput);
			
			// Is he pressing "mouse1"?
			if(iButtons & IN_ATTACK2)
				Format(sOutput, sizeof(sOutput), "%s  MOUSE2", sOutput);
			else
				Format(sOutput, sizeof(sOutput), "%s  _     ", sOutput);
			
			new Handle:hBuffer = StartMessageOne("KeyHintText", i);
			BfWriteByte(hBuffer, 1);
			BfWriteString(hBuffer, sOutput);
			EndMessage();
		}
	}
}