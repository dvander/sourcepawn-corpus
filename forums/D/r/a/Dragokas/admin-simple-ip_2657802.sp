#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION		"1.1"

public Plugin myinfo =
{
	name = "Admins simple two-factor authentification",
	author = "Alex Dragokas",
	description = "Adds ability to setup ip-address in admins_simple.cfg comments as additional protection method",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

/*
	=============================================================
	Purpose:
	
	This is additional protection against using stolen Steam apptickets / SteamId spoofing.
	Plugin allows you to adjust admin access defined by:
	
	1. SteamID + IP.
	2. User name + pass + IP.
	
	simply in admins_simple.cfg (or admins.cfg) without breaking its structure.
	
	IP could be static or dynamic (subnet) or set of IPs (subnets).
	
	=============================================================
	How to use:
	
	example of configs/admins_simple.ini lines:
	
	 - you can setup concrete ip:
	"STEAM_1:1:12345678" "99:z" "" // 180.255.3.5 // Dragon
	
	 - you can setup several ip-s, as well as whole subnet if admin uses dynamic ip:
	"STEAM_1:1:222712714" "99:z" "" // 87.250.34. 87.250.35. 190.34. // CrazyAdmin
	
	 - you can use "Name authentication" method together with confirming user's dynamic ip:
	"Dragokas" "99:z" "" // 180.255.3.
	
	 - (default behaviour - this plugin does not interfere):
	"STEAM_1:1:12345678" "99:z" // some comment (or without)
	
	 - Note: SteamId v3 is also supported here (not my merit).
	
	Admins who failed to pass ip check (depending on settings):
	 - will be kicked
	 - will be removed from admins
	 - will lose all of their admin flags, except the flag defined in settings.
	
	Note: if you want to use "name" authentification method you need to:
	 - setup admin password in addons/sourcemod/configs/core.cfg => PassInfoVar
	 - (optionally) install the same password in autoexec.cfg, like: setinfo "password" "Dragokas"
	Details: https://wiki.alliedmods.net/Adding_Admins_(SourceMod)#Passwords
	
	ENSURE: legal comments of your admins_simple.ini file does not begin with digit,
	otherwise they can be considered as IP.
	
	=============================================================
	Settings (ConVars):
	
	 - sm_admins_simple_ip_enabled 		- def: "1" - Enable plugin (1 - On / 0 - Off)
	 - sm_admins_simple_ip_lock_mode 	- def: "0" - Restriction method for admin who failed ip check (0 - kick / 1 - remove admin permissions / 2 - restrict admin to use only defined flag(s)
	 - sm_admins_simple_ip_lock_flags	- def: "k" - List of admin flags to assign to administrator (if lock mode = 2)
	 - sm_admins_simple_ip_lock_unkn	- def: "1" - Restrict unknown admins (if they cannot be found in config file, like one dynamically added by 3rd party plugins)
	 - sm_admins_simple_ip_log 			- def: "1" - Log when admin failed to pass validation (1 - On / 0 - Off).
	 
	Logs are stored in: sourcemod/logs/admin_ip.log
	
	Note about unknown admins:
	this plugins also ensures client didn't spoof Steam Id on authorization stage
	in the way his SteamId doesn't match Id present in config file anymore.
	This not conflict with admins added dynamically in the middle game by 3rd-party plugin.
	However, such admin will be checked when client is authorized next time and will be a subject for removing.
	So, just in case, you can disable such behaviour by "sm_admins_simple_ip_lock_unkn" ConVar.
	
	=============================================================
	Useful commands:
	
	sm_reloadadmins - refresh admin list, restore default admin permissions, validate in-game admins.
	sm_dump_admcache - dump admin cache list to addons/sourcemod/data/admin_cache_dump.txt (no IP info, though).
	
	=============================================================
	Requirements:
	
	 - "SourceMod Admin File Reader Plugin" (admin-flatfile.smx) by AlliedModders LLC (included in SourceMod)
	 - GeoIP extension (included in SourceMod).
	
	=============================================================
	Credits:
	
	 - AlliedModders LLC - Plugin is based on "admin-simple.sp" source code as a part of SourceMod.
	
	=============================================================
	ChangeLog:
	
	1.0 (21-May-2019)
	 - Initial release
	 
	1.1 (25-Aug-2019)
	 - Fixed mistake when admin is kicked if "sm_admins_simple_ip_lock_flags" is not include flag assigned to him.
	 - AuthId_Steam2 is now logged istead of AuthId_Steam3.
	
	=============================================================
	TODO: add admin.cfg
*/

#include <sourcemod>
#include <geoip>

#define AdminFlagMax 	Admin_Custom6
#define CVAR_FLAGS		FCVAR_NOTIFY

#define DEBUG 0

StringMap hMapSteam;

ConVar g_ConVarEnable;
ConVar g_ConVarMode;
ConVar g_ConVarFlags;
ConVar g_ConVarLockUnknown;
ConVar g_ConVarLog;

char g_sLog[PLATFORM_MAX_PATH];
char g_Filename[PLATFORM_MAX_PATH];

bool g_bAdminIdModified[MAXPLAYERS+1];
bool g_bLateload;

int g_iDefFlagBits;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_admins_simple_ip_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
	
	g_ConVarEnable = CreateConVar("sm_admins_simple_ip_enabled", 		"1", 	"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS);
	g_ConVarMode = CreateConVar("sm_admins_simple_ip_lock_mode", 		"0", 	"Restriction method for admin who failed ip check (0 - kick / 1 - remove admin permissions / 2 - restrict admin to use only defined flag(s)", CVAR_FLAGS);
	g_ConVarFlags = CreateConVar("sm_admins_simple_ip_lock_flags", 		"k", 	"List of admin flags to assign to administrator (if lock mode = 2)", CVAR_FLAGS);
	g_ConVarLockUnknown = CreateConVar("sm_admins_simple_ip_lock_unkn", "1", 	"Restrict unknown admins (if they cannot be found in config file, like one dynamically added by 3rd party plugins)", CVAR_FLAGS);
	g_ConVarLog = CreateConVar("sm_admins_simple_ip_log", 				"1", 	"Log when admin failed to pass validation (1 - On / 0 - Off)", CVAR_FLAGS);
	
	AutoExecConfig(true, "sm_admins_simple_ip");
	
	g_ConVarEnable.AddChangeHook(OnCvarChanged_Enable);
	g_ConVarFlags.AddChangeHook(OnCvarChanged_Flags);
	g_ConVarMode.AddChangeHook(OnCvarChanged_Mode);
	
	if (!hMapSteam)
		hMapSteam = new StringMap();
	
	BuildPath(Path_SM, g_Filename, sizeof(g_Filename), "configs/admins_simple.ini");
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/admin_ip.log");
	
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	#if DEBUG
		RegConsoleCmd("sm_getpriv", CmdGetPriv, "Get current player admin flags");
	#endif
	
	GetDefaultFlagBits();
	
	if (g_bLateload)
		ReadSimpleUsersIP();
}

#if DEBUG
Action CmdGetPriv(int client, int args)
{
	AdminId admin;
	admin = GetUserAdmin(client);
	if (admin != INVALID_ADMIN_ID) {
		PrintToChat(client, "Admin flags for %N. Real: %i, Effective: %i", client, admin.GetFlags(Access_Real), admin.GetFlags(Access_Effective));
		PrintToChat(client, "Access to \"z\" flag: %b", CheckCommandAccess(client, NULL_STRING, ADMFLAG_ROOT, false)); 
	}
	else {
		PrintToChat(client, "Player %N is not admin. Flags: %i", client, GetUserFlagBits(client));
	}
	return Plugin_Handled;
}
#endif

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bAdminIdModified[client]) {
		g_bAdminIdModified[client] = false;
		ServerCommand("sm_reloadadmins"); // restore AdminId state
	}
}

