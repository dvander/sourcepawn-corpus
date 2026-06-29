#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

//#undef REQUIRE_PLUGIN
//#include <updater>

//#define UPDATE_URL "http://giovani_nescau.bitbucket.org/powerups_shop/ps_update.txt" <- No longer functional
#define MenuCommand "sm_powerups"
#define MAX_CLIENTS 33 //33, so we don't make the code confuse by putting + 1 everywhere.
#define MAX_POWERUPS 256
#define MAX_COUNT_SIZE 4 //If we will load only 256 powerups in the max, we will need 3 char positions + 1 for the null terminator.
#define KEYVALUES_SAVETIME 60.0

#define PLUGIN_VERSION "1.0.2"

#include <powerups/#manager.sp> //Manages all powerups

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2]Powerups Shop",
	author = "Nescau",
	description = "Players can buy powerups using points.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/nescaufsa/"
};

//Translation
char g_pluginPrefix[24];

//Powerup informations variables
char g_powerupName[MAX_POWERUPS][64];
char g_powerupNameTranslated[MAX_POWERUPS][64];
int g_powerupCost[MAX_POWERUPS];
float g_powerupDuration[MAX_POWERUPS];
bool g_powerupEnabled[MAX_POWERUPS];
bool g_powerupRemoveOnDeath[MAX_POWERUPS];
bool g_powerupHideFromMenu[MAX_POWERUPS];
char g_powerupProperties[MAX_POWERUPS][128];
int g_powerupCount;
int g_enabledCount;
int g_iEnabledPowerupsSearch[MAX_POWERUPS];

//Menu informations variables
char g_menuTranslationItem[MAX_POWERUPS][256];

//Storage information variables
char powerupsPath[PLATFORM_MAX_PATH];
char playersPath[PLATFORM_MAX_PATH];
KeyValues playerData;
Handle g_tAutoSave = INVALID_HANDLE;

//Plugin configuration variables
ConVar g_cvarWelcomeMessage;			bool g_bWelcomeMessage;
ConVar g_cvarDeathRemove;				bool g_bDeathRemove;
ConVar g_cvarTeamRemove;				bool g_bTeamRemove;
ConVar g_cvarWaitTime;					int g_iWaitTime
ConVar g_cvarAllowRandom;				bool g_bAllowRandom;
ConVar g_cvarRandomCost;				int g_iRandomCost;
ConVar g_cvarAllowHudTime;				bool g_bAllowHudTime;
ConVar g_cvarHudTimeXPos; 				float g_fHudTimeXPos;
ConVar g_cvarHudTimeYPos; 				float g_fHudTimeYPos;


ConVar g_cvarAllowAutoPoints;			ConVar g_cvarAllowObjectivePoints;				ConVar g_cvarAllowKillPoints;
ConVar g_cvarAutoPointsTime;			ConVar g_cvarObjectivePoints;					ConVar g_cvarKillPoints;
ConVar g_cvarAutoPoints;				ConVar g_cvarMinPlayersObjectivePoints;			ConVar g_cvarMinPlayersKillPoints;
ConVar g_cvarMinPlayersAutoPoints;


bool g_bAllowAutoPoints;				bool g_bAllowObjectivePoints;					bool g_bAllowKillPoints;
int g_iAutoPoints;						int g_iObjectivePoints;							int g_iKillPoints;
int g_iMinPlayersAutoPoints;			int g_iMinPlayersObjectivePoints;				int g_iMinPlayersKillPoints;
float g_fAutoPointsTime;

