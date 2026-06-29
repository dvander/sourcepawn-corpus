#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <left4dhooks>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION 				"3.6d"
#define CVAR_FLAGS					FCVAR_NOTIFY
#define DELAY_KICK_FAKECLIENT 		0.1
#define DELAY_KICK_NONEEDBOT 		5.0
#define DELAY_KICK_NONEEDBOT_SAFE	25.0
#define DELAY_CHANGETEAM_NEWPLAYER 	1.5
#define TEAM_SPECTATORS 			1
#define TEAM_SURVIVORS 				2
#define TEAM_INFECTED				3
#define DAMAGE_EVENTS_ONLY			1
#define	DAMAGE_YES					2

ConVar hMaxSurvivors, hMaxInfected, hKickIdlers, hDeadBotTime, hSpecCheckInterval, hFirstWeapon, hSecondWeapon, hThirdWeapon, hFourthWeapon, hFifthWeapon, hRespawnHP, hRespawnBuffHP, hStripBotWeapons, hSpawnSurvivorsAtStart;
int iMaxSurvivors, iMaxInfected, iKickIdlers, giIdleTicks[MAXPLAYERS+1], iDeadBotTime, g_iFirstWeapon, g_iSecondWeapon, g_iThirdWeapon, g_iFourthWeapon, g_iFifthWeapon, iRespawnHP, iRespawnBuffHP, g_iRoundStart, g_iPlayerSpawn, BufferHP = -1, iCountDownTime;
Handle SpecCheckTimer = null, timer_KickIdlers = null, PlayerLeftStartTimer = null, CountDownTimer = null;
static Handle hSetHumanSpec, hTakeOverBot;
bool gbVehicleLeaving, gbFirstItemPickedUp, bKill, bLeftSafeRoom, bStripBotWeapons, bSpawnSurvivorsAtStart, bL4D2Version;
float fSpecCheckInterval;

public Plugin myinfo = 
{
	name 			= "[L4D(2)] MultiSlots Improved",
	author 			= "SwiftReal, MI 5, AlexMy, Psykotik, ururu, KhMaIBQ, HarryPotter",
	description 	= "Allows additional survivor/infected players in coop, versus, and survival",
	version 		= PLUGIN_VERSION,
	url 			= "https://forums.alliedmods.net/showthread.php?t=132408"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test == Engine_Left4Dead ) bL4D2Version = false;
	else if( test == Engine_Left4Dead2 ) bL4D2Version = true;
	else {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success; 
}

