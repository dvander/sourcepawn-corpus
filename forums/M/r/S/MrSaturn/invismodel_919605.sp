/*
*	Plugin Invis Model par Flyflo
*
*	Changelog :
*		- Alpha1 :
*					- Première version utilisable.
*		- Alpha2:
*					- L'invisibilité reste après la mort.
*
*/
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#define VERSION "Alpha2"

new bool:g_IsInvis[MAXPLAYERS+1] = {false, ...};

public Plugin:myinfo = 
{
	name = "ModelInvis",
	author = "Flyflo",
	description = "Set playermodel invisible but not weapons",
	version = VERSION,
	url = "www.geek-gaming.fr"
};

public OnPluginStart()
{
	RegAdminCmd("sm_invismodel", Command_InvisModel, ADMFLAG_SLAY, "sm_invismodel <#userid|name> <1|0> - set the client playermodel invis or not");
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_changeclass", PlayerSpawn);
	HookEvent("teamplay_teambalanced_player", PlayerSpawn);
}

ModelInvis(client)
{
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 0);
	g_IsInvis[client] = true;
}

ModelVis(client)
{
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	g_IsInvis[client] = false;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (!client)
	{
        return;
	}
	
	if(g_IsInvis[client] == true)
	{
		ModelInvis(client);
	}
	else
	{
		ModelVis(client);
	}
}

public Action:Command_InvisModel(client,args)
{

	decl String:target[65];
	decl String:toggleStr[2];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	new toggle = 2;
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_invismodel <#userid|name> <1|0>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, target, sizeof(target));
	
	if (args > 1)
	{
		GetCmdArg(2, toggleStr, sizeof(toggleStr));
		if (StrEqual(toggleStr[0],"1"))
		{
			toggle = 1;
		}
		else if (StrEqual(toggleStr[0],"0"))
		{
			toggle = 0;
		}
		else
		{
			ReplyToCommand(client, "[SM] Usage: sm_invismodel <#userid|name> <1|0>");
			return Plugin_Handled;	
		}
	}
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if(toggle == 1)
		{
			ModelInvis(target_list[i]);
		}
		else
		{
			ModelVis(target_list[i]);
		}
	}	
	
	return Plugin_Handled; 
}

public OnClientDisconnect(client)
{
	ModelVis(client);
}