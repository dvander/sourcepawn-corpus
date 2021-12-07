#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <basecomm>
#include <adminmenu>

new const String:PLUGIN_VERSION[] = "1.4";

public Plugin:myinfo = 
{
	name = "SQLite Bans",
	author = "Eyal282",
	description = "Banning system that works on SQLite",
	version = PLUGIN_VERSION,
	url = ""
}

enum enPenaltyType
{
	Penalty_Ban = 0,
	Penalty_Gag,
	Penalty_Mute,
	Penalty_Silence
}

// returns false if client cannot be authenticated ( GetClientAuthId ) or if requires penalty extension with dontExtend set to true.
native bool:SQLiteBans_CommPunishClient(client, PenaltyType, time, const String:reason[], source, bool:dontExtend);

// always returns true unless you gave an invalid penalty type, which will result in a native error.
native bool:SQLiteBans_CommPunishIdentity(const String:identity[], PenaltyType, const String:name[], time, const String:reason[], source, bool:dontExtend);

native SQLiteBans_CommUnpunishClient(client, PenaltyType, source);
native SQLiteBans_CommUnpunishIdentity(const String:identity[], PenaltyType, source);

new Handle:dbLocal = INVALID_HANDLE;

new Handle:hcv_Website = INVALID_HANDLE;
new Handle:hcv_LogMethod = INVALID_HANDLE;
new Handle:hcv_LogBannedConnects = INVALID_HANDLE;
new Handle:hcv_DefaultGagTime = INVALID_HANDLE;
new Handle:hcv_DefaultMuteTime = INVALID_HANDLE;
new Handle:hcv_Deadtalk = INVALID_HANDLE;
new Handle:hcv_Alltalk = INVALID_HANDLE;

new Float:ExpireBreach = 0.0;

// Unix, setting to -1 makes it permanent.
new ExpirePenalty[MAXPLAYERS+1][enPenaltyType];

new bool:IsHooked = false;

public APLRes:AskPluginLoad2(Handle:myself, bool:bLate, String:error[], err_max)
{
	CreateNative("SQLiteBans_CommPunishClient", Native_CommPunishClient);
	CreateNative("SQLiteBans_CommPunishIdentity", Native_CommPunishIdentity);
	CreateNative("SQLiteBans_CommUnpunishClient", Native_CommUnpunishClient);
	CreateNative("SQLiteBans_CommUnpunishIdentity", Native_CommUnpunishIdentity);
	
	CreateNative("BaseComm_IsClientGagged", BaseCommNative_IsClientGagged);
	CreateNative("BaseComm_IsClientMuted",  BaseCommNative_IsClientMuted);
	CreateNative("BaseComm_SetClientGag",   BaseCommNative_SetClientGag);
	CreateNative("BaseComm_SetClientMute",  BaseCommNative_SetClientMute);
	
	RegPluginLibrary("basecomm");
}

public Native_CommPunishClient(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	new enPenaltyType:PenaltyType = GetNativeCell(2);
		
	new time = GetNativeCell(3);
	
	new String:reason[256];
	GetNativeString(4, reason, sizeof(reason));
	
	new source = GetNativeCell(5);
	
	new bool:dontExtend = GetNativeCell(6);
	
	new String:AuthId[35];
	
	if(!GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId)))
		return 0;
		
	new String:name[64];
	GetClientName(client, name, sizeof(name));
		
	if(PenaltyType == Penalty_Ban)
	{	
		ThrowNativeError(SP_ERROR_NATIVE, "PenaltyType cannot be equal to Penalty_Ban ( %i )", Penalty_Ban);
		return 0;
	}
	else if(PenaltyType >= enPenaltyType)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid PenaltyType");
		return 0;
	}
	
	new bool:Extend = !(ExpirePenalty[client][PenaltyType] == 0);
	
	if(Extend)
	{
		if(dontExtend)
			return 0;

		ExpirePenalty[client][PenaltyType] = ExpirePenalty[client][PenaltyType] + time * 60;
	}
	else
		ExpirePenalty[client][PenaltyType] = GetTime() + time * 60;
	
	if(time == 0) // Permanent doesn't obey extending
		ExpirePenalty[client][PenaltyType] = -1;
	
	if(IsClientVoiceMuted(client))
		SetClientListeningFlags(client, VOICE_MUTED);
	
	else
		SetClientListeningFlags(client, VOICE_NORMAL);
	
	return SQLiteBans_CommPunishIdentity(AuthId, PenaltyType, name, time, reason, source, dontExtend);
}


public Native_CommPunishIdentity(Handle:plugin, numParams)
{
	new String:identity[35];
	GetNativeString(1, identity, sizeof(identity));
	
	new enPenaltyType:PenaltyType = GetNativeCell(2);

	if(PenaltyType == Penalty_Ban)
	{	
		ThrowNativeError(SP_ERROR_NATIVE, "PenaltyType cannot be equal to Penalty_Ban ( %i )", Penalty_Ban);
		return false;
	}
	else if(PenaltyType >= enPenaltyType)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid PenaltyType");
		return false;
	}
	
	new String:name[64];
	GetNativeString(3, name, sizeof(name));
	
	new time = GetNativeCell(4);
	
	new String:reason[256];
	GetNativeString(5, reason, sizeof(reason));
	
	new source = GetNativeCell(6);
	
	new bool:dontExtend = GetNativeCell(7);
	
	new String:AdminAuthId[35], String:AdminName[64];
	
	if(source == 0)
	{
		AdminAuthId = "CONSOLE";
		AdminName = "CONSOLE";
	}
	else
	{
		GetClientAuthId(source, AuthId_Engine, AdminAuthId, sizeof(AdminAuthId));
		GetClientName(source, AdminName, sizeof(AdminName));
	}
	
	new String:sQuery[1024];
	
	new UnixTime = GetTime();
	
	if(time == 0)
	{
		Format(sQuery, sizeof(sQuery), "INSERT OR REPLACE INTO SQLiteBans_players (AuthId, PlayerName, AdminAuthID, AdminName, Penalty, PenaltyReason, TimestampGiven, DurationMinutes) VALUES ('%s', '%s', '%s', '%s', '%i', '%s', '%i', '%i')", identity, name, AdminAuthId, AdminName, PenaltyType, reason, UnixTime, time);
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
	}
	else
	{
		if(!dontExtend)
		{
			Format(sQuery, sizeof(sQuery), "UPDATE OR IGNORE SQLiteBans_players SET DurationMinutes = DurationMinutes + '%i' WHERE AuthId = '%s' AND Penalty = '%i' AND DurationMinutes != '0'", time, identity, PenaltyType);
			SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
		}
		Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO SQLiteBans_players (AuthId, PlayerName, AdminAuthID, AdminName, Penalty, PenaltyReason, TimestampGiven, DurationMinutes) VALUES ('%s', '%s', '%s', '%s', '%i', '%s', '%i', '%i')", identity, name, AdminAuthId, AdminName, PenaltyType, reason, UnixTime, time);	
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
	}
	
	return true;
}

public Native_CommUnpunishClient(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	new enPenaltyType:PenaltyType = GetNativeCell(2);
	
	new source = GetNativeCell(3);
	
	new String:AuthId[35];
	
	if(!GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId)))
		return false;
		
	else if(PenaltyType == Penalty_Ban)
	{	
		ThrowNativeError(SP_ERROR_NATIVE, "PenaltyType cannot be equal to Penalty_Ban ( %i )", Penalty_Ban);
		return false;
	}
	else if(PenaltyType >= enPenaltyType)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid PenaltyType");
		return false;
	}
	
	ExpirePenalty[client][PenaltyType] = 0;
	
	BaseComm_SetClientGag(client, IsClientChatGagged(client));
	BaseComm_SetClientMute(client, IsClientVoiceMuted(client));
	
	return SQLiteBans_CommUnpunishIdentity(AuthId, PenaltyType, source);
}


public Native_CommUnpunishIdentity(Handle:plugin, numParams)
{
	new String:identity[35];
	GetNativeString(1, identity, sizeof(identity));
	
	new enPenaltyType:PenaltyType = GetNativeCell(2);

	if(PenaltyType == Penalty_Ban)
	{	
		ThrowNativeError(SP_ERROR_NATIVE, "PenaltyType cannot be equal to Penalty_Ban ( %i )", Penalty_Ban);
		return false;
	}
	else if(PenaltyType >= enPenaltyType)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid PenaltyType");
		return false;
	}
	
	//new source = GetNativeCell(3);
	
	new String:sQuery[1024];
	Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteBans_players WHERE Penalty = %i AND AuthId = '%s'", PenaltyType, identity);
	
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
	
	return true;
}

