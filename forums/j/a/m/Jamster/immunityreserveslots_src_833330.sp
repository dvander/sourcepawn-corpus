/**
 * ==================================================================================
 *  Immunity Reserve Slots Change Log
 * ==================================================================================
 * 
 * 0.1
 * - Initial release.
 * 
 * 0.2
 * - Added lowest time option to kick types.
 * - Added cvars to control kick message for normal kick and immunity kick.
 * - Small optimizations.
 * 
 * 0.3
 * - Fixed some logging bugs.
 * - Fixed a major bug in the immunity check and optimised regular check.
 *
 * 0.3.1
 * - Fixed a very small bug in the logging code to do with detecting spectators.
 *
 * 0.3.2
 * - Added option to only log who gets kicked.
 *
 * 0.3.3
 * - Added cvar to control whether or not spectators get kicked first before other 
 *   players or not (defaults to enabled).
 *
 * 0.3.4
 * - Added a cvar option to limit the maximum amount of players with high immunity 
 *   to kick low immunity players when the server is full (if more than the value 
 *   are connected at the time no further connections will be allowed).
 * - A bit of code clean up.
 *
 * 1.0
 * - Made final.
 * - Added full translation support.
 * - Changed the way the reason cvars work, no config changes needed for old users.
 *
 * 1.0.1
 * - Added cvar "sm_irs_keepbalance", this will try and keep team balance best as 
 *   possible when kicking players as not to trigger an autobalance. 
 * - Drastic recoding for better performance.
 * - Added use of AskPluginLoad2() for improved late load detection (this makes the
 *   plugin require SM 1.3 now).
 * - Added detection of accidental installation of the default test plugin for
 *   CBaseServer tools to avoid any possible problems.
 * - New verbose logs, now create their own log files instead of spamming regular 
 *   logs. Also improved verbosity.
 * - Fixed a small leak which happened if any logging was disabled.
 * - Spec check now uses a team check instead as in some games it could "incorrectly" 
 *   flag users as spectating when they were dead. Also flags unassigned players now.
 *
 * 1.0.2
 * - Fixed incorrect statement in balance check code.
 * - Small optimisations.
 * - Added command check back in for "sm_reskick_immunity" as some servers might
 *   expect this as a valid way to grant default immunity if reading the official
 *   SM wiki.
 * - Added the regular SM reserve slot plugin to the plugin checks on startup.
 *
 * 1.0.3
 * - Made the default action for detected reserve plugins to move to the disabled
 *   folder after unload rather than stopping the plugin.
 * - Changed translation phrase on plugin error to make more sense.
 *
 * 1.0.4
 * - Made use of GetURandomFloat for random mode.
 * - Improved logging code.
 *
 * 2.0
 * - Added Connect extension support.
 * - Added cvars to configure the reject message on a full server 
 *   (sm_irs_rejectreason_enable and sm_irs_rejectreason).
 *
 * 2.0.1
 * - Added auto password cvar so reserve clients can automatically connect to 
 *   password protected servers, can also be set so any connecting client can
 *   connect e.g. for temporary purposes (sm_irs_autopassword).
 * - Fixed bug in keep balance code where it wouldn't kick spectators if there were
 *   any when the cvar for kick spectators first was disabled.
 * - Added kick list mode, this allows anyone to connect to the server (configurable)
 *   but goes through a list of steam id's for who should get kicked vs who can 
 *   connect (sm_irs_kicklist_mode and sm_irs_kicklist_file).
 * - Removed sm_rescheck_mmunity command check thing I still had in there where it
 *   wouldn't have mattered anyway (i.e. I missed it).
 *
 * 2.0.2
 * - Recoded kick list mode for less disk I/O.
 * - Fixed a bug if kick list mode was set to 2 which could create a possible rare
 *   looping slot scenario. 
 * - Added command to reload the kick list if users want to update the list as soon
 *   as possible (sm_irs_kicklist_reload), list now also updates automatically on
 *   map change properly.
 * - Cleaned up some code.
 *
 * 2.0.3
 * - Fixed CloseHandle() bug.
 *
 * 2.0.4
 * - Fix for too many clients connecting in MVM games. Connect only.
 *
 * 2.0.5
 * - Fix for non-TF2 games throwing errors on map start. Connect only.
 *
 * 2.0.6
 * - Code cleanup.
 * - Added support for Connect 1.2.0+.
 *
 * 2.0.7
 * - Added donator plugin support 
 *   (see: http://forums.alliedmods.net/showthread.php?t=145542).
 *
 * 2.0.8
 * - Added cvar to control when to kick spectators (sm_irs_kickspecdelay, set to 0
 *   instantly kicks spectators, anything else gives them a grace of x secs before
 *   being kicked).
 * ==================================================================================
 */

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <donator>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "2.0.8"

// Toggle build here.
#define EXT_CBASE 1
#define EXT_CONNECT 0

