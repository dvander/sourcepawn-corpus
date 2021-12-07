#include <sourcemod>
#include <sdktools>

#define TEAM_SPECTATORS	1
#define TEAM_SURVIVORS	2
#define BEBOP_VERSION	"0.2 beta"

new newMapActivatedPlayers;
new g_GameMode;
Handle hGameConf = null;
Handle hSpec = null;
Handle hSwitch = null;
ConVar hGameMode;

public Plugin:MyInfo = 
{
	name = "bebop",
	author = "frool, Den Marko",
	description = "allows \"unlimited\" additional players playing in coop mode",
	version = BEBOP_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=110210"
}

public OnPluginStart()
{
	hGameConf = LoadGameConfigFile("bebop");
	if(hGameConf != null)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();
		if(hSpec == null) LogError("L4D_SM_bebop: SetHumanSpec Signature broken");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSwitch = EndPrepSDKCall();
		if(hSwitch == null) LogError("L4D_SM_bebop: TakeOverBot Signature broken");
	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/bebop.txt , you FAILED AT INSTALLING");
	}
	
	hGameMode = FindConVar("mp_gamemode");
	hGameMode.AddChangeHook(pointer_GameMode);
	
	GameMode();
	HookEvent("player_activate", Event_PlayerActivate, EventHookMode_Post);
}

public pointer_GameMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (strcmp(oldValue, newValue) != 0)
	{
		char GameName[64];
		hGameMode.GetString(GameName, sizeof(GameName));
		if((strcmp(GameName, "coop", false) == 0) 
		|| (strcmp(GameName, "realism", false) == 0) 
		|| (strcmp(GameName, "survival", false) == 0))
		{
			g_GameMode = true;
		}
		else if((strcmp(GameName, "versus", false) == 0) 
		|| (strcmp(GameName, "teamversus", false) == 0) 
		|| (strcmp(GameName, "scavenge", false) == 0) 
		|| (strcmp(GameName, "teamscavenge", false) == 0))
		{
			g_GameMode = false;
		}
	}
}

GameMode()
{
	char gameDir[64];
	static bool:isL4D2 = false, flags;

	GetGameFolderName(gameDir, sizeof(gameDir));
	if (StrEqual(gameDir, "left4dead2"))
	{	
		isL4D2 = true;
		flags = hGameMode.Flags;
		hGameMode.Flags = flags & ~FCVAR_PROTECTED;
	}

	if (isL4D2 == true)
	{
		hGameMode.Flags = flags;	
	}
}

public void OnMapEnd()
{	
	newMapActivatedPlayers = 0;
}

public void OnClientDisconnect(client)
{
	if(!g_GameMode) return;
	if(newMapActivatedPlayers <= 4) return;
	if (!IsFakeClient(client))
	{
		int count = GetHumanInGamePlayerCount() - 1;
		if(count >= 4)
		{
			CreateTimer(0.5, Timer_KickNoMoreNeededBot, TIMER_REPEAT);
		}
	}
	return;
}

public Event_PlayerActivate(Event event, const String:name[], bool:dontBroadcast)
{
	if(!g_GameMode) return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsFakeClient(client))
	{
		newMapActivatedPlayers++;
		new count = GetHumanInGamePlayerCount();
		if (client && count > 4 && newMapActivatedPlayers > 4 && (GetClientTeam(client) != TEAM_SURVIVORS || GetClientTeam(client) == TEAM_SPECTATORS))
		{
			SpawnFakeClient();
			CreateTimer(10.0, Timer_PutClientToSurvivorTeam, client, TIMER_REPEAT);
		}
	}
	return;
}

public Action:Timer_PutClientToSurvivorTeam(Handle timer, any client)
{
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
	// new bots=0;
	for(new i=1; i<MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if(IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVORS)
			{
				if(HasIdlePlayer(i))
				{
					r = i;
					break;
				}
			}
		}
		// if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS) 
		// {
			// if( IsFakeClient(i) ) r=i;
			// bots++;
		// }
	}
	return r;
}

public Action:Timer_KickNoMoreNeededBot(Handle timer)
{
	decl String:clientname[256];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
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

public Action:Timer_KickFakeClient(Handle:timer, any:client)
{
	if (IsClientConnected(client)) KickClient(client, "survivor bot left the survivor team");
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
	client = CreateFakeClient("New_Bot");
	if (client != 0)
	{
		ChangeClientTeam(client, 2);
		if (DispatchKeyValue(client, "classname", "survivorbot") == true)
		{
			if (DispatchSpawn(client) == true)
			{
				CreateTimer(1.0, Timer_KickFakeClient, client, TIMER_REPEAT);
				ret = true;
			}
		}
		if(ret == false) KickClient(client, "");
	}
	return ret;
}

stock bool:HasIdlePlayer(bot)
{
	if(IsValidEntity(bot))
	{
		decl String:sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));
		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			if(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") == 0)
			{
				return true;
			}
			else return false;		
		}
		else return false
	}
	return false;
}