public void OnPluginStart()
{
	LoadTranslations("l4dmultislots.phrases");
	BufferHP = FindSendPropInfo( "CTerrorPlayer", "m_healthBuffer" );
	CreateConVar("l4d_multislots_version", PLUGIN_VERSION, "L4D(2) MultiSlots version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_REPLICATED);
	SetConVarString(FindConVar("l4d_multislots_version"), PLUGIN_VERSION);
	
	RegAdminCmd("sm_addbot", AddBot, ADMFLAG_KICK, "Attempt to add and teleport a survivor bot");
	RegConsoleCmd("sm_join", JoinTeam, "Attempt to join Survivors");
	
	hMaxSurvivors		= CreateConVar("l4d_multislots_max_survivors",		"4",	"How many survivors allowed?", CVAR_FLAGS, true, 4.0, true, 32.0);
	hMaxInfected		= CreateConVar("l4d_multislots_max_infected",		"4",	"How many infected allowed?", CVAR_FLAGS, true, 4.0, true, 32.0);
	hKickIdlers		= CreateConVar("l4d_multislots_kickafk",		"2",	"Kick idle players? (0 = no  1 = player 5 min, admins kickimmune  2 = player 5 min, admins 10 min)", CVAR_FLAGS, true, 0.0, true, 2.0);
	hStripBotWeapons	= CreateConVar("l4d_multislots_bot_items_delete",	"1",	"Delete all items form survivor bots when they got kicked by this plugin. (0=off)", CVAR_FLAGS, true, 0.0, true, 1.0);
	hDeadBotTime		= CreateConVar("l4d_multislots_alive_bot_time",		"100",	"When 5+ new player joins the server but no any bot can be taken over, the player will appear as a dead survivor if survivors have left start safe area for at least X seconds. (0=Always spawn alive bot for new player)", CVAR_FLAGS, true, 0.0);	
	hSpecCheckInterval	= CreateConVar("l4d_multislots_spec_message_interval",	"20",	"Setup time interval the instruction message to spectator.(0=off)", CVAR_FLAGS, true, 0.0);
	hRespawnHP		= CreateConVar("l4d_multislots_respawnhp",		"80",	"Amount of HP a new 5+ Survivor will spawn with (Def 80)", CVAR_FLAGS, true, 0.0, true, 100.0);
	hRespawnBuffHP		= CreateConVar("l4d_multislots_respawnbuffhp",		"20",	"Amount of buffer HP a new 5+ Survivor will spawn with (Def 20)", CVAR_FLAGS, true, 0.0, true, 100.0);
	hSpawnSurvivorsAtStart	= CreateConVar("l4d_multislots_spawn_survivors_roundstart",	"1",	"If 1, Spawn numbers of survivor bots when round starts. (Numbers depends on Convar l4d_multislots_max_survivors)", CVAR_FLAGS, true, 0.0, true, 1.0);

	if ( bL4D2Version )
	{
		hFirstWeapon 		= CreateConVar("l4d_multislots_firstweapon", 		"10", 	"First slot weapon given to new 5+ Survivor (1-Autoshotgun, 2-SPAS Shotgun, 3-M16, 4-AK47, 5-Desert Rifle, 6-HuntingRifle, 7-Military Sniper, 8-Chrome Shotgun, 9-Silenced Smg, 10=Random T1, 11=Random T2, 0=off)", CVAR_FLAGS, true, 0.0, true, 11.0);
		hSecondWeapon 		= CreateConVar("l4d_multislots_secondweapon", 		"5", 	"Second slot weapon given to new 5+ Survivor (1 - Dual Pistol, 2 - Bat, 3 - Magnum, 4 - Chainsaw, 5=Random, 0=off)", CVAR_FLAGS, true, 0.0, true, 5.0);
		hThirdWeapon 		= CreateConVar("l4d_multislots_thirdweapon", 		"4", 	"Third slot weapon given to new 5+ Survivor (1 - Moltov, 2 - Pipe Bomb, 3 - Bile Jar, 4=Random, 0=off)", CVAR_FLAGS, true, 0.0, true, 4.0);
		hFourthWeapon 		= CreateConVar("l4d_multislots_forthweapon", 		"1", 	"Fourth slot weapon given to new 5+ Survivor (1 - Medkit, 2 - Defib, 3 - Incendiary Pack, 4 - Explosive Pack, 5=Random, 0=off)", CVAR_FLAGS, true, 0.0, true, 5.0);
		hFifthWeapon 		= CreateConVar("l4d_multislots_fifthweapon", 		"0", 	"Fifth slot weapon given to new 5+ Survivor (1 - Pills, 2 - Adrenaline, 3=Random, 0=off)", CVAR_FLAGS, true, 0.0, true, 3.0);
	} 
	else
	{
		hFirstWeapon 		= CreateConVar("l4d_multislots_firstweapon", 		"6", 	"First slot weapon given to new 5+ Survivor (1 - Autoshotgun, 2 - M16, 3 - Hunting Rifle, 4 - smg, 5 - shotgun, 6=Random T1, 7=Random T2, 0=off)", CVAR_FLAGS, true, 0.0, true, 7.0);
		hSecondWeapon 		= CreateConVar("l4d_multislots_secondweapon", 		"1", 	"Second slot weapon given to new 5+ Survivor (1 - Dual Pistol, 0=off)", CVAR_FLAGS, true, 0.0, true, 1.0);
		hThirdWeapon 		= CreateConVar("l4d_multislots_thirdweapon", 		"3", 	"Third slot weapon given to new 5+ SSurvivor (1 - Moltov, 2 - Pipe Bomb, 3=Random, 0=off)", CVAR_FLAGS, true, 0.0, true, 3.0);
		hFourthWeapon 		= CreateConVar("l4d_multislots_forthweapon", 		"1", 	"Fourth slot weapon given to new 5+ SSurvivor (1 - Medkit, 0=off)", CVAR_FLAGS, true, 0.0, true, 1.0);
		hFifthWeapon 		= CreateConVar("l4d_multislots_fifthweapon", 		"0", 	"Fifth slot weapon given to new 5+ Survivor (1 - Pills, 0=off)", CVAR_FLAGS, true, 0.0, true, 1.0);
	}

	GetCvars();
	hMaxSurvivors.AddChangeHook(ConVarChanged_Cvars);
	hMaxInfected.AddChangeHook(ConVarChanged_Cvars);
	hKickIdlers.AddChangeHook(ConVarChanged_Cvars);
	hStripBotWeapons.AddChangeHook(ConVarChanged_Cvars);
	hDeadBotTime.AddChangeHook(ConVarChanged_Cvars);
	hSpecCheckInterval.AddChangeHook(ConVarChanged_Cvars);
	hRespawnHP.AddChangeHook(ConVarChanged_Cvars);
	hRespawnBuffHP.AddChangeHook(ConVarChanged_Cvars);
	hFirstWeapon.AddChangeHook(ConVarChanged_Cvars);
	hSecondWeapon.AddChangeHook(ConVarChanged_Cvars);
	hThirdWeapon.AddChangeHook(ConVarChanged_Cvars);
	hFourthWeapon.AddChangeHook(ConVarChanged_Cvars);
	hFifthWeapon.AddChangeHook(ConVarChanged_Cvars);
	hSpawnSurvivorsAtStart.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("item_pickup", evtRoundStartAndItemPickup);
	HookEvent("survivor_rescued", evtSurvivorRescued);
	HookEvent("finale_vehicle_leaving", evtFinaleVehicleLeaving);
	HookEvent("mission_lost", evtMissionLost);
	HookEvent("player_activate", evtPlayerActivate);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_team", evtPlayerTeam);
	HookEvent("player_spawn", evtPlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("map_transition", Event_RoundEnd);

	Handle hGameConf = LoadGameConfigFile("l4dmultislots");
	if(hGameConf == null)
	{
		SetFailState("Gamedata l4dmultislots.txt not found");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	hSetHumanSpec = EndPrepSDKCall();
	if (hSetHumanSpec == null)
	{
		SetFailState("Cant initialize SetHumanSpec SDKCall");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hTakeOverBot = EndPrepSDKCall();
	if( hTakeOverBot == null)
	{
		SetFailState("Could not prep the \"TakeOverBot\" function.");
		return;
	}
	delete hGameConf;
	
	AutoExecConfig(true, "l4dmultislots");
	
}

public void OnMapStart()
{
	TweakSettings();
	gbFirstItemPickedUp = false;
	StopTimers();
}

public bool OnClientConnect(int client, char [] rejectmsg, int maxlen)
{
	if(client)
	{
		giIdleTicks[client] = 0;
	}
	return true;
}

public void OnMapEnd()
{
	ClearDefault();
	StopTimers();
	ResetTimer();
	gbVehicleLeaving = false;
	gbFirstItemPickedUp = false;
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	iMaxSurvivors = hMaxSurvivors.IntValue;
	iMaxInfected = hMaxInfected.IntValue;
	iKickIdlers = hKickIdlers.IntValue;
	bStripBotWeapons = hStripBotWeapons.BoolValue;
	iDeadBotTime = hDeadBotTime.IntValue;
	fSpecCheckInterval = hSpecCheckInterval.FloatValue;
	bSpawnSurvivorsAtStart = hSpawnSurvivorsAtStart.BoolValue;

	iRespawnHP = hRespawnHP.IntValue;
	iRespawnBuffHP = hRespawnBuffHP.IntValue;
	
	g_iFirstWeapon = hFirstWeapon.IntValue;
	g_iSecondWeapon = hSecondWeapon.IntValue;
	g_iThirdWeapon = hThirdWeapon.IntValue;
	g_iFourthWeapon = hFourthWeapon.IntValue;
	g_iFifthWeapon = hFifthWeapon.IntValue;
}

public Action AddBot(int client, int args)
{
	if(SpawnFakeClientAndTeleport()) 
		PrintToChat(client, "%T", "A surviving Bot was added.", client);
	else
		PrintToChat(client, "%T", "Impossible to generate a bot at the moment.", client);
	
	return Plugin_Handled;
}

public Action JoinTeam(int client, int args)
{
	if(!IsClientConnected(client))
		return Plugin_Handled;
	
	if(IsClientInGame(client))
	{
		if(GetClientTeam(client) == TEAM_SURVIVORS)
		{	
			if(DispatchKeyValue(client, "classname", "player") == true)
			{
				PrintHintText(client, "%T", "You are already on the team of survivors.", client);
			}
			else if((DispatchKeyValue(client, "classname", "info_survivor_position") == true) && !IsPlayerAlive(client))
			{
				PrintHintText(client, "%T", "Please wait to be revived or rescued", client);
			}
		}
		else if(IsClientIdle(client))
		{
			PrintHintText(client, "You are now idle. Press mouse to play as survivor");
		}
		else
		{			
			if(TotalFreeBots() == 0)
			{
				SpawnFakeClientAndTeleport();
				if(bKill && iDeadBotTime > 0) CreateTimer(1.0, Timer_TakeOverBotAndDie, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				else CreateTimer(1.0, Timer_AutoJoinTeam, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);				
			}
			else
				TakeOverBot(client, false);
		}
	}	
	return Plugin_Handled;
}

public void evtRoundStartAndItemPickup(Event event, const char [] name, bool dontBroadcast)
{
	if(!gbFirstItemPickedUp)
	{
		if(timer_KickIdlers == null)
			timer_KickIdlers = CreateTimer(15.0, Timer_KickIdlers, _, TIMER_REPEAT);	
		
		gbFirstItemPickedUp = true;
	}
}

public void evtPlayerActivate(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)
	{
		if(GetClientTeam(client) != TEAM_INFECTED && GetClientTeam(client) != TEAM_SURVIVORS && !IsFakeClient(client) && !IsClientIdle(client))
			CreateTimer(DELAY_CHANGETEAM_NEWPLAYER, Timer_AutoJoinTeam, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void evtPlayerTeam(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int newteam = event.GetInt("team");
	
	if(client)
	{
		if(!IsClientConnected(client))
			return;
		if(!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
			return;
		
		if(newteam == TEAM_INFECTED)
		{
			//PrintToChatAll("\x04[MS] \x03%N, \x01%T", "joined the Infected Team", client);
			giIdleTicks[client] = 0;
		}
	}

	int oldteam = event.GetInt("oldteam");
	if(oldteam == 1 || event.GetBool("disconnect"))
	{
		if(client && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == TEAM_SPECTATORS)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i))
				{
					if(HasEntProp(i, Prop_Send, "m_humanSpectatorUserID"))
					{
						if(GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client)
						{
							//LogMessage("afk player %N changes team or leaves the game, his bot is %N",client,i);
							CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, GetClientUserId(i));
								
							break;
						}
					}
				}
			}
		}
	}
}

public void evtSurvivorRescued(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if(client)
	{
		StripWeapons(client);
		BypassAndExecuteCommand(client, "give", "pistol");
		int random;
		if(bL4D2Version) random = GetRandomInt(1,5);
		else random = GetRandomInt(1,2);
		switch(random)
		{
			case 1: BypassAndExecuteCommand(client, "give", "smg");
			case 2: BypassAndExecuteCommand(client, "give", "pumpshotgun");
			case 3: BypassAndExecuteCommand(client, "give", "smg_silenced");
			case 4: BypassAndExecuteCommand(client, "give", "shotgun_chrome");
			case 5: BypassAndExecuteCommand(client, "give", "smg_mp5");
		}
	}
}

public void evtFinaleVehicleLeaving(Event event, const char [] name, bool dontBroadcast)
{
	int ExtraPlayer = 0;
	int edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index != -1)
	{
		float pos[3];
		GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (ExtraPlayer < 4)
			{
				ExtraPlayer = ExtraPlayer + 1;
				continue;
			}
			if (!IsClientConnected(i)) continue;
			if (!IsClientInGame(i)) continue;
			if (GetClientTeam(i) != TEAM_SURVIVORS) continue;
			
			int survivorPosition = CreateEntityByName("info_survivor_position");
			DispatchSpawn(survivorPosition);
			TeleportEntity(survivorPosition, pos, NULL_VECTOR, NULL_VECTOR);
			
			//TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	ClearDefault();	
	StopTimers();
	gbVehicleLeaving = true;
}

public void evtMissionLost(Event event, const char [] name, bool dontBroadcast)
{
	gbFirstItemPickedUp = false;
	ClearDefault();
}

public void evtBotReplacedPlayer(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("bot"));
	if(GetClientTeam(client) == TEAM_SURVIVORS)
		CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, client);
}

public void evtPlayerSpawn(Event event, const char[] name, bool dontBroadcast) 
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(0.5, PluginStart);
	g_iPlayerSpawn = 1;	
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(0.5, PluginStart);
	g_iRoundStart = 1;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearDefault();
	ResetTimer();
}