void OnCvarChanged_Enable(ConVar convar, const char[] oldValue, const char[] newValue)
{
	#if DEBUG
		LogToFile(g_sLog, "Flag cvar changed from %s to %s", oldValue, newValue);
	#endif
	
	if (StrEqual(newValue, "1")) {
		ReadSimpleUsersIP();
		ValidateClientAll();
	}
}

void OnCvarChanged_Flags(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetDefaultFlagBits();
}

void OnCvarChanged_Mode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ValidateClientAll();
}

void GetDefaultFlagBits()
{
	AdminFlag flag;
	char sFlags[32];
	
	g_ConVarFlags.GetString(sFlags, sizeof(sFlags));
	g_iDefFlagBits = 0;
	
	for (int i=0; i<strlen(sFlags); i++)
		if (FindFlagByChar(sFlags[i], flag))
			g_iDefFlagBits |= FlagToBit(flag);
	
	ServerCommand("sm_reloadadmins"); // to make in-game restricted admins be able to receive new flags
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if (g_ConVarEnable.BoolValue)
	{
		if (part == AdminCache_Admins)
		{
			ReadSimpleUsersIP();
			
			// we need to give "admin-simple.sp" time to create admins
			CreateTimer(0.1, Timer_ValidateAdmins);
			
			#if DEBUG
				LogToFile(g_sLog, "OnRebuildAdminCache");
			#endif
		}
	}
}

