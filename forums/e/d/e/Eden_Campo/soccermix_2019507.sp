#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
//#include <cURL>
#include <morecolors>

#define PLUGIN_VERSION	"1.0.0"

//#define DEBUG

#pragma semicolon 1

new bool:g_isMixRunning = false;
new bool:g_isMixPaused = false;
new bool:g_isPreparing = false;
new bool:g_breakFinished = false;
new bool:g_breakRestarted = false;
new bool:g_isBreakRunning = false;
new bool:g_allowTimeDecrease = false;
new bool:g_runnedBreakSound = false;
new bool:g_isGKT[MAXPLAYERS] = false;
new bool:g_isGKCT[MAXPLAYERS] = false;

new bool:g_inSprintCooldown[MAXPLAYERS] = false;

new Handle:g_hSoccerMixVersion = INVALID_HANDLE;
new Handle:g_hSoccerMixGameTime = INVALID_HANDLE;
new Handle:g_hSoccerMixModels = INVALID_HANDLE;
new Handle:g_hSoccerMixCVarWarn = INVALID_HANDLE;
new Handle:g_hSoccerMixAllowPause = INVALID_HANDLE;
new Handle:g_hSoccerMixBreakVote = INVALID_HANDLE;
new Handle:g_hSoccerMixUsePassword = INVALID_HANDLE;
new Handle:g_hSoccerMixAutoUnload = INVALID_HANDLE;
//new Handle:g_hSoccerMixHostServer = INVALID_HANDLE;
//new Handle:g_hSoccerMixHostToCall = INVALID_HANDLE;
//new Handle:g_hSoccerMixHostServerPort = INVALID_HANDLE;
//new Handle:g_hSoccerMixHostToCallPort = INVALID_HANDLE;

new Handle:g_hServerPassword = INVALID_HANDLE;

new Handle:g_hMixMenu = INVALID_HANDLE;
new Handle:g_hConfirmMenu = INVALID_HANDLE;
new Handle:g_hBreakVMenu = INVALID_HANDLE;

new SoccerGameTime;
new SoccerUseModels;
new SoccerWarnCVar;
new SoccerAllowPause;
new SoccerBreakVote;
new SoccerUsePass;
new SoccerAutoUnload;

new g_AwayScore = 0;
new g_HomeScore = 0;
new g_CurrentRound = 0;
new g_Half = 1;
new Time_Left;
new Time_Half;
new Break_Time = 60;
new Already_Paused_Time = 0;
new PlayerGoaled;
new PlayerPassed;
new SoundCount = 0;

new String:SoccerLogPath[256];

/*new String:SoccerHost[256];
new String:SoccerDestination[256];
new String:SoccerHostPort[256];
new String:SoccerDestinationPort[256];

//new Handle:cURLConnection;

//new bool:cURLConnecting;
//new bool:cURLWaitingReply;
//new bool:cURLConnected;
*/

public Plugin:myinfo = {
    name = "Soccer Mix",
    author = "Eden.Campo",
    description = "Soccer Mix Mod for Soccer Servers",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/member.php?u=226366"
};

