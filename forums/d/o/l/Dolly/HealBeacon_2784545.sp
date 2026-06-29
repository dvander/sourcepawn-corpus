#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>
#include <adminmenu>
#include <clientprefs>
#include <HealBeacon>

#define PLUGIN_DESCRIPTION "Sets beacon to random players and damage whoever is far from them"
#define PLUGIN_VERSION "1.001"
#define PLUGIN_PREFIX "{fullred}[Heal Beacon] {white}"

int g_LaserSprite = -1;
int g_HaloSprite = -1;

int g_BeaconPlayer[MAXPLAYERS+1] =  { 0, ... };
int EntityPointHurt = -1;
int g_iNeon[MAXPLAYERS+1] = {-1, ...};
int g_iClientBeaconColor[MAXPLAYERS+1][4];
int g_iClientNeonColor[MAXPLAYERS+1][4];
int g_iHealth[MAXPLAYERS+1] = -1;


float g_fClientDistance[MAXPLAYERS+1] = {1.0, ...};


int iCount[MAXPLAYERS+1] = {0, ...};
int iCountdown = 10;



int g_BeaconColor[4] =  {255, 56, 31, 255};

int g_ColorWhite[4] =  {255, 255, 255, 255};
int g_ColorRed[4] =  {255, 0, 0, 255};
int g_ColorLime[4] =  {0, 255, 0, 255};
int g_ColorBlue[4] =  {0, 0, 255, 255};
int g_ColorYellow[4] =  {255, 255, 0, 255};
int g_ColorCyan[4] =  {0, 255, 255, 255};
int g_ColorGold[4] =  {255, 215, 0, 255};

int iRandomsCount;

bool g_bRoundStart;
bool g_bRoundEnd;
bool g_bIsDone;
bool g_bHasNeon[MAXPLAYERS+1];
bool g_bModeIsEnabled;
bool g_bMaxHealth[MAXPLAYERS+1];
bool g_bNoBeacon;
bool g_bIsClientRandom[MAXPLAYERS+1];
bool g_bCloseToBeacon[MAXPLAYERS+1];
bool g_bIsHudEnabled[MAXPLAYERS+1] = true;

ConVar g_cvEnabled;
ConVar g_cvTimer;
ConVar g_cvDamage;
ConVar g_cvRandoms;

Handle BeaconTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle DistanceTimerHandle[MAXPLAYERS + 1] =  {INVALID_HANDLE, ...};

Handle g_HudMsg = INVALID_HANDLE;
Handle g_hRandomsMsg1 = INVALID_HANDLE;
Handle g_hRandomsMsg2 = INVALID_HANDLE;
Handle g_hRandomsMsg3 = INVALID_HANDLE;
Handle g_hRandomsMsg4 = INVALID_HANDLE;
Handle g_hRandomsMsg5 = INVALID_HANDLE;

Handle g_hRoundStart_Timer = INVALID_HANDLE;
Handle g_hHudTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle g_hDistanceTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle g_hRandomsTimer = INVALID_HANDLE;
Handle g_hHudCookie = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "HealBeacon",
	author = "Dolly",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://nide.gg"
};

public void OnPluginStart()
{
	g_cvEnabled = CreateConVar("sm_enable_healbeacon", "0", PLUGIN_DESCRIPTION);
	g_cvTimer = CreateConVar("sm_beacon_timer", "20.0", "The time that will start picking random players at round start");
	g_cvDamage = CreateConVar("sm_beacon_damage", "5", "The damage that the heal beacon will give");
	g_cvRandoms = CreateConVar("sm_healbeacon_randoms", "2", "How many random players should get the heal beacon");
	
	g_cvEnabled.AddChangeHook(OnConVarChange);
	g_cvRandoms.AddChangeHook(OnRandomsConVarChange);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	
	RegAdminCmd("sm_healbeacon", Command_Menu, ADMFLAG_CONVARS, "Shows healbeacon menu");
	RegAdminCmd("sm_beacon_distance", Command_Distance, ADMFLAG_CONVARS, "Change beacon distance");
	RegAdminCmd("sm_replacebeacon", Command_ReplaceBeacon, ADMFLAG_BAN, "Replace an already heal beaconed player with another one");
	RegAdminCmd("sm_addnewbeacon", Command_AddNewBeacon, ADMFLAG_BAN, "Add a new heal beaconed player");
	RegAdminCmd("sm_removebeacon", Command_RemoveBeacon, ADMFLAG_BAN, "Remove heal beacon player");
	RegAdminCmd("sm_checkdistance", Command_CheckDistance, ADMFLAG_BAN, "...");
	RegConsoleCmd("sm_healbeaconhud", Command_HealBeaconHud);
	
	g_hHudCookie = RegClientCookie("HudCookie", "Hud Cookie", CookieAccess_Public);
	
	g_HudMsg = CreateHudSynchronizer();
	g_hRandomsMsg1 = CreateHudSynchronizer();
	g_hRandomsMsg2 = CreateHudSynchronizer();
	g_hRandomsMsg3 = CreateHudSynchronizer();
	g_hRandomsMsg4 = CreateHudSynchronizer();
	g_hRandomsMsg5 = CreateHudSynchronizer();
	
	LoadTranslations("common.phrases");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			OnClientPutInServer(i);
			if(AreClientCookiesCached(i))
			{
				OnClientCookiesCached(i);
			}
		}
	}
	
	AutoExecConfig();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsPlayerRandom", Native_Player);
	
	RegPluginLibrary("HealBeacon");
	
	return APLRes_Success;
}

public int Native_Player(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	
	return g_bIsClientRandom[client];
}

public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	if (StringToInt(newValue) >= 1 && StringToInt(oldValue) < 1)
	{
		CPrintToChatAll("%sHeal Beacon has been {yellow}enabled for the next round.", PLUGIN_PREFIX);
	}
	if (StringToInt(newValue) < 1 && StringToInt(oldValue) >= 1)
	{
		CPrintToChatAll("%sHeal beacon has been disabled", PLUGIN_PREFIX);
	}
}

public void OnRandomsConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	if(StringToInt(newValue) > 5 || StringToInt(newValue) <= 0)
	{
		g_cvRandoms.IntValue = 2;
	}
}

public void OnClientPutInServer(int client)
{
	g_bIsHudEnabled[client] = true;
}

public void OnClientCookiesCached(int client)
{
	char sValue[2];
	GetClientCookie(client, g_hHudCookie, sValue, 2);
	
	g_bIsHudEnabled[client] = view_as<bool>(StringToInt(sValue));
}

public void OnMapStart()
{
	g_LaserSprite = PrecacheModel("sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vtf");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{	
	g_bIsDone = false;
		
	g_bModeIsEnabled = false;
	
	g_bNoBeacon = false;
	
	iRandomsCount = 0;
	
	if(GetConVarBool(g_cvEnabled))
	{
		g_bRoundStart = true;
		g_bRoundEnd = false;
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				DeleteAllHandles(i);
				RemoveNeon(i);
				ResetValues(i);
				g_fClientDistance[i] = 400.0;
				g_BeaconPlayer[i] = 0;
				g_iClientBeaconColor[i] = g_BeaconColor;
				g_bIsClientRandom[i] = false;
				g_iHealth[i] = 0;
				g_bMaxHealth[i] = true;
				g_bHasNeon[i] = false;
				SetEntProp(i, Prop_Data, "m_iMaxHealth", 120);
			}
		}
	
		g_hRoundStart_Timer = CreateTimer(GetConVarFloat(g_cvTimer), RoundStart_Timer);
	}
	
	EntityPointHurt = -1;
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(g_bRoundStart)
	{
		g_bRoundStart = false;
		g_bRoundEnd = true;
		
		delete g_hRandomsTimer;
		
		for (int i = 1; i <= MaxClients; i++)
		{			
			if(IsValidClient(i) && g_bIsClientRandom[i])
				g_bIsClientRandom[i] = false;
		}	
		
		delete g_hRoundStart_Timer;
	}
	
	return Plugin_Continue;
}
	
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client) && g_bIsClientRandom[client] && GetCurrentRandoms() >= 1)
	{
		RemoveRandom(client);
		CPrintToChatAll("%sPlayer %N has died with the heal beacon", PLUGIN_PREFIX, client);
	}
	else if(IsValidClient(client) && g_bIsClientRandom[client] && GetCurrentRandoms() <= 0)
	{
		RemoveRandom(client);
		CPrintToChatAll("%sPlayer %N has died with the heal beacon", PLUGIN_PREFIX, client);
		EndRound();
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int newteam = GetEventInt(event, "team");
	
	if(IsValidClient(client) && g_bIsClientRandom[client] && newteam == 1 && GetCurrentRandoms() >= 1)
	{
		RemoveRandom(client);
		CPrintToChatAll("%s%N has moved to the Spec team with the heal beacon", PLUGIN_PREFIX, client);
	}
	else if(IsValidClient(client) && g_bIsClientRandom[client] && newteam == 1 && GetCurrentRandoms() <= 0)
	{
		RemoveRandom(client);
		CPrintToChatAll("%s%N has moved to the Spec team with the heal beacon", PLUGIN_PREFIX, client);
		EndRound();
	}
	
	return Plugin_Continue;
} 
	
