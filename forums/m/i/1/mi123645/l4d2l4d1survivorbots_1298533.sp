
// define
#define PLUGIN_VERSION "1.0.2"
#define DEBUG 0
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3

#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"

#define ZOEY 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 5
#define FRANCIS 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 6
#define LOUIS 		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 7
#define GENERIC		GetEntProp(client, Prop_Send, "m_survivorCharacter") == 9

#define SET_CHARACTER_GENERIC_SURVIVOR 		SetEntProp(client, Prop_Send, "m_survivorCharacter", 9);
#define SET_CHARACTER_ZOEY 			SetEntProp(client, Prop_Send, "m_survivorCharacter", 5);
#define SET_CHARACTER_FRANCIS		SetEntProp(client, Prop_Send, "m_survivorCharacter", 6);
#define SET_CHARACTER_LOUIS			SetEntProp(client, Prop_Send, "m_survivorCharacter", 7);

// includes
#include <sourcemod>
#include <sdktools>

static bool:g_b_RoundStarted
static L4D1Survivor
static bool:g_bEnabled
static bool:g_bBillVPK
static StartCheckpointDoor
static bool:PlayerEnteredCheckPoint[MAXPLAYERS+1]

public Plugin:myinfo = 
{
	name = "[L4D2] L4D1 Survivor Bots",
	author = "MI 5",
	description = "Spawns the L4D1 Survivors alongside the L4D2 survivors",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	// This plugin only works for L4D2.
	
	decl String:GameName[12];
	GetGameFolderName(GameName, sizeof(GameName));	
	if (!StrEqual(GameName, "left4dead2", false))
		return APLRes_Failure;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	// Enable Cvar
	new Handle:Enabled = CreateConVar("l4d2_l4d1survivorbots_enable", "1", "Enables the plugin", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	g_bEnabled = GetConVarBool(Enabled);
	HookConVarChange(Enabled, _ConVarChange__Enable);
	
	// Bill VPK Cvar
	new Handle:BillVPK = CreateConVar("l4d2_l4d1survivorbots_bill_vpk", "0", "Set this to 1 if you have the Bill model vpk installed. 0 if otherwise.", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	g_bBillVPK = GetConVarBool(BillVPK);
	HookConVarChange(BillVPK, _ConVarChange__BillVPK);
	
	// Events
	HookEvent("item_pickup", Event_RoundStart);
	HookEvent("player_bot_replace", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("door_close", Event_SafeRoomDoorClosed);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("defibrillator_used", Event_DefibUsed);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_entered_checkpoint", Event_PlayerEnteredCheckpoint);
	HookEvent("player_left_checkpoint", Event_PlayerLeftCheckpoint);
	
	
	AutoExecConfig(true, "l4d2l4d1survivorbots")
}

public _ConVarChange__Enable(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_bEnabled = GetConVarBool(convar);
}

public _ConVarChange__BillVPK(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	g_bBillVPK = GetConVarBool(convar);
}

public OnMapStart()
{
	//Precache models here so that the server doesn't crash
	SetConVarInt(FindConVar("precache_l4d1_survivors"), 1, true, true)
	
	if (!IsModelPrecached(MODEL_ZOEY))	PrecacheModel(MODEL_ZOEY, false)
	if (!IsModelPrecached(MODEL_FRANCIS))		PrecacheModel(MODEL_FRANCIS, false)
	if (!IsModelPrecached(MODEL_LOUIS))	PrecacheModel(MODEL_LOUIS, false)
	if (!IsModelPrecached(MODEL_BILL))	PrecacheModel(MODEL_BILL, false)
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_b_RoundStarted)
		return;
	
	if (!g_bEnabled)
		return;
	
	g_b_RoundStarted = true;
	
	L4D1Survivor = 0
	
	KickL4D1Survivors()
	
	#if DEBUG
	PrintToChatAll("Round Started, reseting variables and spawning survivors.")
	#endif
	
	CreateTimer(3.0, Timer_SpawnL4D1Survivor)
}

public Action:Timer_SpawnL4D1Survivor(Handle:timer)
{
	while (TrueNumberOfSurvivors() < 8 && g_bBillVPK || TrueNumberOfSurvivors() < 7 && !g_bBillVPK) 
	{
		new bot = CreateFakeClient("L4D 1 Survivor");
		ChangeClientTeam(bot,2);
		DispatchKeyValue(bot,"classname","SurvivorBot");
		DispatchSpawn(bot);
		CreateTimer(0.1,kickbot,bot);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "bot"));
	if (!client || !IsClientInGame(client)) return;
	
	if (GetClientTeam(client) != TEAM_SURVIVORS)
		return;
	
	if (L4D1Survivor == 4 && g_bBillVPK || L4D1Survivor == 3 && !g_bBillVPK)
		return;
	
	#if DEBUG
	PrintToChatAll("Bots joined, changing them into L4D1 Survivors.")
	#endif
	
	decl String:CurrentMap[100]
	
	GetCurrentMap(CurrentMap, sizeof(CurrentMap))
	
	switch(L4D1Survivor)
	{
		case 0:
		{
			L4D1Survivor++
			if (!StrEqual(CurrentMap, "c6m3_port") == true)
				SET_CHARACTER_ZOEY
			else
			SET_CHARACTER_GENERIC_SURVIVOR
			SetEntityModel(client, MODEL_ZOEY);
			SetClientInfo(client, "name", "Zoey");
			//SetEntProp(client, Prop_Send, "m_iTeamNum", 4)
		}
		case 1:
		{
			L4D1Survivor++
			if (!StrEqual(CurrentMap, "c6m3_port") == true)
				SET_CHARACTER_FRANCIS
			else
			SET_CHARACTER_GENERIC_SURVIVOR
			SetEntityModel(client, MODEL_FRANCIS);
			SetClientInfo(client, "name", "Francis");
			//SetEntProp(client, Prop_Send, "m_iTeamNum", 4)
		}
		case 2:
		{
			L4D1Survivor++
			if (!StrEqual(CurrentMap, "c6m3_port") == true)
				SET_CHARACTER_LOUIS
			else
			SET_CHARACTER_GENERIC_SURVIVOR
			SetEntityModel(client, MODEL_LOUIS);
			SetClientInfo(client, "name", "Louis");
			//SetEntProp(client, Prop_Send, "m_iTeamNum", 4)
		}
		case 3:
		{
			L4D1Survivor++
			if (g_bBillVPK)
			{
				SET_CHARACTER_GENERIC_SURVIVOR
				SetEntityModel(client, MODEL_BILL);
				SetClientInfo(client, "name", "Bill");
				//SetEntProp(client, Prop_Send, "m_iTeamNum", 4)
			}
		}
	}
}

public Action:Event_DefibUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;
	
	// Restore Bill's name after he is defibed
	
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	
	if (GENERIC && g_bBillVPK)
		SetClientInfo(client, "name", "Bill");
}