public OnPluginStart()
{
	BuildPath(Path_SM, SoccerLogPath, sizeof(SoccerLogPath), "logs/SoccerMix.log");

	g_hSoccerMixVersion = CreateConVar("sm_soccermix_version", PLUGIN_VERSION, "Soccer Mix Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_hSoccerMixGameTime = CreateConVar("sm_soccermix_gametime", "1800", "Full gametime in seconds(1800 = 30:00, Break time occurs in half way(15:00)", FCVAR_NOTIFY);
	g_hSoccerMixModels = CreateConVar("sm_soccermix_models", "1", "Decides if the mod will apply soccer models when a player spawns");
	g_hSoccerMixCVarWarn = CreateConVar("sm_soccermix_warn_cvars", "1", "Decides if the mod will tell people to change the CVar values if they dont have the right ones(cl_interp 0.02, cl_interp_ratio 1");
	g_hSoccerMixAllowPause = CreateConVar("sm_soccermix_allow_pause", "1", "Decides weather you can pause the game(as an admin)or not");
	g_hSoccerMixBreakVote = CreateConVar("sm_soccermix_break_vote", "1", "Decides weather to apply a vote. Stop the break or not?");
	g_hSoccerMixUsePassword = CreateConVar("sm_soccermix_use_password", "0", "Decides weather to apply a password to the server on mix start or not");
	g_hSoccerMixAutoUnload = CreateConVar("sm_soccermix_auto_unload", "1", "Unload the plugin on non-soccer maps?");
	//g_hSoccerMixHostServer = CreateConVar("sm_soccermix_host", "0.0.0.0", "Define the HOST ip here");
	//g_hSoccerMixHostServerPort = CreateConVar("sm_soccermix_host_port", "27015", "Define the HOST port here");
	//g_hSoccerMixHostToCall = CreateConVar("sm_soccermix_host_to_call", "82.80.149.137", "Define the server ip to call here!");
	//g_hSoccerMixHostToCallPort = CreateConVar("sm_soccermix_host_to_call_port", "27015", "Define the server port to call here!");
	
	HookConVarChange(g_hSoccerMixVersion, Action_OnSettingsChange);
	HookConVarChange(g_hSoccerMixGameTime, Action_OnSettingsChange);
	HookConVarChange(g_hSoccerMixModels, Action_OnSettingsChange);	
	HookConVarChange(g_hSoccerMixCVarWarn, Action_OnSettingsChange);
	HookConVarChange(g_hSoccerMixAllowPause, Action_OnSettingsChange);
	HookConVarChange(g_hSoccerMixBreakVote, Action_OnSettingsChange);	
	HookConVarChange(g_hSoccerMixUsePassword, Action_OnSettingsChange);
	HookConVarChange(g_hSoccerMixAutoUnload, Action_OnSettingsChange);
	//HookConVarChange(g_hSoccerMixHostServer, Action_OnSettingsChange);
	//HookConVarChange(g_hSoccerMixHostToCall, Action_OnSettingsChange);
	//HookConVarChange(g_hSoccerMixHostServerPort, Action_OnSettingsChange);
	//HookConVarChange(g_hSoccerMixHostToCallPort, Action_OnSettingsChange);
	
	
	SoccerGameTime = GetConVarInt(g_hSoccerMixGameTime);
	SoccerUseModels = GetConVarInt(g_hSoccerMixModels);
	SoccerWarnCVar = GetConVarInt(g_hSoccerMixCVarWarn);
	SoccerAllowPause = GetConVarInt(g_hSoccerMixAllowPause);
	SoccerBreakVote = GetConVarInt(g_hSoccerMixBreakVote);
	SoccerUsePass = GetConVarInt(g_hSoccerMixUsePassword);
	SoccerAutoUnload = GetConVarInt(g_hSoccerMixAutoUnload);
	
	/*
	GetConVarString(g_hSoccerMixHostServer, SoccerHost, sizeof(SoccerHost));
	GetConVarString(g_hSoccerMixHostToCall, SoccerDestination, sizeof(SoccerDestination));
	GetConVarString(g_hSoccerMixHostServerPort, SoccerHostPort, sizeof(SoccerHostPort));
	GetConVarString(g_hSoccerMixHostToCallPort, SoccerDestinationPort, sizeof(SoccerDestinationPort));
	*/
	
	g_hServerPassword = FindConVar("sv_password");
	
	AutoExecConfig(true, "SoccerMix");

	RegAdminCmd("sm_mix", Command_StartMix, ADMFLAG_GENERIC);
	RegAdminCmd("sm_pause", Command_PauseMix, ADMFLAG_GENERIC);
	RegAdminCmd("sm_prepare", Command_Prepare, ADMFLAG_GENERIC);
	RegAdminCmd("sm_gkt", Command_GoalKeeperT, ADMFLAG_GENERIC);
	RegAdminCmd("sm_gkct", Command_GoalKeeperCT, ADMFLAG_GENERIC);
	RegAdminCmd("sm_ungk", Command_UnGoalKeeper, ADMFLAG_GENERIC);
	//RegAdminCmd("sm_subneeded", Command_SubNeeded, ADMFLAG_GENERIC);
	RegAdminCmd("sm_settime", Command_SetTime, ADMFLAG_ROOT);
	RegAdminCmd("sm_setbreak", Command_SetBreak, ADMFLAG_ROOT);
	
	
	RegConsoleCmd("sm_score", Command_Score);
	RegConsoleCmd("sm_askpause", Command_AskPause);
	
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_RestartGame, "mp_restartgame");
	AddCommandListener(Command_Kill, "kill");
	
	HookEvent("round_start", onRoundStart);
	HookEvent("round_end", onRoundEnd);
	HookEvent("player_spawn", onPlayerSpawn);
	HookEvent("player_death", onPlayerDeath);
	
	CreateTimer(1.0, Timer_UpdateRunningTime, _, TIMER_REPEAT);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SoccerMix_StartMix", SoccerMixNative_StartMix);
	CreateNative("SoccerMix_EndMix", SoccerMixNative_EndMix);
	CreateNative("SoccerMix_CallPause", SoccerMixNative_CallPause);
	
	return APLRes_Success;
}

public SoccerMixNative_StartMix(Handle:plugin, numParams)
{
	StartMix();
}

public SoccerMixNative_EndMix(Handle:plugin, numParams)
{
	EndMix();
}

public SoccerMixNative_CallPause(Handle:plugin, numParams)
{
	new PauseProcess = GetNativeCell(1);
	
	new data;
	
	if(PauseProcess == 1)
	{	
		Already_Paused_Time = 0;
		g_isMixPaused = true;
		CPrintToChatAll("{green}[Soccer Mix]{default} Mix is currently {red}PAUSED{default}.");
		
		data = 0;
	}
	else
	{
		Already_Paused_Time = 0;
		g_isMixPaused = false;
		CPrintToChatAll("{green}[Soccer Mix]{default} Mix is currently {red}UNPAUSED{default}.");
		
		data = 1;
	}
		
	CreateTimer(0.1, Timer_EnableDisableBall, data);
}

public OnPluginEnd()
{
	EnableBall();
		
	ServerCommand("phys_timescale 1.0");
		
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
		continue;
			
		SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
	
	if(g_isMixRunning)
	{
		EndMix();
		LogToFile(SoccerLogPath, "CONSOLE has ended a Soccer Mix as the plugin was unloaded!");
	}
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == g_hSoccerMixGameTime)
	{
		SoccerGameTime = bool:StringToInt(newvalue);
	}
	else if (cvar == g_hSoccerMixModels)
	{
		SoccerUseModels = bool:StringToInt(newvalue);
	}
	else if (cvar == g_hSoccerMixCVarWarn)
	{
		SoccerWarnCVar = bool:StringToInt(newvalue);
	}
	else if (cvar == g_hSoccerMixAllowPause)
	{
		SoccerAllowPause = bool:StringToInt(newvalue);
	}
	else if (cvar == g_hSoccerMixBreakVote)
	{
		SoccerBreakVote = bool:StringToInt(newvalue);
	}
	else if (cvar == g_hSoccerMixUsePassword)
	{
		SoccerUsePass = bool:StringToInt(newvalue);
	}
	else if (cvar == g_hSoccerMixAutoUnload)
	{
		SoccerAutoUnload = bool:StringToInt(newvalue);	
	}
	
	/*
	else if(cvar == g_hSoccerMixHostServer)
	{
		GetConVarString(g_hSoccerMixHostServer, SoccerHost, sizeof(SoccerHost));
	}
	else if(cvar == g_hSoccerMixHostToCall)
	{
		GetConVarString(g_hSoccerMixHostToCall, SoccerDestination, sizeof(SoccerDestination));
	}
	else if(cvar == g_hSoccerMixHostServerPort)
	{
		GetConVarString(g_hSoccerMixHostServerPort, SoccerHostPort, sizeof(SoccerHostPort));
	}
	else if(cvar == g_hSoccerMixHostToCallPort)
	{
		GetConVarString(g_hSoccerMixHostToCallPort, SoccerDestinationPort, sizeof(SoccerDestinationPort));
	}*/
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Hooked CVar change. newvalue %s", newvalue);
	#endif
}


public OnMapStart()
{
	if(SoccerAutoUnload)
	{
		new String:MapName[256];
		GetCurrentMap(MapName, sizeof(MapName));
		
		if(StrContains(MapName, "ka_", false) != -1)
		{
			PrintToServer("[Soccer Mix] Detected soccer map, Loading...");

			InitPrecache();
	
			CreateTimer(10.0, Timer_UpdateCVars);
		}
		else
		{
			PrintToServer("[Soccer Mix] Detected non-soccer map, auto unloaded.");
			ServerCommand("sm plugins unload soccermix");
		}
	}
	else
	{
		InitPrecache();
	
		CreateTimer(10.0, Timer_UpdateCVars);
	}
}

