#include <sourcemod> 
#include <sdktools>

#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))


public Plugin:myinfo =  {
	name = "Dead Check Timer", 
	author = "zk", 
	description = "Prevents mission loss until all human players have died or wait for the Timer CountDown to end", 
	version = "1.0", 
	url = ""
};

new Handle:cvar_enable = INVALID_HANDLE;
new bool:is_enable = false;
new Handle:cvar_debug = INVALID_HANDLE;
new bool:is_debug = false;
new Handle:cvar_bots = INVALID_HANDLE;
new bool:is_checkbots = false;
new Handle:g_hDirectorNoDeathCheck = INVALID_HANDLE;
new bool:g_bDirectorNoDeathCheck = false;
new Handle:g_hCvarMPGameMode = INVALID_HANDLE;
new Handle:cvar_modes = INVALID_HANDLE;
new Handle:g_hAllowAllBot = INVALID_HANDLE;
new bool:g_bLostFired = false;
//new bool:g_bBlockDeathCheckDisable = false;
new Handle:cvar_timer = INVALID_HANDLE;
new Handle:cvar_count = INVALID_HANDLE;
new Handle:cvar_reset = INVALID_HANDLE;
new Handle:cvar_sound = INVALID_HANDLE;
new Handle:cvar_print = INVALID_HANDLE;
new Handle:cvar_hud = INVALID_HANDLE;
//new Handle:cvar_soundfile = INVALID_HANDLE;
new Handle:cvar_info = INVALID_HANDLE;
//new Handle:cvar_infocount = INVALID_HANDLE;
//new Handle:g_infocustom = INVALID_HANDLE;
new Handle:cvar_last = INVALID_HANDLE;

new Handle:hTimer = INVALID_HANDLE;
new String:sound[100];
new String:info[64];
new bool:is_timer_on;
new bool:is_hud;
new print_mode;
new reset_mode;

new Survivors;
new Incaps;
new CountDown;
new bool:IsGameOver;
new bool:IsMissionLost;
//new bool:IsTimerON;
new bool:IsL4D2;

