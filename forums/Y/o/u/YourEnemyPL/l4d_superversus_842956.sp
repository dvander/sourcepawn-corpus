/* ========================================================
 * L4D SuperVersus
 * Based upon L4D Spawn Missing Survivors
 * ========================================================
 * Created by DDRKhat
 * Based upon Damizean's "L4D Spawn Missing Survivors"
 * ========================================================
*/
/*
v1.2
-Increased Survivor/Infected limit to 18
-Added text-commands to join both teams (for those without console when the GUI fails)
+!jointeam2 / !joinsurvivor - Text equivalent of console command: jointeam 2
+!jointeam3 / !joininfected - Text equivalent of console command: jointeam 3
-Fixed stupid programming sight. Tank spawning fixed as a result.
-Various code cleanup
V1.1
-Adjusts the games built-in variables for handling survivor/infected limit
-Added a text-command people can use to join infected (Where the Switch Team GUI might fail)
-Added a command to increase zombie count.
V1.0
-Initial Release
*/

// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                 // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define CONSISTENCY_CHECK	1.0
#define PLUGIN_VERSION		"1.2"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

// *********************************************************************************
// VARS
// *********************************************************************************
new Handle:SpawnTimer    		= INVALID_HANDLE;
new Handle:SurvivorLimit 		= INVALID_HANDLE;
new Handle:InfectedLimit 		= INVALID_HANDLE;
new Handle:L4DSurvivorLimit 	= INVALID_HANDLE;
new Handle:L4DInfectedLimit 	= INVALID_HANDLE;
new Handle:SuperTank			= INVALID_HANDLE;
new Handle:hpMulti				= INVALID_HANDLE;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
	name        = "L4D SuperVersus",
	author      = "DDRKhat",
	description = "Allow versus to become up to 18vs18",
	version     = PLUGIN_VERSION,
	url         = ""
};