InitPrecache()
{	
	PrecacheSound("soccer_mod_2008/match/endmatch.wav", true);
	PrecacheSound("soccer_mod_2008/match/prepare.mp3", true);
	PrecacheSound("soccer_mod_2008/match/kickoff.wav", true);
	PrecacheSound("soccer_mod_2008/match/halftime.wav", true);
	PrecacheSound("soccer_mod_2008/punishment/cheerleader_winwin.wav", true);
	PrecacheSound("soccer_mod_2008/punishment/fireworks.wav", true);
	PrecacheSound("soccer_mod_2008/punishment/cheerleader_gogo.wav", true);
	PrecacheSound("soccer_mod_2008/punishment/cheerleader_pushemback.mp3", true);
	PrecacheSound("soccer_mod_2008/punishment/itsred.mp3", true);
	PrecacheSound("soccer_mod_2008/punishment/lightning.mp3", true);
	
	AddFileToDownloadsTable("sound/soccer_mod_2008/match/endmatch.wav");
	AddFileToDownloadsTable("sound/soccer_mod_2008/match/prepare.mp3");
	AddFileToDownloadsTable("sound/soccer_mod_2008/match/kickoff.wav");
	AddFileToDownloadsTable("sound/soccer_mod_2008/match/halftime.wav");
	AddFileToDownloadsTable("sound/soccer_mod_2008/punishment/cheerleader_winwin.wav");
	AddFileToDownloadsTable("sound/soccer_mod_2008/punishment/fireworks.wav");
	AddFileToDownloadsTable("sound/soccer_mod_2008/punishment/cheerleader_gogo.wav");
	AddFileToDownloadsTable("sound/soccer_mod_2008/punishment/cheerleader_pushemback.mp3");
	AddFileToDownloadsTable("sound/soccer_mod_2008/punishment/itsred.mp3");
	AddFileToDownloadsTable("sound/soccer_mod_2008/punishment/lightning.mp3");

	PrecacheModel("models/player/soccermod/termi/2009/home/ct_urban.mdl");
	PrecacheModel("models/player/soccermod/termi/2009/gkhome/ct_urban.mdl");
	PrecacheModel("models/player/soccermod/termi/2009/away/ct_urban.mdl");
	PrecacheModel("models/player/soccermod/termi/2009/gkaway/ct_urban.mdl");
	
	AddFileToDownloadsTable("materials/models/player/soccermod/termi/2009/home/skin_foot_a2.vmt");
	AddFileToDownloadsTable("materials/models/player/soccermod/termi/2009/home/skin_foot_a2.vtf");
	AddFileToDownloadsTable("materials/models/player/soccermod/termi/2009/gkhome/skin_foot_a2.vmt");
	AddFileToDownloadsTable("materials/models/player/soccermod/termi/2009/gkhome/skin_foot_a2.vtf");
	AddFileToDownloadsTable("materials/models/player/soccermod/termi/2009/away/skin_foot_a2.vmt");
	AddFileToDownloadsTable("materials/models/player/soccermod/termi/2009/away/skin_foot_a2.vtf");
	AddFileToDownloadsTable("materials/models/player/soccermod/termi/2009/gkaway/skin_foot_a2.vmt");
	AddFileToDownloadsTable("materials/models/player/soccermod/termi/2009/gkaway/skin_foot_a2.vtf");
	
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/home/ct_urban.phy");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/home/ct_urban.vvd");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/home/ct_urban.mdl");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/home/ct_urban.sw.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/home/ct_urban.dx90.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/home/ct_urban.dx80.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/home/ct_urban.xbox.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkhome/ct_urban.phy");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkhome/ct_urban.vvd");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkhome/ct_urban.mdl");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkhome/ct_urban.sw.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkhome/ct_urban.dx90.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkhome/ct_urban.dx80.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkhome/ct_urban.xbox.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/away/ct_urban.phy");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/away/ct_urban.vvd");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/away/ct_urban.mdl");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/away/ct_urban.sw.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/away/ct_urban.dx90.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/away/ct_urban.dx80.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/away/ct_urban.xbox.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkaway/ct_urban.phy");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkaway/ct_urban.vvd");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkaway/ct_urban.mdl");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkaway/ct_urban.sw.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkaway/ct_urban.dx90.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkaway/ct_urban.dx80.vtx");
	AddFileToDownloadsTable("models/player/soccermod/termi/2009/gkaway/ct_urban.xbox.vtx");
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] InitPrecache FINISHED");
	#endif
}
public Action:Command_SetTime(client, args)
{
	new String:arg[256];
	GetCmdArg(1, arg, sizeof(arg));
	
	new value = StringToInt(arg);
	
	Time_Left = value;
	
	CPrintToChat(client, "{green}[Soccer Mix]{default} Successfully set varriable {yellow}'{white}Time_Left{yellow}'{default} to: {cyan}%i{default}({red}%02i:%02i{default})", Time_Left, Time_Left / 60, Time_Left % 60);
}

public Action:Command_SetBreak(client, args)
{
	new String:arg[256];
	GetCmdArg(1, arg, sizeof(arg));
	
	new value = StringToInt(arg);
	
	Break_Time = value;
	
	CPrintToChat(client, "{green}[Soccer Mix]{default} Successfully set varriable {yellow}'{white}Break_Time{yellow}'{default} to: {cyan}%i{default}({red}%02i:%02i{default})", Break_Time, Break_Time / 60, Break_Time % 60);
}

public Action:Command_Score(client, args)
{
	CPrintToChat(client, "{green}[Soccer Mix]{default} Round number is: {lightgreen}%i{default} - Half {yellow}%i{default}/{yellow}2", g_CurrentRound, g_Half);
	CPrintToChat(client, "{green}[Soccer Mix]{default} Home: {cyan}%i{default} {white}--{default} Away: {cyan}%i", g_HomeScore, g_AwayScore);
	
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	if(!SoccerWarnCVar)
	{
		return;
	}

	QueryClientConVar(client, "cl_interp", ConVarQueryFinished:ClientCLInterp, client);
	QueryClientConVar(client, "cl_interp_ratio", ConVarQueryFinished:ClientCLInterpRatio, client);
}

public ClientCLInterp(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if(!StrEqual(cvarValue, "0.02"))
	{
		CPrintToChat(client, "{green}[Soccer Mix]{red} ConVar-WARNING:{default} Go to spec and write in console: {white}cl_interp{default} {cyan}0.02");
	}
}

public ClientCLInterpRatio(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
 	if(!StrEqual(cvarValue, "1"))
	{
		CPrintToChat(client, "{green}[Soccer Mix]{red} ConVar-WARNING:{default} Go to Spec and Write in Console: {white}cl_interp_ratio{default} {cyan}1");
	}
}

public Action:Timer_UpdateRunningTime(Handle:timer)
{
	if(g_isMixRunning == true)
	{
		if(g_isMixPaused == false)
		{
			if(Time_Left > 0)
			{
				if(g_breakFinished == false)
				{
					if(Time_Left > Time_Half)
					{
						PrintHintTextToAll("Soccer Mix Timeleft %02i:%02i", Time_Left / 60, Time_Left % 60);
						
						if(g_allowTimeDecrease == true)
						{
							Time_Left--;
						}
					}
					else
					{
						StartBreak();
				
						if(g_breakRestarted == false)
						{
							ServerCommand("mp_restartgame 3");
							g_breakRestarted = true;
						}
				
						PrintHintTextToAll("Soccer Mix Break Time %02i:%02i", Break_Time / 60, Break_Time % 60);
						Break_Time--;
					}
				}
				else
				{
					if(g_isBreakRunning == false)
					{
						PrintHintTextToAll("Soccer Mix Timeleft %02i:%02i", Time_Left / 60, Time_Left % 60);
			
						if(g_allowTimeDecrease == true)
						{
							Time_Left--;
						}
					}
				}
			}
			else
			{
				EndMix();
			}
		}
		else
		{
			PrintHintTextToAll("Soccer Mix Pause Time %02i:%02i", Already_Paused_Time / 60, Already_Paused_Time % 60);
			PrintCenterTextAll("Soccer Mix is currently PAUSED");
			Already_Paused_Time++;
		}
	}
}