public Action RoundStart_Timer(Handle timer)
{
	if(GetConVarBool(g_cvEnabled))
	{
	
		if(g_cvRandoms.IntValue == 1)
		{
			GetRandomPlayers();
		}
		else
		{
			g_hRandomsTimer = CreateTimer(1.0, RandomsTimer, _, TIMER_REPEAT);
		}
		

		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				g_hHudTimer[i] = CreateTimer(1.0, Hud_Counter, GetClientSerial(i), TIMER_REPEAT);
				g_hDistanceTimer[i] = CreateTimer(10.0, Distance_Timer, GetClientSerial(i));
			}
		}	
	}
	
	g_hRoundStart_Timer = null;
	return Plugin_Handled;
}

public Action Hud_Counter(Handle timer, int clientserial)
{
	int client = GetClientFromSerial(clientserial);
	
	if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		ShowSyncHudText(client, g_HudMsg, "WARNING: DON'T BE FAR AWAY FROM THE BEACONED PLAYERS OR ELSE YOU WILL GET DAMAGED IN %d", iCountdown - iCount[client]);
	}
	iCount[client]++;
	
	if(iCount[client] >= 10)
	{
		g_hHudTimer[client] = null;
		return Plugin_Stop;
	}
	
	if(g_bRoundEnd)
	{
		g_hHudTimer[client] = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action RandomsTimer(Handle timer)
{
	GetRandomPlayers();
	
	iRandomsCount++;
	
	if(iRandomsCount >= g_cvRandoms.IntValue)
	{
		g_hRandomsTimer = null;
		return Plugin_Stop;
	}
	
	if(g_bRoundEnd)
	{
		g_hRandomsTimer = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Distance_Timer(Handle timer, int clientserial)
{
	int client = GetClientFromSerial(clientserial);
	
	if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
		DistanceTimerHandle[client] = CreateTimer(1.0, DistanceChecker_Timer, GetClientSerial(client), TIMER_REPEAT);
	
	if(!IsValidClient(client))
	{
		g_hDistanceTimer[client] = null;
		return Plugin_Stop;
	}
	
	if(g_bRoundEnd)
	{
		g_hDistanceTimer[client] = null;
		return Plugin_Stop;
	}
	
	g_hDistanceTimer[client] = null;
	return Plugin_Handled;
}

public Action DistanceChecker_Timer(Handle timer, int clientserial)
{
	int client = GetClientFromSerial(clientserial);
	
	if(GetCurrentRandoms() >= 1)
	{	
		ArrayList g_aRandomPlayers = new ArrayList();
		g_aRandomPlayers.Clear();
		
		for (int random = 1; random <= MaxClients; random++)
		{
			if(IsClientRandom(random))
			{
				g_aRandomPlayers.Push(random);
			}
		}
		
		g_bCloseToBeacon[client] = false;
		g_bMaxHealth[client] = false;
		
		if(IsClientRandom(client))
		{
			if(!g_bMaxHealth[client])
			{
				if(GetEntProp(client, Prop_Send, "m_iHealth") < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
				{
					SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + 1);
									
					if(GetEntProp(client, Prop_Send, "m_iHealth") == GetEntProp(client, Prop_Data, "m_iMaxHealth"))
					{
						g_bMaxHealth[client] = true;
					}
				}
			}
		}
			
		if(IsValidClient(client) && g_bIsHudEnabled[client])
		{
			if(GetCurrentRandoms() == 1)
			{
				SetHudTextParams(0.2, 0.0, 1.0, 0, 128, 235, 128);
				ShowSyncHudText(client, g_hRandomsMsg1, "Heal Beacon #1 - %N", g_aRandomPlayers.Get(0));
			}	
			else if(GetCurrentRandoms() == 2)
			{
				SetHudTextParams(0.2, 0.0, 1.0, 255, 128, 255, 255);
				ShowSyncHudText(client, g_hRandomsMsg1, "Heal Beacon #1 - %N", g_aRandomPlayers.Get(0));
				SetHudTextParams(0.2, 0.05, 1.0, 0, 128, 235, 128);
				ShowSyncHudText(client, g_hRandomsMsg2, "Heal Beacon #2 - %N", g_aRandomPlayers.Get(1));
			}
			else if(GetCurrentRandoms() == 3)
			{
				SetHudTextParams(0.2, 0.0, 1.0, 255, 128, 255, 255);
				ShowSyncHudText(client, g_hRandomsMsg1, "Heal Beacon #1 - %N", g_aRandomPlayers.Get(0));
				SetHudTextParams(0.2, 0.05, 1.0, 232, 216, 255, 255);
				ShowSyncHudText(client, g_hRandomsMsg2, "Heal Beacon #2 - %N", g_aRandomPlayers.Get(1));
				SetHudTextParams(0.2, 0.1, 1.0, 0, 128, 128, 255);
				ShowSyncHudText(client, g_hRandomsMsg3, "Heal Beacon #3 - %N", g_aRandomPlayers.Get(2));
			}
			else if(GetCurrentRandoms() == 4)
			{
				SetHudTextParams(0.2, 0.0, 1.0, 0, 170, 130, 150);
				ShowSyncHudText(client, g_hRandomsMsg1, "Heal Beacon #1 - %N", g_aRandomPlayers.Get(0));
				SetHudTextParams(0.2, 0.05, 1.0, 255, 31, 255, 255);
				ShowSyncHudText(client, g_hRandomsMsg2, "Heal Beacon #2 - %N", g_aRandomPlayers.Get(1));
				SetHudTextParams(0.2, 0.1, 1.0, 255, 255, 255, 255);
				ShowSyncHudText(client, g_hRandomsMsg3, "Heal Beacon #3 - %N", g_aRandomPlayers.Get(2));
				SetHudTextParams(0.2, 0.15, 1.0, 255, 231, 128, 255);
				ShowSyncHudText(client, g_hRandomsMsg4, "Heal Beacon #4 - %N", g_aRandomPlayers.Get(3));
			}
			else if(GetCurrentRandoms() == 5)
			{
				SetHudTextParams(0.2, 0.0, 1.0, 255, 15, 0, 255);
				ShowSyncHudText(client, g_hRandomsMsg1, "Heal Beacon #1 - %N", g_aRandomPlayers.Get(0));
				SetHudTextParams(0.2, 0.05, 1.0, 193, 255, 0, 255);
				ShowSyncHudText(client, g_hRandomsMsg2, "Heal Beacon #2 - %N", g_aRandomPlayers.Get(1));
				SetHudTextParams(0.2, 0.1, 1.0, 128, 0, 255, 255);
				ShowSyncHudText(client, g_hRandomsMsg3, "Heal Beacon #3 - %N", g_aRandomPlayers.Get(2));
				SetHudTextParams(0.2, 0.15, 1.0, 212, 255, 0, 255);
				ShowSyncHudText(client, g_hRandomsMsg4, "Heal Beacon #4 - %N", g_aRandomPlayers.Get(3));
				SetHudTextParams(0.2, 0.2, 1.0, 255, 128, 0, 255);
				ShowSyncHudText(client, g_hRandomsMsg5, "Heal Beacon #5 - %N", g_aRandomPlayers.Get(4));
			}
		}		
		
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3 && !g_bIsClientRandom[client])
		{
			if(!g_bModeIsEnabled)
			{
				if(GetCurrentRandoms() == 1)					
					CheckDistanceForNoMode(client, g_aRandomPlayers.Get(0));
						
				else if(GetCurrentRandoms() == 2)
					CheckDistanceForNoModeForTwo(client, g_aRandomPlayers.Get(0), g_aRandomPlayers.Get(1));
						
				else if(GetCurrentRandoms() == 3)
					CheckDistanceForNoModeForThree(client, g_aRandomPlayers.Get(0), g_aRandomPlayers.Get(1), g_aRandomPlayers.Get(2));
						
				else if(GetCurrentRandoms() == 4)
					CheckDistanceForNoModeForFour(client, g_aRandomPlayers.Get(0), g_aRandomPlayers.Get(1), g_aRandomPlayers.Get(2), g_aRandomPlayers.Get(3));
						
				else if(GetCurrentRandoms() == 5)
					CheckDistanceForNoModeForFive(client, g_aRandomPlayers.Get(0), g_aRandomPlayers.Get(1), g_aRandomPlayers.Get(2), g_aRandomPlayers.Get(3), g_aRandomPlayers.Get(4));
			}
			else
			{
				if(GetCurrentRandoms() == 1)					
					CheckDistanceForMode(client, g_aRandomPlayers.Get(0));
						
				else if(GetCurrentRandoms() == 2)
					CheckDistanceForModeForTwo(client, g_aRandomPlayers.Get(0), g_aRandomPlayers.Get(1));
						
				else if(GetCurrentRandoms() == 3)
					CheckDistanceForModeForThree(client, g_aRandomPlayers.Get(0), g_aRandomPlayers.Get(1), g_aRandomPlayers.Get(2));
					
				else if(GetCurrentRandoms() == 4)
					CheckDistanceForModeForFour(client, g_aRandomPlayers.Get(0), g_aRandomPlayers.Get(1), g_aRandomPlayers.Get(2), g_aRandomPlayers.Get(3));
						
				else if(GetCurrentRandoms() == 5)
					CheckDistanceForModeForFive(client, g_aRandomPlayers.Get(0), g_aRandomPlayers.Get(1), g_aRandomPlayers.Get(2), g_aRandomPlayers.Get(3), g_aRandomPlayers.Get(4));
			}
		}
		else if(!IsValidClient(client))
		{
			DistanceTimerHandle[client] = null;
			return Plugin_Stop;
		}
		
		delete g_aRandomPlayers;
	}
	else if(GetCurrentRandoms() <= 0)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
		}
	}

	if(g_bRoundEnd)
	{
		DistanceTimerHandle[client] = null;
		return Plugin_Stop;
	}
		
	return Plugin_Continue;
}
						
