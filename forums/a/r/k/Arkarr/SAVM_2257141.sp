#include <sourcemod>
#include <morecolors>

#define TRIAL_UPDATE	2
#define TRIAL_WAIT	   -1
#define TRIAL_NEW		1
#define DATABASE_INSERT 1
#define DATABASE_DELETE 2
#define DATABASE_UPDATE 3

#define QUERY_CREATE_T_ADMINVIP		"CREATE TABLE IF NOT EXISTS adminsvip (id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY, steamID VARCHAR(40) NOT NULL, lastRecordedName VARCHAR(60) NOT NULL, flags VARCHAR(50) NOT NULL,DateExpiration  VARCHAR(40) NOT NULL)"
#define QUERY_CREATE_T_TRIALUSER	"CREATE TABLE IF NOT EXISTS trialuser (id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY, steamID VARCHAR(40) NOT NULL, DateExpiration VARCHAR(40) NOT NULL, registeredDay VARCHAR(40) NOT NULL)"
#define QUERY_RESET_T_TRIALUSER		"DROP TABLE trialuser"
#define QUERY_SELECT_DATEX_CLIENT	"SELECT DateExpiration FROM adminsvip WHERE steamID LIKE 'STEAM%s'"
#define QUERY_SELECT_ADMINVIP		"SELECT flags, DateExpiration FROM adminsvip WHERE steamID LIKE 'STEAM%s'"
#define QUERY_UPDATE_TRIAL_USER		"UPDATE trialuser SET steamID='STEAM_0:1:%s', DateExpiration='%s', registeredDay='%s' WHERE steamID LIKE 'STEAM%s';"
#define QUERY_INSERT_TRIAL_USER		"INSERT INTO trialuser (steamID, DateExpiration, registeredDay) VALUES ('STEAM_0:1:%s','%s','%s')"
#define QUERY_TRIALUSER_REGISTERDAY	"SELECT registeredDay FROM trialuser WHERE steamID LIKE 'STEAM%s'"
#define QUERY_NEW_ADMINVIP			"INSERT INTO adminsvip (steamID,lastRecordedName,DateExpiration,flags) VALUES ('STEAM_0:1:%s','%s','%s','%s')"
#define	QUERY_DELETE_ADMINVIP		"DELETE FROM adminsvip WHERE steamID LIKE 'STEAM%s'"
#define	QUERY_UPDATEADMINVIP		"UPDATE adminsvip SET lastRecordedName='%s',flags='%s',DateExpiration='%s' WHERE steamID LIKE 'STEAM%s';"
#define QUERY_SELECT_TRIAL_END		"SELECT DateExpiration FROM trialuser WHERE steamID LIKE 'STEAM%s'"

AdminId PreviousAccess[MAXPLAYERS + 1];
Handle DatabaseConnection;
Handle CVAR_Flags;
Handle CVAR_EnbaleTrial;
Handle CVAR_TrialTimer;
Handle CVAR_TrialDays;
Handle CVAR_TrialImmunity;
bool pluginEnabled;
char plugintag[30] = "{purple}[SAVM]{default}";