public OnPluginStart()
{
	cvar_enable = CreateConVar("deadcheck_enable", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_debug = CreateConVar("deadcheck_debug", "0", "Enable debugging output", FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_bots = CreateConVar("deadcheck_bots", "0", "0: Bots and idle players are treated as human non-idle players, 1: Mission will be lost if there are still survivor bots/idle players but no living non-idle humans", FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_modes = CreateConVar("deadcheck_modes", "", "Enable plugin on these gamemodes, separate by commas (no spaces). (Empty = all).", FCVAR_NOTIFY);
	cvar_timer = CreateConVar("deadcheck_timer_on", "1", "0: Disable, 1: Enable Timer CountDown for gameover", FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_count = CreateConVar("deadcheck_timer_count", "10", "(t)s: Time countdown in seconds for gameover", FCVAR_NOTIFY);
	cvar_last = CreateConVar("deadcheck_timer_count_last", "0", "(t)s: Time countdown in seconds for last survivor , 0=No change Count , -1=Game Over", FCVAR_NOTIFY);
	cvar_reset = CreateConVar("deadcheck_timer_reset", "0", "0: Disable, 1: Enable timer reset_mode if some survivor died ,-1 Enable reset_mode only for last survivor", FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_info = CreateConVar("deadcheck_timer_info", "s", "\"Mensaje\": Info mensaje in timer", FCVAR_SPONLY | FCVAR_NOTIFY);
	//cvar_infocount = CreateConVar("deadcheck_timer_info_count", "8", "Select time count for display info", FCVAR_SPONLY | FCVAR_NOTIFY);
	//g_infocustom = CreateConVar("deadcheck_timer_infocustom_on", "1", "0: Disable, 1: Enable custom Info mensaje in timer", FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_print = CreateConVar("deadcheck_timer_print", "4", "0:  Disable, 1: ChatText , 2: CenterText, 4:HintText, 7:All PrintModes", FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_hud = CreateConVar("deadcheck_timer_print_hud", "1", "0:  Disable, 1: Print Instructor Hint (L4D2) ", FCVAR_SPONLY | FCVAR_NOTIFY);
	cvar_sound = CreateConVar("deadcheck_timer_sound", "", "Select file sound, example: \"ambient/alarms/klaxon1.wav\" , \"\": Disabled ", FCVAR_SPONLY | FCVAR_NOTIFY);
	GameCheck();
	
	g_hDirectorNoDeathCheck = FindConVar("director_no_death_check");
	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hAllowAllBot = FindConVar("allow_all_bot_survivor_team");// only L4D2 antibug no missionlost 1st try
	
	HookConVarChange(cvar_enable, ConvarsChanged);
	HookConVarChange(cvar_debug , ConvarsChanged);
	HookConVarChange(cvar_bots , ConvarsChanged);
	HookConVarChange(cvar_modes , ConvarsChanged);
	HookConVarChange(cvar_timer , ConvarsChanged);
	HookConVarChange(cvar_count , ConvarsChanged);
	HookConVarChange(cvar_last , ConvarsChanged);
	HookConVarChange(cvar_reset , ConvarsChanged);
	HookConVarChange(cvar_info , ConvarsChanged);
	HookConVarChange(cvar_print, ConvarsChanged);
	HookConVarChange(cvar_hud, ConvarsChanged);
	HookConVarChange(cvar_sound, ConvarsChanged);
					 
	HookConVarChange(cvar_enable, OnDeathCheckEnableChanged);
	HookConVarChange(cvar_debug, OnDeathCheckDebugChanged);
	HookConVarChange(cvar_bots, OnDeathCheckBotsChanged);
	HookConVarChange(g_hDirectorNoDeathCheck, OnDirectorNoDeathCheckChanged);
	HookConVarChange(g_hCvarMPGameMode, CvarChange_Allow);
	HookConVarChange(cvar_modes, CvarChange_Allow);

	AutoExecConfig(true, "l4d_deadcheck_timer");
	
	IsAllowed();
	if (is_debug)HookEvent("mission_lost", Event_MissionLost);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_start_post_nav", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	
	HookEvent("player_spawn", Event_PlayerSpawnKick);
	HookEvent("player_disconnect", Event_PlayerSpawnKick);
	
	HookEvent("revive_success", Event_DeadCheck,EventHookMode_Pre);	
	HookEvent("player_death", Event_DeadCheck,EventHookMode_Pre);
	HookEvent("player_incapacitated", Event_DeadCheck,EventHookMode_Pre);
	HookEvent("player_ledge_grab", Event_DeadCheck,EventHookMode_Pre);
	
}

GameCheck()
{
	decl String:GameName[16];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
		IsL4D2 = true;
	else
		IsL4D2 = false;
}

public OnMapStart()
{
	is_enable = GetConVarBool(cvar_enable);
	is_debug = GetConVarBool(cvar_debug);
	is_checkbots = GetConVarBool(cvar_bots);
	g_bDirectorNoDeathCheck = GetConVarBool(g_hDirectorNoDeathCheck);
	is_timer_on = GetConVarBool(cvar_timer);
	is_hud = GetConVarBool(cvar_hud);
	print_mode = GetConVarInt(cvar_print);
	reset_mode = GetConVarInt(cvar_reset);
	GetConVarString(cvar_sound, sound, sizeof(sound));
	GetConVarString(cvar_info, info, sizeof(info));
	if (is_debug)PrintToChatAll("OnMapStart");
	IsAllowed();
}

public ConvarsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	is_enable = GetConVarBool(cvar_enable);
	is_debug = GetConVarBool(cvar_debug);
	is_checkbots = GetConVarBool(cvar_bots);
	g_bDirectorNoDeathCheck = GetConVarBool(g_hDirectorNoDeathCheck);
	is_timer_on = GetConVarBool(cvar_timer);
	is_hud = GetConVarBool(cvar_hud);
	print_mode = GetConVarInt(cvar_print);
	reset_mode = GetConVarInt(cvar_reset);
	GetConVarString(cvar_sound, sound, sizeof(sound));
	GetConVarString(cvar_info, info, sizeof(info));
}

public OnDeathCheckEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	is_enable = StringToInt(newVal) == 1;
	if (!is_enable && g_bDirectorNoDeathCheck)SetConVarInt(g_hDirectorNoDeathCheck, 0);
	IsAllowed();
	DeadCheck();
}

public OnDeathCheckDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	is_debug = StringToInt(newVal) == 1;
	
	// When debugging, it's sometimes useful to know whether MissionLost fired
	if (is_debug)HookEvent("mission_lost", Event_MissionLost);
	else UnhookEvent("mission_lost", Event_MissionLost);
}

public OnDeathCheckBotsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	is_checkbots = StringToInt(newVal) == 1;
	DeadCheck();
}

public OnDirectorNoDeathCheckChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bDirectorNoDeathCheck = StringToInt(newVal) == 1;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (is_debug)
	{
		decl String:eventName[32];
		GetEventName(event, eventName, sizeof(eventName));
		PrintToChatAll("%s", eventName);
	}
	
	SetConVarInt(g_hDirectorNoDeathCheck, 0);
	IsGameOver = false;
	IsMissionLost=false;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (is_debug)
	{
		decl String:eventName[32];
		GetEventName(event, eventName, sizeof(eventName));
		PrintToChatAll("%s", eventName);
	}

	if(IsTimerON() && !IsGameOver){
		StopTimer();
		IsGameOver = true;//
		PrintTimer(" ");
	}
	IsMissionLost=true;
}

