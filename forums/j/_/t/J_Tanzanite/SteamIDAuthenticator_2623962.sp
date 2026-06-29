#include <sourcemod>

static bool b_validated[MAXPLAYERS + 1];
static Handle h_enabled = INVALID_HANDLE;
static Handle h_notify = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "SteamID Authenticator",
	author = "TheLazyCWriter",
	description = "Blocks Non-Authenticated players from preforming any actions.",
	version = "1.2.0",
	url = ""
};

public OnPluginStart()
{
	CreateTimer(2.5, Timer_SIDVALIDATE, _, TIMER_REPEAT);

	h_enabled = CreateConVar("sidauth_enabled",
		"1",
		"Enables/Disables SteamID Authentication (non-authenticated players won't be able to do anything with this on). 1 = on, 0 = off.",
		FCVAR_PROTECTED,
		true, 0.0,
		true, 1.0);
	h_notify = CreateConVar("sidauth_notify",
		"1",
		"Notify players when they are getting/have been authenticated. 1 = notify in chat, 0 = don't notify (silent).",
		FCVAR_PROTECTED,
		true, 0.0,
		true, 1.0);
}

public OnClientPutInServer(client)
{
	b_validated[client] = false;

	if (GetConVarBool(h_enabled) && GetConVarBool(h_notify))
		PrintToChat(client, "[SteamID] Authenticating your client...");
}

public Action Timer_SIDVALIDATE(Handle timer)
{
	static char _SID[64];

	if (GetConVarBool(h_enabled))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!b_validated[i] && IsClientConnected(i))
			{
				if (GetClientAuthId(i, AuthId_Steam2, _SID, sizeof(_SID)) == false || StrContains("STEAM_ID_STOP_IGNORING_RETVALS", _SID, false) != -1)
				{
					if (GetConVarBool(h_notify))
						PrintToChat(i, "[SteamID] Error: Authentication failed, retrying...");
				}
				else
				{
					b_validated[i] = true;
					if (GetConVarBool(h_notify))
						PrintToChat(i, "[SteamID] Authentication successful.");
				}
			}
		}
	}
}

public Action OnClientSayCommand(int client)
{
	if (!b_validated[client] && GetConVarBool(h_enabled))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client)
{
	if (!b_validated[client] && GetConVarBool(h_enabled))
		return Plugin_Handled;
	return Plugin_Continue;
}