#include <sourcemod>

#define PLUGIN_NAME			"Scavenge Tank"
#define PLUGIN_AUTHOR		"Mrs. Campanula"
#define PLUGIN_DESC			"Allow to spawn tank in scavenge mode"
#define PLUGIN_VERSION		"1.0.2"
#define PLUGIN_URL				"http://forums.alliedmods.net/showthread.php?p=1009547"

public Plugin:myinfo = 
{
	name 			= PLUGIN_NAME,
	author 			= PLUGIN_AUTHOR,
	description 	= PLUGIN_DESC,
	version 			= PLUGIN_VERSION,
	url 				= PLUGIN_URL
}

new Handle:hTankAfterScoreTied;
new Handle:hTankAfterOvertime;
new Handle:hTankAfterCanCount;
new Handle:hHordeAfterScoreTied;
new Handle:hHordeAfterOvertime;
new Handle:hHordeAfterCanCount;


new bool:bOvertime;
new bool:bFirstTeam;
new nGasCount;

public OnPluginStart()
{
	RegServerCmd("l4d2_scavengetank_force_spawn", Server_ForceTankSpawn, "Force tank spawn");
	RegServerCmd("l4d2_scavengehorde_force_spawn", Server_ForceHordeSpawn, "Force horde spawn");
	hTankAfterOvertime = CreateConVar("l4d2_scavengetank_spawn_tank_after_overtime", "1", "Spawn tank after score tied?", FCVAR_PROTECTED);
	hTankAfterScoreTied = CreateConVar("l4d2_scavengetank_spawn_tank_after_score_tied", "1", "Spawn tank after score tied?", FCVAR_PROTECTED);
	hTankAfterCanCount = CreateConVar("l4d2_scavengetank_spawn_tank_after_cans_count", "0", "Spawn tank after specified count of poured cans ( 0 to disable )", FCVAR_PROTECTED);
	hHordeAfterOvertime = CreateConVar("l4d2_scavengehorde_spawn_horde_after_overtime", "1", "Spawn horde after score tied?", FCVAR_PROTECTED);
	hHordeAfterScoreTied = CreateConVar("l4d2_scavengehorde_spawn_horde_after_score_tied", "1", "Spawn horde after score tied?", FCVAR_PROTECTED);
	hHordeAfterCanCount = CreateConVar("l4d2_scavengehorde_spawn_horde_after_cans_count", "0", "Spawn horde after specified count of poured cans ( 0 to disable )", FCVAR_PROTECTED);
}

public OnMapStart()
{
	if( CheckGameMode() )
	{
		HookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_Pre);
		HookEvent("scavenge_round_halftime", Event_Halftime, EventHookMode_Pre);
		HookEvent("scavenge_score_tied", Event_ScoreTied, EventHookMode_Pre);
		HookEvent("begin_scavenge_overtime", Event_Overtime, EventHookMode_Pre);
		HookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_Pre);
	}
}
public OnMapEnd()
{
	if( CheckGameMode() )
	{
		UnhookEvent("scavenge_round_start", Event_RoundStart, EventHookMode_Pre);
		UnhookEvent("scavenge_round_halftime", Event_Halftime, EventHookMode_Pre);
		UnhookEvent("scavenge_score_tied", Event_ScoreTied, EventHookMode_Pre);
		UnhookEvent("begin_scavenge_overtime", Event_Overtime, EventHookMode_Pre);
		UnhookEvent("gascan_pour_completed", Event_GasCanPourCompleted, EventHookMode_Pre);
	}
}

public bool:CheckGameMode()
{
	new String:gameMode[9];
	GetConVarString(FindConVar("mp_gamemode"), gameMode, 9);
	return ( StrEqual("scavenge", gameMode) || StrEqual("teamscavenge", gameMode) );
}

public Action:Event_RoundStart(Handle:event, String:name[], bool:nobroadcast)
{
	bOvertime = false;
	nGasCount = 0;
	bFirstTeam = true;
	return Plugin_Continue;
}
public Action:Event_Overtime(Handle:event, String:name[], bool:nobroadcast)
{
	if(!bOvertime)
	{
		if(GetConVarBool(hTankAfterOvertime))
			SpawnTank();
		if(GetConVarBool(hHordeAfterOvertime))
			SpawnHorde();
		bOvertime = true;
	}
	return Plugin_Continue;
}
public Action:Event_Halftime(Handle:event, String:name[], bool:nobroadcast)
{
	if(nGasCount > 0)
	{
		nGasCount = 0;
		bFirstTeam = false;
	}
	return Plugin_Continue;
}
public Action:Event_ScoreTied(Handle:event, String:name[], bool:nobroadcast)
{
	if(GetConVarBool(hTankAfterScoreTied))
		SpawnTank();
	
	if(GetConVarBool(hHordeAfterScoreTied))
		SpawnHorde();
		
	return Plugin_Continue;
}
public Action:Event_GasCanPourCompleted(Handle:event, String:name[], bool:nobroadcast)
{
	nGasCount++;
	
	//PrintToChatAll("%i", nGasCount);
	
	if( nGasCount == 15 && GetConVarBool(hTankAfterScoreTied) && bFirstTeam )
	{
		SpawnTank();
	}
	
	if( nGasCount == 15 && GetConVarBool(hHordeAfterScoreTied) && bFirstTeam )
	{
		SpawnHorde();
	}
	
	new i = GetConVarInt(hTankAfterCanCount);
	if(i>0&&(nGasCount%i==0))
		SpawnTank();
	
	new j = GetConVarInt(hHordeAfterCanCount);
	if(j>0&&(nGasCount%j==0))
		SpawnHorde();
	
	return Plugin_Continue;
}

public Action:Server_ForceTankSpawn(args)
{
	SpawnTank();
	return Plugin_Continue;
}

public Action:Server_ForceHordeSpawn(args)
{
	SpawnHorde();
	return Plugin_Continue;
}

public SpawnTank()
{
    new flags = GetCommandFlags("z_spawn");
    for(new i = 1; i <= 18; i++)
    {
        if( IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) )
        {
            SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
            FakeClientCommand(i, "z_spawn tank auto");
            SetCommandFlags("z_spawn", flags);
            return;
        }
    }
}

public SpawnHorde()
{
    new flags = GetCommandFlags("z_spawn");
    for(new i = 1; i <= 18; i++)
    {
        if( IsClientConnected(i) && IsClientInGame(i) && IsFakeClient(i) )
        {
            SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
            FakeClientCommand(i, "z_spawn mob");
            SetCommandFlags("z_spawn", flags);
            return;
        }
    }
}  