//Client info variables
Handle g_hAutoPointsTimer[MAX_CLIENTS];
Handle g_hPowerupTimer[MAX_CLIENTS];
Handle g_hTimeCounter[MAX_CLIENTS];
int g_iClientPowerup[MAX_CLIENTS]; //If != -1, there's a powerup active
float g_fTimeCounter[MAX_CLIENTS];
bool g_bIsAlive[MAX_CLIENTS];

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("ps.phrases");
	LoadTranslations("ps.powerups_phrases");
	
	BuildPath(Path_SM, powerupsPath, PLATFORM_MAX_PATH, "configs/ps_powerups.txt");
	BuildPath(Path_SM, playersPath, PLATFORM_MAX_PATH, "data/ps_players.txt");
	
	RegConsoleCmd(MenuCommand, ShowPsMenu, "Displays the powerups shop.");
	RegAdminCmd("sm_prefresh", PluginRefresh, ADMFLAG_BAN, "Refreshes all information loaded on the plugin.");
	RegAdminCmd("sm_addpoints", AddPoints, ADMFLAG_BAN, "Add points to a player account.");
	RegAdminCmd("sm_removepoints", RemovePoints, ADMFLAG_BAN, "Remove points from a player account.");
	RegAdminCmd("sm_forcepowerup", ForcePowerup, ADMFLAG_BAN, "Forces a powerup on a player.");
	
	
	//ConVars
	CreateConVar("powerups_version", PLUGIN_VERSION, "Powerups Shop version.", FCVAR_NOTIFY);
	
	g_cvarWelcomeMessage = CreateConVar("ps_welcomemessage_enabled", "1", "Displays an welcome message for the player that has connected.", 0, true, 0.0, true, 1.0);
	g_cvarAllowHudTime = CreateConVar("ps_hudtime_allow", "1", "If 1, the remaining time before the powerup ends will be shown in the player hud.", 0, true, 0.0, true, 1.0);
	g_cvarHudTimeXPos = CreateConVar("ps_hudtimepos_x", "2.0", "Position X of the powerup time in the player hud.");
	g_cvarHudTimeYPos = CreateConVar("ps_hudtimepos_y", "2.5", "Position Y of the powerup time in the player hud.");
	
	g_cvarDeathRemove = CreateConVar("ps_powerup_removeondeath", "0", "If 1, the user will lose his bought powerup if he dies.", 0, true, 0.0, true, 1.0);
	g_cvarTeamRemove = CreateConVar("ps_powerup_changeteamremove", "0", "If 1, the user will lose his bought powerup if he changes team.", 0, true, 0.0, true, 1.0);
	
	g_cvarWaitTime = CreateConVar("ps_buy_wait", "180", "Makes the player wait this ammount of seconds before buying anything again.", 0, true, 0.0);
	
	g_cvarAllowRandom = CreateConVar("ps_randompowerups_enable", "1", "Displays the \"Random powerup\" item in the shop menu.", 0, true, 0.0, true, 1.0);
	g_cvarRandomCost = CreateConVar("ps_randompowerup_cost", "200", "If \"ps_randompowerups_enable\" is set to 1, the player will pay this ammount of points for a random powerup.", 0, true, 0.0);
	
	g_cvarAllowAutoPoints = CreateConVar("ps_autopoints_allow", "1", "Allow players to receive points after playing for \"ps_autopoints_playtime\" ammount of seconds.", 0, true, 0.0, true, 1.0 );
	g_cvarAutoPointsTime = CreateConVar("ps_autopoints_playtime", "600", "If \"ps_autopoints_allow\" is set to 1, each time the user plays for this ammount of seconds, he will receive \"ps_autopoints_points\" points.", 0, true, 1.0);
	g_cvarAutoPoints = CreateConVar("ps_autopoints_points", "1", "If \"ps_autopoints_allow\" is set to 1, the user will receive this ammount of points for each \"ps_autopoints_playtime\" seconds he plays.", 0, true, 0.0);
	g_cvarMinPlayersAutoPoints = CreateConVar("ps_autopoints_minplayers", "4", "Minimum ammount of people in the server before players get playtime points.", 0, true, 0.0);
	
	g_cvarAllowObjectivePoints = CreateConVar("ps_objectivepoints_allow", "1", "Allow players to receive points by doing map objectives.", 0, true, 0.0, true, 1.0);
	g_cvarObjectivePoints = CreateConVar("ps_objectivepoints_points", "3", "If \"ps_objectivepoints_allow\" is set to 1, players will receive this ammount of points for doing map objectives.", 0, true, 0.0);
	g_cvarMinPlayersObjectivePoints = CreateConVar("ps_objectivepoints_minplayers", "4", "Minimum ammount of people in the server before players get objective points.", 0, true, 0.0);
	
	g_cvarAllowKillPoints = CreateConVar("ps_killpoints_allow", "1", "Allow players to receive points by killing each others.", 0, true, 0.0, true, 1.0);
	g_cvarKillPoints = CreateConVar("ps_killpoints_points", "1", "If \"ps_killpoints_allow\" is set to 1, players will receive this ammount of points for killing each others.", 0, true, 0.0);
	g_cvarMinPlayersKillPoints = CreateConVar("ps_killpoints_minplayers", "4", "Minimum ammount of people in the server before players get points for killing each others.", 0, true, 0.0);
	
	//Preparations
	AutoExecConfig(true);
	
	//-Updater
	#if defined _updater_included
	
	if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
  	}
  	
  	#endif
	
	PreparePlugin();
	
	Format(g_pluginPrefix, 24, "%T", "Plugin_Prefix", LANG_SERVER);
	Manager_OnPluginStart();
}

/*Updater <- No longer functional
#if defined _updater_included

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
}

public int Updater_OnPluginUpdated()
{
	PrintToServer("[Powerups Shop] A new version of the plugin has been downloaded.");
}

#endif
*/

void PreparePlugin()
{
	//Loads all powerups and it's translations
	PreparePowerups();
	TranslatePowerups();
	
	//Prepare the convars
	ReadConVars();
	
	//Hook all needed events
	HookEvents();
	
	//Import the keyvalues containing all players informations
	LoadClientsData();
	
	//Initiates all variables for the players
	InitializeClientsVars();
	
	//Check if it's possible to give points automatically using the play time
	CheckAutoPointsEnable();
}