public BaseCommNative_IsClientGagged(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	if(!IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", client);
	
	return IsClientChatGagged(client);
}

public BaseCommNative_IsClientMuted(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	if(!IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", client);
	
	return IsClientVoiceMuted(client);
}

public BaseCommNative_SetClientGag(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if(client < 1 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	if(!IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", client);
	
	new bool:shouldGag = GetNativeCell(2);
	
	if(shouldGag)
		SQLiteBans_CommPunishClient(client, Penalty_Gag, GetConVarInt(hcv_DefaultGagTime), "No reason specified", 0, false);
		
	else
		SQLiteBans_CommUnpunishClient(client, Penalty_Gag, 0);
		
	static Handle:hForward;
	
	if(hForward == null)
	{
		hForward = CreateGlobalForward("BaseComm_OnClientGag", ET_Ignore, Param_Cell, Param_Cell);
	}
	
	Call_StartForward(hForward);
	
	Call_PushCell(client);
	Call_PushCell(shouldGag);
	
	Call_Finish();
	
	return true;
}

public BaseCommNative_SetClientMute(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
	
	if(!IsClientInGame(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not in game", client);
	
	new bool:shouldMute = GetNativeCell(2);
	
	if(shouldMute)
		SQLiteBans_CommPunishClient(client, Penalty_Mute, GetConVarInt(hcv_DefaultMuteTime), "No reason specified", 0, false);
		
	else
		SQLiteBans_CommUnpunishClient(client, Penalty_Mute, 0);
		
 	static Handle:hForward;
	
	if(hForward == null)
	{
		hForward = CreateGlobalForward("BaseComm_OnClientMute", ET_Ignore, Param_Cell, Param_Cell);
	}
	
	Call_StartForward(hForward);
	
	Call_PushCell(client);
	Call_PushCell(shouldMute);
	
	Call_Finish();
	
	return true;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_ban", Command_Ban, ADMFLAG_BAN, "sm_ban <#userid|name> <minutes|0> [reason]");
	RegAdminCmd("sm_banip", Command_BanIP, ADMFLAG_BAN, "sm_banip <#userid|name> <minutes|0> [reason]");
	RegAdminCmd("sm_fban", Command_FullBan, ADMFLAG_BAN, "sm_fban <#userid|name> <minutes|0> [reason]");
	RegAdminCmd("sm_fullban", Command_FullBan, ADMFLAG_BAN, "sm_fban <#userid|name> <minutes|0> [reason]");
	RegAdminCmd("sm_addban", Command_AddBan, ADMFLAG_BAN, "sm_addban <steamid|ip> <minutes|0> [reason]");
	RegAdminCmd("sm_unban", Command_Unban, ADMFLAG_UNBAN, "sm_unban <steamid|ip>");
	
	AddCommandListener(Listener_Penalty, "sm_gag");
	AddCommandListener(Listener_Penalty, "sm_mute");
	AddCommandListener(Listener_Penalty, "sm_silence");
	
	AddCommandListener(Listener_Unpenalty, "sm_ungag");
	AddCommandListener(Listener_Unpenalty, "sm_unmute");
	AddCommandListener(Listener_Unpenalty, "sm_unsilence");
	
	RegAdminCmd("sm_ogag", Command_OfflinePenalty, ADMFLAG_CHAT, "sm_ogag <steamid> <minutes|0> [reason]");
	RegAdminCmd("sm_omute", Command_OfflinePenalty, ADMFLAG_CHAT, "sm_omute <steamid> <minutes|0> [reason]");
	RegAdminCmd("sm_osilence", Command_OfflinePenalty, ADMFLAG_CHAT, "sm_osilence <steamid> <minutes|0> [reason]");
	
	RegAdminCmd("sm_oungag", Command_OfflineUnpenalty, ADMFLAG_CHAT, "sm_oungag <steamid>");
	RegAdminCmd("sm_ounmute", Command_OfflineUnpenalty, ADMFLAG_CHAT, "sm_ounmute <steamid>");
	RegAdminCmd("sm_ounsilence", Command_OfflineUnpenalty, ADMFLAG_CHAT, "sm_ounsilence <steamid>");
	
	RegAdminCmd("sm_banlist", Command_BanList, ADMFLAG_UNBAN, "List of all past given bans");
	RegAdminCmd("sm_commlist", Command_CommList, ADMFLAG_CHAT, "List of all past given communication punishments");
	RegAdminCmd("sm_breachbans", Command_BreachBans, ADMFLAG_UNBAN, "Allows all banned clients to connect for the next minute");
	RegAdminCmd("sm_kickbreach", Command_KickBreach, ADMFLAG_UNBAN, "Kicks all ban breaching clients inside the server");
	
	//RegAdminCmd("sm_sqlitebans_backup", Command_Backup, ADMFLAG_ROOT, "Backs up the bans database to an external file");
	
	RegConsoleCmd("sm_commstatus", Command_CommStatus, "Gives you information about communication penalties active on you");
	
	hcv_Website = CreateConVar("sqlite_bans_url", "http://yourwebsite.com", "Url to direct banned players to go to if they wish to appeal their ban");
	hcv_LogMethod = CreateConVar("sqlite_bans_log_method", "1", "0 - Log in the painful to look at \"L20190412.log\" files. 1 - Log in a seperate file, in sourcemod/logs/SQLiteBans.log");
	hcv_LogBannedConnects = CreateConVar("sqlite_bans_log_banned_connects", "0", "0 - Don't. 1 - Log whenever a banned player attempts to join the server");
	hcv_DefaultGagTime = CreateConVar("sqlite_bans_default_gag_time", "7", "If a plugin uses a basecomm native to gag a player, this is how long the gag will last");
	hcv_DefaultMuteTime = CreateConVar("sqlite_bans_default_mute_time", "7", "If a plugin uses a basecomm native to mute a player, this is how long the mute will last");
	
	hcv_Deadtalk = CreateConVar("sm_deadtalk", "0", "Controls how dead communicate. 0 - Off. 1 - Dead players ignore teams. 2 - Dead players talk to living teammates.", 0, true, 0.0, true, 2.0);
	hcv_Alltalk = FindConVar("sv_alltalk");
	
	HookConVarChange(hcv_Deadtalk, hcvChange_Deadtalk);
	HookConVarChange(hcv_Alltalk, hcvChange_Alltalk);
	
	new String:Value[64];
	GetConVarString(hcv_Deadtalk, Value, sizeof(Value));
	
	hcvChange_Deadtalk(hcv_Deadtalk, Value, Value);
	
	GetConVarString(hcv_Alltalk, Value, sizeof(Value));
	
	hcvChange_Alltalk(hcv_Alltalk, Value, Value);
		
	ConnectToDatabase();
}

public ConnectToDatabase()
{		
	new String:Error[256];
	if((dbLocal = SQLite_UseDatabase("sqlite-bans", Error, sizeof(Error))) == INVALID_HANDLE)
		SetFailState("Could not connect to the database \"sqlite-bans\" at the following error:\n%s", Error);
	
	else
	{ 
		SQL_TQuery(dbLocal, SQLCB_Error, "CREATE TABLE IF NOT EXISTS SQLiteBans_players (AuthId VARCHAR(35), IPAddress VARCHAR(32), PlayerName VARCHAR(64) NOT NULL, AdminAuthID VARCHAR(35) NOT NULL, AdminName VARCHAR(64) NOT NULL, Penalty INT(11) NOT NULL, PenaltyReason VARCHAR(256) NOT NULL, TimestampGiven INT(11) NOT NULL, DurationMinutes INT(11) NOT NULL, UNIQUE(AuthId, Penalty), UNIQUE(IPAddress, Penalty))", _, DBPrio_High); 

		new String:sQuery[256];
		
		Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteBans_players WHERE DurationMinutes != 0 AND TimestampGiven + (60 * DurationMinutes) < %i", GetTime());
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery, _, DBPrio_High);
		
		for(new i=1;i <= MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
			
			else if(!IsClientAuthorized(i))
				continue;
			
			OnClientPostAdminCheck(i);
		}
	}
}

public SQLCB_Error(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
}

public Action:OnClientSayCommand(client, const String:command[], const String:Args[])
{
	new Expire, bool:permanent;
	if(IsClientChatGagged(client, Expire, permanent))
	{
		if(permanent)
			PrintToChat(client, "You have been gagged. It will never expire");
		
		else
			PrintToChat(client, "You have been gagged. Expires in %i minutes", (Expire - GetTime()) / 60);
			
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

// Global agreement that if kick_message is not null and flags have no kick, I'll do the kicking?
public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:source)
{
	if(client == 0)
		return Plugin_Continue;
		
	new String:sQuery[1024];
	
	new String:AuthId[35], String:IPAddress[32], String:Name[64], String:AdminAuthId[35], String:AdminName[64];
	GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	GetClientIP(client, IPAddress, sizeof(IPAddress), true);
	GetClientName(client, Name, sizeof(Name));
	
	if(source == 0)
	{
		AdminAuthId = "CONSOLE";
		AdminName = "CONSOLE";
	}
	else
	{
		GetClientAuthId(source, AuthId_Engine, AdminAuthId, sizeof(AdminAuthId));
		GetClientName(source, AdminName, sizeof(AdminName));
	}
	new UnixTime = GetTime();
	
	if(flags & BANFLAG_AUTO)
		Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO SQLiteBans_players (AuthId, IPAddress, PlayerName, AdminAuthID, AdminName, Penalty, PenaltyReason, TimestampGiven, DurationMinutes) VALUES ('%s', '%s', '%s', '%s', '%s',  %i, '%s', %i, %i)", AuthId, IPAddress, Name, AdminAuthId, AdminName, Penalty_Ban, reason, UnixTime, time);
		
	else if(flags & BANFLAG_IP)
		Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO SQLiteBans_players (IPAddress, PlayerName, AdminAuthID, AdminName, Penalty, PenaltyReason, TimestampGiven, DurationMinutes) VALUES ('%s', '%s', '%s', '%s',  %i, '%s', %i, %i)", IPAddress, Name, AdminAuthId, AdminName, Penalty_Ban, reason, UnixTime, time);

	else if(flags & BANFLAG_AUTHID)
		Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO SQLiteBans_players (AuthId, PlayerName, AdminAuthID, AdminName, Penalty, PenaltyReason, TimestampGiven, DurationMinutes) VALUES ('%s', '%s', '%s', '%s',  %i, '%s', %i, %i)", AuthId, Name, AdminAuthId, AdminName, Penalty_Ban, reason, UnixTime, time);
		
	else
		return Plugin_Continue;
	
	LogSQLiteBans(sQuery);
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
	
	if(kick_message[0] != EOS && flags & BANFLAG_NOKICK)
		KickBannedClient(client, time, reason, UnixTime);
	
	return Plugin_Handled;
}

public Action:OnBanIdentity(const String:identity[], time, flags, const String:reason[], const String:command[], any:source)
{		
	new String:sQuery[1024];
	
	new String:AdminAuthId[35], String:AdminName[64];
	
	if(source == 0)
	{
		AdminAuthId = "CONSOLE";
		AdminName = "CONSOLE";
	}
	else
	{
		GetClientAuthId(source, AuthId_Engine, AdminAuthId, sizeof(AdminAuthId));
		GetClientName(source, AdminName, sizeof(AdminName));
	}
	
	new UnixTime = GetTime();
	
	if(flags & BANFLAG_IP)
		Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO SQLiteBans_players (IPAddress, PlayerName, AdminAuthID, AdminName, Penalty, PenaltyReason, TimestampGiven, DurationMinutes) VALUES ('%s', '%s', '%s', '%s',  %i, '%s', %i, %i)", identity, "", AdminAuthId, AdminName, Penalty_Ban, reason, UnixTime, time);
		
	else if(flags & BANFLAG_AUTHID)
		Format(sQuery, sizeof(sQuery), "INSERT OR IGNORE INTO SQLiteBans_players (AuthId, PlayerName, AdminAuthID, AdminName, Penalty, PenaltyReason, TimestampGiven, DurationMinutes) VALUES ('%s', '%s', '%s', '%s',  %i, '%s', %i, %i)", identity, "", AdminAuthId, AdminName, Penalty_Ban, reason, UnixTime, time);
		
	else
		return Plugin_Continue;
	
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
	
	return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
		
	if(IsClientVoiceMuted(client))
		SetClientListeningFlags(client, VOICE_MUTED);
	
	else
		SetClientListeningFlags(client, VOICE_NORMAL);
}


public Action:Event_PlayerDeath(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client == 0)
		return;
		
	if(IsClientVoiceMuted(client))
	{
		SetClientListeningFlags(client, VOICE_MUTED);
		return;
	}
	
	else if(GetConVarBool(hcv_Alltalk))
	{
		SetClientListeningFlags(client, VOICE_NORMAL);
	}
	
	switch(GetConVarInt(hcv_Deadtalk))
	{
		case 1: SetClientListeningFlags(client, VOICE_LISTENALL);
		case 2: SetClientListeningFlags(client, VOICE_TEAM);
	}
}


public hcvChange_Deadtalk(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) == 1)
	{
		HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
		IsHooked = true;
		return;
	}
	
	else if(IsHooked)
	{
		UnhookEvent("player_spawn", Event_PlayerSpawn);
		UnhookEvent("player_death", Event_PlayerDeath);		
		IsHooked = false;
	}
}


public hcvChange_Alltalk(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new mode = GetConVarInt(hcv_Deadtalk);
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(IsClientVoiceMuted(i))
		{
			SetClientListeningFlags(i, VOICE_MUTED);
			continue;
		}
		
		else if(GetConVarBool(convar))
		{
			SetClientListeningFlags(i, VOICE_NORMAL);
			continue;
		}
		
		else if(!IsPlayerAlive(i))
		{
			if(mode == 1)
			{
				SetClientListeningFlags(i, VOICE_LISTENALL);
				continue;
			}
			else if (mode == 2)
			{
				SetClientListeningFlags(i, VOICE_TEAM);
				continue;
			}
		}
	}
}

public OnClientDisconnect(client)
{
	new count = view_as<int>(enPenaltyType);
	for(new i=0;i < count;i++)
		ExpirePenalty[client][i] = 0;
}

public OnClientPostAdminCheck(client)
{
	new count = view_as<int>(enPenaltyType);
	for(new i=0;i < count;i++)
		ExpirePenalty[client][i] = 0;
		
	if(IsFakeClient(client))
		return;

	new String:AuthId[35];
	
	if(!GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId)))
		CreateTimer(5.0, Timer_Auth, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	else
		FindClientPenalties(client);
}

public Action:Timer_Auth(Handle:timer, UserId)
{
	new client = GetClientOfUserId(UserId);
	
	new String:AuthId[35]
	if (!GetClientAuthId(client, AuthId_Engine, AuthId, sizeof AuthId))
		return Plugin_Stop;
		
	else
		FindClientPenalties(client);
	   
	return Plugin_Continue;
}

FindClientPenalties(client)
{
	if(ExpireBreach > GetGameTime())
		return;

	new count = view_as<int>(enPenaltyType);
	for(new i=0;i < count;i++)
		ExpirePenalty[client][i] = 0;
		
	new bool:GotAuthId;
	new String:AuthId[35], String:IPAddress[32];
	GotAuthId = GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
	GetClientIP(client, IPAddress, sizeof(IPAddress), true);
	
	new String:sQuery[256];
	
	if(GotAuthId)
		Format(sQuery, sizeof(sQuery), "SELECT * FROM SQLiteBans_players WHERE AuthId = '%s' OR IPAddress = '%s'", AuthId, IPAddress);
		
	else
		Format(sQuery, sizeof(sQuery), "SELECT * FROM SQLiteBans_players WHERE IPAddress = '%s'", IPAddress);
	
	SQL_TQuery(dbLocal, SQLCB_GetClientInfo, sQuery, GetClientUserId(client));
}


public SQLCB_GetClientInfo(Handle:db, Handle:hndl, const String:sError[], data)
{
	if(hndl == null)
		ThrowError(sError);
    
	new client = GetClientOfUserId(data);

	if(client == 0)
		return;
	
	else if(SQL_GetRowCount(hndl) == 0)
		return;
	
	new bool:Purge = false;
	
	new UnixTime = GetTime();
	
	while(SQL_FetchRow(hndl))
	{
		new TimestampGiven = SQL_FetchInt(hndl, 7);
		new DurationMinutes = SQL_FetchInt(hndl, 8);
		
		if(DurationMinutes != 0 && TimestampGiven + (DurationMinutes * 60) < UnixTime) // if(TimestampGiven + (DurationMinutes * 60) < GetTime())
		{
			Purge = true;
			continue;
		}	
		new enPenaltyType:Penalty = enPenaltyType:SQL_FetchInt(hndl, 5);
		
		switch(Penalty)
		{
			case Penalty_Ban:
			{
				new String:BanReason[256];
				SQL_FetchString(hndl, 6, BanReason, sizeof(BanReason));
				
				new String:AuthId[35], String:IPAddress[32];
				GetClientAuthId(client, AuthId_Engine, AuthId, sizeof(AuthId));
				GetClientIP(client, IPAddress, sizeof(IPAddress), true);
				
				if(GetConVarBool(hcv_LogBannedConnects))
				{
					if(DurationMinutes == 0)
						LogSQLiteBans_BannedConnect("Kicked banned client %N ([AuthId: %s],[IP: %s]), ban will never expire", client, AuthId, IPAddress)
						
					else
						LogSQLiteBans_BannedConnect("Kicked banned client %N ([AuthId: %s],[IP: %s]), ban expires in %i minutes", client, AuthId, IPAddress, ((TimestampGiven + (DurationMinutes * 60)) - UnixTime) / 60)
				}
				KickBannedClient(client, DurationMinutes, BanReason, TimestampGiven);
				
				return;
			}
			default:
			{
				if(Penalty >= enPenaltyType)
					continue;

				if(DurationMinutes == 0)
					ExpirePenalty[client][Penalty] = -1;
					
				else
					ExpirePenalty[client][Penalty] = TimestampGiven + DurationMinutes * 60;
			}
		}
	}
	
	if(IsClientChatGagged(client))
		BaseComm_SetClientGag(client, true);
		
	if(IsClientVoiceMuted(client))
		BaseComm_SetClientMute(client, true);
		
	if(Purge)
	{
		new String:sQuery[256];
			
		Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteBans_players WHERE DurationMinutes != 0 AND TimestampGiven + (60 * DurationMinutes) < %i", UnixTime);
		SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
	}
}

public Action:Command_Ban(client, args)
{
	if(ExpireBreach != 0.0)
	{	
		ReplyToCommand(client, "You need to disable ban breach by using !kickbreach before banning a client.");
		return Plugin_Handled;
	}	
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ban <#userid|name> <time> [reason]");
		return Plugin_Handled;
	}	
	
	new String:ArgStr[256];
	new String:TargetArg[64], String:BanDuration[32];
	new String:BanReason[170];
	GetCmdArgString(ArgStr, sizeof(ArgStr));
	
	new len = BreakString(ArgStr, TargetArg, sizeof(TargetArg));
	
	new len2 = BreakString(ArgStr[len], BanDuration, sizeof(BanDuration));
	
	if(len2 != -1)
		FormatEx(BanReason, sizeof(BanReason), ArgStr[len+len2]);
	
	new target_list[1], String:target_name[MAX_TARGET_LENGTH];
	new TargetClient, ReplyReason, bool:tn_is_ml;
	
	if ((ReplyReason = ProcessTargetString(
		TargetArg,
		client, 
		target_list, 
		1, 
		COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, ReplyReason);
		return Plugin_Handled;
	}
	
	TargetClient = target_list[0];
	
	new bool:canTarget = false;
	
	canTarget = CanClientBanTarget(client, TargetClient);
		
	if(!canTarget)
	{
		ReplyToTargetError(client, COMMAND_TARGET_IMMUNE);
		return Plugin_Handled;
	}
	
	new Duration = StringToInt(BanDuration);
	
	// This is the function to ban a client with source being the banning client or 0 for console. If you want my plugin to use its own kicking mechanism, add BANFLAG_NOKICK and set the kick reason to anything apart from ""
	BanClient(TargetClient, Duration, BANFLAG_AUTHID|BANFLAG_NOKICK, BanReason, "KICK!!!", "sm_ban", client);
	
	new String:AuthId[35], String:AdminAuthId[35], String:IPAddress[32];
	GetClientIP(TargetClient, IPAddress, sizeof(IPAddress), true);
	GetClientAuthId(TargetClient, AuthId_Engine, AuthId, sizeof(AuthId));
	GetClientAuthId(client, AuthId_Engine, AdminAuthId, sizeof(AdminAuthId));
	
	if(Duration == 0)
	{
		ShowActivity2(client, "[SM] ", "permanently banned %N for the reason \"%s\"", TargetClient, BanReason);
		LogSQLiteBans("Admin %N [AuthId: %s] banned %N permanently ([AuthId: %s],[IP: %s])", client, AdminAuthId, TargetClient, AuthId, IPAddress);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "banned %N for %i minutes for the reason \"%s\"", TargetClient, Duration, BanReason);
		LogSQLiteBans("Admin %N [AuthId: %s] banned %N for %i minutes ([AuthId: %s],[IP: %s])", client, AdminAuthId, TargetClient, Duration, AuthId, IPAddress);
	}
	return Plugin_Handled;
}

