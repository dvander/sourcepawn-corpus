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
 * 1.0.5
 * - Added Connect extension support.
 * ==================================================================================
 */

#include <sourcemod>
//#include <cbaseserver>
#include <connect>
#include <sdktools>
#define PLUGIN_VERSION "1.0.5"

new TEAM1;
new TEAM2;
new SPEC;

new bool:g_HighImmunityPlayers[MAXPLAYERS+1];
new bool:b_lateLoad;

new g_HIPCount;

new Handle:cvar_KickType;
new Handle:cvar_Spec;
new Handle:cvar_Logging;
new Handle:cvar_Immunity;
new Handle:cvar_KickReasonImmunity;
new Handle:cvar_KickReason;
new Handle:cvar_HighImmunityLimit;
new Handle:cvar_HighImmunityValue;
new Handle:cvar_KeepBalance;

new String:LogFilePath[PLATFORM_MAX_PATH];

public Plugin:myinfo = 
{
	name = "Immunity Reserve Slots",
	author = "Jamster",
	description = "Immunity based reserve slots for the CBaseServer Tools extension",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("immunityreserveslots.phrases");
	decl String:desc[255];
	
	Format(desc, sizeof(desc), "%t", "irs_version");
	CreateConVar("sm_irs_version", PLUGIN_VERSION, desc, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Format(desc, sizeof(desc), "%t", "irs_kicktype");
	cvar_KickType = CreateConVar("sm_irs_kicktype", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 3.0);
	
	Format(desc, sizeof(desc), "%t", "irs_kickreason");
	cvar_KickReason = CreateConVar("sm_irs_kickreason", "default", desc, FCVAR_PLUGIN);
	
	Format(desc, sizeof(desc), "%t", "irs_kickreason_immunity");
	cvar_KickReasonImmunity = CreateConVar("sm_irs_kickreason_immunity", "default", desc, FCVAR_PLUGIN);
	
	Format(desc, sizeof(desc), "%t", "irs_log");
	cvar_Logging = CreateConVar("sm_irs_log", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	Format(desc, sizeof(desc), "%t", "irs_immunity");
	cvar_Immunity = CreateConVar("sm_irs_immunity", "1", desc, FCVAR_PLUGIN, true, 0.0, true, 2.0);
	
	Format(desc, sizeof(desc), "%t", "irs_kickspecfirst");
	cvar_Spec = CreateConVar("sm_irs_kickspecfirst", "1", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "irs_highimmunitylimit");
	cvar_HighImmunityLimit = CreateConVar("sm_irs_highimmunitylimit", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "irs_highimmunityvalue");
	cvar_HighImmunityValue = CreateConVar("sm_irs_highimmunityvalue", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "irs_keepbalance");
	cvar_KeepBalance = CreateConVar("sm_irs_keepbalance", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "plugin.immunityreserveslots");
}

public OnAllPluginsLoaded()
{
	new Handle:Plugin;
	decl String:plugin1[32] = {"cbaseservertest.smx"};
	decl String:plugin2[32] = {"cbsext_reserves.smx"};
	decl String:plugin3[32] = {"reservedslots.smx"};
	
	Plugin = FindPluginByFile(plugin1);
	if (Plugin != INVALID_HANDLE)
	{
		CloseHandle(Plugin);
		LogError("%t", "IRS Plugin Error", plugin1);
		IRS_RemovePlugin(plugin1);
	}
	
	Plugin = FindPluginByFile(plugin2);
	if (Plugin != INVALID_HANDLE)
	{
		CloseHandle(Plugin);
		LogError("%t", "IRS Plugin Error", plugin2);
		IRS_RemovePlugin(plugin2);
	}
	
	Plugin = FindPluginByFile(plugin3);
	if (Plugin != INVALID_HANDLE)
	{
		CloseHandle(Plugin);
		LogError("%t", "IRS Plugin Error", plugin3);
		IRS_RemovePlugin(plugin3);
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
		CreateDirectory(dir, FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC);
	
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
				OnClientPostAdminCheck(i);
		}
		b_lateLoad = false;
	}
}

public bool:OnClientPreConnect(const String:name[], String:password[255], const String:ip[], const String:steamID[], String:rejectReason[255])
{
	if (GetClientCount(false) < MaxClients)
		return false;	
	
	new AdminId:AdminID = FindAdminByIdentity(AUTHMETHOD_STEAM, steamID);
	
	if (GetAdminFlag(AdminID, Admin_Reservation))
		IRS_KickValidClient(AdminID, name, steamID, GetAdminImmunityLevel(AdminID));
	return true;
}

IRS_LogClient(const client, const team, const immunity, const Float:value = -1.0)
{
	decl String:TeamName[32];
	GetTeamName(team, TeamName, sizeof(TeamName));
	if (value == -1.0)
	{
		if (IsClientInGame(client))
			LogToFileEx(LogFilePath, "%02d: \"%N\" [i: %02d] (%s)", client, client, immunity, TeamName);
		else
			LogToFileEx(LogFilePath, "%02d: \"%N\" [i: %02d] (Connecting)", client, client, immunity);
	}
	else
	{
		if (IsClientInGame(client))
			LogToFileEx(LogFilePath, "%02d: \"%N\" [i: %02d] [v: %f] (%s)", client, client, immunity, value, TeamName);
		else
			LogToFileEx(LogFilePath, "%02d: \"%N\" [i: %02d] (Connecting)", client, client, immunity);
	}
}

IRS_KickValidClient(const AdminId:ConnectingClientAdminID, const String:ConnectingClientName[], const String:ConnectingClientAuthID[], const ConnectingClientImmunity)
{
	decl String:Time[32];
	FormatTime(Time, sizeof(Time), "%Y%m%d");
	BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/irslogs_%s.log", Time);

	new KickType = GetConVarInt(cvar_KickType);
	new Logging = GetConVarInt(cvar_Logging);	
	new Immunity = GetConVarInt(cvar_Immunity);
	new SpecKick = GetConVarInt(cvar_Spec);
		
	new bool:useKeepBalance;
	new bool:immunityKick;
	
	new LowestImmunityLevel = 100;
	new ClientImmunity[MAXPLAYERS+1];
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
		LogToFileEx(LogFilePath, "-- Beginning Check --");
	
	if (GetConVarInt(cvar_KeepBalance))
	{
		useKeepBalance = true;
		countTEAM1 = GetTeamClientCount(TEAM1);
		countTEAM2 = GetTeamClientCount(TEAM2);
		if (countTEAM1 == countTEAM2)
			useKeepBalance = false;
		else if (countTEAM1 > countTEAM2)
			useTeam = TEAM1;
		else
			useTeam = TEAM2;
		if (Logging == 1)
		{
			if (useKeepBalance)
			{
				decl String:TeamName[32];
				GetTeamName(useTeam, TeamName, sizeof(TeamName));
				LogToFileEx(LogFilePath, "Balance check: Team \"%s\" has the most players (%02d | %02d)", TeamName, countTEAM1, countTEAM2);
			}
			else
			{
				LogToFileEx(LogFilePath, "Balance check: Teams are the same size");
			}
		}
	}	
		
	for (new i=1; i<=MaxClients; i++)
	{	
		if (!IsClientConnected(i))
		{
			if (Logging == 1)
				LogToFileEx(LogFilePath, "%02d: NOT CONNECTED", i);
			continue;
		}
			
		if (IsFakeClient(i))
		{
			if (Logging == 1)
				LogToFileEx(LogFilePath, "%02d: BOT", i);
			continue;
		}
		
		if (IsClientInGame(i))
			clientTeam[i] = GetClientTeam(i);
			
		new String:PlayerAuth[32];
		GetClientAuthString(i, PlayerAuth, sizeof(PlayerAuth));
		new AdminId:PlayerAdmin = FindAdminByIdentity(AUTHMETHOD_STEAM, PlayerAuth)
		ClientImmunity[i] = GetAdminImmunityLevel(PlayerAdmin);
		
		// Removed the check for root as it seems this doesn't matter any more in modern SM versions (1.3+).
		if (GetAdminFlag(PlayerAdmin, Admin_Reservation) || CheckCommandAccess(i, "sm_reskick_immunity", ADMFLAG_RESERVATION))
		{
			if (Immunity && ClientImmunity[i] < LowestImmunityLevel)
				LowestImmunityLevel = ClientImmunity[i];
			if (Logging == 1)
				IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
			continue;
		}
		
		if (Immunity == 2 && ClientImmunity[i] > 0)
		{
			if (Logging == 1)
				IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
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
				HighestValue = value;
			
			if (clientTeam[i] == SPEC || clientTeam[i] == 0 && SpecKick)
			{							
				if (KickType == 3 && !HighestSpecValue)
					HighestSpecValue = value;
				
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
					HighestBalanceValue = value;
				
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
			IRS_LogClient(i, clientTeam[i], ClientImmunity[i], value);
	}	
		
	if (Logging == 1)
	{
		decl String:ConnectingClientAdminName[32];
		GetAdminUsername(ConnectingClientAdminID, ConnectingClientAdminName, sizeof(ConnectingClientAdminName));
		LogToFileEx(LogFilePath, "Connecting player \"%s\" (cfg: \"%s\") [%02d]", ConnectingClientName, ConnectingClientAdminName, ConnectingClientImmunity);
		LogToFileEx(LogFilePath, "Lowest immunity: %02d", LowestImmunityLevel);
		LogToFileEx(LogFilePath, "High immunity player count: %d", g_HIPCount);
		LogToFileEx(LogFilePath, "Max player count: %d", MaxClients);
	}
	
	// Makes sense than calculating immune players above, man I was a scrub coder...
	// Then again I would like to see if I could make a method without running a new for loop again too.
	if (Immunity && !HighestValueId && !HighestSpecValueId)
	{			
		if (Logging == 1)
			LogToFileEx(LogFilePath, "All players immune, running extra immunity check");
		
		immunityKick = true;
		
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientConnected(i))
			{
				if (Logging == 1)
					LogToFileEx(LogFilePath, "%02d: NOT CONNECTED", i);
				continue;
			}
				
			if (IsFakeClient(i))
			{
				if (Logging == 1)
					LogToFileEx(LogFilePath, "%02d: BOT", i);
				continue;
			}
			
			if (ClientImmunity[i] > LowestImmunityLevel)
			{
				if (Logging == 1)
					IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
				continue;
			}
				
			if (ClientImmunity[i] >= ConnectingClientImmunity)
			{
				if (Logging == 1)
					IRS_LogClient(i, clientTeam[i], ClientImmunity[i]);
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
					HighestValue = value;
				
				if (clientTeam[i] == SPEC || clientTeam[i] == 0 && SpecKick)
				{							
					if (KickType == 3 && !HighestSpecValue)
						HighestSpecValue = value;
					
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
						HighestBalanceValue = value;
					
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
				IRS_LogClient(i, clientTeam[i], ClientImmunity[i], value);
		}
	}	

	new KickTarget;
	
	if (HighestSpecValueId)
		KickTarget = HighestSpecValueId;
	else if (HighestBalanceValueId)
		KickTarget = HighestBalanceValueId;
	else
		KickTarget = HighestValueId;
							
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
				Format(Reason, sizeof(Reason), "%t", "IRS Kick Reason");
			KickClientEx(KickTarget, "%s", Reason);
			if (Logging == 1)
				LogToFileEx(LogFilePath, "\"%s\" was kicked", KickName);
			if (Logging == 2)
				LogMessage("%t", "IRS Kick Log", ConnectingClientName, ConnectingClientAuthID, KickName, KickAuthid);
		}
		else
		{
			new HighImmunityLimit = GetConVarInt(cvar_HighImmunityLimit);
			if (HighImmunityLimit && g_HIPCount >= HighImmunityLimit)
			{
				if (Logging == 1)
					LogToFileEx(LogFilePath, "Too many high immunity players connected (%d players)", g_HIPCount);
				return;
			}
			decl String:Reason[255];
			GetConVarString(cvar_KickReasonImmunity, Reason, sizeof(Reason));
			if (StrEqual(Reason, "default", false))
				Format(Reason, sizeof(Reason), "%t", "IRS Kick Reason Immunity");
			KickClientEx(KickTarget, "%s", Reason);
			if (Logging == 1)
				LogToFileEx(LogFilePath, "\"%s\" was kicked (Low immunity)", KickName);
			if (Logging == 2)
				LogMessage("%t", "IRS Kick Log", ConnectingClientName, ConnectingClientAuthID, KickName, KickAuthid)
		}
	} 
	else 
	{
		if (Logging == 1)
			LogToFileEx(LogFilePath, "No valid client found to kick");
		return;
	}
}

public OnClientPostAdminCheck(client)
{
	// I do this here as it makes sure the client is actually properly connected, I don't want to add anyone too early.
	if (IsFakeClient(client))
		return;
		
	new HighImmunityValue = GetConVarInt(cvar_HighImmunityValue);
	if (GetConVarInt(cvar_HighImmunityLimit) && HighImmunityValue && GetAdminImmunityLevel(GetUserAdmin(client)) >= HighImmunityValue)
	{
		g_HighImmunityPlayers[client] = true;
		g_HIPCount++;
	}
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
		return;
		
	if (!GetConVarInt(cvar_HighImmunityLimit))
		return;
		
	if (g_HighImmunityPlayers[client])
	{
		g_HighImmunityPlayers[client] = false;
		g_HIPCount--;
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if (late)
		b_lateLoad = true
	
	// I think insurgency is the only game that has different team indexes.
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
	
	return APLRes_Success;
}