public Plugin myinfo =
{
	name = "[ANY] Simple Admin and VIP manager",
	description = "Allow you to manage your admins and VIP very simply",
	author = "Arkarr",
	version = "3.0",
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_savmadd", CMD_AddUser, ADMFLAG_ROOT, "Display the SAVM menu !");
	RegAdminCmd("sm_savmedit", CMD_EditUser, ADMFLAG_ROOT, "Display the SAVM menu !");
	RegAdminCmd("sm_savmdremove", CMD_RemoveUser, ADMFLAG_ROOT, "Display the SAVM menu !");
	RegAdminCmd("sm_savmexpiration", CMD_Expiration, ADMFLAG_ROOT, "Display the SAVM menu !");
	RegConsoleCmd("sm_trial", CMD_Trial, "Add temporaly a user as a admin/vip !");
	RegServerCmd("sm_resettrial", CMD_ResetTrials, "Reset trials database table. WARNING, this will allow ALL users to re-use !trial !!!");
	AddCommandListener(CMD_ReloadAdmins, "sm_reloadadmins");
	
	CVAR_EnbaleTrial = CreateConVar("sm_savm_enable_trial", "1", "Should trial command be actived ?");
	CVAR_Flags = CreateConVar("sm_savm_tmp_flags", "opqrst", "Flags wich should be given when some try !trial command");
	CVAR_TrialTimer = CreateConVar("sm_savm_trial_time", "1800", "Time (in seconds) that a user get is right removed after using !trial (SECONDS / 60 = minutes)");
	CVAR_TrialDays = CreateConVar("sm_savm_trial_day", "1", "Set after how much time a user will be able to do !trial again");
	CVAR_TrialImmunity = CreateConVar("sm_savm_trial_immunity_level", "10", "Immunity level for temporaire admins / VIP");
	
	AutoExecConfig(true, "SAVMconfig");
	
	SQL_TConnect(GotDatabase, "SAVM_Database");
}

public void OnClientPostAdminFilter(int client)
{
	PreviousAccess[client] = INVALID_ADMIN_ID;
	if(pluginEnabled)
		TryLogin(client);
}
	
public Action CMD_Expiration(int client, int args)
{
	if(!pluginEnabled || client == 0)
		return Plugin_Handled;
		
	bool dataFound;
	char query[100];
	char steamID[100];
	char DateExpiration[12];
	
	GetSteamID(client, steamID, sizeof(steamID));
	Format(query, 100, QUERY_SELECT_DATEX_CLIENT, steamID);
	ReplaceString(query, sizeof(query), "STEAM", "%%");

	Handle hQuery = SQL_Query(DatabaseConnection, query);

	if (hQuery != INVALID_HANDLE)
	{
		PrintToServer("[SAVM] Database request : Check time left %s (%N) -> Processing...", steamID, client);
		while (SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, DateExpiration, sizeof(DateExpiration));
			CPrintToChat(client, "%s Your access will end the %s", plugintag, DateExpiration);
			dataFound = true;
		}
		CloseHandle(hQuery);
	}
	if(!dataFound)
		CPrintToChat(client, "%s You are not registred as an admin.", plugintag);
		
	return Plugin_Handled;
}