//Loads all powerups informations
void PreparePowerups()
{
	g_powerupCount = 0;
	g_enabledCount = 0;
	
	KeyValues pkv = new KeyValues("powerups");
	pkv.ImportFromFile(powerupsPath);
	
	char buffer[MAX_COUNT_SIZE];
	int ivalue;
	
	for (int a = 0; a < MAX_POWERUPS; a++)
	{
		strcopy(buffer, MAX_COUNT_SIZE, "");
		
		IntToString(a, buffer, MAX_COUNT_SIZE);
		
		if (pkv.JumpToKey(buffer))
		{
			pkv.GetString("powerup_name", g_powerupName[a], 64, "null");
			
			if (strcmp(g_powerupName[a], "null") == 0)
			{
				SetFailState("[PS] Error found while reading ps_powerups.txt - Powerup %d have a unknown powerup_name.", a);
			}
			
			g_powerupCost[a] = pkv.GetNum("cost", 0);
			
			ivalue = pkv.GetNum("duration", -1);
			
			if (ivalue == -1)
			{
				SetFailState("[PS] Error found while reading ps_powerups.txt - Powerup %d don't have duration.", a);
			}
			
			g_powerupDuration[a] = float(ivalue);
			
			g_powerupEnabled[a] = ((pkv.GetNum("enabled", 0) == 1) ? true : false);
			
			if (g_powerupEnabled[a])
			{
				g_iEnabledPowerupsSearch[g_enabledCount] = a;
				g_enabledCount++;
			}
			
			g_powerupRemoveOnDeath[a] = ((pkv.GetNum("remove_on_death", 0) == 1) ? true : false);
			
			g_powerupHideFromMenu[a] = ((pkv.GetNum("hide_from_menu", 0) == 1) ? true : false);
			
			pkv.GetString("properties", g_powerupProperties[a], 128, "null");
			
			pkv.Rewind();
			
			Format(g_powerupNameTranslated[a], 64, "%T", g_powerupName[a], LANG_SERVER);
			
			g_powerupCount++;
		}
	}
	
	delete pkv;
	
	TranslatePowerups();
}

//Loads all translations
void TranslatePowerups()
{
	for (int a = 0; a < g_powerupCount; a++)
	{	
		if (g_powerupDuration[a] == 0.0)
		{
			Format(g_menuTranslationItem[a], 256, "%T", "Menu_Item_Instant", LANG_SERVER, g_powerupNameTranslated[a], g_powerupCost[a]);
		}
		
		else
		{
			Format(g_menuTranslationItem[a], 256, "%T", "Menu_Item", LANG_SERVER, g_powerupNameTranslated[a], g_powerupCost[a], RoundToZero(g_powerupDuration[a]));
		}
	}
}

void ReadConVars()
{
	g_bWelcomeMessage = g_cvarWelcomeMessage.BoolValue;
	g_bAllowHudTime = g_cvarAllowHudTime.BoolValue;
	g_fHudTimeXPos = g_cvarHudTimeXPos.FloatValue;
	g_fHudTimeYPos = g_cvarHudTimeYPos.FloatValue;
	
	g_bDeathRemove = g_cvarDeathRemove.BoolValue;
	g_bTeamRemove = g_cvarTeamRemove.BoolValue;
	
	g_iWaitTime = g_cvarWaitTime.IntValue;
	
	g_bAllowRandom = g_cvarAllowRandom.BoolValue;
	g_iRandomCost = g_cvarRandomCost.IntValue;
	
	g_bAllowAutoPoints = g_cvarAllowAutoPoints.BoolValue;
	g_fAutoPointsTime = float(g_cvarAutoPointsTime.IntValue);
	g_iAutoPoints = g_cvarAutoPoints.IntValue;
	g_iMinPlayersAutoPoints = g_cvarMinPlayersAutoPoints.IntValue;
	
	g_bAllowObjectivePoints = g_cvarAllowObjectivePoints.BoolValue;
	g_iObjectivePoints = g_cvarObjectivePoints.IntValue;
	g_iMinPlayersObjectivePoints = g_cvarMinPlayersObjectivePoints.IntValue;
	
	g_bAllowKillPoints = g_cvarAllowKillPoints.BoolValue;
	g_iKillPoints = g_cvarKillPoints.IntValue;
	g_iMinPlayersKillPoints = g_cvarMinPlayersKillPoints.IntValue;
}

void HookEvents()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("teamplay_point_captured", Event_CPointCaptureObjective, EventHookMode_Post);
	HookEvent("teamplay_capture_blocked", Event_CPointBlockObjective, EventHookMode_Post);
	HookEvent("teamplay_flag_event", Event_FlagObjective, EventHookMode_Post);
	
	//If the plugin is loaded after the map start, we need to verify if there's players in the server and hook OnTakeDamage for them
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
		}
	}
}

