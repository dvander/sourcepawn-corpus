#pragma semicolon 1

#include <sourcemod>

#define VOTEKICK_KICK_VERSION    "1.0.0"

public Plugin:myinfo = {
	name        = "Votekick & Be Kicked",
	author      = "Dr. McKay",
	description = "Kick specific Steam IDs when they type votekick or voteban",
	version     = VOTEKICK_KICK_VERSION,
	url         = "http://www.doctormckay.com"
}

public OnPluginStart() {
	CreateConVar("sm_votekick_kick_version", VOTEKICK_KICK_VERSION, "Votekick & Be Kicked", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", Command_CheckSpeech);
	RegConsoleCmd("say_team", Command_CheckSpeech);
}

public Action:Command_CheckSpeech(client, args) {
	if(client!=0) {
		// TnTSCS moved the KeyValue code inside here
		decl String:steamid[30];
		decl String:text[256];
		GetClientAuthString(client, steamid, sizeof(steamid));
		GetCmdArg(1, text, sizeof(text));
		
		if(StrEqual(text, "votekick") || StrEqual(text, "voteban") || StrEqual(text, "!votekick") || StrEqual(text, "!voteban") || StrEqual(text, "/votekick") || StrEqual(text, "/voteban")){
			new Handle:steamidFile = CreateKeyValues("VotekickandKick");
			
			decl String:fPath[256];
			BuildPath(Path_SM, fPath, sizeof(fPath), "configs/votekickandkick.txt");
			
			if (FileExists(fPath)) {
				FileToKeyValues(steamidFile, fPath);
			} else {
				SetFailState("File Not Found: %s", fPath);
			}			
			
			if(KvJumpToKey(steamidFile, steamid, false)) {
				KickClient(client, "You are not allowed to type votekick or voteban");
				CloseHandle(steamidFile);
				return Plugin_Handled;
			}
			CloseHandle(steamidFile);
		}		
	}
	return Plugin_Continue;
}