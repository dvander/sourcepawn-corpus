/****************************************************************************************************
	Stealth Revived
*****************************************************************************************************

*****************************************************************************************************
	CHANGELOG: 
			0.1 - First version.
			0.2 - 
				- Improved spectator blocking with SendProxy (If installed) - Credits to Chaosxk
				- Make PTAH optional, sm_stealth_customstatus wont work in CSGO unless PTAH is installed until we find a way to rewrite status without dependencies.
				- Only rewrite status if there is atleast 1 stealthed client.
				- Improved late loading to account for admins already in spectator.
				- Improved support for other games, Still need to do the status rewrite for other games though.
				- Improved status anti-spam.
			0.3 - 
				- Fixed variables not being reset on client disconnect.
				- Added intial TF2 support (Needs further testing)
			0.4 - 
				- Use SteamWorks or SteamTools for more accurate IP detection, If you have both installed then only SteamWorks is used.
			0.5 - 
				- Fix console ending loop (Thanks Bara for report)
				- Fix error spam in TF2 (Thanks rengo)
				- Fixed TF2 disconnect reason (Thanks Drixevel)
			0.6 - 
				- Fix more error spam scenarios (Thanks rengo)
				- Correct TF2 disconnect reason.
				- Misc code changes.
			0.7 - 
				- Fixed issue with fake disconnect event breaking hud / radar.
				- Improved logic inside fake event creation.
				- General fixes.
			0.8 - 
				- Fixed issue where team broadcast being disabled caused the team menu to get stuck.
				- Fixed bad logic in SendProxy Callback.
				- Fixed "unconnected" bug on team changes.
				- Added check to make sure team event exists.
			0.9 - 
				- Removed SendProxy (It's too problematic)
				- Added a ConVar 'sm_stealth_cheat_hide' for cheat blocking (SetTransmit is inherently expensive thus this option can cause performance issues on some setups)
			0.9.1 - 
				- Support Ptah 1.1.0 (fix by FIVE)
			
				
*****************************************************************************************************
*****************************************************************************************************
	INCLUDES
*****************************************************************************************************/
#include <StealthRevived>
#include <sdktools>
#include <sdkhooks>
#include <regex>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#tryinclude <updater>

#undef REQUIRE_EXTENSIONS
#tryinclude <sendproxy>
#tryinclude <ptah>
#tryinclude <SteamWorks>
#tryinclude <SteamTools>

#define UPDATE_URL    "https://bitbucket.org/SM91337/stealthrevived/raw/master/addons/sourcemod/update.txt"

/****************************************************************************************************
	DEFINES
*****************************************************************************************************/
#define PL_VERSION "0.9.1"
#define LoopValidPlayers(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))
#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1, false))

/****************************************************************************************************
	ETIQUETTE.
*****************************************************************************************************/
#pragma newdecls required;
#pragma semicolon 1;

/****************************************************************************************************
	PLUGIN INFO.
*****************************************************************************************************/
public Plugin myinfo = 
{
	name = "Stealth Revived", 
	author = "SM9();", 
	description = "A proper stealth plugin that actually works.", 
	version = PL_VERSION, 
	url = "http://www.fragdeluxe.com/"
}

/****************************************************************************************************
	HANDLES.
*****************************************************************************************************/
ConVar g_cvHostName = null;
ConVar g_cvHostPort = null;
ConVar g_cvHostIP = null;
ConVar g_cvTags = null;
ConVar g_cvCustomStatus = null;
ConVar g_cvFakeDisconnect = null;
ConVar g_cvCmdInterval = null;
ConVar g_cvSetTransmit = null;

/****************************************************************************************************
	BOOLS.
*****************************************************************************************************/
bool g_bStealthed[MAXPLAYERS + 1];
bool g_bDisconnectFaked[MAXPLAYERS + 1];
bool g_bWindows = false;
bool g_bRewriteStatus = false;
bool g_bFakeDC = false;
bool g_bDataCached = false;
bool g_bSetTransmit = true;

/****************************************************************************************************
	INTS.
*****************************************************************************************************/
int g_iLastCommand[MAXPLAYERS + 1];
int g_iCmdInterval = 1;
int g_iTickRate = 0;
int g_iServerPort = 0;
int g_iPlayerManager = -1;
int g_iTF2Stats[10][6];