public Action:Command_BanIP(client, args)
{
	if(ExpireBreach != 0.0)
	{	
		ReplyToCommand(client, "You need to disable ban breach by using !kickbreach before banning a client.");
		return Plugin_Handled;
	}	
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_banip <#userid|name> <time> [reason]");
		return Plugin_Handled;
	}	
	
	new String:ArgStr[256];
	new String:TargetArg[64], String:BanDuration[32];
	new String:BanReason[170];
	GetCmdArgString(ArgStr, sizeof(ArgStr));
	
	new len = BreakString(ArgStr, TargetArg, sizeof(TargetArg));
	
	new len2 = BreakString(ArgStr[len], BanDuration, sizeof(BanDuration));
	
	if(len2 != -1)
		FormatEx(BanReason, sizeof(BanReason), ArgStr[len+len2]);
	
	new target_list[1], String:target_name[MAX_TARGET_LENGTH];
	new TargetClient, ReplyReason, bool:tn_is_ml;
	
	if ((ReplyReason = ProcessTargetString(
		TargetArg,
		client, 
		target_list, 
		1, 
		COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, ReplyReason);
		return Plugin_Handled;
	}
	
	TargetClient = target_list[0];
	
	new bool:canTarget = false;
	
	canTarget = CanClientBanTarget(client, TargetClient);
		
	if(!canTarget)
	{
		ReplyToTargetError(client, COMMAND_TARGET_IMMUNE);
		return Plugin_Handled;
	}
	
	new Duration = StringToInt(BanDuration);
	// This is the function to IP ban a client with source being the banning client or 0 for console. If you want my plugin to use its own kicking mechanism, add BANFLAG_NOKICK and set the kick reason to anything apart from ""
	BanClient(TargetClient, Duration, BANFLAG_IP|BANFLAG_NOKICK, BanReason, "KICK!!!", "sm_banip", client);
	
	new String:AuthId[35], String:AdminAuthId[35], String:IPAddress[32];
	GetClientIP(TargetClient, IPAddress, sizeof(IPAddress), true);
	GetClientAuthId(TargetClient, AuthId_Engine, AuthId, sizeof(AuthId));
	GetClientAuthId(client, AuthId_Engine, AdminAuthId, sizeof(AdminAuthId));
	
	if(Duration == 0)
	{
		ShowActivity2(client, "[SM] ", "permanently banned %N for the reason \"%s\"", TargetClient, BanReason);
		LogSQLiteBans("Admin %N [AuthId: %s] IP banned %N permanently ([AuthId: %s],[IP: %s])", client, AdminAuthId, TargetClient, AuthId, IPAddress);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "banned %N for %i minutes for the reason \"%s\"", TargetClient, Duration, BanReason);
		LogSQLiteBans("Admin %N [AuthId: %s] IP banned %N for %i minutes ([AuthId: %s],[IP: %s])", client, AdminAuthId, TargetClient, Duration, AuthId, IPAddress);
	}
	
	return Plugin_Handled;
}

