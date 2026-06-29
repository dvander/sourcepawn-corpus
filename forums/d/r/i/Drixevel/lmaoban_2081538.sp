#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <sourcebans>
#define MAX_STEAMID_LENGTH  19

public Plugin:myinfo = 
{
	name = "LMAOBAN",
	author = "Aderic",
	description = "Bans clients that connect to the server and spam LMAOBOX text.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2080526"
}

new Handle:banTime;
new Handle:banReason;

new bool:Sourcebans = false;

public OnPluginStart()
{
	banTime = 		CreateConVar("sm_lmaoban_time",		"0", 							"Time (in minutes) to ban the user, 0 means permanent ban.", FCVAR_NONE);
	banReason = 	CreateConVar("sm_lmaoban_reason",	"Aimbot Autoban",  				"Reason for ban.", FCVAR_NONE);
	AutoExecConfig(true, "lmaoban");
}

public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[]) {
	new sArgsSize = strlen(sArgs) - 1;
	
	if (sArgsSize < 22)
		return Plugin_Continue;
	
	PrintToConsole(client, sArgs);
	
	decl String:msg[40];
	
	strcopy(msg, sizeof(msg), sArgs);
	
	if (sArgs[0] == '"' && sArgs[sArgsSize] == '"') {
		StripQuotes(msg);
	}
	
	if (StrEqual(msg, "WWW.LMAOBOX.NET - BEST FREE TF2 HACK!") || StrEqual(msg, "GET GOOD, GET LMAOBOX!")) {
		decl String:stringReason[32];
		GetConVarString(banReason, stringReason, sizeof(stringReason));
		
		if (Sourcebans) {
			if (SBBanPlayer(0, client, GetConVarInt(banTime), stringReason)) {
				decl String:clientSteam[MAX_STEAMID_LENGTH];
				GetClientAuthString(client, clientSteam, MAX_STEAMID_LENGTH);
				LogMessage("Autobanned client <%s> for advertising LMAOBOX via Sourcebans.", clientSteam);
			}
		}
		else {
			if (BanClient(client, GetConVarInt(banTime), BANFLAG_AUTHID, stringReason, stringReason)) {
				decl String:clientSteam[MAX_STEAMID_LENGTH];
				GetClientAuthString(client, clientSteam, MAX_STEAMID_LENGTH);
				LogMessage("Autobanned client <%s> for advertising LMAOBOX.", clientSteam);
			}
		}
		
		// Let's block this nasty message from getting to anyone else.
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public OnAllPluginsLoaded()
{
	Sourcebans = LibraryExists("sourcebans");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourcebans")) Sourcebans = true;
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sourcebans")) Sourcebans = false;
}