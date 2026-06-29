#include <sourcemod>
#include <sdktools>

#define SUPPRESS_VERSION "1.2.1"

public Plugin:myinfo = 
{
	name = "Simple Message Suppression",
	author = "FlyingMongoose, psychonic",
	description = "Suppresses Different Messages",
	version = SUPPRESS_VERSION,
	url = "http://www.simple-plugins.com/"
}

new Handle:cvarBlockSpectateMessage;
new Handle:cvarBlockJoinTeamMessage;
new Handle:cvarBlockDisconnectMessage;
new Handle:cvarBlockConnectMessage;
new Handle:cvarAdminShowMessages;
new iSpecTeam = 1;


public OnPluginStart()
{
	CreateConVar("suppress_version", SUPPRESS_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarBlockSpectateMessage = CreateConVar("sm_blockspectatemessage", "1", "If enabled it blocks the join team message if an administrator joins spectator", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarBlockJoinTeamMessage = CreateConVar("sm_blockjointeammessage", "0", "If enabled it blocks join team messages if an administrator joins any team", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarBlockDisconnectMessage = CreateConVar("sm_blockdisconnectmessage", "1", "Blocks the disconnect message", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarBlockConnectMessage = CreateConVar("sm_blockconnectmessage", "0", "If enabled it blocks the player connection message.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarAdminShowMessages = CreateConVar("sm_adminshowmessages", "1", "Shows disconnect/connect/team join messages for admins only (if disconnect message is set to be blocked)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookEvent("player_team", ev_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_disconnect", ev_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_connect", ev_PlayerConnect, EventHookMode_Pre);
	
	new String:game_folder[64];
	GetGameFolderName(game_folder, sizeof(game_folder))
	
	if (StrContains(game_folder, "insurgency", false) != -1)
	{
		iSpecTeam = 3;
	}
	else
	{
		new String:game_description[64];
		GetGameDescription(game_description, sizeof(game_description), true);
		if (StrContains(game_description, "Insurgency", false) != -1)
		{
			iSpecTeam = 3;
		}
	}
	
	AutoExecConfig(true, "suppressmessage", "sourcemod");
}

public Action:ev_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new iTeam = GetEventInt(event, "team");
	new String:strTeamName[32];
	GetTeamName(iClient,strTeamName,32);
	
	if (GetConVarBool(cvarBlockSpectateMessage))
	{
		if (!dontBroadcast && !GetEventBool(event, "silent"))
		{
			if (iTeam == iSpecTeam)
			{
				if (iClient != 0)
				{
					if (GetConVarInt(cvarAdminShowMessages) == 1)
					{
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetUserFlagBits(i) != 0)
							{
								PrintToChat(i,"%N joined team %s.", iClient,strTeamName);
								PrintToConsole(i,"%N joined team %s.", iClient,strTeamName);
							}
						}
					}
				}		
				SetEventBroadcast(event, true);
			}
		}
	}
	
	if (GetConVarBool(cvarBlockJoinTeamMessage))
	{
		if(!dontBroadcast && !GetEventBool(event, "silent"))
		{
			if(iTeam != iSpecTeam)
			{
				if(iClient != 0)
				{
					if(GetConVarInt(cvarAdminShowMessages) == 1)
					{
						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetUserFlagBits(i) != 0)
							{
								PrintToConsole(i, "%N joined team %s", iClient, strTeamName);
								PrintToChat(i, "%N joined team %s", iClient, strTeamName);
							}
						}
						SetEventBroadcast(event,true);
					}
				}
			}
		}
	}
		
	return Plugin_Continue;
}
public Action:ev_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarBlockConnectMessage))
	{
		if (!dontBroadcast)
		{
			new iUserId = GetEventInt(event, "userid");
			new iClient = GetClientOfUserId(iUserId);
			decl String:strNetworkId[50];
			GetEventString(event, "networkid", strNetworkId, sizeof(strNetworkId));
			decl String:strAddress[50];
			GetEventString(event, "address", strAddress, sizeof(strAddress));
			
			if (iClient != 0)
			{
				if (GetConVarInt(cvarAdminShowMessages) == 1)
				{
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID)
						{
							PrintToChat(i,"%N has connected.", iClient);
							PrintToConsole(i,"%N has connected.", iClient);
						}
					}
				}
			}
			
			SetEventBroadcast(event, true);
		}
	}
	return Plugin_Continue;
}
public Action:ev_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarBlockDisconnectMessage))
	{		
		if (!dontBroadcast)
		{
			new iUserId = GetEventInt(event, "userid");
			new iClient = GetClientOfUserId(iUserId);
			decl String:strReason[50];
			GetEventString(event, "reason", strReason, sizeof(strReason));
			decl String:strName[50];
			GetEventString(event, "name", strName, sizeof(strName));
			decl String:strNetworkId[50];
			GetEventString(event, "networkid", strNetworkId, sizeof(strNetworkId));
			
			if (iClient != 0)
			{
				if (GetConVarInt(cvarAdminShowMessages) == 1)
				{
					for (new i = 1; i <= MaxClients; i++)
					{
						if (IsClientConnected(i) && IsClientInGame(i) && GetUserFlagBits(i) != 0)
						{
							PrintToChat(i, "%N has left the server.", iClient);
							PrintToConsole(i, "Dropped %N from server (Disconnect by user.)", iClient);
						}
					}
				}
			}
			
			SetEventBroadcast(event, true);
		}
	}
	
	return Plugin_Continue;
}