public Event_PlayerSpawnKick(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_VALID_SURVIVOR(client))
		CreateTimer(0.1, CheckSurvivors);
}

public Event_DeadCheck(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (is_debug)
	{
		decl String:eventName[32];
		GetEventName(event, eventName, sizeof(eventName));
		PrintToChatAll("%s", eventName);
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IS_VALID_SURVIVOR(client))
		DeadCheck();
}

public Action:CheckSurvivors(Handle:timer)
{
	DeadCheck();
}

DeadCheck()
{
	if (!is_enable || IsMissionLost)
	{
		return;
	}
	Survivors = 0;
	Incaps = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IS_SURVIVOR_ALIVE(i) && (!is_checkbots || !IsFakeClient(i)))
		{
			Survivors++;
			if(IsPlayerIncapped(i))
				Incaps++;
		}
	}
	if (is_debug)PrintToChatAll("%d Survivors", Survivors);
	if (is_debug)PrintToChatAll("%d Incaps", Incaps);
	
	//if (Survivors > 0 && !g_bDirectorNoDeathCheck && !g_bBlockDeathCheckDisable) //bug 1st try
	if (Survivors > 0 && Incaps == Survivors)
	{
		if (is_debug)PrintToChatAll("preventing deathcheck");
		SetConVarInt(g_hDirectorNoDeathCheck, 1);
	}else if (Survivors == 0 )
	{
		if (is_debug)
		{
			PrintToChatAll("enabling deathcheck");
			g_bLostFired = false; // listen for whether mission lost has fired
			CreateTimer(1.5, CheckLostFired, 0);
		}
		SetConVarInt(g_hDirectorNoDeathCheck, 0);
		if (IsTimerON())
			GameOver();
			
		return;
	}
	
	static alives = 0;
	if (is_timer_on && (Incaps > 0 || Survivors==1 && Incaps==0))
	{
		if (Incaps == Survivors)
		{
			if (is_debug)PrintToChatAll("%d / %d incapacitados", Incaps, Survivors);
			
			if (!IsGameOver && ( !IsTimerON() || (reset_mode != 0 && ( (reset_mode==1 && Survivors < alives ) || (reset_mode==-1 && Survivors==1) || alives == 0 ) ) ) )
			{
				alives = Survivors;
				if (IsTimerON())
					StopTimer();
				//CountDown = GetConVarInt(cvar_count);
				if (Survivors == 1 && GetConVarInt(cvar_last) > 0)
				{
					CountDown = GetConVarInt(cvar_last);
				}
				else if (Survivors == 1 && GetConVarInt(cvar_last) == -1)
				{
					GameOver();
					return;
				}else{
					CountDown = GetConVarInt(cvar_count);
				}
				hTimer = CreateTimer(1.0, TimerCountDown, _, TIMER_REPEAT);
			}
		}
		else {
			if (IsTimerON()){
				StopTimer()
				PrintTimer(" ");
			}
			if(IsGameOver){	//last chance
				IsGameOver=false
				PrintTimer("...");
			}
		}
	}
	return;
}

