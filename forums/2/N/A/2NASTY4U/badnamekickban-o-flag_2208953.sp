#include <sourcemod>


new String:badNames[255][64];
new String:fileName[PLATFORM_MAX_PATH];
new lines;
new Handle:bnkb_bantime;
new Handle:bnkb_reason;
new bool:EventsHooked = false


#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name = "Bad name kick / ban",
	author = "2NASTY4U",
	description = "Kicks / bans anybody with a bad phrase in their name",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("sm_bnkb_version", PLUGIN_VERSION, "Bad name kick / ban version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	bnkb_reason = CreateConVar("sm_bnkb_reason", "Bad name", "Reason to give client when they are kicked / banned")
	bnkb_bantime = CreateConVar("sm_bnkb_bantime", "-1", "How long to ban someone with a bad phrase in their name (0 = perm, -1 = just kick)");
	AutoExecConfig(true, "plugin.badnamekickban");
	
}

public OnMapStart(){
	for(new i; i < lines; i++)
	{
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
	if(GetAdminFlag(playerAdmin, Admin_Custom1, Access_Effective)){
		return;
	}
	
	//Trim the spaces out
	ReplaceString(clientName, 64, " ", "")
	
	//Check if they have a bad phrase in their name
	for(new i = 0; i < lines; i++){
		if(StrContains(clientName, badNames[i], false) != -1)
		{
			//Ban/kick the player
			new bantime = GetConVarInt(bnkb_bantime)
			new String:reason[64]
			GetConVarString(bnkb_reason,reason,64)
			
			if(bantime != -1)
			{
				ServerCommand("sm_ban #%i %i %s", playerId, bantime, reason)
			}
			
			else
			{
				ServerCommand("sm_kick #%i %s", playerId, reason)
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
 