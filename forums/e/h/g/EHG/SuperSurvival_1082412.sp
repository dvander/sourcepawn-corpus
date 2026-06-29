#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include "left4downtown.inc"

#define ID_TEAM_SURVIVOR					2
#define DELAY_KICK_FAKE_CLIENT		0.5

#define L4D_MAXCLIENTS MaxClients
#define L4D_MAXCLIENTS_PLUS1 (L4D_MAXCLIENTS + 1)

#define PLUGIN_VERSION			"1.4"


new Handle:cvarGameMode = INVALID_HANDLE;
new bool:IsBeingManaged[MAXPLAYERS];
new Float:AbsOrigin[3];
new Float:EyeAngles[3];
new Float:Velocity[3];
new bool:allowBotSpawns;
new String:team;

new Handle:gConf = INVALID_HANDLE;
new Handle:fSHS = INVALID_HANDLE;
new Handle:fTOB = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Super Survival",
	author = "EHG",
	description = "Have more than 4 players in survival with no crash at end",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	PrepareAllSDKCalls();
	
	RegAdminCmd("sm_reloadround", FakeRestartVoteCampaign, ADMFLAG_CHANGEMAP, "executes a restart campaign vote and makes everyone votes yes");
	RegAdminCmd("sm_sb_takecontrol", Command_SBcontrol, ADMFLAG_ROOT, "Move player to survivor team and make him take over a bot or create a new one to take over");
	RegAdminCmd("sm_addbot", Command_SBadd, ADMFLAG_ROOT, "Add a bot at spawn");
	RegAdminCmd("sm_addbothere", Command_SBaddhere, ADMFLAG_ROOT, "Add a bot at your location");
	RegAdminCmd("sm_ss_kickextra", Command_KickExtraBots, ADMFLAG_ROOT, "Kick all extra bots");
	RegAdminCmd("sm_ss_moveinfected", Command_moveplayers, ADMFLAG_ROOT, "Move players from infected to survivor team");
	
	CreateConVar("l4d_supersurvival_version", PLUGIN_VERSION, "Super Survival Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);
	
	HookEvent("player_death", Event_PlayerCheck);
	HookEvent("player_incapacitated", Event_PlayerCheck);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start",Event_RoundStart);
	
	cvarGameMode = FindConVar("mp_gamemode");
}

PrepareAllSDKCalls()
{
	gConf = LoadGameConfigFile("left4downtown.l4d2");
	if(gConf == INVALID_HANDLE)
	{
		ThrowError("Could not load gamedata/left4downtown.l4d2.txt");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	fSHS = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	fTOB = EndPrepSDKCall();
}


public OnMapStart()
{
	if (IsSurvivalMode())
	{
		allowBotSpawns = false;
	}
}


public Action:Command_KickExtraBots(client, args)
{
	KickExtraBots();
	PrintToChat(client, "[SM] Extra Bots kicked");
	return Plugin_Handled;
}

public Action:Command_moveplayers(client, args)
{
	ManageMoveTeam();
	PrintToChat(client, "[SM] Infected players moved to survivor team");
	return Plugin_Handled;
}



public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	KickExtraBots();
}



KickExtraBots()
{
	new teamcount = GetTeamClientCount(2);
	if (teamcount > 4 && IsSurvivalMode() && teamcount > Players())
	{
		new origin_bots = 4 - Players();
		if (origin_bots < 0)
		{
			origin_bots = 0;
		}
		new kick_count = BotSurvivors() - origin_bots;
		for(;kick_count>0; kick_count--) KickABot();
	}
}

bool:KickABot()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientConnected(i) && !IsClientInKickQueue(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2)
		{
			KickClient(i);
			return true;
		}
	}
	return false;
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(client) && IsSurvivalMode())
	{
		allowBotSpawns = true;
	}
	team = GetClientTeam(client);
	if (Players() > 4 && IsSurvivalMode())
	{
		ManageMoveTeam();
	}
}


public OnClientAuthorized(client)
{
	if (!IsFakeClient(client) && IsSurvivalMode())
	{
		if (Players() > 4)
		{
			IsBeingManaged[client] = true;
			CreateTimer(0.1, ManageBotDelay, client, TIMER_REPEAT);
			
			SetConVarInt(FindConVar("director_no_death_check"), 1);
		}
		else
		{
			SetConVarInt(FindConVar("director_no_death_check"), 0);
		}
	}
}

