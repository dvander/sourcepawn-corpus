#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 		5
#define SPECMODE_FREELOOK	 		6

#define UPDATE_INTERVAL 2.5

Handle HudHintTimers[MAXPLAYERS + 1];
bool speclist_stealth[MAXPLAYERS + 1];
bool speclist_enabled[MAXPLAYERS + 1];
Handle g_cEnabled = null;

public Plugin myinfo = 
{
	name = "SpecList/Fix", 
	author = "cra88y/Timid", 
	version = "7.0", 
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_speclist", Command_SpecList);
	RegAdminCmd("sm_stealth", Command_Stealth, ADMFLAG_ROOT);
	
	g_cEnabled = RegClientCookie("Speclist_Enabled", "Speclist on or off", CookieAccess_Protected);
	
	HookEvent("player_spawn", Event_Player_Spawn);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsValidClient(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}
public void OnClientPostAdminCheck(int client)
{
	CreateHudHintTimer(client);
	speclist_enabled[client] = true;
	speclist_stealth[client] = false;
}

public void OnClientDisconnect(int client)
{
	if (IsClientInGame(client))
		KillHudHintTimer(client);
}
public void OnClientCookiesCached(int client)
{
	char CookieEnabled[16];
	GetClientCookie(client, g_cEnabled, CookieEnabled, sizeof(CookieEnabled));
	speclist_enabled[client] = CookieEnabled[0] == '\0' ? true : view_as<bool>(StringToInt(CookieEnabled));
	if (!speclist_enabled[client])
	{
		KillHudHintTimer(client);
	}
	/*if (g_iSpecEnabled[client] == 1)
	{
		speclist_enabled[client] = true;
	}
	else
	{
		speclist_enabled[client] = false;
		KillHudHintTimer(client);
	}*/
}
public Action Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsValidClient(client) && !AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
}
public Action Command_Stealth(int client, int args)
{
	speclist_stealth[client] = !speclist_stealth[client];
	
	if (speclist_stealth[client] == true)
		ReplyToCommand(client, "\x01[\x02SpecList\x01] You will now be hidden from speclist.");
	
	if (speclist_stealth[client] == false)
		ReplyToCommand(client, "\x01[\x02SpecList\x01] You will now be shown on speclist.");
	
}
public Action Command_SpecList(int client, int args)
{
	if (speclist_enabled[client] == true)
	{
		speclist_enabled[client] = false;
		KillHudHintTimer(client);
		ReplyToCommand(client, "\x01[\x02SpecList\x01] Spectator list disabled.");
		SetClientCookie(client, g_cEnabled, "0");
	}
	else if (speclist_enabled[client] == false)
	{
		speclist_enabled[client] = true;
		CreateHudHintTimer(client);
		ReplyToCommand(client, "\x01[\x02SpecList\x01] Spectator list enabled.");
		SetClientCookie(client, g_cEnabled, "1");
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
	
	if (IsPlayerAlive(client))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsClientObserver(i))
				continue;
			
			
			iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
				continue;
			
			iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			if (speclist_stealth[i] == true)
				continue;
			
			if (iTarget == client)
			{
				if (IsPlayerVip(i) == true && speclist_stealth[i] == false)
				{
					if (IsPlayerAdmin(i) == true)
					{
						Format(szText, sizeof(szText), "%s %N.", szText, i);
					}
					else
					{
						Format(szText, sizeof(szText), "%s %N.", szText, i);
					}
				}
				else
				{
					Format(szText, sizeof(szText), "%s %N.", szText, i);
				}
				bDisplayHint = true;
			}
		}
	}
	else if (iSpecModeUser == SPECMODE_FIRSTPERSON || iSpecModeUser == SPECMODE_3RDPERSON)
	{
		iTargetUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || !IsClientObserver(i))
				continue;
			
			
			iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
			
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
				continue;
			iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
			
			if (speclist_stealth[i] == true)
				continue;
			
			if (iTarget == iTargetUser)
			{
				if (IsPlayerVip(i) == true)
				{
					if (IsPlayerAdmin(i) == true)
					{
						Format(szText, sizeof(szText), "%s %N.", szText, i);
					}
					else
					{
						Format(szText, sizeof(szText), "%s %N.", szText, i);
					}
				}
				else
				{
					Format(szText, sizeof(szText), "%s %N. ", szText, i);
				}
				bDisplayHint = true;
			}
		}
		
	}
	if (bDisplayHint)
	{
		if (speclist_enabled[client] == true)
		{
			PrintHintText(client, "%s", szText);
			bDisplayHint = false;
		}
	}
	
	return Plugin_Continue;
}
void CreateHudHintTimer(int client)
{
	HudHintTimers[client] = CreateTimer(UPDATE_INTERVAL, Timer_UpdateHudHint, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
	if (IsClientInGame(client) && CheckCommandAccess(client, "", ADMFLAG_UNBAN))
		return true;
	
	return false;
}
bool IsPlayerVip(int client)
{
	if (IsClientInGame(client) && CheckCommandAccess(client, "", ADMFLAG_CUSTOM1))
		return true;
	
	return false;
}
stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
} 