#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <regex>

#define PLUGIN_VERSION 			"Beta2"
#define ACHIEVEMENT_SOUND 		"misc/achievement_earned.wav"
#define ACHIEVEMENT_PARTICLE 	"Achieved"

#define ACHIEVEMENT_CHEAT_ENABLED		(1 << 0)
#define ACHIEVEMENT_UNIQUE				(1 << 1)
#define ACHIEVEMENT_NOTEXT				(1 << 2)
#define ACHIEVEMENT_NOPARTICLE			(1 << 3)
#define ACHIEVEMENT_NOSOUND				(1 << 4)
#define ACHIEVEMENT_SILENT				((1 << 2) | (1 << 3) | (1 << 4))
#define ACHIEVEMENT_DEBUG				(1 << 5)
#define ACHIEVEMENT_HAS_TRANSLATION		(1 << 6)

#define ARG_CLIENT				0
#define ARG_ACH_ID 				1
#define ARG_MAX_PROGRESS		2
#define ARG_ADD_PROGRESS		3
#define ARG_PART_PROGRESS		4
#define ARG_SPECIAL_FLAGS		5
#define ARG_ACH_ACHIEVED		6

#define ARG_STEAMID				0
#define ARG_ACH_NAME			1


new Handle:g_Cvar_Cheats = INVALID_HANDLE;
new Handle:g_Cvar_CAapi_enabled = INVALID_HANDLE;
new Handle:g_Cvar_AchievementsUrl = INVALID_HANDLE;
new Handle:g_Cvar_StoreNames = INVALID_HANDLE;

new String:g_strDatabasePrefix[128];
new Handle:g_hDatabaseConnection = INVALID_HANDLE;
new Handle:g_Cvar_DBTablePrefix = INVALID_HANDLE;
new Handle:g_Cvar_CAapi_db = INVALID_HANDLE;
new bool:g_bConnectedToDB = false;

new g_iPassInt[64][7];
new String:g_strPassString[64][2][64];
new g_iCurPass = 0;

// Forwards
new Handle:g_hForwardAchievementTriggered;
new Handle:g_hForwardAchievementProgressed;

public Plugin:myinfo = 
{
	name = "Achievements API",
	author = "Flyflo",
	description = "Custom achievements API",
	version = PLUGIN_VERSION,
	url = "http://www.geek-gaming.fr"
}

// Declare natives
public APLRes:AskPluginLoad2(Handle:hMySelf, bool:bLate, String:strError[], iMaxErrors)
{
	CreateNative("CA_ProcessAchievement", CA_ProcessAchievement);
	CreateNative("CA_CheckForMilestone", CA_CheckForMilestone);
	CreateNative("CA_ProcessAchievementByName", CA_ProcessAchievementByName);
	CreateNative("CA_CheckForMilestoneByName", CA_CheckForMilestoneByName);
	
	CreateNative("CA_GetAchievementProgress", CA_GetAchievementProgress);
	CreateNative("CA_IsAchievedByClient", CA_IsAchievedByClient);
	
	CreateNative("CA_IdToName", CA_IdToName);
	CreateNative("CA_NameToId", CA_NameToId);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	// Register the plugin as a library
	RegPluginLibrary("ca_api");

	// Load translations
	LoadTranslations("achievements_api.phrases");

	// Create convars
	CreateConVar("sm_ca_api_version", PLUGIN_VERSION, "Custom Achievements Api Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_CAapi_enabled = 					CreateConVar("sm_ca_api_enabled", "1", "Plugin enabled", 0, true, 0.0, true, 1.0);
	
	g_Cvar_CAapi_db = 						CreateConVar("sm_ca_api_db", "achievements", "DB conf to use");
	g_Cvar_DBTablePrefix = 					CreateConVar("sm_ca_api_db_tableprefix", "ca_", "Table prefix");
	
	g_Cvar_StoreNames =						CreateConVar("sm_ca_api_storenames", "1", "Store players' names and steamid in the database.");
	g_Cvar_AchievementsUrl =				CreateConVar("sm_ca_api_achurl", "", "Web site url to show achievements for the player.");
	
	AutoExecConfig(true, "ca_api");
	
	// sv_cheats hook for ACHIEVEMENT_CHEAT_ENABLED
	g_Cvar_Cheats = FindConVar("sv_cheats");
	
	// Setup forwards
	SetupForwards();
	
	// Table prefix convar hook
	HookConVarChange(g_Cvar_DBTablePrefix, TablePrefixChange);
	
	// Console command to print the achievements stored in the database.
	RegAdminCmd("sm_ca_api_list", Cmd_PrintAchievementsList, ADMFLAG_CHEATS, "Print a list of all the achievements.");
	
	// Console command to show the achievements ingame
	RegConsoleCmd("achievements", Cmd_ShowPlayerAchievements, "Show your achievements");
	
	// Connect to the database.
	decl String:strDBConnection[128];
	GetConVarString(g_Cvar_CAapi_db, strDBConnection, sizeof(strDBConnection));
		
	if (SQL_CheckConfig(strDBConnection))
	{
		SQL_TConnect(CA_DatabaseConnect, strDBConnection);
	}
	else
	{
		LogError("[CA_api] Unable to open %s: No such configuration.", strDBConnection);
		g_bConnectedToDB = false;
	}
}

SetupForwards()
{
	g_hForwardAchievementTriggered = CreateGlobalForward("AchievementTriggered", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell);
	g_hForwardAchievementProgressed = CreateGlobalForward("AchievementProgressed", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}

public OnMapStart()
{
	PrecacheSound(ACHIEVEMENT_SOUND, true);
}

public OnConfigsExecuted()
{
	TablePrefixChange(INVALID_HANDLE, "", "");
}

public OnClientPostAdminCheck(hClient)
{
	SaveUser(hClient);
}

/****************************
*							*
*							*
*		DATABASE PART		*
*		START				*
*							*
*							*
*****************************/

public CA_DatabaseConnect(Handle:hOwner, Handle:hQuery, const String:strError[], any:data) 
{	
	// If we can't connect to the database, print the error
	if (hQuery == INVALID_HANDLE)
	{
		decl String:strDBConnection[128];
		GetConVarString(g_Cvar_CAapi_db, strDBConnection, sizeof(strDBConnection));
		
		LogError("[CA_api] Unable to connect to %s, Error: %s", strDBConnection, strError);
		
		g_bConnectedToDB = false;
	}
	else
	{
		// Try to set the NAMES to UTF8
		if (!SQL_FastQuery(hQuery, "SET NAMES 'utf8'"))
		{
			LogError("[CA_api] Unable to change to utf8 mode.");
			g_bConnectedToDB = false;
		}
		else
		{
			g_hDatabaseConnection = hQuery;
			g_bConnectedToDB = true;
		}
	}
}


public CA_GenericSQLCallBack(Handle:hOwner, Handle:hQuery, const String:strError[], any:data) 
{

	if(hQuery == INVALID_HANDLE)
	{
		new bool:b_knownError = true;

		decl String:strErrorFrom[64];
		switch(data)
		{
			case 0:
				strErrorFrom = "CA_ProcessUserAchievement[Insert+Trigger]";
			case 1:
				strErrorFrom = "CA_ProcessUserAchievement[Insert]";
			case 2:
				strErrorFrom = "CA_ProcessUserAchievement[Update+Trigger]";
			case 3:
				strErrorFrom = "CA_ProcessUserAchievement[Update]";
			case 4:
				strErrorFrom = "SaveUser";
			case 5:
				strErrorFrom = "MysqlSetNames";
			default:
			{
				strErrorFrom = "Unknow";
				b_knownError = false;
			}
		}		
			
		// If the query return an error, print it
		if (b_knownError)
		{
			LogError("[CA_api] CA_GenericSQLCallBack -> %s: Error in the SQL query: %s", strErrorFrom, strError);
		}
		else
		{
			LogError("[CA_api] CA_GenericSQLCallBack -> %s: SQL Error", strErrorFrom, strError);
		}
	}
}

// ------------------------------------------------------------------------
// PassArgs(hClient, iAchievementId, iMaxProgress, iAddProgress, iAchievedAchievements, iMilestonePartProgress, iSpecialFlags, String:strClientSteamid[64] = "", String:strAchievementUniqueName[64] = "")
// ------------------------------------------------------------------------
// Used to pass multiples args between functions using SQL_TQuery
// ------------------------------------------------------------------------
PassArgs(hClient, iAchievementId, iMaxProgress, iAddProgress, iAchievedAchievements, iMilestonePartProgress, iSpecialFlags, String:strClientSteamid[64] = "", String:strAchievementUniqueName[64] = "")
{
	if (g_iCurPass == 64)
	{
		g_iCurPass = 0;
	}
	
	g_iPassInt[g_iCurPass][ARG_CLIENT] = hClient;
	g_iPassInt[g_iCurPass][ARG_ACH_ID] = iAchievementId;
	g_iPassInt[g_iCurPass][ARG_MAX_PROGRESS] = iMaxProgress;
	g_iPassInt[g_iCurPass][ARG_ADD_PROGRESS] = iAddProgress;
	g_iPassInt[g_iCurPass][ARG_ACH_ACHIEVED] = iAchievedAchievements;
	g_iPassInt[g_iCurPass][ARG_PART_PROGRESS] = iMilestonePartProgress;
	g_iPassInt[g_iCurPass][ARG_SPECIAL_FLAGS] = iSpecialFlags;
	
	g_strPassString[g_iCurPass][ARG_STEAMID] = strClientSteamid;
	g_strPassString[g_iCurPass][ARG_ACH_NAME] = strAchievementUniqueName;
	
	g_iCurPass++;
	
	return g_iCurPass-1;
}

/****************************
*							*
*							*
*		DATABASE PART		*
*		END					*
*							*
*							*
*****************************/


/****************************
*							*
*							*
*		API PART			*
*		BEGIN				*
*							*
*							*
*****************************/
// NATIVES:
// CA_ProcessAchievement(iAchievementId, hClient, iAddProgress = 1, iSpecialFlags = 0)
// CA_ProcessAchievementByName(String:strAchievementUniqueName[64], hClient, iAddProgress = 1, iSpecialFlags = 0)
// CA_CheckForMilestone(iMilestoneId, hClient, iSpecialFlags = 0, iPartProgress = 0)
// CA_CheckForMilestoneByName(String:strMilestoneUniqueName[64], hClient, iSpecialFlags = 0, iPartProgress = 0)
// CA_GetAchievementProgress(iAchievementId, hClient)
// CA_IsAchievedByClient(iAchievementId, hClient)
// CA_IdToName(iAchievementId, String:strAchievementName[64])
// CA_NameToId(String:strAchievementName[64])
// CA_GetAchievementProgress(iAchievementId, hClient)

// OTHERS :
// CA_MilestoneAchievementsList()
// CA_MilestoneCount()
// CA_CheckForValidAchievement()
// CA_CheckUniqueAchievement
// CA_ProcessUserAchievement()
// CA_TriggerAchievement()


// ------------------------------------------------------------------------
// CA_ProcessAchievement(iAchievementId, hClient, iAddProgress = 1, iSpecialFlags = 0)
// ------------------------------------------------------------------------
// Process an Achievement
// ------------------------------------------------------------------------
public CA_ProcessAchievement(Handle:hPlugin, numParams)
{
	// If the plugin is disabled stop here
	if(!GetConVarBool(g_Cvar_CAapi_enabled))
	{
		return;
	}
	
	// Check if the connection to the DB is establihed
	if(!g_bConnectedToDB)
	{
		LogError("[CA_api] CA_ProcessAchievement: Not connected to the DB");
		return;
	}
	
	// Retrieve the parameters
	new iAchievementId = GetNativeCell(1);
	new hClient = GetNativeCell(2);
	new iAddProgress = GetNativeCell(3);
	new iSpecialFlags = GetNativeCell(4);
	
	// Invalid achievement id
	if(iAchievementId < 0)
	{
		LogError("[CA_api] CA_ProcessAchievement call failed, achievement id %i is invalid.", iAchievementId);
		return;
	}
	
	// Stop if sv_cheats = 1 and the achievement is not flagged as ACHIEVEMENT_CHEAT_ENABLED
	if(GetConVarInt(g_Cvar_Cheats) == 1 && !(iSpecialFlags & ACHIEVEMENT_CHEAT_ENABLED))
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessAchievement: Can't trigger achievement %i unless sv_cheats is set to 0.", iAchievementId);
		}
		return;
	}
	
	decl String:edictName[32];
	GetEdictClassname(hClient, edictName, sizeof(edictName));
	
	// Check if the client is valid
	if((!StrEqual(edictName, "player")) || (!IsClientInGame(hClient)) || (InvalidClient(hClient)))
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("--------------------------------------------------------------------------------");
			PrintToChatAll("\x03[CA_api ERROR]\x01 CA_ProcessAchievement: Call failed, client id %i is invalid.", hClient);
		}
		LogError("[CA_api] CA_ProcessAchievement call failed, client id %i is invalid.", hClient);
		return;
	}
	
	// We're trying to process or add progress to an achievement
	if(iAddProgress >= 1)
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("--------------------------------------------------------------------------------");
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessAchievement called successfully (Client: %i - > %N, Achievement %i).", hClient, hClient, iAchievementId);
		}
		
		// Retrieve the steamid of the player
		decl String:strSteamId[64];
		GetClientAuthString(hClient, strSteamId, sizeof(strSteamId));
		
		// Format query
		decl String:strQuery[512];
		Format(strQuery, sizeof(strQuery), "SELECT id, amount FROM `%sachievements` WHERE `id` = %i;", g_strDatabasePrefix, iAchievementId);
		
		MysqlSetNames();
		SQL_TQuery(g_hDatabaseConnection, CA_CheckForValidAchievement, strQuery, PassArgs(hClient, iAchievementId, -1, iAddProgress, -1, -1, iSpecialFlags, strSteamId));
	}
	else // Invalid progress
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api ERROR]\x01 CA_ProcessAchievement trying to add a %i progress for achievement %i", iAddProgress, iAchievementId);
		}
		LogError("[CA_api] CA_ProcessAchievement trying to add a %i progress for achievement %i", iAddProgress, iAchievementId);
		
		return;
	}
}

