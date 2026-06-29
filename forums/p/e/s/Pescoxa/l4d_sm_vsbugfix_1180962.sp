#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.9.3"
#define SURVIVOR 2
#define INFECTED 3

new LeftSafe = 0;
new Started[MAXPLAYERS + 1];
new HumanMoved = 0;
new Handle:g_hGameMode = INVALID_HANDLE;

new sb_all_bot_type = 1;

// Plugin info
public Plugin:myinfo = 
{
	name = "[L4D/L4D2] VS Bug Fix",
	author = "Pescoxa",
	description = "Fix for Versus Server shutting down and Bots starting without players",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=126940"
};

public OnPluginStart()
{

	decl String:gameMod[32];
	GetGameFolderName(gameMod, sizeof(gameMod));
	if((!StrEqual(gameMod, "left4dead", false)) && (!StrEqual(gameMod, "left4dead2", false)))
	{
		SetFailState("VS Bug Fix supports L4D and L4D2 only.");
	}

	if((StrEqual(gameMod, "left4dead", false)))
	{
		sb_all_bot_type = 1;
	}
	else
	{
		sb_all_bot_type = 2;
	}

	CreateConVar("sm_vsbugfix_version", PLUGIN_VERSION, "[L4D/L4D2] VS Bug Fix", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);

	LeftSafe = 0;
	SetStarted(0);

	LoadTranslations("l4d_sm_vsbugfix.phrases");

	RegAdminCmd("sm_unfreezebots", Command_UnfreezeBots, ADMFLAG_CUSTOM1);
	
	HookEvent("round_start", Event_Round_Start, EventHookMode_Post);
	HookEvent("round_end",Event_Round_End, EventHookMode_Post);
	HookEvent("player_team", Event_Join_Team, EventHookMode_Post);
	HookEvent("player_left_checkpoint", Event_Left_CheckPoint, EventHookMode_Post);
	
	g_hGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hGameMode,CvarChanged_GameMode);
		
}

public Init()
{
	if (IsValidMode())
	{
		if (sb_all_bot_type == 2)
		{ 
			SetConVarInt(FindConVar("sb_all_bot_game"), 1);
		}
		else
		{
			SetConVarInt(FindConVar("sb_all_bot_team"), 1);
		}

		if (LeftSafe == 0)
		{
			SetConVarInt(FindConVar("sb_stop"), 1);
			SetConVarInt(FindConVar("director_ready_duration"), 0);
			SetConVarInt(FindConVar("director_no_mobs"), 1);
		}
		else
		{
			SetConVarInt(FindConVar("sb_stop"), 0);
			ResetConVar(FindConVar("director_ready_duration"));
			ResetConVar(FindConVar("director_no_mobs"));
		}
	}
	else
	{
		if (sb_all_bot_type == 2)
		{ 
			SetConVarInt(FindConVar("sb_all_bot_game"), 0);
		}
		else
		{
			SetConVarInt(FindConVar("sb_all_bot_team"), 0);
		}
		SetConVarInt(FindConVar("sb_stop"), 0);
		ResetConVar(FindConVar("director_ready_duration"));
		ResetConVar(FindConVar("director_no_mobs"));
	}
}

public SetStarted(Value)
{
  new maxplayers = GetMaxClients();
  for (new i = 1; i <= maxplayers; i++)
  	Started[i] = Value;
}