public Action:onRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CPrintToChatAll("{green}[Soccer Mix]{default} This server is powered by {red}SoccerMix {white}v%s", PLUGIN_VERSION);
	
	g_allowTimeDecrease = false;
	PlayerGoaled = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		continue;
		
		SetEntProp(i, Prop_Data, "m_takedamage", 3, 1);
		
		SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	}
	
	if(g_isMixRunning == true)
	{
		if(g_isMixPaused == false)
		{
			SetTeamScore(2, g_HomeScore);
			SetTeamScore(3, g_AwayScore);
		
			CPrintToChatAll("{green}[Soccer Mix]{default} Round number is: {lightgreen}%i{default} - Half {yellow}%i{default}/{yellow}2", g_CurrentRound, g_Half);
			CPrintToChatAll("{green}[Soccer Mix]{default} Home: {cyan}%i{default} {white}--{default} Away: {cyan}%i", g_HomeScore, g_AwayScore);
			CreateTimer(2.0, Timer_AllowTimeDecrease);
		}
		else
		{
			CPrintToChatAll("{green}[Soccer Mix]{default} Mix is currently {red}PAUSED");
		}
	}
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Event onRoundStart");
	#endif
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(damagetype & DMG_FALL || damagetype & DMG_BULLET || damagetype & DMG_SLASH)
	{
		#if defined DEBUG
		CPrintToChatAll("[Soccer Mix Debug] Fired Hook damagetype & DMG_FALL/DMG_BULLET/DMG_SLASH");
		#endif
	
		return Plugin_Handled;
	}
	else if(damagetype & DMG_CRUSH)
	{
		damage = 0.0;
		
		#if defined DEBUG
		CPrintToChatAll("[Soccer Mix Debug] Fired Hook damagetype & DMG_CRUSH");
		#endif
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action:onRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isMixRunning == true)
	{
		if(g_isMixPaused == false)
		{
			new WinningTeam = GetEventInt(event, "winner");
			if (WinningTeam == 2)
			{
				g_HomeScore++;
			}
			else if (WinningTeam == 3)
			{
				g_AwayScore++;
			}
			
			g_CurrentRound++;
		}
		else
		{
			CPrintToChatAll("{green}[Soccer Mix]{default} Scoring doesn't count as the mix is {red}PAUSED");
		}
		
		#if defined DEBUG
		CPrintToChatAll("[Soccer Mix Debug] Fired Event onRoundEnd (mix-running)");
		#endif
	}
	
	if(!PlayerGoaled)
	{
		LogToFile(SoccerLogPath, "Failure on GetClientFrags(client index: %i)", PlayerGoaled);
		return;
	}
	
	if(!IsPlayerAlive(PlayerGoaled))
	{
		new CurrentFrags = GetClientFrags(PlayerGoaled);
		new TotalFrags = CurrentFrags - 1;		
		
		SetClientFrags(PlayerGoaled, TotalFrags);
	
		CPrintToChatAll("{green}[Soccer Mix] {olive}%N{default} scored a {white}OWN GOAL{default}!", PlayerGoaled);
		return;
	}
	
	if(PlayerGoaled != PlayerPassed)
	{
		if(PlayerPassed != 0 && PlayerGoaled != 0)
		{
				new PassTeam = GetClientTeam(PlayerPassed);
				new GoalTeam = GetClientTeam(PlayerGoaled);
				
				new CurrentFrags = GetClientFrags(PlayerGoaled);
				new TotalFrags = CurrentFrags + 1;		
				
				if(GoalTeam == PassTeam)
				{
					SetClientFrags(PlayerGoaled, TotalFrags);
			
					CPrintToChatAll("{green}[Soccer Mix] {olive}%N{default} scored a {white}GOAL{default}! {yellow}%N{default} assisted!", PlayerGoaled, PlayerPassed);
				}
				else
				{	
					SetClientFrags(PlayerGoaled, TotalFrags);
					CPrintToChatAll("{green}[Soccer Mix] {olive}%N{default} scored a {white}GOAL{default}!", PlayerGoaled);
				}
		}
		else
		{
			new CurrentFrags = GetClientFrags(PlayerGoaled);
				
			new TotalFrags = CurrentFrags + 1;
				
			SetClientFrags(PlayerGoaled, TotalFrags);
			CPrintToChatAll("{green}[Soccer Mix] {olive}%N{default} scored a {white}GOAL{default}!", PlayerGoaled);
		}
	}
	else
	{
		new CurrentFrags = GetClientFrags(PlayerGoaled);
				
		new TotalFrags = CurrentFrags + 1;
				
		SetClientFrags(PlayerGoaled, TotalFrags);
		CPrintToChatAll("{green}[Soccer Mix] {olive}%N{default} scored a {white}GOAL{default}!", PlayerGoaled);
	}
}

public Action:onPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);

	SetEntProp(client, Prop_Data, "m_takedamage", 3, 1);
		
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	
	CreateTimer(1.0, Timer_ApplyModel, client);
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Event onPlayerSpawn");
	#endif
}

public Action:onPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);

	new Frags = GetClientFrags(client);
	new Deaths = GetClientDeaths(client);
		
	SetClientFrags(client, Frags + 1);
	SetClientDeaths(client, Deaths - 1);
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Event onPlayerDeath");
	#endif
}

public Action:Command_StartMix(client, args)
{
	if(args == 0)
	{
		g_hMixMenu = CreateMenu(MixMenuHandler);
	
		SetMenuTitle(g_hMixMenu, "Soccer Mix");
		
		AddMenuItem(g_hMixMenu, "specall", "Pre-Teams");
		
		if(!g_isPreparing)
		{
			AddMenuItem(g_hMixMenu, "start prepare", "Start Prepare");
		}
		else
		{
			AddMenuItem(g_hMixMenu, "end prepare", "End Prepare");
		}
		
		if(g_isMixRunning)
		{
			AddMenuItem(g_hMixMenu, "start-mix", "Start Mix", ITEMDRAW_DISABLED);
		}
		else
		{
			AddMenuItem(g_hMixMenu, "start-mix", "Start Mix");
		}
		
		if(!g_isMixPaused)
		{
			AddMenuItem(g_hMixMenu, "pause", "Pause Mix");
		}
		else
		{
			AddMenuItem(g_hMixMenu, "unpause", "Unpause Mix");
		}
		
		if(!g_isMixRunning)
		{
			AddMenuItem(g_hMixMenu, "end-mix", "End Mix", ITEMDRAW_DISABLED);
		}
		else
		{
			AddMenuItem(g_hMixMenu, "end-mix", "End Mix");
		}
		
		DisplayMenu(g_hMixMenu, client, MENU_TIME_FOREVER);
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	decl String:sNewDate[100];
	FormatTime(sNewDate, sizeof(sNewDate), "%d-%m-%Y - %H:%M:%S", GetTime());
	
	if(StrEqual(arg, "1"))
	{
		StartMix();
		EmitAmbientSound("soccer_mod_2008/match/kickoff.wav", vec, client, SNDLEVEL_RAIDSIREN);
		
		LogToFile(SoccerLogPath, "%N started a new Soccer Mix at %s", client, sNewDate);
	}
	else if(StrEqual(arg, "0"))
	{	
		EndMix();
		EmitAmbientSound("soccer_mod_2008/match/endmatch.wav", vec, client, SNDLEVEL_RAIDSIREN);
		
		LogToFile(SoccerLogPath, "%N ended a Soccer Mix at %s", client, sNewDate);
	}
	
	return Plugin_Handled;
}

public MixMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new Float:vec[3];
		GetClientEyePosition(param1, vec);
		
		decl String:sNewDate[100];
		FormatTime(sNewDate, sizeof(sNewDate), "%d-%m-%Y - %H:%M:%S", GetTime());
	
		if(param2 == 0)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i))
				continue;
				
				ChangeClientTeam(i, 1);
			}
			
			CPrintToChat(param1, "{green}[Soccer Mix]{default} Moved all players to Spectator");
		}
	
		if(param2 == 1)
		{
			if(!g_isPreparing)
			{
				ServerCommand("sv_alltalk 0");
				EmitAmbientSound("soccer_mod_2008/match/prepare.mp3", vec, param1, SNDLEVEL_RAIDSIREN);
				g_isPreparing = true;
			}
			else
			{
				ServerCommand("sv_alltalk 1");
				g_isPreparing = false;
			}
			
			CloseHandle(menu);
		}
		
		if(param2 == 2)
		{
			StartMix();
			EmitAmbientSound("soccer_mod_2008/match/kickoff.wav", vec, param1, SNDLEVEL_RAIDSIREN);
			
			LogToFile(SoccerLogPath, "%N started a new Soccer Mix at %s", param1, sNewDate);
			
			CloseHandle(menu);
		}
	
		if(param2 == 3)
		{
			new data;
			
			if(!g_isMixPaused)
			{
				Already_Paused_Time = 0;
				g_isMixPaused = true;
				CPrintToChatAll("{green}[Soccer Mix]{default} Mix is currently {red}PAUSED{default}.");
		
				data = 0;
			}
			else
			{
				Already_Paused_Time = 0;
				g_isMixPaused = false;
				CPrintToChatAll("{green}[Soccer Mix]{default} Mix is currently {red}UNPAUSED{default}.");
		
				data = 1;
			}
			
			CreateTimer(0.1, Timer_EnableDisableBall, data);
			CloseHandle(menu);
		}
		
		if(param2 == 4)
		{
			g_hConfirmMenu = CreateMenu(ConfirmMenuHandler);
			
			SetMenuTitle(g_hConfirmMenu, "Are you sure you want to stop the current mix?");
			
			AddMenuItem(g_hConfirmMenu, "yes", "Yes");
			AddMenuItem(g_hConfirmMenu, "no", "No");
			
			SetMenuExitButton(g_hConfirmMenu, false);
	
			DisplayMenu(g_hConfirmMenu, param1, MENU_TIME_FOREVER);
			
			CloseHandle(menu);
		}
		
	}
}

public ConfirmMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 0)
		{
			new Float:vec[3];
			GetClientEyePosition(param1, vec);
		
			decl String:sNewDate[100];
			FormatTime(sNewDate, sizeof(sNewDate), "%d-%m-%Y - %H:%M:%S", GetTime());
		
			EndMix();
			EmitAmbientSound("soccer_mod_2008/match/endmatch.wav", vec, param1, SNDLEVEL_RAIDSIREN);
			
			LogToFile(SoccerLogPath, "%N ended a Soccer Mix at %s", param1, sNewDate);
			
			CloseHandle(menu);
		}
		
		if(param2 == 1)
		{
			CloseHandle(menu);
		}
	}
}

public BreakVoteHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_VoteEnd) 
	{
		if (param1 == 0)
		{
			g_Half = 2; 
			g_breakFinished = true;
			
			CreateTimer(3.0, Timer_SecureNoGoalAfterBreak);
			
			ServerCommand("mp_restartgame 3");
			ServerCommand("mp_freezetime 3"); 
			
			CPrintToChatAll("{green}[Soccer Mix]{default} Break stopped! Voting has choosen to end the break!");
			
			CloseHandle(menu);
		}
		
		if(param1 == 1)
		{
			CPrintToChatAll("{gteen}[Soccer Mix]{default} Break continues!");
			CloseHandle(menu);
		}
	}
}

public Action:Command_Prepare(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Usage: !prepare <1/0>");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	if(StrEqual(arg, "1"))
	{
		ServerCommand("sv_alltalk 0");
		EmitAmbientSound("soccer_mod_2008/match/prepare.mp3", vec, client, SNDLEVEL_RAIDSIREN);
		g_isPreparing = true;
	}
	else if(StrEqual(arg, "0"))
	{	
		ServerCommand("sv_alltalk 1");
		g_isPreparing = false;
	}
	else
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Usage: !prepare <1/0>");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Command_AskPause(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Usage: !askpause <minutes>");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	new minutes = StringToInt(arg);
	
	CPrintToChatAll("{green}[Soccer Mix]{default} {olive}%N{default} is requesting a pause for {cyan}%i{default} minutes!", client, minutes); 
	
	return Plugin_Handled;
}

public Action:Command_PauseMix(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Usage: !pause <1/0>");
		return Plugin_Handled;
	}
	
	if(!SoccerAllowPause)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Pause is disabled on this server.");
		return Plugin_Handled;
	}
	
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	new data;
	
	if(StrEqual(arg, "1"))
	{
		Already_Paused_Time = 0;
		g_isMixPaused = true;
		CPrintToChatAll("{green}[Soccer Mix]{default} Mix is currently {red}PAUSED{default}.");
		
		data = 0;
		
		CreateTimer(0.1, Timer_EnableDisableBall, data);
	}
	else if(StrEqual(arg, "0"))
	{
		Already_Paused_Time = 0;
		g_isMixPaused = false;
		CPrintToChatAll("{green}[Soccer Mix]{default} Mix is currently {red}UNPAUSED{default}.");
		
		data = 1;
		
		CreateTimer(0.1, Timer_EnableDisableBall, data);
	}
	else
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Usage: !pause <1/0>");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action:Command_JoinTeam(client, const String:command[], args)
{
	new String:TeamChosen[8];
	GetCmdArg(1, TeamChosen, sizeof(TeamChosen));
	
	if(!StrEqual(TeamChosen, "1"))
	{
		CreateTimer(1.0, Timer_RespawnPlayer, client);
		
		if(SoccerWarnCVar)
		{
			QueryClientConVar(client, "cl_interp", ConVarQueryFinished:ClientCLInterp, client);
			QueryClientConVar(client, "cl_interp_ratio", ConVarQueryFinished:ClientCLInterpRatio, client);
		}
	}
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Listener Command_JoinTeam");
	#endif
	
	return Plugin_Continue;
}

public Action:Command_RestartGame(client, const String:command[], args)
{
	PlayerGoaled = 0;
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Listener Command_RestartGame");
	#endif
	
	return Plugin_Continue;
}

public Action:Command_Kill(client, const String:command[], args)
{
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Listener Command_Kill");
	#endif

	return Plugin_Stop;
}