// ------------------------------------------------------------------------
// CA_ProcessAchievementByName(strAchievementUniqueName, hClient, iAddProgress = 1, iSpecialFlags = 0)
// ------------------------------------------------------------------------
// Process an Achievement by Name
// ------------------------------------------------------------------------
public CA_ProcessAchievementByName(Handle:hPlugin, numParams)
{
	// If the plugin is disabled stop here
	if(!GetConVarBool(g_Cvar_CAapi_enabled))
	{
		return;
	}
	
	// Check if the connection to the DB is establihed
	if(!g_bConnectedToDB)
	{
		LogError("[CA_api] CA_ProcessAchievementByName: Not connected to the DB");
		return;
	}
	
	// Retrieve the parameters
	decl String:strAchievementUniqueName[64];
	GetNativeString(1, strAchievementUniqueName, sizeof(strAchievementUniqueName));

	new hClient = GetNativeCell(2);
	new iAddProgress = GetNativeCell(3);
	new iSpecialFlags = GetNativeCell(4);
	
	// Stop if sv_cheats = 1 and the achievement is not flagged as ACHIEVEMENT_CHEAT_ENABLED
	if(GetConVarInt(g_Cvar_Cheats) == 1 && !(iSpecialFlags & ACHIEVEMENT_CHEAT_ENABLED))
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessAchievementByName can't trigger achievement %s unless sv_cheats is set to 0.", strAchievementUniqueName);
		}
		return;
	}
	
	decl String:edictName[32];
	GetEdictClassname(hClient, edictName, sizeof(edictName));
	
	// Check if the client is valid
	if((!StrEqual(edictName, "player")) || (!IsClientInGame(hClient)) || (InvalidClient(hClient)))
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("--------------------------------------------------------------------------------");
			PrintToChatAll("\x03[CA_api ERROR]\x01 CA_ProcessAchievementByName call failed, client id %i is invalid.", hClient);
		}
		LogError("[CA_api] CA_ProcessAchievementByName call failed, client id %i is invalid.", hClient);
		return;
	}
	
	// We're trying to process or add progress to an achievement
	if(iAddProgress >= 1)
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("--------------------------------------------------------------------------------");
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessAchievementByName called successfully (Client: %i -> %N, Achievement %s).", hClient, hClient, strAchievementUniqueName);
		}
		
		// Retrieve the steamid of the player
		decl String:strSteamId[64];
		GetClientAuthString(hClient, strSteamId, sizeof(strSteamId));
		
		// Format query
		decl String:strQuery[512];
		Format(strQuery, sizeof(strQuery), "SELECT id, amount FROM `%sachievements` WHERE `unique_name` = '%s';", g_strDatabasePrefix, strAchievementUniqueName);
		
		MysqlSetNames();
		SQL_TQuery(g_hDatabaseConnection, CA_CheckForValidAchievement, strQuery, PassArgs(hClient, -1, -1, iAddProgress, -1, -1, iSpecialFlags, strSteamId, strAchievementUniqueName));
	}
	else // Invalid progress
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api ERROR]\x01 CA_ProcessAchievement: Trying to add a %i progress for achievement %s", iAddProgress, strAchievementUniqueName);
		}
		LogError("[CA_api] CA_ProcessAchievementByName: Trying to add a %i progress for achievement %s", iAddProgress, strAchievementUniqueName);
		
		return;
	}
}