void LoadClientsData()
{
	playerData = new KeyValues("players");
	playerData.ImportFromFile(playersPath);
	
	if (g_tAutoSave != INVALID_HANDLE)
	{
		KillTimer(g_tAutoSave);
	}
	
	g_tAutoSave = CreateTimer(20.0, Timer_SaveClientsData, 0, TIMER_REPEAT);
}

public Action Timer_SaveClientsData(Handle timer, any integer)
{
	playerData.ExportToFile(playersPath);
}

void InitializeClientsVars()
{
	for (int client = 1; client < MAX_CLIENTS; client++)
	{
		g_hAutoPointsTimer[client] = INVALID_HANDLE;
		g_hPowerupTimer[client] = INVALID_HANDLE;
		g_hTimeCounter[client] = INVALID_HANDLE;
		g_iClientPowerup[client] = -1;
		g_fTimeCounter[client] = 0.0;
		g_bIsAlive[client] = false;
	}
}

//Will be called everytime a player connects and disconnects to check if players can get points by staying on the server.
void CheckAutoPointsEnable()
{	
	int playercount = GetClientCount();
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			if (g_bAllowAutoPoints)
			{
				if (playercount >= g_iMinPlayersAutoPoints)
				{
					if (CheckCommandAccess(client, MenuCommand, 0))
					{
						if (g_hAutoPointsTimer[client] == INVALID_HANDLE)
						{
							g_hAutoPointsTimer[client] = CreateTimer(g_fAutoPointsTime, Timer_GivePoints, client, TIMER_REPEAT);
						}
					}
				}
				
				else
				{
					if (g_hAutoPointsTimer[client] != INVALID_HANDLE)
					{
						KillTimer(g_hAutoPointsTimer[client]);
						g_hAutoPointsTimer[client] = INVALID_HANDLE;
					}
				}
			}
			
			g_bIsAlive[client] = IsPlayerAlive(client); //For some reason, IsPlayerAlive(client) returns true before the player spawns (Pre HookMode).
		}
	}
}

public Action Timer_GivePoints(Handle timer, any client)
{
	SetPoints(client, GetPoints(client) + g_iAutoPoints);
	
	PrintToChat(client, "%T", "ReceivePointsMessage", LANG_SERVER, g_pluginPrefix, g_iAutoPoints);
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client) && CheckCommandAccess(client, MenuCommand, 0) && g_bAllowAutoPoints)
	{
		g_hAutoPointsTimer[client] = CreateTimer(g_fAutoPointsTime, Timer_GivePoints, client, TIMER_REPEAT);
		
		if (g_bWelcomeMessage)
		{
			PrintToChat(client, "%T", "WelcomeMessage", LANG_SERVER, g_pluginPrefix);
		}
	}
	
	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	
	CheckAutoPointsEnable();
	
	//Manager_OnClientPostAdminCheck(client);
}

public void OnClientDisconnect(int client)
{
	RemoveClientPowerup(client, true);
	
	if (g_hAutoPointsTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hAutoPointsTimer[client]);
		g_hAutoPointsTimer[client] = INVALID_HANDLE;
	}
	
	g_bIsAlive[client] = false;
	
	SDKUnhook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	
	//Manager_OnClientDisconnect(client);
}

public void OnClientDisconnect_Post(int client)
{
	CheckAutoPointsEnable();
}

public void OnMapStart()
{
	Manager_OnMapStart();
}

public void OnPluginEnd()
{
	EndData();
	//Manager_OnPluginEnd();
}

//Ends all powerups and saves everything it can
void EndData()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			RemoveClientPowerup(client, true);
			
			if (g_hAutoPointsTimer[client] != INVALID_HANDLE)
			{
				KillTimer(g_hAutoPointsTimer[client]);
				g_hAutoPointsTimer[client] = INVALID_HANDLE;
			}
		}
	}
	
	UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	UnhookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	UnhookEvent("teamplay_point_captured", Event_CPointCaptureObjective, EventHookMode_Post);
	UnhookEvent("teamplay_capture_blocked", Event_CPointBlockObjective, EventHookMode_Post);
	UnhookEvent("teamplay_flag_event", Event_FlagObjective, EventHookMode_Post);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			SDKUnhook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
		}
	}
	
	playerData.ExportToFile(playersPath);
	delete playerData;
}

////////////////////////////////////[ Console commands ]/////////////////////////////////////
public Action PluginRefresh(int client, int args)
{
	EndData();
	PreparePlugin();
	
	ReplyToCommand(client, "[PS] Data was refreshed.");
}

