/*
Well this is one of my first plugins
It's mainly to get people attention in game
It pops up a domintion scrren with what ever text you want.

Just don't use quotes inside the text

Usage:
sm_showtext any thing you want to say.

I Based this plugin off of one of bl4nk's

It's pretty simple but it works great.

-Mammal Master

-www.necrophix.com
TF2 Server: tf2.necrophix.com


*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"


// Functions
public Plugin:myinfo =
{
	name = "ShowText",
	author = "Mammal",
	description = "show text to screen",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_showtext_version", PLUGIN_VERSION, "ShowText Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_showtext", Command_ShowText, ADMFLAG_CHANGEMAP, "sm_showtext <Text>");
	
}

public Action:Command_ShowText(client, args)
{

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_showtext <text>");
		return Plugin_Handled;
	}


	new String:cmdArg[256];
	GetCmdArgString(cmdArg, sizeof(cmdArg));

	
	
	new Text_Ent = CreateEntityByName("game_text_tf");
	DispatchKeyValue(Text_Ent,"message",cmdArg);
	DispatchKeyValue(Text_Ent,"display_to_team","0");
	DispatchKeyValue(Text_Ent,"icon","leaderboard_dominated");
	DispatchKeyValue(Text_Ent,"targetname","game_text1");
	DispatchKeyValue(Text_Ent,"background","0");
	DispatchSpawn(Text_Ent);

	AcceptEntityInput(Text_Ent, "Display", Text_Ent, Text_Ent);

	CreateTimer(10.0, Kill_ent, Text_Ent);
	
	//}

	return Plugin_Handled;
}

public Action:Kill_ent(Handle:timer, any:ent)
{
	
	AcceptEntityInput(ent, "kill");
	
	
	return; //Plugin_Stop;
}