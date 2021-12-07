#include <sdktools_sound>

#undef REQUIRE_PLUGIN
#include <sourcebanspp>

int g_iConnectNetMsgCount[MAXPLAYERS + 1] =  { 0, ... };
char g_szLog[PLATFORM_MAX_PATH];
ConVar g_cBanClient = null;
bool g_bSourceBans = false;

public Plugin myinfo = 
{
	name = "NullWave Crash Fix", 
	author = "backwards, IT-KiLLER, SM9();", 
	description = "Exploit Fix", 
	version = "0.2"
}

public void OnPluginStart() 
{
	HookEvent("player_connect_full", Event_PlayerConnectFull, EventHookMode_Pre);
	AddNormalSoundHook(NormalSoundHook);
	AddAmbientSoundHook(AmbientSoundHook);
	
	BuildPath(Path_SM, g_szLog, sizeof(g_szLog), "logs/NullWaveCrashFix.log");
	
	g_cBanClient = CreateConVar("sm_nwfix_ban", "1", "Should the client be banned for crash attempt?", FCVAR_PROTECTED);
	g_bSourceBans = LibraryExists("sourcebans");
	
	AutoExecConfig(true, "NullWaveFix");
}

public void OnLibraryAdded(const char[] szName) 
{
	if (StrEqual(szName, "sourcebans")) {
		g_bSourceBans = true;
	}
}

public void OnLibraryRemoved(const char[] szName) 
{
	if (StrEqual(szName, "sourcebans")) {
		g_bSourceBans = false;
	}
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++) {
		g_iConnectNetMsgCount[i] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	g_iConnectNetMsgCount[client] = 0;
}

public Action Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsValidClient(client) && client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client) && !IsClientSourceTV(client) && !IsClientReplay(client)) {
		if (!IsClientInKickQueue(client)) {
			KickClient(client, "Something went wrong, please retry connecting");
			LogToFileEx(g_szLog, "Kicked %L for sending an early player_connect_full event (Possible crash attempt)", client);
		}
		
		event.BroadcastDisabled = true;
		return Plugin_Changed;
	}
	
	if (++g_iConnectNetMsgCount[client] == 1) {
		return Plugin_Continue;
	}
	
	if (!IsClientInKickQueue(client)) {
		if(g_cBanClient.BoolValue) {
			if(g_bSourceBans) {
				SBPP_BanPlayer(0, client, 0, "Attempted server crash exploit");
			} else {
				BanClient(client, 0, BANFLAG_AUTO, "Attempted server crash exploit", "Attempted server crash exploit");
			}
			
			LogToFileEx(g_szLog, "Banned %L for sending more than one player_connect_full event (Confirmed crash attempt)", client);
		} else {
			KickClient(client, "Attempted server crash exploit");
			LogToFileEx(g_szLog, "Kicked %L for sending more than one player_connect_full event (Confirmed crash attempt)", client);
		}
	}
	
	event.BroadcastDisabled = true;
	return Plugin_Changed;
}

public Action NormalSoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (sample[0] == '\0' || sample[0] == 'c' && (StrEqual(sample, "common\null.wav") || StrEqual(sample, "common/null.wav")) || !strlen(sample)) {
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action AmbientSoundHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	if (sample[0] == '\0' || sample[0] == 'c' && (StrEqual(sample, "common\null.wav") || StrEqual(sample, "common/null.wav")) || !strlen(sample)) {
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client)) {
		return false;
	}
	
	return true;
} 