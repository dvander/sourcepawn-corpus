#include <sourcemod>
#include <sdktools>
#define VERSION "1.0"

new Handle:g_hDelay = INVALID_HANDLE;
new Handle:g_hHeight = INVALID_HANDLE;
new Handle:g_hNotify = INVALID_HANDLE;

new StuckUsed[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "!zstuck",
	author = "XeroX",
	description = "Allows Players to unstuck themself",
	version = VERSION,
	url = "http://sammys-zps.com"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_zstuck",CommandUnstuck);
	CreateConVar("sm_zstuck_version",VERSION,"Version of this Plugin",FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	g_hDelay = CreateConVar("sm_zstuck_delay","2.0","Delay in which the command can be used in seconds",FCVAR_NOTIFY|FCVAR_REPLICATED,true,2.0);
	g_hHeight = CreateConVar("sm_zstuck_height","64","Height at which the player get moved up to as Float",FCVAR_NOTIFY|FCVAR_REPLICATED,true,64.0,true,256.0);
	g_hNotify = CreateConVar("sm_zstuck_admin_notify","1","Notifies admin when a player unstuck themselfs",FCVAR_REPLICATED,true,0.0,true,1.0);
	AutoExecConfig(true,"zstuck");
}

public OnClientConnected(client)
{
	StuckUsed[client] = GetTime();
}

public Action:CommandUnstuck(client, args)
{
	if(client == 0)
	{
		ReplyToCommand(client,"[ZSTUCK]: This command can only be used ingame");
		return Plugin_Handled;
	}
	else
	{
		if(!IsPlayerAlive(client))
		{
			PrintToChat(client,"[ZSTUCK]: You need to be alive to use this command");
			return Plugin_Handled;
		}
		if(GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
		{
			if(GetTime() - StuckUsed[client] < GetConVarInt(g_hDelay))
			{
				PrintToChat(client,"[ZSTUCK]: Please wait before using it again");
				return Plugin_Handled;
			}
			else
			{
				StuckUsed[client] = GetTime();
				new Float:Pos[3];
				GetClientAbsOrigin(client,Pos);
				Pos[2] += GetConVarFloat(g_hHeight);
				TeleportEntity(client,Pos,NULL_VECTOR,NULL_VECTOR);
				if(GetConVarInt(g_hNotify) == 1)
				{
					InsertServerCommand("sm_chat %N unstucked himself",client);
				}
				ReplyToCommand(client,"[ZSTUCK]: You have unstucked yourself");	
			}
		}
	}
	return Plugin_Handled;
}