// ------------------------------------------------------------------------
// CA_CheckForMilestone(iMilestoneId, hClient, iSpecialFlags = 0, iPartProgress = -4)
// ------------------------------------------------------------------------
// Check if we should trigger a milestone.
// ------------------------------------------------------------------------
public CA_CheckForMilestone(Handle:hPlugin, numParams)
{
	//If the plugin is disabled stop here
	if(!GetConVarBool(g_Cvar_CAapi_enabled))
	{
		return -1;
	}

	// Retrieve the parameters
	new iMilestoneId = GetNativeCell(1);
	new hClient = GetNativeCell(2);
	new iSpecialFlags = GetNativeCell(3);
	new iPartProgress = GetNativeCell(4);
	
	// Invalid achievement id
	if(iMilestoneId < 0)
	{
		LogError("[CA_api] CA_CheckForMilestone call failed, milestone id %i is invalid.", iMilestoneId);
		return -1;
	}

	// Stop if sv_cheats = 1 and the milestone is not flagged as ACHIEVEMENT_CHEAT_ENABLED
	if(GetConVarInt(g_Cvar_Cheats) == 1 && !(iSpecialFlags & ACHIEVEMENT_CHEAT_ENABLED))
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_CheckForMilestone: Can't trigger milestone %i unless sv_cheats is set to 0.", iMilestoneId);
		}
		return -1;
	}

	
	decl String:edictName[32];
	GetEdictClassname(hClient, edictName, sizeof(edictName));
	
	// Check if the client is valid
	if((!StrEqual(edictName, "player")) || (!IsClientInGame(hClient)) || (InvalidClient(hClient)))
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("--------------------------------------------------------------------------------");
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_CheckForMilestone call failed, client id %i is invalid.", hClient);
		}
		
		LogError("[CA_api] CA_CheckForMilestone call failed, client id %i is invalid.", hClient);
		return -1;
	}
	
	// Retrieve the steamid of the player
	decl String:strSteamId[64];
	GetClientAuthString(hClient, strSteamId, sizeof(strSteamId));
	
	// Format query
	decl String:strQuery[512];
	Format(strQuery, sizeof(strQuery),
	"SELECT achievements_list FROM %smilestones WHERE milestone_id = %i;",
	g_strDatabasePrefix, iMilestoneId);
	
	SQL_TQuery(g_hDatabaseConnection, CA_MilestoneAchievementsList, strQuery, PassArgs(hClient, iMilestoneId, -1, -1, -1, iPartProgress, iSpecialFlags, strSteamId));
	
	return 0;
}


// ------------------------------------------------------------------------
// CA_CheckForMilestoneByName(strMilestoneUniqueName, hClient, iSpecialFlags = 0, iPartProgress = -1)
// ------------------------------------------------------------------------
// Check if we should trigger a milestone by name
// ------------------------------------------------------------------------
public CA_CheckForMilestoneByName(Handle:hPlugin, numParams)
{
	//If the plugin is disabled stop here
	if(!GetConVarBool(g_Cvar_CAapi_enabled))
	{
		return -1;
	}
	
	// Retrieve the parameters
	decl String:strMilestoneUniqueName[64];
	GetNativeString(1, strMilestoneUniqueName, sizeof(strMilestoneUniqueName));
	
	new hClient = GetNativeCell(2);
	new iSpecialFlags = GetNativeCell(3);
	new iPartProgress = GetNativeCell(4);
	
	// Stop if sv_cheats = 1 and the achievement is not flagged as ACHIEVEMENT_CHEAT_ENABLED
	if(GetConVarInt(g_Cvar_Cheats) == 1 && !(iSpecialFlags & ACHIEVEMENT_CHEAT_ENABLED))
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_CheckForMilestoneByName: Can't trigger milestone %s unless sv_cheats is set to 0.", strMilestoneUniqueName);
		}
		return -1;
	}
	
	decl String:edictName[32];
	GetEdictClassname(hClient, edictName, sizeof(edictName));
	
	// Check if the client is valid
	if((!StrEqual(edictName, "player")) || (!IsClientInGame(hClient)) || (InvalidClient(hClient)))
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("--------------------------------------------------------------------------------");
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_CheckForMilestoneByName call failed, client id %i is invalid.", hClient);
		}
		
		LogError("[CA_api] CA_CheckForMilestoneByName call failed, client id %i is invalid.", hClient);
		return -1;
	}
	
	// Retrieve the steamid of the player
	decl String:strSteamId[64];
	GetClientAuthString(hClient, strSteamId, sizeof(strSteamId));
	
	// Format query	
	decl String:strQuery[512];
	Format(strQuery, sizeof(strQuery),
	"SELECT achievements_list, milestone_id FROM %smilestones WHERE milestone_unique_name = '%s';",
	g_strDatabasePrefix, strMilestoneUniqueName);
	
	SQL_TQuery(g_hDatabaseConnection, CA_MilestoneAchievementsList, strQuery, PassArgs(hClient, -1, -1, -1, -1, iPartProgress, iSpecialFlags, strSteamId, strMilestoneUniqueName));
	return 0;
}

// ------------------------------------------------------------------------
// CA_MilestoneAchievementsList()
// ------------------------------------------------------------------------
// Called by CA_CheckForMilestone or CA_CheckForMilestoneByName
// - Count the achievements a of a milestone set achieved by a player.
// - Then call CA_MilestoneCount if everything is ok.
// ------------------------------------------------------------------------
/*	Previous query:
*		SELECT achievements_list
*		FROM %smilestones
*		WHERE milestone_id = %i;
*	Or:
*		SELECT achievements_list, milestone_id
*		FROM %smilestones
*		WHERE milestone_unique_name = %s;
*/
public CA_MilestoneAchievementsList(Handle:hOwner, Handle:hQuery, const String:strError[], any:data)
{
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		LogError("[CA_api] CA_MilestoneAchievementsList: Error in the SQL query: %s", strError);
		return -1;
	}
	
	SQL_FetchRow(hQuery);
	
	new iMilestoneId;
	
	// Milestone by Name
	if(g_iPassInt[data][ARG_ACH_ID] == -1)
	{
		iMilestoneId = SQL_FetchInt(hQuery, 1);
		
		if(iMilestoneId < 1)
		{
			if(g_iPassInt[data][ARG_SPECIAL_FLAGS] & ACHIEVEMENT_DEBUG)
			{
				PrintToChatAll("\x03[CA_api]\x01 CA_MilestoneAchievementsList: Invalid milestone id for milestone %s.", g_strPassString[data][ARG_ACH_NAME]);
			}
			LogError("[CA_api] CA_MilestoneAchievementsList: Invalid milestone id for milestone %s.", g_strPassString[data][ARG_ACH_NAME]);
			return -1;
		}
	}
	else // Milestone by id 
	{
		iMilestoneId = g_iPassInt[data][ARG_ACH_ID];
	}
	
	// Number of achievements of the milestone set achieved	
	decl String:AchievementsList[512];
	SQL_FetchString(hQuery, 0, AchievementsList, sizeof(AchievementsList));

	// Check the syntax of the achievement list
	if(SimpleRegexMatch(AchievementsList, "^\\d+(\\|\\d+)*$") > 0)
	{
		if(g_iPassInt[data][ARG_SPECIAL_FLAGS] & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_MilestoneAchievementsList: Valid achievement list for milestone %i.", iMilestoneId);
		}
		
		new iNumReplaces = ReplaceString(AchievementsList, sizeof(AchievementsList), "|", " OR achievement_id = ");

		// Format query
		decl String:strQuery[512];
		Format(strQuery, sizeof(strQuery),
		"SELECT COUNT(*) FROM %sachievements LEFT JOIN %sprogress ON id = achievement_id WHERE (id = %s) AND amount = progression AND steamid = '%s';",
		g_strDatabasePrefix, g_strDatabasePrefix, AchievementsList, g_strPassString[data][ARG_STEAMID]);

		SQL_TQuery(g_hDatabaseConnection, CA_MilestoneCount, strQuery, PassArgs(g_iPassInt[data][ARG_CLIENT], iMilestoneId, iNumReplaces + 1, -1, -1, g_iPassInt[data][ARG_PART_PROGRESS], g_iPassInt[data][ARG_SPECIAL_FLAGS], g_strPassString[data][ARG_STEAMID], g_strPassString[data][ARG_ACH_NAME]));
		
	}
	else // Bad syntax
	{
		if(g_iPassInt[data][ARG_SPECIAL_FLAGS] & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api ERROR]\x01 CA_MilestoneAchievementsList Invalid achievement list for milestone %i.", g_iPassInt[data][ARG_ACH_ID]);
		}
		LogError("[CA_api] CA_MilestoneAchievementsList Invalid achievement list for milestone %i.", g_iPassInt[data][ARG_ACH_ID]);
		return -1;
	}

	return 0;
}

