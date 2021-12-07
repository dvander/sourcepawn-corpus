#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>

#define SPECWHO_VERSION "1.1"
#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5

bool bSpecWhoDisabled[MAXPLAYERS+1] = true;

char TargetSteam32[MAXPLAYERS+1][255];
int iSpecTarget[MAXPLAYERS+1];

Handle SpecWhoHudTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle gRememberCookie = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "SpecWho",
	author = "SomePanns",
	description = "Displays detailed information about who you are spectating.",
	version = "1.1",
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_specwho_version", Command_SpecWho_version, "Displays the current version of the SpecWho plugin.");
	RegConsoleCmd("sm_specwho", Command_SpecWho_Toggle, "Toggle the SpecWho menu on/off for yourself.");

	gRememberCookie = RegClientCookie("specwho_cookie_panel_disabled", "SpecWho Cookie", CookieAccess_Protected); // 1 to disable, 0 to enable

	for (int i = MaxClients; i > 0; --i)
    {
        if (!AreClientCookiesCached(i))
        {
            continue;
		}

		OnClientCookiesCached(i);
	}
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, gRememberCookie, sValue, sizeof(sValue));

	bSpecWhoDisabled[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public void OnClientPostAdminCheck(int client)
{
	OnClientCookiesCached(client);
	SpawnHudTimer(client);
}

public void OnClientDisconnect(int client)
{
	KillTimerSafe(SpecWhoHudTimer[client]);
}

void SpawnHudTimer(int client)
{
	SpecWhoHudTimer[client] = CreateTimer(1.0, Timer_SpecWhoHud, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Command_SpecWho_version(int client, int args)
{
	ReplyToCommand(client, "\x04[SpecWho]\x05 This server is currently running version \x04%s", SPECWHO_VERSION);
}

public Action Command_SpecWho_Toggle(int client, int args)
{
	if(!bSpecWhoDisabled[client])
	{
		SetClientCookie(client, gRememberCookie, "1");
		KillTimerSafe(SpecWhoHudTimer[client]);
		ReplyToCommand(client, "\x04[SpecWho]\x05 You have disabled SpecWho for yourself.");
		OnClientCookiesCached(client);
	}
	else if(bSpecWhoDisabled[client])
	{
		SetClientCookie(client, gRememberCookie, "0");
		SpecWhoHudTimer[client] = CreateTimer(1.0, Timer_SpecWhoHud, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		ReplyToCommand(client, "\x04[SpecWho]\x05 You have enabled SpecWho for yourself.");
		OnClientCookiesCached(client);
	}
}

char GetServerIP()
{
	int pieces[4];
	int longip = GetConVarInt(FindConVar("hostip"));
	int port = GetConVarInt(FindConVar("hostport"));
	char NetIP[255];

	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;

	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d:%i", pieces[0], pieces[1], pieces[2], pieces[3], port);

	return NetIP;
}

public Action Timer_SpecWhoHud(Handle timer, int client)
{
	if(!bSpecWhoDisabled[client])
	{
		if (!IsClientInGame(client) || !IsClientObserver(client))
		{
			return Plugin_Continue;
		}

		int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");

		if (iObserverMode != SPECMODE_FIRSTPERSON && iObserverMode != SPECMODE_3RDPERSON)
		{
			return Plugin_Continue;
		}

		iSpecTarget[client] = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

		if(!IsValidClient(iSpecTarget[client]))
		{
			return Plugin_Continue;
		}

		GetClientAuthId(iSpecTarget[client], AuthId_Steam2, TargetSteam32[iSpecTarget[client]], sizeof(TargetSteam32)); // 32-bit

		Panel panel = new Panel();
		char PhrasePanelTitle[255];
		char PhraseID32[255];
		char PhraseServerIP[255];
		char PhraseYourName[255];

		Format(PhrasePanelTitle, sizeof(PhrasePanelTitle), "Spectating user: %N", iSpecTarget[client]);
		Format(PhraseYourName, sizeof(PhraseYourName), "Your name: %N", client);
		Format(PhraseServerIP, sizeof(PhraseServerIP), "Server IP: %s", GetServerIP());
		Format(PhraseID32, sizeof(PhraseID32), "SteamID32 of %N: %s", iSpecTarget[client], TargetSteam32[iSpecTarget[client]]);

		panel.SetTitle(PhrasePanelTitle);
		panel.DrawText(PhraseYourName);
		panel.DrawText(PhraseServerIP);
		panel.DrawText(PhraseID32);

		if(!IsFakeClient(iSpecTarget[client])) {
			char PhraseTargetConTime[255];
			Format(PhraseTargetConTime, sizeof(PhraseTargetConTime), "%N Connection time: %f seconds", iSpecTarget[client], GetClientTime(iSpecTarget[client]));
			panel.DrawText(PhraseTargetConTime);
		}

		panel.DrawItem("Print SteamID32 to chat");

		panel.Send(client, PanelHandler1, 1);

		delete panel;
	}
	else
	{
		KillTimerSafe(SpecWhoHudTimer[client]);
	}

	return Plugin_Changed;
}

public int PanelHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			iSpecTarget[param1] = GetEntPropEnt(param1, Prop_Send, "m_hObserverTarget");

			if(!IsValidClient(iSpecTarget[param1]))
			{
				return;
			}

			PrintToChat(param1, "\x04[SpecWho]\x05 SteamID32 of %N is %s", iSpecTarget[param1], TargetSteam32[iSpecTarget[param1]]);
		}
	}

	return;
}

stock bool IsValidClient(int client, bool isAlive=false)
{
    if(!client||client>MaxClients)    return false;
    if(isAlive) return IsClientInGame(client) && IsPlayerAlive(client);
    return IsClientInGame(client);
}

public void KillTimerSafe(Handle &hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}
