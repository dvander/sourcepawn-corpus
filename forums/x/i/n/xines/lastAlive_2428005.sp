#include <sourcemod>
#include <cstrike>
#include <clientprefs>

#define CLIENTPREFS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "RegClientCookie") == FeatureStatus_Available)

Handle cookiePref;
int last_alive[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Show last alive on HUD",
	author = "Sidezz, Xines",
	description = "",
	version = "1.0",
	url = "http://www.coldcommunity.com"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_alive", Command_lastAliveToggle, "Toggle display of the last alive HUD");
	
	for (int i = 1; i <= MaxClients; i++) //for reload to work
	{
		if (IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client)) //No cookie for you bot lol.
	{
		if (CLIENTPREFS_AVAILABLE())
		{
			load_CookiesFor(client);
		}
		CreateTimer(1.0, hudTick, client, TIMER_REPEAT);
	}
}

public void OnConfigsExecuted()
{
	if (cookiePref == INVALID_HANDLE && CLIENTPREFS_AVAILABLE())
	{
		cookiePref = RegClientCookie("Last Alive", "Last Alive", CookieAccess_Private);
		SetCookieMenuItem(PrefSelected, 0, "Last Alive");
	}
}

public void OnClientCookiesCached(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		load_CookiesFor(client);
	}
}

void load_CookiesFor(int client)
{
	if (cookiePref == INVALID_HANDLE || !AreClientCookiesCached(client))
	{
		last_alive[client] = 1;
		return;
	}
	
	decl String:buffer[5];
	GetClientCookie(client, cookiePref, buffer, sizeof(buffer));
	
	if (buffer[0])
	{
		last_alive[client] = StringToInt(buffer);
	}
	else
	{
		last_alive[client] = 1;
	}
}

public void PrefSelected(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (!CLIENTPREFS_AVAILABLE())
	{
		return;
	}
	
	switch (action)
	{
		case CookieMenuAction_DisplayOption :
		{
		}
		case CookieMenuAction_SelectOption :
		{
			switch (last_alive[client])
			{
				case 0 :
				{
					last_alive[client] = 1;
				}
				default :
				{
					last_alive[client] = 0;
				}
			}
			ShowCookieMenu(client);
		}
	}
}

public Action Command_lastAliveToggle(int client, int args)
{
	if(client == 0 && !IsClientInGame(client)) return Plugin_Continue;

	switch (last_alive[client])
	{
		case 0 :
		{
			last_alive[client] = 1;
			PrintToChat(client, "\x01\x0B\x04[\x01SM\x04] Last Alive HUD has been disabled");
		}
		default :
		{
			last_alive[client] = 0;
			PrintToChat(client, "\x01\x0B\x04[\x01SM\x04] Last Alive HUD has been enabled");
		}
	}
	
	if (CLIENTPREFS_AVAILABLE())
	{
		decl String:buffer[5];
		
		IntToString(last_alive[client], buffer, sizeof(buffer));
		SetClientCookie(client, cookiePref, buffer);
	}
	
	return Plugin_Handled;
}

public Action hudTick(Handle timer, any client)
{
	if(!IsClientInGame(client))
	{
		KillTimer(timer);
		return Plugin_Handled;
	}

	if(last_alive[client])
		return Plugin_Continue;
	
	char text[512], tAlive, ctAlive;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch(GetClientTeam(i))
			{
				case CS_TEAM_CT: ctAlive++;
				case CS_TEAM_T: tAlive++;
			}
		}
	}
	
	if(tAlive > 1)
	{
		Format(text, sizeof(text), "Terrorists Alive: %i", tAlive);
	}
	else if(tAlive == 1)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				Format(text, sizeof(text), "Last Terrorist: %N", i);
			}
		}
	}

	if(ctAlive > 1)
	{
		Format(text, sizeof(text), "%s\nCounter-Terrorists Alive: %i", text, ctAlive);
	}
	else if(ctAlive == 1)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
			{
				Format(text, sizeof(text), "%s\nLast Counter-Terrorist: %N", text, i);
			}
		}
	}
	
	SetHudTextParams(-1.0, 0.865, 1.0, 255, 255, 255, 255, 0, 6.0, 0.1, 0.2);
	ShowHudText(client, -1, text);
	
	return Plugin_Handled;
}