// *********************************************************************************
// METHODS
// *********************************************************************************
// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName, "left4dead", false)) SetFailState("Use this in Left 4 Dead only.");
	CreateConVar("sm_superversus_version", PLUGIN_VERSION, "L4D Super Versus", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	// Hook first spawn
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn, EventHookMode_PostNoCopy);
	L4DSurvivorLimit = FindConVar("survivor_limit");
	L4DInfectedLimit   = FindConVar("z_max_player_zombies");
	SurvivorLimit = CreateConVar("l4d_survivor_limit","4","Maximum amount of survivors", CVAR_FLAGS,true,0.01,true,18.00);
	InfectedLimit = CreateConVar("l4d_infected_limit","4","Max amount of infected (will not affect bots)", CVAR_FLAGS,true,0.01,true,18.00);
	SuperTank = CreateConVar("l4d_supertank","0","Set tanks HP based on Survivor Count", CVAR_FLAGS);
	hpMulti = CreateConVar("l4d_tank_hpmulti","0.25","Tanks HP Multiplier (multi*(survivors-4))", CVAR_FLAGS,true,0.01,true,1.00);
	RegAdminCmd("sm_hardzombies", HardZombies, ADMFLAG_KICK, "How many zombies you want. (In multiples of 30. Recommended: 3 Max: 6)");
	RegConsoleCmd("sm_jointeam3", JoinTeam, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_joininfected", JoinTeam, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_jointeam2", JoinTeam2, "Jointeam 2 - Without dev console");
	RegConsoleCmd("sm_joinsurvivor", JoinTeam2, "Jointeam 2 - Without dev console");
	SetConVarBounds(L4DSurvivorLimit, ConVarBound_Upper, true, 18.0);
	SetConVarBounds(L4DInfectedLimit,   ConVarBound_Upper, true, 18.0);
	HookConVarChange(hpMulti, ConVarChange_Force);
	HookConVarChange(L4DSurvivorLimit, ConVarChange_Force);
	HookConVarChange(L4DSurvivorLimit, ConVarChange_Force);
	HookEvent("tank_spawn", Event_TankSpawn);
}
// ------------------------------------------------------------------------
// OnConvarChange()
// ------------------------------------------------------------------------
public ConVarChange_Force(Handle:convar, const String:oldValue[], const String:newValue[]) {
if(convar==hpMulti&&StringToFloat(newValue)==0.0) SetConVarFloat(hpMulti,StringToFloat(newValue));
if(convar==L4DSurvivorLimit&&L4DSurvivorLimit!=SurvivorLimit) SetConVarInt(L4DSurvivorLimit,GetConVarInt(SurvivorLimit));
if(convar==L4DInfectedLimit&&L4DInfectedLimit!=InfectedLimit) SetConVarInt(L4DInfectedLimit,GetConVarInt(InfectedLimit));
}
// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd() {if (SpawnTimer != INVALID_HANDLE){KillTimer(SpawnTimer);SpawnTimer = INVALID_HANDLE;}}
// ------------------------------------------------------------------------
// sm_jointeam3()
// ------------------------------------------------------------------------
public Action:JoinTeam(client, args) {FakeClientCommand(client,"jointeam 3");}
public Action:JoinTeam2(client, args) {FakeClientCommand(client,"jointeam 2");}
// ------------------------------------------------------------------------
// OnClientCommand()
// ------------------------------------------------------------------------
public Action:OnClientCommand(client, args)
{
	new String:cmd[16];
	new String:inp[16];
	GetCmdArg(0, cmd, sizeof(cmd));
	GetCmdArg(1, inp, sizeof(inp));
	new Val=StringToInt(inp[0]);
	if (StrEqual(cmd, "jointeam")&&Val==3&&GetConVarInt(InfectedLimit)>TeamPlayers(3)){ChangeClientTeam(client, 3);return Plugin_Handled;}
	if (StrEqual(cmd, "jointeam")&&Val==2){return Plugin_Handled;}
	return Plugin_Continue;
}
// ------------------------------------------------------------------------
// TeamPlayers() arg = teamnum
// ------------------------------------------------------------------------
public TeamPlayers(any:team)
{
	new int=0;
	for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientConnected(i)) continue;
			if (!IsClientInGame(i))    continue;
			if (GetClientTeam(i) != team) continue;
			int++;
		}
	return int;
}
// ------------------------------------------------------------------------
// Event_PlayerFirstSpawn()
// ------------------------------------------------------------------------
public Event_PlayerFirstSpawn(Handle:hEvent, const String:strName[], bool:bDontBroadcast) {if (SpawnTimer != INVALID_HANDLE) return;SpawnTimer = CreateTimer(CONSISTENCY_CHECK, SpawnTick, _, TIMER_REPEAT);}
// ------------------------------------------------------------------------
// SpawnTick()
// ------------------------------------------------------------------------
public Action:SpawnTick(Handle:hTimer, any:Junk)
{    
	// Determine the number of survivors and fill the empty
	// slots.
	new NumSurvivors = 0;
	new MaxSurvivors = GetConVarInt(SurvivorLimit);

	NumSurvivors = TeamPlayers(2);

	// It's impossible to have less than 4 survivors. Set the lower
	// limit to 4 in order to prevent errors with the respawns. Try
	// again later.
	if (NumSurvivors < 4) return Plugin_Continue;

	// Create missing bots
	for (;NumSurvivors < MaxSurvivors; NumSurvivors++) SpawnFakeClient();

	// Once the missing bots are made, dispose of the timer
	SpawnTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

// ------------------------------------------------------------------------
// SpawnFakeClient()
// ------------------------------------------------------------------------
SpawnFakeClient()
{
	// Spawn bot survivor.
	new Bot = CreateFakeClient("SurvivorBot");
	if (Bot == 0) return;

	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	CreateTimer(2.5, KickFakeClient, Bot);
}
// ------------------------------------------------------------------------
// KickFakeClient()
// ------------------------------------------------------------------------
public Action:KickFakeClient(Handle:hTimer, any:Client) {KickClient(Client, "Free slot.");return Plugin_Handled;}
// ------------------------------------------------------------------------
// OnTankSpawn()
// ------------------------------------------------------------------------
public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(SuperTank))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsFakeClient(client))
		{
			CreateTimer(0.1, SetTankHP, client);
		}
	}
	return;
}
// ------------------------------------------------------------------------
// SetTankHP()
// ------------------------------------------------------------------------
public Action:SetTankHP(Handle:timer, any:client) // this delay is necassary or it fails.
{
	if (!GetConVarInt(SuperTank)) return;
	new Float:extrasurvivors=(float(TeamPlayers(2))-4.0);
	if(RoundFloat(extrasurvivors)<0) return;
	new tankhp = RoundFloat((GetEntProp(client,Prop_Send,"m_iHealth")*(1.0+(GetConVarFloat(hpMulti)*extrasurvivors))));
	if(tankhp>65535) tankhp=65535;
	SetEntProp(client,Prop_Send,"m_iHealth",tankhp);
	tankhp = GetEntProp(client,Prop_Send,"m_iHealth");
}
// ------------------------------------------------------------------------
// HardZombies()
// ------------------------------------------------------------------------

public Action:HardZombies(client, args) 
{
	new String:arg[8];
	GetCmdArg(1,arg,8);
	new Input=StringToInt(arg[0]);
	if(Input==1)
	{
		SetConVarInt(FindConVar("z_common_limit"), 30); // Default
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 10); // Default
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30); // Default
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 20); // Default
		SetConVarInt(FindConVar("z_mega_mob_size"), 45); // Default
	}		
	else if(Input>1&&Input<7)
	{
		SetConVarInt(FindConVar("z_common_limit"), 30*Input); // Default 30
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), 30*Input); // Default 10
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), 30*Input); // Default 30
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"), 30*Input); // Default 20
		SetConVarInt(FindConVar("z_mega_mob_size"), 30*Input); // Default 45
	}
	else {ReplyToCommand(client, "\x01[SM] Usage: How many zombies you want. (In multiples of 30. Recommended: 3 Max: 6)");ReplyToCommand(client, "\x01          : Anything above 3 may cause moments of lag 1 resets the defaults");}
	return Plugin_Handled;
}