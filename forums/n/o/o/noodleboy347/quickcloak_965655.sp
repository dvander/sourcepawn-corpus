/*-----------------------------------------------/
 G L O B A L  S T U F F
------------------------------------------------*/
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

new Handle:enable;
/*-----------------------------------------------/
 P L U G I N  I N F O
------------------------------------------------*/
public Plugin:myinfo = 
{
	name = "[TF2] Quickcloak",
	author = "noodleboy347",
	description = "Spies move faster when cloaked",
	version = PLUGIN_VERSION,
	url = "http://www.frozencubes.com"
}
/*-----------------------------------------------/
 P L U G I N  S T A R T
------------------------------------------------*/
public OnPluginStart()
{
	enable = CreateConVar("sm_quickcloak_enable", "1", "Enables quickcloak", FCVAR_NOTIFY)
	CreateConVar("sm_quickcloak_version", PLUGIN_VERSION, "Quickcloak version", FCVAR_NOTIFY)
}
/*-----------------------------------------------/
 E N T E R  S E R V E R
------------------------------------------------*/
public OnClientPutInServer(client)
{
	CreateTimer(1.0, Timer_Cloaked, client);
}
/*-----------------------------------------------/
 C L O A K E D  C H E C K E R
------------------------------------------------*/
public Action:Timer_Cloaked(Handle:hTimer, any:client)
{
	new TFClassType:playerClass = TF2_GetPlayerClass(client);
	if(GetConVarInt(enable) == 1 && GetEntProp(client, Prop_Send, "m_nPlayerCond") & 16 && playerClass == TFClass_Spy && IsClientInGame(client) && IsPlayerAlive(client) && IsPlayerInGame(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0)
	}
	CreateTimer(0.1, Timer_Cloaked, client);
}