public Action:Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;
	
	// Restore Bill's name after he is rescued
	
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (GENERIC && g_bBillVPK)
		SetClientInfo(client, "name", "Bill");
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Round Ended.")
	#endif
	
	g_b_RoundStarted = false;
	L4D1Survivor = 0
}

public Action:Event_PlayerEnteredCheckpoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;
	
	// This event differentiates the starting safe room door and the exit safe room door
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new door = GetEventInt(event, "door");
	
	if (!client)
		return;
	
	if (GetClientTeam(client) == TEAM_INFECTED)
		return;
	
	if (StartCheckpointDoor == 0)
		StartCheckpointDoor = door
	else if (StartCheckpointDoor != door)
	{
		PlayerEnteredCheckPoint[client] = true
	}
	
	#if DEBUG
	PrintToChatAll("Start Checkpoint door Entity index: %i", StartCheckpointDoor) 
	PrintToChatAll("%N has entered the checkpoint", client)
	#endif
}

public Action:Event_PlayerLeftCheckpoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bEnabled)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return;
	
	if (GetClientTeam(client) == TEAM_INFECTED)
		return;
	
	PlayerEnteredCheckPoint[client] = false
	
	#if DEBUG
	PrintToChatAll("%N has left the checkpoint", client)
	#endif
}