public Action Command_Menu(int client, int args)
{
	if(GetConVarBool(g_cvEnabled))
	{
		if(!g_bNoBeacon)
		{
			if(!client)
			{
				ReplyToCommand(client, "%sCannot use this commnad from server rcon", PLUGIN_PREFIX);
				return Plugin_Handled;
			}
			
			if(g_bIsDone)
			{
				
				if(args < 1)
				{
					DisplayHealBeaconMenu(client);
					return Plugin_Handled;
				}
				
				char buffer[14];
				GetCmdArg(1, buffer, sizeof(buffer));
				
				int g_iTarget = FindTarget(client, buffer, false, false);
				
				if(IsValidClient(g_iTarget) && g_bIsClientRandom[g_iTarget])
				{
					DisplayActionsMenu(client, g_iTarget);
					return Plugin_Handled;
				}
				else
				{
					CReplyToCommand(client, "%sInvalid Player or arguement, Please put the current heal beaconed players", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
			}
			else if(!g_bIsDone)
			{
				CReplyToCommand(client, "%sNo one has become the beaconed player yet", PLUGIN_PREFIX);
				return Plugin_Handled;
			}
		}
		else
		{
			CReplyToCommand(client, "%sRound is about to end because there is no beaconed player alive", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
	}
	else
	{
		CReplyToCommand(client, "%sHeal beacon is disabled.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_Distance(int client, int args)
{
	if(GetConVarBool(g_cvEnabled))
	{
		if(!g_bNoBeacon)
		{
			if(g_bIsDone)
			{
				if(!client)
				{
					ReplyToCommand(client, "%sCannot use this command from server rcon", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				
				if(args < 2)
				{
					CReplyToCommand(client, "%sUsage: sm_beacon_distance <playername> <number>", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				
				char arg1[64], arg2[64];
				
				GetCmdArg(1, arg1, sizeof(arg1));
				GetCmdArg(2, arg2, sizeof(arg2));
				
				int g_iTarget = FindTarget(client, arg1, false, false);
				float num2 = StringToFloat(arg2);
				
				if(IsValidClient(g_iTarget))
				{	
					if(g_bIsClientRandom[g_iTarget])
					{
						g_fClientDistance[g_iTarget] = num2;
						CReplyToCommand(client, "%sSuccessfully changed {yellow}%N distance to {white}%f.", PLUGIN_PREFIX, g_iTarget, num2);
						return Plugin_Handled;
					}
					else
					{
						CReplyToCommand(client, "%sPlayer is dead or left the game", PLUGIN_PREFIX);
						return Plugin_Handled;
					}
				}
				else
				{
					CReplyToCommand(client, "%sUsage: sm_beacon_distance <HealBeaconed Player> <number>", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
			}
			else
			{
				CReplyToCommand(client, "%sNone has been detected as the beaconed player yet", PLUGIN_PREFIX);
				return Plugin_Handled;
			}
		}
		else
		{
			CReplyToCommand(client, "%sRound is about to end because there is no beaconed player alive", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
	}
	else
	{
		CReplyToCommand(client, "%sHeal beacon is not enabled.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
}

public Action Command_ReplaceBeacon(int client, int args)
{
	if(GetConVarBool(g_cvEnabled))
	{
		if(!g_bNoBeacon)
		{
			if(g_bIsDone)
			{
				if(args < 2)
				{
					CReplyToCommand(client, "%sUsage: sm_replacebeacon <HealBeacon Player> <Player>", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				
				
				char sArg1[20];
				char sArg2[60];
				
				GetCmdArg(1, sArg1, 20);
				GetCmdArg(2, sArg2, 60);
				
				int g_iRandomTarget = FindTarget(client, sArg1, false, false);
				int g_iTarget = FindTarget(client, sArg2, false, false);
				
				if(g_iTarget == -1)
				{
					return Plugin_Handled;
				}
				
				if(IsValidClient(g_iTarget) && g_bIsClientRandom[g_iTarget])
				{
					CReplyToCommand(client, "%sThe given player is already a beaconed player", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				
				if(GetClientUserId(g_iTarget) == 0 || GetClientUserId(g_iRandomTarget) == 0)
				{
					CReplyToCommand(client, "%sPlayer no longer available", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				
				if(IsValidClient(g_iRandomTarget) && g_bIsClientRandom[g_iRandomTarget])
				{
					if(IsValidClient(g_iTarget) && IsPlayerAlive(g_iTarget) && GetClientTeam(g_iTarget) == 3)
					{
						ApplyHealBeacon(client, g_iRandomTarget, g_iTarget);
						return Plugin_Handled;
					}
					else if(IsValidClient(g_iTarget) && !IsPlayerAlive(g_iTarget) || GetClientTeam(g_iTarget) < 3)
					{
						CReplyToCommand(client, "%sCannot choose a dead player or zombie", PLUGIN_PREFIX);
						return Plugin_Handled;
					}
				}
				else
				{
					CReplyToCommand(client, "%sUsage: sm_replacebeacon <HealBeaconed Player> <Player>", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
			}
			else
			{
				CReplyToCommand(client, "%sNo one has become a beaconed player yet", PLUGIN_PREFIX);
				return Plugin_Handled;
			}
		}
		else
		{
			CReplyToCommand(client, "%sRound is about to end because there is no beaconed player alive", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
	}
	else
	{
		CReplyToCommand(client, "%sHeal beacon is currently disabled", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_AddNewBeacon(int client, int args)
{
	if(GetConVarBool(g_cvEnabled))
	{
		if(!g_bNoBeacon)
		{
			if(g_bIsDone)
			{
				if(GetCurrentRandoms() < 5)
				{
					if(args < 1)
					{
						CReplyToCommand(client, "%sUsage: sm_addnewbeacon <player>", PLUGIN_PREFIX);
						return Plugin_Handled;
					}
					
					char sArg[32];
					GetCmdArg(1, sArg, 32);
					
					int g_iTarget = FindTarget(client, sArg, false, false);
					
					if(IsValidClient(g_iTarget))
					{
						if(g_bIsClientRandom[g_iTarget])
						{
							CReplyToCommand(client, "%sThe specified player is already a heal beaconed player.", PLUGIN_PREFIX);
							return Plugin_Handled;
						}
						else
						{
							g_bIsClientRandom[g_iTarget] = true;
							g_BeaconPlayer[g_iTarget] = 1;
							BeaconPlayerTimer(g_iTarget);
							CReplyToCommand(client, "%sSuccessfully added %N as a new heal beaconed player", PLUGIN_PREFIX, g_iTarget);
							return Plugin_Handled;
						}
					}
				}
				else if(GetCurrentRandoms() >= 5)
				{
					CReplyToCommand(client, "%sThe maximum number of heal beacon players is {yellow}5.", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				else
				{
					CReplyToCommand(client, "%sInvalid Player.", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
			}
			else
			{
				CReplyToCommand(client, "%sNone has become heal beaconed player yet", PLUGIN_PREFIX);
				return Plugin_Handled;
			}
		}
		else
		{
			CReplyToCommand(client, "%sRound is about to end.", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
	}
	else
	{
		CReplyToCommand(client, "%sHeal beacon is currently disabled.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_RemoveBeacon(int client, int args)
{
	if(GetConVarBool(g_cvEnabled))
	{
		if(!g_bNoBeacon)
		{
			if(g_bIsDone)
			{
				if(args < 1)
				{
					CReplyToCommand(client, "%sUsage: sm_removebeacon <HealBeaconed player>.", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
				
				char arg[32];
				GetCmdArg(1, arg, 32);
				
				int g_iTarget = FindTarget(client, arg, false, false);
				
				if(IsClientRandom(g_iTarget))
				{
					RemoveRandom(g_iTarget);
					CReplyToCommand(client, "%sSuccessfully removed beacon from %N.", PLUGIN_PREFIX, g_iTarget);
					return Plugin_Handled;
				}
				else if(!IsValidClient(g_iTarget))
				{
					CReplyToCommand(client, "%sNo matching client found.", PLUGIN_PREFIX);
					return Plugin_Handled;
				}
			}
			else
			{
				CReplyToCommand(client, "%sNo one has become the heal beaconed player.", PLUGIN_PREFIX);
				return Plugin_Handled;
			}
		}
		else
		{
			CReplyToCommand(client, "%sRound is about to end.", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
	}
	else
	{
		CReplyToCommand(client, "%sHeal beacon is currently disabled.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}
				
public Action Command_CheckDistance(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "Cannot use this command from server rcon");
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArg(1, arg, 32);
	
	int g_iTarget = FindTarget(client, arg, false, false);
	
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		if(IsValidClient(g_iTarget) && IsPlayerAlive(g_iTarget))
		{
			float distance = GetDistanceBetween(client, g_iTarget);
			CReplyToCommand(client, "%sThe distance between you and %N is %f", PLUGIN_PREFIX, g_iTarget, distance);
			return Plugin_Handled;
		}
		else if(!IsValidClient(g_iTarget))
		{
			CReplyToCommand(client, "%sno matching client was found", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
		else if(!IsPlayerAlive(g_iTarget))
		{
			CReplyToCommand(client, "%sThe specified player is dead.", PLUGIN_PREFIX);
			return Plugin_Handled;
		}
	}
	else if(!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "%sYou have to be alive to use this command.", PLUGIN_PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_HealBeaconHud(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "Cannot use this command from server rcon");
		return Plugin_Handled;
	}
	
	if(g_bIsHudEnabled[client])
	{
		g_bIsHudEnabled[client] = false;
	}
	else if(!g_bIsHudEnabled[client])
	{
		g_bIsHudEnabled[client] = true;
	}
	
	CReplyToCommand(client, "{fullred}[Heal Beacon] {white}Heal Beacon Hud has been {yellow}%s", !g_bIsHudEnabled[client] ? "Disabled" : "Enabled");
	
	char sValue[2];
	IntToString(g_bIsHudEnabled[client], sValue, 2);
	
	SetClientCookie(client, g_hHudCookie, sValue);
	
	return Plugin_Handled;
}	

public Action Beacon_Timer(Handle timer, int clientserial)
{
	int client = GetClientFromSerial(clientserial);
	
	if(IsClientRandom(client))
	{
		BeaconPlayer(client);
	}
	
	else if(!IsValidClient(client))
	{
		BeaconTimer[client] = null;
		return Plugin_Stop;
	}
	
	if(g_bRoundEnd)
	{
		BeaconTimer[client] = null;
		return Plugin_Stop;
	}
		
	return Plugin_Continue;
}

public int Menu_MainCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char buffer[32];
			
		menu.GetItem(param2, buffer, 32);
			
		int userid = StringToInt(buffer);
		int random = GetClientOfUserId(userid);
		
		if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) == 3 && g_bIsClientRandom[random])
		{
			DisplayActionsMenu(param1, random);
		}
		else if(!IsValidClient(random))
		{
			char item[32];
			menu.GetItem(param2, item, 32);
			if(StrEqual(item, "option2"))
			{
				return 0;
			}
			else
			{
				CPrintToChat(param1, "%sPlayer is dead or left the game", PLUGIN_PREFIX);
			}
		}
		
		char item[32];
		menu.GetItem(param2, item, 32);
		
		if(StrEqual(item, "option2"))
		{
			DisplaySettingsMenu(param1);
		}
	}
	else if(action == MenuAction_End)
		delete menu;
		
	return 0;
}

public int Menu_SettingsCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				DisplayBeaconDamageMenu(param1);
			}
			case 1:
			{
				DisplayBeaconTimerMenu(param1);
			}
			case 2:
			{
				if(!g_bModeIsEnabled)
				{
					CPrintToChat(param1, "%sBetter Damage Mode has been {yellow}enabled!", PLUGIN_PREFIX);
					g_bModeIsEnabled = true;
				}
					
				else if(g_bModeIsEnabled)
				{	
					CPrintToChat(param1, "%sBetter Damage Mode has been {yellow}disabled!", PLUGIN_PREFIX);
					g_bModeIsEnabled = false;
				}
					
				DisplaySettingsMenu(param1);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplayHealBeaconMenu(param1);
		}
	}
	else if(action == MenuAction_End)
		delete menu;
		
		
	return 0;
		
}

public int Menu_BeaconDamageCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char buf[32];
		menu.GetItem(param2, buf, 32);
		
		int num = StringToInt(buf);
		
		g_cvDamage.IntValue = num;
		
		CPrintToChat(param1, "%sBeacon Damage has been changed to %d", PLUGIN_PREFIX, num);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplaySettingsMenu(param1);
		}
	}
	else if(action == MenuAction_End)
		delete menu;
		
	return 0;
	
}

public int Menu_BeaconTimerCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char buf[32];
		menu.GetItem(param2, buf, 32);
		
		float num = StringToFloat(buf);
		
		g_cvTimer.FloatValue = num;
		
		CPrintToChat(param1, "%sBeacon First PickRandom Timer has been changed to %f", PLUGIN_PREFIX, num);
	}
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			DisplaySettingsMenu(param1);
		}
	}
	else if(action == MenuAction_End)
		delete menu;
		
	return 0;
	
}

public int Menu_ActionsCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char buffer[64];
		menu.GetItem(param2, buffer, 64);
		
		int userid = StringToInt(buffer);
		int random = GetClientOfUserId(userid);
		
		if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) == 3)
		{	
			switch(param2)
			{
				case 0:
				{
					RepickRandom(param1, random);
					CPrintToChat(param1, "%sSuccessfully repicked a random player.", PLUGIN_PREFIX);
					LogAction(param1, -1, "[Heal Beacon] \"%L\" has Repicked a random player.", param1);
					DisplayActionsMenu(param1, random);
				}
				
				case 1:
				{
					DisplayBeaconColorsMenu(param1, random);
				}
	
				case 2:
				{
					DisplayBeaconRadiusMenu(param1, random);
				}
			
				case 3:
				{
					if(!g_bHasNeon[random])
					{
						SetClientNeon(random);
						CPrintToChat(param1, "%sSuccessfully Enabled light on %N.", PLUGIN_PREFIX, random);
						LogAction(param1, random, "[Heal Beacon] \"%L\" has Enabled Light on \"%L\".", param1, random);
						DisplayActionsMenu(param1, random);
					}
					else if(g_bHasNeon[random])
					{
						RemoveNeon(random);
						CPrintToChat(param1, "%sSuccessfully Disabled light on %N.", PLUGIN_PREFIX, random);
						LogAction(param1, random, "[Heal Beacon] \"%L\" has Disabled Light on \"%L\".", param1, random);
						DisplayActionsMenu(param1, random);
					}
				}
	
				case 4:
				{
					DisplayNeonColorsMenu(param1, random);
				}
	
				case 5:
				{
					TeleportToRandom(param1, random);
					CPrintToChat(param1, "%sSuccessfully Teleported to %N.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" Teleported to \"%L\".", param1, random);
					DisplayActionsMenu(param1, random);
				}
				case 6:
				{
					TeleportToRandom(random, param1);
					CPrintToChat(param1, "%sSuccessfully Brought %N.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" Brought \"%L\".", param1, random);
					DisplayActionsMenu(param1, random);
				}
				case 7:
				{
					CPrintToChat(param1, "%sSuccessfully removed heal beacon from %N", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has removed heal beacon from \"%L\".", param1, random);
					RemoveRandom(random);
				}
				case 8:
				{
					CPrintToChat(param1, "%sSuccessfully Slayed %N.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has slayed \"%L\".", param1, random);
					ForcePlayerSuicide(random);
				}
			}
		}
		
		else 
		{
			CPrintToChat(param1, "%sThe player is dead or left the game", PLUGIN_PREFIX);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			DisplayHealBeaconMenu(param1);
		}
	}
	else if(action == MenuAction_End)
		delete menu;
		
	return 0;
}

public int Menu_BeaconColorsCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char buffer[32];
		menu.GetItem(param2, buffer, 32);
		
		int userid = StringToInt(buffer);
		int random = GetClientOfUserId(userid);
		
		if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) == 3 && g_bIsClientRandom[random])
		{
			switch(param2)
			{
				case 0:
				{
					DoProgressBeaconColor(random, g_ColorWhite);
					CPrintToChat(param1, "%sSuccessfully changed beacon color on %N to {white}White.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed beacon color on \"%L\" to White.", param1, random);
				}
				case 1:
				{
					DoProgressBeaconColor(random, g_ColorRed);
					CPrintToChat(param1, "%sSuccessfully changed beacon color on %N to {fullred}Red.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed beacon color on \"%L\" to Red.", param1, random);
				}
				case 2:
				{
					DoProgressBeaconColor(random, g_ColorLime);
					CPrintToChat(param1, "%sSuccessfully changed beacon color on %N to {lime}Lime.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed beacon color on \"%L\" to Lime.", param1, random);
				}
				case 3:
				{
					DoProgressBeaconColor(random, g_ColorBlue);
					CPrintToChat(param1, "%sSuccessfully changed beacon color on %N to {blue}Blue.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed beacon color on \"%L\" to Blue.", param1, random);
				}
				case 4:
				{
					DoProgressBeaconColor(random, g_ColorYellow);
					CPrintToChat(param1, "%sSuccessfully changed beacon color on %N to {yellow}Yellow.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed beacon color on \"%L\" to Yellow.", param1, random);
				}
				case 5:
				{
					DoProgressBeaconColor(random, g_ColorCyan);
					CPrintToChat(param1, "%sSuccessfully changed beacon color on %N to {cyan}Cyan.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed beacon color on \"%L\" to Cyan.", param1, random);
				}
				case 6:
				{
					DoProgressBeaconColor(random, g_ColorGold);
					CPrintToChat(param1, "%sSuccessfully changed beacon color on %N to {gold}Gold.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed beacon color on \"%L\" to Gold.", param1, random);
				}
			}
			
			DisplayBeaconColorsMenu(param1, random);
			
		}
		else
		{
			CPrintToChat(param1, "%sThe player is dead or left the game", PLUGIN_PREFIX);
		}
	}
	else if(action == MenuAction_End)
		delete menu;
		
	return 0;
}

public int Menu_NeonColorsCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char buffer[32];
		menu.GetItem(param2, buffer, 32);
		
		int userid = StringToInt(buffer);
		int random = GetClientOfUserId(userid);
		
		if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) == 3)
		{
			switch(param2)
			{
				case 0:
				{
					DoProgressNeonColor(random, g_ColorWhite);
					CPrintToChat(param1, "%sSuccessfully changed Light color on %N to {white}White.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed Light color on \"%L\" to White.", param1, random);
				}
				case 1:
				{
					DoProgressNeonColor(random, g_ColorRed);
					CPrintToChat(param1, "%sSuccessfully changed Light color on %N to {fullred}Red.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed Light color on \"%L\" to Red.", param1, random);
				}
				case 2:
				{
					DoProgressNeonColor(random, g_ColorLime);
					CPrintToChat(param1, "%sSuccessfully changed Light color on %N to {lime}Lime.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed Light color on \"%L\" to Lime.", param1, random);
				}
				case 3:
				{
					DoProgressNeonColor(random, g_ColorBlue);
					CPrintToChat(param1, "%sSuccessfully changed Light color on %N to {blue}Blue.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed Light color on \"%L\" to Blue.", param1, random);
				}
				case 4:
				{
					DoProgressNeonColor(random, g_ColorYellow);
					CPrintToChat(param1, "%sSuccessfully changed Light color on %N to {yellow}yellow.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed Light color on \"%L\" to Yellow.", param1, random);
				}
				case 5:
				{
					DoProgressNeonColor(random, g_ColorCyan);
					CPrintToChat(param1, "%sSuccessfully changed Light color on %N to {cyan}Cyan.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed Light color on \"%L\" to Cyan.", param1, random);
				}
				case 6:
				{
					DoProgressNeonColor(random, g_ColorGold);
					CPrintToChat(param1, "%sSuccessfully changed Light color on %N to {gold}Gold.", PLUGIN_PREFIX, random);
					LogAction(param1, random, "[Heal Beacon] \"%L\" has changed Light color on \"%L\" to Gold.", param1, random);
				}
			}
			
			DisplayNeonColorsMenu(param1, random);
			
		}
		else
		{
			CPrintToChat(param1, "%sThe player is dead or left the game", PLUGIN_PREFIX);
		}
	}
	else if(action == MenuAction_End)
		delete menu;
		
	return 0;
}

public int Menu_BeaconRadiusCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char buffer[32];
		menu.GetItem(param2, buffer, 32);
		
		int userid = StringToInt(buffer);
		int random = GetClientOfUserId(userid);
		
		if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) == 3 && g_bIsClientRandom[random])
		{
			switch(param2)
			{
				case 0:
				{
					g_fClientDistance[random] = 200.0;
				}
				case 1:
				{
					g_fClientDistance[random] = 400.0;
				}
				case 2:
				{
					g_fClientDistance[random] = 600.0;
				}
				case 3:
				{
					g_fClientDistance[random] = 800.0;
				}
				case 4:
				{
					g_fClientDistance[random] = 1000.0;
				}
				case 5:
				{
					g_fClientDistance[random] = 1500.0;
				}
			}
			
			DisplayBeaconRadiusMenu(param1, random);		
		}		
	}
	else if(action == MenuAction_End)
		delete menu;
		
	return 0;
}
	
void BeaconPlayerTimer(int client)
{	
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)		
			BeaconTimer[client] = CreateTimer(0.1, Beacon_Timer, GetClientSerial(client), TIMER_REPEAT);
}

void BeaconPlayer(int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3 && g_BeaconPlayer[client] != 0)
	{
		float fvec[3];
		GetClientAbsOrigin(client, fvec);
		fvec[2] += 10;
		
		TE_SetupBeamRingPoint(fvec, g_fClientDistance[client] - 10.0, g_fClientDistance[client], g_LaserSprite, g_HaloSprite, 0, 15, 0.1, 10.0, 0.0, g_iClientBeaconColor[client], 10, 0);
		TE_SendToAll();
			
		GetClientEyePosition(client, fvec);
		//EmitAmbientSound(Beacon_Sound, fvec, client, SNDLEVEL_RAIDSIREN);
	}
	else
	{
		return;
	}
}

float GetDistanceBetween(int origin, int target)
{
	float fOrigin[3], fTarget[3];
	
	GetEntPropVector(origin, Prop_Data, "m_vecOrigin", fOrigin);
	GetEntPropVector(target, Prop_Data, "m_vecOrigin", fTarget);
	
	return GetVectorDistance(fOrigin, fTarget);
}

void DealDamage(int client, int nDamage, int nDamageType = DMG_GENERIC)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && nDamage > 0)
    {
        EntityPointHurt = CreateEntityByName("point_hurt");
        if(EntityPointHurt != -1)
        {
            char sDamage[16];
            IntToString(nDamage, sDamage, sizeof(sDamage));

            char sDamageType[32];
            IntToString(nDamageType, sDamageType, sizeof(sDamageType));

            DispatchKeyValue(client,			"targetname",		"war3_hurtme");
            DispatchKeyValue(EntityPointHurt,		"DamageTarget",	"war3_hurtme");
            DispatchKeyValue(EntityPointHurt,		"Damage",				sDamage);
            DispatchKeyValue(EntityPointHurt,		"DamageType",		sDamageType);
            DispatchSpawn(EntityPointHurt);
            AcceptEntityInput(EntityPointHurt, "Hurt");
            DispatchKeyValue(EntityPointHurt,		"classname",		"point_hurt");
            DispatchKeyValue(client,			"targetname",		"war3_donthurtme");
            
            RemoveEdict(EntityPointHurt);
        }
        else
        {
       		return;
       	}
   }
}

void GetRandomPlayers()
{
	int g_iCountHumans = 0;
	int g_iClientsCount[MAXPLAYERS+1];
	
	for (int human = 1; human <= MaxClients; human++)
	{
		if(IsValidClient(human) && IsPlayerAlive(human) && GetClientTeam(human) == 3 && !g_bIsClientRandom[human])
		{
			g_iClientsCount[g_iCountHumans++] = human;
		}
	}
	
	if(g_iCountHumans >= 2)
	{

		int random = g_iClientsCount[GetRandomInt(0, g_iCountHumans - 1)];
		g_bIsClientRandom[random] = true;
		g_BeaconPlayer[random] = 1;
		BeaconPlayerTimer(random);
		CPrintToChatAll("%sPlayer %N has been a beaconed player", PLUGIN_PREFIX, random);
		g_bIsDone = true;
	}
	else
	{
		return;
	}
}

void RepickRandom(int client, int random)
{
	int g_iHumansCount = 0;
	int g_iHumans[MAXPLAYERS+1];
	int newRandom = -1;
	
	if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) == 3 && g_bIsClientRandom[random])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3 && !g_bIsClientRandom[i])
			{
				g_iHumans[g_iHumansCount++] = i;
			}
		}
		
		RemoveRandom(random);
		
		newRandom = g_iHumans[GetRandomInt(0, g_iHumansCount - 1)];
		
		if(IsValidClient(newRandom) && IsPlayerAlive(newRandom) && GetClientTeam(newRandom) == 3)
		{
			g_bIsClientRandom[newRandom] = true;
			g_BeaconPlayer[newRandom] = 1;
			BeaconPlayerTimer(newRandom);
			CPrintToChatAll("%sPlayer %N has been the new beaconed player instead of %N repicked by %N", PLUGIN_PREFIX, newRandom, random, client);
		}
		else if(!IsValidClient(newRandom) || !IsPlayerAlive(newRandom) || GetClientTeam(newRandom) != 3)
		{
			CPrintToChatAll("%sRandom Repick has failed!", PLUGIN_PREFIX);
		}
	}
	else
	{
		return;
	}
}

void ApplyHealBeacon(int client, int random, int newRandom)
{
	if(IsValidClient(random) && g_bIsClientRandom[random])
	{
		RemoveRandom(random);
		
		if(IsValidClient(newRandom) && !g_bIsClientRandom[newRandom])
		{
			g_bIsClientRandom[newRandom] = true;
			g_BeaconPlayer[newRandom] = 1;
			BeaconPlayerTimer(newRandom);
			CPrintToChatAll("%sPlayer {yellow}%N{fullred} has been {white}the new heal beaconed player as a replacement of {yellow}%N{white} replaced by Admin {yellow}%N{white}.", PLUGIN_PREFIX, newRandom, random, client);
		}
		else
		{
			return;
		}
	}
	else
	{
		return;
	}
}
			
void DisplayHealBeaconMenu(int client)
{
	Menu menu = new Menu(Menu_MainCallback);
	menu.SetTitle("Do Actions on the heal beaconed players");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3 && g_bIsClientRandom[i])
		{
			int userid = GetClientUserId(i);
			
			char info[64], buffer[32];
			Format(buffer, 32, "Do Actions on %N", GetClientOfUserId(userid));
			
			IntToString(userid, info, 64);
			
			menu.AddItem(info, buffer);
		}
	}
	
	menu.AddItem("option2", "Change Heal Beacon Settings");
	
	menu.Display(client, MENU_TIME_FOREVER);
	menu.ExitBackButton = true;
}

void DisplaySettingsMenu(int client)
{
	Menu menu = new Menu(Menu_SettingsCallback);
	char title[64];
	Format(title, sizeof(title), "Change Heal Beacon Settings");
	menu.SetTitle(title);
	
	menu.AddItem("0", "Change Heal Beacon Damage");
	menu.AddItem("1", "Change The first pick timer");
	menu.AddItem("4", "Toggle better damage mode");
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayBeaconDamageMenu(int client)
{
	Menu menu = new Menu(Menu_BeaconDamageCallback);
	char title[64];
	Format(title, sizeof(title), "Change Heal Beacon Settings");
	menu.SetTitle(title);
	
	menu.AddItem("1", "1");
	menu.AddItem("2", "2");
	menu.AddItem("5", "5");
	menu.AddItem("7", "7");
	menu.AddItem("8", "8");
	menu.AddItem("10", "10");
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayBeaconTimerMenu(int client)
{
	Menu menu = new Menu(Menu_BeaconTimerCallback);
	char title[64];
	Format(title, sizeof(title), "Change Heal Beacon Settings");
	menu.SetTitle(title);
	
	menu.AddItem("10", "10");
	menu.AddItem("20", "20");
	menu.AddItem("25", "25");
	menu.AddItem("30", "30");
	menu.AddItem("40", "40");
	menu.AddItem("60", "60");
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayActionsMenu(int client, int random)
{
	if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) == 3 && g_bIsClientRandom[random])
	{
		Menu menu = new Menu(Menu_ActionsCallback); 
		
		char title[64], buffer[32];
		Format(title, sizeof(title), "Do an Action on %N", random);
		menu.SetTitle(title);
		
		int userid = GetClientUserId(random);
		IntToString(userid, buffer, 32);
		
		menu.AddItem(buffer, "Repick randomly");
		menu.AddItem(buffer, "Change Beacon Color");
		menu.AddItem(buffer, "Change beacon radius and distance");
		
		char light[32];
		g_bHasNeon[random] ? Format(light, 32, "Disable Light on the player") : Format(light, 32, "Enable Light on the player");	
		menu.AddItem(buffer, light);
		
		menu.AddItem(buffer, "Change light color on the player", g_bHasNeon[random] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		menu.AddItem(buffer, "Teleport to player");
		menu.AddItem(buffer, "Bring Player");
		menu.AddItem(buffer, "Remove Heal beacon");
		menu.AddItem(buffer, "Slay Player");
		
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

void DisplayBeaconColorsMenu(int client, int random)
{
	if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) && g_bIsClientRandom[random])
	{
		Menu menu = new Menu(Menu_BeaconColorsCallback);
		
		char title[64];
		Format(title, sizeof(title), "Change beacon color on %N", random);
		menu.SetTitle(title);
		
		char buffer[32];
		int userid = GetClientUserId(random);
			
		IntToString(userid, buffer, 32);
		
		menu.AddItem(buffer, "White");
		menu.AddItem(buffer, "Red");
		menu.AddItem(buffer, "Lime");
		menu.AddItem(buffer, "Blue");
		menu.AddItem(buffer, "Yellow");
		menu.AddItem(buffer, "Cyan");
		menu.AddItem(buffer, "Gold");
		
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		return;
	}
}

void DisplayNeonColorsMenu(int client, int random)
{
	if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) && g_bIsClientRandom[random])
	{
		Menu menu = new Menu(Menu_NeonColorsCallback);
		
		char title[64];
		Format(title, sizeof(title), "Change beacon color on %N", random);
		menu.SetTitle(title);
		
		char buffer[32];
		int userid = GetClientUserId(random);
		
		IntToString(userid, buffer, 32);
		
		menu.AddItem(buffer, "White");
		menu.AddItem(buffer, "Red");
		menu.AddItem(buffer, "Lime");
		menu.AddItem(buffer, "Blue");
		menu.AddItem(buffer, "Yellow");
		menu.AddItem(buffer, "Cyan");
		menu.AddItem(buffer, "Gold");
		
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		return;
	}
}

void DisplayBeaconRadiusMenu(int client, int random)
{
	if(IsValidClient(random) && IsPlayerAlive(random) && GetClientTeam(random) && g_bIsClientRandom[random])
	{
		Menu menu = new Menu(Menu_BeaconRadiusCallback);
		
		char title[64];
		Format(title, sizeof(title), "Change beacon radius and distance on %N", random);
		menu.SetTitle(title);
		
		char buffer[32];
		int userid = GetClientUserId(random);
		
		IntToString(userid, buffer, 32);
		
		menu.AddItem(buffer, "200");
		menu.AddItem(buffer, "400");
		menu.AddItem(buffer, "600");
		menu.AddItem(buffer, "800");
		menu.AddItem(buffer, "1000");
		menu.AddItem(buffer, "1500");
		
		menu.AddItem("Empty", "These are the available distances please type sm_beacon_distance <1|2> <your number> instead", ITEMDRAW_DISABLED);
		
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

void SetClientNeon(int client)
{
	RemoveNeon(client);
	
	g_iNeon[client] = CreateEntityByName("light_dynamic");
	
	if(!IsValidEntity(g_iNeon[client]))
	{
		return;
	}
	
	g_bHasNeon[client] = true;
	
	float fOrigin[3];
	GetClientAbsOrigin(client, fOrigin);
	fOrigin[2] += 5;
	
	char sColor[64];
	Format(sColor, sizeof(sColor), "%i %i %i %i", g_iClientNeonColor[client][0], g_iClientNeonColor[client][1], g_iClientNeonColor[client][2], g_iClientNeonColor[client][3]);
	
	DispatchKeyValue(g_iNeon[client], "_light", sColor);
	DispatchKeyValue(g_iNeon[client], "brightness", "5");
	DispatchKeyValue(g_iNeon[client], "distance", "150");
	DispatchKeyValue(g_iNeon[client], "spotlight_radius", "50");
	DispatchKeyValue(g_iNeon[client], "style", "0");
	DispatchSpawn(g_iNeon[client]);
	AcceptEntityInput(g_iNeon[client], "TurnOn");
	
	TeleportEntity(g_iNeon[client], fOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(g_iNeon[client], "SetParent", client);
}

void RemoveNeon(int client)
{
	if(g_iNeon[client] && IsValidEntity(g_iNeon[client]))
	{
		AcceptEntityInput(g_iNeon[client], "KillHierarchy");
	}
	
	g_bHasNeon[client] = false;
	
	g_iNeon[client] = -1;
}

void TeleportToRandom(int client, int random)
{
	float fOrigin[3];
	GetClientAbsOrigin(random, fOrigin);
	fOrigin[2] += 5;
	
	TeleportEntity(client, fOrigin, NULL_VECTOR, NULL_VECTOR);
}

void DoProgressBeaconColor(int random, int color[4])
{
	if(random != -1)
	{
		g_iClientBeaconColor[random][0] = color[0];
		g_iClientBeaconColor[random][1] = color[1];
		g_iClientBeaconColor[random][2] = color[2];
		g_iClientBeaconColor[random][3] = color[3];
	}
	else
	{
		return;
	}
}

void DoProgressNeonColor(int random, int color[4])
{
	if(random != -1)
	{
		g_iClientNeonColor[random][0] = color[0];
		g_iClientNeonColor[random][1] = color[1];
		g_iClientNeonColor[random][2] = color[2];
		g_iClientNeonColor[random][3] = color[3];
	
		SetClientNeon(random);
	}
	else
	{
		return;
	}
}

void EndRound()
{
	CPrintToChatAll("%sNo beaconed players found, All humans will get hurt until they die so hurry up for winning the round!", PLUGIN_PREFIX);
	g_bNoBeacon = true;
}

int GetCurrentRandoms()
{
	int iRandomsCounter = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3 && g_bIsClientRandom[i])
			iRandomsCounter++;
	}
	
	return iRandomsCounter;
}

void RemoveRandom(int client)
{
	g_bIsClientRandom[client] = false;
	g_BeaconPlayer[client] = 0;
	RemoveNeon(client);
	BeaconTimer[client] = null;
	delete BeaconTimer[client];
}

void ResetValues(int client)
{
	iCount[client] = 0;
	g_BeaconPlayer[client] = 0;
}

void DeleteAllHandles(int client)
{	
	delete BeaconTimer[client];
	
	delete g_hHudTimer[client];
	
	delete g_hDistanceTimer[client];

	delete DistanceTimerHandle[client];
}

void CheckDistanceForNoMode(int client, int randomPlayer)
{
	if(GetDistanceBetween(client, randomPlayer) < (g_fClientDistance[randomPlayer] / 2.0))
	{
		if(!g_bMaxHealth[client])
		{
			if(GetEntProp(client, Prop_Send, "m_iHealth") < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + 1);
								
				if(GetEntProp(client, Prop_Send, "m_iHealth") == GetEntProp(client, Prop_Data, "m_iMaxHealth"))
				{
					g_bMaxHealth[client] = true;
				}
			}
		}
						
		g_bCloseToBeacon[client] = true;
	}
	else if(GetDistanceBetween(client, randomPlayer) > (g_fClientDistance[randomPlayer] / 2.0) && !g_bCloseToBeacon[client])
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		g_iHealth[client] = GetEntProp(client, Prop_Send, "m_iHealth");
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
		g_bCloseToBeacon[client] = false;
	}
}

void CheckDistanceForNoModeForTwo(int client, int randomPlayer0, int randomPlayer1)
{
	if(GetDistanceBetween(client, randomPlayer0) < (g_fClientDistance[randomPlayer0] / 2.0) || GetDistanceBetween(client, randomPlayer1) < (g_fClientDistance[randomPlayer1] / 2.0))
	{
		if(!g_bMaxHealth[client])
		{
			if(GetEntProp(client, Prop_Send, "m_iHealth") < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + 1);
								
				if(GetEntProp(client, Prop_Send, "m_iHealth") == GetEntProp(client, Prop_Data, "m_iMaxHealth"))
				{
					g_bMaxHealth[client] = true;
				}
			}
		}
						
		g_bCloseToBeacon[client] = true;
	}
	else if(GetDistanceBetween(client, randomPlayer0) > (g_fClientDistance[randomPlayer0] / 2.0) && GetDistanceBetween(client, randomPlayer1) > (g_fClientDistance[randomPlayer1] / 2.0) && !g_bCloseToBeacon[client])
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		g_iHealth[client] = GetEntProp(client, Prop_Send, "m_iHealth");
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
		g_bCloseToBeacon[client] = false;
	}
}

void CheckDistanceForNoModeForThree(int client, int randomPlayer0, int randomPlayer1, int randomPlayer2)
{
	if(GetDistanceBetween(client, randomPlayer0) < (g_fClientDistance[randomPlayer0] / 2.0) || GetDistanceBetween(client, randomPlayer1) < (g_fClientDistance[randomPlayer1] / 2.0) || GetDistanceBetween(client, randomPlayer2) < (g_fClientDistance[randomPlayer2] / 2.0))
	{
		if(!g_bMaxHealth[client])
		{
			if(GetEntProp(client, Prop_Send, "m_iHealth") < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + 1);
								
				if(GetEntProp(client, Prop_Send, "m_iHealth") == GetEntProp(client, Prop_Data, "m_iMaxHealth"))
				{
					g_bMaxHealth[client] = true;
				}
			}
		}
						
		g_bCloseToBeacon[client] = true;
	}
	else if(GetDistanceBetween(client, randomPlayer0) > (g_fClientDistance[randomPlayer0] / 2.0) && GetDistanceBetween(client, randomPlayer1) > (g_fClientDistance[randomPlayer1] / 2.0) && GetDistanceBetween(client, randomPlayer2) > (g_fClientDistance[randomPlayer2] / 2.0) && !g_bCloseToBeacon[client])
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		g_iHealth[client] = GetEntProp(client, Prop_Send, "m_iHealth");
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
		g_bCloseToBeacon[client] = false;
	}
}

