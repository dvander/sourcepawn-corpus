#include <sourcemod>


new String:badNames[255][64];
new String:goodSteams[255][32];
new String:fileName[PLATFORM_MAX_PATH];
new lines, adminLines;
new Handle:bnb_bantime;
new Handle:bnb_whitelist;
new Handle:bnb_adminflag;
new Handle:bnb_reason;
new Handle:bnb_log;
new Handle:logFile;
new bool:EventsHooked = false


#define PLUGIN_VERSION "2.00"

public Plugin:myinfo = {
	name = "Bad name ban",
	author = "vIr-Dan",
	description = "Kicks/bans anybody with a bad phrase in their name",
	version = PLUGIN_VERSION,
	url = "http://dansbasement.us/"
};

public OnPluginStart()
{
	bnb_reason = CreateConVar("sm_bnb_reason", "Bad name", "Reason to give client when they are kicked/banned")
	bnb_bantime = CreateConVar("sm_bnb_bantime", "-1", "How long to ban someone with a bad phrase in their name (0 = perm, -1 = kick)");
	bnb_whitelist = CreateConVar("sm_bnb_whitelist", "1", "Allow bnb immunity via whitelist (1-yes, 0-no)");
	bnb_adminflag = CreateConVar("sm_bnb_adminflag", "1", "Allow bnb immunity via admin flags (1-yes, 0-no)");
	bnb_log = CreateConVar("sm_bnb_log", "1", "Whether or not to log bnb kicks to an external file")
	CreateConVar("sm_bnb_version", PLUGIN_VERSION, "Bad name banning version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	
}

public OnMapStart(){
	for(new i; i < lines; i++){
		badNames[i] = ""
	}
	
	for(new i; i < adminLines; i++){
		goodSteams[i] = ""
	}
	lines = 0
	adminLines = 0
	//If there is something wrong with the config, don't do anything until next map
	if(ReadConfig() && !EventsHooked ){
		//Hook events
		HookEvent("player_changename", checkName)
		EventsHooked = true
	}
}

public bool:ReadConfig()
{
	BuildPath(Path_SM, fileName, sizeof(fileName), "configs/bad_names.ini");
	new Handle:file = OpenFile(fileName, "rt");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open bad name config file: %s", fileName);
		return false;
	}

	while (!IsEndOfFile(file))
	{
		decl String:line[64]
		if (!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}
		
		TrimString(line)
		ReplaceString(line, 64, " ", "")
		if (strlen(line) == 0 || (line[0] == '/' && line[1] == '/'))
		{
			continue;
		}
		
		//Add the line to the list of badNames
		strcopy(badNames[lines], sizeof(badNames[]), line)
		lines++
		
	}
	LogMessage("Bad name config read, %i lines total", lines)
	if(GetConVarInt(bnb_whitelist)){
		return ReadAdminConfig();
	}
	CloseHandle(file);
	return true;
}

public bool:ReadAdminConfig()
{
	BuildPath(Path_SM, fileName, sizeof(fileName), "configs/bnb_whitelist.ini");
	new Handle:file = OpenFile(fileName, "rt");
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open bnb whitelist config file: %s", fileName);
		return false;
	}

	while (!IsEndOfFile(file))
	{
		decl String:line[64]
		if (!ReadFileLine(file, line, sizeof(line)))
		{
			break;
		}
		
		TrimString(line)
		if (strlen(line) == 0 || (line[0] == '/' && line[1] == '/'))
		{
			continue;
		}
		
		//Add the line to the list of badNames
		LogMessage("Line %i: %s",adminLines,line)
		strcopy(goodSteams[adminLines], sizeof(goodSteams[]), line)
		adminLines++
		
	}
	LogMessage("Bnb whitelist config read, %i lines total", adminLines)
	CloseHandle(file)
	return true;
}

public OnClientPostAdminCheck(client){
	new String:playerName[64]
	if(!GetClientName(client,playerName,64)){
		return;
	}
	
	nameCheck(playerName,GetClientUserId(client));
}
 
public Action:checkName(Handle:event, const String:name[], bool:dontBroadcast){
	new clientId = GetEventInt(event, "userid")
	new String:clientName[64]
	//Check whether they changed their name or are connecting
	if(strcmp(name,"player_changename")==0){
		GetEventString(event, "newname", clientName, 64)
	}else{
		if(!GetClientName(GetClientOfUserId(clientId),clientName,64)){
			return Plugin_Continue
		}
	}
	nameCheck(clientName, clientId);
	return Plugin_Handled;
}

public nameCheck(String:clientName[64], playerId){
	new player = GetClientOfUserId(playerId);
	if(!player){
		return;
	}
	
	//Is admin immunity allowed? If yes, are they an admin?
	new AdminId:playerAdmin = GetUserAdmin(player);
	if(GetConVarInt(bnb_adminflag) && GetAdminFlag(playerAdmin, Admin_Generic, Access_Effective)){
		return;
	}
	
	decl String:steamID[32]
	GetClientAuthString(player,steamID,32)
	//Is whitelist immunity allowed?  If yes, are they in it?
	if(GetConVarInt(bnb_whitelist)){
		//Check to make sure they are not an admin
		for(new i; i<adminLines;i++){
			//They are in the whitelist, so don't bother checking
			if(strcmp(steamID,goodSteams[i],true)==0){
				return;
			}
		}
	}
	
	//Trim the spaces out
	ReplaceString(clientName, 64, " ", "")
	
	//Check if they have a bad phrase in their name
	for(new i = 0; i < lines; i++){
		if(StrContains(clientName, badNames[i], false) != -1){
			//Ban/kick the player
			new bantime = GetConVarInt(bnb_bantime)
			new String:reason[64]
			GetConVarString(bnb_reason,reason,64)
			if(bantime != -1){
				ServerCommand("sm_ban #%i %i \"%s\"", playerId, bantime, reason)
			}else{			
				ServerCommand("sm_kick #%i %s", playerId, reason)
			}
			
			//Write to log if desired
			if(GetConVarInt(bnb_log) == 1){
				decl String:ctime[64]
				FormatTime(ctime, 64, "logs/bnb_log_%m%d%Y.log");
				new String:logFileName[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, logFileName, sizeof(logFileName), ctime);
				logFile = OpenFile(logFileName, "a+t");
				if (logFile == INVALID_HANDLE)
				{
					LogError("Could not open log file: %s", logFileName);
				}
				WriteFileLine(logFile, "%s(%s) was kicked/banned for having %s in his name", clientName, steamID, badNames[i])
				CloseHandle(logFile);
			}
			break;
		}	
	}
}
 