public Action:Command_FullBan(client, args)
{
	if(ExpireBreach != 0.0)
	{	
		ReplyToCommand(client, "You need to disable ban breach by using !kickbreach before banning a client.");
		return Plugin_Handled;
	}	
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fban <#userid|name> <time> [reason]");
		return Plugin_Handled;
	}	
	
	new String:ArgStr[256];
	new String:TargetArg[64], String:BanDuration[32];
	new String:BanReason[170];
	GetCmdArgString(ArgStr, sizeof(ArgStr));
	
	new len = BreakString(ArgStr, TargetArg, sizeof(TargetArg));
	
	new len2 = BreakString(ArgStr[len], BanDuration, sizeof(BanDuration));
	
	if(len2 != -1)
		FormatEx(BanReason, sizeof(BanReason), ArgStr[len+len2]);
	
	new target_list[1], String:target_name[MAX_TARGET_LENGTH];
	new TargetClient, ReplyReason, bool:tn_is_ml;
	
	if ((ReplyReason = ProcessTargetString(
		TargetArg,
		client, 
		target_list, 
		1, 
		COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, ReplyReason);
		return Plugin_Handled;
	}
	
	TargetClient = target_list[0];
	
	new bool:canTarget = false;
	
	canTarget = CanClientBanTarget(client, TargetClient);
		
	if(!canTarget)
	{
		ReplyToTargetError(client, COMMAND_TARGET_IMMUNE);
		return Plugin_Handled;
	}

	GetCmdArg(0, ArgStr, sizeof(ArgStr)); // I already used it.
	
	new Duration = StringToInt(BanDuration);
	// This is the function to full ban a client with source being the banning client or 0 for console. If you want my plugin to use its own kicking mechanism, add BANFLAG_NOKICK and set the kick reason to anything apart from ""
	BanClient(TargetClient, Duration, BANFLAG_AUTO|BANFLAG_NOKICK, BanReason, "KICK!!!", ArgStr, client);
	
	if(Duration == 0)
		ShowActivity2(client, "[SM] ", "permanently banned %N", TargetClient);
		
	else
		ShowActivity2(client, "[SM] ", "banned %N for %i minutes", TargetClient, Duration);
		
	new String:AuthId[35], String:AdminAuthId[35], String:IPAddress[32];
	GetClientIP(TargetClient, IPAddress, sizeof(IPAddress), true);
	GetClientAuthId(TargetClient, AuthId_Engine, AuthId, sizeof(AuthId));
	GetClientAuthId(client, AuthId_Engine, AdminAuthId, sizeof(AdminAuthId));
	
	if(Duration == 0)
	{
		ShowActivity2(client, "[SM] ", "permanently banned %N for the reason \"%s\"", TargetClient, BanReason);
		LogSQLiteBans("Admin %N [AuthId: %s] fully banned %N permanently ([AuthId: %s],[IP: %s])", client, AdminAuthId, TargetClient, AuthId, IPAddress);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "banned %N for %i minutes for the reason \"%s\"", TargetClient, Duration, BanReason);
		LogSQLiteBans("Admin %N [AuthId: %s] fully banned %N for %i minutes ([AuthId: %s],[IP: %s])", client, AdminAuthId, TargetClient, Duration, AuthId, IPAddress);
	}
	
	return Plugin_Handled;
}