public Action AddPoints(int client, int args)
{
	if (args == 2)
	{
		char clientName[MAX_NAME_LENGTH];	
		GetCmdArg(1, clientName, MAX_NAME_LENGTH);
		
		char number[16];
		GetCmdArg(2, number, 16);
		
		if (!String_IsInteger(number))
		{
			ReplyToCommand(client, "%s Usage: sm_addpoints <player/steamid> <quantity>", g_pluginPrefix);
			return;
		}
		
		int quantity = StringToInt(number);
		
		if (StrContains(clientName, "[U:", true) != -1)
		{
			SetPointsId(clientName, (GetPointsId(clientName) + quantity));
			ReplyToCommand(client, "%s %d point(s) added to id \"%s\"", g_pluginPrefix, quantity, clientName);
		}
		
		else
		{
			int target = FindTarget(client, clientName, true, false);
			
			if(IsValidClient(target))
			{
				SetPoints(target, (GetPoints(target) + quantity));
				GetClientName(target, clientName, MAX_NAME_LENGTH);
				ReplyToCommand(client, "%s %d point(s) added to player \"%s\"", g_pluginPrefix, quantity, clientName);
			}
			
			else
			{
				ReplyToCommand(client, "%s Player \"%s\" not found.", g_pluginPrefix, clientName);
			}
		}
	}
	
	else
	{
		ReplyToCommand(client, "%s Usage: sm_addpoints <client/steamid> <quantity>)", g_pluginPrefix);
	}
}

public Action RemovePoints(int client, int args)
{
	if (args == 2)
	{
		char clientName[MAX_NAME_LENGTH];	
		GetCmdArg(1, clientName, MAX_NAME_LENGTH);
		
		char number[16];
		GetCmdArg(2, number, 16);
		
		int points = 0;
		
		if (!String_IsInteger(number))
		{
			ReplyToCommand(client, "%s Usage: sm_removepoints <player/steamid> <quantity>", g_pluginPrefix);
			return;
		}
		
		int quantity = StringToInt(number);
		
		if (StrContains(clientName, "[U:", true) != -1)
		{
			points = GetPointsId(clientName);
			
			if (points < quantity)
			{
				SetPointsId(clientName, 0);
			}
			
			else
			{
				SetPointsId(clientName, (points - quantity));
			}
			
			ReplyToCommand(client, "%s %d point(s) removed from id \"%s\"", g_pluginPrefix, quantity, clientName);
		}
		
		else
		{
			int target = FindTarget(client, clientName, true, false);
			
			if(IsValidClient(target))
			{
				points = GetPoints(target);
				
				if (points < quantity)
				{
					SetPoints(target, 0);
				}
				
				else
				{
					SetPoints(target, (points - quantity));
				}
				
				GetClientName(target, clientName, MAX_NAME_LENGTH);
				ReplyToCommand(client, "%s %d point(s) removed from player \"%s\"", g_pluginPrefix, quantity, clientName);
			}
			
			else
			{
				ReplyToCommand(client, "%s Player \"%s\" not found.", g_pluginPrefix, clientName);
			}
		}
	}
	
	else
	{
		ReplyToCommand(client, "%s Usage: sm_removepoints <client/steamid> <quantity>)", g_pluginPrefix);
	}
}

public Action ForcePowerup(int client, int args)
{
	if (args == 2)
	{
		char clientName[MAX_NAME_LENGTH];
		char powerupId[16];
		GetCmdArg(1, clientName, MAX_NAME_LENGTH);
		GetCmdArg(2, powerupId, 16);
		
		int target = FindTarget(client, clientName, true, false);
		
		if (!String_IsInteger(powerupId))
		{
			ReplyToCommand(client, "%s Usage: sm_forcepowerup <player> <powerup number>", g_pluginPrefix);
			return;
		}
		
		int powerup = StringToInt(powerupId);
		
		if (powerup > (g_powerupCount - 1))
		{
			ReplyToCommand(client, "%s Powerup %d not found.", g_pluginPrefix, powerup);
			return;
		}
		
		if (IsValidClient(target))
		{
			if (g_iClientPowerup[target] == -1)
			{
				if (g_powerupEnabled[powerup])
				{
					ActivatePowerup(target, powerup);
				
					GetClientName(target, clientName, MAX_NAME_LENGTH);
					PrintToChatAll("%T", "ForcedPowerup", LANG_SERVER, g_pluginPrefix, g_powerupNameTranslated[powerup], clientName);
				}
				
				else
				{
					ReplyToCommand(client, "%s Powerup %s is not enabled.", g_pluginPrefix, g_powerupNameTranslated);
				}
				
			}
			
			else
			{
				GetClientName(target, clientName, MAX_NAME_LENGTH);
				ReplyToCommand(client, "%s Player \"%s\" already have a powerup.", g_pluginPrefix, clientName);
			}
		}
		
		else
		{
			ReplyToCommand(client, "%s Player \"%s\" not found.", g_pluginPrefix, clientName);
		}	
	}
	
	else
	{
		ReplyToCommand(client, "%s Usage: sm_forcepowerup <player> <powerup number>", g_pluginPrefix);
	}
}