public Action PluginStart(Handle timer)
{
	ClearDefault();
	if(bSpawnSurvivorsAtStart) CreateTimer(0.25, Timer_SpawnSurvivorWhenRoundStarts, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if(PlayerLeftStartTimer == null) PlayerLeftStartTimer = CreateTimer(1.0, Timer_PlayerLeftStart, _, TIMER_REPEAT);
	if(SpecCheckTimer == null && fSpecCheckInterval > 0.0) SpecCheckTimer = CreateTimer(fSpecCheckInterval, Timer_SpecCheck, _, TIMER_REPEAT);
}

public Action Timer_SpawnSurvivorWhenRoundStarts(Handle timer, int client)
{
	int team_count = TotalSurvivors();
	//if(team_count < 4) return Plugin_Stop;

	//LogMessage("Spawn Timer_SpawnSurvivorWhenRoundStarts: %d, %d", team_count, iMaxSurvivors);
	if(team_count < iMaxSurvivors)
	{
		team_count++;
		SpawnFakeClient();
		return Plugin_Continue;
	}

	return Plugin_Stop;
}

public Action Timer_PlayerLeftStart(Handle Timer)
{
	if (L4D_HasAnySurvivorLeftSafeArea())
	{
		bLeftSafeRoom = true;
		iCountDownTime = iDeadBotTime;
		if(iCountDownTime > 0)
		{
			if(CountDownTimer == null) CountDownTimer = CreateTimer(1.0, Timer_CountDown, _, TIMER_REPEAT);
		}

		PlayerLeftStartTimer = null;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_CountDown(Handle timer)
{
	if(iCountDownTime <= 0) 
	{
		bKill = true;
		CountDownTimer = null;
		return Plugin_Stop;
	}
	iCountDownTime--;
	return Plugin_Continue;
}

public Action Timer_KickIdlers(Handle timer)
{
	if(gbVehicleLeaving) return Plugin_Stop;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if(GetClientTeam(i) == TEAM_SPECTATORS && !IsFakeClient(i) && !IsClientIdle(i))
			{
				switch(iKickIdlers)
				{
					case 0: {}
					case 1:
					{
						if(GetUserFlagBits(i) == 0)
							giIdleTicks[i]++;
						if(giIdleTicks[i] == 20)
							KickClient(i, "Player idle longer than 5 min.");
					}
					case 2:
					{						
						giIdleTicks[i]++;
						if(GetUserFlagBits(i) == 0)
						{							
							if(giIdleTicks[i] == 20)
								KickClient(i, "Player idle longer than 5 min.");
						}
						else
						{
							if(giIdleTicks[i] == 40)
								KickClient(i, "Admin idle longer than 10 min.");
						}
					}
				}
			}
		}
	}		
	return Plugin_Continue;
}

public Action Timer_SpecCheck(Handle timer)
{
	if(fSpecCheckInterval == 0.0)
	{
		SpecCheckTimer = null;
		return Plugin_Stop;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if(GetClientTeam(i) == TEAM_SPECTATORS && !IsFakeClient(i) && !IsClientIdle(i))
			{
				CPrintToChat(i, "{green}[MS] {lightgreen}%N{default}, %T", i, "Type in chat !join To join the survivors", i);
			}
		}
	}	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			if(GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i) && !IsPlayerAlive(i))
			{
				PrintToChat(i, "\x04[MS] \x03%N\x01, %T", i, "Please wait to be revived or rescued", i);
			}
		}
	}	
	return Plugin_Continue;
}

