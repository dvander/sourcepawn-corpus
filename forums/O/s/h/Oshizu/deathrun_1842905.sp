#include <tf2_stocks>
#include <sourcemod>

#define PLAYERCOND_SPYCLOAK (1<<4)
#define VERSION "1.2.1"

new changeteamallowed = false
new RoundStarted = false

// ConVars

new Handle:outlines
new outlinesEnabled = false

 new Handle:DeathrunMelee
 new DeathrunMeleeEnabled = false
 
 new DeathrunEnabled = false;
 
 new Death[MAXPLAYERS+1] = false

public Plugin:myinfo =
{
	name = "[TF2] Deathrun",
	author = "Oshizu",
	description = "Deathrun Gamemode for Team Fortress 2",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("teamplay_round_start", event_RoundStart);
	HookEvent("arena_round_start", event_ArenaStart); 
	HookEvent("teamplay_round_win", event_RoundWin);
	HookEvent("teamplay_round_stalemate", event_RoundWin);
	HookEvent("player_spawn", player_spawn);
	AddCommandListener(BlockCommand, "kill");
	AddCommandListener(BlockCommand, "explode");
	AddCommandListener(BlockCommand, "retry");
	AddServerTag("deathrun");

	outlines = CreateConVar("sm_deathrun_outlines",	"0", "Enables / Disables ability to players from runners team be seen throught walls by outline")
	HookConVarChange(outlines, OnOutlinesChange)

	DeathrunMelee = CreateConVar("sm_deathrun_melee_only",	"0", "Disables / Enables Melee Only")
	HookConVarChange(DeathrunMelee, OnDeathrunMeleeChange)
	
	AutoExecConfig(true, "plugin.deathrun");
}

public OnOutlinesChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) < 0)
	{
		SetConVarInt(cvar, 0)
	}
	if (StringToInt(newVal) > 1)
	{
		SetConVarInt(cvar, 1)
	}
	if (StringToInt(newVal) == 1)
	{
	outlinesEnabled = true
	}
	else if (StringToInt(newVal) == 0)
	{
	outlinesEnabled = false
	}
}

public OnDeathrunMeleeChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) < 0)
	{
		SetConVarInt(cvar, 0)
	}
	if (StringToInt(newVal) > 1)
	{
		SetConVarInt(cvar, 1)
	}
	if (StringToInt(newVal) == 1)
	{
	DeathrunMeleeEnabled = true
	}
	else if (StringToInt(newVal) == 0)
	{
	DeathrunMeleeEnabled = false
	}
}

public OnConfigsExecuted()
{
	if (DeathrunEnabled)
	{
		SecurityLevel1()
	}
}

public OnMapStart()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
  
	if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "vsh_dr", 6, false) == 0))
	{
		LogMessage("Deathrun map detected. Enabling Deathrun Gamemode.");
		DeathrunEnabled = true;

	}
 	 else
	{
		LogMessage("Current map is not a deathrun map. Disabling Deathrun Gamemode.");
		DeathrunEnabled = false;
		RestoreSecurity()
	}
	if (DeathrunEnabled)
	{
		changeteamallowed = true
		SecurityLevel1()
		ServerCommand("st_gamedesc_override Deathrun v%s", VERSION);
		for(new i = 1, iCount = 0; i <= MaxClients; i++)
		{
			Death[i] = false
		}
	}
}

public OnMapEnd()
{
	changeteamallowed = true
}

public OnGameFrame()
{
	if (DeathrunEnabled)
	{
		Demoshield()
		handle_gameFrameLogic();
		GameFrameScoutSpeed();
		if(DeathrunMeleeEnabled)
		{
			handle_removeweapons()
		}
	}
}