// Anti-Jamster protection scheme.
#if EXT_CONNECT && EXT_CBASE
#define EXT_CBASE 0
#endif

#if EXT_CBASE
#include <cbaseserver>
#endif

#if EXT_CONNECT
#define MAX_CLIENTS_MVM 6
#include <connect>
#endif

new TEAM1;
new TEAM2;
new SPEC;

new bool:g_HighImmunityPlayers[MAXPLAYERS+1];
new bool:b_lateLoad;
new bool:b_loaded;
new bool:b_useDonator;
new bool:b_canKickSpec[MAXPLAYERS+1];

new g_HIPCount;

new Handle:cvar_KickType = INVALID_HANDLE;
new Handle:cvar_Spec = INVALID_HANDLE;
new Handle:cvar_SpecKickDelay = INVALID_HANDLE;
new Handle:cvar_Logging = INVALID_HANDLE;
new Handle:cvar_Immunity = INVALID_HANDLE;
new Handle:cvar_KickReasonImmunity = INVALID_HANDLE;
new Handle:cvar_KickReason = INVALID_HANDLE;
new Handle:cvar_HighImmunityLimit = INVALID_HANDLE;
new Handle:cvar_HighImmunityValue = INVALID_HANDLE;
new Handle:cvar_KeepBalance = INVALID_HANDLE;
new Handle:cvar_KickListMode = INVALID_HANDLE;
new Handle:cvar_KickListFile = INVALID_HANDLE;
new Handle:cvar_Donator = INVALID_HANDLE;
new Handle:cvar_DonatorImmunity = INVALID_HANDLE;

new Handle:arr_KickListIDs = INVALID_HANDLE;

new Handle:t_KickSpecClient[MAXPLAYERS+1] = INVALID_HANDLE;

#if EXT_CONNECT
new bool:isMVM = false;
new Handle:cvar_AutoPassword = INVALID_HANDLE;
new Handle:cvar_RejectReason = INVALID_HANDLE;
new Handle:cvar_RejectReasonEnable = INVALID_HANDLE;
new Handle:cvar_GameTypeMVM = INVALID_HANDLE;
#endif

new String:g_LogFilePath[PLATFORM_MAX_PATH];