public Action Timer_AutoJoinTeam(Handle timer, any client)
{
	if(!IsClientConnected(client))
		return Plugin_Stop;
		
	if (IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS && !IsClientIdle(client))
		return Plugin_Stop;
	
	JoinTeam(client, 0);
	return Plugin_Continue;
}

public Action Timer_KickNoNeededBot(Handle timer, any bot)
{
	if(TotalSurvivors() <= iMaxSurvivors)
		return Plugin_Handled;

	if(IsClientConnected(bot) && IsClientInGame(bot))
	{
		if(GetClientTeam(bot) != TEAM_SURVIVORS)
			return Plugin_Handled;
	
		char BotName[100];
		GetClientName(bot, BotName, sizeof(BotName));
		if(StrEqual(BotName, "SurvivorBot", true))
			return Plugin_Handled;

		if(!HasIdlePlayer(bot))
		{
			if(bStripBotWeapons) StripWeapons(bot);
			KickClient(bot, "Kicking No Needed Bot");
		}
	}
	return Plugin_Handled;
}

public Action Timer_KickFakeBot(Handle timer, any bot)
{
	if(IsClientConnected(bot))
	{
		KickClient(bot, "Kicking FakeClient");		
		return Plugin_Stop;
	}	
	return Plugin_Continue;
}

