/* ========================================================
 * L4D SuperVersus
 * Based upon L4D Spawn Missing Survivors
 * ========================================================
 * Created by DDRKhat
 * Based upon Damizean's "L4D Spawn Missing Survivors"
 * Thanks to Mad_Dugan for finale code
 * Tweaked and cleaned by Damizean.
 * ========================================================
*/
/*
	(Unofficial tweaks by Damizean)
	- Fixed possible error in finale management
	- Added extra check for kicking bots to prevent kicking real
	  clients.
	- Added !changeteam - Small menu to change team, including spectators,
	  in case someone needs to go AFK or teams need to be switched..
	- Reformatted/cleaned up the code.

	v1.4
	- Fixed Cvar forcing on survivor and infected limits
	- CVAR Handle code improvements.
	- Config file added (l4d_superversus.cfg inside of cfg/Soucemod)
	- Tank HP changing now affects HUD
	- Improved Tank monitoring
	- Improved Left4DownTown checks

	v1.3
	- Fixed oversight preventing survivor joining
	- Join commands now obey vs_max_team_switches
	- Added Finale check. Makes saved survivors safe (To protect points)
	- Added (If Left4Downtown 0.3.0 or later exists) Lobby Unreserving
	- Fixed rare extra survivor
	- Added option for Extra medpacks for extra survivors.

	v1.2
	- Increased Survivor/Infected limit to 18
	- Added text-commands to join both teams (for those without console when the GUI fails)
	+ !jointeam2 / !joinsurvivor - Text equivalent of console command: jointeam 2
	+ !jointeam3 / !joininfected - Text equivalent of console command: jointeam 3
	- Fixed stupid programming sight. Tank spawning fixed as a result.
	- Various code cleanup
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
#pragma semicolon 1	// Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>

// *********************************************************************************
// OPTIONALS - If these exist, we use them. If not, we do nothing.
// *********************************************************************************
native L4D_LobbyUnreserve();
native L4D_LobbyIsReserved();

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define CONSISTENCY_CHECK	1.5
#define PLUGIN_VERSION	  	"1.4"
#define CVAR_FLAGS		  	FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MEDKIT					"models/w_models/weapons/w_eq_Medkit.mdl"

// *********************************************************************************
// VARIABLES
// *********************************************************************************
// Convars
new Handle: SpawnTimer				= INVALID_HANDLE;
new Handle: SurvivorLimit			= INVALID_HANDLE;
new Handle: InfectedLimit		 	= INVALID_HANDLE;
new Handle: L4D_InfectedLimit	 	= INVALID_HANDLE;
new Handle: L4D_SurvivorLimit		= INVALID_HANDLE;
new Handle: SuperTank					= INVALID_HANDLE;
new Handle: SuperTankMultiplier	= INVALID_HANDLE;
new Handle: ExtraAidKits				= INVALID_HANDLE;
new Handle: ExtraAidKitsCount		= INVALID_HANDLE;
new Handle: Unreserve					= INVALID_HANDLE;

// Variables to keep track of the survivors status
new bool: ClientUnableToEscape[MAXPLAYERS + 1];

// Variable to check if the convar is changing to prevent change loops
new bool: ConvarChanging = false;

// Variable to keep track of the amount of medkits
new AidKitCount = 0;
// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
	name			= "L4D Super Versus (Unofficial version)",
	author	  		= "DDRKhat",
	description	= "Allow versus to become up to 18vs18",
	version		= PLUGIN_VERSION,
	url			= ""
};

// *********************************************************************************
// METHODS
// *********************************************************************************
// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
public OnPluginStart()
{
	// Require Left 4 Dead
	decl String: ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if (!StrEqual(ModName, "left4dead", false))
	{
		SetFailState("Use this in Left 4 Dead only.");
	}


	// Create convars
	CreateConVar("sm_supercoop_version", PLUGIN_VERSION, "L4D Super Coop", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	L4D_SurvivorLimit  	 	= FindConVar("survivor_limit");
	L4D_InfectedLimit   	= FindConVar("z_max_player_zombies");
	SurvivorLimit	   		= CreateConVar("l4d_survivor_limit", "4", "Maximum amount of survivors", CVAR_FLAGS, true, 1.00, true, 18.00);
	InfectedLimit	  		= CreateConVar("l4d_infected_limit", "4", "Max amount of human infected", CVAR_FLAGS, true, 1.00, true, 18.00);
	SuperTank		  			= CreateConVar("l4d_supertank", "0", "Set tanks HP based on number of survivors", CVAR_FLAGS, true, 0.0, true, 1.0);
	SuperTankMultiplier	= CreateConVar("l4d_tank_hpmulti", "0.25", "Tanks HP multiplier (multi * (survivors - 4))", CVAR_FLAGS, true, 0.01, true, 1.00);
	ExtraAidKits				= CreateConVar("l4d_XtraHP", "1", "Give survivors extra HP packs at beginning of each round and at finale radio?", CVAR_FLAGS, true, 0.0, true, 1.0);
	ExtraAidKitsCount		= CreateConVar("l4d_XtraHP_count", "4", "If XtraHP is turned on, how many HP packes to give?", CVAR_FLAGS, true, 4.0);
	Unreserve		   			= CreateConVar("l4d_killreservation", "0", "Should we clear lobby reservaton? (For use with Left4DownTown extension ONLY)", CVAR_FLAGS, true, 0.0, true, 1.0);

	// Hook convars
	SetConVarBounds(L4D_SurvivorLimit,  ConVarBound_Upper, true, 18.0);
	SetConVarBounds(L4D_InfectedLimit,  ConVarBound_Upper, true, 18.0);
	HookConVarChange(L4D_SurvivorLimit,	ConVar_Manage);
	HookConVarChange(SurvivorLimit,	 	ConVar_Manage);
	HookConVarChange(L4D_InfectedLimit, ConVar_Manage);
	HookConVarChange(InfectedLimit,	 	ConVar_Manage);

	// Commands
	RegAdminCmd("sm_hardzombies",		HardZombies, ADMFLAG_KICK, "How many zombies you want to add. (In multiples of 30. Recommended: 3 Max: 6)");
	RegConsoleCmd("sm_changeteam",   	ChangeTeam, "Displays a change team menu.");
	RegConsoleCmd("sm_jointeam3",		JoinTeam,   "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_joininfected", 	JoinTeam,   "Jointeam 3 - Without dev console");
	RegConsoleCmd("sm_jointeam2",		JoinTeam2,  "Jointeam 2 - Without dev console");
	RegConsoleCmd("sm_joinsurvivor", 	JoinTeam2,  "Jointeam 2 - Without dev console");

	// Events
	HookEvent("tank_spawn",		   		Event_TankSpawn);
	HookEvent("finale_vehicle_leaving",	Event_FinaleVehicleLeaving, EventHookMode_PostNoCopy);
	HookEvent("revive_success",		 	Event_ReviveSuccess);
	HookEvent("survivor_rescued",	   		Event_SurvivorRescued);
	HookEvent("player_incapacitated",   	Event_PlayerIncapacitated);
	HookEvent("player_death",		   		Event_PlayerDeath);
	HookEvent("round_start",				Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", 				Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", 			Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_first_spawn",	 	Event_PlayerFirstSpawn, EventHookMode_Post);

	// Exec config
	AutoExecConfig(true, "l4d_superversus");
}

// ------------------------------------------------------------------------
// OnAskPluginLoad()
// ------------------------------------------------------------------------
public bool: AskPluginLoad()
{
	MarkNativeAsOptional("L4D_LobbyUnreserve");
	MarkNativeAsOptional("L4D_LobbyIsReserved");

	return true;
}

// ------------------------------------------------------------------------
// OnLibraryRemoved()
// ------------------------------------------------------------------------
public OnLibraryRemoved(const String: name[])
{
	if (StrEqual(name, "Left 4 Downtown Extension"))
	{
		SetConVarInt(Unreserve, 0);
	}
}

// ------------------------------------------------------------------------
// L4DDownTown()
// ------------------------------------------------------------------------
bool: L4DDownTown()
{
	if (GetConVarFloat(FindConVar("left4downtown_version")) > 0.00)
	{
		return true;
	}
	else
	{
		return false;
	}
}

// ------------------------------------------------------------------------
// ConVar_Manage()
// ------------------------------------------------------------------------
public ConVar_Manage(Handle: ConVar, const String: Value[], const String: NewValue[])
{
	if (ConvarChanging)
	{
		return;
	}

	ConvarChanging = true;
	SetConVarInt(L4D_SurvivorLimit, GetConVarInt(SurvivorLimit));
	SetConVarInt(L4D_InfectedLimit, GetConVarInt(InfectedLimit));
	ConvarChanging = false;
}

// ------------------------------------------------------------------------
// OnMapStart()
// ------------------------------------------------------------------------
public OnMapStart()
{
	// Reset given aid kit count
	AidKitCount = 0;

	//Add medkits if turned on
	if (GetConVarInt(ExtraAidKits) && (AidKitCount < GetConVarInt(ExtraAidKitsCount)))
	{
		ExtraMedkits();
	}

	return;
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd()
{
	if (SpawnTimer != INVALID_HANDLE)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = INVALID_HANDLE;
	}
}

// ------------------------------------------------------------------------
// Event_RoundStart
// ------------------------------------------------------------------------
public Action: Event_RoundStart(Handle: hEvent, const String: strName[], bool: bDontBroadcast)
{
	//Add medkits if turned on
	if (GetConVarInt(ExtraAidKits) && (AidKitCount < GetConVarInt(ExtraAidKitsCount)))
	{
		ExtraMedkits();
	}

	return;
}

// ------------------------------------------------------------------------
// Event_RoundEnd
// ------------------------------------------------------------------------
public Action: Event_RoundEnd (Handle: event, const String: name[], bool: dontBroadcast)
{
	// Reset given aid kit count
	AidKitCount = 0;

	return;
}

// ------------------------------------------------------------------------
// ChangeTeam() - Thanks to Damizean for this
// ------------------------------------------------------------------------
public Action: ChangeTeam(Client, Args)
{
	new Handle: hMenu = CreateMenu(MenuChangeTeam);
	SetMenuTitle(hMenu, "Change team");
	AddMenuItem(hMenu, "", "Survivors");
	AddMenuItem(hMenu, "", "Spectators");
	AddMenuItem(hMenu, "", "Infecteds");

	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, Client, 20);

	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// MenuChangeTeam() - Thanks to Damizean for this
// ------------------------------------------------------------------------
public MenuChangeTeam(Handle: hCurrentMenu, MenuAction: State, Param1, Param2)
{
	switch (State)
	{
		case MenuAction_Select:
		{
			// Determine if the player choose a valid option
			switch(Param2)
			{
				case 0:
				{
					FakeClientCommandEx(Param1, "jointeam 2");
				}
				case 1:
				{
					ChangeClientTeam(Param1, 1);
				}
				case 2:
				{
					ChangeClientTeam(Param1, 3);
				}
			}
		}

		case MenuAction_End:
		{
			CloseHandle(hCurrentMenu);
		}
	}
}

// ------------------------------------------------------------------------
// JoinTeam
// ------------------------------------------------------------------------
public Action:JoinTeam(client, args)
{
	FakeClientCommand(client,"jointeam 3");
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// JoinTeam2
// ------------------------------------------------------------------------
public Action: JoinTeam2(client, args)
{
	FakeClientCommand(client, "jointeam 2");

	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// OnClientPutInServer - We have to use this because AIDirector Puts bots in, but doesn't connect them
// ------------------------------------------------------------------------
public OnClientPutInServer(client)
{
	if (!GetConVarInt(Unreserve))
	{
		return;
	}

	if (L4DDownTown() || L4D_LobbyIsReserved())
	{
		L4D_LobbyUnreserve();
	}
}

// ------------------------------------------------------------------------
// TeamPlayers()
// ------------------------------------------------------------------------
TeamPlayers(any: team)
{
	new int = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		// Connection check
		if (!IsClientConnected(i))
		{
			continue;
		}
		if (!IsClientInGame(i))
		{
			continue;
		}
		if (GetClientTeam(i) != team)
		{
			continue;
		}

		int++;
	}

	return int;
}

// ------------------------------------------------------------------------
// RealPlayersInGame()
// ------------------------------------------------------------------------
bool: RealPlayersInGame()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			return true;
		}
	}

	return false;
}

// ------------------------------------------------------------------------
// OnClientConnect()
// ------------------------------------------------------------------------
public bool: OnClientConnect(Client, String: rejectmsg[], maxlen)
{
	new String: name[100];
	GetClientName(Client, name, 100);

	// Fix for tank not spawning during finale
	if (IsFakeClient(Client) && StrContains(name, "tank", false))
	{
		TankHasJoined();
	}

	return true;
}

// ------------------------------------------------------------------------
// OnClientDisconnect()
// ------------------------------------------------------------------------
public OnClientDisconnect(Client)
{
	if (IsFakeClient(Client))
	{
		return;
	}

	if (!RealPlayersInGame())
	{
		new i;
		for (i = 1; i <= GetMaxClients(); i++)
		{
			if (!IsClientConnected(i))
			{
				continue;
			}

			KickFakeClient(INVALID_HANDLE, i);
		}
	}
}

// ------------------------------------------------------------------------
// Event_PlayerFirstSpawn()
// ------------------------------------------------------------------------
public Event_PlayerFirstSpawn(Handle: hEvent, const String: strName[], bool: bDontBroadcast)
{
	// Startup bot spawn timer
	if (SpawnTimer != INVALID_HANDLE)
	{
		return;
	}

	SpawnTimer = CreateTimer(CONSISTENCY_CHECK, SpawnTick, _, TIMER_REPEAT);
}

// ------------------------------------------------------------------------
// SpawnTick()
// ------------------------------------------------------------------------
public Action: SpawnTick(Handle: hTimer, any: Junk)
{
	// Determine the number of survivors and fill the empty
	// slots.
	new NumSurvivors = TeamPlayers(2);

	// It's impossible to have less than 4 survivors. Set the lower
	// limit to 4 in order to prevent errors with the respawns. Try
	// again later.
	if (NumSurvivors < 4)
	{
		return Plugin_Continue;
	}

	new MaxSurvivors = GetConVarInt(SurvivorLimit);
	// Create missing bots
	for (;NumSurvivors < MaxSurvivors; NumSurvivors++)
	{
		SpawnFakeClient();
	}

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
	if (Bot == 0)
	{
		return;
	}

	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	CreateTimer(0.5, KickFakeClient, Bot);

	if (GetConVarInt(ExtraAidKits) && (AidKitCount < GetConVarInt(ExtraAidKitsCount)))
	{
		ExtraMedkits();
	}
}

// ------------------------------------------------------------------------
// KickFakeClient()
// ------------------------------------------------------------------------
public Action: KickFakeClient(Handle: hTimer, any: Client)
{
	if (!IsClientConnected(Client))
	{
		return Plugin_Stop;
	}

	if (!IsFakeClient(Client))
	{
		return Plugin_Stop;
	}

	KickClient(Client, "Killing bot - Freeing slot.");

	return Plugin_Stop;
}

// ------------------------------------------------------------------------
// Event_TankSpawn() - For SuperTank
// ------------------------------------------------------------------------
public Event_TankSpawn(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	if (!GetConVarInt(SuperTank))
	{
		return;
	}

	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	CreateTimer(1.0, SetTankHP, Client);
}

// ------------------------------------------------------------------------
// TankHasJoined() - Fixes tank not spawning in finale, thanks AtomicStryker
// ------------------------------------------------------------------------
public Action: TankHasJoined()
{
	// Iterate all Clients
	for (new target = 1; target <= GetMaxClients(); target++)
	{
		if (IsClientConnected(target))
		{
			// Get the target client class
			new String: class[100];
			GetClientModel(target, class, sizeof(class));

			// Kick all Infected Bots that are NOT tank
			if (GetClientTeam(target) == 3 && IsFakeClient(target) && (StrContains(class, "tank", false) == -1))
			{
				KickClient(target);
			}
		}
	}

	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// SetTankHP() - Sets thank HP if SuperTank is turned on
// ------------------------------------------------------------------------
public Action: SetTankHP(Handle: Timer, any: Client)
{
	if (!GetConVarInt(SuperTank))
	{
		return Plugin_Stop;
	}

	new Float: ExtraSurvivors = (float(TeamPlayers(2)) - 4.0);
	if (RoundFloat(ExtraSurvivors) < 0)
	{
		return Plugin_Stop;
	}

	new TankHP = RoundFloat((GetEntProp(Client, Prop_Send, "m_iHealth") * (1.0 + (GetConVarFloat(SuperTankMultiplier) * ExtraSurvivors))));
	if (TankHP > 65535)
	{
		TankHP = 65535;
	}

	SetEntProp(Client, Prop_Send, "m_iHealth",	TankHP);
	SetEntProp(Client, Prop_Send, "m_iMaxHealth", TankHP);

	return Plugin_Stop;
}

// ------------------------------------------------------------------------
// HardZombies()
// ------------------------------------------------------------------------
public Action: HardZombies(client, args)
{
	new String: arg[8];
	GetCmdArg(1, arg, 8);
	new Input = StringToInt(arg[0]);

	if (Input == 1)
	{
		SetConVarInt(FindConVar("z_common_limit"),		  		30); // Default
		SetConVarInt(FindConVar("z_mob_spawn_min_size"),		10); // Default
		SetConVarInt(FindConVar("z_mob_spawn_max_size"),		30); // Default
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"),	20); // Default
		SetConVarInt(FindConVar("z_mega_mob_size"),		 	45); // Default
	}
	else if (Input > 1 && Input < 7)
	{
		SetConVarInt(FindConVar("z_common_limit"),		  		30 * Input);
		SetConVarInt(FindConVar("z_mob_spawn_min_size"),		30 * Input);
		SetConVarInt(FindConVar("z_mob_spawn_max_size"),		30 * Input);
		SetConVarInt(FindConVar("z_mob_spawn_finale_size"),	30 * Input);
		SetConVarInt(FindConVar("z_mega_mob_size"),		 	30 * Input);
	}
	else
	{
		ReplyToCommand(client, "\x01[SM] Usage: How many zombies you want to add. (In multiples of 30. Recommended: 3 Max: 6)");
		ReplyToCommand(client, "\x01		  : Anything above 3 may cause moments of lag, 1 resets the defaults");
	}

	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// ExtraMedkits() - Adds extra medkits if turned on, thanks to YourEnemyPL
// ------------------------------------------------------------------------
ExtraMedkits()
{
	if (AidKitCount >=  GetConVarInt(ExtraAidKitsCount))
	{
		return;
	}

	new far_ent = FindNearestFarthestEntity("weapon_ammo_spawn", false);
	if (far_ent == -1)
	{
		return;
	}

	if (!IsModelPrecached(MEDKIT))
	{
		PrecacheModel(MEDKIT);
	}

	new String: map[128];
	GetCurrentMap(map, sizeof(map));

	new m1 = StrContains(map, "airport05_runway", false);
	new m2 = StrContains(map, "farm05_cornfield", false);
	new m3 = StrContains(map, "hospital05_rooftop", false);
	new m4 = StrContains(map, "smalltown05_houseboat", false);

	new bool: IsFinalMap = ((m1 >= 0 || m2 >= 0 || m3 >= 0 || m4 >= 0) ? true : false);

	new Float: pos[3];
	new Float: alt_pos[3];
	new index;

	CalcStartPosition(pos);
	for (new i = 0; i < GetConVarInt(ExtraAidKitsCount); i++)
	{
		if (GetConVarInt(ExtraAidKits))
		{
			index = CreateEntityByName("weapon_first_aid_kit");

			if (index)
			{
				alt_pos[0] = pos[0]+GetRandomFloat( -5.0, 5.0 );
				alt_pos[1] = pos[1]+GetRandomFloat( -5.0, 5.0 );
				alt_pos[2] = pos[2]+GetRandomFloat( 5.0, 15.0 );

				SetEntityModel(index, MEDKIT);
				DispatchKeyValueVector(index, "Origin", alt_pos);
				DispatchSpawn(index);
			}
		}
	}

	if (IsFinalMap){
		GetEntPropVector (far_ent, Prop_Data, "m_vecOrigin", pos);
		for (new i = 0; i < GetConVarInt(ExtraAidKitsCount); i++)
		{
			if (GetConVarInt(ExtraAidKits))
			{
				index = CreateEntityByName("weapon_first_aid_kit");

				if (index)
				{
					alt_pos[0] = pos[0]+GetRandomFloat( -5.0, 5.0 );
					alt_pos[1] = pos[1]+GetRandomFloat( -5.0, 5.0 );
					alt_pos[2] = pos[2]+GetRandomFloat( 5.0, 15.0 );

					SetEntityModel(index, MEDKIT);
					DispatchKeyValueVector(index, "Origin", alt_pos);
					DispatchSpawn(index);
				}
			}
		}
	}

	AidKitCount = GetConVarInt(ExtraAidKitsCount);

	return;
}

// ------------------------------------------------------------------------
// FindNearestFarthestEntity() - For medkit spawning
// ------------------------------------------------------------------------
FindNearestFarthestEntity(String: name[128], bool: near)
{
	new String: Classname[128];
	new max_entities = GetMaxEntities();

	new Float: start_pos[3];
	CalcStartPosition(start_pos);

	new Float: pos[3];
	new ent = -1;
	new sign = (near ? 1 : -1);
	new Float: distansce = 1000000.0*sign;

	for (new i = 0; i < max_entities; i++)
	{
		if (IsValidEntity (i))
		{
			GetEdictClassname(i, Classname, sizeof(Classname));
			if(StrEqual(Classname, name))
			{
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", pos);
				new Float: otherDist = CalcDistance(pos, start_pos);
				if (distansce * sign > otherDist*sign)
				{
					distansce = otherDist;
					ent = i;
				}
			}
		}
	}

	return ent;
}

// ------------------------------------------------------------------------
// Float: CalcDistance() - For medkit spawning
// ------------------------------------------------------------------------
Float: CalcDistance(Float: pos[3], Float: player_pos[3])
{
	return SquareRoot((pos[0] - player_pos[0]) * (pos[0] - player_pos[0]) + (pos[1] - player_pos[1]) * (pos[1] - player_pos[1]) + (pos[2] - player_pos[2]) * (pos[2] - player_pos[2]));
}

// ------------------------------------------------------------------------
// CalcStartPosition() - For medkit spawning
// ------------------------------------------------------------------------
CalcStartPosition(Float: array[3])
{
	decl String: map[128];
	GetCurrentMap(map, sizeof(map));
	decl index;

	if ((index = StrContains(map, "smalltown", false)) >= 0)
	{
		switch (map[index + 10])
		{
			case '1':
			{
				SetPos(array, -11748,-14701,-207);
			}
			case '2':
			{
				SetPos(array, -11047,-9055,-591);
			}
			case '3':
			{
				SetPos(array, -8476,-5564,-24);
			}
			case '4':
			{
				SetPos(array, -3091,103,328);
			}
			case '5':
			{
				SetPos(array, 1972,4651,-63);
			}
		}
	}
	else if ((index = StrContains(map, "airport", false)) >= 0)
	{
		switch (map[index + 8])
		{
			case '1':
			{
				SetPos(array, 6837,-667,768);
			}
			case '2':
			{
				SetPos(array, 5274,2621,48);
			}
			case '3':
			{
				SetPos(array, -5354,-3099,16);
			}
			case '4':
			{
				SetPos(array, -450,3531,296);
			}
			case '5':
			{
				SetPos(array, -6617,12040,152);
			}
		}
	}
	else if ((index = StrContains(map, "farm", false)) >= 0)
	{
		switch (map[index + 5])
		{
			case '1':
			{
				SetPos(array, -7956,-14987,301);
			}
			case '2':
			{
				SetPos(array, -6586,-6707,348);
			}
			case '3':
			{
				SetPos(array, -961,-10377,-63);
			}
			case '4':
			{
				SetPos(array, 7723,-11371,440);
			}
			case '5':
			{
				SetPos(array, 10459,-352,-28);
			}
		}
	}
	else if ((index = StrContains(map, "hospital", false)) >= 0)
	{
		switch (map[index + 9])
		{
			case '1':
			{
				SetPos(array, 1753,874,432);
			}
			case '2':
			{
				SetPos(array, 2955,3026,16);
			}
			case '3':
			{
				SetPos(array, 10937,4725,16);
			}
			case '4':
			{
				SetPos(array, 12407,12569,16);
			}
			case '5':
			{
				SetPos(array, 5383,8442,5536);
			}
		}
	}
}

// ------------------------------------------------------------------------
// SetPos() - For medkit spawning
// ------------------------------------------------------------------------
SetPos(Float: array[3], pos0, pos1, pos2)
{
	array[0] = float(pos0);
	array[1] = float(pos1);
	array[2] = float(pos2);
}

// ------------------------------------------------------------------------
// Event_FinaleVehicleLeaving() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_FinaleVehicleLeaving(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index == -1)
	{
		return;
	}

	new Float: Pos[3];
	GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", Pos);
	for (new i = 1; i <= MaxClients; i++)
	{
		// Connection + escape check
		if (!IsClientConnected(i))
		{
			continue;
		}
		if (!IsClientInGame(i))
		{
			continue;
		}
		if (GetClientTeam(i) != 2)
		{
			continue;
		}
		if (ClientUnableToEscape[i] != false)
		{
			continue;
		}

		TeleportEntity(i, Pos, NULL_VECTOR, NULL_VECTOR);
	}
}

// ------------------------------------------------------------------------
// Event_ReviveSuccess() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_ReviveSuccess(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "subject"));
	ClientUnableToEscape[Client] = false;
}

// ------------------------------------------------------------------------
// Event_SurvivorRescued() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_SurvivorRescued(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "victim"));
	ClientUnableToEscape[Client] = false;
}

// ------------------------------------------------------------------------
// Event_PlayerIncapacitated() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_PlayerIncapacitated(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ClientUnableToEscape[Client] = true;
}

// ------------------------------------------------------------------------
// Event_PlayerDeath() - Thanks to Mad_Dugan for this
// ------------------------------------------------------------------------
public Event_PlayerDeath(Handle: hEvent, const String: StrName[], bool: DontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ClientUnableToEscape[Client] = true;
}