// ------------------------------------------------------------------------
// CA_MilestoneCount()
// ------------------------------------------------------------------------
// Called by CA_MilestoneAchievementsList
// - Count the achievement a of a milestone set achieved by a player.
// - Then call CA_MilestoneCount if everything is ok.
// ------------------------------------------------------------------------
/*	Previous query:
*		SELECT COUNT(*)
*		FROM %sachievements
*		LEFT JOIN %sprogress ON id = achievement_id
*		WHERE (id = %s) AND amount = progression
*		AND steamid = '%s';
*/
public CA_MilestoneCount(Handle:hOwner, Handle:hQuery, const String:strError[], any:data)
{
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		LogError("[CA_api] CA_MilestoneCount: Error in the SQL query: %s", strError);
		return -1;
	}
	
	SQL_FetchRow(hQuery);
	
	// Number of achievements of the milestone set achieved
	new iAchievedAchievements = SQL_FetchInt(hQuery, 0);
	
	if(g_iPassInt[data][ARG_SPECIAL_FLAGS] & ACHIEVEMENT_DEBUG)
	{
		PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_MilestoneCount: Actual progress %i/%i for milestone %i.", iAchievedAchievements, g_iPassInt[data][ARG_MAX_PROGRESS], g_iPassInt[data][ARG_ACH_ID]);
	}
		
	if(iAchievedAchievements != 0)
	{
		decl String:strQuery[512];
		
		//Full Milestone
		if(g_iPassInt[data][ARG_PART_PROGRESS] == -1)
		{
			if(iAchievedAchievements >= g_iPassInt[data][ARG_MAX_PROGRESS])
			{
				if(g_iPassInt[data][ARG_SPECIAL_FLAGS] & ACHIEVEMENT_DEBUG)
				{
					PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_MilestoneCount: All achievements (%i/%i) for the milestone set %i, calling CA_CheckForValidAchievement.", iAchievedAchievements, g_iPassInt[data][ARG_MAX_PROGRESS], g_iPassInt[data][ARG_ACH_ID]);
				}
				
				Format(strQuery, sizeof(strQuery), "SELECT id, amount FROM `%sachievements` WHERE `id` = %i;", g_strDatabasePrefix, g_iPassInt[data][ARG_ACH_ID]);
				MysqlSetNames();
				SQL_TQuery(g_hDatabaseConnection, CA_CheckForValidAchievement, strQuery, PassArgs(g_iPassInt[data][ARG_CLIENT], g_iPassInt[data][ARG_ACH_ID], -1, 1, -1, -1, g_iPassInt[data][ARG_SPECIAL_FLAGS], g_strPassString[data][ARG_STEAMID], g_strPassString[data][ARG_ACH_NAME]));
			}
		}
		else if(g_iPassInt[data][ARG_PART_PROGRESS] > 0) //Part Milestone
		{
			// Enough achievements done
			if(iAchievedAchievements >= g_iPassInt[data][ARG_PART_PROGRESS])
			{
				if(g_iPassInt[data][ARG_SPECIAL_FLAGS] & ACHIEVEMENT_DEBUG)
				{
					PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_MilestoneCount: Enough achievements (%i/%i, maximum: %i) for the milestone set %i, calling CA_CheckForValidAchievement.", iAchievedAchievements, g_iPassInt[data][ARG_PART_PROGRESS], g_iPassInt[data][ARG_MAX_PROGRESS], g_iPassInt[data][ARG_ACH_ID]);
				}

				Format(strQuery, sizeof(strQuery), "SELECT id, amount FROM `%sachievements` WHERE `id` = %i;", g_strDatabasePrefix, g_iPassInt[data][ARG_ACH_ID]);
				
				MysqlSetNames();
				SQL_TQuery(g_hDatabaseConnection, CA_CheckForValidAchievement, strQuery, PassArgs(g_iPassInt[data][ARG_CLIENT], g_iPassInt[data][ARG_ACH_ID], -1, 1, -1, -1, g_iPassInt[data][ARG_SPECIAL_FLAGS], g_strPassString[data][ARG_STEAMID], g_strPassString[data][ARG_ACH_NAME]));
			}
		}
		else // Invalid Part Progress
		{
			if(g_iPassInt[data][ARG_SPECIAL_FLAGS] & ACHIEVEMENT_DEBUG)
			{
				PrintToChatAll("\x03[CA_api]\x01 CA_MilestoneCount: Invalid part progress (%i) for the milestone set %i.", g_iPassInt[data][ARG_PART_PROGRESS], g_iPassInt[data][ARG_ACH_ID]);
			}
			LogError("[CA_api ERROR] CA_MilestoneCount: Invalid part progress (%i) for the milestone set %i.", g_iPassInt[data][ARG_PART_PROGRESS], g_iPassInt[data][ARG_ACH_ID]);
			return -1;
		}
	}

	return 0;
}

// ------------------------------------------------------------------------
// CA_CheckForValidAchievement()
// ------------------------------------------------------------------------
// Called by CA_ProcessAchievement, CA_MilestoneCount or by CA_ProcessAchievementByName
// - Check if the achievement exists.
// - If everything is ok:
//		- Call CA_CheckUniqueAchievement if the achievement if flagged as ACHIEVEMENT_UNIQUE.
//		- Call CA_ProcessUserAchievement else.
// ------------------------------------------------------------------------
/*	Previous query:
*		SELECT id, amount
*		FROM `%sachievements`
*		WHERE `id` = %i;
*	Or:
*		SELECT id, amount
*		FROM `%sachievements`
*		WHERE `unique_name` = %s;
*/
public CA_CheckForValidAchievement(Handle:hOwner, Handle:hQuery, const String:strError[], any:data)
{
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		LogError("[CA_api] CA_CheckForValidAchievement: Error in the SQL query: %s", strError);
		
		return -1;
	}
	
	new iSpecialFlags = g_iPassInt[data][ARG_SPECIAL_FLAGS];
	
	// No result, invalid achievement
	if (SQL_GetRowCount(hQuery) == 0)
	{
		// Achievement passed by id
		if(g_iPassInt[data][ARG_ACH_ID] != -1)
		{
			if(iSpecialFlags & ACHIEVEMENT_DEBUG)
			{
				PrintToChatAll("\x03[CA_api ERROR]\x01 CA_CheckForValidAchievement: Test failed, achievement %i is invalid.", g_iPassInt[data][ARG_ACH_ID]);
			}
			LogError("[CA_api] CA_CheckForValidAchievement: Test failed, achievement %i is invalid.", g_iPassInt[data][ARG_ACH_ID]);
		}
		else // Achievement passed by name
		{
			if(iSpecialFlags & ACHIEVEMENT_DEBUG)
			{
				PrintToChatAll("\x03[CA_api ERROR]\x01 CA_CheckForValidAchievement: Test failed, achievement %s is invalid.", g_strPassString[data][ARG_ACH_NAME]);
			}
			LogError("[CA_api] CA_CheckForValidAchievement: Test failed, achievement %s is invalid.", g_strPassString[data][ARG_ACH_NAME]);
		}
		
		return -1;
	}
	
	SQL_FetchRow(hQuery);
	
	new iAchievementId = SQL_FetchInt(hQuery, 0);
	new iAchievementMaxValue = SQL_FetchInt(hQuery, 1);
	
	decl String:strQuery[512];
	
	if(iSpecialFlags & ACHIEVEMENT_UNIQUE)
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_CheckForValidAchievement: Achievement %i is UNIQUE.", iAchievementId);
		}
		
		// Format query
		Format(strQuery, sizeof(strQuery),
		"SELECT COUNT(*) FROM `%sachievements` AS `a` LEFT JOIN `%sprogress` AS `p` ON `a`.`id` = `p`.`achievement_id` WHERE `id` = %i AND `a`.`amount` = `p`.`progression`;",
		g_strDatabasePrefix, g_strDatabasePrefix, iAchievementId);
		
		SQL_TQuery(g_hDatabaseConnection, CA_CheckUniqueAchievement, strQuery, PassArgs(g_iPassInt[data][ARG_CLIENT], iAchievementId, iAchievementMaxValue, g_iPassInt[data][ARG_ADD_PROGRESS], -1, -1, g_iPassInt[data][ARG_SPECIAL_FLAGS], g_strPassString[data][ARG_STEAMID], g_strPassString[data][ARG_ACH_NAME]));
	}
	else
	{
		if(iSpecialFlags & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_CheckForValidAchievement: Achievement %i is normal.", iAchievementId);
		}
		
		// Format query
		Format(strQuery, sizeof(strQuery),
		"SELECT `a`.`name`, `p`.`progression` FROM `%sachievements` AS `a` LEFT JOIN `%sprogress` AS `p` ON `a`.`id` = `p`.`achievement_id` WHERE `p`.`steamid` = '%s' AND `id` = %i;",
		g_strDatabasePrefix, g_strDatabasePrefix, g_strPassString[data][ARG_STEAMID], iAchievementId);
		
		SQL_TQuery(g_hDatabaseConnection, CA_ProcessUserAchievement, strQuery, PassArgs(g_iPassInt[data][ARG_CLIENT], iAchievementId, iAchievementMaxValue, g_iPassInt[data][ARG_ADD_PROGRESS], -1, -1, g_iPassInt[data][ARG_SPECIAL_FLAGS], g_strPassString[data][ARG_STEAMID], g_strPassString[data][ARG_ACH_NAME]));
	}

	return 0;
}