public Action Timer_TakeOverBotAndDie(Handle timer, int client)
{
	if (!IsClientInGame(client)) return Plugin_Stop;

	int team = GetClientTeam(client);
	if(team == TEAM_SPECTATORS)
	{
		if(IsClientIdle(client))
		{
			SDKCall(hTakeOverBot, client, true);
		}
		else
		{
			int bot = FindBotToTakeOver();
			if (bot == 0)
			{
				PrintHintText(client, "%T", "No Bots for replacement.", client);
				return Plugin_Stop;
			}
			SDKCall(hSetHumanSpec, bot, client);
			SDKCall(hTakeOverBot, client, true);
		}

		CreateTimer(1.0, Timer_KillSurvivor, client);
	}
	else if (team == TEAM_SURVIVORS)
	{
		if(IsPlayerAlive(client))
		{
			CreateTimer(0.1, Timer_KillSurvivor, client);
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else if (team == TEAM_INFECTED)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_KillSurvivor(Handle timer, int client)
{
	if(IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS && IsPlayerAlive(client))
	{
		StripWeapons(client);
		ForcePlayerSuicide(client);
		PrintHintText(client, "%T", "The survivors has started the game, please wait to be resurrected or rescued", client);
	}
}
////////////////////////////////////
// stocks
////////////////////////////////////
void ClearDefault()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	bKill = false;
	bLeftSafeRoom = false;
}

void TweakSettings()
{
	Handle hMaxSurvivorsLimitCvar = FindConVar("survivor_limit");
	SetConVarBounds(hMaxSurvivorsLimitCvar,  ConVarBound_Lower, true, 4.0);
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Upper, true, 32.0);
	SetConVarInt(hMaxSurvivorsLimitCvar, iMaxSurvivors);
	
	Handle hMaxInfectedLimitCvar = FindConVar("z_max_player_zombies");
	SetConVarBounds(hMaxInfectedLimitCvar,  ConVarBound_Lower, true, 4.0);
	SetConVarBounds(hMaxInfectedLimitCvar, ConVarBound_Upper, true, 32.0);
	SetConVarInt(hMaxInfectedLimitCvar, iMaxInfected);
	
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000); // allow spawning bots at any time
}