public Action:Event_SafeRoomDoorClosed(Handle:event, const String:name[], bool:dontBroadcast)
{	
	// Fixes glitch with L4D1 Survivors not being counted towards the final score.
	
	if (!g_bEnabled)
		return;
	
	new checkpoint = GetEventBool(event, "checkpoint");
	
	if (!checkpoint)
		return;
	
	new PlayersWhoEnteredCheckpoint
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (PlayerEnteredCheckPoint[client])
					PlayersWhoEnteredCheckpoint++
			}
		}
	}
	
	if (PlayersWhoEnteredCheckpoint != NumberOfSurvivorsExcludeDead())
		return;
	
	#if DEBUG
	PrintToChatAll("Safe Room Door Closed")
	#endif
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (IsFakeClient(client))
				{
					if (GENERIC && g_bBillVPK)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", 0)
					else if (ZOEY)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", 1)
					else if (FRANCIS)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", 2)
					else if (LOUIS)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", 3)
				}
			}
		}
	}
}

public Action:Event_FinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Fixes glitch with the L4D1 Survivors not being counted towards the final score in versus.
	
	if (!g_bEnabled)
		return;
	
	#if DEBUG
	PrintToChatAll("Finale Vehicle Leaving")
	#endif
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (IsFakeClient(client))
				{
					if (GENERIC && g_bBillVPK)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", 0)
					else if (ZOEY)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", 1)
					else if (FRANCIS)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", 2)
					else if (LOUIS)
						SetEntProp(client, Prop_Send, "m_survivorCharacter", 3)
				}
			}
		}
	}
}

public Action:Event_FinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Prevents a horrific glitch with the L4D1 Survivors on this map
	
	if (!g_bEnabled)
		return;
	
	#if DEBUG
	PrintToChatAll("Finale Started.")
	#endif
	
	decl String:CurrentMap[100]
	decl String:Name[100]
	
	GetCurrentMap(CurrentMap, sizeof(CurrentMap))
	
	if (!StrEqual(CurrentMap, "c6m3_port") == true)
		return;
	
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (IsFakeClient(client))
				{
					GetClientName(client, Name, sizeof(Name))
					if (StrEqual(Name, "Zoey", true))
						SET_CHARACTER_ZOEY
					else if (StrEqual(Name, "Francis", true))
						SET_CHARACTER_FRANCIS
					else if (StrEqual(Name, "Louis", true))
						SET_CHARACTER_LOUIS
				}
			}
		}
	}
}

public OnMapEnd()
{
	#if DEBUG
	LogMessage("Map Ended.")
	#endif
	g_b_RoundStarted = false;
	L4D1Survivor = 0
}

stock TrueNumberOfSurvivors ()
{
	new TotalSurvivors;
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
			if (GetClientTeam(client) == TEAM_SURVIVORS)
				TotalSurvivors++;
		}
	return TotalSurvivors;
}

stock NumberOfSurvivorsExcludeDead ()
{
	new TotalSurvivors;
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (!GetEntProp(client,Prop_Send, "m_lifeState"))
				{
					TotalSurvivors++;
				}
			}
		}
	}
	return TotalSurvivors;
}

stock KickL4D1Survivors ()
{
	// I could be kicking the bots by their character netprops, but I decided to kick them by model due to the fact that they wouldn't be kicked after a versus match (part of the versus score fix)
	decl String:Model[100]
	for (new client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				if (IsFakeClient(client))
				{
					GetClientModel(client, Model, sizeof(Model))
					if ((StrEqual(Model, MODEL_BILL, true) && g_bBillVPK) || StrEqual(Model, MODEL_ZOEY, true) || StrEqual(Model, MODEL_FRANCIS, true) || StrEqual(Model, MODEL_LOUIS, true))
						CreateTimer(0.1,kickbot,client);
				}
			}
		}
	}
}

public Action:kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client);
	}
}

////////////////////////////////