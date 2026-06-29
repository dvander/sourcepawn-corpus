#include <sourcemod>

new String:badNames[255][64];
new String:fileName[PLATFORM_MAX_PATH];
new String:logFileName[PLATFORM_MAX_PATH];
new String:goodSteams[255][32];
new lines, adminLines;
new Handle:bnb_bantime;
new Handle:bnb_allowimmun;
new Handle:bnb_reason;
new Handle:bnb_log;
new bool:EventsHooked = false

#define PLUGIN_VERSION "1.70"

public Plugin:myinfo = {
	name = "Bad name ban",
	author = "vIr-Dan modified by Lebson506th",
	description = "Kicks/bans anybody with a bad phrase in their name",
	version = PLUGIN_VERSION,
	url = "http://dansbasement.us/"
};

public OnPluginStart() {
	bnb_reason = CreateConVar("sm_bnb_reason", "Bad name", "Reason to give client when they are kicked/banned")
	bnb_bantime = CreateConVar("sm_bnb_bantime", "-1", "How long to ban someone with a bad phrase in their name (0 = perm, -1 = kick)");
	bnb_allowimmun = CreateConVar("sm_bnb_allow_immun", "1", "Whether or not to allow bnb immunity via bnb_whitelist.ini")
	bnb_log = CreateConVar("sm_bnb_log", "1", "Whether or not to log just bnb kicks (1) or all activity (2) to an external file. 0 to disable")
	CreateConVar("sm_bnb_version", PLUGIN_VERSION, "Bad name banning version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
}

public OnMapStart() {
	decl String:ctime[64]
	FormatTime(ctime, 64, "logs/bnb_log_%m%d%Y.log");
	BuildPath(Path_SM, logFileName, sizeof(logFileName), ctime);

	for(new i; i < lines; i++)
		badNames[i] = ""
	for(new i; i < adminLines; i++)
		goodSteams[i] = ""

	lines = 0
	adminLines = 0

	//If there is something wrong with the config, don't do anything until next map
	if(ReadConfig() && !EventsHooked ) {
		//Hook events
		HookEvent("player_activate", checkName)
		HookEvent("player_changename", checkName)
		EventsHooked = true
	}
}

public bool:ReadConfig() {
	BuildPath(Path_SM, fileName, sizeof(fileName), "configs/bad_names.ini");
	new Handle:file = OpenFile(fileName, "rt");

	if (file == INVALID_HANDLE) {
		if(GetConVarBool(bnb_log))
			LogToFile(logFileName, "Could not open bad name config file: %s", fileName);

		return false;
	}

	while (!IsEndOfFile(file)) {
		decl String:line[64]

		if (!ReadFileLine(file, line, sizeof(line)))
			break;

		TrimString(line)
		ReplaceString(line, 64, " ", "")

		if (strlen(line) == 0 || (line[0] == '/' && line[1] == '/'))
			continue;

		//Add the line to the list of badNames
		strcopy(badNames[lines], sizeof(badNames[]), line)
		lines++
		
	}

	if(GetConVarInt(bnb_log) == 2)
		LogToFile(logFileName, "Bad name config read, %i lines total", lines)

	if(GetConVarBool(bnb_allowimmun))
		return ReadAdminConfig();

	CloseHandle(file);
	return true;
}

public bool:ReadAdminConfig() {
	BuildPath(Path_SM, fileName, sizeof(fileName), "configs/bnb_whitelist.ini");
	new Handle:file = OpenFile(fileName, "rt");

	if (file == INVALID_HANDLE) {
		if(GetConVarBool(bnb_log))
			LogToFile(logFileName, "Could not open bnb whitelist config file: %s", fileName);

		return false;
	}

	while (!IsEndOfFile(file)) {
		decl String:line[64]

		if (!ReadFileLine(file, line, sizeof(line)))
			break;

		TrimString(line)

		if (strlen(line) == 0 || (line[0] == '/' && line[1] == '/'))
			continue;

		//Add the line to the list of badNames

		LogToFile(logFileName, "Line %i: %s",adminLines,line)
		strcopy(goodSteams[adminLines], sizeof(goodSteams[]), line)
		adminLines++
	}

	if(GetConVarInt(bnb_log) == 2)
		LogToFile(logFileName, "Bnb whitelist config read, %i lines total", adminLines)

	CloseHandle(file)
	return true;
}

public Action:checkName(Handle:event, const String:name[], bool:dontBroadcast) {
	new playerId = GetEventInt(event, "userid")
	new player = GetClientOfUserId(playerId)

	//Make sure immunity is even allowed
	if(GetConVarInt(bnb_allowimmun)==1) {
		//Check to make sure they are not an admin
		decl String:steamID[32]
		GetClientAuthString(player,steamID,32)

		for(new i; i<adminLines;i++) {
			//They are in the whitelist, so don't bother checking
			if(strcmp(steamID,goodSteams[i],true)==0)
				return Plugin_Continue
		}
	}

	new String:clientName[64]
	//Check whether they changed their name or are connecting

	if(strcmp(name,"player_changename")==0)
		GetEventString(event, "newname", clientName, 64)
	else {
		if(!GetClientName(player,clientName,64))
			return Plugin_Continue
	}

	//Trim the spaces out
	ReplaceString(clientName, 64, " ", "")

	new bantime = GetConVarInt(bnb_bantime)
	new String:reason[64]
	GetConVarString(bnb_reason,reason,64)
	
	//Check if they have a bad phrase in their name
	for(new i = 0; i < lines; i++) {
		if(StrContains(clientName, badNames[i], false) != -1) {
			//Ban/kick the player
			if(bantime != -1)
				ServerCommand("sm_ban #%i %i \"%s\"", playerId, bantime, reason);
			else
				ServerCommand("kickid %i %s", playerId, reason)

			//Write to log if desired
			if(GetConVarBool(bnb_log)) {
				GetClientName(player,clientName,64)
				LogToFile(logFileName, "%s was kicked/banned for having %s in his name", clientName, badNames[i])
			}
		}	
	}

	return Plugin_Continue
}