int TakeOverBot(int client, bool completely)
{
	if (!IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS && IsFakeClient(client)) return;
	
	int bot = FindBotToTakeOver();	
	if (bot==0)
	{
		PrintHintText(client, "No survivor bots to take over.");
		return;
	}
	
	if(completely)
	{
		SDKCall(hSetHumanSpec, bot, client);
		SDKCall(hTakeOverBot, client, true);
	}
	else
	{
		SDKCall(hSetHumanSpec, bot, client);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
	}
	return;
}

int FindBotToTakeOver()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsFakeClient(i) && GetClientTeam(i)==TEAM_SURVIVORS && IsPlayerAlive(i) && !HasIdlePlayer(i)) return i;
		}
	}
	return 0;
}

void BypassAndExecuteCommand(int client, char [] strCommand, char [] strParam1)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

void StripWeapons(int client) // strip all items from client
{
	int itemIdx;
	for (int x = 0; x <= 4; x++)
	{
		if((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, itemIdx);
			AcceptEntityInput(itemIdx, "Kill");
		}
	}
}

void SetHealth( int client )
{
	float Buff = GetEntDataFloat( client, BufferHP );

	SetEntProp( client, Prop_Send, "m_iHealth", iRespawnHP, 1 );
	SetEntDataFloat( client, BufferHP, Buff + iRespawnBuffHP, true );
}

