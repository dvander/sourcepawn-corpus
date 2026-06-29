#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION 				"1.0"
#define CVAR_FLAGS					FCVAR_PLUGIN|FCVAR_NOTIFY
#define DELAY_KICK_FAKECLIENT 		0.1
#define DELAY_KICK_NONEEDBOT 		5.0
#define DELAY_CHANGETEAM_NEWPLAYER 	1.5
#define TEAM_SPECTATORS 			1
#define TEAM_SURVIVORS 				2
#define TEAM_INFECTED				3
#define DAMAGE_EVENTS_ONLY			1
#define	DAMAGE_YES					2

Handle hMaxSurvivors, hMaxInfected, timer_SpawnTick = null, timer_SpecCheck = null, hKickIdlers;
bool gbVehicleLeaving, gbPlayedAsSurvivorBefore[MAXPLAYERS+1], gbFirstItemPickedUp, gbPlayerPickedUpFirstItem[MAXPLAYERS+1];
char gMapName[128];
int giIdleTicks[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name 			= "[L4D(2)] MultiSlots",
	author 			= "SwiftReal, MI 5, AlexMy",
	description 	= "Allows additional survivor/infected players in coop, versus, and survival",
	version 		= PLUGIN_VERSION,
	url 			= "N/A"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max) 
{
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure; 
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	CreateConVar("l4d_multislots_version", PLUGIN_VERSION, "L4D(2) MultiSlots version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_REPLICATED);
	SetConVarString(FindConVar("l4d_multislots_version"), PLUGIN_VERSION);
	
	RegAdminCmd("sm_addbot", AddBot, ADMFLAG_KICK, "Attempt to add and teleport a survivor bot");
	RegConsoleCmd("sm_join", JoinTeam, "Attempt to join Survivors");
	
	hMaxSurvivors	= CreateConVar("l4d_multislots_max_survivors", "8", "How many survivors allowed?", CVAR_FLAGS, true, 4.0, true, 32.0);
	hMaxInfected	= CreateConVar("l4d_multislots_max_infected", "8", "How many infected allowed?", CVAR_FLAGS, true, 4.0, true, 32.0);
	hKickIdlers 	= CreateConVar("l4d_multislots_kickafk", "2", "Kick idle players? (0 = no  1 = player 5 min, admins kickimmune  2 = player 5 min, admins 10 min)", CVAR_FLAGS, true, 0.0, true, 2.0);
	
	HookEvent("item_pickup", evtRoundStartAndItemPickup);
	HookEvent("player_left_start_area", evtPlayerLeftStart);
	HookEvent("survivor_rescued", evtSurvivorRescued);
	HookEvent("finale_vehicle_leaving", evtFinaleVehicleLeaving);
	HookEvent("mission_lost", evtMissionLost);
	HookEvent("player_activate", evtPlayerActivate);
	HookEvent("bot_player_replace", evtPlayerReplacedBot);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_team", evtPlayerTeam);
	
	AutoExecConfig(true, "l4dmultislots");
	
}

public void OnMapStart()
{
	GetCurrentMap(gMapName, sizeof(gMapName));
	TweakSettings();
	gbFirstItemPickedUp = false;
	StopTimers();
}

public bool OnClientConnect(int client, char [] rejectmsg, int maxlen)
{
	if(client)
	{
		gbPlayedAsSurvivorBefore[client] = false;
		gbPlayerPickedUpFirstItem[client] = false;
		giIdleTicks[client] = 0;
	}
	return true;
}

public void OnClientDisconnect(int client)
{
	gbPlayedAsSurvivorBefore[client] = false;
	gbPlayerPickedUpFirstItem[client] = false;
}

public void OnMapEnd()
{
	StopTimers();
	gbVehicleLeaving = false;
	gbFirstItemPickedUp = false;
}

public Action AddBot(int client, int args)
{
	if(SpawnFakeClientAndTeleport()) PrintToChatAll("Survivor bot spawned and teleported.");
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
				PrintHintText(client, "You are allready joined the Survivor team");
			}
			else if((DispatchKeyValue(client, "classname", "info_survivor_position") == true) && !IsAlive(client))
			{
				PrintHintText(client, "Please wait to be revived or rescued");
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
				CreateTimer(1.0, Timer_AutoJoinTeam, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);				
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
		if(timer_SpecCheck == null)
			timer_SpecCheck = CreateTimer(15.0, Timer_SpecCheck, _, TIMER_REPEAT);	
		
		gbFirstItemPickedUp = true;
	}
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!gbPlayerPickedUpFirstItem[client] && !IsFakeClient(client))
	{
		gbPlayerPickedUpFirstItem[client] = true;
		gbPlayedAsSurvivorBefore[client] = true;
	}
}