public Plugin:myinfo = 
{
	#if EXT_CBASE
	name = "Immunity Reserve Slots [CBASESERVER]",
	#endif
	#if EXT_CONNECT
	name = "Immunity Reserve Slots [CONNECT]",
	#endif
	author = "Jamster",
	description = "Immunity based reserve slots for CBaseServer Tools and Connect extensions",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("immunityreserveslots.phrases");
	decl String:desc[255];
	
	arr_KickListIDs = CreateArray(32);
	b_loaded = false;
	
	#if EXT_CONNECT
	
	Format(desc, sizeof(desc), "%t", "irs_autopassword");
	cvar_AutoPassword = CreateConVar("sm_irs_autopassword", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	Format(desc, sizeof(desc), "%t", "irs_rejectreason_enable");
	cvar_RejectReasonEnable = CreateConVar("sm_irs_rejectreason_enable", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "irs_rejectreason");
	cvar_RejectReason = CreateConVar("sm_irs_rejectreason", "default", desc, FCVAR_PLUGIN);
	
	cvar_GameTypeMVM = FindConVar("tf_gamemode_mvm");
	
	#endif
	
	Format(desc, sizeof(desc), "%t", "irs_version");
	CreateConVar("sm_irs_version", PLUGIN_VERSION, desc, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Format(desc, sizeof(desc), "%t", "irs_kicktype");
	cvar_KickType = CreateConVar("sm_irs_kicktype", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 3.0);
	
	Format(desc, sizeof(desc), "%t", "irs_kickreason");
	cvar_KickReason = CreateConVar("sm_irs_kickreason", "default", desc, FCVAR_PLUGIN);
	
	Format(desc, sizeof(desc), "%t", "irs_kickreason_immunity");
	cvar_KickReasonImmunity = CreateConVar("sm_irs_kickreason_immunity", "default", desc, FCVAR_PLUGIN);
	
	Format(desc, sizeof(desc), "%t", "irs_kicklist_file");
	cvar_KickListFile = CreateConVar("sm_irs_kicklist_file", "default", desc, FCVAR_PLUGIN);
	
	Format(desc, sizeof(desc), "%t", "irs_kicklist_mode");
	cvar_KickListMode = CreateConVar("sm_irs_kicklist_mode", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	Format(desc, sizeof(desc), "%t", "irs_log");
	cvar_Logging = CreateConVar("sm_irs_log", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	Format(desc, sizeof(desc), "%t", "irs_immunity");
	cvar_Immunity = CreateConVar("sm_irs_immunity", "1", desc, FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	Format(desc, sizeof(desc), "%t", "irs_kickspecfirst");
	cvar_Spec = CreateConVar("sm_irs_kickspecfirst", "1", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "irs_kickspecdelay");
	cvar_SpecKickDelay = CreateConVar("sm_irs_kickspecdelay", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "irs_donator_support");
	cvar_Donator = CreateConVar("sm_irs_donator_support", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "irs_donator_immunity");
	cvar_DonatorImmunity = CreateConVar("sm_irs_donator_immunity", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 99.0);
	
	Format(desc, sizeof(desc), "%t", "irs_highimmunitylimit");
	cvar_HighImmunityLimit = CreateConVar("sm_irs_highimmunitylimit", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "irs_highimmunityvalue");
	cvar_HighImmunityValue = CreateConVar("sm_irs_highimmunityvalue", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "irs_keepbalance");
	cvar_KeepBalance = CreateConVar("sm_irs_keepbalance", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "irs_kicklist_reload");
	RegServerCmd("sm_irs_kicklist_reload", Command_KickListReload, desc);
	
	HookConVarChange(cvar_KickListFile, KickListFileChanged);
	HookConVarChange(cvar_KickListMode, KickListConVarChanged);
	
	AddCommandListener(listen_join_team, "jointeam");
	AddCommandListener(listen_join_team, "spectate");

	AutoExecConfig(true, "plugin.immunityreserveslots");
}

public OnConfigsExecuted()
{
	LoadKickList();
	
	#if EXT_CONNECT
	
	if (cvar_GameTypeMVM != INVALID_HANDLE && GetConVarInt(cvar_GameTypeMVM))
	{
		isMVM = true;
	}
	else
	{
		isMVM = false;
	}
	
	#endif
		
	b_loaded = true;
	
	if (GetConVarInt(cvar_Donator) && !b_useDonator)
	{
		LogError("%t", "IRS Donator Plugin Error");
	}
}

public OnMapEnd()
{
	b_loaded = false;
}

public KickListFileChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (!StrEqual(oldValue, newValue, false) && b_loaded)
	{
		LoadKickList();
	}
}

public KickListConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (newValue[0] != 0 && b_loaded)
	{
		LoadKickList();
	}
}

public Action:Command_KickListReload(client)
{	
	if (LoadKickList())
	{
		ReplyToCommand(client, "%t", "IRS Kick List Reloaded");
	}
	return Plugin_Handled;
}

LoadKickList()
{
	ClearArray(arr_KickListIDs);
	if (GetConVarInt(cvar_KickListMode))
	{
		decl String:path[PLATFORM_MAX_PATH];
		GetConVarString(cvar_KickListFile, path, sizeof(path));
		if (StrEqual(path, "default", false))
		{
			BuildPath(Path_SM, path, sizeof(path), "configs/irs_kicklist.ini");
		}
		
		new Handle:h_path = OpenFile(path, "r");
		if (h_path == INVALID_HANDLE)
		{
			LogError("%t", "IRS Kick List Path Error", path);
		}
		else
		{
			decl String:line[32];
			while (!IsEndOfFile(h_path))
			{
				ReadFileLine(h_path, line, sizeof(line));
				TrimString(line);
				// Yep, I ain't checking if STEAMID's are valid, I'm raw like that.
				if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
				{
					PushArrayString(arr_KickListIDs, line);
				}
			}
			CloseHandle(h_path);
			return true;
		}
	}
	
	return false;
}

public OnAllPluginsLoaded()
{
	b_useDonator = LibraryExists("donator.core");
	
	new Handle:h_Plugin;
	new Handle:arr_Plugins = CreateArray(64);
	decl String:plugin[64];
	
	PushArrayString(arr_Plugins, "cbaseservertest.smx");
	PushArrayString(arr_Plugins, "cbsext_reserves.smx");
	PushArrayString(arr_Plugins, "reservedslots.smx");
	PushArrayString(arr_Plugins, "immunityreserveslots.smx");
	
	#if EXT_CBASE
	
	PushArrayString(arr_Plugins, "immunityreserveslots_connect.smx");
	
	#endif
	
	#if EXT_CONNECT
	
	PushArrayString(arr_Plugins, "immunityreserveslots_cbase.smx");
	
	#endif
	
	new index = GetArraySize(arr_Plugins);
	
	for (new i=0; i<index; i++)
	{
		GetArrayString(arr_Plugins, i, plugin, sizeof(plugin));
		h_Plugin = FindPluginByFile(plugin);
		if (h_Plugin != INVALID_HANDLE)
		{
			CloseHandle(h_Plugin);
			LogError("%t", "IRS Plugin Error", plugin);
			IRS_RemovePlugin(plugin);
		}
	}
	
	CloseHandle(arr_Plugins);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "donator.core"))
	{
		b_useDonator = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "donator.core"))
	{
		b_useDonator = true;
	}
}