// ------------------------------------------------------------------------
// CA_CheckUniqueAchievement
// ------------------------------------------------------------------------
// Called by CA_CheckForValidAchievement
// - Check if a player already achieved an unique achievement:
//		- Stop if it's true.
//		- Else continue.
// ------------------------------------------------------------------------
/*	Previous query:
*		SELECT COUNT(*)
*		FROM `%sachievements` AS `a`
*		LEFT JOIN `%sprogress` AS `p` ON `a`.`id` = `p`.`achievement_id`
*		WHERE `id` = %i
*		AND `a`.`amount` = `p`.`progression`;
*/
public CA_CheckUniqueAchievement(Handle:hOwner, Handle:hQuery, const String:strError[], any:data) 
{
	// If the query return an error, print it and exit
	if(hQuery == INVALID_HANDLE)
	{
		LogError("[CA_api] CA_CheckUniqueAchievement: Error in the SQL query: %s", strError);
		
		return;
	}

	SQL_FetchRow(hQuery);
	
	// No-one achieved the achievement
	if(SQL_FetchInt(hQuery, 0) == 0)
	{		
		// Format query
		decl String:strQuery[512];
		Format(strQuery, sizeof(strQuery),
		"SELECT `a`.`name`, `p`.`progression` FROM `%sachievements` AS `a` LEFT JOIN `%sprogress` AS `p` ON `a`.`id` = `p`.`achievement_id` WHERE `p`.`steamid` = '%s' AND `id` = %i;",
		g_strDatabasePrefix, g_strDatabasePrefix, g_strPassString[data][ARG_STEAMID], g_iPassInt[data][ARG_ACH_ID]);
		
		SQL_TQuery(g_hDatabaseConnection, CA_ProcessUserAchievement, strQuery, PassArgs(g_iPassInt[data][ARG_CLIENT], g_iPassInt[data][ARG_ACH_ID], g_iPassInt[data][ARG_MAX_PROGRESS], g_iPassInt[data][ARG_ADD_PROGRESS], -1, -1, g_iPassInt[data][ARG_SPECIAL_FLAGS], g_strPassString[data][ARG_STEAMID], g_strPassString[data][ARG_ACH_NAME]));	
	}
	else
	{
		if(g_iPassInt[data][ARG_SPECIAL_FLAGS] & ACHIEVEMENT_DEBUG)
		{
			PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_CheckUniqueAchievement: Unique achievement %i already achieved.", g_iPassInt[data][ARG_ACH_ID]);
		}
	}
}

// ------------------------------------------------------------------------
// CA_ProcessUserAchievement()
// ------------------------------------------------------------------------
// Called by CA_CheckForValidAchievement or CA_CheckUniqueAchievement
// Add the specified progress to the achievement.
// Trigger the achievement effect if the max value is reached.
// ------------------------------------------------------------------------
/*	Previous query:
		SELECT `a`.`name`, `p`.`progression`
		FROM `%sachievements` AS `a`
		LEFT JOIN `%sprogress` AS `p` ON `a`.`id` = `p`.`achievement_id`
		WHERE `p`.`steamid` = '%s'
		AND `id` = %i;
*/
public CA_ProcessUserAchievement(Handle:hOwner, Handle:hQuery, const String:strError[], any:data) 
{
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		LogError("[CA_api] CA_ProcessUserAchievement: Error in the SQL query: %s", strError);
		return;
	}
	
	new iClient = g_iPassInt[data][ARG_CLIENT];
	new iAchievementId = g_iPassInt[data][ARG_ACH_ID];
	new iAchievementMaxValue = g_iPassInt[data][ARG_MAX_PROGRESS];
	new iAddprogress = g_iPassInt[data][ARG_ADD_PROGRESS];
	new iSpecialFlags = g_iPassInt[data][ARG_SPECIAL_FLAGS];
	
	decl String:strSteamId[64];
	strSteamId = g_strPassString[data][ARG_STEAMID];
	
	decl String:strUniqueName[64];
	strUniqueName = g_strPassString[data][ARG_ACH_NAME];
	
	new iRowCount = SQL_GetRowCount(hQuery);
	
	if(iSpecialFlags & ACHIEVEMENT_DEBUG)
	{
		PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessUserAchievement called for achievement %i.", iAchievementId);
	}
	
	decl String:strQuery[512];
	
	// No record, create one
	if(iRowCount == 0)
	{
		// The achievement is achieved
		if(iAddprogress >= iAchievementMaxValue)
		{
			if(iSpecialFlags & ACHIEVEMENT_DEBUG)
			{
				PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessUserAchievement: Creating entry, inserting progress into database and triggering the achievement %i (instant achievement).", iAchievementId);
			}
			
			// Retrieve the current date
			decl String:FormatedDate[64];
			FormatTime(FormatedDate, sizeof(FormatedDate), "%Y%m%d%H%M%S", GetTime());
			
			// Format query (insertion of the record)
			Format(strQuery, sizeof(strQuery), "INSERT INTO `%sprogress` (`steamid`, `achievement_id`, `progression`, `achieved`) VALUES ('%s', %i, %i, %s);", g_strDatabasePrefix, strSteamId, iAchievementId, iAchievementMaxValue, FormatedDate);
			SQL_TQuery(g_hDatabaseConnection, CA_GenericSQLCallBack, strQuery, 0);
			
			// Format query (trigger effects)
			decl String:strQuery2[512];
			Format(strQuery2, sizeof(strQuery2), "SELECT name FROM `%sachievements` WHERE `id` = %i;", g_strDatabasePrefix, iAchievementId);
			
			SQL_TQuery(g_hDatabaseConnection, CA_TriggerAchievement, strQuery2, PassArgs(iClient, iAchievementId, iAchievementMaxValue, iAddprogress, -1, -1, iSpecialFlags, "", strUniqueName));
			
			// Firing forward
			Forward_AchievementProgressed(iAchievementId, strUniqueName, iClient, iAddprogress, 0, iAchievementMaxValue, iSpecialFlags);
			Forward_AchievementTriggered(iAchievementId, strUniqueName, iClient, iSpecialFlags);
		}
		else // Just insert with the actual progress
		{
			if(iSpecialFlags & ACHIEVEMENT_DEBUG)
			{
				PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessUserAchievement: Creating entry and inserting progress %i into database.", iAchievementId);
			}
			Format(strQuery, sizeof(strQuery), "INSERT INTO `%sprogress` (`steamid`, `achievement_id`, `progression`) VALUES ('%s', %i, %i);", g_strDatabasePrefix, strSteamId, iAchievementId, iAddprogress);
			SQL_TQuery(g_hDatabaseConnection, CA_GenericSQLCallBack, strQuery, 1);
			
			// Firing forward
			Forward_AchievementProgressed(iAchievementId, strUniqueName, iClient, iAddprogress, 0, iAchievementMaxValue, iSpecialFlags);
		}
	}
	else if(iRowCount == 1) // A record already exist
	{
		SQL_FetchRow(hQuery);
		
		new iActualProgress = SQL_FetchInt(hQuery, 1);
		
		// Triggering situation
		if(iActualProgress + iAddprogress >= iAchievementMaxValue)
		{
			// Achievement never triggered
			if(iActualProgress != iAchievementMaxValue)
			{
			
				// Retrieve the achievement name
				decl String:strAchievementName[64];
				SQL_FetchString(hQuery, 0, strAchievementName, sizeof(strAchievementName));
				
				if(iSpecialFlags & ACHIEVEMENT_DEBUG)
				{
					PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessUserAchievement: Updating progress into database and triggering achievement %i.", iAchievementId);
				}
				
				// Trigger effect
				AchievementEffect(iClient, iAchievementId, strUniqueName, strAchievementName, iSpecialFlags);
				
				// Retrieve the current date
				decl String:FormatedDate[64];
				FormatTime(FormatedDate, sizeof(FormatedDate), "%Y%m%d%H%M%S", GetTime());
				
				// Format query (update the record)
				Format(strQuery, sizeof(strQuery), "UPDATE `%sprogress` SET `progression` = %i, `achieved` = %s WHERE `steamid` = '%s' AND `achievement_id` = %i;", g_strDatabasePrefix, iAchievementMaxValue, FormatedDate, strSteamId, iAchievementId);
				SQL_TQuery(g_hDatabaseConnection, CA_GenericSQLCallBack, strQuery, 2);
				
				// Firing forward
				Forward_AchievementProgressed(iAchievementId, strUniqueName, iClient, iAddprogress, iActualProgress, iAchievementMaxValue, iSpecialFlags);
				Forward_AchievementTriggered(iAchievementId, strUniqueName, iClient, iSpecialFlags);
			}
			else
			{
				if(iSpecialFlags & ACHIEVEMENT_DEBUG)
				{
					PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessUserAchievement: Player %N already achieved achievement %i.", iClient, iAchievementId);
				}
			}
		}
		else if (iActualProgress + iAddprogress < iAchievementMaxValue) // Just progress
		{
			if(iSpecialFlags & ACHIEVEMENT_DEBUG)
			{
				PrintToChatAll("\x03[CA_api DEBUG]\x01 CA_ProcessUserAchievement: Updating progress %i into database.", iAchievementId);
			}
			
			// Format query (update the record)
			Format(strQuery, sizeof(strQuery), "UPDATE `%sprogress` SET `progression` = `progression`+%i WHERE `steamid` = '%s' AND `achievement_id` = %i;", g_strDatabasePrefix, iAddprogress, strSteamId, iAchievementId);
			SQL_TQuery(g_hDatabaseConnection, CA_GenericSQLCallBack, strQuery, 3);
			
			// Firing forward
			Forward_AchievementProgressed(iAchievementId, strUniqueName, iClient, iAddprogress, iActualProgress, iAchievementMaxValue, iSpecialFlags);
		}
	}
}