/****************************************************************************************************
	STRINGS.
*****************************************************************************************************/
char g_szVersion[128];
char g_szHostName[128];
char g_szServerIP[128];
char g_szCurrentMap[128];
char g_szMaxPlayers[128];
char g_szGameName[128];
char g_szAccount[128];
char g_szSteamId[128];
char g_szTags[512];

public void OnPluginStart()
{
	AutoExecConfig_SetFile("plugin.stealthrevived");
	
	g_cvCustomStatus = AutoExecConfig_CreateConVar("sm_stealth_customstatus", "1", "Should the plugin rewrite status out? 0 = False, 1 = True", _, true, 0.0, true, 1.0);
	g_cvCustomStatus.AddChangeHook(OnCvarChanged);
	
	g_cvFakeDisconnect = AutoExecConfig_CreateConVar("sm_stealth_fakedc", "1", "Should the plugin fire a fake disconnect when somebody goes stealth? 0 = False, 1 = True", _, true, 0.0, true, 1.0);
	g_cvFakeDisconnect.AddChangeHook(OnCvarChanged);
	
	g_cvCmdInterval = AutoExecConfig_CreateConVar("sm_stealth_cmd_interval", "1", "How often can the status cmd be used in seconds?", _, true, 0.0);
	g_cvCmdInterval.AddChangeHook(OnCvarChanged);
	
	g_cvSetTransmit = AutoExecConfig_CreateConVar("sm_stealth_cheat_hide", "1", "Should the plugin prevent cheats with 'spectator list'? (This option may cause performance issues on some servers)", _, true, 0.0, true, 1.0);
	g_cvSetTransmit.AddChangeHook(OnCvarChanged);
	
	AutoExecConfig_CleanFile(); AutoExecConfig_ExecuteFile();
	
	g_cvHostName = FindConVar("hostname");
	g_cvHostPort = FindConVar("hostport");
	g_cvHostIP = FindConVar("hostip");
	g_cvTags = FindConVar("sv_tags");
	
	if (g_cvTags != null) {
		g_cvTags.AddChangeHook(OnCvarChanged);
	}
	
	#if defined _updater_included
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	#if defined _PTaH_included
	if (LibraryExists("PTaH")) {
		PTaH(PTaH_ExecuteStringCommandPre, Hook, ExecuteStringCommand);
	}
	#endif
	
	AddCommandListener(Command_Status, "status");
	
	GetGameFolderName(g_szGameName, sizeof(g_szGameName));
	
	if (!HookEventEx("player_team", Event_PlayerTeam_Pre, EventHookMode_Pre)) {
		SetFailState("player_team event does not exist on this mod, plugin disabled");
		return;
	}
	
	if (StrEqual(g_szGameName, "tf", false)) {
		HookEventEx("player_spawn", TF2Events_CallBack);
		HookEventEx("player_escort_score", TF2Events_CallBack);
		HookEventEx("player_death", TF2Events_CallBack);
	}
}

public void OnLibraryAdded(const char[] szName)
{
	if (StrEqual(szName, "updater", false)) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] szError, int iErrMax)
{
	RegPluginLibrary("StealthRevived");
	CreateNative("SR_IsClientStealthed", Native_IsClientStealthed);
	return APLRes_Success;
}

public void OnCvarChanged(ConVar cConVar, const char[] szOldValue, const char[] szNewValue)
{
	if (cConVar == g_cvCustomStatus) {
		g_bRewriteStatus = view_as<bool>(StringToInt(szNewValue));
	} else if (cConVar == g_cvFakeDisconnect) {
		g_bFakeDC = view_as<bool>(StringToInt(szNewValue));
	} else if (cConVar == g_cvCmdInterval) {
		g_iCmdInterval = StringToInt(szNewValue);
	} else if (cConVar == g_cvTags) {
		strcopy(g_szTags, 512, szNewValue);
	} else if (cConVar == g_cvSetTransmit) {
		g_bSetTransmit = view_as<bool>(StringToInt(szNewValue));
		
		LoopValidPlayers(iClient) {
			if (g_bSetTransmit) {
				SDKHook(iClient, SDKHook_SetTransmit, Hook_SetTransmit);
			} else {
				SDKUnhook(iClient, SDKHook_SetTransmit, Hook_SetTransmit);
			}
		}
	}
}