void CheckDistanceForNoModeForFour(int client, int randomPlayer0, int randomPlayer1, int randomPlayer2, int randomPlayer3)
{
	if(GetDistanceBetween(client, randomPlayer0) < (g_fClientDistance[randomPlayer0] / 2.0) || GetDistanceBetween(client, randomPlayer1) < (g_fClientDistance[randomPlayer1] / 2.0) || GetDistanceBetween(client, randomPlayer2) < (g_fClientDistance[randomPlayer2] / 2.0) || GetDistanceBetween(client, randomPlayer3) < (g_fClientDistance[randomPlayer3] / 2.0))
	{
		if(!g_bMaxHealth[client])
		{
			if(GetEntProp(client, Prop_Send, "m_iHealth") < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + 1);
								
				if(GetEntProp(client, Prop_Send, "m_iHealth") == GetEntProp(client, Prop_Data, "m_iMaxHealth"))
				{
					g_bMaxHealth[client] = true;
				}
			}
		}
						
		g_bCloseToBeacon[client] = true;
	}
	else if(GetDistanceBetween(client, randomPlayer0) > (g_fClientDistance[randomPlayer0] / 2.0) && GetDistanceBetween(client, randomPlayer1) > (g_fClientDistance[randomPlayer1] / 2.0) && GetDistanceBetween(client, randomPlayer2) > (g_fClientDistance[randomPlayer2] / 2.0) && GetDistanceBetween(client, randomPlayer3) > (g_fClientDistance[randomPlayer3] / 2.0) && !g_bCloseToBeacon[client])
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		g_iHealth[client] = GetEntProp(client, Prop_Send, "m_iHealth");
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
		g_bCloseToBeacon[client] = false;
	}
}