void GiveWeapon(int client) // give client weapon
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	int iRandom = g_iThirdWeapon;
	if (bL4D2Version && iRandom == 4) iRandom = GetRandomInt(1,3);
	if (!bL4D2Version && iRandom == 3) iRandom = GetRandomInt(1,2);
	
	switch ( iRandom )
	{
		case 1: FakeClientCommand( client, "give molotov" );
		case 2: FakeClientCommand( client, "give pipe_bomb" );
		case 3: FakeClientCommand( client, "give vomitjar" );
		default: {}//nothing
	}
	
	
	iRandom = g_iFourthWeapon;
	if(bL4D2Version && iRandom == 5) iRandom = GetRandomInt(1,4);
	
	switch ( iRandom )
	{
		case 1: FakeClientCommand( client, "give first_aid_kit" );
		case 2: FakeClientCommand( client, "give defibrillator" );
		case 3: FakeClientCommand( client, "give weapon_upgradepack_incendiary" );
		case 4: FakeClientCommand( client, "give weapon_upgradepack_explosive" );
		default: {}//nothing
	}
	
	iRandom = g_iFifthWeapon;
	if(bL4D2Version && iRandom == 3) iRandom = GetRandomInt(1,2);
	
	switch ( iRandom )
	{
		case 1: FakeClientCommand( client, "give pain_pills" );
		case 2: FakeClientCommand( client, "give adrenaline" );
		default: {}//nothing
	}

	iRandom = g_iSecondWeapon;
	if(bL4D2Version && iRandom == 5) iRandom = GetRandomInt(1,4);
		
	switch ( iRandom )
	{
		case 1:
		{
			FakeClientCommand( client, "give pistol" );
			FakeClientCommand( client, "give pistol" );
		}
		case 2: FakeClientCommand( client, "give baseball_bat" );
		case 3: FakeClientCommand( client, "give pistol_magnum" );
		case 4: FakeClientCommand( client, "give chainsaw" );
		default: {}//nothing
	}

	iRandom = g_iFirstWeapon;
	if(bL4D2Version)
	{
		if(g_iFirstWeapon == 10) iRandom = GetRandomInt(8,9);
		else if(g_iFirstWeapon == 11) iRandom = GetRandomInt(1,7);
		
		switch ( iRandom )
		{
			case 1: FakeClientCommand( client, "give autoshotgun" );
			case 2: FakeClientCommand( client, "give shotgun_spas" );
			case 3: FakeClientCommand( client, "give rifle" );
			case 4: FakeClientCommand( client, "give rifle_ak47" );
			case 5: FakeClientCommand( client, "give rifle_desert" );
			case 6: FakeClientCommand( client, "give hunting_rifle" );
			case 7: FakeClientCommand( client, "give sniper_military" );
			case 8: FakeClientCommand( client, "give shotgun_chrome" );
			case 9: FakeClientCommand( client, "give smg_silenced" );
			default: {}//nothing
		}
	}
	else
	{
		if(g_iFirstWeapon == 6) iRandom = GetRandomInt(4,5);
		else if(g_iFirstWeapon == 7) iRandom = GetRandomInt(1,3);
		
		switch ( iRandom )
		{
			case 1: FakeClientCommand( client, "give autoshotgun" );
			case 2: FakeClientCommand( client, "give rifle" );
			case 3: FakeClientCommand( client, "give hunting_rifle" );
			case 4: FakeClientCommand( client, "give smg" );
			case 5: FakeClientCommand( client, "give pumpshotgun" );
			default: {}//nothing
		}
	}
	
	SetCommandFlags( "give", flags);
}

