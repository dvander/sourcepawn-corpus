#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS
#define DEBUG		0
FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

//Handles!!!
new Handle:SpawnTimer		= INVALID_HANDLE;
new Handle:SurvivorLimmit = INVALID_HANDLE;
new Handle:InfectedLimmit = INVALID_HANDLE;
new Handle:L4dSurvivorLimmit = INVALID_HANDLE;
new Handle:L4dInfectedLimmit = INVALID_HANDLE;
new bool:useful[MAXPLAYERS+1];
new Handle
#if DEBUG
new String:l4dtankId[] = "STEAM_1:0:25653524";
#endif
//end of handles

//PLUGIN!!!

public Plugin:myinfo =
{
	name = "extra_bots",
	author = "gamemann",
	description = "you can add infectedbots ingame and survivors at spawn",
	version = "1.0.0",
	url = "http://sourcemod.net",
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName, "left4dead", false)&&!StrEqual(ModName, "left4dead2", false)) SetFailState("Use this in Left 4 Dead (2) only.");
/////////////////
////CONVARS
/////////////////
	CreateConVar("sm_extrabots_version", "1.0.0", "version of the plugin", CVAR_FLAGS);
	L4dSurvivorLimmit = FindConVar("survivor_limmit");
	L4dInfectedLimmit = FindConVar("infected_limmit");
	SurvivorLimmit = CreateConVar("sm_survivor_limmit_at_spawn", "4", "the survivor limmit at spawn", CVAR_FLAGS,true,4.00,true,18.00);
	InfectedLimmit = CreateConVar("sm_infected_limmit", "4", "the infected limmit and default is 4", CVAR_FLAGS,true,4.00,true,18.00);
	////////////
	////convar handleling
	////////////
	SetConVarBounds(L4dSurvivorLimmit, ConVarBound_Upper, true, 18.0);
	SetConVarBounds(L4dInfectedLimmit, ConVarBounder_Upper, ture, 18.0);
	HookConVarChange(L4DSurvivorLimit, FSL);
	HookConVarChange(SurvivorLimit, FSL);
	HookConVarChange(L4DInfectedLimit, FIL);
	HookConVarChange(InfectedLimit, FIL);
	/////////////////////
	////command
	/////////////////////
	#if DEBUG
	RegConsoleCmd("sm_me", L4dTankCommand, "if you want to kno me go everywhere!!!");
		RegConsoleCmd("sm_jointeam3", JoinTeam, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_joininfected", JoinTeam, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_jointeam2", JoinTeam2, "Jointeam 2 - Without dev console");
	RegConsoleCmd("sm_joinsurvivor", JoinTeam2, "Jointeam 2 - Without dev console");
	//////
	//Events
	//////
	HookEvent("round_start", RoundStart);
	HookEvent("heal_begin", HealBegin);
	HookEvent("heal_end", HealEnd);
	HookEvent("revive_begin", ReviveBegin);
	HookEvent("revive_end", ReviveEnd);
	HookEvent("finale_vehicle_leaving", FinaleVehicleLeaving);
	//////////
	//Load our config
	//////////
	AutoExecConfig(true, "l4d2_extra_bots");
}

#define FORCE_INT_CHANGE(%1,%2,%3) public %1 (Handle:c, const String:o[], const String:n[]) { SetConVarInt(%2,%3); } 
FORCE_INT_CHANGE(FSL,L4DSurvivorLimit,GetConVarInt(SurvivorLimit))
FORCE_INT_CHANGE(FIL,L4DInfectedLimit,GetConVarInt(InfectedLimit))
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (SpawnTimer == INVALID_HANDLE&&TeamPlayers(2)
<GetConVarInt(SurvivorLimmit)) SpawnTimer = CreateTimer(30.0, SpawnCheck, _, TIMER_REPEAT);
	if (KickTimer == INVALID_HANDLE&&TeamPlayers(2)>GetConVarInt(SurvivorLimmit)) KickTimer = CreateTimer(30.0, SpawnCheck, _, TIMER_REPEAT);
}
