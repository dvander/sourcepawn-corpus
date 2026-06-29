#include <sourcemod>
#include <sdktools>
#include <geoip.inc>
#include <string.inc>

#define PLUGIN_VERSION "SaveChat_Ver_3.0"

static String:chatFile[128]
new Handle:fileHandle       = INVALID_HANDLE
new Handle:sc_record_detail = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "SaveChat",
	author = "citkabuto + ETHORBIT + Sunyata",
	description = "Records player chat messages to a file",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=117116"
}

public OnPluginStart()
{
	new String:date[21]
	new String:logFile[100]

	/* Register CVars */
	CreateConVar("sm_savechat_version", PLUGIN_VERSION, "Save Player Chat Messages Plugin", 
		FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED)

	sc_record_detail = CreateConVar("sc_record_detail", "1", 
		"Record player Steam ID and IP address",
		FCVAR_PLUGIN)

	/* Say commands */
	RegConsoleCmd("say", Command_Say)
	RegConsoleCmd("say_team", Command_SayTeam)

	/* Format date for log filename */
	FormatTime(date, sizeof(date), "%d%m%y", -1)

	/* Create name of logfile to use */
	Format(logFile, sizeof(logFile), "/logs/chat%s.log", date)
	BuildPath(Path_SM, chatFile, PLATFORM_MAX_PATH, logFile)
}

/*
 * Capture player chat and record to file
 */
public Action:Command_Say(client, args)
{
	LogChat(client, args, false)
	return Plugin_Continue
}

/*
 * Capture player team chat and record to file
 */
public Action:Command_SayTeam(client, args)
{
	LogChat(client, args, true)
	return Plugin_Continue
}

public OnClientPostAdminCheck(client)
{
	/* Only record player detail if CVAR set */
	if(GetConVarInt(sc_record_detail) != 1)
		return

	if(IsFakeClient(client)) 
		return

	new String:msg[2048]
	new String:time[21]
	new String:country[3]
	new String:steamID[128]
	new String:playerIP[50]
	
	GetClientAuthString(client, steamID, sizeof(steamID))

	/* Get 2 digit country code for current player */
	if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
		country   = "  "
	} else {
		if(GeoipCode2(playerIP, country) == false) {
			country = "  "
		}
	}

	FormatTime(time, sizeof(time), "%H:%M:%S", -1)
	Format(msg, sizeof(msg), "[%s] [%s] %-35N has joined (%s | %s)",
		time,
		country,
		client,
		steamID,
		playerIP)

	SaveMessage(msg)
}

/*
 * Extract all relevant information and format 
 */
public LogChat(client, args, bool:teamchat)
{
	new String:msg[2048]
	new String:time[21]
	new String:text[1024]
	new String:country[3]
	new String:playerIP[50]
	new String:teamName[20]

	GetCmdArgString(text, sizeof(text))
	StripQuotes(text)

	if(client == 0) {
		/* Don't try and obtain client country/team if this is a console message */
		Format(country, sizeof(country), "  ")
		Format(teamName, sizeof(teamName), "")
	} else {
		/* Get 2 digit country code for current player */
		if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
			country   = "  "
		} else {
			if(GeoipCode2(playerIP, country) == false) {
				country = "  "
			}
		}
		GetTeamName(GetClientTeam(client), teamName, sizeof(teamName))
	}
	FormatTime(time, sizeof(time), "%H:%M:%S", -1)

	if(GetConVarInt(sc_record_detail) == 1) {
		Format(msg, sizeof(msg), "[%s] [%s] [%-11s] %-35N :%s %s",
			time,
			country,
			teamName,
			client,
			teamchat == true ? " (TEAM)" : "",
			text)
	} else {
		Format(msg, sizeof(msg), "[%s] [%s] %-35N :%s %s",
			time,
			country,
			client,
			teamchat == true ? " (TEAM)" : "",
			text)
	}

	SaveMessage(msg)
}

public OnClientDisconnect(client)
{
	new String:msg[2048]
	new String:time[21]
	new String:country[3]
	new String:steamID[128]
	new String:playerIP[50]

	/* Only record player detail if CVAR set */
	if(GetConVarInt(sc_record_detail) != 1)
		return

	if(IsFakeClient(client)) 
		return
		
	GetClientAuthString(client, steamID, sizeof(steamID))
	
	/* Get 2 digit country code for current player */
	if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
		country   = "  "
	} else {
		if(GeoipCode2(playerIP, country) == false) {
			country = "  "
		}
	}
	
	FormatTime(time, sizeof(time), "%H:%M:%S", -1)
	Format(msg, sizeof(msg), "[%s] [%s] %-35N has disconnected (%s | %s)",
		time,
		country,
		client,
		steamID,
		playerIP)

	SaveMessage(msg)
}
/*
 * Log a map transition
 */
public OnMapStart(){
	new String:map[128]
	new String:msg[1024]
	new String:date[21]
	new String:time[21]
	new String:logFile[100]

	GetCurrentMap(map, sizeof(map))

	/* The date may have rolled over, so update the logfile name here */
	FormatTime(date, sizeof(date), "%d%m%y", -1)
	Format(logFile, sizeof(logFile), "/logs/chat%s.log", date)
	BuildPath(Path_SM, chatFile, PLATFORM_MAX_PATH, logFile)

	FormatTime(time, sizeof(time), "%d/%m/%Y %H:%M:%S", -1)
	Format(msg, sizeof(msg), "[%s] --- NEW MAP STARTED: %s ---", time, map)

	SaveMessage("--=================================================================--")
	SaveMessage(msg)
	SaveMessage("--=================================================================--")
}

/*
 * Log the message to file
 */
public SaveMessage(const String:message[])
{
	fileHandle = OpenFile(chatFile, "a")  /* Append */
	WriteFileLine(fileHandle, message)
	CloseHandle(fileHandle)
}