void CheckDistanceForNoModeForFive(int client, int randomPlayer0, int randomPlayer1, int randomPlayer2, int randomPlayer3, int randomPlayer4)
{
	if(GetDistanceBetween(client, randomPlayer0) < (g_fClientDistance[randomPlayer0] / 2.0) || GetDistanceBetween(client, randomPlayer1) < (g_fClientDistance[randomPlayer1] / 2.0) || GetDistanceBetween(client, randomPlayer2) < (g_fClientDistance[randomPlayer2] / 2.0) || GetDistanceBetween(client, randomPlayer3) < (g_fClientDistance[randomPlayer3] / 2.0) || GetDistanceBetween(client, randomPlayer4) < (g_fClientDistance[randomPlayer4] / 2.0)) 
	{
		if(!g_bMaxHealth[client])
		{
			if(GetEntProp(client, Prop_Send, "m_iHealth") < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + 1);
								
				if(GetEntProp(client, Prop_Send, "m_iHealth") == GetEntProp(client, Prop_Data, "m_iMaxHealth"))
				{
					g_bMaxHealth[client] = true;
				}
			}
		}
						
		g_bCloseToBeacon[client] = true;
	}
	else if(GetDistanceBetween(client, randomPlayer0) > (g_fClientDistance[randomPlayer0] / 2.0) && GetDistanceBetween(client, randomPlayer1) > (g_fClientDistance[randomPlayer1] / 2.0) && GetDistanceBetween(client, randomPlayer2) > (g_fClientDistance[randomPlayer2] / 2.0) && GetDistanceBetween(client, randomPlayer3) > (g_fClientDistance[randomPlayer3] / 2.0) && GetDistanceBetween(client, randomPlayer4) > (g_fClientDistance[randomPlayer4] / 2.0) && !g_bCloseToBeacon[client])
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		g_iHealth[client] = GetEntProp(client, Prop_Send, "m_iHealth");
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
		g_bCloseToBeacon[client] = false;
	}
}