IRS_RemovePlugin(const String:plugin_name[])
{
	decl String:plugin[PLATFORM_MAX_PATH];
	decl String:dir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, plugin, sizeof(plugin), "plugins/%s", plugin_name);
	BuildPath(Path_SM, dir, sizeof(dir), "plugins/disabled", plugin_name);
	
	ServerCommand("sm plugins unload %s", plugin_name);
	
	if (!DirExists(dir))
	{
		CreateDirectory(dir, FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC);
	}
	
	Format(dir, sizeof(dir), "%s/%s", dir, plugin_name);
	RenameFile(dir, plugin);
}

public OnMapStart()
{
	g_HIPCount = 0;
	
	if (b_lateLoad)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			g_HighImmunityPlayers[i] = false;
			if (IsClientConnected(i))
			{
				OnClientPostAdminCheck(i);
			}
		}
		b_lateLoad = false;
	}
}

#if EXT_CONNECT
GetRealClientCount()
{
	new ClientCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			ClientCount++;
		}
	}
	
	return ClientCount;
}

public bool:OnClientPreConnectEx(const String:name[], String:password[255], const String:ip[], const String:steamID[], String:rejectReason[255])
{	
	new AdminId:AdminID = FindAdminByIdentity(AUTHMETHOD_STEAM, steamID);
	
	//decl String:Time[32];
	//FormatTime(Time, sizeof(Time), "%Y%m%d");
	//BuildPath(Path_SM, g_LogFilePath, sizeof(g_LogFilePath), "logs/irslogs_%s.log", Time);
	
	//LogToFileEx(g_LogFilePath, "[DEBUG] %s (%s) connecting", name, steamID);
	
	new bool:isDonator = false;
	if (b_useDonator && GetConVarInt(cvar_Donator))
	{
		isDonator = FindDonatorBySteamId(steamID);
	}
	
	if (GetConVarInt(cvar_AutoPassword) == 2 || (GetConVarInt(cvar_AutoPassword) == 1 && (GetAdminFlag(AdminID, Admin_Reservation) || isDonator)))
	{
		//LogToFileEx(g_LogFilePath, "[DEBUG] Giving connecting client the server password to allow connection");
		GetConVarString(FindConVar("sv_password"), password, sizeof(password));
	}
	
	if (!isMVM && GetClientCount(false) < MaxClients)
	{
		//LogToFileEx(g_LogFilePath, "[DEBUG] Game is not full or MVM game mode is disabled");
		return true;
	}
		
	if (isMVM && GetRealClientCount() < MAX_CLIENTS_MVM)
	{
		//LogToFileEx(g_LogFilePath, "[DEBUG] Game is MVM but there's still room available (%d clients connected)", GetRealClientCount());
		return true;
	}
		
	if (GetConVarInt(cvar_KickListMode) == 2)
	{
		//LogToFileEx(g_LogFilePath, "[DEBUG] Running kicklist check");
		if (FindStringInArray(arr_KickListIDs, steamID) != -1)
		{
			//LogToFileEx(g_LogFilePath, "[DEBUG] Connecting client is found in kicklist, refusing connection");
			if (GetConVarInt(cvar_RejectReasonEnable) || isMVM)
			{
				GetConVarString(cvar_RejectReason, rejectReason, sizeof(rejectReason));
				if (StrEqual(rejectReason, "default", false))
				{
					Format(rejectReason, sizeof(rejectReason), "%t", "IRS Reject Reason");
				}
				return false;
			}
			else
			{
				return true;
			}
		}
	}
	
	if (GetAdminFlag(AdminID, Admin_Reservation) || isDonator || GetConVarInt(cvar_KickListMode) == 2)
	{
		// DONATOR LEVEL CHECK HERE WHEN POSSIBLE VIA STEAMID
			
		//LogToFileEx(g_LogFilePath, "[DEBUG] Checking for a valid client to kick for connecting client");
		new ImmunityLevel = GetAdminImmunityLevel(AdminID);
		if (ImmunityLevel == 0 && isDonator)
		{
			ImmunityLevel = GetConVarInt(cvar_DonatorImmunity);
		}
		
		if (IRS_KickValidClient(AdminID, name, steamID, ImmunityLevel, isDonator))
		{
			//LogToFileEx(g_LogFilePath, "[DEBUG] Plugin has made successful kick and will now allow client to connect");
			return true;
		}
		else if (GetConVarInt(cvar_RejectReasonEnable) || isMVM)
		{
			GetConVarString(cvar_RejectReason, rejectReason, sizeof(rejectReason));
			if (StrEqual(rejectReason, "default", false))
			{
				Format(rejectReason, sizeof(rejectReason), "%t", "IRS Reject Reason");
			}
			//LogToFileEx(g_LogFilePath, "[DEBUG] No slot for connecting client, refusing connection (rejection mode)");
			return false;
		}
		//else
		//{
			//LogToFileEx(g_LogFilePath, "[DEBUG] No slot for connecting client, refusing connection (normal)");
		//}
	}
	
	if (isMVM)
	{
		//LogToFileEx(g_LogFilePath, "[DEBUG] MVM game is full, refusing connection");
		GetConVarString(cvar_RejectReason, rejectReason, sizeof(rejectReason));
		if (StrEqual(rejectReason, "default", false))
		{
			Format(rejectReason, sizeof(rejectReason), "%t", "IRS Reject Reason");
		}
		return false;
	}
	
	//LogToFileEx(g_LogFilePath, "[DEBUG] End of preconnection code");
	
	return true;
}
#endif

