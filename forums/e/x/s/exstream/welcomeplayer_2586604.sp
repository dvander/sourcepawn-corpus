#include <sourcemod>
#include <colors>

#define CVAR_WPE "sm_wp_enabled"
#define CVAR_FDR "sm_wp_features_repeat"
#define CVAR_GRP "sm_wp_greet_player"
#define CVAR_GRA "sm_wp_greet_all"

new Handle:g_Cvar_WpEnabled = INVALID_HANDLE;
new Handle:g_Cvar_FeRepeat = INVALID_HANDLE;
new Handle:g_Cvar_GrPlayer = INVALID_HANDLE;
new Handle:g_Cvar_GrAll = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Welcome Player",
    author = "Nefarius",
    description = "Simple server join welcome message",
    version = "0.0.1",
    url = "http://nefarius.at"
}

public OnPluginStart()
{
	g_Cvar_WpEnabled =	CreateConVar(CVAR_WPE, "1", "Display welcome message on player join (1 = Enabled/Default, 0 = Disabled)", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvar_FeRepeat =	CreateConVar(CVAR_FDR, "40", "Time in seconds to repeat feature message (Default: 120)", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED, true, 0.0, true, 3600.0);
	g_Cvar_GrPlayer =	CreateConVar(CVAR_GRP, "1", "Greet player on join (1 = Enabled/Default, 0 = Disabled)", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvar_GrAll =		CreateConVar(CVAR_GRA, "1", "Greet all active clients on new member join (1 = Enabled/Default, 0 = Disabled)", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED);
        AutoExecConfig(true,"plugin.welcomemessage"); 	
	// display features
	if (GetConVarFloat(g_Cvar_FeRepeat) > 0.0)
		CreateTimer(GetConVarFloat(g_Cvar_FeRepeat), ServerFeatureAnnounce);
}

public OnClientPutInServer(client)
{
	if (GetConVarBool(g_Cvar_WpEnabled) /* && (GetUserFlagBits(client) & ADMFLAG_CUSTOM1) */)
	{
		// notify all players
		if (GetConVarBool(g_Cvar_GrAll))
			CreateTimer(0.01, PlayerInstantJoinAnnounce, any:client);
		// notify new player only; 10sec delay (MOTD, Menu etc.)
		if (GetConVarBool(g_Cvar_GrPlayer))
			CreateTimer(10.0, PlayerPersonalJoinAnnounce, any:client);
	}
}

public Action:PlayerInstantJoinAnnounce(Handle:timer, any:client)
{
	if(!IsFakeClient(client))
	{
		new String:name[32], String:authid[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, authid, sizeof(authid));
		
		CPrintToChatAll(" \x03%s\x01 \x01Join the server", name, authid);
	}
}

public Action:PlayerPersonalJoinAnnounce(Handle:timer, any:client)
{
	if(!IsFakeClient(client))
	{
		new String:name[32], String:authid[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, authid, sizeof(authid));
		
		CPrintToChat(client, "\x04Welcome, to the server \x01%s", name);
	}
}

public Action:ServerFeatureAnnounce(Handle:timer)
{
	if (GetConVarFloat(g_Cvar_FeRepeat) > 0.0)
	{
		CPrintToChatAll("\x01Welcome to \x03your server name ");
		CPrintToChatAll("\x01Jion use on \x03Teamspeak");
		CPrintToChatAll("\x0311.11.11.11");
		CPrintToChatAll("\x01Please use push to talk only");
		
		CreateTimer(GetConVarFloat(g_Cvar_FeRepeat), ServerFeatureAnnounce);
	}
}

