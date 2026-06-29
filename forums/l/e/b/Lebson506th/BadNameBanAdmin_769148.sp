#include <sourcemod>


new String:badNames[255][64];
new String:fileName[PLATFORM_MAX_PATH];
new String:logFileName[PLATFORM_MAX_PATH];
new lines;
new Handle:bnb_bantime;
new Handle:bnb_reason;
new Handle:bnb_log;
new bool:EventsHooked = false


#define PLUGIN_VERSION "1.60"

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
	bnb_log = CreateConVar("sm_bnb_log", "1", "Whether or not to log bnb kicks to an external file")
	CreateConVar("sm_bnb_version", PLUGIN_VERSION, "Bad name banning version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	decl String:ctime[64]
	FormatTime(ctime, 64, "logs/bnb_log_%m%d%Y.log");
	BuildPath(Path_SM, logFileName, sizeof(logFileName), ctime);
}

public OnMapStart(){
	for(new i; i < lines; i++){
		badNames[i] = ""
	}
	lines = 0
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
	
	CloseHandle(file);
	return true;
}

public OnClientPostAdminCheck(client){
	new String:playerName[64]
	if(!GetClientName(client,playerName,64)){
		return;
	}
	nameCheck(playerName,client);
}

nameCheck(String:clientName[64], player){
	new playerId = GetClientUserId(player);
	
	new AdminId:playerAdmin = GetUserAdmin(player);
	if(GetAdminFlag(playerAdmin, Admin_Generic, Access_Effective)){
		return;
	}
	
	//Trim the spaces out
	ReplaceString(clientName, 64, " ", "")
	
	//Check if they have a bad phrase in their name
	for(new i = 0; i < lines; i++){
		if(StrContains(clientName, badNames[i], false) != -1){
			//Ban/kick the player
			new bantime = GetConVarInt(bnb_bantime)
			if(bantime != -1){
				ServerCommand("banid %i %i", bantime, playerId)
			}
			new String:reason[64]
			GetConVarString(bnb_reason,reason,64)
			ServerCommand("kickid %i %s", playerId, reason)
			
			//Write to log if desired
			if(GetConVarInt(bnb_log) == 1){
				GetClientName(player,clientName,64)
				LogToFile(logFileName, "%s was kicked/banned for having %s in his name", clientName, badNames[i])
			}
		}	
	}
	return;

}
 

public Action:checkName(Handle:event, const String:name[], bool:dontBroadcast){
	new String:playerName[64];
	GetEventString(event, "newname", playerName, 64)
	nameCheck(playerName, GetClientOfUserId(GetEventInt(event, "userid")));
}
 