public Action:TimerCountDown(Handle:timer)
{
	if (IsGameOver){
		hTimer=INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if (CountDown == 0)
	{
		GameOver();
	}
	else if (CountDown > 0)
	{
		PrintTimer(" %d %s", CountDown, info);	
		CountDown--;
		SoundAlert();
		
	}
	return Plugin_Continue;
	
}

SoundAlert(){
	if(!StrEqual(sound,""))
		EmitSoundToAll(sound, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

// When everyone is dead in coop, the Mission Lost event should fire
// If it doesn't, the all dead glitch happened
public Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bLostFired = true;
}

public Action:CheckLostFired(Handle:timer, any:value)
{
	if (!g_bLostFired)PrintToChatAll("mission_lost did not fire");
	g_bLostFired = false;
}

// If the last human survivor slays themselves after closing the door but before it seals
// the game will stay in limbo until a human takes control of a Survivor in the safe room
// To prevent this, we wait until after the door seals (about 1 second, so 2 second timer)
// And then if there are no humans, we momentarily allow an all bot survivor team
public Event_DoorClose(Handle:event, const String:name[], bool:dontBroadcast)
{
	new checkpoint = GetEventBool(event, "checkpoint");
	if (checkpoint)
	{
		CreateTimer(2.0, DoorCloseDelay, 0);
	}
}

public Action:DoorCloseDelay(Handle:timer, any:value)
{
	new bool:FoundHumanSurvivor = false;
	for (new i = 1; i < MaxClients; i++)
	{
		if (IS_SURVIVOR_ALIVE(i) && !IsFakeClient(i))FoundHumanSurvivor = true;
	}
	
	// Don't bother doing this if the cvar is already false
	if (!FoundHumanSurvivor && !GetConVarBool(g_hAllowAllBot))
	{
		if (is_debug)PrintToChatAll("Momentarily activating allow_all_bot_survivor_team");
		SetConVarBool(g_hAllowAllBot, true);
		CreateTimer(1.0, DeactivateAllowBotCVARDelay, 0);
	}
}

public Action:DeactivateAllowBotCVARDelay(Handle:timer, any:value)
{
	SetConVarBool(g_hAllowAllBot, false);
}

// Allowed game modes thanks to SilverShot
public OnConfigsExecuted()
{
	IsAllowed();
}

public CvarChange_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
{
	IsAllowed();
}

stock bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))return true;
	else return false;
}
stock bool:IsPlayerGrapEdge(client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	else return false;
}

bool:IsTimerON(){
	return hTimer!=INVALID_HANDLE
}

GameOver()
{
	StopTimer();
	IsGameOver = true;
	SetConVarInt(g_hDirectorNoDeathCheck, 0);
	PrintTimer("Game Over");
}

StopTimer(){
	if (hTimer != INVALID_HANDLE)
	{
		KillTimer(hTimer);
		hTimer = INVALID_HANDLE;
	}
}


PrintTimer(const String:ctime[], any:...)
{
	decl String: buffer[254];
	VFormat(buffer, sizeof(buffer), ctime, 2);
	
	if(print_mode & 1){//(1<<0)
		PrintToChatAll(buffer);
	}
	if(print_mode & 2){//(1<<1)
		PrintCenterTextAll(buffer);
	}
	if(print_mode & 4){//(1<<2)
		PrintHintTextToAll(buffer);
	}
	
	if (is_hud){
		PrintHudTimer(buffer);
	}
	/*
		if (GetConVarBool(g_infocustom))			//Custom +Info agregar CVAR
		{
			if (Survivors == 1){														//lastsurvivor
				if(print_mode>=2)
				PrintHintTextToAll("( %d )%s Ultimo Sobreviviente!", CountDown, info);
				if (GetConVarBool(cvar_hud))
				PrintHudTimer(" %d %s Ultimo Sobreviviente!", CountDown, info);
			}
			else if (CountDown > GetConVarInt(cvar_count) - (GetConVarInt(cvar_count) * 0.3)){	//timer count > 70% del time inicial 
				if(print_mode>=2)
				PrintHintTextToAll(" %d %s Ayuda a algun Sobreviviente a levantarse!" , CountDown, info);
				if (GetConVarBool(cvar_hud))
				PrintHudTimer(" %d %s Ayuda a algun Sobreviviente a levantarse!" , CountDown, info);
			}
		}
	*/

}
	
