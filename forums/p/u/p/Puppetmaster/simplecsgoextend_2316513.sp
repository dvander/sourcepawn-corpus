#include <dbi>
#include <sourcemod> 
#include <cstrike>
#include <clientprefs>
#include <sdktools>
//#include <smlib>

#define PLUGIN_VERSION "0.0.0"

//convars
ConVar mapTime;
int playerVotes[64];
int tally[2];

//begin
public Plugin:myinfo =
{
	name = "SimpleCSGOExtend",
	author = "Puppetmaster",
	description = "SimpleCSGOExtend Addon",
	version = PLUGIN_VERSION,
	url = "http://gamingzone.ddns.net/"
};

//called at start of plugin, sets everything up.
public OnPluginStart()
{
	mapTime = FindConVar("mp_timelimit");
}


SetMapTime(int newTime)
{
	mapTime.IntValue = newTime;
}

public int GetConvar()
{
	char buffer[128]
 
	mapTime.GetString(buffer, 128)
 
	return StringToInt(buffer)
}

public void extendMap(){
	SetMapTime(GetConvar()+10);
}

public Action:Timer_voteComplete(Handle:timer)
{
	PrintToChatAll("Vote Complete");
	//tally = {0,0}; //clear the array, [0] is yes, [1] is no.
	tally[0] = 0;
	tally[1] = 0;
	//tally all the votes up
	for(int x = 0; x<64; x++){
		if(playerVotes[x] != -1)
		{
			if(playerVotes[x] == 1)
			{
				tally[0]++; //yes		
			}
			else {
				tally[1]++; //no
			}
		}
	}
	PrintToChatAll("Yes(%d) - No(%d)", tally[0], tally[1])
	if(tally[0] > tally[1])
	{
		extendMap();
		PrintToChatAll("Extending map by 10 minutes");
	}
	else
	{
		PrintToChatAll("Vote failed");	
	}
	return Plugin_Continue;
}



public Action OnClientSayCommand(int client, const char[] command, const char[] args) {
	if (strcmp(args[0], "sm_voteextend", false) == 0) {
		if(GetUserAdmin(client) != INVALID_ADMIN_ID){
			//first clear votes array
			for(int x = 0; x<64; x++){
				playerVotes[x] = -1;
			}
			CreateTimer(22.0, Timer_voteComplete);
			PrintToChatAll("Voting to extend the map by 10 minutes is underway. Say !yes or !no to vote.");
					
		}
	}
	else if (strcmp(args[0], "!yes", false) == 0) {
		playerVotes[client] = 1;
	}
	else if (strcmp(args[0], "!no", false) == 0) {
		playerVotes[client] = 0;
	}
}
