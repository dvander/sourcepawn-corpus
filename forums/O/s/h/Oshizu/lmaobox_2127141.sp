#include <sourcemod>
#define MAX_STEAMID_LENGTH  19
 
public Plugin:myinfo = 
{
	name = "LMAOBAN",
	author = "Aderic & Mio Isurugi (Oshizu)",
	description = "Bans clients that connect to the server and spam LMAOBOX text.",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?p=2080526"
}

new Handle:banTime;
new Handle:banReason;

public OnPluginStart()
{
	banTime = 		CreateConVar("sm_lmaoban_time",		"60", 							"Time (in minutes) to ban the user, 0 means permanent ban.", FCVAR_NONE);
	banReason = 	CreateConVar("sm_lmaoban_reason",	"Hack Advertising Ban - Hacks are for losers, Real men uses skill.",  				"Reason for ban.", FCVAR_NONE);
	AutoExecConfig(true, "lmaoban");
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	if (StrContains(sArgs, "LMAOBOX", false) != -1)
	{
		decl String:stringReason[32];
		GetConVarString(banReason, stringReason, sizeof(stringReason));
		
		if (BanClient(client, GetConVarInt(banTime), BANFLAG_AUTHID, stringReason, stringReason, "LMAOBAN")) {
			decl String:clientSteam[MAX_STEAMID_LENGTH];
			GetClientAuthString(client, clientSteam, MAX_STEAMID_LENGTH);
			LogMessage("Autobanned client <%s> for advertising LMAOBOX.", clientSteam);
		}
		
		// Let's block this nasty message from getting to anyone else.
		return Plugin_Handled;
	}

	return Plugin_Continue;
}