public Action ShowPsMenu(int client, int args)
{
	if (IsValidClient(client))
	{
		Menu menu = new Menu(MenuCall);
		menu.SetTitle("%T", "Menu_Title", LANG_SERVER, GetPoints(client));
		
		bool itemsAdded = false;
		char buffer[MAX_COUNT_SIZE];
		
		if (g_bAllowRandom && g_enabledCount > 0)
		{
			char buffer1[256];
			Format(buffer1, 256, "%T", "Menu_Item_RandomPowerup", LANG_SERVER, g_iRandomCost);
			
			menu.AddItem("##RANDOMPOWERUP##_PS", buffer1);
			itemsAdded = true;
		}
		
		for (int a = 0; a < g_powerupCount; a++)
		{
			if (g_powerupEnabled[a] && !g_powerupHideFromMenu[a])
			{
				IntToString(a, buffer, MAX_COUNT_SIZE);
				
				menu.AddItem(buffer, g_menuTranslationItem[a]);
				itemsAdded = true;
			}
		}
		
		if (!itemsAdded)
		{
			menu.AddItem("#NOITEMS", "Sorry, but the server administrator didn't add any powerup.", ITEMDRAW_DISABLED);
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int MenuCall(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	
	else if (action == MenuAction_Select)
	{
		char info[64];
		
		menu.GetItem(param2, info, 64);
		
		if (StrEqual("##RANDOMPOWERUP##_PS", info))
		{
			BuyRandomPowerup(param1);
		}
		
		else
		{
			BuyPowerup(param1, StringToInt(info));
		}
	}
}

////////////////////////////////////[ Events ]////////////////////////////////////

public Action Event_PlayerDeath(Event playerDeath, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(playerDeath.GetInt("userid"));
	int attacker = GetClientOfUserId(playerDeath.GetInt("attacker"));
	
	if (IsValidClient(client))
	{
		if (playerDeath.GetInt("death_flags") != 32) //Isn't a "Deadringing" spy
		{
			if ((g_iClientPowerup[client] != -1 && g_powerupRemoveOnDeath[g_iClientPowerup[client]]) || g_bDeathRemove)
			{
				char clientName[MAX_NAME_LENGTH];
				GetClientName(client, clientName, MAX_NAME_LENGTH);
				
				RemoveClientPowerup(client, true);
				PrintToChatAll("%T", "PowerupEnded_Death", LANG_SERVER, g_pluginPrefix, clientName);
			}
			
			else 
			{
				RemoveClientPowerup(client, false);
			}
			
			//Manager_HookPlayerDeath(playerDeath);
			
			if (client != attacker && attacker > 0 && g_bAllowKillPoints && GetClientCount() >= g_iMinPlayersKillPoints)
			{
				SetPoints(attacker, GetPoints(attacker) + g_iKillPoints);
		
				PrintToChat(attacker, "%T", "ReceivePointsMessage_Kill", LANG_SERVER, g_pluginPrefix, g_iKillPoints);
			}
			
			g_bIsAlive[client] = false;
		}
	}
}

public Action Event_PlayerSpawn(Event playerSpawn, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(playerSpawn.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		if (g_iClientPowerup[client] != -1)
		{
			if (g_bIsAlive[client]) //Did the player respawn without being dead? (Changed class?)
			{
				RemoveClientPowerup(client, false);
			}
			
			//If he did change class or respawned, he still or is now alive
			g_bIsAlive[client] = true;
			
			ActivatePowerup(client, g_iClientPowerup[client], true); //Requires the player to be alive
			
		}
		
		//If the if block wasn't executated, the player is now alive anyway
		g_bIsAlive[client] = true;
		
		//Manager_HookPlayerSpawn(playerSpawn);
	}
}

public Action Event_PlayerTeam(Event playerTeam, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(playerTeam.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		if (g_bTeamRemove)
		{
			char clientName[MAX_NAME_LENGTH];
			GetClientName(client, clientName, MAX_NAME_LENGTH);
			
			RemoveClientPowerup(client, true);
			PrintToChatAll("%T", "PowerupEnded_Team", LANG_SERVER, g_pluginPrefix, clientName);
		}
		
		else
		{
			RemoveClientPowerup(client, false);
		}
		
		//Manager_HookPlayerTeam(playerTeam);
	}
}

public Action Event_CPointCaptureObjective(Event objective, const char[] name, bool dontBroadcast)
{
	if (g_bAllowObjectivePoints && GetClientCount() >= g_iMinPlayersObjectivePoints)
	{
		int capper;
		char cappersString[MAXPLAYERS + 1];
		objective.GetString("cappers", cappersString, sizeof(cappersString));
		
		for (int a = 0; a < strlen(cappersString); a++)
		{
			capper = cappersString[a];
			
			if (IsValidClient(capper))
			{
				SetPoints(capper, GetPoints(capper) + g_iObjectivePoints);
	
				PrintToChat(capper, "%T", "ReceivePointsMessage_PointCaptured", LANG_SERVER, g_pluginPrefix, g_iObjectivePoints);
			}
		}
	}
}

public Action Event_CPointBlockObjective(Event objective, const char[] name, bool dontBroadcast)
{
	if (g_bAllowObjectivePoints && GetClientCount() >= g_iMinPlayersObjectivePoints)
	{
		int client = objective.GetInt("blocker");
		
		if (IsValidClient(client))
		{
			SetPoints(client, GetPoints(client) + g_iObjectivePoints);

			PrintToChat(client, "%T", "ReceivePointsMessage_PointBlocked", LANG_SERVER, g_pluginPrefix, g_iObjectivePoints);
		}
	}
}

public Action Event_FlagObjective(Event flagObjective, const char[] name, bool dontBroadcast)
{
	if (g_bAllowObjectivePoints && GetClientCount() >= g_iMinPlayersObjectivePoints)
	{
		int client = flagObjective.GetInt("player");
		
		if (IsValidClient(client))
		{
			SetPoints(client, GetPoints(client) + g_iObjectivePoints);
			
			if (flagObjective.GetInt("eventtype") == TF_FLAGEVENT_CAPTURED)
			{
				PrintToChat(client, "%T", "ReceivePointsMessage_FlagCapture", LANG_SERVER, g_pluginPrefix, g_iObjectivePoints);
			}
			
			else if (flagObjective.GetInt("eventtype") == TF_FLAGEVENT_DEFENDED)
			{
				PrintToChat(client, "%T", "ReceivePointsMessage_FlagDefend", LANG_SERVER, g_pluginPrefix, g_iObjectivePoints);
			}
		}
	}
}

public Action Event_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	return Manager_OnTakeDamage(victim, attacker, inflictor, damage, damagetype);
}

////////////////////////////////////[ Main functions ]////////////////////////////////////

int GetPoints(int client)
{
	char sid[32];
	GetClientAuthId(client, AuthId_Steam3, sid, 32);
	return GetPointsId(sid);
}

int GetPointsId(char[] sid)
{
	playerData.JumpToKey(sid, true);
	int points = playerData.GetNum("points", 0);
	playerData.Rewind();
	
	return points;
}

void SetPoints(int client, int quantity)
{
	char sid[32];
	GetClientAuthId(client, AuthId_Steam3, sid, 32);
	SetPointsId(sid, quantity);
}

void SetPointsId(char[] sid, int quantity)
{
	playerData.JumpToKey(sid, true);
	playerData.SetNum("points", quantity);
	playerData.Rewind();
}

int GetWaitTime(int client)
{
	char sid[32];
	GetClientAuthId(client, AuthId_Steam3, sid, 32);
	
	return GetWaitTimeId(sid);
}

int GetWaitTimeId(char[] sid)
{
	int time = GetTime();
	
	playerData.JumpToKey(sid, true);
	int waittime = playerData.GetNum("wait_time", 0);
	
	if (waittime <= time)
	{
		playerData.SetNum("wait_time", 0);
		waittime = 0;
	}
	
	playerData.Rewind();
	
	return waittime;
}

void SetWaitTime(int client, int time)
{
	char sid[32];
	GetClientAuthId(client, AuthId_Steam3, sid, 32);
	
	SetWaitTimeId(sid, time);
}

void SetWaitTimeId(char[] sid, int time)
{
	playerData.JumpToKey(sid, true);
	playerData.SetNum("wait_time", time);
	playerData.Rewind();
}

void RemoveClientPowerup(int client, bool resetPowerupVar, bool isTimer = false)
{
	if (g_iClientPowerup[client] != -1 && g_bIsAlive[client])
	{
		Manager_ManagePowerup(client, g_iClientPowerup[client], g_powerupProperties[g_iClientPowerup[client]], false);
	}
	
	if (!isTimer && g_hPowerupTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hPowerupTimer[client]);
		g_hPowerupTimer[client] = INVALID_HANDLE;
	}
	
	if (g_hTimeCounter[client] != INVALID_HANDLE)
	{
		KillTimer(g_hTimeCounter[client]);
		g_hTimeCounter[client] = INVALID_HANDLE;
	}
	
	if (resetPowerupVar)
	{
		g_iClientPowerup[client] = -1;
		g_fTimeCounter[client] = 0.0;
	}
}

void BuyRandomPowerup(int client)
{
	if (g_iClientPowerup[client] != -1)
	{
		PrintToChat(client, "%T", "CantBuy_PowerupActive", LANG_SERVER, g_pluginPrefix);
		return;
	}
	
	int waittime = GetWaitTime(client);
	int actualTime = GetTime();
	
	if (waittime > actualTime)
	{
		PrintToChat(client, "%T", "CantBuy_WaitTime", LANG_SERVER, g_pluginPrefix, (waittime - actualTime));
		return;
	}
	
	int points = GetPoints(client);
	
	if (points < g_iRandomCost)
	{
		PrintToChat(client, "%T", "CantBuy_UnsufficientPoints", LANG_SERVER, g_pluginPrefix);
		return;
	}
	
	int randomInt = GetRandomInt(0, (g_enabledCount - 1));
	
	SetPoints(client, (points - g_iRandomCost))
	ActivatePowerup(client, g_iEnabledPowerupsSearch[randomInt]);
	
	SetWaitTime(client, (GetTime() + g_iWaitTime));
	
	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, MAX_NAME_LENGTH);
	PrintToChatAll("%T", "RandomPowerup", LANG_SERVER, g_pluginPrefix, clientName, g_powerupNameTranslated[randomInt]);
}