#if EXT_CBASE
public OnClientPreConnect(const String:name[], const String:pass[], const String:ip[], const String:authid[])
{
	if (GetClientCount(false) < MaxClients)
	{
		return;	
	}
	
	new bool:isDonator = false;
	if (b_useDonator && GetConVarInt(cvar_Donator))
	{
		isDonator = FindDonatorBySteamId(authid);
	}
		
	if (GetConVarInt(cvar_KickListMode) == 2)
	{
		if (FindStringInArray(arr_KickListIDs, authid) != -1)
		{
			return;
		}
	}
	
	new AdminId:AdminID = FindAdminByIdentity(AUTHMETHOD_STEAM, authid);
	
	// DONATOR LEVEL CHECK HERE WHEN POSSIBLE VIA STEAMID
	
	new ImmunityLevel = GetAdminImmunityLevel(AdminID);
	if (ImmunityLevel == 0 && isDonator)
	{
		ImmunityLevel = -1;
	}
	
	if (GetAdminFlag(AdminID, Admin_Reservation) || isDonator || GetConVarInt(cvar_KickListMode) == 2)
	{
		IRS_KickValidClient(AdminID, name, authid, GetAdminImmunityLevel(AdminID), isDonator);
	}
}
#endif

IRS_LogClient(const client, const team, const immunity, const Float:value = -1.0)
{
	decl String:TeamName[32];
	GetTeamName(team, TeamName, sizeof(TeamName));
	if (value == -1.0)
	{
		if (IsClientInGame(client))
		{
			LogToFileEx(g_LogFilePath, "%02d: \"%N\" [i: %02d] (%s)", client, client, immunity, TeamName);
		}
		else
		{
			LogToFileEx(g_LogFilePath, "%02d: \"%N\" [i: %02d] (Connecting)", client, client, immunity);
		}
	}
	else
	{
		if (IsClientInGame(client))
		{
			LogToFileEx(g_LogFilePath, "%02d: \"%N\" [i: %02d] [v: %f] (%s)", client, client, immunity, value, TeamName);
		}
		else
		{
			LogToFileEx(g_LogFilePath, "%02d: \"%N\" [i: %02d] (Connecting)", client, client, immunity);
		}
	}
}

