#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Reset Score for CS:GO",
	author = "Sheepdude",
	description = "Allows admins to reset scores and players to reset their own score.",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

new SCORE_OFFSET;
new MANAGER;
new MVPCount[MAXPLAYERS+1];

public OnPluginStart()
{
	RegConsoleCmd("sm_resetscore", CmdResetScore);
	RegConsoleCmd("sm_rs", CmdResetScore);
	RegAdminCmd("sm_resettargetscore", AdminResetTargetScore, ADMFLAG_GENERIC);
	SCORE_OFFSET = FindSendPropInfo("CCSPlayer", "m_bIsControllingBot") - 132;
	HookEvent("round_mvp", OnRoundMVP);
}

public OnMapStart()
{
	for(new i = 1; i <= MaxClients; i++)
		MVPCount[i] = 0;
	MANAGER = FindEntityByClassname(MaxClients+1, "cs_player_manager");
	if(MANAGER == -1)
		SetFailState("Can't find cs_player_manager entity.");
	SDKHook(MANAGER, SDKHook_ThinkPost, Hook_ThinkPost);
}

public OnRoundMVP(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	MVPCount[client]++;
}

public Hook_ThinkPost(entity)
{
	for(new i=1; i<= MaxClients; i++)
	{
		if(IsClientInGame(i))
			SetEntProp(entity, Prop_Send, "m_iMVPs", MVPCount[i], 4, i);
	}
}

public Action:CmdResetScore(client, args)
{
	ResetScore(client);
}

public Action:AdminResetTargetScore(client, args)
{
	if(args > 0)
	{
		decl String:target[64];
		GetCmdArg(1, target, sizeof(target));
		if(IterateResetScores(target) == 0)
		{
			new targetindex = FindTarget(client, target);
			if(targetindex > 0)
			{
				ResetScore(targetindex);
				ShowActivity2(client, "[SM] ", "%N reset %N's score.", client, targetindex);
			}
		}
		else
		{
			if(StrEqual(target, "@all"))
				ShowActivity2(client, "[SM] ", "%N reset everyone's scores.", client);
			else if(StrEqual(target, "@ct"))
				ShowActivity2(client, "[SM] ", "%N reset the CT's scores.", client);
			else if(StrEqual(target, "@t"))
				ShowActivity2(client, "[SM] ", "%N reset the T's scores.", client);
		}
	}
	else
		ReplyToCommand(client,"[SM] Usage: sm_resettargetscore <@all/@t/@ct/partial name>");
}

ResetScore(client)
{
	if(IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_iFrags", 0);
		new ASSISTS_OFFSET = FindDataMapOffs(client, "m_iFrags") + 4;
		SetEntData(client, ASSISTS_OFFSET, 0);
		SetEntData(client, SCORE_OFFSET, 0);
		SetEntProp(client, Prop_Data, "m_iDeaths", 0);
		MVPCount[client] = 0;
	}
}

IterateResetScores(const String:target[])
{
	new clients[MAXPLAYERS];
	new count = FindMatchingPlayers(target, clients);
	if(count == 0)
		return 0;
	for(new i = 0; i < count; i++)
		ResetScore(clients[i]);
	return count;
}

public FindMatchingPlayers(const String:matchstr[], clients[])
{
	new k = 0;
	if(StrEqual(matchstr, "@all", false))
	{
		for(new x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x))
			{
				clients[k] = x;
				k++;
			}
		}
	}
	else if(StrEqual(matchstr, "@t", false))
	{
		for(new x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x) && GetClientTeam(x) == 2)
			{
				clients[k] = x;
				k++;
			}
		}
	}
	else if(StrEqual(matchstr, "@ct", false))
	{
		for(new x = 1; x <= MaxClients; x++)
		{
			if(IsClientInGame(x) && GetClientTeam(x) == 3)
			{
				clients[k] = x;
				k++;
			}
		}
	}
	return k;
}