public void OnConfigsExecuted()
{
	g_bRewriteStatus = g_cvCustomStatus.BoolValue;
	g_bFakeDC = g_cvFakeDisconnect.BoolValue;
	g_iCmdInterval = g_cvCmdInterval.IntValue;
	g_cvTags.GetString(g_szTags, 512);
	g_bSetTransmit = g_cvSetTransmit.BoolValue;
	
	LoopValidPlayers(iClient) {
		OnClientPutInServer(iClient);
		
		if (!IsClientStealthWorthy(iClient)) {
			continue;
		}
		
		if (GetClientTeam(iClient) < 2) {
			g_bStealthed[iClient] = true;
		}
	}
}

public void OnMapStart()
{
	GetCurrentMap(g_szCurrentMap, 128);
	
	for (int i = 0; i < 10; i++) {
		for (int y = 0; y < 6; y++) {
			g_iTF2Stats[i][y] = 0;
		}
	}
	
	g_iPlayerManager = GetPlayerResourceEntity();
	
	if (g_iPlayerManager == -1) {
		return;
	}
	
	SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PlayerManagerThinkPost);
}

public Action Command_Status(int iClient, const char[] szCommand, int iArgs)
{
	if (iClient < 1) {
		return Plugin_Continue;
	}
	
	if (g_iLastCommand[iClient] > -1 && GetTime() - g_iLastCommand[iClient] < g_iCmdInterval) {
		return Plugin_Handled;
	}
	
	if (!g_bRewriteStatus) {
		return Plugin_Continue;
	}
	
	if (GetStealthCount() < 1) {
		return Plugin_Continue;
	}
	
	ExecuteStringCommand(iClient, "status");
	
	return Plugin_Handled;
}

public Action ExecuteStringCommand(int iClient, char szMessage[1024])
{
	if (g_iLastCommand[iClient] > -1 && GetTime() - g_iLastCommand[iClient] < g_iCmdInterval) {
		return Plugin_Handled;
	}
	
	if (!g_bRewriteStatus) {
		return Plugin_Continue;
	}
	
	static char szMessage2[1024];
	szMessage2 = szMessage;
	
	TrimString(szMessage2);
	
	if (StrContains(szMessage2, "status") == -1) {
		return Plugin_Continue;
	}
	
	return PrintCustomStatus(iClient) ? Plugin_Handled : Plugin_Continue;
}

public Action Event_PlayerTeam_Pre(Event evGlobal, char[] szEvent, bool bDontBroadcast)
{
	int iUserId = evGlobal.GetInt("userid");
	int iClient = GetClientOfUserId(iUserId);
	
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || view_as<bool>(evGlobal.GetInt("disconnect")) || IsFakeClient(iClient)) {
		return Plugin_Continue;
	}
	
	int iTeam = evGlobal.GetInt("team");
	
	if (iTeam == GetClientTeam(iClient)) {
		return Plugin_Continue;
	}
	
	int iOldTeam = evGlobal.GetInt("oldteam");
	
	Event evNewTeam = CreateEvent("player_team", true);
	
	if (evNewTeam == null) {
		SetFailState("Failed to create player_team event");
		return Plugin_Continue;
	}
	
	evNewTeam.SetInt("userid", iUserId);
	evNewTeam.SetInt("team", iTeam);
	evNewTeam.SetInt("oldteam", iOldTeam);
	evNewTeam.SetInt("disconnect", false);
	
	evGlobal.BroadcastDisabled = true;
	
	if (iTeam > 1) {
		g_bStealthed[iClient] = false;
	} else {
		evNewTeam.FireToClient(iClient);
	}
	
	CreateTimer(0.01, Timer_DelayedTeam, evNewTeam);
	
	return Plugin_Continue;
}