bool:IRS_KickValidClient(const AdminId:ConnectingClientAdminID, const String:ConnectingClientName[], const String:ConnectingClientAuthID[], const ConnectingClientImmunity, const isDonator)
{	
	decl String:Time[32];
	FormatTime(Time, sizeof(Time), "%Y%m%d");
	BuildPath(Path_SM, g_LogFilePath, sizeof(g_LogFilePath), "logs/irslogs_%s.log", Time);
	
	new KickType = GetConVarInt(cvar_KickType);
	new Logging = GetConVarInt(cvar_Logging);	
	new Immunity = GetConVarInt(cvar_Immunity);
	new SpecKick = GetConVarInt(cvar_Spec);
	new SpecKickDelay = GetConVarInt(cvar_SpecKickDelay);
	new Donator = GetConVarInt(cvar_Donator);
	new DonatorImmunityValue = GetConVarInt(cvar_DonatorImmunity);
		
	new bool:useKeepBalance;
	new bool:immunityKick;
	new bool:useKickList;
	
	new LowestImmunityLevel = 100;
	new ClientImmunity[MAXPLAYERS+1];
	new ClientDonator[MAXPLAYERS+1];
	new countTEAM1;
	new countTEAM2;
	new clientTeam[MAXPLAYERS+1] = -1;
	new useTeam;
	new HighestSpecValueId;	
	new HighestValueId;
	new HighestBalanceValueId;
	
	new Float:HighestBalanceValue;
	new Float:HighestValue;
	new Float:HighestSpecValue;
	new Float:value;
	
	if (Logging == 1)
	{
		LogToFileEx(g_LogFilePath, "-- Beginning Check --");
	}
	
	if (GetConVarInt(cvar_KeepBalance))
	{
		useKeepBalance = true;
		countTEAM1 = GetTeamClientCount(TEAM1);
		countTEAM2 = GetTeamClientCount(TEAM2);
		if (countTEAM1 == countTEAM2)
		{
			useKeepBalance = false;
		}
		else if (countTEAM1 > countTEAM2)
		{
			useTeam = TEAM1;
		}
		else
		{
			useTeam = TEAM2;
		}
		
		if (Logging == 1)
		{
			if (useKeepBalance)
			{
				decl String:TeamName[32];
				GetTeamName(useTeam, TeamName, sizeof(TeamName));
				LogToFileEx(g_LogFilePath, "Balance check: Team \"%s\" has the most players (%02d | %02d)", TeamName, countTEAM1, countTEAM2);
			}
			else
			{
				LogToFileEx(g_LogFilePath, "Balance check: Teams are the same size");
			}
		}
	}
	
	// Look at how lazy I am.
	if (GetArraySize(arr_KickListIDs))
	{
		useKickList = true;
	}
	else
	{
		useKickList = false;
	}
		
	for (new i=1; i<=MaxClients; i++)
	{	
		if (!IsClientConnected(i))
		{
			if (Logging == 1)
			{
				LogToFileEx(g_LogFilePath, "%02d: NOT CONNECTED", i);
			}
			continue;
		}
			
		if (IsFakeClient(i))
		{
			if (Logging == 1)
			{
				LogToFileEx(g_LogFilePath, "%02d: BOT", i);
			}
			continue;
		}
		
		if (IsClientInGame(i))
		{
			clientTeam[i] = GetClientTeam(i);
		}
			
		decl String:PlayerAuth[32];
		GetClientAuthString(i, PlayerAuth, sizeof(PlayerAuth));
		new AdminId:PlayerAdmin = FindAdminByIdentity(AUTHMETHOD_STEAM, PlayerAuth)
		ClientImmunity[i] = GetAdminImmunityLevel(PlayerAdmin);
		
		if (b_useDonator && Donator)
		{
			if (IsPlayerDonator(i))
			{
				ClientDonator[i] = true;
			}
			if (ClientImmunity[i] == 0)
			{
				ClientImmunity[i] = DonatorImmunityValue;
			}
		}
		
		// Kick list check, if the player isn't found then they're excluded.
		if (useKickList)
		{
			if (FindStringInArray(arr_KickListIDs, PlayerAuth) == -1)
			{
				if (Logging == 1)
				{
					IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
				}
				continue;
			}
		}
		
		// Removed the check for root as it seems this doesn't matter any more in modern SM versions (1.3+), or it never did and I'm terrible.
		if (GetAdminFlag(PlayerAdmin, Admin_Reservation) || ClientDonator[i])
		{
			if (Immunity && ClientImmunity[i] < LowestImmunityLevel)
			{
				LowestImmunityLevel = ClientImmunity[i];
			}
			if (Logging == 1)
			{
				IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
			}
			continue;
		}
		
		if (Immunity == 2 && ClientImmunity[i] > 0)
		{
			if (Logging == 1)
			{
				IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
			}
			continue;
		}
			
		if (IsClientInGame(i))
		{
			switch (KickType)
			{
				case 0:
					value = GetURandomFloat();
				case 1:
					value = GetClientAvgLatency(i, NetFlow_Outgoing);
				case 2:
					value = GetClientTime(i);
				case 3:
					value = GetClientTime(i);
			}
			
			if (KickType == 3 && !HighestValue)
			{
				HighestValue = value;
			}
			
			if ((clientTeam[i] == SPEC || clientTeam[i] == 0) && (SpecKick || useKeepBalance))
			{
				if (SpecKickDelay && b_canKickSpec[i] || !SpecKickDelay)
				{
					if (KickType == 3 && !HighestSpecValue)
					{
						HighestSpecValue = value;
					}
					
					if (KickType == 3 && value <= HighestSpecValue)
					{
						HighestSpecValue = value;
						HighestSpecValueId = i;
					}
					else if (KickType != 3 && value >= HighestSpecValue)
					{
						HighestSpecValue = value;
						HighestSpecValueId = i;
					}
				}
			} 
			else if (KickType == 3 && value <= HighestValue)
			{
				HighestValue = value;
				HighestValueId = i;
			} 
			else if (KickType != 3 && value >= HighestValue)
			{
				HighestValue = value;
				HighestValueId = i;
			}
			
			if (useKeepBalance && clientTeam[i] == useTeam)
			{
				if (KickType == 3 && !HighestBalanceValue)
				{
					HighestBalanceValue = value;
				}
				
				if (KickType == 3 && value <= HighestBalanceValue)
				{
					HighestBalanceValue = value;
					HighestBalanceValueId = i;
				}
				else if (KickType != 3 && value >= HighestBalanceValue)
				{
					HighestBalanceValue = value;
					HighestBalanceValueId = i;
				}
			}	
		}

		if (Logging == 1)
		{
			IRS_LogClient(i, clientTeam[i], ClientImmunity[i], value);
		}
	}
		
	if (Logging == 1)
	{
		decl String:ConnectingClientAdminName[32];
		if (ConnectingClientAdminID != INVALID_ADMIN_ID)
		{
			GetAdminUsername(ConnectingClientAdminID, ConnectingClientAdminName, sizeof(ConnectingClientAdminName));
		}
		else if (isDonator)
		{
			Format(ConnectingClientAdminName, sizeof(ConnectingClientAdminName), "DONATOR");
		}
		else
		{
			Format(ConnectingClientAdminName, sizeof(ConnectingClientAdminName), "ADMIN_NAME_ERROR");
		}
		LogToFileEx(g_LogFilePath, "Connecting player \"%s\" (cfg: \"%s\") [%02d]", ConnectingClientName, ConnectingClientAdminName, ConnectingClientImmunity);
		LogToFileEx(g_LogFilePath, "Lowest immunity: %02d", LowestImmunityLevel);
		LogToFileEx(g_LogFilePath, "High immunity player count: %d", g_HIPCount);
		LogToFileEx(g_LogFilePath, "Max player count: %d", MaxClients);
	}
	
	// Two Loops Supremacy
	if (Immunity && !HighestValueId && !HighestSpecValueId)
	{			
		if (Logging == 1)
		{
			LogToFileEx(g_LogFilePath, "All players immune, running extra immunity check");
		}
		
		immunityKick = true;
		
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientConnected(i))
			{
				if (Logging == 1)
				{
					LogToFileEx(g_LogFilePath, "%02d: NOT CONNECTED", i);
				}
				continue;
			}
				
			if (IsFakeClient(i))
			{
				if (Logging == 1)
				{
					LogToFileEx(g_LogFilePath, "%02d: BOT", i);
				}
				continue;
			}
			
			if (useKickList)
			{
				decl String:PlayerAuth[32];
				GetClientAuthString(i, PlayerAuth, sizeof(PlayerAuth));
				if (FindStringInArray(arr_KickListIDs, PlayerAuth) == -1)
				{
					if (Logging == 1)
					{
						IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
					}
					continue;
				}
			}
			
			if (ClientImmunity[i] > LowestImmunityLevel)
			{
				if (Logging == 1)
				{
					IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
				}
				continue;
			}
				
			if (ClientImmunity[i] >= ConnectingClientImmunity)
			{
				if (Logging == 1)
				{
					IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
				}
				continue;
			}
				
			if (IsClientInGame(i))
			{
				switch (KickType)
				{
					case 0:
						value = GetURandomFloat();
					case 1:
						value = GetClientAvgLatency(i, NetFlow_Outgoing);
					case 2:
						value = GetClientTime(i);
					case 3:
						value = GetClientTime(i);
				}
				
				if (KickType == 3 && !HighestValue)
				{
					HighestValue = value;
				}
				
				if ((clientTeam[i] == SPEC || clientTeam[i] == 0) && (SpecKick || useKeepBalance))
				{							
					if (SpecKickDelay && b_canKickSpec[i] || !SpecKickDelay)
					{
						if (KickType == 3 && !HighestSpecValue)
						{
							HighestSpecValue = value;
						}
						
						if (KickType == 3 && value <= HighestSpecValue)
						{
							HighestSpecValue = value;
							HighestSpecValueId = i;
						}
						else if (KickType != 3 && value >= HighestSpecValue)
						{
							HighestSpecValue = value;
							HighestSpecValueId = i;
						}
					}
				} 
				else if (KickType == 3 && value <= HighestValue)
				{
					HighestValue = value;
					HighestValueId = i;
				} 
				else if (KickType != 3 && value >= HighestValue)
				{
					HighestValue = value;
					HighestValueId = i;
				}
				
				if (useKeepBalance && clientTeam[i] == useTeam)
				{
					if (KickType == 3 && !HighestBalanceValue)
					{
						HighestBalanceValue = value;
					}
					
					if (KickType == 3 && value <= HighestBalanceValue)
					{
						HighestBalanceValue = value;
						HighestBalanceValueId = i;
					}
					else if (KickType != 3 && value >= HighestBalanceValue)
					{
						HighestBalanceValue = value;
						HighestBalanceValueId = i;
					}
				}	
			}
			
			if (Logging == 1)
			{
				IRS_LogClient(i, clientTeam[i], ClientImmunity[i], value);
			}
		}
	}

	new KickTarget;
	
	if (HighestSpecValueId)
	{
		KickTarget = HighestSpecValueId;
	}
	else if (HighestBalanceValueId)
	{
		KickTarget = HighestBalanceValueId;
	}
	else
	{
		KickTarget = HighestValueId;
	}
							
	if (KickTarget)
	{
		decl String:KickName[32];
		decl String:KickAuthid[32];
		GetClientName(KickTarget, KickName, sizeof(KickName));
		GetClientAuthString(KickTarget, KickAuthid, sizeof(KickAuthid));
		
		if (!immunityKick)
		{
			decl String:Reason[255];
			GetConVarString(cvar_KickReason, Reason, sizeof(Reason));
			if (StrEqual(Reason, "default", false))
			{
				Format(Reason, sizeof(Reason), "%t", "IRS Kick Reason");
			}
			KickClientEx(KickTarget, "%s", Reason);
			if (Logging == 1)
			{
				LogToFileEx(g_LogFilePath, "\"%s\" was kicked", KickName);
			}
			if (Logging == 2)
			{
				LogMessage("%t", "IRS Kick Log", ConnectingClientName, ConnectingClientAuthID, KickName, KickAuthid);
			}
		}
		else
		{
			new HighImmunityLimit = GetConVarInt(cvar_HighImmunityLimit);
			if (HighImmunityLimit && g_HIPCount >= HighImmunityLimit)
			{
				if (Logging == 1)
				{
					LogToFileEx(g_LogFilePath, "Too many high immunity players connected (%d players)", g_HIPCount);
				}
				return false;
			}
			decl String:Reason[255];
			GetConVarString(cvar_KickReasonImmunity, Reason, sizeof(Reason));
			if (StrEqual(Reason, "default", false))
			{
				Format(Reason, sizeof(Reason), "%t", "IRS Kick Reason Immunity");
			}
			KickClientEx(KickTarget, "%s", Reason);
			if (Logging == 1)
			{
				LogToFileEx(g_LogFilePath, "\"%s\" was kicked (Low immunity)", KickName);
			}
			if (Logging == 2)
			{
				LogMessage("%t", "IRS Kick Log", ConnectingClientName, ConnectingClientAuthID, KickName, KickAuthid);
			}
		}
		return true;
	} 
	else 
	{
		if (Logging == 1)
		{
			LogToFileEx(g_LogFilePath, "No valid client found to kick");
		}
	}
	
	return false;
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	// I do this here as it makes sure the client is actually connected, I don't want to add anyone too early.	
	new HighImmunityValue = GetConVarInt(cvar_HighImmunityValue);
	if (GetConVarInt(cvar_HighImmunityLimit) && HighImmunityValue && GetAdminImmunityLevel(GetUserAdmin(client)) >= HighImmunityValue)
	{
		g_HighImmunityPlayers[client] = true;
		g_HIPCount++;
	}
	
	new Float:KickSpecDelay = GetConVarFloat(cvar_SpecKickDelay);
	if (KickSpecDelay)
	{
		CheckKickSpecDelay(KickSpecDelay, client);
	}
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
		
	if (!GetConVarInt(cvar_HighImmunityLimit))
	{
		return;
	}
		
	if (g_HighImmunityPlayers[client])
	{
		g_HighImmunityPlayers[client] = false;
		g_HIPCount--;
	}
	
	if (t_KickSpecClient[client] != INVALID_HANDLE)
	{
		KillTimer(t_KickSpecClient[client]);
		t_KickSpecClient[client] = INVALID_HANDLE;
		b_canKickSpec[client] = false;
	}
}