public player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (DeathrunEnabled)
	{
		TF2_RemoveWeaponSlot(client, 5)
		if (TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			TF2_RemoveWeaponSlot(client, 3)
			new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
			if (cond & PLAYERCOND_SPYCLOAK)
    	    {
				SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
			}
		}
		if(GetClientTeam(client) == 2)
		{
			if (outlinesEnabled)
			{
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
		else if(GetClientTeam(client) == 3)
		{
			CreateTimer(4.0, STC, client);
		}
	}
}
public Action:STC(Handle:timer, any:client)
{
	if(!Death[client])
	{
		CreateTimer(1.0, SwitchTeam, client);
	}
}

public Action:SwitchTeam(Handle:timer, any:client)
{
	ChangeClientTeam(client, 2);
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) // When round starts random player gets moved into death team and player who was before death gets moved to runners team
{
	if (DeathrunEnabled)
	{
	RoundStarted = false
	SecurityLevel1()
	changeteamallowed = false
	CreateTimer(1.0, moveplayers);
	}
}

public Action:event_ArenaStart(Handle:event, const String:name[], bool:dontBroadcast) // When round starts random player gets moved into death team and player who was before death gets moved to runners team
{
	if (DeathrunEnabled)
	{
		changeteamallowed = true
		RoundStarted = true
	}
}

public Action:event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (DeathrunEnabled)
	{
		changeteamallowed = true
		for(new i = 1, iCount = 0; i <= MaxClients; i++)
		{
			Death[i] = false
		}
	}
}

public Action:SecurityLevel1()
{
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
	SetConVarInt(FindConVar("tf_scout_air_dash_count"), 0);

}


public Action:RestoreSecurity()
{
	SetConVarInt(FindConVar("tf_arena_use_queue"), 1);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 1);
	SetConVarInt(FindConVar("mp_autoteambalance"), 1);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 1);
	SetConVarInt(FindConVar("mp_scrambleteams_auto"), 1);
	SetConVarInt(FindConVar("tf_scout_air_dash_count"), 1);

}

public Action:moveplayers(Handle:timer)
{
	CreateTimer(1.0, moveplayers2);
	for(new i = 1, iCount = 0; i <= MaxClients; i++)
	{
		if(ClientState(i))
		{
			ChangeClientTeam(i, 2);
			Death[i] = false
		}
	}
}

public Action:moveplayers2(Handle:timer)
{
	new player = GetRandomPlayer(2);
	Death[player] = true
	ChangeClientTeam(player, 3);
}

handle_gameFrameLogic()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetCloak(i) > 1.0) 
			SetCloak(i, 1.0);
		}
	}
}

handle_removeweapons()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
		TF2_RemoveWeaponSlot(i, 0)
		TF2_RemoveWeaponSlot(i, 1)
		TF2_RemoveWeaponSlot(i, 3)
		TF2_RemoveWeaponSlot(i, 4)
		TF2_RemoveWeaponSlot(i, 5)
		TF2_SwitchtoSlot(i, TFWeaponSlot_Melee);
		}
	}
}

Demoshield()
{
	new ent = -1;
	while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
	{
		AcceptEntityInput(ent, "kill");
	}

}

GameFrameScoutSpeed()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == 2)
			{
				if (TF2_GetPlayerClass(i) == TFClass_Scout)
				{
					if (RoundStarted)
					{
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 300.0);
					}
				}
			}
		}
	}
}

//STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS STOCKS 

/// Small userful thingy from cs:s deathrun manager made by Rogue plugin
public Action:BlockCommand(client, const String:command[], args) // Blocks use of commands USED FOR kill & explode things
{
	return Plugin_Handled; // blocks command 
}

/// Small userful thingy from cs:s deathrun manager made by Rogue plugin
stock GetRandomPlayer(team) 
{
    new clients[MaxClients+1], clientCount;
    for (new i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && (GetClientTeam(i) == team))
            clients[clientCount++] = i;
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

/// Stock Made by FlaminSarge from [TF2] Be the Horsemann
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

// From TF2Lib
stock SetCloak(client, Float:value)
{
	if (value < 0.0)
		value = 0.0;
	
	else if (value > 100.0)
		value = 100.0;

	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", value);
}

// From TF2Lib
stock Float:GetCloak(client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
}

// Dont Remember from where i got it
public bool:ClientState(client)
{
    if (client < 1)
        return false;
    
    if (!IsClientConnected(client))
        return false;
    
    if (!IsClientInGame(client))
        return false;
    
    if (IsFakeClient(client)) // No Replay & SourceTV Love :(
        return false;
    
    return true;
}