public Action:Command_GoalKeeperT(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Usage: !gkt <name>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Error while processing GK Command");
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		new Team = GetClientTeam(target_list[i]);
		
		if(Team == 2)
		{
			SetEntityModel(target_list[i], "models/player/soccermod/termi/2009/gkhome/ct_urban.mdl");
			g_isGKT[target_list[i]] = true;
		
			CPrintToChat(client, "{green}[Soccer Mix]{default} Successfuly set Goal Keeper to {yellow}%N", target_list[i]);
		}
		else
		{
			CPrintToChat(client, "{green}[Soccer Mix]{yellow}%N{default} ins't a Terrorist!", target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_GoalKeeperCT(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Usage: !gkct <name>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Error while processing GK Command");
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		new Team = GetClientTeam(target_list[i]);
		
		if(Team == 3)
		{
			SetEntityModel(target_list[i], "models/player/soccermod/termi/2009/gkaway/ct_urban.mdl");
			g_isGKCT[target_list[i]] = true;
		
			CPrintToChat(client, "{green}[Soccer Mix] {default} Successfuly set Goal Keeper to {yellow}%N", target_list[i]);
		}
		else
		{
			CPrintToChat(client, "{green}[Soccer Mix] {yellow}%N{default} ins't a Counter-Terrorist!", target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_UnGoalKeeper(client, args)
{
	if(args < 1)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Usage: !ungk <name>");
		return Plugin_Handled;
	}

	new String:arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
 
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} Error while processing UNGK Command");
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		new Team = GetClientTeam(target_list[i]);
		
		if(Team == 2)
		{
			g_isGKT[target_list[i]] = false;
			SetEntityModel(target_list[i], "models/player/soccermod/termi/2009/home/ct_urban.mdl");
			
			CPrintToChat(client, "{green}[Soccer Mix] {default} Successfuly unset Goal Keeper to {yellow}%N", target_list[i]);
		}
		else if(Team == 3)
		{
			g_isGKCT[target_list[i]] = false;
			SetEntityModel(target_list[i], "models/player/soccermod/termi/2009/away/ct_urban.mdl");
			
			CPrintToChat(client, "{green}[Soccer Mix] {default} Successfuly unset Goal Keeper to {yellow}%N", target_list[i]);
		}
	}
	
	return Plugin_Handled;
}

/*
	new String:requestStr[100];
	Format(requestStr, sizeof(requestStr), "{green}[Soccer Mix]{default} Server Soccer({yellow}%s:%d{default}) is requesting a sub! Type !join to join the mix!", SoccerHost, hostport);
	SocketSend(socket, requestStr);


public Action:Command_SubNeeded(client, args)
{
	new destport = StringToInt(SoccerDestinationPort);

	if(cURLConnecting)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} cURL is in connecting state.");
		return Plugin_Handled;
	}
	else if(cURLWaitingReply)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} cURL is waiting for reply.");
		return Plugin_Handled;
	}
	else if(cURLConnected)
	{
		CPrintToChat(client, "{green}[Soccer Mix]{default} cURL is already connected!");
		return Plugin_Handled;
	}
	
	
	cURLConnection = curl_easy_init();
	
	if(cURLConnection != INVALID_HANDLE)
	{
		//CURL_DEFAULT_OPT(curl_echo);
		curl_easy_setopt_int(cURLConnection, CURLOPT_CONNECT_ONLY, 1);
		curl_easy_setopt_string(cURLConnection, CURLOPT_URL, SoccerDestination);
		curl_easy_setopt_int(cURLConnection, CURLOPT_PORT, destport);
		curl_easy_perform_thread(cURLConnection, OnEchoServerConnected);
		
		cURLConnecting = true;
		
		CreateTimer(10.0, Timer_SendSubRequest);
	} 
	else 
	{
		cURLConnected = false;
		cURLConnecting = false;
	}
	
	return Plugin_Handled;
}

public OnEchoServerConnected(Handle:hndl, CURLcode: code, any:data)
{
	cURLConnecting = false;
	
	if(code != CURLE_OK)
	{
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		LogToFile(SoccerLogPath, "Connection to %s:%s has failed. Error code: %s", SoccerDestination, SoccerDestinationPort, error_buffer);
		CloseHandle(cURLConnection);
		cURLConnection = INVALID_HANDLE;
		cURLConnected = false;
		return;
	}
	
	LogToFile(SoccerLogPath, "Successfully connected to %s:%s!", SoccerDestination, SoccerDestinationPort);
	
	cURLWaitingReply = false;
	cURLConnected = true;
	curl_easy_send_recv(cURLConnection, cURLSend_Callback, cURLRecv_Callback, cURLSend_Recv_Complete_Callback, SendRecv_Act_GOTO_WAIT, 60000 , 60000);
}

public SendRecv_Act:cURLSend_Callback(Handle:hndl, CURLcode: code, const last_sent_dataSize)
{
	if(code != CURLE_OK)
	{
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		LogToFile(SoccerLogPath, "cURLSend_Callback to %s:%s has failed. Error code: %s", SoccerDestination, SoccerDestinationPort, error_buffer);
		return SendRecv_Act_GOTO_END;
	}
	return SendRecv_Act_GOTO_RECV;
}

public SendRecv_Act:cURLRecv_Callback(Handle:hndl, CURLcode: code, const String:receiveData[], const dataSize)
{
	if(code != CURLE_OK)
	{
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		LogToFile(SoccerLogPath, "cURLRecv_Callback to %s:%s has failed. Error code: %s", SoccerDestination, SoccerDestinationPort, error_buffer);
		return SendRecv_Act_GOTO_END;
	}
	
	new String:buffer[dataSize];
	strcopy(buffer,dataSize, receiveData);
	PrintToServer("Echo Receive: DataSize - %d",dataSize);
	PrintToServer("Echo Receive: Data - %s",buffer);
	cURLWaitingReply = false;
	return SendRecv_Act_GOTO_WAIT;
}

public cURLSend_Recv_Complete_Callback(Handle:hndl, CURLcode: code)
{
	LogToFile(SoccerLogPath, "(cURLSend_Recv_Complete_Callback)Successfully disconnected from %s:%s!", SoccerDestination, SoccerDestinationPort);
	if(code != CURLE_OK)
	{
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		LogToFile(SoccerLogPath, "(cURLSend_Recv_Complete_Callback)Error on dissconnection: %s", error_buffer);
	}
	
	CloseHandle(cURLConnection);
	cURLConnection = INVALID_HANDLE;
	cURLConnected = false;
	cURLConnecting = false;
}

public Action:Timer_SendSubRequest(Handle:timer, any:client)
{
	new hostport = StringToInt(SoccerHostPort);

	//new String:requestStr[100];
	//Format(requestStr, sizeof(requestStr), "{green}[Soccer Mix]{default} Server Soccer({yellow}%s:%d{default}) is requesting a sub! Type !join to join the mix!", SoccerHost, hostport);
	
	new String:requestStr[100];
	Format(requestStr, sizeof(requestStr), "This is a test, ignore it!\n");

	cURLWaitingReply = true;
	PrintToServer("Echo Send: %s", requestStr);
	curl_set_send_buffer(cURLConnection, requestStr);
	curl_send_recv_Signal(cURLConnection, SendRecv_Act_GOTO_SEND);
	return Plugin_Handled;
}	
*/

public Action:Timer_RespawnPlayer(Handle:timer, any:client)
{
	if(!IsPlayerAlive(client))
	{
		CS_RespawnPlayer(client);
		
		if(g_isMixPaused == true)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
		}
	}
}	

StartMix()
{
	g_isMixRunning = true;
	g_isMixPaused = false;
	g_breakFinished = false;
	g_breakRestarted = false;
	g_isBreakRunning = false;
	g_allowTimeDecrease = false;
	g_runnedBreakSound = false;
	
	g_AwayScore = 0;
	g_HomeScore = 0;
	g_CurrentRound = 0;
	g_Half = 1;
	Time_Left = SoccerGameTime;
	Time_Half = Time_Left / 2;
	Break_Time = 60;
	Already_Paused_Time = 0;
	SoundCount = 0;
	
	ServerCommand("mp_restartgame 1");
	ServerCommand("mp_freezetime 3");
	ServerCommand("sv_alltalk 0");
	ServerCommand("mp_limitteams 5");
	
	CPrintToChatAll("{green}[Soccer Mix]{default} Mix has begun!");
	
	if(SoccerUsePass)
	{
		new RandomPass = GetRandomInt(100, 1000);
		SetConVarInt(g_hServerPassword, RandomPass);
		
		new String:FormatPassword[256];
		Format(FormatPassword, sizeof(FormatPassword), "Successfully set server password to %d", RandomPass);
		PrintToAdmins(FormatPassword);
	}
	
	CreateTimer(300.0, Timer_EmitSounds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Func_StartMix();");
	#endif
}

EndMix()
{
	EnableBall();

	g_isMixRunning = false;
	g_isMixPaused = false;
	g_breakFinished = false;
	g_breakRestarted = false;
	g_allowTimeDecrease = false;
	g_runnedBreakSound = false;
	
	ServerCommand("mp_freezetime 0");
	ServerCommand("sv_alltalk 1");
	ServerCommand("mp_limitteams 0");
	ServerCommand("mp_restartgame 10");
	
	if(g_AwayScore > g_HomeScore)
	{
		CPrintToChatAll("{green}[Soccer Mix] the {gray}W{chocolate}i{chocolate}{orange}n{gold}n{lightgoldenrodyellow}e{black}{lightgreen}r{firebrick}s{default} are Team Away!");
		CPrintToChatAll("{green}[Soccer Mix] Team Away won the game with a score of %i goals!", g_AwayScore);
		CPrintToChatAll("{green}[Soccer Mix] the {gray}W{chocolate}i{chocolate}{orange}n{gold}n{lightgoldenrodyellow}e{black}{lightgreen}r{firebrick}s{default} are Team Away!");
		CPrintToChatAll("{green}[Soccer Mix] Team Away won the game with a score of %i goals!", g_AwayScore);
		CPrintToChatAll("{green}[Soccer Mix] the {gray}W{chocolate}i{chocolate}{orange}n{gold}n{lightgoldenrodyellow}e{black}{lightgreen}r{firebrick}s{default} are Team Away!");
		CPrintToChatAll("{green}[Soccer Mix] Team Away won the game with a score of %i goals!", g_AwayScore);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
			continue;
			
			new Float:vec[3];
			GetClientEyePosition(i, vec);
			
			EmitAmbientSound("soccer_mod_2008/punishment/cheerleader_winwin.wav", vec, i, SNDLEVEL_RAIDSIREN);
			EmitAmbientSound("soccer_mod_2008/punishment/fireworks.wav", vec, i, SNDLEVEL_RAIDSIREN);
		}
	}
	else if(g_AwayScore < g_HomeScore)
	{
		CPrintToChatAll("{green}[Soccer Mix] the {gray}W{chocolate}i{chocolate}{orange}n{gold}n{lightgoldenrodyellow}e{black}{lightgreen}r{firebrick}s{default} are Team Home!");
		CPrintToChatAll("{green}[Soccer Mix] Team Home won the game with a score of %i goals!", g_HomeScore);
		CPrintToChatAll("{green}[Soccer Mix] the {gray}W{chocolate}i{chocolate}{orange}n{gold}n{lightgoldenrodyellow}e{black}{lightgreen}r{firebrick}s{default} are Team Home!");
		CPrintToChatAll("{green}[Soccer Mix] Team Home won the game with a score of %i goals!", g_HomeScore);
		CPrintToChatAll("{green}[Soccer Mix] the {gray}W{chocolate}i{chocolate}{orange}n{gold}n{lightgoldenrodyellow}e{black}{lightgreen}r{firebrick}s{default} are Team Home!");
		CPrintToChatAll("{green}[Soccer Mix] Team Home won the game with a score of %i goals!", g_HomeScore);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
			continue;
			
			new Float:vec[3];
			GetClientEyePosition(i, vec);
			
			EmitAmbientSound("soccer_mod_2008/punishment/fireworks.wav", vec, i, SNDLEVEL_RAIDSIREN);
			EmitAmbientSound("soccer_mod_2008/punishment/cheerleader_winwin.wav", vec, i, SNDLEVEL_RAIDSIREN);
		}
	}
	
	ServerCommand("sm_evilrocket @all");
	
	CPrintToChatAll("{green}[Soccer Mix]{default} Mix has ended!");
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
		continue;
		
		g_isGKT[i] = false;
		g_isGKCT[i] = false;
	}
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Func_EndMix();");
	#endif
}