void BuyPowerup(int client, int powerup)
{
	if(g_iClientPowerup[client] != -1)
	{
		PrintToChat(client, "%T", "CantBuy_PowerupActive", LANG_SERVER, g_pluginPrefix);
		return;
	}
	
	int waittime = GetWaitTime(client);
	int actualTime = GetTime();
	
	if (waittime > actualTime)
	{
		PrintToChat(client, "%T", "CantBuy_WaitTime", LANG_SERVER, g_pluginPrefix, (waittime - actualTime));
		return;
	}
	
	int points = GetPoints(client);
	
	if (points < g_powerupCost[powerup])
	{
		PrintToChat(client, "%T", "CantBuy_UnsufficientPoints", LANG_SERVER, g_pluginPrefix);
		return;
	}
	
	SetPoints(client, (points - g_powerupCost[powerup]));	
	
	ActivatePowerup(client, powerup);
	
	SetWaitTime(client, (GetTime() + g_iWaitTime));
	
	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, MAX_NAME_LENGTH);
	PrintToChatAll("%T", "PostBuyMessage", LANG_SERVER, g_pluginPrefix, clientName, g_powerupNameTranslated[powerup]);
}

void ActivatePowerup(int client, int powerup, bool continueTimer = false)
{
	if (g_bIsAlive[client])
	{
		Manager_ManagePowerup(client, powerup, g_powerupProperties[powerup], true);
		g_iClientPowerup[client] = powerup;

		if (!continueTimer)
		{
			g_fTimeCounter[client] = g_powerupDuration[powerup];
			
			if (g_fTimeCounter[client] != 0.0)
			{
				g_hPowerupTimer[client] = CreateTimer(g_fTimeCounter[client], Timer_RemovePowerup, client);
				g_hTimeCounter[client] = CreateTimer(1.0, Timer_TimeCounter, client, TIMER_REPEAT);
			} else {
				RemoveClientPowerup(client, true);
			}
		}
		
		else
		{
			g_hPowerupTimer[client] = CreateTimer(g_fTimeCounter[client], Timer_RemovePowerup, client);
			g_hTimeCounter[client] = CreateTimer(1.0, Timer_TimeCounter, client, TIMER_REPEAT);
		}
	}
	
	else
	{
		g_iClientPowerup[client] = powerup;
		g_fTimeCounter[client] = g_powerupDuration[powerup];
	}
}