public Action:Command_AddBan(client, args)
{
	if(ExpireBreach != 0.0)
	{	
		ReplyToCommand(client, "You need to disable ban breach by using !kickbreach before banning a client.");
		return Plugin_Handled;
	}	
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addban <steamid|ip> <minutes|0> [reason]");
		return Plugin_Handled;
	}	
	
	new String:ArgStr[256];
	new String:TargetArg[64], String:BanDuration[32];
	new String:BanReason[170];
	GetCmdArgString(ArgStr, sizeof(ArgStr));
	
	new len = BreakString(ArgStr, TargetArg, sizeof(TargetArg));
	
	new len2 = BreakString(ArgStr[len], BanDuration, sizeof(BanDuration));
	
	if(len2 != -1)
		FormatEx(BanReason, sizeof(BanReason), ArgStr[len+len2]);
	
	new bool:isAuthBan = !IsCharNumeric(TargetArg[0]);
	
	new flags;
	if(isAuthBan)
		flags &= BANFLAG_AUTHID
		
	else
		flags &= BANFLAG_IP;
		
	new Duration = StringToInt(BanDuration);
	// This is the function to ban an identity with source being the banning client or 0 for console. If you want my plugin to use its own kicking mechanism, add BANFLAG_NOKICK and set the kick reason to anything apart from ""
	BanIdentity(TargetArg, Duration, flags, BanReason, "sm_addban", client); 
		
	ReplyToCommand(client, "Added %s to the ban list", TargetArg);
	
	new String:AdminAuthId[35];
	GetClientAuthId(client, AuthId_Engine, AdminAuthId, sizeof(AdminAuthId));
	
	if(Duration == 0)
		LogSQLiteBans("Admin %N [AuthId: %s] added a permanent ban on identity: %s", client, AdminAuthId, TargetArg);
		
	else
		LogSQLiteBans("Admin %N [AuthId: %s] added a %i minute ban on identity: %s", client, AdminAuthId, Duration, TargetArg);
		
	return Plugin_Handled;
}

public Action:Command_Unban(client, args)
{
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unban <steamid|ip>");
		return Plugin_Handled;
	}	
	
	new String:TargetArg[64];
	GetCmdArgString(TargetArg, sizeof(TargetArg));
	StripQuotes(TargetArg);
	ReplaceString(TargetArg, sizeof(TargetArg), " ", ""); // Some bug when using rcon...
	
	if(TargetArg[0] == EOS)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unban <steamid|ip>");
		return Plugin_Handled;
	}
	
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, GetEntityUserId(client));
	WritePackCell(DP, GetCmdReplySource());
	
	WritePackString(DP, TargetArg);
	
	if(client == 0)
		WritePackString(DP, "CONSOLE");
		
	else
	{
		new String:AdminAuthId[35];
		GetClientAuthId(client, AuthId_Engine, AdminAuthId, sizeof(AdminAuthId));
		
		WritePackString(DP, AdminAuthId);
	}
	
	new String:sQuery[1024];
	Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteBans_players WHERE Penalty = %i AND (AuthId = '%s' OR IPAddress = '%s')", Penalty_Ban, TargetArg, TargetArg);
	SQL_TQuery(dbLocal, SQLCB_Unban, sQuery, DP);
	
	return Plugin_Handled;
}

public SQLCB_Unban(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	if(hndl == null)
	{
		CloseHandle(DP);
		ThrowError(sError);
    }
	
	ResetPack(DP);
	
	new UserId = ReadPackCell(DP);
	
	new ReplySource:CmdReplySource = ReadPackCell(DP);
	
	new String:TargetArg[64];
	ReadPackString(DP, TargetArg, sizeof(TargetArg));
	
	new String:AdminAuthId[35];
	ReadPackString(DP, AdminAuthId, sizeof(AdminAuthId)); // Even if the player disconnects we must log him.
	
	CloseHandle(DP);
	new client = GetEntityOfUserId(UserId);
	
	new AffectedRows = SQL_GetAffectedRows(hndl)
	ReplyToCommandBySource(client, CmdReplySource, "Successfully deleted %i bans matching %s", AffectedRows, TargetArg);
	
	LogSQLiteBans("Admin %N [AuthId: %s] deleted %i bans matching \"%s\"", client, AdminAuthId, AffectedRows, TargetArg);
}