public Action Timer_ValidateAdmins(Handle timer)
{
	#if DEBUG
		LogToFile(g_sLog, "Timer Callback");
	#endif

	ValidateClientAll();
}

void ValidateClientAll()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !IsFakeClient(i))
			OnClientPostAdminFilterEx(i, true);
}

public void ReadSimpleUsersIP()
{
	#if DEBUG
		LogToFile(g_sLog, "ReadSimpleUsersIP");
	#endif
	
	hMapSteam.Clear();
	
	File file = OpenFile(g_Filename, "rt");
	if (!file)
	{
		SetFailState("Could not open file: %s", g_Filename);
		return;
	}
	
	static char line[255], sComment[192], sIP[192];
	static int len, i, j;
	static bool ignoring;
	
	while (!file.EndOfFile())
	{
		if (!file.ReadLine(line, sizeof(line)))
			break;
		
		sComment[0] = '\0';
		sIP[0] = '\0';
		
		/* Extract and delete comments */
		len = strlen(line);
		ignoring = false;
		for (i=0; i<len; i++)
		{
			if (ignoring)
			{
				if (line[i] == '"')
					ignoring = false;
			} else {
				if (line[i] == '"')
				{
					ignoring = true;
				} else if (line[i] == ';') {
					line[i] = '\0';
					break;
				} else if (line[i] == '/'
							&& i != len - 1
							&& line[i+1] == '/')
				{
					strcopy(sComment, sizeof(sComment), line[i+2]);
					TrimString(sComment);
					
					if (48 <= sComment[0] <= 57) {
						
						// TODO: add more reliable check of ip
						for (j = 0; j < strlen(sComment); j++)
							if (!(48 <= sComment[j] <= 57 || sComment[j] == 46 || sComment[j] == 32)) // digit, dot or space
								break;
						
						strcopy(sIP, j+1, sComment); // cb to copy + NULL
					}
					
					/*
					if (48 <= sComment[0] <= 57) {
						BreakString(sComment, sIP, sizeof(sIP));
					}
					*/
					line[i] = '\0';
					break;
				}
			}
		}
		
		TrimString(line);
		
		if ((line[0] == '/' && line[1] == '/')
			|| (line[0] == ';' || line[0] == '\0'))
		{
			continue;
		}
		
		ReadAdminLineIP(line, sIP);
		#if DEBUG
			PrintToServer(line);
		#endif
	}
	
	file.Close();
}

void DecodeAuthMethod(const char[] auth, char method[32])
{
	if ((StrContains(auth, "STEAM_") == 0) || (strncmp("0:", auth, 2) == 0) || (strncmp("1:", auth, 2) == 0))
	{
		// Steam2 Id
		strcopy(method, sizeof(method), AUTHMETHOD_STEAM);
	}
	else if (!strncmp(auth, "[U:", 3) && auth[strlen(auth) - 1] == ']')
	{
		// Steam3 Id
		strcopy(method, sizeof(method), AUTHMETHOD_STEAM);
	}
	else
	{
		if (auth[0] == '!')
		{
			strcopy(method, sizeof(method), AUTHMETHOD_IP);
		}
		else
		{
			strcopy(method, sizeof(method), AUTHMETHOD_NAME);
		}
	}
}