// ------------------------------------------------------------------------
// CA_TriggerAchievement()
// ------------------------------------------------------------------------
// Called by CA_ProcessUserAchievement
// Trigger the achievement effect.
// ------------------------------------------------------------------------
/*	Previous query:
*		SELECT name FROM `%sachievements`
*		WHERE `id` = %i;
*/
public CA_TriggerAchievement(Handle:hOwner, Handle:hQuery, const String:strError[], any:data) 
{
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		LogError("[CA_api] CA_TriggerAchievement: Error in the SQL query: %s", strError);
		return;
	}
	SQL_FetchRow(hQuery);
	
	// Retrieve the achievement name
	decl String:strAchievementName[64];
	SQL_FetchString(hQuery, 0, strAchievementName, sizeof(strAchievementName));
	
	// Trigger the effect
	AchievementEffect(g_iPassInt[data][ARG_CLIENT], g_iPassInt[data][ARG_ACH_ID], g_strPassString[data][ARG_ACH_NAME], strAchievementName, g_iPassInt[data][ARG_SPECIAL_FLAGS]);
}

// ------------------------------------------------------------------------
// CA_GetAchievementProgress(iAchievementId, hClient)
// ------------------------------------------------------------------------
// Return the progress of an achievement (Non-threaded query)
// ------------------------------------------------------------------------
public CA_GetAchievementProgress(Handle:hPlugin, numParams)
{
	// Check if the connection to the DB is establihed
	if(!g_bConnectedToDB)
	{
		LogError("[CA_api] CA_GetAchievementProgress: Not connected to the DB");
		return -1;
	}
	
	// Retrieve the parameters
	new iAchievementId = GetNativeCell(1);
	new hClient = GetNativeCell(2);
	
	decl String:edictName[32];
	GetEdictClassname(hClient, edictName, sizeof(edictName));
	
	// Check if the client is valid
	if((!StrEqual(edictName, "player")) || (!IsClientInGame(hClient)) || (InvalidClient(hClient)))
	{
		LogError("[CA_api] CA_GetAchievementProgress call failed, client id %i is invalid.", hClient);
		
		return -1;
	}
	
	// Retrieve the steamid of the player
	decl String:strSteamId[32];
	GetClientAuthString(hClient, strSteamId, sizeof(strSteamId));
	
	//Format query
	decl String:strQuery[512];
	Format(strQuery, sizeof(strQuery), "SELECT `p`.`progression` FROM `%sachievements` AS `a` LEFT JOIN `%sprogress` AS `p` ON `a`.`id` = `p`.`achievement_id` WHERE `p`.`steamid` = '%s' AND `id` = %i;", g_strDatabasePrefix, g_strDatabasePrefix, strSteamId, iAchievementId);
	
	MysqlSetNames();
	
	SQL_LockDatabase(g_hDatabaseConnection);
	new Handle:hQuery = SQL_Query(g_hDatabaseConnection, strQuery);
	
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		decl String:strError[255];
		SQL_GetError(g_hDatabaseConnection, strError, sizeof(strError));
		LogError("[CA_api] CA_GetAchievementProgress: Error in the SQL query: %s", strError);

		SQL_UnlockDatabase(g_hDatabaseConnection);
		return -1;
	}
	SQL_UnlockDatabase(g_hDatabaseConnection);
	
	// We have no result
	if (SQL_GetRowCount(hQuery) == 0)
	{
		CloseHandle(hQuery);
		
		//Format query (check if the achievement exists)
		Format(strQuery, sizeof(strQuery), "SELECT * FROM `%sachievements` WHERE `id` = %i;", g_strDatabasePrefix, iAchievementId);
		
		SQL_LockDatabase(g_hDatabaseConnection);
		new Handle:hQuery2 = SQL_Query(g_hDatabaseConnection, strQuery);
		
		// If the query return an error, print it and exit
		if (hQuery2 == INVALID_HANDLE)
		{
			decl String:strError[255];
			SQL_GetError(g_hDatabaseConnection, strError, sizeof(strError));
			LogError("[CA_api] CA_GetAchievementProgress: Error in the SQL query: %s", strError);

			SQL_UnlockDatabase(g_hDatabaseConnection);
			return -1;
		}
		SQL_UnlockDatabase(g_hDatabaseConnection);
		
		// No result, the achievement doesn't exist
		if (SQL_GetRowCount(hQuery2) == 1)
		{
			CloseHandle(hQuery2);
			LogError("[CA_api] CA_GetAchievementProgress: Achievement %i doesn't exist !", iAchievementId);
			return -1;
		}
		
		// The achivement exists, but the player never triggered it
		return 0;
	}
	
	SQL_FetchRow(hQuery);
	new iProgress = SQL_FetchInt(hQuery, 0);
	CloseHandle(hQuery);

	return iProgress;
}

