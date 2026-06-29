#include <sourcemod>

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
	g_Cvar_FeRepeat =	CreateConVar(CVAR_FDR, "120", "Time in seconds to repeat feature message (Default: 120)", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED, true, 0.0, true, 3600.0);
	g_Cvar_GrPlayer =	CreateConVar(CVAR_GRP, "1", "Greet player on join (1 = Enabled/Default, 0 = Disabled)", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED);
	g_Cvar_GrAll =		CreateConVar(CVAR_GRA, "1", "Greet all active clients on new member join (1 = Enabled/Default, 0 = Disabled)", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED);
	
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
		
		PrintToChatAll("\x01[SM] \x04%s\x01 (\x05%s\x01) joined the server!", name, authid);
	}
}

public Action:PlayerPersonalJoinAnnounce(Handle:timer, any:client)
{
	if(!IsFakeClient(client))
	{
		new String:name[32], String:authid[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, authid, sizeof(authid));
		
		PrintToChat(client, "Welcome, \x04XT-Gamer \x05%s\x01", name);
	}
}

public Action:ServerFeatureAnnounce(Handle:timer)
{
	if (GetConVarFloat(g_Cvar_FeRepeat) > 0.0)
	{
		PrintToChatAll("This Server offers the following features:");
		PrintToChatAll("\x01  \x03*\x01 A \x04Healthpack\x01 is dropped randomly from dead players");
		PrintToChatAll("\x01  \x03*\x01 \x04HE Grenade damage\x01 is increased");
		PrintToChatAll("\x01  \x03*\x01 The default \x04Grenade stock is increased\x01");
		PrintToChatAll("\x01  \x03*\x01 Gameplay is \x04Anti-Camp protected\x01");
		PrintToChatAll("\x01  \x03*\x01 \x04Teamkillers\x01 will get punished");
		
		CreateTimer(GetConVarFloat(g_Cvar_FeRepeat), ServerFeatureAnnounce);
	}
}