public Action CMD_Trial(int client, int args)
{
	if(!pluginEnabled || client == 0)
		return Plugin_Handled;
		
	if(GetConVarInt(CVAR_EnbaleTrial) == 0)
	{
		CPrintToChat(client, "%s Sorry, option disabled by admin.", plugintag);
		return Plugin_Handled;
	}
	
	char flags[24];
	char immunityLevel[10];
	char expirationDate[12];
	GetConVarString(CVAR_Flags, flags, sizeof(flags));
	GetConVarString(CVAR_TrialImmunity, immunityLevel, sizeof(immunityLevel));
	
	if(strlen(flags) == 0)
	{
		CPrintToChat(client, "%s Operation failed ! No flag(s) found !", plugintag);
		return Plugin_Handled;
	}
	
	float timerval = 0.0;
	timerval = GetConVarFloat(CVAR_TrialTimer);
	
	char auth[120];
	GetSteamID(client, auth, sizeof(auth));
	int registred = CanUseTrial(DatabaseConnection, auth, client, expirationDate);

	if(registred != TRIAL_WAIT)
	{
		char sql[200], today[24], tomorrow[24], today_ex[3][5];
		
		FormatTime(today, sizeof(today), "%d.%m.%Y");
		ExplodeString(today, ".", today_ex, sizeof today_ex, sizeof today_ex[]);
		int days = StringToInt(today_ex[0])+GetConVarInt(CVAR_TrialDays);
		int month = StringToInt(today_ex[1]);
		int year = StringToInt(today_ex[2]);
		if((days > 31 && (month % 2 == 1)) || (days > 30 &&  (month % 2 == 0)))
		{
			days = 1;
			month++;
			if(month > 12)
			{
				month = 1;
				year++;
			}
		}
		Format(tomorrow, sizeof(tomorrow), "%02i.%02i.%i", days, month, year);
		if(registred == TRIAL_UPDATE)
			Format(sql, sizeof(sql), QUERY_UPDATE_TRIAL_USER, auth, tomorrow, today, auth);
		else if(registred == TRIAL_NEW)
			Format(sql, sizeof(sql), QUERY_INSERT_TRIAL_USER, auth, tomorrow, today);
		
		if (!SQL_FastQuery(DatabaseConnection, sql))
		{
			CPrintToChat(client, "%s You can't use trial now ! A error as been found, try later !", plugintag);
			char error[255];
			SQL_GetError(DatabaseConnection, error, sizeof(error));
			PrintToServer("[SAVM] ERROR: %s", error);
		}
		else
		{
			if (AddUserAsTmpAdmin(client, flags, StringToInt(immunityLevel), "-1", false))
			{
				Handle pack;
				CPrintToChat(client, "%s Success ! Your right will end in %.2f secondes !", plugintag, timerval);
				CPrintToChat(client, "%s You will be able to use !trial again the {green}%s", plugintag, tomorrow);
				
				CreateDataTimer(timerval, RemoveTMPAdmins, pack, TIMER_FLAG_NO_MAPCHANGE);
				WritePackCell(pack, client);
			}
		}		
	}
	else
	{
		CPrintToChat(client, "%s You can't use trial now ! Wait the {green}%s{default} to use !trial again !", plugintag, expirationDate);
	}
	
	return Plugin_Handled;
}

public Action CMD_ReloadAdmins(int client, const char[] command, int args)
{
	if(!CheckCommandAccess(client, command, ADMFLAG_BAN))
		return Plugin_Continue;
		
	if(IsValidClient(client))
		CPrintToChat(client, "%s Updating admins list, please wait.", plugintag);
	else
		PrintToServer("[SAVM] Updating admins list, please wait.");
		
	for(int i = 0; i <= MaxClients; i++)
		if(IsValidClient(i))
			TryLogin(i);
			
	if(IsValidClient(client)) 
		CPrintToChat(client, "%s Done ! Admins are now updated !", plugintag);
	else
		PrintToServer("[SAVM] Done ! Admins are now updated !");
	
	return Plugin_Continue;
}

public Action RemoveTMPAdmins(Handle timer, Handle pack)
{
	ResetPack(pack);
	int player = ReadPackCell(pack);
	if(IsValidClient(player))
	{
		CPrintToChat(player, "%s Your trial period end now !", plugintag);
		RemoveAdmin(GetUserAdmin(player));
		SetUserAdmin(player, PreviousAccess[player], true);
	}
}