StartBreak()
{
	if(g_runnedBreakSound == false)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
			continue;
			
			new Float:vec[3];
			GetClientEyePosition(i, vec);
			
			EmitAmbientSound("soccer_mod_2008/match/halftime.wav", vec, i, SNDLEVEL_RAIDSIREN);
			g_runnedBreakSound = true;
			g_isBreakRunning = true;
		}
		
		if(SoccerBreakVote)
		{
			g_hBreakVMenu = CreateMenu(BreakVoteHandler);
			
			SetMenuTitle(g_hBreakVMenu, "Would you like to stop the break?");
			
			AddMenuItem(g_hBreakVMenu, "yes", "Yes");
			AddMenuItem(g_hBreakVMenu, "no", "No");
			
			SetMenuExitButton(g_hBreakVMenu, false);
			
			VoteMenuToAll(g_hBreakVMenu, 15);
		}
		
		CreateTimer(1.0, Timer_MixBreak, _, TIMER_REPEAT);
		ServerCommand("mp_freezetime 0");
		
		#if defined DEBUG
		CPrintToChatAll("[Soccer Mix Debug] Fired Func_StartBreak();");
		#endif
	}
}

stock RequestClientJoin(client)
{
	new Handle:kv = CreateKeyValues("menu");
	KvSetString(kv, "time", "10");
	Format(address, sizeof(address), "%s:%s", SoccerDestination, SoccerDestinationPort);
	KvSetString(kv, "title", address);
	CreateDialog(client, kv, DialogType_AskConnect);
	CloseHandle(kv);
}

public Action:Timer_MixBreak(Handle:timer)
{
	if(g_isMixRunning)
	{
		if(g_isBreakRunning)
		{
			if(Break_Time >= 0)
			{
				DisableBall();
			}
			else
			{	
				CreateTimer(3.0, Timer_SecureNoGoalAfterBreak);
		
				g_breakFinished = true;
			
				for(new i = 1; i <= MaxClients; i++)
				{
					if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
					continue;
			
					new Float:vec[3];
					GetClientEyePosition(i, vec);
			
					EmitAmbientSound("soccer_mod_2008/match/halftime.wav", vec, i, SNDLEVEL_RAIDSIREN);
				}
		
		
				ServerCommand("mp_restartgame 3");
				ServerCommand("mp_freezetime 3");
		
				g_Half = 2;
		
				KillTimer(timer);
			}
		}
		else
		{
			KillTimer(timer);
		}
	}
	else
	{
		EnableBall();
		g_isBreakRunning = false;
		KillTimer(timer);
	}
}

