
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5
#define SPECMODE_FREELOOK	 		6

#define UPDATE_INTERVAL 2.5
#define PLUGIN_VERSION "1.1.2ab"

Handle HudHintTimers[MAXPLAYERS+1];
Handle sm_speclist_enabled;
Handle sm_speclist_allowed;
Handle sm_speclist_adminonly;
Handle sm_speclist_noadmins;
bool g_Enabled;
bool g_AdminOnly;
bool g_NoAdmins;
 
public Plugin myinfo =
{
	name = "Spectator List",
	author = "GoD-Tony , csgo simple fix by Niko",
	description = "View who is spectating you in CS:GO",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
 
public void OnPluginStart()
{
	CreateConVar("sm_speclist_version", PLUGIN_VERSION, "Spectator List Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_speclist_enabled = CreateConVar("sm_speclist_enabled","1","Enables the spectator list for all players by default.");
	sm_speclist_allowed = CreateConVar("sm_speclist_allowed","1","Allows players to enable spectator list manually when disabled by default.");
	sm_speclist_adminonly = CreateConVar("sm_speclist_adminonly","0","Only admins can use the features of this plugin.");
	sm_speclist_noadmins = CreateConVar("sm_speclist_noadmins", "1","Don't show non-admins that admins are spectating them.");
	
	RegConsoleCmd("sm_speclist", Command_SpecList);
	
	HookConVarChange(sm_speclist_enabled, OnConVarChange);
	HookConVarChange(sm_speclist_adminonly, OnConVarChange);
	HookConVarChange(sm_speclist_noadmins, OnConVarChange);
	
	g_Enabled = GetConVarBool(sm_speclist_enabled);
	g_AdminOnly = GetConVarBool(sm_speclist_adminonly);
	g_NoAdmins = GetConVarBool(sm_speclist_noadmins);
	
	AutoExecConfig(true, "plugin.speclist");
}

public void OnConVarChange(Handle hCvar, const char[] oldValue, const char[] newValue)
{
	if (hCvar == sm_speclist_enabled)
	{
		g_Enabled = GetConVarBool(sm_speclist_enabled);
		
		if (g_Enabled)
		{
			// Enable timers on all players in game.
			for(int i = 1; i <= MaxClients; i++) 
			{
				if (!IsClientInGame(i))
					continue;
				
				CreateHudHintTimer(i);
			}
		}
		else
		{
			// Kill all of the active timers.
			for(int i = 1; i <= MaxClients; i++) 
				KillHudHintTimer(i);
		}
	}
	else if (hCvar == sm_speclist_adminonly)
	{
		g_AdminOnly = GetConVarBool(sm_speclist_adminonly);
		
		if (g_AdminOnly)
		{
			// Kill all of the active timers.
			for(int i = 1; i <= MaxClients; i++) 
				KillHudHintTimer(i);
				
			// Enable timers on all admins in game.
			for(int i = 1; i <= MaxClients; i++) 
			{
				if (!IsClientInGame(i))
					continue;
				
				CreateHudHintTimer(i);
			}
		}
	}
	else if (hCvar == sm_speclist_noadmins)
	{
		g_NoAdmins = GetConVarBool(sm_speclist_noadmins);
		
		if (g_NoAdmins)
		{
			// Kill all of the active timers.
			for(int i = 1; i <= MaxClients; i++) 
				KillHudHintTimer(i);
				
			// Enable timers on all admins in game.
			for(int  i = 1; i <= MaxClients; i++) 
			{
				if (!IsClientInGame(i))
					continue;
				
				CreateHudHintTimer(i);
			}
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (g_Enabled)
		CreateHudHintTimer(client);
}

public void OnClientDisconnect(int client)
{
	if(IsClientInGame(client))
		KillHudHintTimer(client);
}

// Using 'sm_speclist' to toggle the spectator list per player.
public Action Command_SpecList(int client, int args)
{
	if (HudHintTimers[client] != INVALID_HANDLE)
	{
		KillHudHintTimer(client);
		ReplyToCommand(client, "[SM] Spectator list disabled.");
	}
	else if (g_Enabled || GetConVarBool(sm_speclist_allowed))
	{
		CreateHudHintTimer(client);
		ReplyToCommand(client, "[SM] Spectator list enabled.");
	}
	
	return Plugin_Handled;
}


public Action Timer_UpdateHudHint(Handle timer, any client)
{
	int iSpecModeUser = GetEntProp(client, Prop_Send, "m_iObserverMode");
	int iSpecMode, iTarget, iTargetUser;
	bool bDisplayHint = false;
	
	char szText[2048];
	szText[0] = '\0';
	
	// Dealing with a client who is in the game and playing.
	if (IsPlayerAlive(client))
	{
		for(int i = 1; i <= MaxClients; i++) 
		{
			if (!IsClientInGame(i) || !IsClientObserver(i))
				continue;
			
			// The 'client' is not an admin and do not display admins is enabled and the client (i) is an admin, so ignore them.
			if(!IsPlayerAdmin(client) && (g_NoAdmins && IsPlayerAdmin(i)))
				continue;
				
			iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			
			// The client isn't spectating any one person, so ignore them.
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
				continue;
			
			// Find out who the client is spectating.
			iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			// Are they spectating our player?
			if (iTarget == client)
			{
				Format(szText, sizeof(szText), "%s%N\n", szText, i);
				bDisplayHint = true;
			}
		}
	}
	else if (iSpecModeUser == SPECMODE_FIRSTPERSON || iSpecModeUser == SPECMODE_3RDPERSON)
	{
		// Find out who the User is spectating.
		iTargetUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		
		if (iTargetUser > 0)
			Format(szText, sizeof(szText), "Spectating %N:\n", iTargetUser);
		
		for(int i = 1; i <= MaxClients; i++) 
		{			
			if (!IsClientInGame(i) || !IsClientObserver(i))
				continue;
			
			// The 'client' is not an admin and do not display admins is enabled and the client (i) is an admin, so ignore them.
			if(!IsPlayerAdmin(client) && (g_NoAdmins && IsPlayerAdmin(i)))
				continue;
				
			iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			
			// The client isn't spectating any one person, so ignore them.
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
				continue;
			
			// Find out who the client is spectating.
			iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			// Are they spectating the same player as User?
			if (iTarget == iTargetUser)
				Format(szText, sizeof(szText), "%s%N\n", szText, i);
		}
	}
	
	/* We do this to prevent displaying a message
		to a player if no one is spectating them anyway. */
	if (bDisplayHint)
	{
		Panel panel = new Panel();
		panel.DrawText(szText);
		panel.SetTitle("Users spectating you");
		//panel.CurrentKey(10);
		panel.Send(client,Handler_DoNothing,3);
		delete panel;
		bDisplayHint = false;
	}
	
	return Plugin_Continue;
}

public int Handler_DoNothing(Handle menu, MenuAction action, int param1, int param2)
{
	/* Do nothing */
}

void CreateHudHintTimer(int client)
{
	// If AdminOnly is enabled, make sure we only create timers on admins.
	//new AdminId:admin = GetUserAdmin(client);
	
	//if (!g_AdminOnly || (g_AdminOnly && GetAdminFlag(admin, Admin_Generic, Access_Effective)))
	if (!g_AdminOnly || (g_AdminOnly && IsPlayerAdmin(client)))
		HudHintTimers[client] = CreateTimer(UPDATE_INTERVAL, Timer_UpdateHudHint, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void KillHudHintTimer(int client)
{
	if (HudHintTimers[client] != INVALID_HANDLE)
	{
		KillTimer(HudHintTimers[client]);
		HudHintTimers[client] = INVALID_HANDLE;
	}
}

bool IsPlayerAdmin(int client)
{
	if(IsClientInGame(client) && CheckCommandAccess(client, "show_spectate", ADMFLAG_GENERIC))
		return true;
	
	return false;
}