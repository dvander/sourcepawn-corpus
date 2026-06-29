#include <sourcemod>
#include <cstrike> 
#include <sdktools>
#include <clientprefs>

// Timeleft by Fastmancz, all credits to him ( https://forums.alliedmods.net/showthread.php?t=309700 )
public Plugin myinfo = 
{
	name = "HUDv2",
	author = "xSLOW",
	description = "Better Hud",
	version = "1.0"
};

#define MESSAGE_1 "MESSAGE 1"                    // Top Left Message 1
#define MESSAGE_2 "MESSAGE 2"                    // Top Left Message 2
#define MESSAGE_3 "[ MESSAGE 3 ]"                // Top Mid Message
#define slots 32                                 // Number of your server slots
#define rgba 97, 252, 0, 255                     // Color of the text (default = green)

Handle g_HUDv2_Cookie;
bool g_IsHudEnabled;

public void OnPluginStart()
{
	g_HUDv2_Cookie = RegClientCookie("HudCookie_V2", "HudCookie_V2", CookieAccess_Protected);

	CreateTimer(1.0, TIMER, _, TIMER_REPEAT);
	RegConsoleCmd("hud", Command_hud);
}

public void OnClientPutInServer(client)
{
	char buffer[64];
	GetClientCookie(client, g_HUDv2_Cookie, buffer, sizeof(buffer));
	if(StrEqual(buffer,""))
	{
		g_IsHudEnabled = true;
	}
	else
	g_IsHudEnabled = false;
}


public Action Command_hud(client, args) 
{
	if(g_IsHudEnabled)
	{
		PrintToChat(client, " ★ \x02HUD is now off")
		g_IsHudEnabled = false;
		SetClientCookie(client, g_HUDv2_Cookie, "0");
	}
	else
	{
		PrintToChat(client, " ★ \x04HUD is now on")
		g_IsHudEnabled = true;
		SetClientCookie(client, g_HUDv2_Cookie, "1");
	}
	
}


public Action TIMER(Handle timer)
{
	int clientCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i))++clientCount;
	char sTime[60];
	int iTimeleft;

	char szTime[30];
	FormatTime(szTime, sizeof(szTime), "%H:%M:%S", GetTime());

	GetMapTimeLeft(iTimeleft);
	if(iTimeleft > 0)
	{
		FormatTime(sTime, sizeof(sTime), "%M:%S", iTimeleft);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && g_IsHudEnabled == true)
			{
				SetHudTextParams(0.0, 0.0, 1.0, rgba, 0, 0.1, 0.0, 0.0);  
				ShowHudText(i, -1, MESSAGE_1);  

				SetHudTextParams(0.0, 0.03, 1.0, rgba, 0, 0.1, 0.0, 0.0);  
				ShowHudText(i, -1, MESSAGE_2);  

				SetHudTextParams(-1.0, 0.075, 5.0, rgba, 0, 0.1, 0.0, 0.0);  
				ShowHudText(i, -1, MESSAGE_3);  

				char players[60];
				Format(players, sizeof(players), "Players: %d/%d", clientCount, slots);
				SetHudTextParams(0.0, 0.06, 1.0, rgba, 0, 0.00, 0.0, 0.0);
				ShowHudText(i, -1, players);

				char message[60];
				Format(message, sizeof(message), "Timeleft: %s", sTime);
				SetHudTextParams(0.0, 0.09, 1.0, rgba, 0, 0.00, 0.0, 0.0);
				ShowHudText(i, -1, message);

				char timp2[60];
				Format(timp2, sizeof(timp2), "Clock: %s", szTime);
				SetHudTextParams(0.0, 0.12, 1.0, rgba, 0, 0.00, 0.0, 0.0);
				ShowHudText(i, -1, timp2);
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsClientValid(int client)
{
    if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
        return true;
    return false;
}