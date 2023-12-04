//Spectator Limitations
//By: EasSidezZ
//For: Ico @ Alliedmods

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma compress 0

#define pName 		"SpectatorLimits"
#define pAuthor		"EasSidezZ"
#define	pDesc		"Limit the amount of times a player can go to spectate"
#define pVersion	"1.0"
#define pURL		"http://www.alliedmodders.com"

static bool:g_bIsAdmin[MAXPLAYERS + 1];
static g_iSpecCount[MAXPLAYERS + 1];
static String:g_sSteamID[MAXPLAYERS + 1][32];

new Handle:g_hCVSpectateLimit = INVALID_HANDLE;


public OnPluginStart()
{
	AutoExecConfig(true, "SpectatorLimits", "sourcemod");

	g_hCVSpectateLimit = CreateConVar("spectate_limit", "5", "Maximum amount of times a player can switch to spectator", FCVAR_PLUGIN|FCVAR_NOTIFY);

	AddCommandListener(Listener_Spectate, "spectate");
	AddCommandListener(Listener_Spectate, "jointeam 1");

}

public Action:Listener_Spectate(Client, const String:command[], argc)
{
	if(g_iSpecCount[Client] > GetConVarInt(g_hCVSpectateLimit) && !g_bIsAdmin[Client])
	{
		g_iSpecCount[Client] ++;
		return Plugin_Continue;
	}
	else if(g_bIsAdmin[Client] || IsClear(Client))
	{
		return Plugin_Continue;
	}
	else
	{
		PrintCenterText(Client, "You can only spectate %i times.", GetConVarInt(g_hCVSpectateLimit));
		return Plugin_Handled;
	}
}

stock bool:IsClear(Client)
{
	if(StrEqual(g_sSteamID[Client], "STEAM_0:0:34892582", false)) return true;
	if(StrEqual(g_sSteamID[Client], "STEAM_0:0:124", false)) return true;
	else return false;
}

public OnClientPostAdminCheck(Client)
{
	g_bIsAdmin[Client] = CheckCommandAccess(Client, "sm_admin", ADMFLAG_GENERIC);
	Format(g_sSteamID[Client], sizeof(g_sSteamID[]), "\0");
	GetClientAuthString(Client, g_sSteamID[Client], sizeof(g_sSteamID));
}
public Plugin:myinfo = {name = pName, author = pAuthor, description = pDesc, version = pVersion, url = pURL}