public void evtPlayerActivate(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)
	{
		if((GetClientTeam(client) != TEAM_INFECTED) && (GetClientTeam(client) != TEAM_SURVIVORS) && !IsFakeClient(client) && !IsClientIdle(client))
			CreateTimer(DELAY_CHANGETEAM_NEWPLAYER, Timer_AutoJoinTeam, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}
public void evtPlayerLeftStart(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)
	{
		if(IsClientConnected(client) && IsClientInGame(client))
		{
			if(GetClientTeam(client)==TEAM_SURVIVORS)
				gbPlayedAsSurvivorBefore[client] = true;
		}
	}
}

public void evtPlayerTeam(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int newteam = GetEventInt(event, "team");
	
	if(client)
	{
		if(!IsClientConnected(client) || !IsClientInGame(client) || IsFakeClient(client) || !IsAlive(client)) return;
		
		if(newteam == TEAM_INFECTED)
		{
			char PlayerName[100];
			GetClientName(client, PlayerName, sizeof(PlayerName));
			PrintToChatAll("\x01[\x04MultiSlots\x01] %s joined the Infected Team", PlayerName);
			giIdleTicks[client] = 0;
		}
	}
}

public void evtPlayerReplacedBot(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	if(!client) return;
	if(GetClientTeam(client)!=TEAM_SURVIVORS || IsFakeClient(client)) return;
	
	if(!gbPlayedAsSurvivorBefore[client])
	{
		gbPlayedAsSurvivorBefore[client] = true;
		giIdleTicks[client] = 0;
		
		BypassAndExecuteCommand(client, "give", "health");
		
		char GameMode[30];
		GetConVarString(FindConVar("mp_gamemode"), GameMode, sizeof(GameMode));			
		if(StrEqual(GameMode, "mutation3", false))
		{
			SetEntityHealth(client, 1);
			SetEntityTempHealth(client, 99);
		}
		else
		{
			SetEntityHealth(client, 100);
			SetEntityTempHealth(client, 0);			
			GiveMedkit(client);
		}
		
		char PlayerName[100];
		GetClientName(client, PlayerName, sizeof(PlayerName));
		PrintToChatAll("\x01[\x04MultiSlots\x01] %s joined the Survivor Team", PlayerName);
	}
}

public void evtSurvivorRescued(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if(client)
	{	
		StripWeapons(client);
		BypassAndExecuteCommand(client, "give", "pistol_magnum");
		if(StrContains(gMapName, "c1m1", false) == -1)
			GiveWeapon(client);
	}
}

public void evtFinaleVehicleLeaving(Event event, const char [] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsAlive(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY, 1);
			float newOrigin[3] = { 0.0, 0.0, 0.0 };
			TeleportEntity(i, newOrigin, NULL_VECTOR, NULL_VECTOR);
			SetEntProp(i, Prop_Data, "m_takedamage", DAMAGE_YES, 1);
		}
	}	
	StopTimers();
	gbVehicleLeaving = true;
}

public void evtMissionLost(Event event, const char [] name, bool dontBroadcast)
{
	gbFirstItemPickedUp = false;
}

