/* ========================================================
 * L4D SuperVersus
 * Based upon L4D Spawn Missing Survivors
 * ========================================================
 * Created by DDRKhat
 * Based upon Damizean's "L4D Spawn Missing Survivors"
 * ========================================================
*/
/*
v1.4
-Fixed Cvar forcing on survivor and infected limits
-CVAR Handle code improvements.
-Config file added (l4d_superversus.cfg inside of cfg/Soucemod)
-Tank HP changing now affects HUD
-Improved Tank monitoring
-Improved Left4DownTown checks
v1.3
-Fixed oversight preventing survivor joining
-Join commands now obey vs_max_team_switches
-Added Finale check. Makes saved survivors safe (To protect points)
-Added (If Left4Downtown 0.3.0 or later exists) Lobby Unreserving
-Fixed rare extra survivor
-Added option for Extra medpacks for extra survivors.
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
// *********************************************************************************
#pragma semicolon 1                 // Force strict semicolon mode.
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
// *********************************************************************************
// OPTIONALS - If these exist, we use the. If not, we do nothing.
// *********************************************************************************
native L4D_LobbyUnreserve();
native L4D_LobbyIsReserved();
// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define CONSISTENCY_CHECK	1.0
#define PLUGIN_VERSION		"1.4"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define medkitten		"models/w_models/eapons/w_eq_Medkit.mdl"
#define uzzi			"models/w_models/weapons/w_smg_uzi.mdl"
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
new Handle:XtraHP				= INVALID_HANDLE;
new Handle:KillRes				= INVALID_HANDLE;
new bool:bIncappedOrDead[MAXPLAYERS+1];
new TankHP;
new TankAlive=0;
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
	//////////
	// Left4Dead Dependant
	//////////
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName, "left4dead", false)) SetFailState("Use this in Left 4 Dead only.");
	//////////
	// Convars
	//////////
	CreateConVar("sm_superversus_version", PLUGIN_VERSION, "L4D Super Versus", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	L4DSurvivorLimit = FindConVar("survivor_limit");
	L4DInfectedLimit   = FindConVar("z_max_player_zombies");
	SurvivorLimit = CreateConVar("l4d_survivor_limit","4","Maximum amount of survivors", CVAR_FLAGS,true,1.00,true,18.00);
	InfectedLimit = CreateConVar("l4d_infected_limit","4","Max amount of infected (will not affect bots)", CVAR_FLAGS,true,1.00,true,18.00);
	SuperTank = CreateConVar("l4d_supertank","0","Set tanks HP based on Survivor Count", CVAR_FLAGS,true,0.0,true,1.0);
	XtraHP = CreateConVar("l4d_XtraHP","0","Give extra survivors HP packs? (1 for extra medpacks)", CVAR_FLAGS,true,0.0,true,1.0);
	hpMulti = CreateConVar("l4d_tank_hpmulti","0.25","Tanks HP Multiplier (multi*(survivors-4))", CVAR_FLAGS,true,0.01,true,1.00);
	KillRes = CreateConVar("l4d_killreservation","0","Should we clear Lobby reservaton? (For use with Left4DownTown extension ONLY)", CVAR_FLAGS,true,0.0,true,1.0);
	//////////
	// Convar handling
	//////////
	SetConVarBounds(L4DSurvivorLimit, ConVarBound_Upper, true, 18.0);
	SetConVarBounds(L4DInfectedLimit,   ConVarBound_Upper, true, 18.0);
	HookConVarChange(L4DSurvivorLimit, FSL);
	HookConVarChange(SurvivorLimit, FSL);
	HookConVarChange(L4DInfectedLimit, FIL);
	HookConVarChange(InfectedLimit, FIL);
	//////////
	// Commands
	//////////
	RegAdminCmd("sm_hardzombies", HardZombies, ADMFLAG_KICK, "How many zombies you want. (In multiples of 30. Recommended: 3 Max: 6)");
	RegConsoleCmd("sm_jointeam3", JoinTeam, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_joininfected", JoinTeam, "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_jointeam2", JoinTeam2, "Jointeam 2 - Without dev console");
	RegConsoleCmd("sm_joinsurvivor", JoinTeam2, "Jointeam 2 - Without dev console");
	//////////
	// Events
	//////////
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("tank_killed", Event_Tankdie);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	//////////
	// Load our config
	//////////
	AutoExecConfig(true, "l4d_superversus");

	SetRandomSeed( RoundFloat( GetEngineTime() ) );
}
// ------------------------------------------------------------------------
// OnAskPluginLoad() && OnLibraryRemoved && l4dt
// ------------------------------------------------------------------------
public bool:AskPluginLoad()
{
	MarkNativeAsOptional("L4D_LobbyUnreserve");
	MarkNativeAsOptional("L4D_LobbyIsReserved");
	return true;
}
public bool:l4dt()
{
	if(GetConVarFloat(FindConVar("left4downtown_version"))>0.00) return true;
	else return false;
}
public OnLibraryRemoved(const String:name[]) {if(StrEqual(name,"Left 4 Downtown Extension")) SetConVarInt(KillRes,0);}
// ------------------------------------------------------------------------
// OnConvarChange()
// ------------------------------------------------------------------------
#define FORCE_INT_CHANGE(%1,%2,%3) public %1 (Handle:c, const String:o[], const String:n[]) { SetConVarInt(%2,%3);} 
FORCE_INT_CHANGE(FSL,L4DSurvivorLimit,GetConVarInt(SurvivorLimit))
FORCE_INT_CHANGE(FIL,L4DInfectedLimit,GetConVarInt(InfectedLimit))
// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd() {if (SpawnTimer != INVALID_HANDLE){KillTimer(SpawnTimer);SpawnTimer = INVALID_HANDLE;}}
// ------------------------------------------------------------------------
// jointeam2 && jointeam3
// ------------------------------------------------------------------------
public Action:JoinTeam(client, args) {FakeClientCommand(client,"jointeam 3");return Plugin_Handled;}
public Action:JoinTeam2(client, args) {FakeClientCommand(client,"jointeam 2");return Plugin_Handled;}
// ------------------------------------------------------------------------
// OnClientPutInServer - We have to use this because AIDirector Puts bots in, doesn't connect them.
// ------------------------------------------------------------------------
public OnClientPutInServer(client) {if(GetConVarInt(KillRes)){if(l4dt()) if(L4D_LobbyIsReserved()) L4D_LobbyUnreserve();}}
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
// PlayersInGame()
// ------------------------------------------------------------------------
bool:RealPlayersInGame ()
{
	new i;
	for (i=1;i<=GetMaxClients();i++)
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			return true;
	return false;
}
// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
public OnClientDisconnect(client)
{
	if (IsFakeClient(client)) return;
	if (!RealPlayersInGame()) { new i; for (i=1;i<=GetMaxClients();i++) CreateTimer(0.1, KickFakeClient, i); }
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
	new NumSurvivors = TeamPlayers(2);

	// It's impossible to have less than 4 survivors. Set the lower
	// limit to 4 in order to prevent errors with the respawns. Try
	// again later.
	if (NumSurvivors < 4) return Plugin_Continue;

	new MaxSurvivors = GetConVarInt(SurvivorLimit);
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
	CreateTimer(0.1, KickFakeClient, Bot);
}
public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	new mode = l4d_gamemode();
	if (mode<=2 && mode>0) if (GetConVarInt(XtraHP)) ExtraMedkitsUzis();
	return;
}
ExtraMedkitsUzis()
{
	new ent=FindEntity("weapon_first_aid_kit_spawn");
	if (ent==-1) return;
	
	new Float:pos[3];
	new Float:alt_pos[3];
	
	if (!IsModelPrecached(medkitten) ) PrecacheModel(medkitten);
	if (!IsModelPrecached(uzzi) ) PrecacheModel(uzzi);

	GetEntPropVector (ent, Prop_Data, "m_vecOrigin", pos);
	for (new i=0; i<GetConVarInt(SurvivorLimit)-4; i++)
	{
		new index = CreateEntityByName("weapon_first_aid_kit");
		new index2 = CreateEntityByName("weapon_smg");
		if (index && index2)
		{
			alt_pos[0]=pos[0]+GetRandomFloat( 0.0, 10.0 );
			alt_pos[1]=pos[1]+GetRandomFloat( 0.0, 10.0 );
			alt_pos[2]=pos[2]+5;
			
			SetEntityModel(index,medkitten);
			DispatchKeyValueVector(index, "Origin", alt_pos);
			DispatchSpawn(index);
			
			alt_pos[0]=pos[0]+GetRandomFloat( 0.0, 10.0 );
			alt_pos[1]=pos[1]+GetRandomFloat( 0.0, 10.0 );	
			
			SetEntityModel(index2,uzzi);
			DispatchKeyValueVector(index2, "Origin", alt_pos);
			DispatchSpawn(index2);			
			
		}
	}
	return;
}
FindEntity(String:name[128])
{
	new String:Classname[128];
	new max_entities = GetMaxEntities();
	
	for (new i = 0; i < max_entities; i++)
	{
		if (IsValidEntity (i))
		{
			GetEdictClassname(i, Classname, sizeof(Classname));
			if(StrEqual(Classname, name)) return i;
		}
	}
	return -1;
}
l4d_gamemode() // i get this from sm_did plugin
{
	// 1 - coop / 2 - versus / 3 - survival / or false (thx DDR Khat for code)
	new String:gmode[32];
	GetConVarString(FindConVar("mp_gamemode"), gmode, sizeof(gmode));

	if      (strcmp(gmode, "coop")            == 0) return 1;
	else if (strcmp(gmode, "versus", false)   == 0) return 2;
	else if (strcmp(gmode, "survival", false) == 0) return 3;
	else return false;
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
		if(!TankAlive) {CreateTimer(0.1, SetTankHP, client);}
		else SetEntProp(client,Prop_Send,"m_iMaxHealth",TankHP);
	}
	return;
}
public Event_Tankdie(Handle:event, const String:name[], bool:dontBroadcast)
{
	TankAlive=0;
}
// ------------------------------------------------------------------------
// SetTankHP()
// ------------------------------------------------------------------------
public Action:SetTankHP(Handle:timer, any:client) // this delay is necassary or it fails.
{
	if (!GetConVarInt(SuperTank)) return;
	new Float:extrasurvivors=(float(TeamPlayers(2))-4.0);
	if(RoundFloat(extrasurvivors)<0) return;
	TankHP = RoundFloat((GetEntProp(client,Prop_Send,"m_iHealth")*(1.0+(GetConVarFloat(hpMulti)*extrasurvivors))));
	if(TankHP>65535) TankHP=65535;
	SetEntProp(client,Prop_Send,"m_iHealth",TankHP);
	SetEntProp(client,Prop_Send,"m_iMaxHealth",TankHP);
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
// ------------------------------------------------------------------------
// FinaleEnd() and reliated. Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_FinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast) {new edict_index = FindEntityByClassname(-1, "info_survivor_position");if (edict_index != -1) {new Float:pos[3];GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);for(new i=1; i <= MaxClients; i++){if(IsClientInGame(i) && IsClientInGame(i)){if((GetClientTeam(i) == 2) && (bIncappedOrDead[i] == false)){TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);}}				}	}}
public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast) {new client = GetClientOfUserId(GetEventInt(event, "subject"));bIncappedOrDead[client] = false;}
public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast) {new client = GetClientOfUserId(GetEventInt(event, "victim"));bIncappedOrDead[client] = false;}
public Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast) {new client = GetClientOfUserId(GetEventInt(event, "userid"));bIncappedOrDead[client] = true;}
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {new client = GetClientOfUserId(GetEventInt(event, "userid"));bIncappedOrDead[client] = true;}