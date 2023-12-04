#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

int g_iMaxByte;
char g_sDefaultName[MAX_NAME_LENGTH], g_sPlayerName[MAXPLAYERS+1][MAX_NAME_LENGTH];
bool g_bEnabled, g_bWarning, g_bBlockEvent[MAXPLAYERS+1], g_bWarningJoin[MAXPLAYERS+1];
EngineVersion g_eEngineVersion;

public Plugin myinfo =
{
	name = "Player Name Fixer",
	author = "Romeo",
	description = "Fix player name errors.",
	version = "2.1",
	url = ""
};

public void OnPluginStart()
{	
	ConVar Convar;
	
	Convar = CreateConVar("pnf_enable",  "1", "Enable/Disable plugin", 0, true, 0.0, true, 1.0);
	Convar.AddChangeHook(OnConVarChange_Enabled);
	OnConVarChange_Enabled(Convar, NULL_STRING, NULL_STRING);
	
	Convar = CreateConVar("pnf_maxbyte", "4", "Byte limit", 0, true, 2.0, true, 4.0);
	Convar.AddChangeHook(OnConVarChange_MaxByte);
	OnConVarChange_MaxByte(Convar, NULL_STRING, NULL_STRING);
	
	Convar = CreateConVar("pnf_warning", "1", "Enable/Disable warning message", 0, true, 0.0, true, 1.0);
	Convar.AddChangeHook(OnConVarChange_Warning);
	OnConVarChange_Warning(Convar, NULL_STRING, NULL_STRING);
	
	Convar = CreateConVar("pnf_default", "Unnamed", "Default name when the name is blank");
	Convar.AddChangeHook(OnConVarChange_Default);
	OnConVarChange_Default(Convar, NULL_STRING, NULL_STRING);
	
	HookEvent("player_changename", OnPlayerChangeNamePost, EventHookMode_Post);
	HookEvent("player_team", OnPlayerTeamPost, EventHookMode_Post);
	HookUserMessage(GetUserMessageId("SayText2"), SayText2, true);
	
	g_eEngineVersion = GetEngineVersion();
	
	LoadTranslations("player_name_fixer.phrases");
	AutoExecConfig(true, "player_name_fixer");
}

public void OnConVarChange_Enabled(ConVar Convar, const char[] oldValue, const char[] newValue) {g_bEnabled = Convar.BoolValue;}
public void OnConVarChange_MaxByte(ConVar Convar, const char[] oldValue, const char[] newValue) {g_iMaxByte = Convar.IntValue;}
public void OnConVarChange_Warning(ConVar Convar, const char[] oldValue, const char[] newValue) {g_bWarning = Convar.BoolValue;}
public void OnConVarChange_Default(ConVar Convar, const char[] oldValue, const char[] newValue) {Convar.GetString(g_sDefaultName, MAX_NAME_LENGTH);}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	g_bBlockEvent[client] = false;
	g_bWarningJoin[client] = false;
	
	if(g_bEnabled)
    {
		GetClientName(client, g_sPlayerName[client], MAX_NAME_LENGTH);
		if (CheckName(client)) g_bWarningJoin[client] = true;
	}
	
	return true;
}

public void OnClientDisconnect(int client)
{
	if (g_bEnabled) SetClientInfo(client, "name", g_sPlayerName[client]);
}

public void OnPlayerChangeNamePost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (g_bEnabled && !g_bBlockEvent[client])
    {
		event.GetString("newname", g_sPlayerName[client], MAX_NAME_LENGTH);
		if (CheckName(client) && g_bWarning) PrintWarningMessage(client);
	}
}

public void OnPlayerTeamPost(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (g_bEnabled && g_bWarning && IsValidClient(client) && g_bWarningJoin[client])
	{
		PrintWarningMessage(client);
		g_bWarningJoin[client] = false;
	}
}

bool CheckName(int client)
{
	int iPosition;
	bool bFixName = false;
	char sTemp[5], sFixedName[MAX_NAME_LENGTH];
	
	while (g_sPlayerName[client][iPosition] != 0 && iPosition < MAX_NAME_LENGTH)
	{
		int iByte = IsCharMB(g_sPlayerName[client][iPosition]);
		if (!iByte) iByte = 1;
		Format(sTemp, iByte + 1, "%s", g_sPlayerName[client][iPosition]);
		if (iByte < g_iMaxByte) StrCat(sFixedName, MAX_NAME_LENGTH, sTemp);
		else if (iByte >= g_iMaxByte) bFixName = true;
		iPosition += iByte;
	}
	
	if (bFixName)
	{
		g_bBlockEvent[client] = true;
		if (sFixedName[0]) SetClientName(client, sFixedName);
		else SetClientName(client, g_sDefaultName);
		g_bBlockEvent[client] = false;
	}
	
	return bFixName;
}

void PrintWarningMessage(int client)
{
	if (IsSource2009()) PrintToChat(client, " 0x800080%N, 0x8B0000%t", client, "Warning");
	else PrintToChat(client, " \x03%N, \x02%t", client, "Warning");
}

public Action SayText2(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	if (!reliable) return Plugin_Continue;
	
	int client = 0;
	char buffer[25];
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		client = PbReadInt(bf, "ent_idx");
		if (!PbReadBool(bf, "chat")) return Plugin_Continue;
		PbReadString(bf, "msg_name", buffer, sizeof(buffer));
	}
	else
	{
		client = BfReadByte(bf);
		if (BfReadByte(bf)) return Plugin_Continue;
		BfReadChar(bf);
		BfReadChar(bf);
		BfReadString(bf, buffer, sizeof(buffer));
	}
	
	if (StrContains(buffer, "_Name_Change") != -1 && IsValidClient(client) && g_bBlockEvent[client]) return Plugin_Handled;
	
	return Plugin_Continue;
}

stock bool IsSource2009()
{
	return (g_eEngineVersion == Engine_CSS
	|| g_eEngineVersion == Engine_HL2DM
	|| g_eEngineVersion == Engine_DODS
	|| g_eEngineVersion == Engine_TF2
	|| g_eEngineVersion == Engine_SDK2013);
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}