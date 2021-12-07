#pragma semicolon 1

#include <sourcemod>

int iWarnings[MAXPLAYERS + 1];

Handle h_iWarnings;

public Plugin:myinfo =
{
	name = "Thirdpersonshoulder Block",
	author = "Don & Lunatix",
	description = "Kicks clients who enable the thirdpersonshoulder mode on L4D1/2 to prevent them from looking around corners, through walls etc.",
	version = "2.0",
	url = "http://forums.alliedmods.net/showthread.php?t=159582 & https://github.com/lunatixxx"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGame[12];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "left4dead") || StrEqual(sGame, "left4dead2"))	/* Only load the plugin if the server is running Left 4 Dead or Left 4 Dead 2.
										 * Loading the plugin on Counter-Strike: Source or Team Fortress 2 would cause all clients to get kicked,
										 * because the thirdpersonshoulder mode and the corresponding ConVar that we check do not exist there.
										 */
	{
		return APLRes_Success;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports L4D1/2");
		return APLRes_Failure;
	}
}

public OnPluginStart()
{
	CreateConVar("l4d_tpsblock_version", "2.0", "Version of the Thirdpersonshoulder Block plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_iWarnings = CreateConVar("sm_tps_kick_warnings", "20", "How many warnings should plugin warn before kicking client", _, true, 1.0);
	CreateTimer(GetRandomFloat(4.5, 5.5), CheckClients, _, TIMER_REPEAT);
}

public Action:CheckClients(Handle:timer)
{
	for (new iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++)
	{
		if (IsClientInGame(iClientIndex) && !IsFakeClient(iClientIndex))
		{
			if (GetClientTeam(iClientIndex) == 2 || GetClientTeam(iClientIndex) == 3)	// Only query clients on survivor or infected team, ignore spectators.
			{
				QueryClientConVar(iClientIndex, "c_thirdpersonshoulder", QueryClientConVarCallback);
			}
		}
	}	
}

public QueryClientConVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (IsClientInGame(client) && !IsClientInKickQueue(client))
	{
		if (result != ConVarQuery_Okay)		/* If the ConVar was somehow not found on the client, is not valid or is protected, kick the client.
							 * The ConVar should always be readable unless the client is trying to prevent it from being read out.
							 */
		{
			new String:sName[MAX_NAME_LENGTH];
			GetClientName(client, sName, sizeof(sName));
			KickClient(client, "Kicked for failing checks on thirdpersonshoulder cvar.");
			LogAction(0, client, "Kicked \"%L\" for potentially using thirdpersonshoulder mode, ConVar c_thirdpersonshoulder not found, not valid or protected", client);
			PrintToChatAll("\x04 %s kicked for failing checks on cvar c_thirdpersonshoulder.\x01", sName);
		}
		else if (!StrEqual(cvarValue, "false") && !StrEqual(cvarValue, "0"))	/* If the ConVar was found on the client, but is not set to either "false" or "0",
											 * kick the client as well, as he might be using thirdpersonshoulder.
											 */
		{
			int iTotalWarnings = GetConVarInt(h_iWarnings);
			
			iWarnings[client]++;
			
			new String:sName[MAX_NAME_LENGTH];
			GetClientName(client, sName, sizeof(sName));
			LogAction(0, client, "Kicked \"%L\" for potentially using thirdpersonshoulder mode", client);
			PrintToChat(client, "\x04You are suspected of using third person view, type c_thirdpersonshoulder 0 in the console or you will be kicked.\x01", iTotalWarnings - iWarnings[client] );
			
			if (iWarnings[client] >= iTotalWarnings)
			{
				KickClient(client, "Kicked for potentially using thirdpersonshoulder mode.\nEnter \"c_thirdpersonshoulder 0\" (without the \"\") in your console before rejoining the server");
				PrintToChatAll("\x04 %s kicked after many warnings to disable third person camera.\x01", sName);
			}
		}
	}
}