public Action:Listener_Penalty(client, const String:command[], args)
{
	if(client && !CheckCommandAccess(client, command, ADMFLAG_CHAT))
		return Plugin_Continue;
		
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: %s <#userid|name> <time> [reason]", command);
		return Plugin_Stop;
	}	
	
	new String:ArgStr[256];
	new String:TargetArg[64], String:PenaltyDuration[32];
	new String:PenaltyReason[170];
	GetCmdArgString(ArgStr, sizeof(ArgStr));
	
	new len = BreakString(ArgStr, TargetArg, sizeof(TargetArg));
	
	new len2 = BreakString(ArgStr[len], PenaltyDuration, sizeof(PenaltyDuration));
	
	if(len2 != -1)
		FormatEx(PenaltyReason, sizeof(PenaltyReason), ArgStr[len+len2]);
	
	new target_list[MAXPLAYERS+1], String:target_name[MAX_TARGET_LENGTH];
	new TargetClient, target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
		TargetArg,
		client, 
		target_list, 
		sizeof(target_list), 
		COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Stop;
	}
	
	new String:PenaltyAlias[32];
	new PenaltyType = enPenaltyType;
	if(StrEqual(command, "sm_gag"))
	{
		PenaltyType = Penalty_Gag;
		PenaltyAlias = "gagged";
	}
	else if(StrEqual(command, "sm_mute"))
	{
		PenaltyType = Penalty_Mute;
		PenaltyAlias = "muted";
	}
	else if(StrEqual(command, "sm_silence"))
	{
		PenaltyType = Penalty_Silence;
		PenaltyAlias = "silenced";
	}
	
	new Duration = StringToInt(PenaltyDuration);
	
	TargetClient = target_list[0];
	
	new bool:Extended = !(ExpirePenalty[TargetClient][PenaltyType] == 0);

	if(ExpirePenalty[TargetClient][PenaltyType] == -1)
	{
		ReplyToCommand(client, "[SM] Cannot extend penalty on a permanently %s client.", PenaltyAlias);
		return Plugin_Stop;
	}
	
	if(!IsClientAuthorized(TargetClient))
	{
		ReplyToCommand(client, "[SM] Error: Could not authenticate %N.", TargetClient);
		return Plugin_Stop;
	}
	if(!SQLiteBans_CommPunishClient(TargetClient, PenaltyType, Duration, PenaltyReason, client, false))
		return Plugin_Stop;

	if(!Extended)
	{
		if(Duration == 0)
		{
			PrintToChat(TargetClient, "You have been permanently %s by %N.", PenaltyAlias, client);
			ShowActivity2(client, "[SM] ", "permanently %s %N", PenaltyAlias, TargetClient);
		}
		else
		{
			PrintToChat(TargetClient, "You have been %s by %N for %i minutes.", PenaltyAlias, client, Duration);
			ShowActivity2(client, "[SM] ", "%s %N for %i minutes", PenaltyAlias, TargetClient, Duration);
		}
	}
	else
	{
		PrintToChat(TargetClient, "You have been %s by %N for %i more minutes ( total: %i )", PenaltyAlias, client, Duration, PositiveOrZero(((ExpirePenalty[TargetClient][PenaltyType] - GetTime()) / 60)));
		ShowActivity2(client, "[SM] ", "%s %N for %i more minutes ( total: %i )", PenaltyAlias, TargetClient, Duration, PositiveOrZero((ExpirePenalty[TargetClient][PenaltyType] - GetTime()) / 60));
	}	
	
	PrintToChat(TargetClient, "Reason: %s", PenaltyReason);
	
	return Plugin_Stop;
}


public Action:Listener_Unpenalty(client, const String:command[], args)
{
	if(client && !CheckCommandAccess(client, command, ADMFLAG_CHAT))
		return Plugin_Continue;
		
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: %s <#userid|name>", command);
		return Plugin_Stop;
	}	
	
	new String:TargetArg[64];
	GetCmdArg(1, TargetArg, sizeof(TargetArg));

	new target_list[MAXPLAYERS+1], String:target_name[MAX_TARGET_LENGTH];
	new TargetClient, target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
		TargetArg,
		client, 
		target_list, 
		sizeof(target_list), 
		COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Stop;
	}
	
	new String:PenaltyAlias[32];
	new PenaltyType = enPenaltyType;
	
	if(StrEqual(command, "sm_ungag"))
	{
		PenaltyType = Penalty_Gag;
		PenaltyAlias = "ungagged";
	}
	else if(StrEqual(command, "sm_unmute"))
	{
		PenaltyType = Penalty_Mute;
		PenaltyAlias = "unmuted";
	}
	else if(StrEqual(command, "sm_unsilence"))
	{
		PenaltyType = Penalty_Silence;
		PenaltyAlias = "unsilenced";
	}
	
	for(new i=0;i < target_count;i++)
	{
		TargetClient = target_list[i];
		
		PrintToChat(TargetClient, "You have been %s by %N", PenaltyAlias, client);
		
		SQLiteBans_CommUnpunishClient(TargetClient, PenaltyType, client);
	}

	ShowActivity2(client, "[SM] ", "%s %s", PenaltyAlias, target_name);
		
	return Plugin_Stop;
}


public Action:Command_OfflinePenalty(client, args)
{
	new String:command[32];
	GetCmdArg(0, command, sizeof(command));
	
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: %s <steamid> <minutes|0> [reason]", command);
		return Plugin_Handled;
	}	

	new String:ArgStr[256];
	new String:TargetArg[64], String:PenaltyDuration[32];
	new String:PenaltyReason[170];
	GetCmdArgString(ArgStr, sizeof(ArgStr));
	
	new len = BreakString(ArgStr, TargetArg, sizeof(TargetArg));
	
	new len2 = BreakString(ArgStr[len], PenaltyDuration, sizeof(PenaltyDuration));
	
	if(len2 != -1)
		FormatEx(PenaltyReason, sizeof(PenaltyReason), ArgStr[len+len2]);
		
	new PenaltyType = enPenaltyType;
	new String:PenaltyAlias[32];
	
	if(StrEqual(command, "sm_ogag"))
	{
		PenaltyType = Penalty_Gag;
		PenaltyAlias = "gagged";
	}
	else if(StrEqual(command, "sm_omute"))
	{
		PenaltyType = Penalty_Mute;
		PenaltyAlias = "muted";
	}
	else if(StrEqual(command, "sm_osilence"))
	{
		PenaltyType = Penalty_Silence;
		PenaltyAlias = "silenced";
	}


	new Duration = StringToInt(PenaltyDuration);
	
	if(SQLiteBans_CommPunishIdentity(TargetArg, PenaltyType, "", Duration, PenaltyReason, client, false))
	{
		if(Duration != 0)
		{
			ReplyToCommand(client, "Successfully %s steamid %s for %i minutes.", PenaltyAlias, TargetArg, Duration);
			ReplyToCommand(client, "Note: Using this command on an already %s player will extend the duration", PenaltyAlias);
		}	
		else
			ReplyToCommand(client, "Successfully %s steamid %s permanently", PenaltyAlias, TargetArg);
			
	}
	else
	{
		ReplyToCommand(client, "Could not %s steamid %s", PenaltyAlias, TargetArg);
	}
	return Plugin_Handled;
}


public Action:Command_OfflineUnpenalty(client, args)
{
	new String:command[32];
	GetCmdArg(0, command, sizeof(command));
	if(args == 0)
	{
		ReplyToCommand(client, "[SM] Usage: %s <steamid>", command);
		return Plugin_Handled;
	}	
	
	new String:TargetArg[64];
	GetCmdArgString(TargetArg, sizeof(TargetArg));
	StripQuotes(TargetArg);
	
	if(TargetArg[0] == EOS)
	{
		ReplyToCommand(client, "[SM] Usage: %s <steamid>", command);
		return Plugin_Handled;
	}
	new UserId = (client == 0 ? 0 : GetClientUserId(client));
	
	new PenaltyType = enPenaltyType;
	
	if(StrEqual(command, "sm_oungag"))
		PenaltyType = Penalty_Gag;

	else if(StrEqual(command, "sm_ounmute"))
		PenaltyType = Penalty_Mute;
		
	else if(StrEqual(command, "sm_ounsilence"))
		PenaltyType = Penalty_Silence;
		
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, UserId);
	WritePackCell(DP, GetCmdReplySource());
	WritePackString(DP, TargetArg);
	
	new String:sQuery[1024];
	Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteBans_players WHERE Penalty = %i AND AuthId = '%s'", PenaltyType, TargetArg);
	SQL_TQuery(dbLocal, SQLCB_Unpenalty, sQuery, DP);
	
	return Plugin_Handled;
}


public SQLCB_Unpenalty(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	if(hndl == null)
	{
		CloseHandle(DP);
		ThrowError(sError);
    }
	
	ResetPack(DP);
	
	new UserId = ReadPackCell(DP);
	
	new ReplySource:CmdReplySource = ReadPackCell(DP);
	
	new String:TargetArg[64];
	ReadPackString(DP, TargetArg, sizeof(TargetArg));
	
	CloseHandle(DP);
	new client = (UserId == 0 ? 0 : GetClientOfUserId(UserId));
	
	if(client == 0)
		CmdReplySource = SM_REPLY_TO_CONSOLE;
	
	new ReplySource:PrevReplySource = GetCmdReplySource();
	
	SetCmdReplySource(CmdReplySource);
	
	ReplyToCommand(client, "Successfully deleted %i penalties matching %s", SQL_GetAffectedRows(hndl), TargetArg);
	
	SetCmdReplySource(PrevReplySource);
}