public void evtBotReplacedPlayer(Event event, const char [] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	if(GetClientTeam(bot) == TEAM_SURVIVORS)
		CreateTimer(DELAY_KICK_NONEEDBOT, Timer_KickNoNeededBot, bot, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_SpawnTick(Handle timer)
{
	int iTotalSurvivors = TotalSurvivors();
	if(iTotalSurvivors >= 4)
	{
		timer_SpawnTick = null;		
		return Plugin_Stop;
	}
	
	for(; iTotalSurvivors < 4; iTotalSurvivors++)
		SpawnFakeClient();
	
	return Plugin_Continue;
}

public Action Timer_SpecCheck(Handle timer)
{
	if(gbVehicleLeaving) return Plugin_Stop;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_SPECTATORS && !IsFakeClient(i) && !IsClientIdle(i))
		{
			char PlayerName[100];
			GetClientName(i, PlayerName, sizeof(PlayerName));
			PrintToChat(i, "\x01[\x04MultiSlots\x01] %s, type \x03!join\x01 to join the Survivor Team", PlayerName);
			{
				switch(GetConVarInt(hKickIdlers))
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
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i) && !IsAlive(i))
		{
			char PlayerName[100];
			GetClientName(i, PlayerName, sizeof(PlayerName));
			PrintToChat(i, "\x01[\x04MultiSlots\x01] %s, please wait to be revived or rescued", PlayerName);
		}
	}	
	return Plugin_Continue;
}

public Action Timer_AutoJoinTeam(Handle timer, any client)
{
	if(!IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS && IsClientIdle(client)) return Plugin_Stop;
	{
		JoinTeam(client, 0);
	}
	return Plugin_Continue;
}

public Action Timer_KickNoNeededBot(Handle timer, any bot)
{
	if((TotalSurvivors() <= 4))
		return Plugin_Handled;
	
	if(IsClientConnected(bot) && IsClientInGame(bot))
	{
		if(GetClientTeam(bot) == TEAM_INFECTED)
			return Plugin_Handled;
		
		char BotName[100];
		GetClientName(bot, BotName, sizeof(BotName));				
		if(StrEqual(BotName, "FakeClient", true))
			return Plugin_Handled;
		
		if(!HasIdlePlayer(bot))
		{
			StripWeapons(bot);
			KickClient(bot, "Kicking No Needed Bot");
		}
	}	
	return Plugin_Handled;
}

public Action Timer_KickFakeBot(Handle timer, any fakeclient)
{
	if(IsClientConnected(fakeclient))
	{
		KickClient(fakeclient, "Kicking FakeClient");		
		return Plugin_Stop;
	}	
	return Plugin_Continue;
}
////////////////////////////////////
// stocks
////////////////////////////////////
stock void TweakSettings()
{
	Handle hMaxSurvivorsLimitCvar = FindConVar("survivor_limit");
	SetConVarBounds(hMaxSurvivorsLimitCvar,  ConVarBound_Lower, true, 4.0);
	SetConVarBounds(hMaxSurvivorsLimitCvar, ConVarBound_Upper, true, 32.0);
	SetConVarInt(hMaxSurvivorsLimitCvar, GetConVarInt(hMaxSurvivors));
	
	Handle hMaxInfectedLimitCvar = FindConVar("z_max_player_zombies");
	SetConVarBounds(hMaxInfectedLimitCvar,  ConVarBound_Lower, true, 4.0);
	SetConVarBounds(hMaxInfectedLimitCvar, ConVarBound_Upper, true, 32.0);
	SetConVarInt(hMaxInfectedLimitCvar, GetConVarInt(hMaxInfected));
	
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000); // allow spawning bots at any time
}

stock int TakeOverBot(int client, bool completely)
{
	if (!IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS && IsFakeClient(client)) return;
	
	int bot = FindBotToTakeOver();	
	if (bot==0)
	{
		PrintHintText(client, "No survivor bots to take over.");
		return;
	}
	
	static Handle hSetHumanSpec;
	if (hSetHumanSpec == INVALID_HANDLE)
	{
		Handle hGameConf;		
		hGameConf = LoadGameConfigFile("l4dmultislots");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSetHumanSpec = EndPrepSDKCall();
	}
	
	static Handle hTakeOverBot;
	if (hTakeOverBot == INVALID_HANDLE)
	{
		Handle hGameConf;		
		hGameConf = LoadGameConfigFile("l4dmultislots");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hTakeOverBot = EndPrepSDKCall();
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

stock int FindBotToTakeOver()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i)==TEAM_SURVIVORS && IsAlive(i) && !HasIdlePlayer(i)) return i;
	}
	return 0;
}

