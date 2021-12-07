
#include <sdkhooks>
#include <sdktools>
#include <SteamWorks>
#include <smjansson>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "https://raw.githubusercontent.com/SirPurpleness/SourceCBL/master/updater.txt"
#define SPECWHO_VERSION "1.1"
#define SPECMODE_NONE 				0
#define SPECMODE_FIRSTPERSON 		4
#define SPECMODE_3RDPERSON 			5

#pragma dynamic 1045840

char ClientSteam[MAXPLAYERS+1][255];
char g_sPadding[128] = "  ";
char FilePath[PLATFORM_MAX_PATH];
char port[32];
char hostname[64];
char TargetSteam32[MAXPLAYERS+1][255];

ConVar g_hCvarEnabled;

bool IsEnabled = true;
bool bSpecWhoDisabled[MAXPLAYERS+1] = false;

Handle SpecWhoHudTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle hAuthTimer[MAXPLAYERS+1] = INVALID_HANDLE;
Handle gamePort;
Handle gameHostName;

int AuthTries[MAXPLAYERS+1] = 0;
int iSpecTarget[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "SourceCBL",
	author = "SomePanns",
	description = "Allows communities to keep hackers/cheaters away from their servers by using a global database with stored information of hackers/cheaters.",
	version = "1.2",
}

public void OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_scbl_enabled", "1", "1 = Enabled (default), 0 = disabled.");

	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	BuildPath(Path_SM, FilePath, sizeof(FilePath), "configs/sourcecbl_whitelist.txt");

	if(LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
}


public OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
}

public void OnMapStart()
{
	gamePort = FindConVar("hostport");
	gameHostName = FindConVar("hostname");

	GetConVarString(gamePort, port, 32);
	GetConVarString(gameHostName, hostname, 64);

	char s_URL[] = "http://sourcecbl.com/api/statistics";

	Handle handle = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, s_URL);
	SteamWorks_SetHTTPRequestGetOrPostParameter(handle, "ip", port);
	SteamWorks_SetHTTPRequestGetOrPostParameter(handle, "hostname", hostname);
	SteamWorks_SendHTTPRequest(handle);
	CloseHandle(handle);
}

public void OnClientPostAdminCheck(int client)
{
	SpawnHudTimer(client);
}

public void OnConfigsExecuted() {
	IsEnabled = GetConVarBool(g_hCvarEnabled);

	if(!IsEnabled) {
		ServerCommand("sm plugins unload sourcecbl");
	}
}

public void OnClientDisconnect(int client)
{
	AuthTries[client] = 0;
	KillTimerSafe(SpecWhoHudTimer[client]);
}

public void OnClientPutInServer(int client)
{
	AuthTries[client] = 0;
}

void SpawnHudTimer(int client)
{
	SpecWhoHudTimer[client] = CreateTimer(1.0, Timer_SpecWhoHud, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsEnabled = GetConVarBool(g_hCvarEnabled);

	if(convar == g_hCvarEnabled)
	{
		if(StrEqual(oldValue, "1", false)) { // disable the plugin
			ServerCommand("sm plugins unload sourcecbl");
			PrintToServer("[SCBL] SourceCBL Disabled");
		}
	}
}

public void OnClientAuthorized(int client)
{
	if(!IsFakeClient(client))
	{
		if(GetClientAuthId(client, AuthId_SteamID64, ClientSteam[client], sizeof(ClientSteam)))
		{
			UploadDataString(client);
		}
		else
		{
			LogError("[SourceCBL] Could not fetch Steam ID of client %N. Re-trying later.", client);
			hAuthTimer[client] = CreateTimer(180.0, AuthTimer, client, TIMER_REPEAT);
		}
	}
}

public bool IsPlayerGenericAdmin(int client)
{
    if (CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false))
    {
        return true;
    }

    return false;
}

public bool SCBL_Whitelist(int client)
{
	char Whitelisted[64];
	int i_Whitelisted;

	KeyValues Whitelist = CreateKeyValues("");
	Whitelist.ImportFromFile(FilePath);

	if(Whitelist.GotoFirstSubKey(true))
    {
        do
        {
			Whitelist.GetSectionName(ClientSteam[client], sizeof(ClientSteam));

			Whitelist.GetString("whitelist", Whitelisted, sizeof(Whitelisted), NULL_STRING);
			i_Whitelisted = StringToInt(Whitelisted);

			if(i_Whitelisted == 1) {
			    return true;
			}
			else
			{
				return false;
			}


        }
        while(Whitelist.GotoNextKey(true));
    }
	Whitelist.Rewind();

	return false;
}

void ProcessElement(char[] sKey, Handle hObj) {
	switch(json_typeof(hObj)) {
		case JSON_OBJECT: {
			StrCat(g_sPadding, sizeof(g_sPadding), "  ");
			IterateJsonObject(hObj);
			strcopy(g_sPadding, sizeof(g_sPadding), g_sPadding[2]);
		}

		 case JSON_ARRAY: {
			StrCat(g_sPadding, sizeof(g_sPadding), "  ");
			IterateJsonArray(hObj);
			strcopy(g_sPadding, sizeof(g_sPadding), g_sPadding[2]);
		}

		case JSON_STRING: {
			char sString[1024];
			json_string_value(hObj, sString, sizeof(sString));

			for(int client = 1; client <= MaxClients; client++)
			{
				if(StrEqual(sKey, "steam_id", false)) {
					if(StrEqual(sString, ClientSteam[client], false))
					{
						if(!SCBL_Whitelist(client)) {
							CreateTimer(0.1, SourceCBLTimer, client);

							break;
						}
						else {
							SendConnectionData(client, "1");
						}
					}

					break;
				}
			}
		}
	}
}