void CheckDistanceForMode(int client, int randomPlayer)
{
	if(GetDistanceBetween(client, randomPlayer) > (g_fClientDistance[randomPlayer] / 2.0))
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
	}
}

void CheckDistanceForModeForTwo(int client, int randomPlayer0, int randomPlayer1)
{
	if(GetDistanceBetween(client, randomPlayer0) > (g_fClientDistance[randomPlayer0] / 2.0) && GetDistanceBetween(client, randomPlayer1) > (g_fClientDistance[randomPlayer1] / 2.0))
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
	}
}

void CheckDistanceForModeForThree(int client, int randomPlayer0, int randomPlayer1, int randomPlayer2)
{
	if(GetDistanceBetween(client, randomPlayer0) > (g_fClientDistance[randomPlayer0] / 2.0) && GetDistanceBetween(client, randomPlayer1) > (g_fClientDistance[randomPlayer1] / 2.0) && GetDistanceBetween(client, randomPlayer2) > (g_fClientDistance[randomPlayer2] / 2.0))
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
	}
}

void CheckDistanceForModeForFour(int client, int randomPlayer0, int randomPlayer1, int randomPlayer2, int randomPlayer3)
{
	if(GetDistanceBetween(client, randomPlayer0) > (g_fClientDistance[randomPlayer0] / 2.0) && GetDistanceBetween(client, randomPlayer1) > (g_fClientDistance[randomPlayer1] / 2.0) && GetDistanceBetween(client, randomPlayer2) > (g_fClientDistance[randomPlayer2] / 2.0) && GetDistanceBetween(client, randomPlayer3) > (g_fClientDistance[randomPlayer3] / 2.0))
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
	}
}