// ------------------------------------------------------------------------
// CA_IsAchievedByClient(iAchievementId, hClient)
// ------------------------------------------------------------------------
// Says if a Client achieved the specified Achievement (Non-threaded query)
// ------------------------------------------------------------------------
public CA_IsAchievedByClient(Handle:hPlugin, numParams)
{
	// Check if the connection to the DB is establihed
	if(!g_bConnectedToDB)
	{
		LogError("[CA_api] CA_IsAchievedByClient: Not connected to the DB");
		return -1;
	}
	
	// Retrieve the parameters
	new iAchievementId = GetNativeCell(1);
	new hClient = GetNativeCell(2);
	
	decl String:edictName[32];
	GetEdictClassname(hClient, edictName, sizeof(edictName));
	
	// Check if the client is valid
	if((!StrEqual(edictName, "player")) || (!IsClientInGame(hClient)) || (InvalidClient(hClient)))
	{
		LogError("[CA_api] CA_IsAchievedByClient call failed, client id %i is invalid.", hClient);
		return -1;
	}
	
	// Retrieve the steamid of the player
	decl String:strSteamId[32];
	GetClientAuthString(hClient, strSteamId, sizeof(strSteamId));
	
	// Format query (retrieve the max value of the achievement and the actual progress of the client)
	decl String:strQuery[512];
	Format(strQuery, sizeof(strQuery),
	"SELECT `p`.`progression` , `a`.`amount` FROM `%sachievements` AS `a` LEFT JOIN `%sprogress` AS `p` ON `a`.`id` = `p`.`achievement_id` WHERE `p`.`steamid` = '%s' AND `id` = %i;",
	g_strDatabasePrefix, g_strDatabasePrefix, strSteamId, iAchievementId);
	
	MysqlSetNames();
	SQL_LockDatabase(g_hDatabaseConnection);
	new Handle:hQuery = SQL_Query(g_hDatabaseConnection, strQuery);
	
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		decl String:strError[255];
		SQL_GetError(g_hDatabaseConnection, strError, sizeof(strError));
		LogError("[CA_api] CA_IsAchievedByClient: Error in the SQL query: %s", strError);

		SQL_UnlockDatabase(g_hDatabaseConnection);
		return -1;
	}
	SQL_UnlockDatabase(g_hDatabaseConnection);
	
	//We have no result
	if (SQL_GetRowCount(hQuery) == 0)
	{
		CloseHandle(hQuery);
		
		// Format query (check if the achievement exists)
		Format(strQuery, sizeof(strQuery), "SELECT * FROM `%sachievements` WHERE `id` = %i;", g_strDatabasePrefix, iAchievementId);
		
		SQL_LockDatabase(g_hDatabaseConnection);
		new Handle:hQuery2 = SQL_Query(g_hDatabaseConnection, strQuery);
		
		// If the query return an error, print it and exit
		if (hQuery2 == INVALID_HANDLE)
		{
			decl String:strError[255];
			SQL_GetError(g_hDatabaseConnection, strError, sizeof(strError));
			LogError("[CA_api] CA_IsAchievedByClient: Error in the SQL query: %s", strError);

			SQL_UnlockDatabase(g_hDatabaseConnection);
			return -1;
		}
		SQL_UnlockDatabase(g_hDatabaseConnection);
		
		// The achievement doesn't exist
		if (SQL_GetRowCount(hQuery2) != 1)
		{
			CloseHandle(hQuery2);
			LogError("[CA_api] CA_IsAchievedByClient: Achievement %i doesn't exist !", iAchievementId);
			return -1;
		}
		
		// The achivement exists, but the player never triggered it
		return 0;
	}
	
	SQL_FetchRow(hQuery);
	new iProgress = SQL_FetchInt(hQuery, 0);
	new iMaxValue = SQL_FetchInt(hQuery, 1);
	CloseHandle(hQuery);

	return (iProgress == iMaxValue);
}


// ------------------------------------------------------------------------
// CA_IdToName(iAchievementId, String:strAchievementName[64])
// ------------------------------------------------------------------------
// Return the unique name of the specified Achievement (Non-threaded query)
// ------------------------------------------------------------------------
public CA_IdToName(Handle:hPlugin, numParams)
{
	// Check if the connection to the DB is establihed
	if(!g_bConnectedToDB)
	{
		LogError("[CA_api] CA_IdToName: Not connected to the DB");
		return -1;
	}
	
	new iAchievementId = GetNativeCell(1);
	decl String:strAchievementName[64];
	
	// Invalid achievement id
	if(iAchievementId < 0)
	{
		return -1;
	}
	
	// Format query
	decl String:strQuery[512];
	Format(strQuery, sizeof(strQuery), "SELECT unique_name FROM %sachievements WHERE id = %i;", g_strDatabasePrefix, iAchievementId);
	
	MysqlSetNames();
	SQL_LockDatabase(g_hDatabaseConnection);
	new Handle:hQuery = SQL_Query(g_hDatabaseConnection, strQuery);
	
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		decl String:strError[255];
		SQL_GetError(g_hDatabaseConnection, strError, sizeof(strError));
		LogError("[CA_api] CA_IdToName: Error in the SQL query: %s", strError);

		SQL_UnlockDatabase(g_hDatabaseConnection);
		return -1;
	}
	SQL_UnlockDatabase(g_hDatabaseConnection);
	
	// The achievement doesn't exist
	if (SQL_GetRowCount(hQuery) != 1)
	{
		CloseHandle(hQuery);
		LogError("[CA_api] CA_IdToName: Achievement %i doesn't exist !", iAchievementId);
		return -1;
	}

	SQL_FetchRow(hQuery);
	SQL_FetchString(hQuery, 0, strAchievementName, sizeof(strAchievementName));
	CloseHandle(hQuery);
	
	// Achievement exists but doesn't have an unique name
	if(StrEqual(strAchievementName, ""))
	{
		return -1;
	}
	
	
	SetNativeString(2, strAchievementName, sizeof(strAchievementName));
	return 0;
}

// ------------------------------------------------------------------------
// CA_NameToId(strAchievementName)
// ------------------------------------------------------------------------
// Return the id of the specified Achievement (Non-threaded query)
// ------------------------------------------------------------------------
public CA_NameToId(Handle:hPlugin, numParams)
{
	// Check if the connection to the DB is establihed
	if(!g_bConnectedToDB)
	{
		LogError("[CA_api] CA_NameToId: Not connected to the DB");
		return -1;
	}
	
	decl String:strAchievementName[64];
	GetNativeString(1, strAchievementName, sizeof(strAchievementName));
	
	// Format query
	decl String:strQuery[512];
	Format(strQuery, sizeof(strQuery), "SELECT id FROM %sachievements WHERE unique_name = '%s';",	g_strDatabasePrefix, strAchievementName);
	
	MysqlSetNames();
	SQL_LockDatabase(g_hDatabaseConnection);
	new Handle:hQuery = SQL_Query(g_hDatabaseConnection, strQuery);
	
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		decl String:strError[255];
		SQL_GetError(g_hDatabaseConnection, strError, sizeof(strError));
		LogError("[CA_api] CA_NameToId: Error in the SQL query: %s", strError);

		SQL_UnlockDatabase(g_hDatabaseConnection);
		return -1;
	}
	SQL_UnlockDatabase(g_hDatabaseConnection);
	
	// The achievement doesn't exist
	if (SQL_GetRowCount(hQuery) != 1)
	{
		CloseHandle(hQuery);
		LogError("[CA_api] CA_NameToId: Achievement %s doesn't exist !", strAchievementName);
		return -1;
	}
	
	SQL_FetchRow(hQuery);
	new iAchievementId = SQL_FetchInt(hQuery, 0);
	CloseHandle(hQuery);
	
	return iAchievementId;
}

/****************************
*							*
*							*
*		API PART			*
*		END					*
*							*
*							*
*****************************/

/****************************
*							*
*							*
*		DISPLAY PART		*
*		START				*
*							*
*							*
*****************************/

AchievementEffect(client, iAchievementId, const String:strUniqueName[64], const String:strName[], iSpecialFlags)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			new fConditionFlags = TF2_GetPlayerConditionFlags(client);
			
			// No effect when the player is a cloaked or disguised spy
			if(!(fConditionFlags & TF_CONDFLAG_DISGUISED) && !(fConditionFlags & TF_CONDFLAG_CLOAKED))
			{
				if(!(iSpecialFlags & ACHIEVEMENT_NOSOUND))
				{
					new Float:flVec[3];
					GetClientEyePosition(client, flVec);
					// EmitAmbientSound(ACHIEVEMENT_SOUND, flVec, client, SNDLEVEL_RAIDSIREN);
					EmitSoundToAll(ACHIEVEMENT_SOUND, client);
				}
				else
				{
					if(iSpecialFlags & ACHIEVEMENT_DEBUG)
					{
						PrintToChatAll("\x03[CA_api DEBUG]\x01 NOSOUND achievement.");
					}
				}
				
				if(!(iSpecialFlags & ACHIEVEMENT_NOPARTICLE))
				{
					AttachAchievementParticle(client);
				}
				else
				{
					if(iSpecialFlags & ACHIEVEMENT_DEBUG)
					{
						PrintToChatAll("\x03[CA_api DEBUG]\x01 NOPARTICLE achievement.");
					}
				}
			}
		}
		
		if(!(iSpecialFlags & ACHIEVEMENT_NOTEXT))
		{
		
			decl String:strMessage[200];
			
			// Use a translation
			if(iSpecialFlags & ACHIEVEMENT_HAS_TRANSLATION)
			{
				if(iSpecialFlags & ACHIEVEMENT_DEBUG)
				{
					PrintToChatAll("\x03[CA_api DEBUG]\x01 HAS_TRANSLATION achievement.");
				}
			
				// Achievement passed by id
				if(StrEqual(strUniqueName, ""))
				{
					decl String:strAchievementId[8];
					IntToString(iAchievementId, strAchievementId, sizeof(strAchievementId));
					
					Format(strMessage, sizeof(strMessage), "\x03%N\x01 %t \x05%t", client, "Achievement Message", strAchievementId);
					SayText2(client, strMessage);
				}
				else // Achievement passed by name
				{
					Format(strMessage, sizeof(strMessage), "\x03%N\x01 %t \x05%t", client, "Achievement Message", strUniqueName);
					SayText2(client, strMessage);
				}
			}
			else
			{
				Format(strMessage, sizeof(strMessage), "\x03%N\x01 %t \x05%s", client, "Achievement Message", strName);
				SayText2(client, strMessage);
			}
		}
		else
		{
			if(iSpecialFlags & ACHIEVEMENT_DEBUG)
			{
				PrintToChatAll("\x03[CA_api DEBUG]\x01 NOTEXT achievement.");
			}
		}
	}
}

