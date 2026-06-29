#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>

#define PLUGIN_NAME         "Class time limit"
#define PLUGIN_AUTHOR       "Erreur 500"
#define PLUGIN_DESCRIPTION	"Limit class by time"
#define PLUGIN_VERSION      "1.0"
#define PLUGIN_CONTACT      "erreur500@hotmail.fr"

#define TF_TEAM_BLU					3
#define TF_TEAM_RED					2

new Handle:ClientTimer[MAXPLAYERS+1] = 	INVALID_HANDLE;

new Handle:c_TimerRedScout = 			INVALID_HANDLE;
new Handle:c_WaitTimerRedScout = 		INVALID_HANDLE;
new Handle:c_TimerRedSoldier = 			INVALID_HANDLE;
new Handle:c_WaitTimerRedSoldier = 		INVALID_HANDLE;
new Handle:c_TimerRedPyro = 			INVALID_HANDLE;
new Handle:c_WaitTimerRedPyro = 		INVALID_HANDLE;
new Handle:c_TimerRedDemoMan = 			INVALID_HANDLE;
new Handle:c_WaitTimerRedDemoMan = 		INVALID_HANDLE;
new Handle:c_TimerRedHeavy = 			INVALID_HANDLE;
new Handle:c_WaitTimerRedHeavy = 		INVALID_HANDLE;
new Handle:c_TimerRedMedic = 			INVALID_HANDLE;
new Handle:c_WaitTimerRedMedic = 		INVALID_HANDLE;
new Handle:c_TimerRedSniper = 			INVALID_HANDLE;
new Handle:c_WaitTimerRedSniper = 		INVALID_HANDLE;
new Handle:c_TimerRedEngineer = 		INVALID_HANDLE;
new Handle:c_WaitTimerRedEngineer = 	INVALID_HANDLE;
new Handle:c_TimerRedSpy = 				INVALID_HANDLE;
new Handle:c_WaitTimerRedSpy = 			INVALID_HANDLE;
new Handle:c_TimerBlueScout = 			INVALID_HANDLE;
new Handle:c_WaitTimerBlueScout = 		INVALID_HANDLE;
new Handle:c_TimerBlueSoldier = 		INVALID_HANDLE;
new Handle:c_WaitTimerBlueSoldier = 	INVALID_HANDLE;
new Handle:c_TimerBluePyro = 			INVALID_HANDLE;
new Handle:c_WaitTimerBluePyro = 		INVALID_HANDLE;
new Handle:c_TimerBlueDemoMan = 		INVALID_HANDLE;
new Handle:c_WaitTimerBlueDemoMan = 	INVALID_HANDLE;
new Handle:c_TimerBlueHeavy = 			INVALID_HANDLE;
new Handle:c_WaitTimerBlueHeavy = 		INVALID_HANDLE;
new Handle:c_TimerBlueMedic = 			INVALID_HANDLE;
new Handle:c_WaitTimerBlueMedic = 		INVALID_HANDLE;
new Handle:c_TimerBlueSniper = 			INVALID_HANDLE;
new Handle:c_WaitTimerBlueSniper = 		INVALID_HANDLE;
new Handle:c_TimerBlueEngineer = 		INVALID_HANDLE;
new Handle:c_WaitTimerBlueEngineer = 	INVALID_HANDLE;
new Handle:c_TimerBlueSpy = 			INVALID_HANDLE;
new Handle:c_WaitTimerBlueSpy = 		INVALID_HANDLE;
new Handle:cvarEnabled	=				INVALID_HANDLE;
new Handle:c_Flags	=					INVALID_HANDLE;
new Handle:c_Immunity	=				INVALID_HANDLE;

