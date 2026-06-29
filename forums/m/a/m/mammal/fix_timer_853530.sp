/*

-Mammal Master

-www.necrophix.com
TF2 Server: tf2.necrophix.com


*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"
#define MAX_LINE_WIDTH 60

new Handle:ErrorChecking;
new Handle:fix_timer_roundtime;

public bool:isGoodMap = true;

// Functions
public Plugin:myinfo =
{
	name = "[TF2]Fix 0:00",
	author = "Mammal Master",
	description = "Fix timer if missing",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_fix_timer_version", PLUGIN_VERSION, "Fix Timer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_fix_timer", Command_fixtimer, ADMFLAG_CHANGEMAP, "sm_fix_timer");
	RegAdminCmd("sm_settimer", Command_settimer, ADMFLAG_CHANGEMAP, "sm_settimer <second>");
	
	ErrorChecking = CreateConVar("sm_fix_timer_error_check","1","Shows Error Messages in-game chat, 0= don't show, 1 = show", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	fix_timer_roundtime = CreateConVar("sm_fix_timer_roundtime","960","How Much time in seconds for each round.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	if(isGoodMap)
	{	
		HookEvent("teamplay_round_start",round_start);
	}
}

public OnMapStart(){
	

	
	new String:map[128];
	GetCurrentMap(map, sizeof(map));
	
	if(StrContains(map, "arena_") != -1 || StrContains(map, "dom_") != -1)
	{
		isGoodMap = false;
	}
	
	
}
	
public Action:TimeChecker(Handle:timer, any:data)
{
		
	
	FindTimer();
	
}	
public round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
if(isGoodMap){
	FindTimer();
}
}
	
public FindTimer()
{


	new ent=-1;
	new String:game_timer_name[64];
	new String:game_round_win_name[64];
	new game_timer_length,game_round_reset,game_timer_ent;
	new bool:checker_game = false;
	new bool:checker_game_0 = false;
	new bool:checker_round = false;
	
	
	while ((ent = FindEntityByClassname(ent, "team_round_timer")) != -1) {
		GetEntPropString(ent, Prop_Data, "m_iName", game_timer_name, sizeof(game_timer_name));

		game_timer_length = GetEntProp(ent, Prop_Data, "m_nTimerInitialLength");
		 
		if(strcmp(game_timer_name, "zz_teamplay_timelimit_timer") == 0){
			if (GetConVarInt(ErrorChecking) == 1)
			{
				PrintToServer("[TF2][Fix Timer] It is Just the default zz_teamplay timer Length: %i", game_timer_length);
			}	
			make_game_timer_0(ent,GetConVarInt(fix_timer_roundtime));
		}else{
			if(game_timer_length == 0)
			{
				checker_game_0=true;
				if (GetConVarInt(ErrorChecking) == 1)
				{
					PrintToServer("[TF2][Fix Timer] It is 0 Length: %i", game_timer_length);
				}

			}else{
				if (GetConVarInt(ErrorChecking) == 1)
				{
					PrintToServer("[TF2][Fix Timer] It is NOT 0 Length: %i", game_timer_length);
				}
			}		
		
			checker_game=true;
		}
		

		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Found a team_round_timer %s", game_timer_name);
			PrintToServer("[TF2][Fix Timer] Found a Length: %i", game_timer_length);
		}
		
	}
	ent=-1;
	while ((ent = FindEntityByClassname(ent, "game_round_win")) != -1) {
		GetEntPropString(ent, Prop_Data, "m_iName", game_round_win_name, sizeof(game_round_win_name));
		checker_round=true;
		game_round_reset = GetEntProp(ent, Prop_Data, "m_bForceMapReset");

		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Found a game_round_win %s : reset: %i", game_round_win_name,game_round_reset);
		}
		
	}
	
	
	
	if(checker_game && checker_round && !checker_game_0){
		
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Not Needed ");
		}
		return true;
	}
	
	if(!checker_round ){
		make_game_round();
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Added round Win ");
		}
	}
	
			
	if(!checker_game ){
		make_game_timer();
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Added game_timer ");
		}
	}else if(checker_game && checker_game_0 ){
		make_game_timer();
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Added game_timer ");
		}
	}else if(checker_game && !checker_game_0 && !checker_round ){
		make_game_timer_0(game_timer_ent,GetConVarInt(fix_timer_roundtime));
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Fixed game_timer ");
		}
	}

	
	return false;
}

public make_game_timer()
{
	new team_round_timer = CreateEntityByName("team_round_timer");
	
	
	if (IsValidEdict(team_round_timer))
	{
		new String:timer_length[11];
		IntToString(GetConVarInt(fix_timer_roundtime), timer_length, sizeof(timer_length));
		
		DispatchKeyValue(team_round_timer, "targetname", "round_timer");
		
		DispatchKeyValue(team_round_timer, "timer_length", timer_length);
		DispatchKeyValue(team_round_timer, "max_length", "1100");
		DispatchKeyValue(team_round_timer, "show_in_hud", "1");
		DispatchKeyValue(team_round_timer, "auto_countdown", "1");
		
		DispatchKeyValue(team_round_timer, "OnFinished", "round_tie,RoundWin,,0,-1");
		
		DispatchSpawn(team_round_timer);
		SetVariantString("OnFinished round_tie,RoundWin,,0,-1");
		AcceptEntityInput(team_round_timer, "AddOutput");
		
		
	}
	
}

public make_game_round()
{
	new game_round_win = CreateEntityByName("game_round_win");
	
	
	if (IsValidEdict(game_round_win))
	{
		
		
		DispatchKeyValue(game_round_win, "targetname", "round_tie");
		DispatchKeyValue(game_round_win, "force_map_reset", "1");
		DispatchKeyValue(game_round_win, "TeamNum", "0");
		DispatchKeyValue(game_round_win, "switch_teams", "0");
		
	
		DispatchSpawn(game_round_win);
		
	}
	
}


public Action:Command_fixtimer(client, args)
{
	new ent=-1;
	new String:game_timer_name[64];
	
	new String:game_round_win_name[64];
	new game_timer_length,game_round_reset;
	
	
	while ((ent = FindEntityByClassname(ent, "team_round_timer")) != -1) {
		GetEntPropString(ent, Prop_Data, "m_iName", game_timer_name, sizeof(game_timer_name));
		
		game_timer_length = GetEntProp(ent, Prop_Data, "m_nTimerInitialLength");
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Found a team_round_timer %s ", game_timer_name);
			PrintToServer("[TF2][Fix Timer] Found a Length: %i", game_timer_length);
		}
		
		
	}
	ent=-1;
	while ((ent = FindEntityByClassname(ent, "game_round_win")) != -1) {
		GetEntPropString(ent, Prop_Data, "m_iName", game_round_win_name, sizeof(game_round_win_name));
			
		game_round_reset = GetEntProp(ent, Prop_Data, "m_bForceMapReset");
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] Found a game_round_win %s : reset: %i", game_round_win_name,game_round_reset);
		}
		
	}
	
	return Plugin_Handled;
	
}

public make_game_timer_0(team_round_timer,time)
{
	PrintToServer("[TF2][Fix Timer] 0 time on entity %i", team_round_timer);
	if (IsValidEdict(team_round_timer))
	{
		if (GetConVarInt(ErrorChecking) == 1)
		{
			PrintToServer("[TF2][Fix Timer] 0 time on entity %i", team_round_timer);
		}
		SetVariantInt(time);
		AcceptEntityInput(team_round_timer, "SetTime");
		SetVariantString("OnFinished round_tie,RoundWin,,0,-1");
		AcceptEntityInput(team_round_timer, "AddOutput");
		return true;
	}
	return false;
}

public Action:Command_settimer(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_settimer <seconds>");
		return Plugin_Handled;
	}

	new String:opt1[30];
	new String:cmdArg[32];
	GetCmdArg(1, cmdArg, sizeof(cmdArg));
	new timer_time = StringToInt(cmdArg);
	if(timer_time <= 0){
		ReplyToCommand(client, "[SM] Usage: sm_settimer <seconds>");
		return Plugin_Handled;
	}
	
	new ent=-1;	
	new String:game_timer_name[64];
	new game_timer_length;
	
	
	while ((ent = FindEntityByClassname(ent, "team_round_timer")) != -1) {
		GetEntPropString(ent, Prop_Data, "m_iName", game_timer_name, sizeof(game_timer_name));
		
		game_timer_length = GetEntProp(ent, Prop_Data, "m_nTimerInitialLength");
		PrintToServer("[TF2][Fix Timer] Found a team_round_timer %s ", game_timer_name);
		PrintToServer("[TF2][Fix Timer] Found a Length: %i", game_timer_length);
		make_game_timer_0(ent,timer_time);
		PrintToServer("[TF2][Fix Timer] Changing timer to: %i ",timer_time);
		
	}	
	
	PrintToServer("\x04[TF2][Filter]\x03 Filters were set to %s by %s", opt1, client);
	return Plugin_Handled;
}