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
#define PLUGIN_VERSION		"1.4 modified"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define M_medkit		"models/w_models/weapons/w_eq_Medkit.mdl"
#define M_uzi			"models/w_models/weapons/w_smg_uzi.mdl"
#define M_autoshotgun	"models/w_models/weapons/w_autoshot_m4super.mdl"
#define M_m16			"models/w_models/weapons/w_rifle_m16a2.mdl"

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
new Handle:XtraWeapons			= INVALID_HANDLE;
new Handle:SayAboutTankHP		= INVALID_HANDLE;
new Handle:KillRes				= INVALID_HANDLE;
new bool:bIncappedOrDead[MAXPLAYERS+1];
new TankHP;
new TankAlive=0;
new bool:alreadyMedWeapSpawned=false;
// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
	name        = "L4D SuperVersus",
	author      = "original author DDRKhat, modifications YourEnemyPL",
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
	XtraWeapons = CreateConVar("l4d_XtraWeapons","0","Give extra weapons?", CVAR_FLAGS,true,0.0,true,1.0);
	SayAboutTankHP = CreateConVar("l4d_tankhp_inform","0","Say about tank HP?", CVAR_FLAGS,true,0.0,true,1.0);
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
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
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
	
	new mode = l4d_gamemode();
	if (mode<=2 && mode>0) 
		if ( GetConVarInt(XtraHP) || GetConVarInt(XtraWeapons) )
			ExtraMedkitsWeapons();
}
public Action:Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	new mode = l4d_gamemode();
	if (mode<=2 && mode>0) 
		if ( GetConVarInt(XtraHP) || GetConVarInt(XtraWeapons) )
			ExtraMedkitsWeapons();
			
	return;
}
public Action:Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	alreadyMedWeapSpawned = false;
	return;
}
public OnMapStart()
{
	alreadyMedWeapSpawned = false;
	
	new mode = l4d_gamemode();
	if (mode<=2 && mode>0) 
		if ( GetConVarInt(XtraHP) || GetConVarInt(XtraWeapons) )
			ExtraMedkitsWeapons();
	return;		
}
ExtraMedkitsWeapons()
{
	if (alreadyMedWeapSpawned) return;

	//new near_ent = FindNearestFarthestEntity("weapon_ammo_spawn",true); // nearest
	//if (near_ent==-1) return; // no weaponammostack, exiting
	
	new far_ent = FindNearestFarthestEntity("weapon_ammo_spawn",false); // farthest
	if (far_ent==-1) return; // no weaponammostack, exiting

	if (!IsModelPrecached(M_medkit) ) PrecacheModel(M_medkit);
	if (!IsModelPrecached(M_uzi) ) PrecacheModel(M_uzi);
	if (!IsModelPrecached(M_autoshotgun) ) PrecacheModel(M_autoshotgun);
	if (!IsModelPrecached(M_m16) ) PrecacheModel(M_m16);

	alreadyMedWeapSpawned = true;
	
	new String:map[128];
	GetCurrentMap(map, sizeof(map));
	
	new m1 = StrContains(map,"airport05_runway",false);
	new m2 = StrContains(map,"farm05_cornfield",false);
	new m3 = StrContains(map,"hospital05_rooftop",false);
	new m4 = StrContains(map,"smalltown05_houseboat",false);

	new bool:IsFinalMap = ( (m1>=0 || m2>=0 || m3>=0 || m4>=0)?true:false );
	
	new Float:pos[3];
	new Float:alt_pos[3];
	new index;
	new index2;
	new index3;
	
	//if (!IsFinalMap || (near_ent!=far_ent && IsFinalMap) ){
	//GetEntPropVector (near_ent, Prop_Data, "m_vecOrigin", pos);
	CalcStartPosition(pos);
	for (new i=0; i<GetConVarInt(SurvivorLimit)-4; i++)
	{
		if (GetConVarInt(XtraHP))
		{
			index = CreateEntityByName("weapon_first_aid_kit");
			
			if (index){
			alt_pos[0]=pos[0]+GetRandomFloat( -5.0, 5.0 );
			alt_pos[1]=pos[1]+GetRandomFloat( -5.0, 5.0 );
			alt_pos[2]=pos[2]+GetRandomFloat( 5.0, 15.0 );
			
			SetEntityModel(index,M_medkit);
			DispatchKeyValueVector(index, "Origin", alt_pos);
			DispatchSpawn(index);
			}
		}
		
		if (GetConVarInt(XtraWeapons) )
		{
			index2 = CreateEntityByName("weapon_smg");
			
			if (index2){
			alt_pos[0]=pos[0]+GetRandomFloat( -5.0, 5.0 );
			alt_pos[1]=pos[1]+GetRandomFloat( -5.0, 5.0 );
			alt_pos[2]=pos[2]+GetRandomFloat( 5.0, 15.0 );
			
			SetEntityModel(index2,M_uzi);
			DispatchKeyValueVector(index2, "Origin", alt_pos);
			DispatchSpawn(index2);			
			}
		}
	}
	//}

	if (IsFinalMap){
		GetEntPropVector (far_ent, Prop_Data, "m_vecOrigin", pos);
		for (new i=0; i<GetConVarInt(SurvivorLimit)-4; i++)
		{
			if (GetConVarInt(XtraHP))
			{
				index = CreateEntityByName("weapon_first_aid_kit");
				
				if (index){
				alt_pos[0]=pos[0]+GetRandomFloat( -5.0, 5.0 );
				alt_pos[1]=pos[1]+GetRandomFloat( -5.0, 5.0 );
				alt_pos[2]=pos[2]+GetRandomFloat( 5.0, 15.0 );
				
				SetEntityModel(index,M_medkit);
				DispatchKeyValueVector(index, "Origin", alt_pos);
				DispatchSpawn(index);
				}
			}
			
			if (GetConVarInt(XtraWeapons) )
			{
				index2 = CreateEntityByName("weapon_autoshotgun");
				index3 = CreateEntityByName("weapon_rifle");
				
				if (index2 && index3){
				alt_pos[0]=pos[0]+GetRandomFloat( -5.0, 5.0 );
				alt_pos[1]=pos[1]+GetRandomFloat( -5.0, 5.0 );	
				alt_pos[2]=pos[2]+GetRandomFloat( 5.0, 15.0 );
				
				SetEntityModel(index2,M_autoshotgun);
				DispatchKeyValueVector(index2, "Origin", alt_pos);
				DispatchSpawn(index2);			
				
				alt_pos[0]=pos[0]+GetRandomFloat( -5.0, 5.0 );
				alt_pos[1]=pos[1]+GetRandomFloat( -5.0, 5.0 );	
				alt_pos[2]=pos[2]+GetRandomFloat( 5.0, 15.0 );
				
				SetEntityModel(index3,M_m16);
				DispatchKeyValueVector(index3, "Origin", alt_pos);
				DispatchSpawn(index3);	
				}
			}
		}
	}

	return;
}

