#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new votecount = 0;
new bool:voteEnded;
new bool:timerCreated = false;
new bool:didclientVote[32];
new Handle:sm_rebootvote_count;
new Handle:sm_rebootvote_type;
new Handle:sm_rebootvote_map;

public Plugin:myinfo = {
	name = "Dota 2 - Server reboot voter.",
	author = "The-Disaster",
	description = "Server reboot/map reload voter.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart(){
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	sm_rebootvote_count = CreateConVar("sm_rebootvote_count", "7", "Amount of votes needed to reboot the server.");
	sm_rebootvote_type = CreateConVar("sm_rebootvote_type", "0", "Reboot the server = 0 || Change the map = 1");
	sm_rebootvote_map = CreateConVar("sm_rebootvote_map", "dota", "The map you want to change into when the vote is passed.");
}

public Action:Command_Say(client, const String:command[], args){
	decl String:sayString[32];
	decl String:clientName[32];
	new maxVotes = GetConVarInt(sm_rebootvote_count);
	GetCmdArg(1,sayString,sizeof(sayString));
	

	GetClientName(client, clientName, sizeof(clientName));
	GetCmdArgString(sayString, sizeof(sayString));
	StripQuotes(sayString);
	if(!strcmp(sayString,"-vb",false))
	{
		if(IsClientSourceTV(client) || IsClientReplay(client) || IsFakeClient(client)){
			return;
		}else if(GetClientTeam(client) != 2 && GetClientTeam(client) != 3){
			PrintToChat(client, "You have no right to vote.");
			return;
		}else if(didclientVote[client]){
			PrintToChat(client, "You have already voted for a server reboot.");
			return;
		}else
			votecount++;
		
		PrintToChatAll("%s have voted for a server reboot (%d / %d)", clientName, votecount, maxVotes);
		if(votecount < maxVotes){
			voteEnded = false;
			didclientVote[client] = true;
			if(!timerCreated){
				timerCreated = true;
				CreateTimer(30.0, checkForVotes);
			}
		}else if(votecount >= maxVotes){
			if(!voteEnded){
				voteEnded = true;
				votecount = 0;
				CreateTimer(1.0, ExitServer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action:ExitServer(Handle:Timer, any:client){
	static repeatNumber = 0;
	new voteType = GetConVarInt(sm_rebootvote_type);
	new String:mapName[32];
	
	GetConVarString(sm_rebootvote_map, mapName, sizeof(mapName));
	
	if(repeatNumber >= 9) {
		repeatNumber = 0;
		
		if(voteType == 0)
			ServerCommand("exit");
		else
			ServerCommand("map %s", mapName);
		
		reSetVotes();
		return Plugin_Stop;
	}
	
	if(voteType == 0)
		PrintToChatAll("Server will reboot in %d", 9-repeatNumber);
	else
		PrintToChatAll("Changing map to %s in %d", mapName, 9-repeatNumber);
	
	repeatNumber++;
	
	return Plugin_Continue;
}

public Action:checkForVotes(Handle:Timer, any:client){
	if(voteEnded) return;
	
	PrintToChatAll("Vote failed, server will not reboot.");
	reSetVotes();
}

public reSetVotes(){
	voteEnded = false;
	timerCreated = false;
	votecount = 0;
	for(new i = 1; i <= 32; i++){
		didclientVote[i] = false;
	}
}