public Action:Timer_SecureNoGoalAfterBreak(Handle:timer)
{
	EnableBall();
	g_isBreakRunning = false;
	Time_Left++;
}

public Action:Timer_AllowTimeDecrease(Handle:timer)
{
	g_allowTimeDecrease = true;
}

public Action:Timer_ApplyModel(Handle:timer, any:client)
{
	if(!client)
	{
		CreateTimer(1.0, Timer_ApplyModel, client);
	}
	
	if(!SoccerUseModels)
	{
		return;
	}

	new Team = GetClientTeam(client);
	
	if(g_isGKT[client] == true && Team == 2)
	{
		SetEntityModel(client, "models/player/soccermod/termi/2009/gkhome/ct_urban.mdl");
	}
	else if(g_isGKT[client] == false && Team == 2)
	{
		SetEntityModel(client, "models/player/soccermod/termi/2009/home/ct_urban.mdl");
	}
	
	if(g_isGKCT[client] == true && Team == 3)
	{
		SetEntityModel(client, "models/player/soccermod/termi/2009/gkaway/ct_urban.mdl");
	}
	else if(g_isGKCT[client] == false && Team == 3)
	{
		SetEntityModel(client, "models/player/soccermod/termi/2009/away/ct_urban.mdl");
	}
}

public Action:Timer_EnableDisableBall(Handle:timer, any:data)
{
	if(data == 0)
	{
		//DisableBall();
		
		ServerCommand("phys_timescale 0.0");
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
			continue;
			
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.0);
			
			new Float:vec[3];
			GetClientEyePosition(i, vec);
			EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", vec, i, SNDLEVEL_RAIDSIREN);
		}
	}
	else if(data == 1)
	{
		//EnableBall();
		
		ServerCommand("phys_timescale 1.0");
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
			continue;
			
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
			
			new Float:vec[3];
			GetClientEyePosition(i, vec);
			EmitAmbientSound("physics/glass/glass_impact_bullet4.wav", vec, i, SNDLEVEL_RAIDSIREN);
		}
	}
}

public Action:Timer_EmitSounds(Handle:timer)
{
	if(SoundCount == 5)
	{
		KillTimer(timer);
	}
	
	new RandomSound = GetRandomInt(1, 4);
	
	switch(RandomSound)
	{
		case 1:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
				continue;
			
				new Float:vec[3];
				GetClientEyePosition(i, vec);
			
				EmitAmbientSound("soccer_mod_2008/punishment/cheerleader_gogo.wav", vec, i, SNDLEVEL_RAIDSIREN);
			}	
		}
		case 2:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
				continue;
			
				new Float:vec[3];
				GetClientEyePosition(i, vec);
			
				EmitAmbientSound("soccer_mod_2008/punishment/cheerleader_pushemback.mp3", vec, i, SNDLEVEL_RAIDSIREN);
			}
		}
		case 3:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
				continue;
			
				new Float:vec[3];
				GetClientEyePosition(i, vec);
			
				EmitAmbientSound("soccer_mod_2008/punishment/itsred.mp3", vec, i, SNDLEVEL_RAIDSIREN);
			}
		}
		case 4:
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(!IsClientConnected(i) || IsFakeClient(i) || !IsClientInGame(i))
				continue;
			
				new Float:vec[3];
				GetClientEyePosition(i, vec);
			
				EmitAmbientSound("soccer_mod_2008/punishment/lightning.mp3", vec, i, SNDLEVEL_RAIDSIREN);
			}
		}
	}
}

public Action:Timer_UpdateCVars(Handle:timer)
{
	ServerCommand("mp_autoteambalance 1");
	ServerCommand("sv_alltalk 1");
}

public OnEntityCreated(edict, const String:classname[])
{
	if(IsValidEdict(edict) && IsValidEntity(edict))
	{
		if(StrEqual(classname, "func_physbox"))
		{
			SDKHook(edict, SDKHook_OnTakeDamage, OnEntityTakeDamage);
			
			#if defined DEBUG
			CPrintToChatAll("[Soccer Mix Debug] Fired OnEntityCreated(func_physbox)");
			#endif
		}
	}
}

public Action:OnEntityTakeDamage(edict, &inflictor, &attacker, &Float:damage, &damagetype)
{
	if(IsValidEdict(edict) && IsValidEntity(edict))
	{
		if(g_isMixPaused)
		{
			return Plugin_Handled;
		}
		
		if(g_isBreakRunning)
		{
			return Plugin_Handled;
		}
	
		PlayerPassed = PlayerGoaled;
		
		PlayerGoaled = attacker;
		
		#if defined DEBUG
		CPrintToChatAll("[Soccer Mix Debug] Fired Hook OnEntityTakeDamage: PlayerPassed(index) = %i, PlayerGoaled(index) = %i", PlayerPassed, PlayerGoaled);
		#endif
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (buttons & IN_USE)
	{
		if (IsPlayerAlive(client) && IsClientInGame(client))
		{
			if(!g_inSprintCooldown[client])
			{
				SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.4);
				CreateTimer(3.0, Timer_SprintOff, client);
				g_inSprintCooldown[client] = true;
				CPrintToChat(client, "{green}[Soccer Mix]{default} Woosh!");
			}
			else
			{
				CPrintToChat(client, "{green}[Soccer Mix]{default} You must wait a while before sprinting again!");
			}
		}
	}
}

public Action:Timer_SprintOff(Handle:timer, any:client)
{
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
	CreateTimer(7.0, Timer_CooldownOff, client);
}

public Action:Timer_CooldownOff(Handle:timer, any:client)
{
	g_inSprintCooldown[client] = false;
}

stock SetClientFrags(client, Frags)
{
	if(!client)
	{
		LogError("[Soccer Mix] Faliure on SetClientFrags(client index %i)", client);
		return;
	}

	SetEntProp(client, Prop_Data, "m_iFrags", Frags);
}

stock SetClientDeaths(client, Deaths)
{
	if(!client)
	{
		LogError("[Soccer Mix] Faliure on SetClientDeaths(client index %i)", client);
		return;
	}

	SetEntProp(client, Prop_Data, "m_iDeaths", Deaths);
}

stock DisableBall()
{
	new Entity;
	while( (Entity = FindEntityByClassname(Entity, "func_physbox") ) != -1)
	AcceptEntityInput(Entity, "DisableMotion", -1, -1, 0);
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Func_DisableBall();");
	#endif
}

stock EnableBall()
{
	new Entity;
	while( (Entity = FindEntityByClassname(Entity, "func_physbox") ) != -1)
	AcceptEntityInput(Entity, "EnableMotion", -1, -1, 0);
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired Func_EnableBall();");
	#endif
}

stock PrintToAdmins(const String:message[])
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || !IsClientAuthorized(i))
		continue;
		
		if(GetUserAdmin(i) == INVALID_ADMIN_ID)
		continue;
		
		CPrintToChat(i, "{green}[Soccer Mix Admin]{default} %s", message);
	}
	
	#if defined DEBUG
	CPrintToChatAll("[Soccer Mix Debug] Fired PrintToAdmins();");
	#endif
}