//  near = true - nearest
//  near = false - farthest
FindNearestFarthestEntity(String:name[128],bool:near)
{
	new String:Classname[128];
	new max_entities = GetMaxEntities();
	
	/*// find any player
	new player;
	for (player = 0; player < max_entities; player++)
	{
		if (IsValidEntity (player))
		{
			GetEdictClassname(player, Classname, sizeof(Classname));
			if(StrEqual(Classname, "player")) break;
		}
	}
	if (player==max_entities) return -1;
	new Float:start_pos[3];
	GetEntPropVector(player, Prop_Data, "m_vecOrigin", start_pos);
	*/
	
	new Float:start_pos[3];
	CalcStartPosition(start_pos);
	
	new Float:pos[3];
	new ent=-1;
	new sign = (near?1:-1);
	new Float:distansce = 1000000.0*sign;

	for (new i = 0; i < max_entities; i++)
	{
		if (IsValidEntity (i))
		{
			GetEdictClassname(i, Classname, sizeof(Classname));
			if(StrEqual(Classname, name))
				{
					GetEntPropVector(i, Prop_Data, "m_vecOrigin",pos);
					new Float:otherDist = CalcDistance(pos,start_pos);
					if (distansce*sign>otherDist*sign)
					{
						distansce = otherDist;
						ent = i;
					}
				}
		}
	}
	return ent;
}
Float:CalcDistance(Float:pos[3],Float:player_pos[3])
{
	return SquareRoot((pos[0]-player_pos[0])*(pos[0]-player_pos[0])+(pos[1]-player_pos[1])*(pos[1]-player_pos[1])+(pos[2]-player_pos[2])*(pos[2]-player_pos[2]));
}

CalcStartPosition(Float:array[3])
{
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	decl index;
	
	if ((index=StrContains(map,"smalltown",false))>=0)
		{
			switch (map[index+10])
			{
			case '1': SetPos(array,-11748,-14701,-207);
			case '2': SetPos(array,-11047,-9055,-591);
			case '3': SetPos(array,-8476,-5564,-24);
			case '4': SetPos(array,-3091,103,328);
			case '5': SetPos(array,1972,4651,-63);
			}
		}
	else if ((index=StrContains(map,"airport",false))>=0)
		{
			switch (map[index+8])
			{
			case '1': SetPos(array,6837,-667,768);
			case '2': SetPos(array,5274,2621,48);
			case '3': SetPos(array,-5354,-3099,16);
			case '4': SetPos(array,-450,3531,296);
			case '5': SetPos(array,-6617,12040,152);
			}
		}
	else if ((index=StrContains(map,"farm",false))>=0)
		{	
			switch (map[index+5])
			{
			case '1': SetPos(array,-7956,-14987,301);
			case '2': SetPos(array,-6586,-6707,348);
			case '3': SetPos(array,-961,-10377,-63);
			case '4': SetPos(array,7723,-11371,440);
			case '5': SetPos(array,10459,-352,-28);
			}
		}
	else if ((index=StrContains(map,"hospital",false))>=0)
		{
			switch (map[index+9])
			{
			case '1': SetPos(array,1753,874,432);
			case '2': SetPos(array,2955,3026,16);
			case '3': SetPos(array,10937,4725,16);
			case '4': SetPos(array,12407,12569,16);
			case '5': SetPos(array,5383,8442,5536);
			}
		}
}
SetPos(Float:array[3], pos0, pos1, pos2)
{
	array[0]=float(pos0);
	array[1]=float(pos1);
	array[2]=float(pos2);
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
	if ( GetConVarInt(SayAboutTankHP) ) PrintToChatAll("Tank new HP %d (default %d)",TankHP,GetEntProp(client,Prop_Send,"m_iHealth"));
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