public Action Timer_RemovePowerup(Handle timer, any client)
{
	RemoveClientPowerup(client, true, true);
	
	g_hPowerupTimer[client] = INVALID_HANDLE;
	
	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, MAX_NAME_LENGTH);
	
	PrintToChatAll("%T", "PowerupEnded", LANG_SERVER, g_pluginPrefix, clientName);
}

public Action Timer_TimeCounter(Handle timer, any client)
{
	if (g_fTimeCounter[client] > 0.0)
	{
		g_fTimeCounter[client] -= 1.0;
		
		if (g_bAllowHudTime)
		{
			SetHudTextParams(g_fHudTimeXPos, g_fHudTimeYPos, 1.0, 255, 255, 255, 255);
			ShowHudText(client, -1, "%.f", g_fTimeCounter[client]);
		}
	}
}

////////////////////////////////////[ Helpers ]////////////////////////////////////

bool String_IsInteger(const char[] str)
{	
	int len = strlen(str);
	
	if (len > 0)
	{
		for (int loop = 0; loop < len; loop++)
		{
			if (!IsCharNumeric(str[loop]))
			{
				return false;
			}
		}
		
		return true;
	}
	
	return false;
}

bool String_IsFloat(const char[] str)
{
	int len = strlen(str);
	
	if (len > 0)
	{
		bool dotFound = false;
		
		for (int loop = 0; loop < len; loop++)
		{
			if (!IsCharNumeric(str[loop]) && str[loop] == '.')
			{
				if (dotFound)
				{
					return false;
				}
				
				dotFound = true;
			}
			
			else if (!IsCharNumeric(str[loop]))
			{
				return false;
			}
		}
		
		return true;
	}
	
	return false;
}

bool IsValidClient(int client)
{
	return (client > 0 && client < MAX_CLIENTS && IsClientConnected(client) && IsClientAuthorized(client) && IsClientInGame(client) && !IsClientSourceTV(client)  && !IsFakeClient(client));
}