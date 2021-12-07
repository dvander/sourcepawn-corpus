//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
#include <sdktools>
#pragma  semicolon 1

////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo = 
{
	name = "[L4D] Boomer Suicide Bomb",
	author = "noodleboy347",
	description = "Lets Boomers explode themselves with reload",
	version = "1.0",
	url = "http://www.frozencubes.com"
}

//////////////////////////
//P L U G I N  S T A R T//
//////////////////////////
public OnPluginStart()
{
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
}

////////////////////////
//R U N  C O M M A N D//
////////////////////////
public Action:OnPlayerRunCmd(client, &buttons)
{
	if(IsClientInGame(client) && !(IsFakeClient(client)) && getclientteam(client) == TEAM_INFECTED && IsPlayerAlive(client) && !(IsPlayerSpawnGhost(client)) && GetEntProp(client, Prop_Send,  "m_zombieClass") == 2) && (buttons & IN_RELOAD))
		ForcePlayerSuicide(client);
}  
 
bool:IsPlayerSpawnGhost(client)
{
	if(GetEntData(client, propinfoghost, 1)) return true;
	else return false;
}
 
