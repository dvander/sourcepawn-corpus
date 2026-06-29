#include <sourcemod>
#pragma semicolon 1

new Handle:FF;
new Handle:resct;

public Plugin:myinfo =  
{ 
    name = "Shortcuts", 
    author = "Kotori17", 
    description = "shortcuts", 
    version = "1.0", 
    url = "http://steamcommunity.com/id/kotori17/" 
} 

public OnPluginStart() 
{ 
	RegAdminCmd("sm_ffopen", Command_openff, ADMFLAG_GENERIC);
	RegAdminCmd("sm_ffclose", Command_closeff, ADMFLAG_GENERIC);
	RegAdminCmd("sm_otoresct1", Command_res1, ADMFLAG_GENERIC);
	RegAdminCmd("sm_otoresct0", Command_res0, ADMFLAG_GENERIC);
	RegAdminCmd("sm_finishthegame", Command_Finish, ADMFLAG_GENERIC);
	resct = FindConVar("mp_respawn_on_death_ct");
	FF = FindConVar("mp_friendlyfire");
} 

public Action:Command_Finish(client, args)
{
	if (args < 1)
	{
	ReplyToCommand(client, "[Shortcuts] Usage: sm_finishthegame <map>");
	return Plugin_Handled;
	}
	ServerCommand("sm_slay @all");
	PrintToChatAll("%N: Finished the game", client);
	CreateTimer(5.0, Finish);
	
	return Plugin_Handled;
}

public Action:Finish(Handle timer)
{
	new String:arg[20];
	GetCmdArg(1, arg, sizeof(arg));
	ForceChangeLevel(arg, "Finished the game");
	return Plugin_Handled;
}

public Action:Command_res1(client, args)
{
	SetConVarInt(resct, 1);
	return Plugin_Handled;
}

public Action:Command_res0(client, args)
{
	SetConVarInt(resct, 0);
	return Plugin_Handled;
}

public Action:Command_openff(client, args)
{
   SetConVarInt(FF, 1);
   return Plugin_Handled;
}

public Action:Command_closeff(client, args)
{
	SetConVarInt(FF, 0);
	return Plugin_Handled;
}