public Action:ManageBotDelay(Handle:timer, any:client)
{
	if (allowBotSpawns)
	{
		CreateTimer(1.0, TakeOverBot, client, TIMER_REPEAT);
		CreateTimer(2.0, ManageMoveTeamDelay, 0);
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action:ManageMoveTeamDelay(Handle:timer)
{
	ManageMoveTeam();
}

ManageMoveTeam()
{
	for(new i = 1; i <= MaxClients; ++i)
	{
		team = GetClientTeam(i);
		if (!IsFakeClient(i) && IsSurvivalMode() && IsClientInGame(i) && team == 3 && IsBeingManaged[i] != true && GetUserAdmin(i) == INVALID_ADMIN_ID)
		{
			ChangePlayerTeam(i);
		}
	}
}
	
public Action:TakeOverBot(Handle:timer, any:client)
{
	team = GetClientTeam(client);
	if (IsClientInGame(client) && team > 0 && team < 4)
	{
		ChangePlayerTeam(client);
		IsBeingManaged[client] = false;
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}


public Action:Command_SBadd(client, args)
{
	SpawnSurvivorFakeClient();
	return Plugin_Handled;
}


public Action:Command_SBaddhere(client, args)
{
	SpawnSurvivorFakeClientHere(client);
	return Plugin_Handled;
}

public Action:Command_SBcontrol(client, args)
{
	if (!client) return Plugin_Handled;
	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_sb_takecontrol <player>");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	
	for (new i = 0; i < target_count; i++)
	{
		if(target_list[i] == -1 || target_list[i] == 0 || !IsClientInGame(target_list[i]) || !IsValidEntity(target_list[i]) || IsFakeClient(target_list[i]) || GetClientTeam(target_list[i]) == 2)
		{
			continue;
		}
		ChangePlayerTeam(target_list[i]);
	}
	
	return Plugin_Handled;
}




stock bool:ChangePlayerTeam(client)
{
	if (GetClientTeam(client) == ID_TEAM_SURVIVOR)
	{
		return false;
	}
	new bot;
	for(bot = 1; 
	bot < L4D_MAXCLIENTS_PLUS1 && (!IsClientConnected(bot) || !IsFakeClient(bot) || (GetClientTeam(bot) != ID_TEAM_SURVIVOR));
	bot++) {}
	
	if(bot == L4D_MAXCLIENTS_PLUS1)
	{
		SpawnSurvivorFakeClient();
		CreateTimer(1.5, Timer_DelayChangeTeamLoop, client);
		return false;
	}
	
	
	SDKCall(fSHS, bot, client);
	SDKCall(fTOB, client, true);
	
	return true;
}

public Action:Timer_DelayChangeTeamLoop(Handle:timer, any:client)
{
	ChangePlayerTeam(client);
}



bool:SpawnSurvivorFakeClient()
{
	// init ret value
	new bool:ret = false;
	
	// create fake client
	new client = 0;
	client = CreateFakeClient("Survivor");
	
	// if entity is valid
	if (client != 0)
	{
		// move into survivor team
		ChangeClientTeam(client, ID_TEAM_SURVIVOR);
		//FakeClientCommand(client, "jointeam %i", ID_TEAM_SURVIVOR);
		
		// set entity classname to survivorbot
		if (DispatchKeyValue(client, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(client) == true)
			{
				
				CreateTimer(DELAY_KICK_FAKE_CLIENT, Timer_KickFakeClient, client, TIMER_REPEAT);
				ret = true;
			}
		}
		
		// if something went wrong kick the created fake client
		if (ret == false)
		{
			KickClient(client, "");
		}
	}
	
	return ret;
}

bool:SpawnSurvivorFakeClientHere(player)
{
	// init ret value
	new bool:ret = false;
	
	// create fake client
	new client = 0;
	client = CreateFakeClient("Survivor");
	
	// if entity is valid
	if (client != 0)
	{
		// move into survivor team
		ChangeClientTeam(client, ID_TEAM_SURVIVOR);
		//FakeClientCommand(client, "jointeam %i", ID_TEAM_SURVIVOR);
		
		// set entity classname to survivorbot
		if (DispatchKeyValue(client, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(client) == true)
			{
				
				GetClientAbsOrigin(player, AbsOrigin);
				GetClientEyeAngles(player, EyeAngles);
				Velocity[0] = GetEntPropFloat(player, Prop_Send, "m_vecVelocity[0]");
				Velocity[1] = GetEntPropFloat(player, Prop_Send, "m_vecVelocity[1]");
				Velocity[2] = GetEntPropFloat(player, Prop_Send, "m_vecVelocity[2]");
				CreateTimer(0.1, TeleportDelay, client);
				
				CreateTimer(DELAY_KICK_FAKE_CLIENT, Timer_KickFakeClient, client, TIMER_REPEAT);
				ret = true;
			}
		}
		
		// if something went wrong kick the created fake client
		if (ret == false)
		{
			KickClient(client, "");
		}
	}
	
	return ret;
}

public Action:TeleportDelay(Handle:timer, any:client)
{
	TeleportEntity(client, AbsOrigin, EyeAngles, Velocity);
}

public Action:Timer_KickFakeClient(Handle:timer, any:client)
{
	if (IsClientConnected(client))
	{
		KickClient(client, "client_is_fakeclient");
	}
	
	return Plugin_Stop;
}


public Action:Event_PlayerCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsFakeClient(client))
	{
		if (Players() > 4 && IsSurvivalMode())
		{
			SetConVarInt(FindConVar("director_no_death_check"), 1);
			if (!AnySurvivorAlive())
			{
				CreateTimer(2.0, RestartDelay);
			}
		}
		else
		{
			SetConVarInt(FindConVar("director_no_death_check"), 0);
		}
	}
	return Plugin_Continue;
}

bool:IsSurvivalMode()
{
	decl String:sGameMode[32];
	GetConVarString(cvarGameMode, sGameMode, sizeof(sGameMode));
	if (StrContains(sGameMode, "survival") > -1)
	{
		return true;
	}
	else
	{
		return false;
	}	
}


bool:AnySurvivorAlive()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if ( IsClientInGame(client) &&
		     (GetClientTeam(client) == 2) &&
		     IsPlayerAlive(client) &&
		     GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 0)
			return true;
	}

	return false;
}


Players() {
	new players;
	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientAuthorized(client) && !IsFakeClient(client)) {
			players++;
		}
	}

	return players;
}

BotSurvivors() {
	new Survivors;
	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientAuthorized(client) && IsFakeClient(client) && GetClientTeam(client) == 2) {
			Survivors++;
		}
	}

	return Survivors;
}


public Action:FakeRestartVoteCampaign(client, args)
{
	RestartCampaignAny();
	return Plugin_Handled;
}

public Action:RestartDelay(Handle:timer, any:client)
{
	RestartCampaignAny();
	return Plugin_Handled;
}

RestartCampaignAny()
{	
	decl String:currentmap[128];
	GetCurrentMap(currentmap, sizeof(currentmap));
	L4D_RestartScenarioFromVote(currentmap);
}