AttachAchievementParticle(client)
{
	new iParticle = CreateEntityByName("info_particle_system");
	
	decl String:strName[128];
	if (IsValidEdict(iParticle))
	{
		new Float:flPos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", flPos);
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		Format(strName, sizeof(strName), "target%i", client);
		DispatchKeyValue(client, "targetname", strName);
		
		DispatchKeyValue(iParticle, "targetname", "tf2particle");
		DispatchKeyValue(iParticle, "parentname", strName);
		DispatchKeyValue(iParticle, "effect_name", ACHIEVEMENT_PARTICLE);
		DispatchSpawn(iParticle);
		SetVariantString(strName);
		AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle, 0);
		SetVariantString("head");
		AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		
		CreateTimer(5.0, Timer_DeleteParticles, iParticle);
	}
}

public Action:Timer_DeleteParticles(Handle:timer, any:iParticle)
{
    if (IsValidEntity(iParticle))
    {
        decl String:strClassname[256];
        GetEdictClassname(iParticle, strClassname, sizeof(strClassname));
		
        if (StrEqual(strClassname, "info_particle_system", false))
        {
            RemoveEdict(iParticle);
        }
    }
}

stock SayText2(iAuthorIndex , const String:strMessage[] )
{
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE)
	{
        BfWriteByte(buffer, iAuthorIndex);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, strMessage);
        EndMessage();
    }
}


public Action:Cmd_ShowPlayerAchievements(client, args)
{
	decl String:strAuthId[32];
	GetClientAuthString(client, strAuthId, sizeof(strAuthId));
	
	decl String:strAchievementsUrl[512];
	GetConVarString(g_Cvar_AchievementsUrl, strAchievementsUrl, sizeof(strAchievementsUrl));
	
	if(!StrEqual(strAchievementsUrl, ""))
	{
		decl String:strDisplayAdress[512];
		Format(strDisplayAdress, sizeof(strDisplayAdress), "%s%s",strAchievementsUrl, strAuthId);

		ShowMOTDPanel(client, "_:", strDisplayAdress, MOTDPANEL_TYPE_URL);
	}
	
	return Plugin_Handled;
}

/****************************
*							*
*							*
*		DISPLAY PART		*
*		END					*
*							*
*							*
*****************************/

/****************************
*							*
*							*
*		MISC PART			*
*		START				*
*							*
*							*
*****************************/

public bool:InvalidClient(client)
{
	if(client < 1)
	{
		return true;
	}
	
	if(!IsClientConnected(client))
	{
		return true;
	}
	
	if(!IsClientInGame(client))
	{
		return true;
	}
	
	if(IsFakeClient(client))
	{
		return true;
	}
	
	decl String:strAuthId[50];
	GetClientAuthString(client, strAuthId, sizeof(strAuthId));
	
	if(StrEqual(strAuthId, "BOT"))
	{
		return true;
	}
	
	return false;
}

public SaveUser(hClient)
{
	if (!g_bConnectedToDB || !GetConVarBool(g_Cvar_StoreNames))
	{
		return;
	}
	
	decl String:strSteamId[128];
	decl String:strName[128];
	decl String:strEscapedName[128];
	
	GetClientAuthString(hClient, strSteamId, sizeof(strSteamId));
	GetClientName(hClient, strName, sizeof(strName));
	SQL_EscapeString(g_hDatabaseConnection, strName, strEscapedName, sizeof(strEscapedName));
	
	decl String:strQuery[512];
	Format(strQuery, sizeof(strQuery), "INSERT INTO `%splayers` (`steamid`, `name`) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE `name` = VALUES(`name`)", g_strDatabasePrefix, strSteamId, strEscapedName);
	MysqlSetNames();
	SQL_TQuery(g_hDatabaseConnection, CA_GenericSQLCallBack, strQuery, 4);
}

// ------------------------------------------------------------------------
// Forward_AchievementTriggered()
// ------------------------------------------------------------------------
// Called whenever a client triggers an achievement
// ------------------------------------------------------------------------
Forward_AchievementTriggered(iAchievementId, String:strAchievementUniqueName[64], iClient, iSpecialFlags)
{
	Call_StartForward(g_hForwardAchievementTriggered);
	Call_PushCell(iAchievementId);
	Call_PushString(strAchievementUniqueName);
	Call_PushCell(iClient);
	Call_PushCell(iSpecialFlags);
	Call_Finish();
}

// ------------------------------------------------------------------------
// Forward_AchievementProgressed()
// ------------------------------------------------------------------------
// Called whenever a client progresses an achievement
// ------------------------------------------------------------------------
Forward_AchievementProgressed(iAchievementId, String:strAchievementUniqueName[64], iClient, iProgress, iOldProgress, iMaxProgress, iSpecialFlags)
{
	Call_StartForward(g_hForwardAchievementProgressed);
	Call_PushCell(iAchievementId);
	Call_PushString(strAchievementUniqueName);
	Call_PushCell(iClient);
	Call_PushCell(iProgress);
	Call_PushCell(iOldProgress);
	Call_PushCell(iMaxProgress);
	Call_PushCell(iSpecialFlags);
	Call_Finish();
}

// ------------------------------------------------------------------------
// Cmd_PrintAchievementsList
// ------------------------------------------------------------------------
// Called by the sm_ca_api_list console command
// Print the list of achievements stored in the database
// ------------------------------------------------------------------------
public Action:Cmd_PrintAchievementsList(client, args)
{
	// Check if the connection to the DB is establihed
	if(!g_bConnectedToDB)
	{
		ReplyToCommand(client, "Not connected to the DB.");
		LogError("[CA_api] Cmd_PrintAchievementsList: Not connected to the DB");
		return Plugin_Handled;
	}

	decl String:strQuery[512];
	Format(strQuery, sizeof(strQuery), "SELECT id, unique_name, name, description, amount FROM `%sachievements`", g_strDatabasePrefix);
		
	SQL_LockDatabase(g_hDatabaseConnection);
	new Handle:hQuery = SQL_Query(g_hDatabaseConnection, strQuery);
	
	// If the query return an error, print it and exit
	if (hQuery == INVALID_HANDLE)
	{
		decl String:strError[255];
		SQL_GetError(g_hDatabaseConnection, strError, sizeof(strError));
		LogError("[CA_api] PrintAchievementsList: Error in the SQL query: %s", strError);

		SQL_UnlockDatabase(g_hDatabaseConnection);
		ReplyToCommand(client, "Unable to retrieve the achievement list.");
		return Plugin_Handled;
	}
	SQL_UnlockDatabase(g_hDatabaseConnection);
	
	
	if (SQL_GetRowCount(hQuery) == 0)
	{
		CloseHandle(hQuery);
		
		ReplyToCommand(client, "No achievements.");
	}
	else
	{
		ReplyToCommand(client, "#id \t Unique Name \t Name \t Description \t Trigger value");
		
		decl String:strAchievementUniqueName[64];
		decl String:strAchievementName[64];
		decl String:strAchievementDescription[200];
		while(SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 1, strAchievementUniqueName, sizeof(strAchievementUniqueName));
			
			if(StrEqual(strAchievementUniqueName, ""))
			{
				strAchievementUniqueName = "UNKNOWN";
			}
			
			SQL_FetchString(hQuery, 2, strAchievementName, sizeof(strAchievementName));
			SQL_FetchString(hQuery, 3, strAchievementDescription, sizeof(strAchievementDescription));
			ReplyToCommand(client, "%i \t %s \t %s \t\t %s \t %i", 
							SQL_FetchInt(hQuery, 0), strAchievementUniqueName, strAchievementName, strAchievementDescription, SQL_FetchInt(hQuery, 4));
			
		}
		CloseHandle(hQuery);
	}

	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// MysqlSetNames()
// ------------------------------------------------------------------------
// Set NAMES to UTF8 before sendind the query
// ------------------------------------------------------------------------
MysqlSetNames()
{
	SQL_TQuery(g_hDatabaseConnection, CA_GenericSQLCallBack, "SET NAMES 'utf8'", 5);
}

// ------------------------------------------------------------------------
// TablePrefixChange()
// ------------------------------------------------------------------------
// Update g_strDatabasePrefix when sm_achievementsapi_db_tableprefix is changed.
// ------------------------------------------------------------------------
public TablePrefixChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(g_Cvar_DBTablePrefix, g_strDatabasePrefix, sizeof(g_strDatabasePrefix));
}

/****************************
*							*
*							*
*		MISC PART			*
*		END					*
*							*
*							*
*****************************/