int TotalSurvivors() // total bots, including players
{
	int a = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
		 	if(GetClientTeam(i) == TEAM_SURVIVORS) a++;
		}
	}
	return a;
}

int TotalFreeBots() // total bots (excl. IDLE players)
{
	int a = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
		 	if(IsFakeClient(i) && GetClientTeam(i) == TEAM_SURVIVORS && !HasIdlePlayer(i)) a++;
		}
	}
	return a;
}

int GetRandomClient(int fakeclient)
{
	int iClientCount, iClients[MAXPLAYERS+1];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i) && i != fakeclient)
		{
			iClients[iClientCount++] = i;
		}
	}
	return (iClientCount == 0) ? 0 : iClients[GetRandomInt(0, iClientCount - 1)];
}

void StopTimers()
{
	delete timer_KickIdlers;
}

void ResetTimer()
{
	delete PlayerLeftStartTimer;
	delete CountDownTimer;
}

bool SpawnFakeClient()
{
	bool fakeclientKicked = false;
	
	int fakeclient = 0;
	fakeclient = CreateFakeClient("SurvivorBot");

	if(fakeclient != 0)
	{
		ChangeClientTeam(fakeclient, TEAM_SURVIVORS);
		
		if(DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			if(DispatchSpawn(fakeclient) == true)
			{	
				CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, fakeclient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				fakeclientKicked = true;
			}
		}			
		if(fakeclientKicked == false)
			KickClient(fakeclient, "Kicking FakeClient");
	}	
	return fakeclientKicked;
}

bool SpawnFakeClientAndTeleport()
{
	bool fakeclientKicked = false;
	int fakeclient = CreateFakeClient("SurvivorBot");
	int iAliveSurvivor = GetRandomClient(fakeclient);
	
	if(fakeclient != 0)
	{
		ChangeClientTeam(fakeclient, TEAM_SURVIVORS);
		
		if(DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			if(DispatchSpawn(fakeclient) == true)
			{
				if (iAliveSurvivor != 0)
				{
					float teleportOrigin[3];
					GetClientAbsOrigin(iAliveSurvivor, teleportOrigin);
					TeleportEntity(fakeclient, teleportOrigin, NULL_VECTOR, NULL_VECTOR);
				}
				StripWeapons(fakeclient);
				GiveWeapon(fakeclient);
				if (bLeftSafeRoom)
					SetHealth( fakeclient );

				CreateTimer(DELAY_KICK_FAKECLIENT, Timer_KickFakeBot, fakeclient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				fakeclientKicked = true;
			}
		}
		if(fakeclientKicked == false)
			KickClient(fakeclient, "Kicking FakeClient");
	}
	return fakeclientKicked;
}

bool HasIdlePlayer(int bot)
{
	if(IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVORS && IsFakeClient(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			if( !GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") )
				return false;
		}
		return true;
	}
	return false;
}

bool IsClientIdle(int client)
{
	if(GetClientTeam(client) != TEAM_SPECTATORS)
		return false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i) && IsFakeClient(i))
		{
			if(HasEntProp(i, Prop_Send, "m_humanSpectatorUserID"))
			{
				if(GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client)
						return true;
			}
		}
	}
	return false;
}