void CheckDistanceForModeForFive(int client, int randomPlayer0, int randomPlayer1, int randomPlayer2, int randomPlayer3, int randomPlayer4)
{
	if(GetDistanceBetween(client, randomPlayer0) > (g_fClientDistance[randomPlayer0] / 2.0) && GetDistanceBetween(client, randomPlayer1) > (g_fClientDistance[randomPlayer1] / 2.0) && GetDistanceBetween(client, randomPlayer2) > (g_fClientDistance[randomPlayer2] / 2.0) && GetDistanceBetween(client, randomPlayer3) > (g_fClientDistance[randomPlayer3] / 2.0) && GetDistanceBetween(client, randomPlayer4) > (g_fClientDistance[randomPlayer4] / 2.0))
	{
		SetHudTextParams(-1.0, 0.2, 1.0, 0, 255, 255, 255);
		ShowSyncHudText(client, g_HudMsg, "WARNING: YOU ARE TOO FAR AWAY FROM THE BEACONED PLAYERS PLEASE GET CLOSER TO THEM");
		DealDamage(client, g_cvDamage.IntValue, DMG_GENERIC);
	}
}

bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client));
}

stock bool IsClientRandom(int client)
{
	return (1 <= client <= MaxClients && IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3 && g_bIsClientRandom[client]);
}					