public Action CMD_AddUser(int client, int args)
{
	if(!pluginEnabled || client == 0)
		return Plugin_Handled;
		
	if(args < 3)
	{
		CPrintToChat(client, "%s Usage : /savmadd [TARGET] [FLAGS] {fullred}OR{default} [GROUP NAME] [IMMUNITY] [DATE (if not specified, unlimited)], exemple :", plugintag);
		CPrintToChat(client, "%s /savmadd {green}Arkarr btfqa 20 25.03.2099", plugintag);
		CPrintToChat(client, "%s /savmadd {green}Arkarr AdminGroup  -1 25.03.2099", plugintag);
		return Plugin_Handled;
	}
	
	char target[50], accesFlags[22], imunity[12], date[12];
	
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, accesFlags, sizeof(accesFlags));
	GetCmdArg(3, imunity, sizeof(imunity));
	if(args == 4)
		GetCmdArg(4, date, sizeof(date));
	else
		Format(date, sizeof(date), "01.01.99999");
		
	int player = FindTarget(client, target, true);
	
	char fullFlags[40];
	Format(fullFlags, sizeof(fullFlags), "%s:%s", accesFlags, imunity);
	
	CPrintToChat(client, "%s Flags recored sucessfully -> '%s'", plugintag, fullFlags);
	CPrintToChat(client, "%s End date recored sucessfully -> '%s'", plugintag, date);
	CPrintToChat(client, "%s Querying database to save the results...", plugintag);
	
	if(SaveInDataBase(client, player, fullFlags, date, DATABASE_INSERT))
	{
		CPrintToChat(client, "%s {green}Success{default} !", plugintag);
		SetUserAdmin(player, INVALID_ADMIN_ID, true);
		TryLogin(player);
	}
	else
	{
		CPrintToChat(client, "%s {fullred}Failed{default} !", plugintag);
	}
	
	return Plugin_Handled;
}

public Action CMD_RemoveUser(int client, int args)
{
	if(!pluginEnabled || client == 0)
		return Plugin_Handled;
		
	if(args != 1)
	{
		CPrintToChat(client, "%s Usage : /savmdremove [TARGET], exemple :", plugintag);
		CPrintToChat(client, "%s /savmdremove {green}Arkarr", plugintag);
		return Plugin_Handled;
	}
	
	char target[50];
	
	GetCmdArg(1, target, sizeof(target));
	int player = FindTarget(client, target, true);
	
	CPrintToChat(client, "%s Querying database to save the results...", plugintag);
	
	if(SaveInDataBase(client, player, "none", "none", DATABASE_DELETE))
	{
		CPrintToChat(client, "%s {green}Success{default} !", plugintag);
		SetUserAdmin(player, INVALID_ADMIN_ID, true);
	}
	else
	{
		CPrintToChat(client, "%s {fullred}Failed{default} !", plugintag);
	}
	
	return Plugin_Handled;
}

public Action CMD_EditUser(int client, int args)
{
	if(!pluginEnabled || client == 0)
		return Plugin_Handled;
		
	if(args < 3)
	{
		CPrintToChat(client, "%s Usage : /savmedit [TARGET] [FLAGS] {fullred}OR{default} [GROUP NAME] [IMMUNITY] [DATE (if not specified, unlimited)], exemple :", plugintag);
		CPrintToChat(client, "%s /savmedit {green}Arkarr btfqa 20 25.03.2099", plugintag);
		CPrintToChat(client, "%s /savmedit {green}Arkarr AdminGroup -1 25.03.2099", plugintag);
		return Plugin_Handled;
	}
	
	char target[50], accesFlags[22], imunity[12], date[12];
	
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, accesFlags, sizeof(accesFlags));
	GetCmdArg(3, imunity, sizeof(imunity));
	
	if(args == 4)
		GetCmdArg(4, date, sizeof(date));
	else
		Format(date, sizeof(date), "01.01.99999");

	int player = FindTarget(client, target, true);
	
	CPrintToChat(client, "%s Flags recored sucessfully -> '%s:%s'", plugintag, accesFlags, imunity);
	CPrintToChat(client, "%s End date recored sucessfully -> '%s'", plugintag, date);
	CPrintToChat(client, "%s Querying database to save the results...", plugintag);
	
	char fullFlags[40];
	Format(fullFlags, sizeof(fullFlags), "%s:%s", accesFlags, imunity);
	
	if(SaveInDataBase(client, player, fullFlags, date, DATABASE_UPDATE))
	{
		CPrintToChat(client, "%s {green}Success{default} !", plugintag);
		SetUserAdmin(player, INVALID_ADMIN_ID, true);
		TryLogin(player);
	}
	else
	{
		CPrintToChat(client, "%s {fullred}Failed{default} !", plugintag);
	}
	
	return Plugin_Handled;
}