public Action SourceCBLTimer(Handle timer, int client)
{
	if(IsClientConnected(client))
	{
		SendConnectionData(client, "0");

		for(int admins = 0; admins <= MaxClients; admins++)
		{
			if(IsValidClient(admins))
			{
				if(IsPlayerGenericAdmin(admins))
				{
					PrintToChat(admins, "\x04[SourceCBL]\x05 Connecting player \x04%N\x05 with Steam ID \x04%s\x05 is a marked cheater and has been blocked.", client, ClientSteam[client]);
				}
			}
		}

		char Reason[255];
		Format(Reason, sizeof(Reason), "You have been banned by SourceCBL for cheating. Visit www.SourceCBL.com for more information");
		KickClientEx(client, Reason);
	}
}

stock bool IsValidClient(int client, bool isAlive=false)
{
    if(!client||client>MaxClients)    return false;
    if(isAlive) return IsClientInGame(client) && IsPlayerAlive(client);
    return IsClientInGame(client);
}

public int SendConnectionData(int client, char[] handled)
{
	// handled = 1 = allowed, 0 = blocked

	char[] s_URL = "http://sourcecbl.com/api/connections";
	Handle handle = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, s_URL);
	SteamWorks_SetHTTPRequestGetOrPostParameter(handle, "ip", port);
	SteamWorks_SetHTTPRequestGetOrPostParameter(handle, "hostname", hostname);
	SteamWorks_SetHTTPRequestGetOrPostParameter(handle, "steamid", ClientSteam[client]);
	SteamWorks_SetHTTPRequestGetOrPostParameter(handle, "handled", handled);
	SteamWorks_SendHTTPRequest(handle);
	CloseHandle(handle);
}

public void IterateJsonArray(Handle hArray) {
	for(int iElement = 0; iElement < json_array_size(hArray); iElement++) {
		Handle hValue = json_array_get(hArray, iElement);
		char sElement[4];
		IntToString(iElement, sElement, sizeof(sElement));
		ProcessElement(sElement, hValue);

		CloseHandle(hValue);
	}
}


public void IterateJsonObject(Handle hObj) {
	Handle hIterator = json_object_iter(hObj);

	while(hIterator != INVALID_HANDLE) {
		char sKey[128];
		json_object_iter_key(hIterator, sKey, sizeof(sKey));

		Handle hValue = json_object_iter_value(hIterator);

		ProcessElement(sKey, hValue);

		CloseHandle(hValue);
		hIterator = json_object_iter_next(hObj, hIterator);
	}
}

public void UploadDataString(int client)
{
	char s_URL[] = "http://sourcecbl.com/api/steam";

	Handle handle = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, s_URL);

	SteamWorks_SetHTTPRequestGetOrPostParameter(handle, "steamid", ClientSteam[client]);
	SteamWorks_SetHTTPRequestRawPostBody(handle, "application/json", s_URL, sizeof(s_URL));
	if (!handle || !SteamWorks_SetHTTPCallbacks(handle, HTTP_RequestComplete) || !SteamWorks_SendHTTPRequest(handle))
	{
		CloseHandle(handle);
	}
}

public int HTTP_RequestComplete(Handle HTTPRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
    if(!bRequestSuccessful) {
        LogError("[SourceCBL] An error occured while requesting the API.");
    } else {
		SteamWorks_GetHTTPResponseBodyCallback(HTTPRequest, APIWebResponse);

		CloseHandle(HTTPRequest);
    }
}

public int APIWebResponse(const char[] sData)
{
	Handle hObj = json_load(sData);

	ProcessElement("steam_id", hObj);

	CloseHandle(hObj);
}

public void KillTimerSafe(Handle &hTimer)
{
	if(hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}

public Action AuthTimer(Handle timer, int client)
{
	if(IsClientInGame(client)) // We expect this to run only when they're in the game and not e.g. downloading content
	{
		if(GetClientAuthId(client, AuthId_SteamID64, ClientSteam[client], sizeof(ClientSteam)))
		{
			UploadDataString(client);
			KillTimerSafe(hAuthTimer[client]);
		}
		else
		{
			AuthTries[client]++;
			if(AuthTries[client] > 3)
			{
				char errorGettingData[255];
				Format(errorGettingData, sizeof(errorGettingData), "SourceCBL failed to retrieve your Steam ID after several tries, please reconnect and try again.");

				KillTimerSafe(hAuthTimer[client]);
				KickClientEx(client, errorGettingData);
			}
		}
	}
}

char GetServerIP()
{
	int pieces[4];
	int longip = GetConVarInt(FindConVar("hostip"));
	int iport = GetConVarInt(FindConVar("hostport"));
	char NetIP[255];

	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;

	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d:%i", pieces[0], pieces[1], pieces[2], pieces[3], iport);

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

		if(iSpecTarget[client] > 0 && !IsValidClient(iSpecTarget[client]))
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