void ReadAdminLineIP(const char[] line, const char[] sIP)
{
	static char auth[64], auth_method[32];
	
	if ((BreakString(line, auth, sizeof(auth))) == -1)
	{
		/* This line is bad... we need at least two parameters */
		return;
	}
	
	if (sIP[0] == '\0') {
		hMapSteam.SetString(auth, sIP);
		return;
	}
	
	DecodeAuthMethod(auth, auth_method);
	
	if (StrEqual(auth_method, AUTHMETHOD_STEAM) || 
		StrEqual(auth_method, AUTHMETHOD_NAME)) {
		
		hMapSteam.SetString(auth, sIP);
		
		#if DEBUG
			LogToFile(g_sLog, "IP binding: %s = %s", auth, sIP);
		#endif
	}
	else { // AUTHMETHOD_IP
		hMapSteam.SetString(auth[1], sIP);
	}
}

bool ComparePartialIP(const char[] sIP, const char[] sPartial)
{
	static char tIP[32], tPartial[32];
	static int iLen;
	strcopy(tIP, sizeof(tIP), sIP);
	strcopy(tPartial, sizeof(tPartial), sPartial);
	
	#if DEBUG
		LogToFile(g_sLog, "sIP: %s. Partial: %s", sIP, sPartial);
	#endif
	
	// add "." to both strings and compare them
	StrCat(tIP, sizeof(tIP), ".");
	
	iLen = strlen(tPartial);
	
	if (tPartial[iLen-1] != 46)
		StrCat(tPartial, sizeof(tPartial), ".");
	
	return (StrContains(tIP, tPartial) == 0);
}

public void OnClientPostAdminFilter(int client)
{
	OnClientPostAdminFilterEx(client, false);
}

void OnClientPostAdminFilterEx(int client, bool bLateCheck)
{
	if (!g_ConVarEnable.BoolValue)
		return;
	
	static char sSteam[64], sIP[32], sName[MAX_NAME_LENGTH], sIPSet[192], sCountry[4];
	static bool bShoudCheck;
	static AdminId admin;
	static int iFlagBits, flags;
	
	if (IsFakeClient(client))
		return;
	
	admin = GetUserAdmin(client);
	
	#if DEBUG
		LogToFile(g_sLog, "OnClientPostAdminFilter: %N, flags: %i, adminId: %i", client, GetUserFlagBits(client), admin);
	#endif
	
	if (admin == INVALID_ADMIN_ID || (iFlagBits = GetUserFlagBits(client)) == 0)
		return;
	
	if (iFlagBits & ~g_iDefFlagBits == 0) // admin is already have <= default flag bits
		return;
	
	bShoudCheck = false;
	
	if (!bShoudCheck) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		if (hMapSteam.GetString(sSteam, sIPSet, sizeof(sIPSet)))
			bShoudCheck = true;
	}
	
	if (!bShoudCheck) {
		GetClientAuthId(client, AuthId_Steam3, sSteam, sizeof(sSteam));
		if (hMapSteam.GetString(sSteam, sIPSet, sizeof(sIPSet)))
			bShoudCheck = true;
	}
	
	if (!bShoudCheck) {
		GetClientName(client, sName, sizeof(sName));
		if (hMapSteam.GetString(sName, sIPSet, sizeof(sIPSet)))
			bShoudCheck = true;
	}
	
	GetClientIP(client, sIP, sizeof(sIP));
	GeoipCode3(sIP, sCountry);
	
	if (!bShoudCheck) {
		if (hMapSteam.GetString(sIP, sIPSet, sizeof(sIPSet)))
			bShoudCheck = true;
	}
	
	#if DEBUG
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		LogToFile(g_sLog, "Steam is: %s of %N (%s). bShoudCheck? %b. IPSet: %s", sSteam, client, sIP, bShoudCheck, sIPSet);
	#endif
	
	if (bShoudCheck) {
		
		if (sIPSet[0] == '\0') // ip check is not required
			return;
		
		if (!CheckIP(sIP, sIPSet)) {
			
			flags = RestrictAdmin(client, admin);

			if (g_ConVarLog.BoolValue) {
				LogToFile(g_sLog, "Admin %N is restricted due to failing IP validation ( %s | [%s] %s ). Flags: %i => %i", client, sSteam, sCountry, sIP, iFlagBits, flags);
			}
		}
		else {
			#if DEBUG
				LogToFile(g_sLog, "IP validation of %N is passed.", client);
			#endif
		}
	}
	else {
		/* It's admin without auth info in admins-simple (or admins) file.
			Perhaps, it is possible in such ways:
			 - dynamically added admin with 3rd-party plugin
			 - SteamId is hijacked on post-authentification stage
		*/
		
		if (!bLateCheck) { // skip dynamically added admins
			if (g_ConVarLockUnknown.BoolValue) {
			
				flags = RestrictAdmin(client, admin);
				
				if (g_ConVarLog.BoolValue) {
					GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
					LogToFile(g_sLog, "Admin %N is restricted because we can't find his info in config file ( %s | [%s] %s ). Flags: %i => %i", client, sSteam, sCountry, sIP, iFlagBits, flags);
				}
			}
		}
	}
}

