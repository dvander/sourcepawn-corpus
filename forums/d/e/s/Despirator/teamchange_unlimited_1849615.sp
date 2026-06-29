#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0"

public Plugin:myinfo =
{
	name = "TeamChange Unlimited",
	author = "FrozDark (HLModders LLC)",
	description = "TeamChange Unlimited",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public OnPluginStart() 
{ 
	AddCommandListener(Command_JoinTeam, "jointeam");
} 

public Action:Command_JoinTeam(client, const String:command[], argc) 
{ 
	if (!client) return Plugin_Continue;
	
	decl String:g_szTeam[4]; 
	GetCmdArgString(g_szTeam, sizeof(g_szTeam)); 
	new team = StringToInt(g_szTeam); 
	if (1 <= team <= 3)
	{ 
		ChangeClientTeam(client, team); 
		return Plugin_Handled; 
	} 
	return Plugin_Continue; 
}