#include <sourcemod>

#define BUFLEN 64
#define VOTEFAILURE_ADMIN 12
#define VERSION "1.0.0"
#define DESCRIPTION "Blocks votekicking admins"

public Plugin myinfo = {
	name = "ULTRA Admin Protection",
	description = DESCRIPTION,
	author = "Apple3.14159",
	version = VERSION,
	url = "https://ultra.gameme.com"
};

public void OnPluginStart(){
	CreateConVar("ultra_admin_protection_version", VERSION, DESCRIPTION, FCVAR_NOTIFY);
	AddCommandListener(blockKickingAdmin, "callvote");
}

public Action blockKickingAdmin(int client, const char[] command, int argc){
	if(argc < 2){
		return Plugin_Continue;
	}
	
	char reason[BUFLEN];
	GetCmdArg(1, reason, BUFLEN);
	if(strcmp(reason, "kick", false)){
		return Plugin_Continue;
	}
	
	char victimUserStr[BUFLEN];
	GetCmdArg(2, victimUserStr, BUFLEN);
	int victimUser = StringToInt(victimUserStr);
	if(!victimUser){
		PrintToChat(client, "Argument isn't userid");
		return Plugin_Continue;
	}
	
	int victimClient = GetClientOfUserId(victimUser);
	
	if(!victimClient){
		PrintToChat(client, "Getting client from userid failed");
		return Plugin_Continue;
	}
	
	AdminId votekickerAdmin = GetUserAdmin(client);
	AdminId victimAdmin = GetUserAdmin(victimClient);
	
	if(votekickerAdmin == INVALID_ADMIN_ID && victimAdmin != INVALID_ADMIN_ID){
		Handle failedVoteHandle = StartMessageOne("CallVoteFailed", client, USERMSG_RELIABLE);
		BfWriteByte(failedVoteHandle, VOTEFAILURE_ADMIN);
		BfWriteShort(failedVoteHandle, -1);
		EndMessage();
		
		return Plugin_Handled;
	} else return Plugin_Continue;
}