public Action CMD_ResetTrials(int args)
{
	PrintToServer("[SAVM] Removing trials table...");
	
	char sql[200];
	Format(sql, sizeof(sql), QUERY_RESET_T_TRIALUSER);
	
	if (!SQL_FastQuery(DatabaseConnection, sql))
	{
		char error[255];
		SQL_GetError(DatabaseConnection, error, sizeof(error));
		PrintToServer("ERROR: %s", error);
		return Plugin_Handled;
	}
	
	PrintToServer("[SAVM] Trial user table removed. Rebuilding...");
	
	char query[300];
	Format(query, sizeof(query), QUERY_CREATE_T_TRIALUSER);
	if (!SQL_FastQuery(DatabaseConnection, query))
	{
		char error[255];
		SQL_GetError(DatabaseConnection, error, sizeof(error));
		PrintToServer("[SAVM] ERROR: %s", error);
		return Plugin_Handled;
	}
	
	PrintToServer("[SAVM] Trial user table rebuilded. Everything should be OKAY :D !");
	
	return Plugin_Handled;
}

public bool SaveInDataBase(int client, int player, const char[] flags, const char[] ExpirationDate, int actionType)
{
	char sql[200], steamID[100], name[50];
	GetSteamID(client, steamID, sizeof(steamID));
	GetClientName(player, name, sizeof(name));
	ReplaceString(name, sizeof(name), ".", "");
	ReplaceString(name, sizeof(name), "-", "");
	ReplaceString(name, sizeof(name), "_", "");
	ReplaceString(name, sizeof(name), "'", "");
	if(actionType == DATABASE_INSERT)
		Format(sql, sizeof(sql), QUERY_NEW_ADMINVIP, steamID, name, ExpirationDate, flags);
	else if(actionType == DATABASE_DELETE)
		Format(sql, sizeof(sql), QUERY_DELETE_ADMINVIP, steamID);
	else if(actionType == DATABASE_UPDATE)
		Format(sql, sizeof(sql), QUERY_UPDATEADMINVIP, name, flags, ExpirationDate, steamID);
	ReplaceString(sql, sizeof(sql), "STEAM", "%%");
	
	if (!SQL_FastQuery(DatabaseConnection, sql))
	{
		char error[255];
		SQL_GetError(DatabaseConnection, error, sizeof(error));
		PrintToChat(client, "ERROR: %s", error);
		return false;
	}
	return true;
}

public void TryLogin(int client)
{
	char auth[48];
	GetSteamID(client, auth, sizeof(auth));
	if(!GetUserDatabaseData(DatabaseConnection, auth, client))
		PrintToServer("[SAVM] A error happened when trying to query database !");
}

public void GotDatabase(Handle owner, Handle hndl, char[] error, any data)
{
	if(hndl == INVALID_HANDLE)
		SetFailState("[SAVM] Error with database : %s", error);
	
	PrintToServer("[SAVM] Successfully connected to the database !");
	DatabaseConnection = hndl;
	pluginEnabled = CreateDBTables(DatabaseConnection);
}