public Action Timer_DelayedTeam(Handle hTimer, Event evNewTeam)
{
	int iUserId = evNewTeam.GetInt("userid");
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		evNewTeam.Cancel();
		evNewTeam = null;
		return Plugin_Stop;
	}
	
	int iTeam = evNewTeam.GetInt("team");
	
	if (iTeam > 1) {
		if (g_bDisconnectFaked[iClient]) {
			Event evFakeConnect = CreateEvent("player_connect", true);
			
			if (evFakeConnect != null) {
				char szName[MAX_NAME_LENGTH]; GetClientName(iClient, szName, sizeof(szName));
				char szAuthId[64]; GetClientAuthId(iClient, AuthId_Engine, szAuthId, sizeof(szAuthId));
				char szIP[64]; GetClientIP(iClient, szIP, sizeof(szIP), false);
				
				evFakeConnect.SetString("name", szName);
				evFakeConnect.SetInt("index", iClient);
				evFakeConnect.SetInt("userid", iUserId);
				evFakeConnect.SetString("networkid", szAuthId);
				evFakeConnect.SetString("address", szIP);
				evFakeConnect.SetInt("bot", false);
				
				LoopValidPlayers(i) {
					if (i == iClient) {
						continue;
					}
					
					evFakeConnect.FireToClient(i);
				}
				
				evFakeConnect.Cancel();
			}
		}
		
		g_bDisconnectFaked[iClient] = false;
		evNewTeam.Fire();
		evNewTeam = null;
	} else {
		evNewTeam.Cancel();
		evNewTeam = null;
		
		if (!g_bStealthed[iClient] && IsClientStealthWorthy(iClient)) {
			if (g_bFakeDC) {
				Event evFakeDisconnect = CreateEvent("player_disconnect", true);
				
				if (evFakeDisconnect != null) {
					char szName[MAX_NAME_LENGTH]; GetClientName(iClient, szName, sizeof(szName));
					char szAuthId[64]; GetClientAuthId(iClient, AuthId_Engine, szAuthId, sizeof(szAuthId));
					char szIP[64]; GetClientIP(iClient, szIP, sizeof(szIP), false);
					
					evFakeDisconnect.SetInt("userid", iUserId);
					evFakeDisconnect.SetString("reason", StrEqual(g_szGameName, "csgo", false) ? "Disconnect" : "Disconnect by user.");
					evFakeDisconnect.SetString("name", szName);
					evFakeDisconnect.SetString("networkid", szAuthId);
					evFakeDisconnect.SetInt("bot", false);
					
					LoopValidPlayers(i) {
						if (i == iClient) {
							continue;
						}
						
						evFakeDisconnect.FireToClient(i);
					}
					
					evFakeDisconnect.Cancel();
					g_bDisconnectFaked[iClient] = true;
				}
			}
			
			g_bStealthed[iClient] = true;
		}
	}
	
	if (evNewTeam != null) {
		evNewTeam.Cancel();
	}
	
	return Plugin_Stop;
}

