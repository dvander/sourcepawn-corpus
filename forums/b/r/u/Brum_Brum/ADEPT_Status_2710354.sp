#include <sdktools>
#include <PTaH>

#pragma semicolon 1
#pragma newdecls required

ArrayList StatusArray;
ConVar gc_ShowOnlyPlayerInfo, gc_SortPlayerByUserId;
bool g_bHidden[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "ADEPT -> Status", 
	description = "Autorski plugin StudioADEPT.net", 
	author = "Brum Brum", 
	version = "1.0", 
	url = "http://www.StudioADEPT.net/forum"
};

public void OnPluginStart()
{
	gc_ShowOnlyPlayerInfo = CreateConVar("sm_status_show_only_player_info", "0", "Show only information about player who executes the status command", _, true, 0.0, true, 1.0);
	gc_SortPlayerByUserId = CreateConVar("sm_status_sort_player_by_userid", "1", "Sort player by their userid", _, true, 0.0, true, 1.0);
	StatusArray = new ArrayList(512);
	PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);
	AutoExecConfig(true, "ADEPT_Status");
}
public void OnMapStart() {
	LoadConfig();
}
public void OnClientPostAdminCheck(int client) {
	g_bHidden[client] = false;
}
public void OnClientDisconnect(int client) {
	g_bHidden[client] = false;
}
public void OnMapEnd() {
	StatusArray.Clear();
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && !IsFakeClient(i) && !IsClientSourceTV(i)) {
			g_bHidden[i] = false;
		}
	}
}
public Action ExecuteStringCommand(int client, char sCommandString[512])
{
	if (IsValidClient(client))
	{
		static char sMessage[512];
		strcopy(sMessage, sizeof(sMessage), sCommandString);
		TrimString(sMessage);
		
		if (StrContains(sMessage, "status ") == 0 || StrEqual(sMessage, "status", false))
		{
			bool playerlist = false;
			for (int i = 0; i < StatusArray.Length; i++) {
				char buffer[512];
				StatusArray.GetString(i, buffer, sizeof(buffer));
				if (StrContains(buffer, "{USERID}") != -1 && !playerlist) {
					if (!gc_ShowOnlyPlayerInfo.BoolValue) {
						if (gc_SortPlayerByUserId.BoolValue) {
							ArrayList sorted = new ArrayList(2);
							for (int j = 1; j <= MaxClients; j++) {
								if (IsClientConnected(j) && !IsFakeClient(j) && !IsClientSourceTV(j) && !g_bHidden[j]) {
									int index = sorted.Push(GetClientUserId(j));
									sorted.Set(index, i, 1);
								}
							}
							SortADTArray(sorted, Sort_Ascending, Sort_Integer);
							for (int j = 0; j < sorted.Length; j++) {
								buffer = "";
								StatusArray.GetString(i, buffer, sizeof(buffer));
								Format(buffer, sizeof(buffer), "%s", CheckMessageVariables(buffer, GetClientOfUserId(sorted.Get(j, 0))));
								PrintToConsole(client, buffer);
							}
						} else {
							for (int j = 1; j <= MaxClients; j++) {
								if (IsClientConnected(j) && !IsFakeClient(j) && !IsClientSourceTV(j) && !g_bHidden[client]) {
									buffer = "";
									StatusArray.GetString(i, buffer, sizeof(buffer));
									Format(buffer, sizeof(buffer), "%s", CheckMessageVariables(buffer, j));
									PrintToConsole(client, buffer);
								}
							}
						}
					}
					else {
						Format(buffer, sizeof(buffer), "%s", CheckMessageVariables(buffer, client));
						PrintToConsole(client, buffer);
					}
					playerlist = true;
					continue;
				}
				Format(buffer, sizeof(buffer), "%s", CheckMessageVariables(buffer));
				PrintToConsole(client, buffer);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
char CheckMessageVariables(const char[] message, int client = -1) {
	char buffer[256], sMessage[512], Name[16];
	strcopy(sMessage, sizeof(sMessage), message);
	if (client > -1 && !IsClientConnected(client) && !IsFakeClient(client) && !IsClientSourceTV(client))return sMessage;
	
	if (StrContains(sMessage, "{SERVER_IP}", false) != -1) {
		ReplaceString(sMessage, sizeof(sMessage), "{SERVER_IP}", GetServerIP());
	}
	if (StrContains(sMessage, "{SERVER_NAME}", false) != -1) {
		GetConVarString(FindConVar("hostname"), buffer, sizeof(buffer));
		ReplaceString(sMessage, sizeof(sMessage), "{SERVER_NAME}", buffer);
	}
	if (StrContains(sMessage, "{CURRENT_MAP}", false) != -1) {
		GetCurrentMap(buffer, sizeof(buffer));
		ReplaceString(sMessage, sizeof(sMessage), "{CURRENT_MAP}", buffer);
	}
	if (StrContains(sMessage, "{PLAYER_COUNT}", false) != -1) {
		IntToString(GetPlayers(false), buffer, sizeof(buffer));
		ReplaceString(sMessage, sizeof(sMessage), "{PLAYER_COUNT}", buffer);
	}
	if (StrContains(sMessage, "{CONNECTING_PLAYERS}", false) != -1) {
		IntToString(GetPlayers(true), buffer, sizeof(buffer));
		ReplaceString(sMessage, sizeof(sMessage), "{CONNECTING_PLAYERS}", buffer);
	}
	if (StrContains(sMessage, "{MAXPLAYERS}", false) != -1) {
		IntToString(GetMaxHumanPlayers(), buffer, sizeof(buffer));
		ReplaceString(sMessage, sizeof(sMessage), "{MAXPLAYERS}", buffer);
	}
	if (StrContains(sMessage, "{USERID}", false) != -1) {
		IntToString(GetClientUserId(client), buffer, sizeof(buffer));
		ReplaceString(sMessage, sizeof(sMessage), "{USERID}", buffer);
	}
	if (StrContains(sMessage, "{PLAYERNAME}", false) != -1) {
		Format(Name, sizeof(Name), "%N", client);
		ReplaceString(sMessage, sizeof(sMessage), "{PLAYERNAME}", Name);
	}
	if (StrContains(sMessage, "{STEAM32}", false) != -1) {
		GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
		ReplaceString(sMessage, sizeof(sMessage), "{STEAM32}", buffer);
	}
	if (StrContains(sMessage, "{CONNECTION_TIME}", false) != -1) {
		Format(buffer, sizeof(buffer), "%s", FormatShortTime(RoundToFloor(GetClientTime(client))));
		ReplaceString(sMessage, sizeof(sMessage), "{CONNECTION_TIME}", buffer);
	}
	if (StrContains(sMessage, "{CLIENT_PING}", false) != -1) {
		Format(buffer, sizeof(buffer), "%d", GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPing", _, client));
		ReplaceString(sMessage, sizeof(sMessage), "{CLIENT_PING}", buffer);
	}
	if (StrContains(sMessage, "{CURRENT_DATE}", false) != -1) {
		FormatTime(buffer, sizeof(buffer), "%d.%m.%Y");
		ReplaceString(sMessage, sizeof(sMessage), "{CURRENT_DATE}", buffer);
	}
	if (StrContains(sMessage, "{CURRENT_TIME}", false) != -1) {
		FormatTime(buffer, sizeof(buffer), "%H:%M:%S");
		ReplaceString(sMessage, sizeof(sMessage), "{CURRENT_TIME}", buffer);
	}
	if (StrContains(sMessage, "{NEXTMAP}", false) != -1) {
		GetNextMap(buffer, sizeof(buffer));
		ReplaceString(sMessage, sizeof(sMessage), "{NEXTMAP}", buffer);
	}
	return sMessage;
}
void LoadConfig() {
	char inFile[PLATFORM_MAX_PATH];
	char line[512];
	
	BuildPath(Path_SM, inFile, sizeof(inFile), "configs/ADEPT_Status.txt");
	
	Handle file = OpenFile(inFile, "rt");
	if (file != INVALID_HANDLE)
	{
		while (!IsEndOfFile(file))
		{
			if (!ReadFileLine(file, line, sizeof(line))) {
				break;
			}
			
			TrimString(line);
			if (strlen(line) > 0)
			{
				if (StrContains(line, "//") != -1)
					continue;
				
				StatusArray.PushString(line);
			}
		}
		CloseHandle(file);
	}
}
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max) {
	CreateNative("Status_HidePlayer", Native_HidePlayer);
	CreateNative("Status_ShowPlayer", Native_ShowPlayer);
	CreateNative("Status_IsPlayerHidden", Native_IsPlayerHidden);
	
	RegPluginLibrary("Custom_Status");
	return APLRes_Success;
}
public int Native_HidePlayer(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (!IsValidClient(client))return;
	
	g_bHidden[client] = true;
}
public int Native_ShowPlayer(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (!IsValidClient(client))return;
	
	g_bHidden[client] = false;
}
public int Native_IsPlayerHidden(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	if (!IsValidClient(client))return false;
	
	return g_bHidden[client];
}
int GetPlayers(bool connecting) {
	int players;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_bHidden[i])continue;
		if (connecting && IsClientConnected(i) && !IsClientInGame(i))players++;
		else if (!connecting && IsValidClient(i))players++;
	}
	return players;
}
char FormatShortTime(int time) {
	char Time[12];
	int g_iHours = 0;
	int g_iMinutes = 0;
	int g_iSeconds = time;
	
	while (g_iSeconds > 3600) {
		g_iHours++;
		g_iSeconds -= 3600;
	}
	while (g_iSeconds > 60) {
		g_iMinutes++;
		g_iSeconds -= 60;
	}
	if (g_iHours >= 1)Format(Time, sizeof(Time), "%d:%d:%d", g_iHours, g_iMinutes, g_iSeconds);
	else if (g_iMinutes >= 1)Format(Time, sizeof(Time), "  %d:%d", g_iMinutes, g_iSeconds);
	else Format(Time, sizeof(Time), "   %d", g_iSeconds);
	return Time;
}
char GetServerIP() {
	char NetIP[32];
	int pieces[4];
	int longip = FindConVar("hostip").IntValue;
	
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	
	Format(NetIP, sizeof(NetIP), "%d.%d.%d.%d:%d", pieces[0], pieces[1], pieces[2], pieces[3], FindConVar("hostport").IntValue);
	return NetIP;
}
bool IsValidClient(int client) {
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsClientConnected(client) || IsFakeClient(client) || IsClientSourceTV(client))
		return false;
	
	return true;
}