public bool GetUserDatabaseData(Handle db, char[] steamID, int client)
{
	char query[100];
	char flagsAndImmunity[68];
	char DateExpiration[12];
	char flagsImmunity[2][24];
	Format(query, sizeof(query), QUERY_SELECT_ADMINVIP, steamID);
	ReplaceString(query, sizeof(query), "STEAM", "%%");

	Handle hQuery = SQL_Query(db, query);
	if (hQuery != INVALID_HANDLE)
	{
		PrintToServer("[SAVM] Database request : User %s (%N) -> Processing...", steamID, client);
		while (SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, flagsAndImmunity, sizeof(flagsAndImmunity));
			SQL_FetchString(hQuery, 1, DateExpiration, sizeof(DateExpiration));
			PrintToServer("[SAVM] User %s (%N) has been found with flag '%s' until %s",steamID, client, flagsAndImmunity, DateExpiration);
			
			ExplodeString(flagsAndImmunity, ":", flagsImmunity, sizeof flagsImmunity, sizeof flagsImmunity[]);
			
			if (AddUserAsTmpAdmin(client, flagsImmunity[0], StringToInt(flagsImmunity[1]), DateExpiration, true))
				PrintToServer("[SAVM] %s (%N) successfully added as admin/VIP !", steamID, client);
			else
				PrintToServer("[SAVM] %s (%N) Can't be added as admin/VIP, time is over !", steamID, client);
				
			return true;
		}
		CloseHandle(hQuery);
	}
	else
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("[SAVM] Failed to query (error: %s)", error);
	}
	
	char registeredDay[100];
	char registeredDay_ex[3][5];
	char flags[100];
	GetConVarString(CVAR_Flags, flags, sizeof(flags));
	
	Format(query, 100, QUERY_TRIALUSER_REGISTERDAY, steamID);
	ReplaceString(query, sizeof(query), "STEAM", "%%");

	hQuery = SQL_Query(db, query);
	if (hQuery != INVALID_HANDLE)
	{
		PrintToServer("[SAVM] Database request : User (trial) %s (%N) -> Processing...", steamID, client);
		while (SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, registeredDay, sizeof(registeredDay));
			
			ExplodeString(registeredDay, ".", registeredDay_ex, sizeof registeredDay_ex, sizeof registeredDay_ex[]);
			int days = StringToInt(registeredDay_ex[0])+GetConVarInt(CVAR_TrialDays);
			int month = StringToInt(registeredDay_ex[1]);
			int year = StringToInt(registeredDay_ex[2]);
			if((days > 31 && (month % 2 == 1)) || (days > 30 &&  (month % 2 == 0)))
			{
				days = 1;
				month++;
				if(month > 12)
				{
					month = 1;
					year++;
				}
			}
			Format(registeredDay, sizeof(registeredDay), "%i.%i.%i", days, month, year);
			
			PrintToServer("[SAVM] Trial user %s (%N) has been found until %s", steamID, client, registeredDay);
			char today[12];
			FormatTime(today, sizeof(today), "%d.%m.%Y");
			
			if(isDateGreater(registeredDay, today))
				if (AddUserAsTmpAdmin(client, flags, GetConVarInt(CVAR_TrialImmunity), "-1", false))				
					return true;
		}
		CloseHandle(hQuery);
	}
	else
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("[SAVM] Failed to query (error: %s)", error);
	}
	
	return false;
}

public int CanUseTrial(Handle db, char[] steamID, int client, char[] expirationdate)
{
	char query[100];
	char DateExpiration[12];
	Format(query, 100, QUERY_SELECT_TRIAL_END, steamID);
	ReplaceString(query, sizeof(query), "STEAM", "%%");

	Handle hQuery = SQL_Query(db, query);
	if (hQuery != INVALID_HANDLE)
	{
		PrintToServer("[SAVM] Database request : User %s (%N) want VIP accces -> Processing...", steamID, client);
		while (SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, DateExpiration, sizeof(DateExpiration));
			PrintToServer("[SAVM] User %s (%N) has been found trial not allowed until %s", steamID, client, DateExpiration);
			char today[12];
			FormatTime(today, sizeof(today), "%d.%m.%Y");
			PrintToServer("[SAVM] Start date check...", steamID, client);
			if(isDateGreater(today, DateExpiration))
			{
				CloseHandle(hQuery);
				Format(expirationdate, 12, DateExpiration);
				
				return TRIAL_UPDATE;
			}
			CloseHandle(hQuery);
			Format(expirationdate, 12, DateExpiration);
			
			return TRIAL_WAIT;
		}
		CloseHandle(hQuery);
	}
	return TRIAL_NEW;
}