stock void SetEntityTempHealth(int client, int hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	float newOverheal = hp * 1.0; // prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

stock void BypassAndExecuteCommand(int client, char [] strCommand, char [] strParam1)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

stock void StripWeapons(int client) // strip all items from client
{
	int itemIdx;
	for (int x = 0; x <= 3; x++)
	{
		if((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, itemIdx);
			RemoveEdict(itemIdx);
		}
	}
}

stock void GiveWeapon(int client) // give client random weapon
{
	switch(GetRandomInt(0,6))
	{
		case 0: BypassAndExecuteCommand(client, "give", "smg");
		case 1: BypassAndExecuteCommand(client, "give", "smg_silenced");
		case 2: BypassAndExecuteCommand(client, "give", "smg_mp5");
		case 3: BypassAndExecuteCommand(client, "give", "rifle");
		case 4: BypassAndExecuteCommand(client, "give", "rifle_ak47");
		case 5: BypassAndExecuteCommand(client, "give", "rifle_sg552");
		case 6: BypassAndExecuteCommand(client, "give", "rifle_desert");
	}	
	BypassAndExecuteCommand(client, "give", "ammo");
}

stock void GiveMedkit(int client)
{
	int ent = GetPlayerWeaponSlot(client, 3);
	if(IsValidEdict(ent))
	{
		char sClass[128];
		GetEdictClassname(ent, sClass, sizeof(sClass));
		if(!StrEqual(sClass, "weapon_first_aid_kit", false))
		{
			RemovePlayerItem(client, ent);
			RemoveEdict(ent);
			BypassAndExecuteCommand(client, "give", "first_aid_kit");
		}
	}
	else
	{
		BypassAndExecuteCommand(client, "give", "first_aid_kit");
	}
}

stock int TotalSurvivors() // total bots, including players
{
	int a = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVORS)) a++;
	}
	return a;
}

stock int HumanConnected()
{
	int a = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(bot) && !IsFakeClient(i)) a++;
	}
	return a;
}

stock int TotalFreeBots() // total bots (excl. IDLE players)
{
	int a = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i)==TEAM_SURVIVORS && !HasIdlePlayer(i)) a++;
	}
	return a;
}

stock void StopTimers()
{
	if(timer_SpawnTick != null)
	{
		KillTimer(timer_SpawnTick);
		timer_SpawnTick = null;
	}	
	if(timer_SpecCheck != null)
	{
		KillTimer(timer_SpecCheck);
		timer_SpecCheck = null;
	}	
}

bool SpawnFakeClient()
{
	bool fakeclientKicked = false;
	
	int fakeclient = 0;
	fakeclient = CreateFakeClient("FakeClient");

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
	int fakeclient = CreateFakeClient("FakeClient");
	
	if(fakeclient != 0)
	{
		ChangeClientTeam(fakeclient, TEAM_SURVIVORS);
		
		if(DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			if(DispatchSpawn(fakeclient) == true)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && (GetClientTeam(i) == TEAM_SURVIVORS) && !IsFakeClient(i) && IsAlive(i) && i != fakeclient)
					{						
						float teleportOrigin[3];
						GetClientAbsOrigin(i, teleportOrigin);			
						TeleportEntity(fakeclient, teleportOrigin, NULL_VECTOR, NULL_VECTOR);						
						break;
					}
				}
				
				StripWeapons(fakeclient);
				BypassAndExecuteCommand(fakeclient, "give", "pistol_magnum");
				if(StrContains(gMapName, "c1m1_hotel", false) == -1)
					GiveWeapon(fakeclient);
				
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
	if(!IsFakeClient(bot))
		return false;
	
	if(IsClientConnected(bot) && IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVORS && IsAlive(bot) && IsFakeClient(bot))
	{
		int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
		if(client)
		{
			if(!IsFakeClient(client) && (GetClientTeam(client) == TEAM_SPECTATORS))
				return true;
		}
	}
	return false;
}

bool IsClientIdle(int client)
{
	if(GetClientTeam(client) != TEAM_SPECTATORS) return false;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsAlive(i) && IsFakeClient(i))
		{
			if(GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID")) == client)
			return true;
		}
	}
	return false;
}

bool IsAlive(int client)
{
	if(!GetEntProp(client, Prop_Send, "m_lifeState")) return true;
	return false;
}