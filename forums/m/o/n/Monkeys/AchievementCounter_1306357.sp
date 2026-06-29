#include <sourcemod>
#include <colors>

#pragma semicolon 1

#define VERSION "1.0"

static String:FilePath[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "Achievement Counter",
	author = "Monkeys",
	description = "Counts the amount of achievements you've earned on a server",
	version = VERSION,
	url = ""
};

public OnPluginStart()
{
	BuildPath( Path_SM, FilePath, sizeof(FilePath), "data/AchCountLog.txt" );
	HookEvent( "achievement_earned", EventAchEarned );
}

public OnMapStart()
{
	if( !FileExists( FilePath ) ) PrintToChatAll( "|Achievement Counter| AchCountLogs.txt not found. Please move it to addons/sourcemod/data/." );
}

public OnClientPostAdminCheck(Client)
{
	decl String:Auth[32];
	GetClientAuthString( Client, Auth, sizeof(Auth) );
	new Handle:KV = CreateKeyValues( "Achievements Log" );
	FileToKeyValues( KV, FilePath );
	if(IsClientInGame(Client))
		CPrintToChat(Client, "{green}%d achievements have been earned on this server", KvGetNum(KV, "Achievement Count", 0));
	CloseHandle(KV);
}

public EventAchEarned(Handle:Event, const String:name[], bool:dontBroadcast)
{
	new Handle:KV = CreateKeyValues( "Achievements Log" );
	FileToKeyValues( KV, FilePath );
	KvSetNum( KV, "Achievement Count", (KvGetNum(KV, "Achievement Count", 0)+1) );
	KvRewind(KV);
	KeyValuesToFile(KV, FilePath);
	CloseHandle(KV);
}