public bool AddUserAsTmpAdmin(int client, char[] flags, int ImunnityLevel, char[] DateExpiration, bool doCheck)
{
	char today[12];
	bool add = false;
	FormatTime(today, sizeof(today), "%d.%m.%Y");
	if(doCheck)
	{
		add = !isDateGreater(today, DateExpiration);
		PrintToServer("result check : %b", add);
		if(add)
		{
			Handle pack;
			CreateDataTimer(1.0, AddAdminPlayer, pack);
			WritePackCell(pack, client);
			WritePackString(pack, flags);
			WritePackCell(pack, ImunnityLevel);
		}
	}
	else
	{
		Handle pack;
		CreateDataTimer(1.0, AddAdminPlayer, pack);
		WritePackCell(pack, client);
		WritePackString(pack, flags);
		WritePackCell(pack, ImunnityLevel);
	}
	
	if(doCheck)
		return add;
	else 
		return true;
}

public Action AddAdminPlayer(Handle timer, Handle pack)
{
	int client, ImunnityLevel;
	char flags[34];
	
	ResetPack(pack);
	client = ReadPackCell(pack);
	ReadPackString(pack, flags, sizeof(flags));
	ImunnityLevel = ReadPackCell(pack);
	
	GroupId grpID = FindAdmGroup(flags);
	AdminId admin = CreateAdmin();
	if(grpID == INVALID_GROUP_ID)
	{
		SetAdminImmunityLevel(admin, ImunnityLevel);
		for(int i = 0; i < strlen(flags); i++)
		{
			AdminFlag flag;
			if(FindFlagByChar(flags[i], flag))
				SetAdminFlag(admin, flag, true);
			else
				PrintToServer("[SAVM] Error : flag '%c' unknow !", flags[i]);
		}
	}
	else
	{
		int bitFlags = GetAdmGroupAddFlags(grpID);
		AdminFlag admflags[40];
		//BitToFlag(bitFlags, flag);
		FlagBitsToArray(bitFlags, admflags, sizeof(admflags));
		for(int i = 0; i < sizeof(admflags); i++)
			SetAdminFlag(admin, admflags[i], true);
	}
	PreviousAccess[client] = CreateAdmin();
	int bits = GetAdminFlags(GetUserAdmin(client), Access_Real);
	AdminFlag adminflags;
	BitToFlag(bits, adminflags);
	SetAdminFlag(PreviousAccess[client], adminflags, true);
	SetUserAdmin(client, admin, true);
}


public bool CreateDBTables(Handle db)
{
	char query[300];
	Format(query, sizeof(query), QUERY_CREATE_T_TRIALUSER);
	if (!SQL_FastQuery(db, query))
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("[SAVM] ERROR: %s", error);
		return false;
	}
	
	Format(query, sizeof(query), QUERY_CREATE_T_ADMINVIP);
	if (!SQL_FastQuery(db, query))
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("[SAVM] ERROR: %s", error);
		return false;
	}
	
	return true;
}

public bool isDateGreater(const char[] date1, const char[] date2)
{
	char d1[3][5], d2[3][5];
	ExplodeString(date1, ".", d1, sizeof d1, sizeof d1[]);
	ExplodeString(date2, ".", d2, sizeof d2, sizeof d2[]);
	
	if(StringToInt(d1[2]) > StringToInt(d2[2]))
        return true;
	else if(StringToInt(d1[2]) == StringToInt(d2[2]) && StringToInt(d1[1]) > StringToInt(d2[1]))
        return true;
	else if(StringToInt(d1[2]) == StringToInt(d2[2]) && StringToInt(d1[1]) == StringToInt(d2[1]) && StringToInt(d2[0]) > StringToInt(d1[0]))
        return true;
        
	return false;
}

public void GetSteamID(int client, char[] steamID, int maxSize)
{
	GetClientAuthId(client, AuthId_Steam2, steamID, maxSize);
	strcopy(steamID, maxSize, steamID[10]);
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}