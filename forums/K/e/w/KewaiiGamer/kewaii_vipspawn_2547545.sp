#include <sourcemod>
#include <csgocolors>
#include <zephstocks>
#include <cstrike>
#include <kewaii_lib>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "VipSpawn"
#define PLUGIN_AUTHOR "Kewaii"
#define PLUGIN_DESCRIPTION "Advanced Respawn for Vip players"
#define PLUGIN_VERSION "1.0.5"
#define PLUGIN_TAG "{pink}[VipSpawn by Kewaii]{green}"

public Plugin myinfo =
{
    name        =    PLUGIN_NAME,
    author        =    PLUGIN_AUTHOR,
    description    =    PLUGIN_DESCRIPTION,
    version        =    PLUGIN_VERSION,
	url         = "http://steamcommunity.com/id/KewaiiGamer"
};

bool g_bRevived[MAXPLAYERS+1] = {false, ...};
int g_cvarVIPFlag = -1;

public void OnPluginStart()
{
	g_cvarVIPFlag = RegisterConVar("kewaii_vipspawn", "o", "Flag for VIP Access.", TYPE_FLAG);
   	LoadTranslations("kewaii_vipspawn.phrases");
	RegConsoleCmd("sm_vipspawn", Command_VipSpawn);
	HookEvent("round_start", OnRoundStart);
	AutoExecConfig(true, "kewaii_vipspawn");
}
public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		g_bRevived[i] = false;
	}
}

public bool IsClientVIP(int client)
{
	return CheckCommandAccess(client, "", g_eCvars[g_cvarVIPFlag][aCache], true);
}

public Action Command_VipSpawn(int client, int args)
{
	if(IsClientInGame(client))
	{
		if(IsClientVIP(client))
		{
	   		if(IsPlayerAlive(client))
	   		{
	   			CPrintToChat(client, "%s %t", PLUGIN_TAG, "DeadPlayer");
	   		}
	   		else
	      	{
		        if(g_bRevived[client])
	        	{
	          		CPrintToChat(client, "%s %t", PLUGIN_TAG, "PlayerAlreadyUsedVipspawn");
		        }
	        	else
	        	{
		          	CS_RespawnPlayer(client);
		          	char clientName[MAX_NAME_LENGTH];
	          		GetClientName(client, clientName, sizeof(clientName));
	          		CPrintToChatAll("%s %t", PLUGIN_TAG, "PlayerUsedVipspawn", clientName);
	        	  	g_bRevived[client] = true;
	        	}
	      	}
	   	}
	   	else
	   	{
	   		CPrintToChat(client, "%s %t", PLUGIN_TAG, "PlayerNotVip");
	   	}
   	}
   	else
   	{
	   	PrintToServer("%t","Command is in-game only");
   	}
   	return Plugin_Handled;
}