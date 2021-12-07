#include <sourcemod>
#include <cstrike>

new Handle:g_Terrorist = INVALID_HANDLE;
new Handle:g_CTerrorist = INVALID_HANDLE;
new Handle:g_hCvarTeamName1  = INVALID_HANDLE;
new Handle:g_hCvarTeamName2 = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "Team Names",
    author = "Internet Bully",
    description = "Allows you to set the name of teams",
	version     = "1.1",
    url = "http://www.sourcemod.net/"
}

public OnPluginStart() 
{
	g_Terrorist 	= CreateConVar("sm_teamname_t", "", "Set your Terrorist team name.", FCVAR_PLUGIN);
	g_CTerrorist 	= CreateConVar("sm_teamname_ct", "", "Set your Counter-Terrorist team name.", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_teamname", Command_TeamName, ADMFLAG_ROOT);
	HookConVarChange(g_Terrorist, OnConVarChange);
	HookConVarChange(g_CTerrorist, OnConVarChange);
	
	g_hCvarTeamName1 = FindConVar("mp_teamname_1");
	g_hCvarTeamName2 = FindConVar("mp_teamname_2");
}

public OnMapStart()
{
	decl String:sBuffer[32];
	GetConVarString(g_Terrorist, sBuffer, sizeof(sBuffer));
	SetConVarString(g_hCvarTeamName2, sBuffer);
	GetConVarString(g_CTerrorist, sBuffer, sizeof(sBuffer));
	SetConVarString(g_hCvarTeamName1, sBuffer);
}

public Action Command_TeamName(int client, int args) {
	if (args < 2 || args > 2) {
		ReplyToCommand(client, "[SM] Usage: sm_teamname <T | CT> <Name>");
		return Plugin_Handled;
	}
	char arg1[32];
	char newName[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, newName, sizeof(newName));
	if (StrEqual(arg1, "T", false)) {
		SetConVarString(g_hCvarTeamName2, newName);
		ApplyClanTag(newName, 2);
	} else if (StrEqual(arg1, "CT", false)) {
		SetConVarString(g_hCvarTeamName1, newName);
		ApplyClanTag(newName, 3);
	} else {
		ReplyToCommand(client, "[SM] Usage: sm_teamname <T | CT> <Name>");
	}
	return Plugin_Handled;
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));
	
	if(hCvar == g_Terrorist) {
		SetConVarString(g_hCvarTeamName2, sBuffer);
		ApplyClanTag(sBuffer, 2);
	}
	else if(hCvar == g_CTerrorist) {
		SetConVarString(g_hCvarTeamName1, sBuffer);
		ApplyClanTag(sBuffer, 3);
	}
}

stock void ApplyClanTag(const char[] sBuffer, int team) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i))
			continue;
		if (GetClientTeam(i) != team)
			continue;
		CS_SetClientClanTag(i, sBuffer);
	}
}