PrintHudTimer(const String:ctime[], any:... )
{
	if(!IsL4D2)
	return;
	decl String: buffer[254];
	VFormat(buffer, sizeof(buffer), ctime, 2);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IS_VALID_SURVIVOR(i) && !IsFakeClient(i))
		{
			//if(!StrEqual(buffer,""))
			DisplayInstructorHint(i, 1.0, 0.0, 1.0, true, false, "icon_alert", "" , "", false, { 255, 255, 255 }, buffer, 2);
		}
	}
}

stock DisplayInstructorHint(target, Float:fTime, Float:fHeight, Float:fRange, bool:bFollow, bool:bShowOffScreen, const String:sIconOnScreen[], const String:sIconOffScreen[], String:sCmd[], bool:bShowTextAlways, iColor[3], const String:sText[], iShowType=0)
{
	new Handle:event = CreateEvent("instructor_server_hint_create");
	if (event == INVALID_HANDLE)
	{
		return;
	}
	decl String:sBuffer[32];
	Format(sBuffer, sizeof(sBuffer), "%d", target);
	SetEventString(event, "hint_name", sBuffer);
	SetEventString(event, "hint_replace_key", sBuffer);
	//SetEventInt(event, "hint_target", 0);	ALL?
	SetEventInt(event, "hint_target", target);
	//SetEventInt(event, "hint_activator_userid", 0); ALL?
	SetEventInt(event, "hint_activator_userid", target);
	SetEventBool(event, "hint_static", !bFollow);
	SetEventInt(event, "hint_timeout", RoundToFloor(fTime) );
	SetEventString(event, "hint_icon_onscreen", sIconOnScreen);	
	SetEventString(event, "hint_icon_offscreen", sIconOffScreen);
	SetEventString(event, "hint_caption", sText);
	SetEventString(event, "hint_activator_caption", sText);
	Format(sBuffer, sizeof(sBuffer), "%d %d %d", iColor[0], iColor[1], iColor[2]);
	SetEventString(event, "hint_color", sBuffer);
	SetEventFloat(event, "hint_icon_offset", fHeight);
	SetEventFloat(event, "hint_range", fRange);
	SetEventInt(event, "hint_flags", 0);// Change it..
	SetEventString(event, "hint_binding", sCmd);
	SetEventBool(event, "hint_allow_nodraw_target", true);
	SetEventBool(event, "hint_nooffscreen", !bShowOffScreen);
	SetEventBool(event, "hint_forcecaption", bShowTextAlways);
	//SetEventBool(event, "hint_local_player_only", true);
	SetEventBool(event, "hint_local_player_only", false);
	SetEventInt(event, "hint_instance_type", iShowType);
	FireEvent(event);
	/*
    How many instances of a single lesson type can be open or active at the same time.

        0 : Multiple
        1 : Single Open (Prevents new hints from opening.)
        2 : Fixed Replace (Ends other hints when a new one is shown.)
        3 : Single Active (Hides other hints when a new one is shown.)
	*/
}

bool:IsAllowedGameMode()
{
	if (g_hCvarMPGameMode == INVALID_HANDLE)
		return false;
	
	decl String:sGameMode[32], String:sGameModes[64];
	GetConVarString(cvar_modes, sGameModes, sizeof(sGameModes));
	if (strlen(sGameModes) == 0)
		return true;
	
	GetConVarString(g_hCvarMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	return (StrContains(sGameModes, sGameMode, false) != -1);
}

IsAllowed()
{
	new bool:bAllow = GetConVarBool(cvar_enable);
	new bool:bAllowMode = IsAllowedGameMode();
	
	if (is_enable == false && bAllow == true && bAllowMode == true)
	{
		is_enable = true;
	}
	else if (is_enable == true && (bAllow == false || bAllowMode == false))
	{
		is_enable = false;
	}
}
// /allowed game modes thanks to SilverShot