public Action TF2Events_CallBack(Event evEvent, char[] szEvent, bool bDontBroadcast)
{
	int iEvent = -1;
	int iClassPlayer = -1;
	int iClassAttacker = -1;
	int iClassAssister = -1;
	
	if (StrEqual(szEvent, "player_spawn", false)) {
		iClassPlayer = TF2_GetPlayerClass(GetClientOfUserId(evEvent.GetInt("userid")));
		iEvent = TF_SR_Spawns;
	} else if (StrEqual(szEvent, "player_escort_score", false)) {
		iClassPlayer = TF2_GetPlayerClass(evEvent.GetInt("player"));
		iEvent = TF_SR_Points;
	} else if (StrEqual(szEvent, "player_death", false)) {
		iClassPlayer = TF2_GetPlayerClass(GetClientOfUserId(evEvent.GetInt("userid")));
		iClassAttacker = TF2_GetPlayerClass(GetClientOfUserId(evEvent.GetInt("attacker")));
		iClassAssister = TF2_GetPlayerClass(GetClientOfUserId(evEvent.GetInt("assister")));
		
		iEvent = TF_SR_Deaths;
	}
	
	switch (iEvent) {
		case TF_SR_Spawns :  {
			if (TF2_IsValidClass(iClassPlayer)) {
				g_iTF2Stats[iClassPlayer][TF_SR_Spawns]++;
			}
		}
		
		case TF_SR_Points :  {
			if (TF2_IsValidClass(iClassPlayer)) {
				g_iTF2Stats[iClassPlayer][TF_SR_Points] += evEvent.GetInt("points");
			}
		}
		
		case TF_SR_Deaths :  {
			if (TF2_IsValidClass(iClassPlayer)) {
				g_iTF2Stats[iClassPlayer][TF_SR_Deaths]++;
			}
			
			if (TF2_IsValidClass(iClassAttacker)) {
				g_iTF2Stats[iClassAttacker][TF_SR_Kills]++;
			}
			
			if (TF2_IsValidClass(iClassAssister)) {
				g_iTF2Stats[iClassAssister][TF_SR_Assists]++;
			}
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	if (g_bSetTransmit) {
		SDKHook(iClient, SDKHook_SetTransmit, Hook_SetTransmit);
	}
	
	g_iLastCommand[iClient] = -1;
	g_bStealthed[iClient] = false;
	g_bDisconnectFaked[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
	g_iLastCommand[iClient] = -1;
	g_bStealthed[iClient] = false;
	g_bDisconnectFaked[iClient] = false;
}

public void OnEntityCreated(int iEntity, const char[] szClassName)
{
	if (StrContains(szClassName, "player_manager", false) == -1) {
		return;
	}
	
	g_iPlayerManager = iEntity;
	SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PlayerManagerThinkPost);
}

public void Hook_PlayerManagerThinkPost(int iEntity)
{
	LoopValidPlayers(iClient) {
		SetEntProp(iEntity, Prop_Send, "m_bConnected", !g_bStealthed[iClient], _, iClient);
	}
}

public Action Hook_SetTransmit(int iEntity, int iClient)
{
	if (iEntity == iClient || iEntity < 1 || iEntity > MaxClients) {
		return Plugin_Continue;
	}
	
	if(!g_bSetTransmit) {
		SDKUnhook(iEntity, SDKHook_SetTransmit, Hook_SetTransmit);
		SDKUnhook(iClient, SDKHook_SetTransmit, Hook_SetTransmit);
		return Plugin_Continue;
	}
	
	if (!g_bStealthed[iEntity]) {
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

stock bool PrintCustomStatus(int iClient)
{
	g_iLastCommand[iClient] = GetTime();
	
	if (GetStealthCount() < 1) {
		return false;
	}
	
	if (!g_bDataCached) {
		CacheInformation(0);
	}
	
	PrintToConsole(iClient, "hostname: %s", g_szHostName);
	PrintToConsole(iClient, g_szVersion);
	
	bool bTF2 = false;
	
	
	if (!StrEqual(g_szGameName, "tf", false)) {
		PrintToConsole(iClient, "udp/ip  : %s:%d", g_szServerIP, g_iServerPort);
		PrintToConsole(iClient, "os      : %s", g_bWindows ? "Windows" : "Linux");
		PrintToConsole(iClient, "type    : community dedicated");
		PrintToConsole(iClient, "map     : %s", g_szCurrentMap);
		PrintToConsole(iClient, "players : %d humans, %d bots %s (not hibernating)\n", GetPlayerCount(), GetBotCount(), g_szMaxPlayers);
		PrintToConsole(iClient, "# userid name uniqueid connected ping loss state rate");
	} else {
		bTF2 = true;
		
		PrintToConsole(iClient, "udp/ip  : %s:%d  (public ip: %s)", g_szServerIP, g_iServerPort, g_szServerIP);
		PrintToConsole(iClient, g_szSteamId);
		PrintToConsole(iClient, g_szAccount);
		PrintToConsole(iClient, "map     : %s at: 0 x, 0 y, 0 z", g_szCurrentMap);
		PrintToConsole(iClient, "tags    : %s", g_szTags);
		PrintToConsole(iClient, "players : %d humans, %d bots %s", GetPlayerCount(), GetBotCount(), g_szMaxPlayers);
		PrintToConsole(iClient, "edicts  : %d used of 2048 max", GetEntityCount());
		PrintToConsole(iClient, "         Spawns Points Kills Deaths Assists");
		
		PrintToConsole(iClient, "Scout         %d      %d     %d      %d       %d", 
			g_iTF2Stats[TFClass_Scout][TF_SR_Spawns], g_iTF2Stats[TFClass_Scout][TF_SR_Points], g_iTF2Stats[TFClass_Scout][TF_SR_Kills], 
			g_iTF2Stats[TFClass_Scout][TF_SR_Deaths], g_iTF2Stats[TFClass_Scout][TF_SR_Assists]);
		
		PrintToConsole(iClient, "Sniper        %d      %d     %d      %d       %d", 
			g_iTF2Stats[TFClass_Sniper][TF_SR_Spawns], g_iTF2Stats[TFClass_Sniper][TF_SR_Points], g_iTF2Stats[TFClass_Sniper][TF_SR_Kills], 
			g_iTF2Stats[TFClass_Sniper][TF_SR_Deaths], g_iTF2Stats[TFClass_Sniper][TF_SR_Assists]);
		
		PrintToConsole(iClient, "Soldier       %d      %d     %d      %d       %d", 
			g_iTF2Stats[TFClass_Soldier][TF_SR_Spawns], g_iTF2Stats[TFClass_Soldier][TF_SR_Points], g_iTF2Stats[TFClass_Soldier][TF_SR_Kills], 
			g_iTF2Stats[TFClass_Soldier][TF_SR_Deaths], g_iTF2Stats[TFClass_Soldier][TF_SR_Assists]);
		
		PrintToConsole(iClient, "Demoman       %d      %d     %d      %d       %d", 
			g_iTF2Stats[TFClass_DemoMan][TF_SR_Spawns], g_iTF2Stats[TFClass_DemoMan][TF_SR_Points], g_iTF2Stats[TFClass_DemoMan][TF_SR_Kills], 
			g_iTF2Stats[TFClass_DemoMan][TF_SR_Deaths], g_iTF2Stats[TFClass_DemoMan][TF_SR_Assists]);
		
		PrintToConsole(iClient, "Medic         %d      %d     %d      %d       %d", 
			g_iTF2Stats[TFClass_Medic][TF_SR_Spawns], g_iTF2Stats[TFClass_Medic][TF_SR_Points], g_iTF2Stats[TFClass_Medic][TF_SR_Kills], 
			g_iTF2Stats[TFClass_Medic][TF_SR_Deaths], g_iTF2Stats[TFClass_Medic][TF_SR_Assists]);
		
		PrintToConsole(iClient, "Heavy         %d      %d     %d      %d       %d", 
			g_iTF2Stats[TFClass_Heavy][TF_SR_Spawns], g_iTF2Stats[TFClass_Heavy][TF_SR_Points], g_iTF2Stats[TFClass_Heavy][TF_SR_Kills], 
			g_iTF2Stats[TFClass_Heavy][TF_SR_Deaths], g_iTF2Stats[TFClass_Heavy][TF_SR_Assists]);
		
		PrintToConsole(iClient, "Pyro          %d      %d     %d      %d       %d", 
			g_iTF2Stats[TFClass_Pyro][TF_SR_Spawns], g_iTF2Stats[TFClass_Pyro][TF_SR_Points], g_iTF2Stats[TFClass_Pyro][TF_SR_Kills], 
			g_iTF2Stats[TFClass_Pyro][TF_SR_Deaths], g_iTF2Stats[TFClass_Pyro][TF_SR_Assists]);
		
		PrintToConsole(iClient, "Spy           %d      %d     %d      %d       %d", 
			g_iTF2Stats[TFClass_Spy][TF_SR_Spawns], g_iTF2Stats[TFClass_Spy][TF_SR_Points], g_iTF2Stats[TFClass_Spy][TF_SR_Kills], 
			g_iTF2Stats[TFClass_Spy][TF_SR_Deaths], g_iTF2Stats[TFClass_Spy][TF_SR_Assists]);
		
		PrintToConsole(iClient, "Engineer      %d      %d     %d      %d       %d\n", 
			g_iTF2Stats[TFClass_Engineer][TF_SR_Spawns], g_iTF2Stats[TFClass_Engineer][TF_SR_Points], g_iTF2Stats[TFClass_Engineer][TF_SR_Kills], 
			g_iTF2Stats[TFClass_Engineer][TF_SR_Deaths], g_iTF2Stats[TFClass_Engineer][TF_SR_Assists]);
		
		PrintToConsole(iClient, "# userid name                uniqueid            connected ping loss state");
	}
	
	char szAuthId[64]; char szTime[9]; char szRate[9]; char szName[MAX_NAME_LENGTH];
	
	LoopValidClients(i) {
		if (g_bStealthed[i]) {
			continue;
		}
		
		Format(szName, sizeof(szName), "\"%N\"", i);
		
		if (bTF2) {
			GetClientAuthId(i, AuthId_Steam3, szAuthId, 64);
			if (!IsFakeClient(i)) {
				FormatShortTime(RoundToFloor(GetClientTime(i)), szTime, 9);
				PrintToConsole(iClient, "# %6d %-19s %19s %9s %4d %4d active", GetClientUserId(i), szName, szAuthId, szTime, GetPing(i), GetLoss(i));
			} else {
				PrintToConsole(iClient, "# %6d %-19s %19s                     active", GetClientUserId(i), szName, szAuthId);
			}
		} else {
			if (!IsFakeClient(i)) {
				GetClientAuthId(i, AuthId_Steam2, szAuthId, 64);
				GetClientInfo(i, "rate", szRate, 9);
				FormatShortTime(RoundToFloor(GetClientTime(i)), szTime, 9);
				
				PrintToConsole(iClient, "# %d %d %s %s %s %d %d active %s", GetClientUserId(i), i, szName, szAuthId, szTime, GetPing(i), GetLoss(i), szRate);
			} else {
				PrintToConsole(iClient, "#%d %s BOT active %d", i, szName, g_iTickRate);
			}
		}
	}
	
	if (!bTF2) {
		PrintToConsole(iClient, "#end");
	}
	
	return true;
}

public void CacheInformation(any anything)
{
	bool bSecure = false; bool bSteamWorks; bool bSteamTools;
	char szStatus[512]; char szBuffer[512]; ServerCommandEx(szStatus, sizeof(szStatus), "status");
	
	g_iTickRate = RoundToZero(1.0 / GetTickInterval());
	
	g_bWindows = StrContains(szStatus, "os      :  Windows", true) != -1;
	g_cvHostName.GetString(g_szHostName, sizeof(g_szHostName));
	g_iServerPort = g_cvHostPort.IntValue;
	
	#if defined _SteamWorks_Included || defined _steamtools_included
	bSteamWorks = LibraryExists("SteamWorks");
	bSteamTools = LibraryExists("SteamTools");
	
	if (bSteamWorks || bSteamTools) {
		int iSIP[4];
		
		if (bSteamWorks) {
			SteamWorks_GetPublicIP(iSIP);
			bSecure = SteamWorks_IsVACEnabled();
		} else if (bSteamTools) {
			Steam_GetPublicIP(iSIP);
			bSecure = Steam_IsVACEnabled();
		}
		
		Format(g_szServerIP, sizeof(g_szServerIP), "%d.%d.%d.%d", iSIP[0], iSIP[1], iSIP[2], iSIP[3]);
	}
	#endif
	
	if (!bSteamWorks && !bSteamTools) {
		int iServerIP = g_cvHostIP.IntValue;
		Format(g_szServerIP, sizeof(g_szServerIP), "%d.%d.%d.%d", iServerIP >>> 24 & 255, iServerIP >>> 16 & 255, iServerIP >>> 8 & 255, iServerIP & 255);
	}
	
	Regex rRegex = null;
	int iMatches = 0;
	
	if (StrEqual(g_szGameName, "csgo", false)) {
		rRegex = CompileRegex("version (.*?) secure");
		
		iMatches = rRegex.Match(szStatus);
		
		if (iMatches < 1) {
			delete rRegex;
			
			if (!bSteamWorks && !bSteamTools) {
				bSecure = false;
			}
			
			rRegex = CompileRegex("version (.*?) insecure");
			iMatches = rRegex.Match(szStatus);
			
		} else if (!bSteamWorks && !bSteamTools) {
			bSecure = true;
		}
		
		if (iMatches > 0) {
			rRegex.GetSubString(0, szBuffer, sizeof(szBuffer));
		}
		
		delete rRegex;
		
		char szSplit[2][64];
		
		if (ExplodeString(szBuffer, "/", szSplit, 2, sizeof(szSplit)) < 1) {
			return;
		}
		
		Format(g_szVersion, sizeof(g_szVersion), "%s %s", szSplit[0], bSecure ? "secure" : "insecure");
	} else if (StrEqual(g_szGameName, "tf", false)) {
		rRegex = CompileRegex("version.*");
		iMatches = rRegex.Match(szStatus);
		
		if (iMatches > 0) {
			rRegex.GetSubString(0, g_szVersion, sizeof(g_szVersion));
		}
		
		delete rRegex;
		
		rRegex = CompileRegex("account.*");
		iMatches = rRegex.Match(szStatus);
		
		if (iMatches > 0) {
			rRegex.GetSubString(0, g_szAccount, sizeof(g_szAccount));
		}
		
		delete rRegex;
		
		rRegex = CompileRegex("steamid.*");
		iMatches = rRegex.Match(szStatus);
		
		if (iMatches > 0) {
			rRegex.GetSubString(0, g_szSteamId, sizeof(g_szSteamId));
		}
		
		delete rRegex;
	}
	
	rRegex = CompileRegex("\\((.*? max)\\)");
	iMatches = rRegex.Match(szStatus);
	
	if (iMatches > 0) {
		rRegex.GetSubString(1, szBuffer, sizeof(szBuffer));
	}
	
	delete rRegex;
	
	Format(g_szMaxPlayers, sizeof(g_szMaxPlayers), "(%s)", szBuffer);
	
	g_bDataCached = true;
}

stock bool IsValidClient(int iClient, bool bIgnoreBots = true)
{
	if (iClient < 1 || iClient > MaxClients) {
		return false;
	}
	
	if (!IsClientInGame(iClient)) {
		return false;
	}
	
	if (IsFakeClient(iClient) && bIgnoreBots) {
		return false;
	}
	
	return true;
}

stock bool IsClientStealthWorthy(int iClient) {
	return CheckCommandAccess(iClient, "admin_stealth", ADMFLAG_KICK);
}

stock int GetPlayerCount()
{
	int iCount = 0;
	
	LoopValidPlayers(iClient) {
		if (g_bStealthed[iClient]) {
			continue;
		}
		
		iCount++;
	}
	
	return iCount;
}

stock int GetBotCount()
{
	int iCount = 0;
	
	LoopValidClients(iClient) {
		if (!IsFakeClient(iClient)) {
			continue;
		}
		
		iCount++;
	}
	
	return iCount;
}

stock int GetStealthCount()
{
	int iCount = 0;
	
	LoopValidClients(iClient) {
		if (!g_bStealthed[iClient]) {
			continue;
		}
		
		iCount++;
	}
	
	return iCount;
}

stock int GetLoss(int iClient) {
	return RoundFloat(GetClientAvgLoss(iClient, NetFlow_Both));
}

stock int GetPing(int iClient)
{
	float fPing = GetClientLatency(iClient, NetFlow_Both);
	fPing *= 1000.0;
	
	return RoundFloat(fPing);
}

stock bool TF2_IsValidClass(int iClass) {
	return iClass < 10 && iClass > 0;
}

stock int TF2_GetPlayerClass(int iClient)
{
	if (!IsValidClient(iClient, false)) {
		return -1;
	}
	
	if (!HasEntProp(iClient, Prop_Send, "m_iClass")) {
		return -1;
	}
	
	return GetEntProp(iClient, Prop_Send, "m_iClass");
}

// Thanks Necavi - https://forums.alliedmods.net/showthread.php?p=1796351
stock void FormatShortTime(int iTime, char[] szOut, int iSize)
{
	int iTemp = iTime % 60;
	
	Format(szOut, iSize, "%02d", iTemp);
	iTemp = (iTime % 3600) / 60;
	
	Format(szOut, iSize, "%02d:%s", iTemp, szOut);
	
	iTemp = (iTime % 86400) / 3600;
	
	if (iTemp > 0) {
		Format(szOut, iSize, "%d%:s", iTemp, szOut);
	}
}

public int Native_IsClientStealthed(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	
	return g_bStealthed[iClient];
} 