public Action:Command_CommStatus(client, args)
{
	new String:ExpirationDate[64];
	new Expire, UnixTime = GetTime();
	new bool:Gagged = IsClientChatGagged(client, Expire);
	FormatTime(ExpirationDate, sizeof(ExpirationDate), "%d/%m/%Y - %H:%M:%S", Expire);
	
	new MinutesLeft = (Expire - UnixTime) / 60;
	if(Expire <= 0) // If you aren't gagged, it won't expire lol.
	{
		FormatEx(ExpirationDate, sizeof(ExpirationDate), "Never");
		MinutesLeft = 0;
	}	
	
	PrintToChat(client, "Gagged: %s, Expiration: %s ( %i minutes )", Gagged ? "Yes" : "No", ExpirationDate, MinutesLeft);
	
	new bool:Muted = IsClientVoiceMuted(client, Expire);
	
	FormatTime(ExpirationDate, sizeof(ExpirationDate), "%d/%m/%Y - %H:%M:%S", Expire);
	
	MinutesLeft = (Expire - UnixTime) / 60;
	if(Expire <= 0) // If you aren't muted, it won't expire lol.
	{
		FormatEx(ExpirationDate, sizeof(ExpirationDate), "Never");
		MinutesLeft = 0;
	}	
	
	PrintToChat(client, "Muted: %s, Expiration: %s ( %i minutes )", Muted ? "Yes" : "No", ExpirationDate, MinutesLeft);
	
	return Plugin_Handled;
}

public Action:Command_BanList(client, args)
{
	if(client == 0)
		return Plugin_Handled;
	
	QueryBanList(client, 0);
	
	return Plugin_Handled;
}

public QueryBanList(client, ItemPos)
{
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, GetClientUserId(client));
	WritePackCell(DP, ItemPos);
		
	new String:sQuery[256];
	
	Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteBans_players WHERE DurationMinutes != 0 AND TimestampGiven + (60 * DurationMinutes) < %i", GetTime());
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
		
	Format(sQuery, sizeof(sQuery), "SELECT * FROM SQLiteBans_players WHERE Penalty = %i ORDER BY TimestampGiven DESC", Penalty_Ban); 
	SQL_TQuery(dbLocal, SQLCB_BanList, sQuery, DP); 
}

public SQLCB_BanList(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{

	ResetPack(DP);
	
	new UserId = ReadPackCell(DP);
	new ItemPos = ReadPackCell(DP);
	
	CloseHandle(DP);
	
	if(hndl == null)
		ThrowError(sError);
    
	new client = GetClientOfUserId(UserId);

	if(client != 0)
	{
		if(SQL_GetRowCount(hndl) == 0)
		{
			PrintToChat(client, "There are no banned clients from the server");
			PrintToConsole(client, "There are no banned clients from the server");
		}
		new String:TempFormat[512], String:AuthId[35], String:IPAddress[32], String:PlayerName[64], String:BanReason[256];
		
		new Handle:hMenu = CreateMenu(BanList_MenuHandler);
	
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, AuthId, sizeof(AuthId));
			SQL_FetchString(hndl, 1, IPAddress, sizeof(IPAddress));
			SQL_FetchString(hndl, 2, PlayerName, sizeof(PlayerName));
			
			if(PlayerName[0] == EOS)
				FormatEx(PlayerName, sizeof(PlayerName), AuthId);
				
			if(PlayerName[0] == EOS)
				FormatEx(PlayerName, sizeof(PlayerName), IPAddress);
			
			SQL_FetchString(hndl, 6, BanReason, sizeof(BanReason));
			StripQuotes(BanReason);
			
			new BanExpiration = SQL_FetchInt(hndl, 8) - ((GetTime() - SQL_FetchInt(hndl, 7)) / 60)
			
			Format(TempFormat, sizeof(TempFormat), "\"%s\" \"%s\" \"%i\" \"%s\"", AuthId, IPAddress, BanExpiration, BanReason);
			AddMenuItem(hMenu, TempFormat, PlayerName);
		}
		
		DisplayMenuAtItem(hMenu, client, ItemPos, MENU_TIME_FOREVER);
	
	}
}


public BanList_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		new String:AuthId[32], String:IPAddress[32], String:Name[64], String:Info[512], BanExpiration, String:sBanExpiration[64], String:ExpirationDate[64], String:BanReason[256];
		
		GetMenuItem(hMenu, item, Info, sizeof(Info), _, Name, sizeof(Name));
		
		new len = BreakString(Info, AuthId, sizeof(AuthId));
		new len2 = BreakString(Info[len], IPAddress, sizeof(IPAddress));
		
		new len3 = BreakString(Info[len+len2], sBanExpiration, sizeof(sBanExpiration));
		BanExpiration = StringToInt(sBanExpiration);
		
		if(len3 != -1)
			BreakString(Info[len+len2+len3], BanReason, sizeof(BanReason));
		
		FormatTime(ExpirationDate, sizeof(ExpirationDate), "%d/%m/%Y - %H:%M:%S", GetTime() + (60 * BanExpiration));
		
		if(BanExpiration <= 0)
		{
			BanExpiration = 0;
			FormatEx(ExpirationDate, sizeof(ExpirationDate), "Never");
		}
		PrintToChat(client, "Name: %s, Steam ID: %s, Ban Reason: %s", Name, AuthId, BanReason);
		PrintToChat(client, "IP Address: %s, Ban Expiration: %s ( %i minutes )", IPAddress, ExpirationDate, BanExpiration);
		PrintToConsole(client, "Name: %s, SteamID: %s, Ban Reason: %s, IP Address: %s, Ban Expiration: %s ( %i minutes )", Name, AuthId, BanReason, IPAddress, ExpirationDate, BanExpiration);
		
		QueryBanList(client, GetMenuSelectionPosition());
	}
}


public Action:Command_CommList(client, args)
{
	if(client == 0)
		return Plugin_Handled;
	
	QueryCommList(client, 0);
	
	return Plugin_Handled;
}
public QueryCommList(client, ItemPos)
{
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, GetClientUserId(client));
	WritePackCell(DP, ItemPos);
		
	new String:sQuery[256];
	
	Format(sQuery, sizeof(sQuery), "DELETE FROM SQLiteBans_players WHERE DurationMinutes != 0 AND TimestampGiven + (60 * DurationMinutes) < %i", GetTime());
	SQL_TQuery(dbLocal, SQLCB_Error, sQuery);
		
	Format(sQuery, sizeof(sQuery), "SELECT * FROM SQLiteBans_players WHERE Penalty > %i AND Penalty < %i ORDER BY TimestampGiven DESC", Penalty_Ban, enPenaltyType); 
	SQL_TQuery(dbLocal, SQLCB_CommList, sQuery, DP); 
}

public SQLCB_CommList(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	if(hndl == null)
		ThrowError(sError);
    
	ResetPack(DP);
	
	new UserId = ReadPackCell(DP);
	new ItemPos = ReadPackCell(DP);
	
	CloseHandle(DP);
	
	new client = GetClientOfUserId(UserId);

	if(client != 0)
	{
		if(SQL_GetRowCount(hndl) == 0)
		{
			PrintToChat(client, "There are no communication punished clients in the server");
			PrintToConsole(client, "There are no communication punished clients in the server");
		}
		new String:TempFormat[512], String:AuthId[35], String:PlayerName[64], String:PenaltyReason[256];
		
		new Handle:hMenu = CreateMenu(CommList_MenuHandler);
	
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, AuthId, sizeof(AuthId));
			SQL_FetchString(hndl, 2, PlayerName, sizeof(PlayerName));
			
			if(PlayerName[0] == EOS)
				FormatEx(PlayerName, sizeof(PlayerName), AuthId);
			
			new enPenaltyType:Penalty = enPenaltyType:SQL_FetchInt(hndl, 5);
			SQL_FetchString(hndl, 6, PenaltyReason, sizeof(PenaltyReason));
			
			new PenaltyExpiration = SQL_FetchInt(hndl, 8) - ((GetTime() - SQL_FetchInt(hndl, 7)) / 60)
			
			StripQuotes(PenaltyReason);
			Format(TempFormat, sizeof(TempFormat), "\"%s\" \"%i\" \"%i\" \"%s\"", AuthId, PenaltyExpiration, Penalty, PenaltyReason);
			AddMenuItem(hMenu, TempFormat, PlayerName);
		}
		
		DisplayMenuAtItem(hMenu, client, ItemPos, MENU_TIME_FOREVER);
	
	}
}