new bool:b_iWaiTimerRedScout[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerRedSoldier[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerRedPyro[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerRedDemoMan[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerRedHeavy[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerRedMedic[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerRedSniper[MAXPLAYERS+1] =		false;
new bool:b_iWaiTimerRedEngineer[MAXPLAYERS+1] =	 	false;
new bool:b_iWaiTimerRedSpy[MAXPLAYERS+1] = 			false;
new bool:b_iWaiTimerBlueScout[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerBlueSoldier[MAXPLAYERS+1] = 	false;
new bool:b_iWaiTimerBluePyro[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerBlueDemoMan[MAXPLAYERS+1] = 	false;
new bool:b_iWaiTimerBlueHeavy[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerBlueMedic[MAXPLAYERS+1] = 		false;
new bool:b_iWaiTimerBlueSniper[MAXPLAYERS+1] =		false;
new bool:b_iWaiTimerBlueEngineer[MAXPLAYERS+1] = 	false;
new bool:b_iWaiTimerBlueSpy[MAXPLAYERS+1] = 		false;

new TimerRedScout[MAXPLAYERS+1] = 				1;
new TimeLeftRedScout[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitRedScout[MAXPLAYERS+1] = 		1;
new TimerRedSoldier[MAXPLAYERS+1] = 			1;
new TimeLeftRedSoldier[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitRedSoldier[MAXPLAYERS+1] = 	1;
new TimerRedPyro[MAXPLAYERS+1] =				1;
new TimeLeftRedPyro[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitRedPyro[MAXPLAYERS+1] =		1;
new TimerRedDemoMan[MAXPLAYERS+1] = 			1;
new TimeLeftRedDemoMan[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitRedDemoMan[MAXPLAYERS+1] = 	1;
new TimerRedHeavy[MAXPLAYERS+1] = 				1;
new TimeLeftRedHeavy[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitRedHeavy[MAXPLAYERS+1] = 		1;
new TimerRedMedic[MAXPLAYERS+1] = 				1;
new TimeLeftRedMedic[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitRedMedic[MAXPLAYERS+1] = 		1;
new TimerRedSniper[MAXPLAYERS+1] = 				1;
new TimeLeftRedSniper[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitRedSniper[MAXPLAYERS+1] = 	1;
new TimerRedEngineer[MAXPLAYERS+1] = 			1;
new TimeLeftRedEngineer[MAXPLAYERS+1] = 		1;
new TimeLeftToWaitRedEngineer[MAXPLAYERS+1] = 	1;
new TimerRedSpy[MAXPLAYERS+1] = 				1;
new TimeLeftRedSpy[MAXPLAYERS+1] = 				1;
new TimeLeftToWaitRedSpy[MAXPLAYERS+1] = 		1;
new TimerBlueScout[MAXPLAYERS+1] = 				1;
new TimeLeftBlueScout[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitBlueScout[MAXPLAYERS+1] = 	1;
new TimerBlueSoldier[MAXPLAYERS+1] = 			1;
new TimeLeftBlueSoldier[MAXPLAYERS+1] = 		1;
new TimeLeftToWaitBlueSoldier[MAXPLAYERS+1] = 	1;
new TimerBluePyro[MAXPLAYERS+1] =				1;
new TimeLeftBluePyro[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitBluePyro[MAXPLAYERS+1] =		1;
new TimerBlueDemoMan[MAXPLAYERS+1] = 			1;
new TimeLeftBlueDemoMan[MAXPLAYERS+1] = 		1;
new TimeLeftToWaitBlueDemoMan[MAXPLAYERS+1] = 	1;
new TimerBlueHeavy[MAXPLAYERS+1] = 				1;
new TimeLeftBlueHeavy[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitBlueHeavy[MAXPLAYERS+1] = 	1;
new TimerBlueMedic[MAXPLAYERS+1] = 				1;
new TimeLeftBlueMedic[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitBlueMedic[MAXPLAYERS+1] = 	1;
new TimerBlueSniper[MAXPLAYERS+1] = 			1;
new TimeLeftBlueSniper[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitBlueSniper[MAXPLAYERS+1] = 	1;
new TimerBlueEngineer[MAXPLAYERS+1] = 			1;
new TimeLeftBlueEngineer[MAXPLAYERS+1] = 		1;
new TimeLeftToWaitBlueEngineer[MAXPLAYERS+1] = 	1;
new TimerBlueSpy[MAXPLAYERS+1] = 				1;
new TimeLeftBlueSpy[MAXPLAYERS+1] = 			1;
new TimeLeftToWaitBlueSpy[MAXPLAYERS+1] = 		1;

new ClientImmune = 0;


public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{
	cvarEnabled				= CreateConVar("ctl_enabled", "1", "Enable or disable class time limit ?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_Flags                = CreateConVar("ctl_flags", "a", "Admin flags for no time limit");
	c_Immunity             = CreateConVar("ctl_immunity", "0", "Enable or disable admins being immune for class time limit ?");
	c_TimerRedScout			= CreateConVar("ctl_red_scout", "-1", "Timer for play red Scout in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedScout 	= CreateConVar("ctl_wait_red_scout", "500", "Timer to wait for go red Scout in seconds, not need if Timer = -1 or 0");
	c_TimerRedSoldier 		= CreateConVar("ctl_red_soldier", "-1", "Timer for play red Soldier in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedSoldier 	= CreateConVar("ctl_wait_red_soldier", "500", "Timer to wait for go red Soldier in seconds, not need if Timer = -1 or 0");
	c_TimerRedPyro 			= CreateConVar("ctl_red_pyro", "-1", "Timer for play red Pyro in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedPyro 		= CreateConVar("ctl_wait_red_pyro", "500", "Timer to wait for go red Pyro in seconds, not need if Timer = -1 or 0");
	c_TimerRedDemoMan 		= CreateConVar("ctl_red_demoman", "-1", "Timer for play red DemoMan in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedDemoMan 	= CreateConVar("ctl_wait_red_demoman", "500", "Timer to wait for go red DemoMan in seconds, not need if Timer = -1 or 0");
	c_TimerRedHeavy 		= CreateConVar("ctl_red_heavy", "-1", "Timer for play red Heavy in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedHeavy 	= CreateConVar("ctl_wait_red_heavy", "500", "Timer to wait for go red Heavy in seconds, not need if Timer = -1 or 0");
	c_TimerRedMedic 		= CreateConVar("ctl_red_medic", "-1", "Timer for play red Medic in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedMedic 	= CreateConVar("ctl_wait_red_medic", "500", "Timer to wait for go red Medic in seconds, not need if Timer = -1 or 0");
	c_TimerRedSniper 		= CreateConVar("ctl_red_sniper", "500", "Timer for play red Sniper in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedSniper 	= CreateConVar("ctl_wait_red_sniper", "1000", "Timer to wait for go red Sniper in seconds, not need if Timer = -1 or 0");
	c_TimerRedEngineer 		= CreateConVar("ctl_red_engineer", "-1", "Timer for play red Engineer in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedEngineer 	= CreateConVar("ctl_wait_red_engineer", "500", "Timer to wait for go red Engineer in seconds, not need if Timer = -1 or 0");
	c_TimerRedSpy 			= CreateConVar("ctl_red_spy", "0", "Timer for play red Spy in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerRedSpy 		= CreateConVar("ctl_wait_red_spy", "500", "Timer to wait for go red Spy in seconds, not need if Timer = -1 or 0");
	c_TimerBlueScout 		= CreateConVar("ctl_blue_scout", "-1", "Timer for play blue Scout in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBlueScout 	= CreateConVar("ctl_wait_blue_scout", "500", "Timer to wait for go blue Scout in seconds, not need if Timer = -1 or 0");
	c_TimerBlueSoldier 		= CreateConVar("ctl_blue_soldier", "-1", "Timer for play blue Soldier in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBlueSoldier 	= CreateConVar("ctl_wait_blue_soldier", "500", "Timer to wait for go blue Soldier in seconds, not need if Timer = -1 or 0");
	c_TimerBluePyro 		= CreateConVar("ctl_blue_pyro", "-1", "Timer for play blue Pyro in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBluePyro 	= CreateConVar("ctl_wait_blue_pyro", "500", "Timer to wait for go blue Pyro in seconds, not need if Timer = -1 or 0");
	c_TimerBlueDemoMan 		= CreateConVar("ctl_blue_demoman", "-1", "Timer for play blue DemoMan in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBlueDemoMan 	= CreateConVar("ctl_wait_blue_demoman", "500", "Timer to wait for go blue DemoMan in seconds, not need if Timer = -1 or 0");
	c_TimerBlueHeavy 		= CreateConVar("ctl_blue_heavy", "-1", "Timer for play blue Heavy in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBlueHeavy 	= CreateConVar("ctl_wait_blue_heavy", "500", "Timer to wait for go blue Heavy in seconds, not need if Timer = -1 or 0");
	c_TimerBlueMedic 		= CreateConVar("ctl_blue_medic", "-1", "Timer for play blue Medic in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBlueMedic 	= CreateConVar("ctl_wait_blue_medic", "500", "Timer to wait for go blue Medic in seconds, not need if Timer = -1 or 0");
	c_TimerBlueSniper 		= CreateConVar("ctl_blue_sniper", "500", "Timer for play blue Sniper in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBlueSniper 	= CreateConVar("ctl_wait_blue_sniper", "1000", "Timer to wait for go blue Sniper in seconds, not need if Timer = -1 or 0");
	c_TimerBlueEngineer 	= CreateConVar("ctl_blue_engineer", "-1", "Timer for play blue Engineer in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBlueEngineer = CreateConVar("ctl_wait_blue_engineer", "500", "Timer to wait for go blue Engineer in seconds, not need if Timer = -1 or 0");
	c_TimerBlueSpy 			= CreateConVar("ctl_blue_spy", "0", "Timer for play blue Spy in seconds, -1 for no limit, 0 for block class");
	c_WaitTimerBlueSpy 		= CreateConVar("ctl_wait_blue_spy", "500", "Timer to wait for go blue Spy in seconds, not need if Timer = -1 or 0");
	
	AutoExecConfig(true, "Class_Time_Limit", "sourcemod"); 
}

public OnConfigsExecuted()
{	
	PrintToServer("[Class_Time_Limit] Configs loaded");
}

public OnMapStart()
{
	new bool:Enabled = GetConVarBool(cvarEnabled);
	if(Enabled)
	{
		HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
	}
}

public OnClientPutInServer(iClient)
{	
	new bool:Enabled = GetConVarBool(cvarEnabled);
	new Immunity = GetConVarInt(c_Immunity);
	decl String:Flags[32];
	GetConVarString(c_Flags, Flags, sizeof(Flags));
	new iFlags = GetUserFlagBits(iClient);
	if(iFlags == Flags[1])
	{
		ClientImmune = 1;
	}
	else
	{
		ClientImmune = 0;
	}
	
	if(Enabled && Immunity == 0 || Enabled && Immunity == 1 && ClientImmune == 0)
	{
	ClientTimer[iClient] = CreateTimer(1.0, FoncClassTimer, iClient, TIMER_REPEAT);
	}
}

public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new bool:Enabled = GetConVarBool(cvarEnabled);
	new Immunity = GetConVarInt(c_Immunity);
	decl String:Flags[32];
	GetConVarString(c_Flags, Flags, sizeof(Flags));
	new iFlags = GetUserFlagBits(iClient);
	if(iFlags == Flags[1])
	{
		ClientImmune = 1;
	}
	else
	{
		ClientImmune = 0;
	}
	if(Enabled && Immunity == 0 || Enabled && Immunity == 1 && ClientImmune == 0)
	{
	ControlBlokedClass(iClient);
	}
}

public Action:FoncClassTimer(Handle:timer, any:iClient)
{
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	new iTeam = GetClientTeam(iClient);
	new iTimerRedScout = GetConVarInt(c_TimerRedScout);
	new iTimerRedSoldier = GetConVarInt(c_TimerRedSoldier);
	new iTimerRedPyro = GetConVarInt(c_TimerRedPyro);
	new iTimerRedDemoMan = GetConVarInt(c_TimerRedDemoMan);
	new iTimerRedHeavy = GetConVarInt(c_TimerRedHeavy);
	new iTimerRedMedic = GetConVarInt(c_TimerRedMedic);
	new iTimerRedSniper = GetConVarInt(c_TimerRedSniper);
	new iTimerRedEngineer = GetConVarInt(c_TimerRedEngineer);
	new iTimerRedSpy = GetConVarInt(c_TimerRedSpy);
	new iTimerBlueScout = GetConVarInt(c_TimerBlueScout);
	new iTimerBlueSoldier = GetConVarInt(c_TimerBlueSoldier);
	new iTimerBluePyro = GetConVarInt(c_TimerBluePyro);
	new iTimerBlueDemoMan = GetConVarInt(c_TimerBlueDemoMan);
	new iTimerBlueHeavy = GetConVarInt(c_TimerBlueHeavy);
	new iTimerBlueMedic = GetConVarInt(c_TimerBlueMedic);
	new iTimerBlueSniper = GetConVarInt(c_TimerBlueSniper);
	new iTimerBlueEngineer = GetConVarInt(c_TimerBlueEngineer);
	new iTimerBlueSpy = GetConVarInt(c_TimerBlueSpy);

	
	if	(iClass == TFClass_Scout && iTeam ==_:TFTeam_Red && iTimerRedScout > 1)
	{
		TimerRedScout[iClient] += 1;
		new iWaitTimerRedScout = GetConVarInt(c_WaitTimerRedScout) + iTimerRedScout;
		TimeLeftRedScout[iClient] = iTimerRedScout - TimerRedScout[iClient];
		
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedScout[iClient] == iTimerRedScout)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedScout[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedScout[iClient] == false && TimeLeftRedScout[iClient] == 30 || TimeLeftRedScout[iClient] <= 10 && TimeLeftRedScout[iClient] > 0 && b_iWaiTimerRedScout[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedScout[iClient]);
		}
		else if (b_iWaiTimerRedScout[iClient] == true && TimerRedScout[iClient] < iWaitTimerRedScout)
		{	
			TimeLeftToWaitRedScout[iClient] = iWaitTimerRedScout - TimerRedScout[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Scout {RED}!", TimeLeftToWaitRedScout[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}

	}
	else if	(iClass == TFClass_Soldier && iTeam ==_:TFTeam_Red && iTimerRedSoldier > 1)
	{
		TimerRedSoldier[iClient] += 1;
		new iWaitTimerRedSoldier = GetConVarInt(c_WaitTimerRedSoldier) + iTimerRedSoldier;
		TimeLeftRedSoldier[iClient] = iTimerRedSoldier - TimerRedSoldier[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedSoldier[iClient] == iTimerRedSoldier)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedSoldier[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedSoldier[iClient] == false && TimeLeftRedSoldier[iClient] == 30 || TimeLeftRedSoldier[iClient] <= 10 && TimeLeftRedSoldier[iClient] > 0 && b_iWaiTimerRedSoldier[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedSoldier[iClient]);
		}
		else if (b_iWaiTimerRedSoldier[iClient] == true && TimerRedSoldier[iClient] < iWaitTimerRedSoldier)
		{	
			TimeLeftToWaitRedSoldier[iClient] = iWaitTimerRedSoldier - TimerRedSoldier[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Soldier {RED}!", TimeLeftToWaitRedSoldier[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}

	}
	else if	(iClass == TFClass_Pyro && iTeam ==_:TFTeam_Red && iTimerRedPyro > 1)
	{
		TimerRedPyro[iClient] += 1;
		new iWaitTimerRedPyro = GetConVarInt(c_WaitTimerRedPyro) + iTimerRedPyro;
		TimeLeftRedPyro[iClient] = iTimerRedPyro - TimerRedPyro[iClient];

		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedPyro[iClient] == iTimerRedPyro)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedPyro[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedPyro[iClient] == false && TimeLeftRedPyro[iClient] == 30 || TimeLeftRedPyro[iClient] <= 10 && TimeLeftRedPyro[iClient] > 0 && b_iWaiTimerRedPyro[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedPyro[iClient]);
		}
		else if (b_iWaiTimerRedPyro[iClient] == true && TimerRedPyro[iClient] < iWaitTimerRedPyro)
		{	
			TimeLeftToWaitRedPyro[iClient] = iWaitTimerRedPyro - TimerRedPyro[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Pyro {RED}!", TimeLeftToWaitRedPyro[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
	}
	else if	(iClass == TFClass_DemoMan && iTeam ==_:TFTeam_Red && iTimerRedDemoMan > 1)
	{
		TimerRedDemoMan[iClient] += 1;
		new iWaitTimerRedDemoMan = GetConVarInt(c_WaitTimerRedDemoMan) + iTimerRedDemoMan;
		TimeLeftRedDemoMan[iClient] = iTimerRedDemoMan - TimerRedDemoMan[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedDemoMan[iClient] == iTimerRedDemoMan && iTimerRedDemoMan > 1)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedDemoMan[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedDemoMan[iClient] == false && TimeLeftRedDemoMan[iClient] == 30 || TimeLeftRedDemoMan[iClient] <= 10 && TimeLeftRedDemoMan[iClient] > 0 && b_iWaiTimerRedDemoMan[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedDemoMan[iClient]);
		}
		else if (b_iWaiTimerRedDemoMan[iClient] == true && TimerRedDemoMan[iClient] < iWaitTimerRedDemoMan)
		{	
			TimeLeftToWaitRedDemoMan[iClient] = iWaitTimerRedDemoMan - TimerRedDemoMan[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}DemoMan {RED}!", TimeLeftToWaitRedDemoMan[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
	}
	
	else if	(iClass == TFClass_Heavy && iTeam ==_:TFTeam_Red && iTimerRedHeavy > 1)
	{
		TimerRedHeavy[iClient] += 1;
		new iWaitTimerRedHeavy = GetConVarInt(c_WaitTimerRedHeavy) + iTimerRedHeavy;
		TimeLeftRedHeavy[iClient] = iTimerRedHeavy - TimerRedHeavy[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedHeavy[iClient] == iTimerRedHeavy)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedHeavy[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedHeavy[iClient] == false && TimeLeftRedHeavy[iClient] == 30 || TimeLeftRedHeavy[iClient] <= 10 && TimeLeftRedHeavy[iClient] > 0 && b_iWaiTimerRedHeavy[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedHeavy[iClient]);
		}
		else if (b_iWaiTimerRedHeavy[iClient] == true && TimerRedHeavy[iClient] < iWaitTimerRedHeavy)
		{	
			TimeLeftToWaitRedHeavy[iClient] = iWaitTimerRedHeavy - TimerRedHeavy[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Heavy {RED}!", TimeLeftToWaitRedHeavy[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
	}
	
	else if	(iClass == TFClass_Medic && iTeam ==_:TFTeam_Red && iTimerRedMedic > 1)
	{
		TimerRedMedic[iClient] += 1;
		new iWaitTimerRedMedic = GetConVarInt(c_WaitTimerRedMedic) + iTimerRedMedic;
		TimeLeftRedMedic[iClient] = iTimerRedMedic - TimerRedMedic[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedMedic[iClient] == iTimerRedMedic)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedMedic[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedMedic[iClient] == false && TimeLeftRedMedic[iClient] == 30 || TimeLeftRedMedic[iClient] <= 10 && TimeLeftRedMedic[iClient] > 0 && b_iWaiTimerRedMedic[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedMedic[iClient]);
		}
		else if (b_iWaiTimerRedMedic[iClient] == true && TimerRedMedic[iClient] < iWaitTimerRedMedic)
		{	
			TimeLeftToWaitRedMedic[iClient] = iWaitTimerRedMedic - TimerRedMedic[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Medic {RED}!", TimeLeftToWaitRedMedic[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
	}
	
	else if	(iClass == TFClass_Sniper && iTeam ==_:TFTeam_Red && iTimerRedSniper > 1)
	{
		TimerRedSniper[iClient] += 1;
		new iWaitTimerRedSniper = GetConVarInt(c_WaitTimerRedSniper) + iTimerRedSniper;
		TimeLeftRedSniper[iClient] = iTimerRedSniper - TimerRedSniper[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedSniper[iClient] == iTimerRedSniper)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedSniper[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedSniper[iClient] == false && TimeLeftRedSniper[iClient] == 30 || TimeLeftRedSniper[iClient] <= 10 && TimeLeftRedSniper[iClient] > 0 && b_iWaiTimerRedSniper[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedSniper[iClient]);
		}
		else if (b_iWaiTimerRedSniper[iClient] == true && TimerRedSniper[iClient] < iWaitTimerRedSniper)
		{	
			TimeLeftToWaitRedSniper[iClient] = iWaitTimerRedSniper - TimerRedSniper[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Sniper {RED}!", TimeLeftToWaitRedSniper[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
	}
	
	else if	(iClass == TFClass_Engineer && iTeam ==_:TFTeam_Red && iTimerRedEngineer > 1)
	{
		TimerRedEngineer[iClient] += 1;
		new iWaitTimerRedEngineer = GetConVarInt(c_WaitTimerRedEngineer) + iTimerRedEngineer;
		TimeLeftRedEngineer[iClient] = iTimerRedEngineer - TimerRedEngineer[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedEngineer[iClient] == iTimerRedEngineer)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedEngineer[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedEngineer[iClient] == false && TimeLeftRedEngineer[iClient] == 30 || TimeLeftRedEngineer[iClient] <= 10 && TimeLeftRedEngineer[iClient] > 0 && b_iWaiTimerRedEngineer[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedEngineer[iClient]);
		}
		else if (b_iWaiTimerRedEngineer[iClient] == true && TimerRedEngineer[iClient] < iWaitTimerRedEngineer)
		{	
			TimeLeftToWaitRedEngineer[iClient] = iWaitTimerRedEngineer - TimerRedEngineer[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}Il vous reste encore{GREEN} %d {RED}seconds à attendre pour rejouer {GOLD}Engineer{RED}!", TimeLeftToWaitRedEngineer[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
	}
	
	else if	(iClass == TFClass_Spy && iTeam ==_:TFTeam_Red && iTimerRedSpy > 1)
	{
		TimerRedSpy[iClient] += 1;
		new iWaitTimerRedSpy = GetConVarInt(c_WaitTimerRedSpy) + iTimerRedSpy;
		TimeLeftRedSpy[iClient] = iTimerRedSpy - TimerRedSpy[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerRedSpy[iClient] == iTimerRedSpy)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerRedSpy[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
		else if (b_iWaiTimerRedSpy[iClient] == false && TimeLeftRedSpy[iClient] == 30 || TimeLeftRedSpy[iClient] <= 10 && TimeLeftRedSpy[iClient] > 0 && b_iWaiTimerRedSpy[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftRedSpy[iClient]);
		}
		else if (b_iWaiTimerRedSpy[iClient] == true && TimerRedSpy[iClient] < iWaitTimerRedSpy)
		{	
			TimeLeftToWaitRedSpy[iClient] = iWaitTimerRedSpy - TimerRedSpy[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Spy {RED}!", TimeLeftToWaitRedSpy[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
		}
	}
	
	else if	(iClass == TFClass_Scout && iTeam ==_:TFTeam_Blue && iTimerBlueScout > 1)
	{
		TimerBlueScout[iClient] += 1;
		new iWaitTimerBlueScout = GetConVarInt(c_WaitTimerBlueScout) + iTimerBlueScout;
		TimeLeftBlueScout[iClient] = iTimerBlueScout - TimerBlueScout[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerBlueScout[iClient] == iTimerBlueScout)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerBlueScout[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
		else if (b_iWaiTimerBlueScout[iClient] == false && TimeLeftBlueScout[iClient] == 30 || TimeLeftBlueScout[iClient] <= 10 && TimeLeftBlueScout[iClient] > 0 && b_iWaiTimerBlueScout[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBlueScout[iClient]);
		}
		else if (b_iWaiTimerBlueScout[iClient] == true && TimerBlueScout[iClient] < iWaitTimerBlueScout)
		{	
			TimeLeftToWaitBlueScout[iClient] = iWaitTimerBlueScout - TimerBlueScout[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Scout {RED}!", TimeLeftToWaitBlueScout[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
	}
	else if	(iClass == TFClass_Soldier && iTeam ==_:TFTeam_Blue && iTimerBlueSoldier > 1)
	{
		TimerBlueSoldier[iClient] += 1;
		new iWaitTimerBlueSoldier = GetConVarInt(c_WaitTimerBlueSoldier) + iTimerBlueSoldier;
		TimeLeftBlueSoldier[iClient] = iTimerBlueSoldier - TimerBlueSoldier[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerBlueSoldier[iClient] == iTimerBlueSoldier)
		{
			b_iWaiTimerBlueSoldier[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		}
		else if (b_iWaiTimerBlueSoldier[iClient] == false && TimeLeftBlueSoldier[iClient] == 30 || TimeLeftBlueSoldier[iClient] <= 10 && TimeLeftBlueSoldier[iClient] > 0 && b_iWaiTimerBlueSoldier[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBlueSoldier[iClient]);
		}
		else if (b_iWaiTimerBlueSoldier[iClient] == true && TimerBlueSoldier[iClient] < iWaitTimerBlueSoldier)
		{	
			TimeLeftToWaitBlueSoldier[iClient] = iWaitTimerBlueSoldier - TimerBlueSoldier[iClient];
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Soldier {RED}!", TimeLeftToWaitBlueSoldier[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		}
	}
	else if	(iClass == TFClass_Pyro && iTeam ==_:TFTeam_Blue && iTimerBluePyro > 1)
	{
		TimerBluePyro[iClient] += 1;
		new iWaitTimerBluePyro = GetConVarInt(c_WaitTimerBluePyro) + iTimerBluePyro;
		TimeLeftBluePyro[iClient] = iTimerBluePyro - TimerBluePyro[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerBluePyro[iClient] == iTimerBluePyro)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerBluePyro[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
		else if (b_iWaiTimerBluePyro[iClient] == false && TimeLeftBluePyro[iClient] == 30 || TimeLeftBluePyro[iClient] <= 10 && TimeLeftBluePyro[iClient] > 0 && b_iWaiTimerBluePyro[iClient] == false)
		{
			CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBluePyro[iClient]);
		}
		else if (b_iWaiTimerBluePyro[iClient] == true && TimerBluePyro[iClient] < iWaitTimerBluePyro)
		{	
			TimeLeftToWaitBluePyro[iClient] = iWaitTimerBluePyro - TimerBluePyro[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Pyro {RED}!", TimeLeftToWaitBluePyro[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
	}
	else if	(iClass == TFClass_DemoMan && iTeam ==_:TFTeam_Blue && iTimerBlueDemoMan > 1)
	{
		TimerBlueDemoMan[iClient] += 1;
		new iWaitTimerBlueDemoMan = GetConVarInt(c_WaitTimerBlueDemoMan) + iTimerBlueDemoMan;
		TimeLeftBlueDemoMan[iClient] = iTimerBlueDemoMan - TimerBlueDemoMan[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerBlueDemoMan[iClient] == iTimerBlueDemoMan)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerBlueDemoMan[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
		else if (b_iWaiTimerBlueDemoMan[iClient] == false && TimeLeftBlueDemoMan[iClient] == 30 || TimeLeftBlueDemoMan[iClient] <= 10 && TimeLeftBlueDemoMan[iClient] > 0 && b_iWaiTimerBlueDemoMan[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBlueDemoMan[iClient]);
		}
		else if (b_iWaiTimerBlueDemoMan[iClient] == true && TimerBlueDemoMan[iClient] < iWaitTimerBlueDemoMan)
		{	
			TimeLeftToWaitBlueDemoMan[iClient] = iWaitTimerBlueDemoMan - TimerBlueDemoMan[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}DemoMan {RED}!", TimeLeftToWaitBlueDemoMan[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
	}
	
	else if	(iClass == TFClass_Heavy && iTeam ==_:TFTeam_Blue && iTimerBlueHeavy > 1)
	{
		TimerBlueHeavy[iClient] += 1;
		new iWaitTimerBlueHeavy = GetConVarInt(c_WaitTimerBlueHeavy) + iTimerBlueHeavy;
		TimeLeftBlueHeavy[iClient] = iTimerBlueHeavy - TimerBlueHeavy[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerBlueHeavy[iClient] == iTimerBlueHeavy)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerBlueHeavy[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
		else if (b_iWaiTimerBlueHeavy[iClient] == false && TimeLeftBlueHeavy[iClient] == 30 || TimeLeftBlueHeavy[iClient] <= 10 && TimeLeftBlueHeavy[iClient] > 0 && b_iWaiTimerBlueHeavy[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBlueHeavy[iClient]);
		}
		else if (b_iWaiTimerBlueHeavy[iClient] == true && TimerBlueHeavy[iClient] < iWaitTimerBlueHeavy)
		{	
			TimeLeftToWaitBlueHeavy[iClient] = iWaitTimerBlueHeavy - TimerBlueHeavy[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Heavy {RED}!", TimeLeftToWaitBlueHeavy[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
	}
	
	else if	(iClass == TFClass_Medic && iTeam ==_:TFTeam_Blue && iTimerBlueMedic > 1)
	{
		TimerBlueMedic[iClient] += 1;
		new iWaitTimerBlueMedic = GetConVarInt(c_WaitTimerBlueMedic) + iTimerBlueMedic;
		TimeLeftBlueMedic[iClient] = iTimerBlueMedic - TimerBlueMedic[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerBlueMedic[iClient] == iTimerBlueMedic)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerBlueMedic[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
		else if (b_iWaiTimerBlueMedic[iClient] == false && TimeLeftBlueMedic[iClient] == 30 || TimeLeftBlueMedic[iClient] <= 10 && TimeLeftBlueMedic[iClient] > 0 && b_iWaiTimerBlueMedic[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBlueMedic[iClient]);
		}
		else if (b_iWaiTimerBlueMedic[iClient] == true && TimerBlueMedic[iClient] < iWaitTimerBlueMedic)
		{	
			TimeLeftToWaitBlueMedic[iClient] = iWaitTimerBlueMedic - TimerBlueMedic[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Medic {RED}!", TimeLeftToWaitBlueMedic[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
	}
	
	else if	(iClass == TFClass_Sniper && iTeam ==_:TFTeam_Blue && iTimerBlueSniper > 1)
	{
		TimerBlueSniper[iClient] += 1;
		new iWaitTimerBlueSniper = GetConVarInt(c_WaitTimerBlueSniper) + iTimerBlueSniper;
		TimeLeftBlueSniper[iClient] = iTimerBlueSniper - TimerBlueSniper[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerBlueSniper[iClient] == iTimerBlueSniper)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerBlueSniper[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
		else if (b_iWaiTimerBlueSniper[iClient] == false && TimeLeftBlueSniper[iClient] == 30 || TimeLeftBlueSniper[iClient] <= 10 && TimeLeftBlueSniper[iClient] > 0 && b_iWaiTimerBlueSniper[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBlueSniper[iClient]);
		}
		else if (b_iWaiTimerBlueSniper[iClient] == true && TimerBlueSniper[iClient] < iWaitTimerBlueSniper)
		{	
			TimeLeftToWaitBlueSniper[iClient] = iWaitTimerBlueSniper - TimerBlueSniper[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Sniper {RED}!", TimeLeftToWaitBlueSniper[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
	}
	
	else if	(iClass == TFClass_Engineer && iTeam ==_:TFTeam_Blue && iTimerBlueEngineer > 1)
	{
		TimerBlueEngineer[iClient] += 1;
		new iWaitTimerBlueEngineer = GetConVarInt(c_WaitTimerBlueEngineer) + iTimerBlueEngineer;
		TimeLeftBlueEngineer[iClient] = iTimerBlueEngineer - TimerBlueEngineer[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueSpy(iClient);
		
		if (TimerBlueEngineer[iClient] == iTimerBlueEngineer)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerBlueEngineer[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
		else if (b_iWaiTimerBlueEngineer[iClient] == false && TimeLeftBlueEngineer[iClient] == 30 || TimeLeftBlueEngineer[iClient] <= 10 && TimeLeftBlueEngineer[iClient] > 0 && b_iWaiTimerBlueEngineer[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBlueEngineer[iClient]);
		}
		else if (b_iWaiTimerBlueEngineer[iClient] == true && TimerBlueEngineer[iClient] < iWaitTimerBlueEngineer)
		{	
			TimeLeftToWaitBlueEngineer[iClient] = iWaitTimerBlueEngineer - TimerBlueEngineer[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Engineer {RED}!", TimeLeftToWaitBlueEngineer[iClient]);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
	}
	
	else if	(iClass == TFClass_Spy && iTeam ==_:TFTeam_Blue && iTimerBlueSpy > 1)
	{
		TimerBlueSpy[iClient] += 1;
		new iWaitTimerBlueSpy = GetConVarInt(c_WaitTimerBlueSpy) + iTimerBlueSpy;
		TimeLeftBlueSpy[iClient] = iTimerBlueSpy - TimerBlueSpy[iClient];
		
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient)
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		
		if (TimerBlueSpy[iClient] == iTimerBlueSpy)
		{
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			b_iWaiTimerBlueSpy[iClient] = true;
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		}
		else if (b_iWaiTimerBlueSpy[iClient] == false && TimeLeftBlueSpy[iClient] == 30 || TimeLeftBlueSpy[iClient] <= 10 && TimeLeftBlueSpy[iClient] > 0 && b_iWaiTimerBlueSpy[iClient] == false)
		{
				CPrintToChat(iClient, "{ORANGE}Time left for play this class is{GREEN} %d {ORANGE}second(s) !", TimeLeftBlueSpy[iClient]);
		}
		else if (b_iWaiTimerBlueSpy[iClient] == true && TimerBlueSpy[iClient] < iWaitTimerBlueSpy)
		{	
			TimeLeftToWaitBlueSpy[iClient] = iWaitTimerBlueSpy - TimerBlueSpy[iClient];
			TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
			ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
			CPrintToChat(iClient, "{RED}You must wait{GREEN} %d {RED}seconds to replay {GOLD}Spy {RED}!", TimeLeftToWaitBlueSpy[iClient]);
		}
	}
	else
	{
		ContinuTimerRedScout(iClient);
		ContinuTimerRedSoldier(iClient);
		ContinuTimerRedPyro(iClient);
		ContinuTimerRedDemoMan(iClient);
		ContinuTimerRedHeavy(iClient);
		ContinuTimerRedMedic(iClient);
		ContinuTimerRedSniper(iClient);
		ContinuTimerRedEngineer(iClient);
		ContinuTimerRedSpy(iClient);
		ContinuTimerBlueScout(iClient);
		ContinuTimerBlueSoldier(iClient);
		ContinuTimerBluePyro(iClient);
		ContinuTimerBlueDemoMan(iClient);
		ContinuTimerBlueHeavy(iClient);
		ContinuTimerBlueMedic(iClient);
		ContinuTimerBlueSniper(iClient);
		ContinuTimerBlueEngineer(iClient);
		ContinuTimerBlueSpy(iClient);
	}
	
	return Plugin_Continue;
}


ContinuTimerRedScout(iClient)	
{
	if(b_iWaiTimerRedScout[iClient] == true)
	{
		TimerRedScout[iClient] += 1;
		new iTimerRedScout = GetConVarInt(c_TimerRedScout);
		new iWaitTimerRedScout = GetConVarInt(c_WaitTimerRedScout) + iTimerRedScout;
			if(b_iWaiTimerRedScout[iClient] == true && TimerRedScout[iClient] >= iWaitTimerRedScout)
		{
			TimerRedScout[iClient] = 0;
			b_iWaiTimerRedScout[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}Scout {LIME}is now allowed !")
		}
	}
}

ContinuTimerRedSoldier(iClient)	
{
	if(b_iWaiTimerRedSoldier[iClient] == true)
	{
		TimerRedSoldier[iClient] += 1;
		new iTimerRedSoldier = GetConVarInt(c_TimerRedSoldier);
		new iWaitTimerRedSoldier = GetConVarInt(c_WaitTimerRedSoldier) + iTimerRedSoldier;
			if(b_iWaiTimerRedSoldier[iClient] == true && TimerRedSoldier[iClient] >= iWaitTimerRedSoldier)
		{
			TimerRedSoldier[iClient] = 0;
			b_iWaiTimerRedSoldier[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}Soldier {LIME}is now allowed !")
		}
	}
}

ContinuTimerRedPyro(iClient)	
{
	if(b_iWaiTimerRedPyro[iClient] == true)
	{
		TimerRedPyro[iClient] += 1;
		new iTimerRedPyro = GetConVarInt(c_TimerRedPyro);
		new iWaitTimerRedPyro = GetConVarInt(c_WaitTimerRedPyro) + iTimerRedPyro;
			if(b_iWaiTimerRedPyro[iClient] == true && TimerRedPyro[iClient] >= iWaitTimerRedPyro)
		{
			TimerRedPyro[iClient] = 0;
			b_iWaiTimerRedPyro[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}Pyro {LIME}is now allowed !")
		}
	}
}

ContinuTimerRedDemoMan(iClient)	
{
	if(b_iWaiTimerRedDemoMan[iClient] == true)
	{
		TimerRedDemoMan[iClient] += 1;
		new iTimerRedDemoMan = GetConVarInt(c_TimerRedDemoMan);
		new iWaitTimerRedDemoMan = GetConVarInt(c_WaitTimerRedDemoMan) + iTimerRedDemoMan;
			if(b_iWaiTimerRedDemoMan[iClient] == true && TimerRedDemoMan[iClient] >= iWaitTimerRedDemoMan)
		{
			TimerRedDemoMan[iClient] = 0;
			b_iWaiTimerRedDemoMan[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}DemoMan {LIME}is now allowed !")
		}
	}
}

ContinuTimerRedHeavy(iClient)	
{
	if(b_iWaiTimerRedHeavy[iClient] == true)
	{
		TimerRedHeavy[iClient] += 1;
		new iTimerRedHeavy = GetConVarInt(c_TimerRedHeavy);
		new iWaitTimerRedHeavy = GetConVarInt(c_WaitTimerRedHeavy) + iTimerRedHeavy;
			if(b_iWaiTimerRedHeavy[iClient] == true && TimerRedHeavy[iClient] >= iWaitTimerRedHeavy)
		{
			TimerRedHeavy[iClient] = 0;
			b_iWaiTimerRedHeavy[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}Heavy {LIME}is now allowed !")
		}
	}
}

ContinuTimerRedMedic(iClient)	
{
	if(b_iWaiTimerRedMedic[iClient] == true)
	{
		TimerRedMedic[iClient] += 1;
		new iTimerRedMedic = GetConVarInt(c_TimerRedMedic);
		new iWaitTimerRedMedic = GetConVarInt(c_WaitTimerRedMedic) + iTimerRedMedic;
			if(b_iWaiTimerRedMedic[iClient] == true && TimerRedMedic[iClient] >= iWaitTimerRedMedic)
		{
			TimerRedMedic[iClient] = 0;
			b_iWaiTimerRedMedic[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}Medic {LIME}is now allowed !")
		}
	}
}

ContinuTimerRedSniper(iClient)	
{
	if(b_iWaiTimerRedSniper[iClient] == true)
	{
		TimerRedSniper[iClient] += 1;
		new iTimerRedSniper = GetConVarInt(c_TimerRedSniper);
		new iWaitTimerRedSniper = GetConVarInt(c_WaitTimerRedSniper) + iTimerRedSniper;
			if(b_iWaiTimerRedSniper[iClient] == true && TimerRedSniper[iClient] >= iWaitTimerRedSniper)
		{
			TimerRedSniper[iClient] = 0;
			b_iWaiTimerRedSniper[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}Sniper {LIME}is now allowed !")
		}
	}
}

ContinuTimerRedEngineer(iClient)	
{
	if(b_iWaiTimerRedEngineer[iClient] == true)
	{
		TimerRedEngineer[iClient] += 1;
		new iTimerRedEngineer = GetConVarInt(c_TimerRedEngineer);
		new iWaitTimerRedEngineer = GetConVarInt(c_WaitTimerRedEngineer) + iTimerRedEngineer;
			if(b_iWaiTimerRedEngineer[iClient] == true && TimerRedEngineer[iClient] >= iWaitTimerRedEngineer)
		{
			TimerRedEngineer[iClient] = 0;
			b_iWaiTimerRedEngineer[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}Engineer {LIME}is now allowed !")
		}
	}
}

ContinuTimerRedSpy(iClient)	
{
	if(b_iWaiTimerRedSpy[iClient] == true)
	{
		TimerRedSpy[iClient] += 1;
		new iTimerRedSpy = GetConVarInt(c_TimerRedSpy);
		new iWaitTimerRedSpy = GetConVarInt(c_WaitTimerRedSpy) + iTimerRedSpy;
			if(b_iWaiTimerRedSpy[iClient] == true && TimerRedSpy[iClient] >= iWaitTimerRedSpy)
		{
			TimerRedSpy[iClient] = 0;
			b_iWaiTimerRedSpy[iClient] = false;
			CPrintToChat(iClient, "{RED}Red {GOLD}Spy {LIME}is now allowed !")
		}
	}
}

ContinuTimerBlueScout(iClient)	
{
	if(b_iWaiTimerBlueScout[iClient] == true)
	{
		TimerBlueScout[iClient] += 1;
		new iTimerBlueScout = GetConVarInt(c_TimerBlueScout);
		new iWaitTimerBlueScout = GetConVarInt(c_WaitTimerBlueScout) + iTimerBlueScout;
			if(b_iWaiTimerBlueScout[iClient] == true && TimerBlueScout[iClient] >= iWaitTimerBlueScout)
		{
			TimerBlueScout[iClient] = 0;
			b_iWaiTimerBlueScout[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}Scout {LIME}is now allowed !")
		}
	}
}

ContinuTimerBlueSoldier(iClient)	
{
	if(b_iWaiTimerBlueSoldier[iClient] == true)
	{
		TimerBlueSoldier[iClient] += 1;
		new iTimerBlueSoldier = GetConVarInt(c_TimerBlueSoldier);
		new iWaitTimerBlueSoldier = GetConVarInt(c_WaitTimerBlueSoldier) + iTimerBlueSoldier;
			if(b_iWaiTimerBlueSoldier[iClient] == true && TimerBlueSoldier[iClient] >= iWaitTimerBlueSoldier)
		{
			TimerBlueSoldier[iClient] = 0;
			b_iWaiTimerBlueSoldier[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}Soldier {LIME}is now allowed !")
		}
	}
}

ContinuTimerBluePyro(iClient)	
{
	if(b_iWaiTimerBluePyro[iClient] == true)
	{
		TimerBluePyro[iClient] += 1;
		new iTimerBluePyro = GetConVarInt(c_TimerBluePyro);
		new iWaitTimerBluePyro = GetConVarInt(c_WaitTimerBluePyro) + iTimerBluePyro;
			if(b_iWaiTimerBluePyro[iClient] == true && TimerBluePyro[iClient] >= iWaitTimerBluePyro)
		{
			TimerBluePyro[iClient] = 0;
			b_iWaiTimerBluePyro[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}Pyro {LIME}is now allowed !")
		}
	}
}

ContinuTimerBlueDemoMan(iClient)	
{
	if(b_iWaiTimerBlueDemoMan[iClient] == true)
	{
		TimerBlueDemoMan[iClient] += 1;
		new iTimerBlueDemoMan = GetConVarInt(c_TimerBlueDemoMan);
		new iWaitTimerBlueDemoMan = GetConVarInt(c_WaitTimerBlueDemoMan) + iTimerBlueDemoMan;
			if(b_iWaiTimerBlueDemoMan[iClient] == true && TimerBlueDemoMan[iClient] >= iWaitTimerBlueDemoMan)
		{
			TimerBlueDemoMan[iClient] = 0;
			b_iWaiTimerBlueDemoMan[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}DemoMan {LIME}is now allowed !")
		}
	}
}

ContinuTimerBlueHeavy(iClient)	
{
	if(b_iWaiTimerBlueHeavy[iClient] == true)
	{
		TimerBlueHeavy[iClient] += 1;
		new iTimerBlueHeavy = GetConVarInt(c_TimerBlueHeavy);
		new iWaitTimerBlueHeavy = GetConVarInt(c_WaitTimerBlueHeavy) + iTimerBlueHeavy;
			if(b_iWaiTimerBlueHeavy[iClient] == true && TimerBlueHeavy[iClient] >= iWaitTimerBlueHeavy)
		{
			TimerBlueHeavy[iClient] = 0;
			b_iWaiTimerBlueHeavy[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}Heavy {LIME}is now allowed !")
		}
	}
}

ContinuTimerBlueMedic(iClient)	
{
	if(b_iWaiTimerBlueMedic[iClient] == true)
	{
		TimerBlueMedic[iClient] += 1;
		new iTimerBlueMedic = GetConVarInt(c_TimerBlueMedic);
		new iWaitTimerBlueMedic = GetConVarInt(c_WaitTimerBlueMedic) + iTimerBlueMedic;
			if(b_iWaiTimerBlueMedic[iClient] == true && TimerBlueMedic[iClient] >= iWaitTimerBlueMedic)
		{
			TimerBlueMedic[iClient] = 0;
			b_iWaiTimerBlueMedic[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}Medic {LIME}is now allowed !")
		}
	}
}

ContinuTimerBlueSniper(iClient)	
{
	if(b_iWaiTimerBlueSniper[iClient] == true)
	{
		TimerBlueSniper[iClient] += 1;
		new iTimerBlueSniper = GetConVarInt(c_TimerBlueSniper);
		new iWaitTimerBlueSniper = GetConVarInt(c_WaitTimerBlueSniper) + iTimerBlueSniper;
			if(b_iWaiTimerBlueSniper[iClient] == true && TimerBlueSniper[iClient] >= iWaitTimerBlueSniper)
		{
			TimerBlueSniper[iClient] = 0;
			b_iWaiTimerBlueSniper[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}Sniper {LIME}is now allowed !")
		}
	}
}

ContinuTimerBlueEngineer(iClient)	
{
	if(b_iWaiTimerBlueEngineer[iClient] == true)
	{
		TimerBlueEngineer[iClient] += 1;
		new iTimerBlueEngineer = GetConVarInt(c_TimerBlueEngineer);
		new iWaitTimerBlueEngineer = GetConVarInt(c_WaitTimerBlueEngineer) + iTimerBlueEngineer;
			if(b_iWaiTimerBlueEngineer[iClient] == true && TimerBlueEngineer[iClient] >= iWaitTimerBlueEngineer)
		{
			TimerBlueEngineer[iClient] = 0;
			b_iWaiTimerBlueEngineer[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}Engineer {LIME}is now allowed !")
		}
	}
}

ContinuTimerBlueSpy(iClient)	
{
	if(b_iWaiTimerBlueSpy[iClient] == true)
	{
		TimerBlueSpy[iClient] += 1;
		new iTimerBlueSpy = GetConVarInt(c_TimerBlueSpy);
		new iWaitTimerBlueSpy = GetConVarInt(c_WaitTimerBlueSpy) + iTimerBlueSpy;
			if(b_iWaiTimerBlueSpy[iClient] == true && TimerBlueSpy[iClient] >= iWaitTimerBlueSpy)
		{
			TimerBlueSpy[iClient] = 0;
			b_iWaiTimerBlueSpy[iClient] = false;
			CPrintToChat(iClient, "{BLUE}Blue {GOLD}Spy {LIME}is now allowed !")
		}
	}
}

ControlBlokedClass(iClient)
{
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	new iTeam = GetClientTeam(iClient);
	new iTimerRedScout = GetConVarInt(c_TimerRedScout);
	new iTimerRedSoldier = GetConVarInt(c_TimerRedSoldier);
	new iTimerRedPyro = GetConVarInt(c_TimerRedPyro);
	new iTimerRedDemoMan = GetConVarInt(c_TimerRedDemoMan);
	new iTimerRedHeavy = GetConVarInt(c_TimerRedHeavy);
	new iTimerRedMedic = GetConVarInt(c_TimerRedMedic);
	new iTimerRedSniper = GetConVarInt(c_TimerRedSniper);
	new iTimerRedEngineer = GetConVarInt(c_TimerRedEngineer);
	new iTimerRedSpy = GetConVarInt(c_TimerRedSpy);
	new iTimerBlueScout = GetConVarInt(c_TimerBlueScout);
	new iTimerBlueSoldier = GetConVarInt(c_TimerBlueSoldier);
	new iTimerBluePyro = GetConVarInt(c_TimerBluePyro);
	new iTimerBlueDemoMan = GetConVarInt(c_TimerBlueDemoMan);
	new iTimerBlueHeavy = GetConVarInt(c_TimerBlueHeavy);
	new iTimerBlueMedic = GetConVarInt(c_TimerBlueMedic);
	new iTimerBlueSniper = GetConVarInt(c_TimerBlueSniper);
	new iTimerBlueEngineer = GetConVarInt(c_TimerBlueEngineer);
	new iTimerBlueSpy = GetConVarInt(c_TimerBlueSpy);
	
	if	(iClass == TFClass_Scout && iTeam ==_:TFTeam_Red && iTimerRedScout == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	
	else if	(iClass == TFClass_Soldier && iTeam ==_:TFTeam_Red && iTimerRedSoldier == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	
	else if	(iClass == TFClass_Pyro && iTeam ==_:TFTeam_Red && iTimerRedPyro == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	
	else if	(iClass == TFClass_DemoMan && iTeam ==_:TFTeam_Red && iTimerRedDemoMan == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	
	else if	(iClass == TFClass_Heavy && iTeam ==_:TFTeam_Red && iTimerRedHeavy == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	
	else if	(iClass == TFClass_Medic && iTeam ==_:TFTeam_Red && iTimerRedMedic == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	else if	(iClass == TFClass_Sniper && iTeam ==_:TFTeam_Red && iTimerRedSniper == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	
	else if	(iClass == TFClass_Engineer && iTeam ==_:TFTeam_Red && iTimerRedEngineer == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	
	else if	(iClass == TFClass_Spy && iTeam ==_:TFTeam_Red && iTimerRedSpy == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_RED ? "class_red" : "class_blue");
	}
	
	else if	(iClass == TFClass_Scout && iTeam ==_:TFTeam_Blue && iTimerBlueScout == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
	
	else if	(iClass == TFClass_Soldier && iTeam ==_:TFTeam_Blue && iTimerBlueSoldier == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!");
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
	
	else if	(iClass == TFClass_Pyro && iTeam ==_:TFTeam_Blue && iTimerBluePyro == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!");
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
	
	else if	(iClass == TFClass_DemoMan && iTeam ==_:TFTeam_Blue && iTimerBlueDemoMan == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
	
	else if	(iClass == TFClass_Heavy && iTeam ==_:TFTeam_Blue && iTimerBlueHeavy == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
	
	else if	(iClass == TFClass_Medic && iTeam ==_:TFTeam_Blue && iTimerBlueMedic == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED}blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
	else if	(iClass == TFClass_Sniper && iTeam ==_:TFTeam_Blue && iTimerBlueSniper == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
	
	else if	(iClass == TFClass_Engineer && iTeam ==_:TFTeam_Blue && iTimerBlueEngineer == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
	
	else if	(iClass == TFClass_Spy && iTeam ==_:TFTeam_Blue && iTimerBlueSpy == 0)
	{
		CPrintToChat(iClient, "{BLACK}This class is{RED} blocked{BLACK}, please chose an other class!")
		TF2_SetPlayerClass(iClient, TFClass_Unknown, true, true);
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
	}
}

public OnClientDisconnect(iClient)
{
	KillTimer(Handle:ClientTimer[iClient], true); 
}

public OnMapEnd()
{
	UnhookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
}