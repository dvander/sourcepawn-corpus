#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.0"


public Plugin:myinfo = 
{
	name = "L4D Kill Enabler",
	author = "KawMAN",
	description = "Enable kill command without changing sv_cheats",
	version = PLUGIN_VERSION,
	url = "http://wsciekle.pl"
}

new String:g_tankmodel[]="models/infected/hulk.mdl";
new Handle:g_Kill_Block_Mode = INVALID_HANDLE;
new flagi;
new flagi2;

public OnPluginStart()
{
	flagi = GetCommandFlags("kill");
	flagi2 = GetCommandFlags("explode");
	SetCommandFlags("kill", flagi & ~FCVAR_CHEAT);
	SetCommandFlags("explode", flagi2 & ~FCVAR_CHEAT);
	RegConsoleCmd("kill", Kill_Me);
	RegConsoleCmd("explode", Kill_Me);
	CreateConVar("l4d_kill_block_v", PLUGIN_VERSION, "L4D Kill Enabler Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Kill_Block_Mode = CreateConVar("l4d_kill_mode", "3", "Kill Enabler Mode [0=Kill Disabled,1=Allow kill for all,2=Allow kill only for Infected, 3=Allow kill only for Infected without Tank]");
}

public OnPluginEnd()
{
	SetCommandFlags("kill", flagi);
	SetCommandFlags("explode", flagi2);
}

public Action:Kill_Me(client, args)
{
	if(GetConVarInt(g_Kill_Block_Mode) == 1)
	{
		ForcePlayerSuicide(client);
	}
	
	
	if(GetConVarInt(g_Kill_Block_Mode) == 2 || GetConVarInt(g_Kill_Block_Mode) == 3)
	{
		new cTeam  = GetClientTeam( client );
		if (cTeam == 3)
		{
			if(GetConVarInt(g_Kill_Block_Mode) == 3)
			{
				new String:model[255];
				GetClientModel(client, model, sizeof(model));
				if(strcmp(g_tankmodel,model,true)!= 0) 
				{
					ForcePlayerSuicide(client);
				}
				else
				{
					PrintToChat(client, "[SM] Kill command is blocked for Tank");
				}
			}
			else
			{
				ForcePlayerSuicide(client);
			}
		}
		else
		{
			PrintToChat(client, "[SM] Kill command is blocked for your team");
		}
	}
	return Plugin_Handled;
}