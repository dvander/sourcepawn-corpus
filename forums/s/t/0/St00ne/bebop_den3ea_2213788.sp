#include <sourcemod>
#include <sdktools>

#define TEAM_SPECTATORS	1
#define TEAM_SURVIVORS	2
#define BEBOP_VERSION	"0.3e beta"

new newMapActivatedPlayers;
new bool:g_GameMode = true;
new Handle:gamemodes;
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hSpec = INVALID_HANDLE;
new Handle:hSwitch = INVALID_HANDLE;

public Plugin:MyInfo = 
{
	name = "bebop",
	author = "frool, Den Marko, St00ne",
	description = "allows \"unlimited\" additional players in coop mode",
	version = BEBOP_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=110210"
};

public OnPluginStart()
{
	hGameConf = LoadGameConfigFile("bebop");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hSpec = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hSwitch = EndPrepSDKCall();

	//GameMode();
	gamemodes = FindConVar("mp_gamemode");
	HookConVarChange(gamemodes,  Event_GameModeChanges);
	HookEvent("player_activate", Event_PlayerActivate);
}

public Event_GameModeChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GameMode()
}

GameMode()
{
	decl String:GameName[64];
	GetConVarString(gamemodes, GameName, sizeof(GameName));
	if((StrEqual(GameName, "coop") == true)
	|| (StrEqual(GameName, "realism") == true)
	|| (StrEqual(GameName, "survival") == true))
	{
		g_GameMode = true;
	}
	else if((StrEqual(GameName, "versus") == true)
	|| (StrEqual(GameName, "teamversus") == true)
	|| (StrEqual(GameName, "scavenge") == true)
	|| (StrEqual(GameName, "teamscavenge") == true))
	{
		g_GameMode = false;
	}
}

public OnMapEnd()
{	
	newMapActivatedPlayers = 0;
}

public OnClientDisconnect(client)
{
	GameMode();
	
	if(g_GameMode)
	{
		if(newMapActivatedPlayers > 4)
		{
			if (!IsFakeClient(client))
			{
				new count = GetHumanInGamePlayerCount() - 1;
				if(count >= 4)
				{
					CreateTimer(1.0, Timer_KickNoMoreNeededBot, 0, TIMER_REPEAT);
				}
			}
		}
	}
}

public Event_PlayerActivate(Handle: event, const String:name[], bool:dontBroadcast)
{
	GameMode();
	
	if(g_GameMode)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!IsFakeClient(client))
		{
			newMapActivatedPlayers++;
			new count = GetHumanInGamePlayerCount();
			if (count > 4 && newMapActivatedPlayers > 4 && (GetClientTeam(client) != TEAM_SURVIVORS || GetClientTeam(client) == TEAM_SPECTATORS))
			{
				SpawnFakeClient();
				CreateTimer(10.0, Timer_PutClientToSurvivorTeam, GetClientSerial(client), TIMER_REPEAT);
			}
		}
	}
}

public Action:Timer_PutClientToSurvivorTeam(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (client && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetClientTeam(client) == TEAM_SPECTATORS)
		{
			new bot = GetABot();
			if(bot)
			{
				SDKCall(hSpec, bot, client);
				SDKCall(hSwitch, client, true);
			}
		}
	}
	return Plugin_Stop;
}

GetABot()
{
	new r=0;
	new bots=0;
	for(new i=1; i<MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS) 
		{
			if( IsFakeClient(i) ) r=i;
			bots++;
		}
	}
	return r;
}

public Action:Timer_KickNoMoreNeededBot(Handle:timer, any:data)
{
	new String:	clientname[256];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (IsFakeClient(i) && (GetClientTeam(i) == TEAM_SURVIVORS))
			{
				if(HasIdlePlayer(i))
				{
					GetClientName(i, clientname, sizeof(clientname));
					if (StrEqual(clientname, "NewBot", true))
					{
						continue;
					}
					KickClient(i, "client_is_NewBot");
					break;
				}
			}
		}
	}
	return Plugin_Stop;
}

public Action:Timer_KickFakeClient(Handle:timer, any:serial)
{
	new client = GetClientFromSerial(serial);
	if (IsClientConnected(client))
	{
		KickClient(client, "client_is_NewBot");
	}
	return Plugin_Stop;
}

GetHumanInGamePlayerCount()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			if (!IsFakeClient(i))
			{
				if (IsClientInGame(i))
				{
					count++;
				}
			}
		}
	}
	return count;
}

bool:SpawnFakeClient()
{
	new bool:ret = false;
	new client = 0;
	client = CreateFakeClient("NewBot");
	if (client != 0)
	{
		ChangeClientTeam(client, 2);
		if (DispatchKeyValue(client, "classname", "survivorbot") == true)
		{
			if (DispatchSpawn(client) == true)
			{
				CreateTimer(1.0, Timer_KickFakeClient, GetClientSerial(client), TIMER_REPEAT);
				ret = true;
			}
		}
		if (ret == false)
		{
			KickClient(client, "");
		}
	}
	return ret;
}

stock bool:HasIdlePlayer(bot)
{
	if(IsValidEntity(bot))
	{
		if(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") == 0)
		{
			return true;
		}
		else return false;
	}
	
	return false;
}

//***END***///