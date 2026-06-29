#include <sourcemod>

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

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	decl String:sBuffer[32];
	GetConVarString(hCvar, sBuffer, sizeof(sBuffer));
	
	if(hCvar == g_Terrorist)
		SetConVarString(g_hCvarTeamName2, sBuffer);
	else if(hCvar == g_CTerrorist)
		SetConVarString(g_hCvarTeamName1, sBuffer);
}