public CommList_MenuHandler(Handle:hMenu, MenuAction:action, client, item)
{
	if(action == MenuAction_End)
		CloseHandle(hMenu);
	
	else if(action == MenuAction_Select)
	{
		new String:AuthId[32], String:Name[64], String:Info[512], String:sPenaltyType[11], enPenaltyType:PenaltyType, String:PenaltyAlias[32], PenaltyExpiration, String:sPenaltyExpiration[64], String:ExpirationDate[64], String:PenaltyReason[256];
		
		GetMenuItem(hMenu, item, Info, sizeof(Info), _, Name, sizeof(Name));
		
		new len = BreakString(Info, AuthId, sizeof(AuthId));
		new len2 = BreakString(Info[len], sPenaltyExpiration, sizeof(sPenaltyExpiration));
		PenaltyExpiration = StringToInt(sPenaltyExpiration);
		
		new len3 = BreakString(Info[len+len2], sPenaltyType, sizeof(sPenaltyType));
		PenaltyType = enPenaltyType:StringToInt(sPenaltyType);
		
		if(len3 != -1)
			BreakString(Info[len+len2+len3], PenaltyReason, sizeof(PenaltyReason));
		
		FormatTime(ExpirationDate, sizeof(ExpirationDate), "%d/%m/%Y - %H:%M:%S", GetTime() + (60 * PenaltyExpiration));
		
		if(PenaltyExpiration <= 0)
		{
			PenaltyExpiration = 0;
			FormatEx(ExpirationDate, sizeof(ExpirationDate), "Never");
		}
		
	
		switch(PenaltyType)
		{
			case Penalty_Gag: PenaltyAlias = "Gag";
			case Penalty_Mute: PenaltyAlias = "Mute";
			case Penalty_Silence: PenaltyAlias = "Silence";
		}
	
		PrintToChat(client, "Name: %s, Steam ID: %s, Penalty Reason: %s", Name, AuthId, PenaltyReason);
		PrintToChat(client, "Penalty Type: %s, Penalty Expiration: %s ( %i minutes )", PenaltyAlias, ExpirationDate, PenaltyExpiration);
		PrintToConsole(client, "Name: %s, SteamID: %s, Penalty Type: %s, Penalty Reason: %s, Penalty Expiration: %s ( %i minutes )", Name, AuthId, PenaltyAlias, PenaltyReason, ExpirationDate, PenaltyExpiration);
		
		Command_CommList(client, 0);
	}
}

public Action:Command_BreachBans(client, args)
{
	ExpireBreach = GetGameTime() + 60.0;
	
	PrintToChatAll("Admin %N started a ban breach for testing purposes", client);
	PrintToChatAll("All banned players can join for the next 60 seconds");
	
	ReplyToCommand(client, "Don't forget to !kickbreach after the target client has entered");
	
	LogAction(client, client, "Admin %N started a 60 second ban breach", client);
	
	return Plugin_Handled;
}

public Action:Command_KickBreach(client, args)
{
	ExpireBreach = 0.0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i) || !IsClientAuthorized(i))
			continue;
			
		else if(IsFakeClient(i))
			continue;
			
		FindClientPenalties(i);
	}

	PrintToChatAll("Admin %N kicked all breaching clients", client);
	LogAction(client, client, "Kicked all ban breaching clients");
	
	return Plugin_Handled;
}
/*
public Action:Command_Backup(client, args)
{
	new String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT * FROM SQLiteBans_players");
	
	new Handle:DP = CreateDataPack();
	
	WritePackCell(DP, GetEntityUserId(client));
	WritePackCell(DP, GetCmdReplySource());
	
	SQL_TQuery(dbLocal, SQLCB_Backup, "SELECT * FROM SQLiteBans_players", DP);
}


public SQLCB_Backup(Handle:db, Handle:hndl, const String:sError[], Handle:DP)
{
	if(hndl == null)
		ThrowError(sError);
	
	else if(SQL_GetRowCount(hndl) == 0)
	{
		ResetPack(DP);
		
		new client = GetEntityOfUserId(ReadPackCell(DP));
		new ReplySource:CmdReplySource = ReadPackCell(DP);
		
		CloseHandle(DP);
		
		ReplyToCommandBySource(client, CmdReplySource, "There are no bans or comm punishments to backup.");
		
		return;
	}
	
	while(SQL_FetchRow(hndl))
	{
		for(new i=0;i < SQL_GetFieldCount(hndl);i++)
		{
			new Type = 0; // 0 = Int, 1 = Float, 2 = String.
		}
	}
}
*/
stock KickBannedClient(client, BanDuration, const String:BanReason[], TimestampGiven)
{
	new String:KickReason[256];
	if(BanReason[0] == EOS)
		KickReason = "No reason specified";
		
	else
		FormatEx(KickReason, sizeof(KickReason), BanReason);
		
	new String:Website[128];
	GetConVarString(hcv_Website, Website, sizeof(Website));
	
	if(BanDuration == 0)
		KickClient(client, "You have been permanently banned from this server.\nReason: %s\n\nCheck %s for more info", KickReason, Website);
		
	else
		KickClient(client, "You have been banned from this server for %i minutes.\nReason: %s\n\nCheck %s for more info.\nYour ban will expire in %i minutes", BanDuration, BanReason, Website, BanDuration - ((GetTime() - TimestampGiven) / 60));
}

stock bool:IsClientChatGagged(client, &Expire=0, &bool:permanent=false, &bool:silenced=false)
{
	silenced = false;
	permanent = false;
	Expire = 0;
	
	new UnixTime = GetTime();
	
	if(ExpirePenalty[client][Penalty_Silence] > UnixTime)
	{
		silenced = true;
		Expire = ExpirePenalty[client][Penalty_Silence];
		return true;
	}
	else if(ExpirePenalty[client][Penalty_Silence] == -1)
	{
		silenced = true;
		permanent = true;
		Expire = ExpirePenalty[client][Penalty_Silence];
		return true;
	}
	
	if(ExpirePenalty[client][Penalty_Gag] > UnixTime)
	{
		Expire = ExpirePenalty[client][Penalty_Gag];
		return true;
	}
	else if(ExpirePenalty[client][Penalty_Gag] == -1)
	{
		permanent = true;
		Expire = ExpirePenalty[client][Penalty_Gag];
		return true;
	}
	
	return false;
}
stock bool:IsClientVoiceMuted(client, &Expire=0, &bool:permanent=false, &bool:silenced=false)
{
	silenced = false;
	permanent = false;
	Expire = 0;
	
	new UnixTime = GetTime();
	
	if(ExpirePenalty[client][Penalty_Silence] > UnixTime)
	{
		silenced = true;
		Expire = ExpirePenalty[client][Penalty_Silence];
		return true;
	}
	else if(ExpirePenalty[client][Penalty_Silence] == -1)
	{
		silenced = true;
		permanent = true;
		Expire = ExpirePenalty[client][Penalty_Silence];
		return true;
	}
	
	if(ExpirePenalty[client][Penalty_Mute] > UnixTime)
	{
		Expire = ExpirePenalty[client][Penalty_Mute];
		return true;
	}
	else if(ExpirePenalty[client][Penalty_Mute] == -1)
	{
		permanent = true;
		Expire = ExpirePenalty[client][Penalty_Mute];
		return true;
	}
	
	return false;
}

stock bool:CanClientBanTarget(client, target)
{
	if(client == 0)
		return true;
		
	else if(CheckCommandAccess(client, "sm_rcon", ADMFLAG_RCON))
		return true;
	
	return CanUserTarget(client, target);
}

// Like GetClientUserId but client index 0 will return 0.
stock GetEntityUserId(entity)
{
	if(entity == 0)
		return 0;
		
	return GetClientUserId(entity);
}

stock GetEntityOfUserId(UserId)
{
	if(UserId == 0)
		return 0;
		
	return GetClientOfUserId(UserId);
}

stock ReplyToCommandBySource(client, ReplySource:CmdReplySource, const String:format[], any:...)
{
	if(client == 0)
		CmdReplySource = SM_REPLY_TO_CONSOLE;
		
	new String:buffer[512];
	
	VFormat(buffer, sizeof(buffer), format, 4);
	
	new ReplySource:PrevReplySource = GetCmdReplySource();
	
	SetCmdReplySource(CmdReplySource);
	
	ReplyToCommand(client, buffer);
	
	SetCmdReplySource(PrevReplySource);
}

stock LogSQLiteBans(const String:format[], any:...)
{
	new String:FilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "logs/SQLiteBans.log");

	new String:buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	if(GetConVarBool(hcv_LogMethod))
		LogToFile(FilePath, buffer);
		
	else
		LogMessage(buffer);
}

stock LogSQLiteBans_BannedConnect(const String:format[], any:...)
{
	new String:FilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, FilePath, sizeof(FilePath), "logs/SQLiteBans-BannedConnect.log");

	new String:buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	if(GetConVarBool(hcv_LogMethod))
		LogToFile(FilePath, buffer);
		
	else
		LogMessage(buffer);
}

stock PositiveOrZero(value)
{
	if(value < 0)
		return 0;
		
	return value;
}