void CloseMenu(int client)
{
	if (GetClientMenu(client, INVALID_HANDLE) != MenuSource_None)
	{
		InternalShowMenu(client, "\10", 1); // thanks to Zira
		CancelClientMenu(client, true, INVALID_HANDLE);
	}
}

int RestrictAdmin(int client, AdminId admin)
{
	static int i, len, mode, flags_new;
	static char sFlags[32];
	
	mode = g_ConVarMode.IntValue;
	
	if (mode == 0) {

		#if DEBUG
			char sUserName[MAX_NAME_LENGTH];
			GetClientName(client, sUserName, sizeof(sUserName));
		
			LogToFile(g_sLog, "Admin %s is kicked.", sUserName);
		#endif
		
		KickClient(client, "Kicked: contact to administrator");
		return 0;
	}
	
	// to restore assigned AdminId on user disconnect
	g_bAdminIdModified[client] = true;
	
	g_ConVarFlags.GetString(sFlags, sizeof(sFlags));
	
	len = strlen(sFlags);
	
	if(len == 0 || mode == 1) {
		//RemoveAdmin(admin);
		SetUserAdmin(client, INVALID_ADMIN_ID, false);
		#if DEBUG
			LogToFile(g_sLog, "Admin %N is removed. Mode = %i", client, mode);
		#endif
		CloseMenu(client);
		return 0;
	}

	//int flags_bak = admin.GetFlags(Access_Real) | admin.GetFlags(Access_Effective);
	
	// revoke all flags
	for (i = 1; i <= view_as<int>(AdminFlagMax); i++)
		admin.SetFlag(view_as<AdminFlag>(i), false);
	
	// add required flags
	for (i=0; i<len; i++)
	{
		AdminFlag flag;
		
		if (!FindFlagByChar(sFlags[i], flag))
		{
			LogError("Invalid flag detected: %c", sFlags[i]);
			continue;
		}
		admin.SetFlag(flag, true);
		
		//SetUserAdmin(client, INVALID_ADMIN_ID, false);
		
		SetUserAdmin(client, admin, false);
		
		//DumpAdminCache(AdminCache_Admins, true);
		//RunAdminCacheChecks(client);
		
		#if DEBUG
			LogToFile(g_sLog, "Admin %N is restricted to use flag: %s", client, sFlags);
		#endif
	}
	
	flags_new = admin.GetFlags(Access_Real) | admin.GetFlags(Access_Effective);
	
	/*
	// revoke all flags
	for (i = 1; i <= view_as<int>(AdminFlagMax); i++)
		admin.SetFlag(view_as<AdminFlag>(i), false);
	
	AdminFlag admflags[30];
	
	// return previous AdminId state
	len = FlagBitsToArray(flags_bak, admflags, sizeof(admflags));
	
	for (i = 0; i < len; i++)
		admin.SetFlag(admflags[i], true);
	
	LogToFile(g_sLog, "Bak flags: %i", admin.GetFlags(Access_Effective));
	*/
	
	CloseMenu(client);
	
	return flags_new;
}

bool CheckIP(const char[] sIP, const char[] sIPSet)
{
	#if DEBUG
		LogToFile(g_sLog, "Checking IP: %s. IpSet: %s", sIP, sIPSet);
	#endif

	/* Extract IP addresses */
	static int idx, cur_idx;
	static char sPartialIP[16];
	
	idx = 0, cur_idx = 0;
	while (cur_idx != -1)
	{
		cur_idx = BreakString(sIPSet[idx], sPartialIP, sizeof(sPartialIP));
		idx += cur_idx;
		TrimString(sPartialIP);
		if (ComparePartialIP(sIP, sPartialIP)) {
			return true;
		}
	}
	return false;
}