public Action:listen_join_team(client, const String:command[], argc)
{
	new Float:KickSpecDelay = GetConVarFloat(cvar_SpecKickDelay);
	
	if (!KickSpecDelay || IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	
	if (StrEqual(command, "jointeam", false) || StrEqual(command, "spectate", false))
	{
		CheckKickSpecDelay(KickSpecDelay, client);
	}
	
	return Plugin_Continue;
}

CheckKickSpecDelay(const Float:delay, const client)
{
	new clientTeam = GetClientTeam(client);
	if ((clientTeam != TEAM1 || clientTeam != TEAM2) && t_KickSpecClient[client] == INVALID_HANDLE)
	{
		t_KickSpecClient[client] = CreateTimer(delay, t_KickSpecClientTimer, client);
	}
	else if ((clientTeam == TEAM1 || clientTeam == TEAM2) && t_KickSpecClient[client] != INVALID_HANDLE)
	{
		KillTimer(t_KickSpecClient[client]);
		t_KickSpecClient[client] = INVALID_HANDLE;
	}
}

public Action:t_KickSpecClientTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		b_canKickSpec[client] = true;
	}
	
	t_KickSpecClient[client] = INVALID_HANDLE;
	return Plugin_Handled;
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
	{
		b_lateLoad = true
	}
	
	// I think insurgency is the only game that has different team indexes. I'll probably never ever check either, I'm terrible.
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if (StrEqual(game, "insurgency"))
	{
		TEAM1 = 1;
		TEAM2 = 2;
		SPEC = 3;
	}
	else
	{
		SPEC = 1;
		TEAM1 = 2;
		TEAM2 = 3;
	}
	
	MarkNativeAsOptional("IsPlayerDonator");
	MarkNativeAsOptional("FindDonatorBySteamId");
	
	return APLRes_Success;
}