public IsValidMode()
{
	new String:gmode[32];
	GetConVarString(FindConVar("mp_gamemode"), gmode, sizeof(gmode));

	if ((strcmp(gmode, "versus", false) == 0) || (strcmp(gmode, "teamversus", false) == 0) || (strcmp(gmode, "scavenge", false) == 0) || (strcmp(gmode, "teamscavenge", false) == 0) || (strcmp(gmode, "mutation12", false) == 0))
	{
		return true;
	}
	else
	{
		return false;
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN: COMMANDS
///////////////////////////////////////////////////////////////////////////////////////////////////
public Action:Command_UnfreezeBots(client, args)
{

	RunUnfreeze(client);
	ReplyToCommand(client, "\x04[VBF] \x01%T", "BOTsAreUnfrozen.", client);

}
///////////////////////////////////////////////////////////////////////////////////////////////////
// END: COMMANDS
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN: GOD FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////
public God(client, bool:value)
{

	if (!client || !IsClientInGame(client))
		return;
	
	if (value && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);		
		PrintToChat(client, "\x04[VBF] \x01%T", "GodOn", client);
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(client, "\x04[VBF] \x01%T", "GodOff", client);
	}
}

public Action:TimerGod(Handle:timer, any:client)
{
	if (LeftSafe == 0)
		God(client, true);
	else
		God(client, false);
}

public Action:TimerUnGod(Handle:timer, any:client)
{
	God(client, false);
}
///////////////////////////////////////////////////////////////////////////////////////////////////
// END: GOD FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN: FREEZE AND UNFREEZE FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////
public FreezeAllSurvivorBOT()
{
	for (new i = 1; i <= GetMaxClients(); i++)
	{
	
		if (!IsValidEntity(i))
		{
			continue;
		}
		
		if (!IsClientConnected(i) || IsClientInKickQueue(i))
		{
			continue;
		}
		
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (!IsFakeClient(i))
		{
			continue;
		}
		
		if (GetClientTeam(i) != SURVIVOR)
		{
			continue;
		}
		
		Freeze(i);
	}
	
	if (LeftSafe == 0)
	{
		SetConVarInt(FindConVar("sb_stop"), 1);
	}
}

public UnFreezeAll()
{
	for (new i = 1; i <= GetMaxClients(); i++)
	{
	
		if (!IsValidEntity(i))
		{
			continue;
		}
		
		if (!IsClientConnected(i) || IsClientInKickQueue(i))
		{
			continue;
		}
		
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (GetClientTeam(i) == 1)
		{
			continue;
		}
		
		UnFreeze(i);
		God(i, false);
	}
	
	SetConVarInt(FindConVar("sb_stop"), 0);
}

public FreezeUnFreezeClient(client, clientTeam)
{
	
	if(client == 0)
		return;
	
	if(!IsValidEntity(client))
		return;
	
	if(!IsClientConnected(client))
		return;
	
	if(IsFakeClient(client))
	{
		if(clientTeam == SURVIVOR)
		{
			if(LeftSafe != 1)
			{
				CreateTimer(0.5, TimerFreeze, client);
			}
		}
		return;
	}
	else
	{
		CreateTimer(0.5, TimerUnFreeze, client);
		return;
	}
}

public Freeze(client)
{
	if((client > 0) &&IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
		SetEntityMoveType(client, MOVETYPE_NONE);
}

public UnFreeze(client)
{
	if((client > 0) && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
		SetEntityMoveType(client, MOVETYPE_WALK);
}

public Action:TimerFreeze(Handle:timer, any:client)
{
	FreezeAllSurvivorBOT();
}

public Action:TimerUnFreeze(Handle:timer, any:client)
{
	UnFreeze(client);
}
///////////////////////////////////////////////////////////////////////////////////////////////////
// END: FREEZE AND UNFREEZE FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN: EVENTS THAT CONTROLS THE PLUGIN
///////////////////////////////////////////////////////////////////////////////////////////////////
public CvarChanged_GameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Init();
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	LeftSafe = 0;
	SetStarted(0);
	HumanMoved = 0;
	
	Init();
	
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_MOVELEFT || buttons & IN_BACK || buttons & IN_FORWARD || buttons & IN_MOVERIGHT || buttons & IN_USE)
	{
		if ((client > 0) && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client) && (GetClientTeam(client) == SURVIVOR))
		{
			if (!IsFakeClient(client))
				HumanMoved = 1;
			if (HumanMoved == 1)
			{
				Started[client] = 1;
			}
		}
	}
	return Plugin_Continue;
}

public Event_Left_CheckPoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "entityid");
	//new area = GetEventInt(event, "area");
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ((Started[client] > 0) && (client > 0) && (entity == 0) && (LeftSafe == 0))
	{
		CreateTimer(0.5, OnLeftSafeArea, client);
	}
}

public Action:OnLeftSafeArea(Handle:timer, any:client)
{

	if (client == 0 || !IsClientInGame(client))
		return;

	if (GetClientTeam(client) != SURVIVOR)
	{
		Started[client] = 0;
		return;
	}

	RunUnfreeze(client);
		
}

public RunUnfreeze(client)
{
	LeftSafe = 1;
	SetStarted(1);
	
	UnFreezeAll();
	SetConVarInt(FindConVar("sb_stop"), 0);
	ResetConVar(FindConVar("director_ready_duration"));
	ResetConVar(FindConVar("director_no_mobs"));
}

public Event_Join_Team(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new clientTeam = GetEventInt(event, "team");
	FreezeUnFreezeClient(client, clientTeam);
	
	if (LeftSafe == 0)
	{
		if (clientTeam == SURVIVOR)
			CreateTimer(0.5, TimerGod, client);
		else if (clientTeam == INFECTED)
			CreateTimer(0.5, TimerUnGod, client);

		SetStarted(0);
	}
}

public Action:Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	LeftSafe = 0;
	SetStarted(0);
	HumanMoved = 0;
}
///////////////////////////////////////////////////////////////////////////////////////////////////
// END: EVENTS THAT CONTROLS THE PLUGIN
///////////////////////////////////////////////////////////////////////////////////////////////////