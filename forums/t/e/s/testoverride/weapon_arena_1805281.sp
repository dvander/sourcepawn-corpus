/***************************************************************************************
* 
* 	DESCRIPTION
*		Enables "<insert your favourite weapon here> arena" which means that everyone will instantly be given specified weapon,
*		and infinite (optional) ammo for it. By default no other weapons will be visible on ground in game. As long as Weapon Arena is enabled
*		you can't change to any other weapon than the given one, grenades, knife or C4. Upon new round you will be given a new weapon, if you
*		lost your previous... 
* 
* 	VERSIONS and ChangeLog
* 
* 		0.0.0.1	*	Initial Beta Release
*
* 		0.0.0.2	*	Disabled Weapon Arena options in Arms Race mode. Fixed RTA functions. Added Translations.
* 
* 	KNOWN ISSUES
* 		None Yet
* 
* 	REQUESTS
* 		None Yet
*
****************************************************************************************


	C O M P I L E   O P T I O N S


***************************************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/***************************************************************************************


	P L U G I N   I N C L U D E S


***************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#undef REQUIRE_PLUGIN
#include <adminmenu>

/*****************************************************************


		P L U G I N   D E F I N E S


*****************************************************************/

#define 	PLUGIN_VERSION 		"0.0.0.2"

#define 	MAX_WEAPONS				35
#define		MAX_WEAPON_STRING		80
#define		MAX_WEAPON_SLOTS		6

#define 	HEGrenadeOffset 		11	
#define		IncenderyGrenadesOffset	14	

/***************************************************************************************


	G L O B A L   V A R S


***************************************************************************************/
// Voting Variables
new Handle:g_Cvar_Needed = INVALID_HANDLE;
new Handle:g_Cvar_MinPlayers = INVALID_HANDLE;
new Handle:g_Cvar_Interval = INVALID_HANDLE;
new Handle:g_Cvar_RTAPostVoteAction = INVALID_HANDLE;

new Handle:SERVER_GAME_TYPE= INVALID_HANDLE;
new Handle:SERVER_GAME_MODE = INVALID_HANDLE;

new bool:g_CanRTA = false;		
new bool:g_RTAAllowed = false;	
new g_Voters = 0;				
new g_Votes = 0;				
new g_VotesNeeded = 0;			
new bool:g_Voted[MAXPLAYERS+1] = {false, ...};
new bool:g_InChange = false;

// Plugin Internal Variables
new bool:IsWeaponArena = false;
new bool:IsZeusArena = false;
new bool:IsZeusArenaT = false;
new bool:IsZeusArenaCT = false;
new bool:IsArmsRace = false;
new bool:HookedPlayers = false;


// Console Variables
new bool:RemoveHostages = true;
new bool:RemoveBomb = true;
new bool:InvisibleWeapons = true;
new bool:RequireZeusKill = true;
new bool:UnlimitedAmmo = true;
new bool:RandomTeamWeapons = true;
new bool:RandomWeapons = true;
new bool:AllowVotes = true;

// Console Variables



// Console Variables: Runtime Optimizers
new WeaponArena = 0;
new WeaponArenaT = 0;
new WeaponArenaCT = 0;

// Timers


// Library Load Checks


// Game Variables


// Map Variables


// Client Variables
new HEGrenades[MAXPLAYERS+1];
new INCGrenades[MAXPLAYERS+1];


// M i s c
new Handle:WeaponArenaMenu = INVALID_HANDLE;

new temp1 = 0;

new const String:g_weapons[MAX_WEAPONS][] = {
	"",                    // weapon arena off
	"weapon_ak47",         // 1
	"weapon_aug",          // 2
	"weapon_bizon",        // 3
	"weapon_deagle",       // 4
	"weapon_elite",        // 5
	"weapon_famas",        // 6
	"weapon_fiveseven",    // 7
	"weapon_g3sg1",        // 8
	"weapon_galilar",      // 9
	"weapon_glock",        // 10
	"weapon_hegrenade",    // 11
	"weapon_hkp2000",      // 12
	"weapon_incgrenade",   // 13
	"weapon_knife",        // 14
	"weapon_m249",         // 15
	"weapon_m4a1",         // 16
	"weapon_mac10",        // 17
	"weapon_mag7",         // 18
	"weapon_molotov",      // 19
	"weapon_mp7",          // 20
	"weapon_mp9",          // 21
	"weapon_negev",        // 22
	"weapon_nova",         // 23
	"weapon_p250",         // 24
	"weapon_p90",          // 25
	"weapon_sawedoff",     // 26
	"weapon_scar20",       // 27
	"weapon_sg556",        // 28
	"weapon_ssg08",        // 29
	"weapon_taser",        // 30
	"weapon_tec9",         // 31
	"weapon_ump45",        // 32
	"weapon_xm1014",       // 33
	"weapon_awp"	       // 34
};

new const String:g_weapons1[MAX_WEAPONS][] = {
	"",             // weapon arena off
	"AK47",         // 1
	"AUG",          // 2
	"Bizon",        // 3
	"Deagle",       // 4
	"Elite",        // 5
	"Famas",        // 6
	"FiveSeven",    // 7
	"G3SG1",        // 8
	"Galilar",      // 9
	"Glock",        // 10
	"HeGrenade",    // 11
	"HKP2000",      // 12
	"Incgrenade",   // 13
	"Knife",        // 14
	"M249",         // 15
	"M4A1",         // 16
	"Mac10",        // 17
	"Mag7",         // 18
	"Molotov",      // 19
	"MP7",          // 20
	"MP9",          // 21
	"Negev",        // 22
	"Nova",         // 23
	"P250",         // 24
	"P90",          // 25
	"Sawedoff",     // 26
	"Scar20",       // 27
	"SG556",        // 28
	"SSG08",        // 29
	"Taser",        // 30
	"TEC9",         // 31
	"UMP45",        // 32
	"XM1014",       // 33
	"AWP"        	// 34
};

static ammoCounts[] = {
	0,		// weapon arena off
	30,		// AK47
	30,    	// AUG
	64,    	// Bizon
	7,    	// Deagle
	30,    	// Elite
	25,    	// Famas
	90,   	// FiveSeven
	20,    	// G3SG1
	35,    	// Galilar
	20,    	// Glock
	1,    	// HeGrenade
	13,    	// HKP2000
	1,   	// Incgrenade
	1,    	// Knife
	100,    // M249
	30,    	// M4A1
	30,    	// Mac10
	5,    	// Mag7
	1,    	// Molotov
	30,    	// MP7
	30,    	// MP9
	150,    // Negev
	8,    	// Nova
	13,    	// P250
	50,    	// P90
	7,    	// Sawedoff
	20,    	// Scar20
	30,    	// SG556
	10,    	// SSG08
	1,    	// Taser
	32,    	// TEC9
	25,    	// UMP45
	7,    	// XM1014
	10		// AWP
};


/***************************************************************************************


	F O R W A R D   P U B L I C S


***************************************************************************************/
public Plugin:myinfo = 
{
	name = "Weapon Arena",
	author = "testoverride",
	description = "CS:GO Weapon Arena",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	HookConVarChange((CreateConVar("sm_weaponarena_removebomb", "1", 
	"Should the bomb be stripped during the weapon arena?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnRemoveBombChanged);
	
	HookConVarChange((CreateConVar("sm_weaponarena_removehostages", "1", 
	"Should the hostages be removed during the weapon arena?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnRemoveHostagesChanged);

	HookConVarChange((CreateConVar("sm_weaponarena_invisibleweapons", "1", 
	"Should the ground Weapons be removed during the weapon arena?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnInvisibleWeaponsChanged);

	HookConVarChange((CreateConVar("sm_weaponarena_requirezeuskill", "1", 
	"Should a kill be rqeuired to give taser in Zeus Arena?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnRequireZeusKillChanged);
	
	HookConVarChange((CreateConVar("sm_weaponarena_unlimitedammo", "1", 
	"Should a players have unlimited ammo in the Weapon Arena?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnUnlimitedAmmoChanged);

	HookConVarChange((CreateConVar("sm_weaponarena_randomweapons", "1", 
	"Should a Random Weapon Arena be enabled?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnRandomWeaponsChanged);
	
	HookConVarChange((CreateConVar("sm_weaponarena_randomteamweapons", "1", 
	"Should a Random Weapon Arena be enabled?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnRandomTeamWeaponsChanged);
	
	HookConVarChange((CreateConVar("sm_weaponarena_allowvotes", "1", 
	"Should a Random Weapon Arena be enabled?\n0 = NO\n1 = YES", FCVAR_NONE, true, 0.0, true, 1.0)), OnAllowVotesChanged);

	g_Cvar_Needed = CreateConVar("sm_Weaponarena_needed", "0.60",
	"Percentage of players needed to RockTheMode (Def 60%)", 0, true, 0.05, true, 1.0);

	g_Cvar_MinPlayers = CreateConVar("sm_weaponarena_minplayers", "1",
	"Number of players required before RTA will be enabled.", 0, true, 0.0, true, float(MAXPLAYERS));
	
	g_Cvar_Interval = CreateConVar("sm_weaponarena_interval", "240.0",
	"Time (in seconds) after a failed RTA before another can be held", 0, true, 0.00);
	
	g_Cvar_RTAPostVoteAction = CreateConVar("sm_weaponarena_postvoteaction", "0",
	"What to do with RTA's after a vote has completed. 0 - Allow, 1 - Deny", _, true, 0.0, true, 1.0);
	
	HookEvent("player_death", eventPlayerDeath);
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("hegrenade_detonate", HEboomEvent);
	HookEvent("molotov_detonate", HEboomEvent);
	HookEvent("weapon_fire", eventGiveAmmo);
	HookEvent("round_start", eventRoundStart);
	HookEvent("round_end", eventRoundEnd);

	RegAdminCmd("sm_weaponarena", Cmd_WeaponArena, ADMFLAG_GENERIC, "Enables Weapon Arena");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	SERVER_GAME_TYPE = FindConVar("game_type");
	SERVER_GAME_MODE = FindConVar("game_mode");

	new String:sGameDir[32];

	GetGameFolderName(sGameDir, sizeof(sGameDir));
	
	if (StrContains(sGameDir, "csgo", false) == -1)
	{
		SetFailState("Weapon Arena is for CS:GO only");
	}

	LoadTranslations("weapon_arena.phrases");

	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnMapStart()
{
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_InChange = false;
	g_RTAAllowed = true;

	if(GetConVarInt(SERVER_GAME_TYPE) == 1 && GetConVarInt(SERVER_GAME_MODE) == 0)
	{
		IsArmsRace = true;
		g_CanRTA = false;		
	} else
	{
		IsArmsRace = false;
		g_CanRTA = true;	
	}

	ResetArena();
}

public OnMapEnd()
{
	g_CanRTA = false;	
	g_RTAAllowed = false;

	ResetArena();
}
public OnClientPutInServer(client)
{
	if (IsWeaponArena)
	{
		if (HookedPlayers)
		{
			SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
			SDKHook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
			SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
			SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
		}
	}
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed));
	
	return;
}

public OnClientDisconnect(client)
{
	if (IsWeaponArena)
	{
		if(IsClientInGame(client))
		{
			if (HookedPlayers)
			{
				SDKUnhook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKUnhook(client, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
				SDKUnhook(client, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
	}

	if(IsFakeClient(client))
	return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	
	g_VotesNeeded = RoundToFloor(float(g_Voters) * GetConVarFloat(g_Cvar_Needed));
	
	if (!g_CanRTA)
	{
		return;	
	}
	
	if (g_Votes && g_Voters && g_Votes >= g_VotesNeeded && g_RTAAllowed ) 
	{
		if (GetConVarInt(g_Cvar_RTAPostVoteAction) == 1)
		{
			return;
		}
		
		StartRTA();
	}	
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		WeaponArenaMenu = INVALID_HANDLE;
	}
}
 
public OnAdminMenuReady(Handle:topmenu)
{

	/* Block us from being called twice */
	if (topmenu == WeaponArenaMenu)
	{
		return;
	}

	WeaponArenaMenu = topmenu;	
	AttachWeaponArena_Categories();
	AttachWeaponArena_Items();
}
/**************************************************************************************


	T I M E R   F U N C T I O N S


**************************************************************************************/
public Action:Timer_RemoveHostages(Handle:timer)
{
	new iEnt = -1;
	while((iEnt = FindEntityByClassname(iEnt, "hostage_entity")) != -1) //Find the hostages themselves and destroy them
	{
		AcceptEntityInput(iEnt, "kill");
	}
}

public Action:RemoveGroundWeapons(Handle:timer)
{
	new maxEntities = GetMaxEntities();
	decl String:class[20];
	
	for (new i = MaxClients + 1; i < maxEntities; i++)
	{
		if (IsValidEdict(i))
		{
			GetEdictClassname(i, class, sizeof(class));
			if ((StrContains(class, "weapon_") != -1) || (StrContains(class, "item_") != -1))
			{
				if(RandomTeamWeapons)
				{
					if (StrEqual(class, "weapon_knife") || StrEqual(class, g_weapons[WeaponArenaCT])  || StrEqual(class, g_weapons[WeaponArenaT])) 
					{
						continue;
					} else 				
					if (StrEqual(class, "weapon_c4") && !RemoveBomb)
					{
						continue;
					} else 
					{
					AcceptEntityInput(i, "Kill");
					}
				}

				if (!RandomTeamWeapons)
				{
					if (StrEqual(class, "weapon_knife") || StrEqual(class, g_weapons[WeaponArena])) 
					{
						continue;
					} else
					if (StrEqual(class, "weapon_c4") && !RemoveBomb)
					{
						continue;
					} else 
					{
					AcceptEntityInput(i, "Kill");
					}
				}
			}
		}
	}
}

/**************************************************************************************

	C O M M A N D S

**************************************************************************************/
ResetArena()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (HookedPlayers)
			{
				SDKUnhook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}

			if (HookedPlayers)
			{
			SDKUnhook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
			SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
			SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
			SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
	
		}
	}
	
	HookedPlayers = false;
	IsWeaponArena = false;
	IsZeusArena = false;
	IsZeusArenaT = false;
	IsZeusArenaCT = false;
	WeaponArena = 0;
	WeaponArenaT = 0;
	WeaponArenaCT = 0;
}


RemovePlayerWeapons(client)
{
	new weapon_index = -1;
	new iEnt = -1;

	if (RemoveBomb)
	{
		while((iEnt = FindEntityByClassname(iEnt, "func_bomb_target")) != -1) //Find bombsites
		{
			AcceptEntityInput(iEnt,"kill"); //Destroy the entity
		}
	}
	
	for (new slot = 0; slot < MAX_WEAPON_SLOTS; slot++)
	{
		while ((weapon_index = GetPlayerWeaponSlot(client, slot)) != -1)
		{
			if (IsValidEntity(weapon_index))
			{
				if (weapon_index == 4 && !RemoveBomb)
				{
					return;
				}
				
				RemovePlayerItem(client, weapon_index);
				AcceptEntityInput(weapon_index, "kill");
			}
		}
	}
}

GetClientHEGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, HEGrenadeOffset);
}

GetClientIncendaryGrenades(client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", _, IncenderyGrenadesOffset);
}

public Action:OnWeaponDrop(client, weapon)
{
	if (IsZeusArena)
	{
		if (!IsValidEntity(weapon))
		{
			return Plugin_Continue;
		}
		
		AcceptEntityInput(weapon, "kill");

		if (!RequireZeusKill)
		{
			GivePlayerItem(client, g_weapons[WeaponArena]);
		}
	}

	if (IsZeusArenaCT)
	{
		if (!IsValidEntity(weapon))
		{
			return Plugin_Continue;
		}
		
		AcceptEntityInput(weapon, "kill");

		if (!RequireZeusKill)
		{
			GivePlayerItem(client, g_weapons[WeaponArenaCT]);
		}
	}

	if (IsZeusArenaT)
	{
		if (!IsValidEntity(weapon))
		{
			return Plugin_Continue;
		}
		
		AcceptEntityInput(weapon, "kill");

		if (!RequireZeusKill)
		{
			GivePlayerItem(client, g_weapons[WeaponArenaT]);
		}
	}

	return Plugin_Continue;
}

public Action:Cmd_WeaponArena(client, args)
{

	if(IsArmsRace)
	{
		ReplyToCommand(client, "%t", "Arms Race");
		
		return Plugin_Handled;
	}

	if (args != 1)
	{
		ReplyToCommand(client, "%t", "Usage");
		
		return Plugin_Handled;
	}
	
	decl String:arg1[4];
	arg1[0] = '\0';
	temp1 = 0;

	GetCmdArg(1, arg1, sizeof(arg1));
	temp1 = StringToInt(arg1);

	if (temp1 > MAX_WEAPONS)
	{
		ReplyToCommand(client, "%t", "Usage");
		return Plugin_Handled;
	}

	if (temp1 == 0)
	{
		PrintToChatAll("[SM] %t", "Weapon Arena Disabled");
		ResetArena();
		return Plugin_Handled;
	}

	IsWeaponArena = true;	

	if(RandomTeamWeapons)
	{
		WeaponArenaCT = GetRandomInt(1, 34);
		WeaponArenaT = GetRandomInt(1, 34);
		
		PrintToChatAll("[SM] %t", "Terrorist Arena Enabled", g_weapons1[WeaponArenaT]);
		PrintToChatAll("[SM] %t", "Counter-Terrorist Arena Enabled", g_weapons1[WeaponArenaCT]);

		switch(WeaponArenaT)
		{
			case 30:
			{
				IsZeusArenaT = true;
				IsZeusArena = true;
			}
			default:
			{
				IsZeusArenaT = false;
				IsZeusArena = false;
			}
		}

		switch(WeaponArenaCT)
		{
			case 30:
			{
				IsZeusArenaCT = true;
				IsZeusArena = true;
			}
			default:
			{
				IsZeusArenaCT = false;
				IsZeusArena = false;
			}
		}
	}
	else if(!RandomTeamWeapons && RandomWeapons)
	{
		WeaponArena = GetRandomInt(1, 34);
		PrintToChatAll("[SM] %t", "Random Arena Enabled", g_weapons1[WeaponArena]);

		switch(temp1)
		{
			case 30:
			{
				IsZeusArenaCT = false;
				IsZeusArenaT = false;
				IsZeusArena = true;
			}
			default:
			{
				IsZeusArenaCT = false;
				IsZeusArenaT = false;
				IsZeusArena = false;
			}
		}
	}
	else
	{
		WeaponArena = StringToInt(arg1);
		PrintToChatAll("[SM] %t", "Random Arena Enabled", g_weapons1[WeaponArena]);

		switch(temp1)
		{
			case 30:
			{
				IsZeusArenaCT = false;
				IsZeusArenaT = false;
				IsZeusArena = true;
			}
			default:
			{
				IsZeusArenaCT = false;
				IsZeusArenaT = false;
				IsZeusArena = false;
			}
		}
	}
	
	if (InvisibleWeapons)
	{
		CreateTimer(0.1, RemoveGroundWeapons);
	}

	if (RemoveHostages)
	{
		CreateTimer(0.5, Timer_RemoveHostages);
	}

	if (!HookedPlayers)
	{
		HookPlayers(true);
		
		HookedPlayers = true;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		RemovePlayerWeapons(i);
		
		if (RandomTeamWeapons)
		{
			switch(GetClientTeam(i))
			{
				case CS_TEAM_T:
				{
					switch(WeaponArenaT)
					{
						case 14:
						{
							GivePlayerItem(i, g_weapons[WeaponArenaT]);
						}
						default:
						{
							GivePlayerItem(i, "weapon_knife");					
							GivePlayerItem(i, g_weapons[WeaponArenaT]);
						}
					}
				}
				case CS_TEAM_CT:
				{
					switch(WeaponArenaCT)
					{
						case 14:
						{
							GivePlayerItem(i, g_weapons[WeaponArenaCT]);
						}
						default:
						{
							GivePlayerItem(i, "weapon_knife");					
							GivePlayerItem(i, g_weapons[WeaponArenaCT]);
						}
					}
				}
			}
		}

		if (!RandomTeamWeapons)
		{
			switch(WeaponArena)
			{
				case 14:
				{
					GivePlayerItem(i, g_weapons[WeaponArena]);
				}
				default:
				{
					GivePlayerItem(i, "weapon_knife");					
					GivePlayerItem(i, g_weapons[WeaponArena]);
				}
			}
		}
	}

	return Plugin_Handled;
}

public HookPlayers(bool:mode)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (mode)
			{
				SDKHook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKHook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
				SDKHook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKHook(i, SDKHook_WeaponDrop, OnWeaponDrop);				
			}
			else
			{
				SDKUnhook(i, SDKHook_WeaponEquip, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponCanUse, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponCanSwitchTo, OnWeaponCanUse);
				SDKUnhook(i, SDKHook_WeaponDrop, OnWeaponDrop);
			}
		}
	}
}

public Action:OnWeaponCanUse(client, weapon)
{
	if (!IsWeaponArena)
	{
		return Plugin_Continue;
	}
	
	decl String:sWeapon[32];
	sWeapon[0] = '\0';

	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if (!RandomTeamWeapons)
	{
		if (!RemoveBomb)
		{
			if(StrEqual(sWeapon, g_weapons[WeaponArena], false) || StrEqual(sWeapon, "weapon_knife", false) || StrEqual(sWeapon, "weapon_c4", false))
			{
				return Plugin_Continue;
			}
		} 
		else if (RemoveBomb)
		{
			if(StrEqual(sWeapon, g_weapons[WeaponArena], false) || StrEqual(sWeapon, "weapon_knife", false))
			{
				return Plugin_Continue;
			}
		}	
	}

	if (RandomTeamWeapons)
	{
		switch(GetClientTeam(client))
		{
			case CS_TEAM_T:
			{
				if (!RemoveBomb)
				{
					if(StrEqual(sWeapon, g_weapons[WeaponArenaT], false) || StrEqual(sWeapon, "weapon_knife", false) || StrEqual(sWeapon, "weapon_c4", false))
					{
						return Plugin_Continue;
					}
				} 
				else if (RemoveBomb)
				{
					if(StrEqual(sWeapon, g_weapons[WeaponArenaT], false) || StrEqual(sWeapon, "weapon_knife", false))
					{
						return Plugin_Continue;
					}
				}	
			}
			case CS_TEAM_CT:
			{
				if(StrEqual(sWeapon, g_weapons[WeaponArenaCT], false) || StrEqual(sWeapon, "weapon_knife", false))
				{
					return Plugin_Continue;
				}
			}
		}
	}
	
	return Plugin_Handled;
}

/**************************************************************************************

	E V E N T S

**************************************************************************************/
public eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsWeaponArena)
	{
		return;
	}

	if (IsClientInGame(client) && IsPlayerAlive(client))
	{	
		RemovePlayerWeapons(client);
		
		if (RandomTeamWeapons)
		{
			switch(GetClientTeam(client))
			{
				case CS_TEAM_T:
				{
					switch(WeaponArenaT)
					{
						case 14:
						{
							GivePlayerItem(client, g_weapons[WeaponArenaT]);
						}
						default:
						{
							GivePlayerItem(client, "weapon_knife");					
							GivePlayerItem(client, g_weapons[WeaponArenaT]);
						}
					}			
				}
				case CS_TEAM_CT:
				{
					switch(WeaponArenaCT)
					{
						case 14:
						{
							GivePlayerItem(client, g_weapons[WeaponArenaCT]);
						}
						default:
						{
							GivePlayerItem(client, "weapon_knife");					
							GivePlayerItem(client, g_weapons[WeaponArenaCT]);
						}
					}			
				}
			}
		}
		
		if (!RandomTeamWeapons)
		{
			switch(WeaponArena)
			{
				case 14:
				{
					GivePlayerItem(client, g_weapons[WeaponArena]);
				}
				default:
				{
					GivePlayerItem(client, "weapon_knife");					
					GivePlayerItem(client, g_weapons[WeaponArena]);
				}
			}			
		}
	}
}

public eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!IsZeusArena || killer < 1 || killer > MaxClients || !RequireZeusKill)
	{
		return;
	}
	
	decl String:weapon[MAX_WEAPON_STRING];
	weapon[0] = '\0';

	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (StrEqual(weapon, "taser", false) || StrEqual(weapon, "knife", false))
	{
		if (IsZeusArenaT)
		{
			GivePlayerItem(killer, g_weapons[WeaponArenaT]);
		} else
		if (IsZeusArenaCT)
		{
			GivePlayerItem(killer, g_weapons[WeaponArenaCT]);
		} else
		{
			GivePlayerItem(killer, g_weapons[WeaponArena]);
		}
	}
}

public Action:HEboomEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(IsWeaponArena)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if(IsPlayerAlive(client))
		{
			HEGrenades[client] = GetClientHEGrenades(client);
			INCGrenades[client] = GetClientIncendaryGrenades(client);
			
			if (RandomTeamWeapons)
			{
				switch(GetClientTeam(client))
				{
					case CS_TEAM_T:
					{
						switch(WeaponArenaT)
						{
							case 11, 13, 19:
							{
								if (HEGrenades[client] == 0 && INCGrenades[client] == 0 )
								{
									GivePlayerItem(client, g_weapons[WeaponArenaT]);
								}
							}
						}
					}
					case CS_TEAM_CT:
					{
						switch(WeaponArenaCT)
						{
							case 11, 13, 19:
							{
								if (HEGrenades[client] == 0 && INCGrenades[client] == 0 )
								{
									GivePlayerItem(client, g_weapons[WeaponArenaCT]);
								}
							}
						}
					}
				}
			}
			
			if (!RandomTeamWeapons)
			{
				switch(WeaponArena)
				{
					case 11, 13, 19:
					{
						if (HEGrenades[client] == 0 && INCGrenades[client] == 0 )
						{
							GivePlayerItem(client, g_weapons[WeaponArena]);
						}
					}
				}
			}
		}
	}
}

public eventGiveAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{

	if(UnlimitedAmmo && IsWeaponArena)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new String:weapons[64];
		new String:Pri[64];
		new String:Sec[64];
	
		GetEventString(event, "weapon", weapons, sizeof(weapons));
		
		if(IsPlayerAlive(client))
		{
			new primary = GetPlayerWeaponSlot(client, 0);
			new secondary = GetPlayerWeaponSlot(client, 1);
			new weapon;
			
			if (primary != -1)
			{
				GetEdictClassname(primary, Pri, sizeof(Pri));
				ReplaceString(Pri, sizeof(Pri), "weapon_", "");
			}
			if (secondary != -1)
			{
				GetEdictClassname(secondary, Sec, sizeof(Sec));
				ReplaceString(Sec, sizeof(Sec), "weapon_", "");
			}
			
			if (StrEqual(weapons, Pri)) weapon = primary;
			else if (StrEqual(weapons, Sec)) weapon = secondary;
			else return;

			
			new clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
			new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
			
			if (clip <= 1)
			{		
				if (ammo > 0)
				{
					if (RandomTeamWeapons)
					{
						switch(GetClientTeam(client))
						{
							case CS_TEAM_T:
							{
								SetEntProp(weapon, Prop_Send, "m_iClip1", ammoCounts[WeaponArenaT]);
							}
							case CS_TEAM_CT:
							{
								SetEntProp(weapon, Prop_Send, "m_iClip1", ammoCounts[WeaponArenaCT]);
							}
						}						
					}
					
					if (!RandomTeamWeapons)
					{
						SetEntProp(weapon, Prop_Send, "m_iClip1", ammoCounts[WeaponArena]);
					}
				}
			}
		}
	}
}

public Action:eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsArmsRace)
	{
		PrintToChatAll("[SM] %t","Arms Race");
	}
	
	if (!IsWeaponArena && !AllowVotes && !IsArmsRace)
	{
		PrintToChatAll("[SM] %t", "Weapon Arena Votes Disabled");
	}

	if (!IsWeaponArena && AllowVotes && !IsArmsRace)
	{
		PrintToChatAll("[SM] %t", "Weapon Arena Disabled");
	}
	if (IsWeaponArena)
	{
		new iEnt = -1;
		while((iEnt = FindEntityByClassname(iEnt, "func_buyzone")) != -1) //Find the buy zones and destroy them
		{
			AcceptEntityInput(iEnt, "kill");
		}

		if (RemoveHostages)
		{
			CreateTimer(0.2, Timer_RemoveHostages);
		}

		if (InvisibleWeapons)
		{
			CreateTimer(0.1, RemoveGroundWeapons);
		}

		if(RandomTeamWeapons)
		{
			PrintToChatAll("[SM] %t", "Terrorist Arena Enabled", g_weapons1[WeaponArenaT]);
			PrintToChatAll("[SM] %t", "Counter-Terrorist Arena Enabled", g_weapons1[WeaponArenaCT]);
		}

		if(RandomWeapons && !RandomTeamWeapons)
		{
		PrintToChatAll("[SM] %t", "Random Arena Enabled", g_weapons1[WeaponArena]);
		}

		if(!RandomTeamWeapons && !RandomWeapons)
		{
		PrintToChatAll("[SM] %t", "Random Arena Enabled", g_weapons1[WeaponArena]);
		}
	}
}

public Action:eventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsWeaponArena && RandomWeapons && !RandomTeamWeapons)
	{
		WeaponArena = GetRandomInt(1, 34);

		switch(WeaponArena)
		{
			case 30:
			{
				IsZeusArena = true;
			}
			default:
			{
				IsZeusArena = false;
			}
		}
	}

	if (IsWeaponArena && !RandomWeapons && !RandomTeamWeapons)
	{
		switch(WeaponArena)
		{
			case 30:
			{
				IsZeusArena = true;
			}
			default:
			{
				IsZeusArena = false;
			}
		}
	}
	
	if (IsWeaponArena && RandomTeamWeapons)
	{
		WeaponArenaT = GetRandomInt(1, 34);
		WeaponArenaCT = GetRandomInt(1, 34);

		switch(WeaponArenaT)
		{
			case 30:
			{
				IsZeusArenaT = true;
				IsZeusArena = true;
			}
			default:
			{
				IsZeusArenaT = false;
				IsZeusArena = false;
			}
		}

		switch(WeaponArenaCT)
		{
			case 30:
			{
				IsZeusArenaCT = true;
				IsZeusArena = true;
			}
			default:
			{
				IsZeusArenaCT = false;
				IsZeusArena = false;
			}
		}
	}
}

/**************************************************************************************

	A D M I N   M E N U 

**************************************************************************************/

new TopMenuObject:Arena_Weapons;
new TopMenuObject:Arena_Toggles;
new TopMenuObject:Arena_Pistols;
new TopMenuObject:WAaug;
new TopMenuObject:WAak;
new TopMenuObject:WAbizon;
new TopMenuObject:WAdeagle;
new TopMenuObject:WAelite;
new TopMenuObject:WAfamas;
new TopMenuObject:WAfiveseven;
new TopMenuObject:WAg3sg1;
new TopMenuObject:WAgalilar;
new TopMenuObject:WAglock;
new TopMenuObject:WAhe;
new TopMenuObject:WAhkp2000;
new TopMenuObject:WAinc;
new TopMenuObject:WAknife;
new TopMenuObject:WAm249;
new TopMenuObject:WAm4a1;
new TopMenuObject:WAmac10;
new TopMenuObject:WAmag7;
new TopMenuObject:WAmolotov;
new TopMenuObject:WAmp7;
new TopMenuObject:WAmp9;
new TopMenuObject:WAnegev;
new TopMenuObject:WAnova;
new TopMenuObject:WAp250;
new TopMenuObject:WAp90;
new TopMenuObject:WAsawedoff;
new TopMenuObject:WAscar20;
new TopMenuObject:WAsg556;
new TopMenuObject:WAssg08;
new TopMenuObject:WAtaser;
new TopMenuObject:WAtec9;
new TopMenuObject:WAump45;
new TopMenuObject:WAxm1014;
new TopMenuObject:WAawp;
new TopMenuObject:WAammo;
new TopMenuObject:WArandom;
new TopMenuObject:WArandomT;
new TopMenuObject:WAarena;
new TopMenuObject:WAbomb;
new TopMenuObject:WAallowvotes;
new TopMenuObject:WAinvisible;
new TopMenuObject:WAhostages;
new TopMenuObject:WAzeuskill;
 
AttachWeaponArena_Categories()
{
	Arena_Weapons = AddToTopMenu(WeaponArenaMenu,
		"Arena_Weapons",
		TopMenuObject_Category,
		WeaponArena_Categories,
		INVALID_TOPMENUOBJECT);

	Arena_Toggles =	AddToTopMenu(WeaponArenaMenu,
		"Arena_Toggles",
		TopMenuObject_Category,
		WeaponArena_Categories,
		INVALID_TOPMENUOBJECT);
}

AttachWeaponArena_Items()
{	/* If the category is third party, it will have its own unique name. */
	new TopMenuObject:Arena_Item = FindTopMenuCategory(WeaponArenaMenu, "Arena_Weapons");
 	new TopMenuObject:Arena_Toggle = FindTopMenuCategory(WeaponArenaMenu, "Arena_Toggles");
	
	if (Arena_Item == INVALID_TOPMENUOBJECT)
	{
		/* Error! */
		return;
	} else
	if (Arena_Toggle == INVALID_TOPMENUOBJECT)
	{
		/* Error! */
		return;
	}

	WAak = AddToTopMenu(WeaponArenaMenu, 
		"AK_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"AK_Arena",
		ADMFLAG_SLAY);

	WAaug = AddToTopMenu(WeaponArenaMenu, 
		"Aug_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Aug_Arena",
		ADMFLAG_SLAY);

	WAbizon = AddToTopMenu(WeaponArenaMenu, 
		"Bizon_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Bizon_Arena",
		ADMFLAG_SLAY);

	WAdeagle = AddToTopMenu(WeaponArenaMenu, 
		"Deagle_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Deagle_Arena",
		ADMFLAG_SLAY);

	WAelite = AddToTopMenu(WeaponArenaMenu, 
		"Elite_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Elite_Arena",
		ADMFLAG_SLAY);

	WAfamas = AddToTopMenu(WeaponArenaMenu, 
		"Famas_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Famas_Arena",
		ADMFLAG_SLAY);

	WAfiveseven = AddToTopMenu(WeaponArenaMenu, 
		"FiveSeven_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"FiveSeven_Arena",
		ADMFLAG_SLAY);

	WAg3sg1 = AddToTopMenu(WeaponArenaMenu, 
		"G3SG1_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"G3SG1_Arena",
		ADMFLAG_SLAY);

	WAgalilar = AddToTopMenu(WeaponArenaMenu, 
		"Galilar_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Galilar_Arena",
		ADMFLAG_SLAY);

	WAglock = AddToTopMenu(WeaponArenaMenu, 
		"Glock_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Glock_Arena",
		ADMFLAG_SLAY);

	WAhe = AddToTopMenu(WeaponArenaMenu, 
		"HE_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"HE_Arena",
		ADMFLAG_SLAY);

	WAhkp2000 = AddToTopMenu(WeaponArenaMenu, 
		"HKP2000_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"HKP2000_Arena",
		ADMFLAG_SLAY);

	WAinc = AddToTopMenu(WeaponArenaMenu, 
		"Inc_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Inc_Arena",
		ADMFLAG_SLAY);

	WAknife = AddToTopMenu(WeaponArenaMenu, 
		"Knife_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Knife_Arena",
		ADMFLAG_SLAY);

	WAm249 = AddToTopMenu(WeaponArenaMenu, 
		"M249_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"M249_Arena",
		ADMFLAG_SLAY);

	WAm4a1 = AddToTopMenu(WeaponArenaMenu, 
		"M4A1_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"M4A1_Arena",
		ADMFLAG_SLAY);

	WAmac10 = AddToTopMenu(WeaponArenaMenu, 
		"MAC10_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"MAC10_Arena",
		ADMFLAG_SLAY);

	WAmag7 = AddToTopMenu(WeaponArenaMenu, 
		"MAG7_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"MAG7_Arena",
		ADMFLAG_SLAY);

	WAmolotov = AddToTopMenu(WeaponArenaMenu, 
		"Molotov_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Molotov_Arena",
		ADMFLAG_SLAY);

	WAmp7 = AddToTopMenu(WeaponArenaMenu, 
		"MP7_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"MP7_Arena",
		ADMFLAG_SLAY);

	WAmp9 = AddToTopMenu(WeaponArenaMenu, 
		"MP9_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"MP9_Arena",
		ADMFLAG_SLAY);

	WAnegev = AddToTopMenu(WeaponArenaMenu, 
		"Negev_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Negev_Arena",
		ADMFLAG_SLAY);

	WAnova = AddToTopMenu(WeaponArenaMenu, 
		"Nova_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Nova_Arena",
		ADMFLAG_SLAY);

	WAp250 = AddToTopMenu(WeaponArenaMenu, 
		"P250_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"P250_Arena",
		ADMFLAG_SLAY);

	WAp90 = AddToTopMenu(WeaponArenaMenu, 
		"P90_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"P90_Arena",
		ADMFLAG_SLAY);

	WAsawedoff = AddToTopMenu(WeaponArenaMenu, 
		"SawedOff_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"SawedOff_Arena",
		ADMFLAG_SLAY);

	WAscar20 = AddToTopMenu(WeaponArenaMenu, 
		"Scar20_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Scar20_Arena",
		ADMFLAG_SLAY);

	WAsg556 = AddToTopMenu(WeaponArenaMenu, 
		"SG556_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"SG556_Arena",
		ADMFLAG_SLAY);

	WAssg08 = AddToTopMenu(WeaponArenaMenu, 
		"SSG08_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"SSG08_Arena",
		ADMFLAG_SLAY);

	WAtaser = AddToTopMenu(WeaponArenaMenu, 
		"Taser_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"Taser_Arena",
		ADMFLAG_SLAY);

	WAtec9 = AddToTopMenu(WeaponArenaMenu, 
		"TEC9_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"TEC9_Arena",
		ADMFLAG_SLAY);

	WAump45 = AddToTopMenu(WeaponArenaMenu, 
		"UMP45_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"UMP45_Arena",
		ADMFLAG_SLAY);

	WAxm1014 = AddToTopMenu(WeaponArenaMenu, 
		"XM1014_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"XM1014_Arena",
		ADMFLAG_SLAY);

	WAawp = AddToTopMenu(WeaponArenaMenu, 
		"AWP_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Item,
		"AWP_Arena",
		ADMFLAG_SLAY);

	WAammo = AddToTopMenu(WeaponArenaMenu, 
		"Unlimited_Ammo",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"Unlimited_Ammo",
		ADMFLAG_SLAY);

	WArandom = AddToTopMenu(WeaponArenaMenu, 
		"Random_Weapons",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"Random_Weapons",
		ADMFLAG_SLAY);

	WArandomT = AddToTopMenu(WeaponArenaMenu, 
		"Random_Team_Weapons",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"Random_Team_Weapons",
		ADMFLAG_SLAY);

	WAarena = AddToTopMenu(WeaponArenaMenu, 
		"Regular_Arena",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"Regular_Arena",
		ADMFLAG_SLAY);

	WAbomb = AddToTopMenu(WeaponArenaMenu, 
		"Remove_Bomb",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"Remove_Bomb",
		ADMFLAG_SLAY);

	WAallowvotes = AddToTopMenu(WeaponArenaMenu, 
		"WAAllow_Votes",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"WAAllow_Votes",
		ADMFLAG_SLAY);

	WAinvisible = AddToTopMenu(WeaponArenaMenu, 
		"Remove_Weapons",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"Remove_Weapons",
		ADMFLAG_SLAY);

	WAhostages = AddToTopMenu(WeaponArenaMenu, 
		"Remove_Hostages",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"Remove_Hostages",
		ADMFLAG_SLAY);

	WAzeuskill = AddToTopMenu(WeaponArenaMenu, 
		"Require_Zeus_Kill",
		TopMenuObject_Item,
		WeaponArena_Items,
		Arena_Toggle,
		"Require_Zeus_Kill",
		ADMFLAG_SLAY);
}

public WeaponArena_Categories(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		if (object_id == Arena_Weapons)
		{
			Format(buffer, maxlength, "Arena Commands:");
		}
		else if (object_id == Arena_Toggles)
		{
			Format(buffer, maxlength, "Arena Toggles:");
		}
		else if (object_id == Arena_Pistols)
		{
			Format(buffer, maxlength, "Arena Pistols:");
		}
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == Arena_Weapons)
		{
			Format(buffer, maxlength, "Arena Commands");
		}
		else if (object_id == Arena_Toggles)
		{
			Format(buffer, maxlength, "Arena Toggles");
		}
		else if (object_id == Arena_Pistols)
		{
			Format(buffer, maxlength, "Arena Pistols");
		}
	}
}

public WeaponArena_Items(Handle:topmenu, 
			TopMenuAction:action,
			TopMenuObject:object_id,
			param,
			String:buffer[],
			maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == WAak)
		{
			Format(buffer, maxlength, "AK47 Arena");
		}
		else if (object_id == WAaug)
		{
			Format(buffer, maxlength, "Aug Arena");
		}
		else if (object_id == WAbizon)
		{
			Format(buffer, maxlength, "Bizon Arena");
		}
		else if (object_id == WAdeagle)
		{
			Format(buffer, maxlength, "Deagle Arena");
		}
		else if (object_id == WAelite)
		{
			Format(buffer, maxlength, "Elite Arena");
		}
		else if (object_id == WAfamas)
		{
			Format(buffer, maxlength, "Famas Arena");
		}
		else if (object_id == WAfiveseven)
		{
			Format(buffer, maxlength, "FiveSeven Arena");
		}
		else if (object_id == WAg3sg1)
		{
			Format(buffer, maxlength, "G3SG1 Arena");
		}
		else if (object_id == WAgalilar)
		{
			Format(buffer, maxlength, "Galilar Arena");
		}
		else if (object_id == WAglock)
		{
			Format(buffer, maxlength, "Glock Arena");
		}
		else if (object_id == WAhe)
		{
			Format(buffer, maxlength, "HE Arena");
		}
		else if (object_id == WAhkp2000)
		{
			Format(buffer, maxlength, "HKP2000 Arena");
		}
		else if (object_id == WAinc)
		{
			Format(buffer, maxlength, "Incendeary Arena");
		}
		else if (object_id == WAknife)
		{
			Format(buffer, maxlength, "Knife Arena");
		}
		else if (object_id == WAm249)
		{
			Format(buffer, maxlength, "M249 Arena");
		}
		else if (object_id == WAm4a1)
		{
			Format(buffer, maxlength, "M4A1 Arena");
		}
		else if (object_id == WAmac10)
		{
			Format(buffer, maxlength, "MAC10 Arena");
		}
		else if (object_id == WAmag7)
		{
			Format(buffer, maxlength, "MAG7 Arena");
		}
		else if (object_id == WAmolotov)
		{
			Format(buffer, maxlength, "Molotov Arena");
		}
		else if (object_id == WAmp7)
		{
			Format(buffer, maxlength, "MP7 Arena");
		}
		else if (object_id == WAmp9)
		{
			Format(buffer, maxlength, "MP9 Arena");
		}
		else if (object_id == WAnegev)
		{
			Format(buffer, maxlength, "Negev Arena");
		}
		else if (object_id == WAnova)
		{
			Format(buffer, maxlength, "Nova Arena");
		}
		else if (object_id == WAp250)
		{
			Format(buffer, maxlength, "P250 Arena");
		}
		else if (object_id == WAp90)
		{
			Format(buffer, maxlength, "P90 Arena");
		}
		else if (object_id == WAsawedoff)
		{
			Format(buffer, maxlength, "SawedOff Arena");
		}
		else if (object_id == WAscar20)
		{
			Format(buffer, maxlength, "SCAR20 Arena");
		}
		else if (object_id == WAsg556)
		{
			Format(buffer, maxlength, "SG556 Arena");
		}
		else if (object_id == WAssg08)
		{
			Format(buffer, maxlength, "SSG08 Arena");
		}
		else if (object_id == WAtaser)
		{
			Format(buffer, maxlength, "Zeus Arena");
		}
		else if (object_id == WAtec9)
		{
			Format(buffer, maxlength, "TEC9 Arena");
		}
		else if (object_id == WAump45)
		{
			Format(buffer, maxlength, "UMP45 Arena");
		}
		else if (object_id == WAxm1014)
		{
			Format(buffer, maxlength, "XM1014 Arena");
		}
		else if (object_id == WAawp)
		{
			Format(buffer, maxlength, "AWP Arena");
		}
		else if (object_id == WAammo)
		{
			Format(buffer, maxlength, "Toggle Unlimited Ammo");
		}
		else if (object_id == WArandom)
		{
			Format(buffer, maxlength, "Enable Random Weapons Mode");
		}
		else if (object_id == WArandomT)
		{
			Format(buffer, maxlength, "Enable Random Team Weapons Mode");
		}
		else if (object_id == WAarena)
		{
			Format(buffer, maxlength, "Enable Regular Weapon Arena Mode");
		}
		else if (object_id == WAbomb)
		{
			Format(buffer, maxlength, "Toggle Remove Bomb");
		}
		else if (object_id == WAallowvotes)
		{
			Format(buffer, maxlength, "Toggle Allow RTA");
		}
		else if (object_id == WAinvisible)
		{
			Format(buffer, maxlength, "Toggle Remove Ground Weapons");
		}
		else if (object_id == WAhostages)
		{
			Format(buffer, maxlength, "Toggle Remove Hostages");
		}
		else if (object_id == WAzeuskill)
		{
			Format(buffer, maxlength, "Toggle Require Zeus Kill");
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == WAak)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 1");
		}
		else if (object_id == WAaug)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 2");
		}
		else if (object_id == WAbizon)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 3");
		}
		else if (object_id == WAdeagle)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 4");
		}
		else if (object_id == WAelite)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 5");
		}
		else if (object_id == WAfamas)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 6");
		}
		else if (object_id == WAfiveseven)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 7");
		}
		else if (object_id == WAg3sg1)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 8");
		}
		else if (object_id == WAgalilar)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 9");
		}
		else if (object_id == WAglock)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 10");
		}
		else if (object_id == WAhe)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 11");
		}
		else if (object_id == WAhkp2000)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 12");
		}
		else if (object_id == WAinc)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 13");
		}
		else if (object_id == WAknife)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 14");
		}
		else if (object_id == WAm249)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 15");
		}
		else if (object_id == WAm4a1)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 16");
		}
		else if (object_id == WAmac10)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 17");
		}
		else if (object_id == WAmag7)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 18");
		}
		else if (object_id == WAmolotov)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 19");
		}
		else if (object_id == WAmp7)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 20");
		}
		else if (object_id == WAmp9)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 21");
		}
		else if (object_id == WAnegev)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 22");
		}
		else if (object_id == WAnova)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 23");
		}
		else if (object_id == WAp250)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 24");
		}
		else if (object_id == WAp90)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 25");
		}
		else if (object_id == WAsawedoff)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 26");
		}
		else if (object_id == WAscar20)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 27");
		}
		else if (object_id == WAsg556)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 28");
		}
		else if (object_id == WAssg08)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 29");
		}
		else if (object_id == WAtaser)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 30");
		}
		else if (object_id == WAtec9)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 31");
		}
		else if (object_id == WAump45)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 32");
		}
		else if (object_id == WAxm1014)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 33");
		}
		else if (object_id == WAawp)
		{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 34");
		}
		else if (object_id == WAammo)
		{
			if(UnlimitedAmmo)
			{
			ServerCommand("sm_weaponarena_unlimitedammo 0");
			} else
			if(!UnlimitedAmmo)
			{
			ServerCommand("sm_weaponarena_unlimitedammo 1");
			}
		}
		else if (object_id == WAbomb)
		{
			if(RemoveBomb)
			{
			ServerCommand("sm_weaponarena_removebomb 0");
			} else
			if(!RemoveBomb)
			{
			ServerCommand("sm_weaponarena_removebomb 1");
			}
		}
		else if (object_id == WAallowvotes)
		{
			if(AllowVotes)
			{
			ServerCommand("sm_weaponarena_allowvotes 0");
			} else
			if(!AllowVotes)
			{
			ServerCommand("sm_weaponarena_allowvotes 1");
			}
		}
		else if (object_id == WAinvisible)
		{
			if(InvisibleWeapons)
			{
			ServerCommand("sm_weaponarena_invisibleweapons 0");
			} else
			if(!InvisibleWeapons)
			{
			ServerCommand("sm_weaponarena_invisibleweapons 1");
			}
		}
		else if (object_id == WAzeuskill)
		{
			if(RequireZeusKill)
			{
			ServerCommand("sm_weaponarena_requirezeuskill 0");
			} else
			if(!RequireZeusKill)
			{
			ServerCommand("sm_weaponarena_requirezeuskill 1");
			}
		}
		else if (object_id == WAhostages)
		{
			if(RemoveHostages)
			{
			ServerCommand("sm_weaponarena_removehostages 0");
			} else
			if(!RemoveHostages)
			{
			ServerCommand("sm_weaponarena_removehostages 1");
			}
		}
		else if (object_id == WArandom)
		{
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena_randomweapons 1");
		}
		else if (object_id == WArandomT)
		{
			ServerCommand("sm_weaponarena_randomteamweapons 1");
			ServerCommand("sm_weaponarena_randomweapons 0");
		}
		else if (object_id == WAarena)
		{
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena_randomweapons 0");
		}
	}
}

/**************************************************************************************

	V O T I N G  F U N C T I O N

**************************************************************************************/
public Action:Command_RTA(client, args)
{
	if (!g_CanRTA || !client)
	{
		return Plugin_Handled;
	}
	
	AttemptRTA(client);
	
	return Plugin_Handled;
}

AttemptRTA(client)
{
	if (!g_RTAAllowed  || (GetConVarInt(g_Cvar_RTAPostVoteAction) == 1))
	{
		ReplyToCommand(client, "[SM] %t", "RTA Not Allowed");
		return;
	}
			
	if (GetClientCount(true) < GetConVarInt(g_Cvar_MinPlayers))
	{
		ReplyToCommand(client, "[SM] %t", "Minimal Players Not Met");
		return;			
	}
	
	if (g_Voted[client])
	{
		ReplyToCommand(client, "[SM] %t", "Already Voted", g_Votes, g_VotesNeeded);
		return;
	}	
	
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	g_Votes++;
	g_Voted[client] = true;
	
	PrintToChatAll("[SM] %t", "RTA Requested", name, g_Votes, g_VotesNeeded);
	
	if (g_Votes >= g_VotesNeeded)
	{
		StartRTA();
	}	
}

public Action:Timer_DelayRTA(Handle:timer)
{
	g_RTAAllowed = true;
}

StartRTA()
{
	if (g_InChange)
	{
		return;	
	}
	DoVoteRTAMenu();
	ResetRTA();
	g_RTAAllowed = false;
	CreateTimer(GetConVarFloat(g_Cvar_Interval), Timer_DelayRTA, _, TIMER_FLAG_NO_MAPCHANGE);
}
 
ResetRTA()
{
	g_Votes = 0;

	for (new i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}

public Action:Command_Say(client, args)
{
	if(AllowVotes)
	{
		if (!g_CanRTA || !client)
		{
			return Plugin_Continue;
		}
		
		decl String:text[192];
		if (!GetCmdArgString(text, sizeof(text)))
		{
			return Plugin_Continue;
		}
	
		new startidx = 0;
		if(text[strlen(text)-1] == '"')
		{
			text[strlen(text)-1] = '\0';
			startidx = 1;
		}

		new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		if (strcmp(text[startidx], "rta", false) == 0 || strcmp(text[startidx], "rockthearena", false) == 0)
		{
			AttemptRTA(client);
		}
		
		SetCmdReplySource(old);
	}
		
	return Plugin_Continue;	
}

public Handle_VoteRTAMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} else
	if (action == MenuAction_VoteEnd) {
		new votes;
		new totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		new Float:percent = FloatDiv(float(votes),float(totalVotes));
		PrintToChatAll("[SM] %t", "Vote Successful", RoundToNearest(100.0*percent), totalVotes);
		
		switch(param1)
		{
			case 0:
			{
			ServerCommand("sm_weaponarena 0");
			}
			case 1:
			{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 14");
			}
			case 2:
			{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 11");
			}
			case 3:
			{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 30");
			}
			case 4:
			{
			ServerCommand("sm_weaponarena_randomweapons 1");
			ServerCommand("sm_weaponarena_randomteamweapons 0");
			ServerCommand("sm_weaponarena 1");
			}
			case 5:
			{
			ServerCommand("sm_weaponarena_randomweapons 0");
			ServerCommand("sm_weaponarena_randomteamweapons 1");
			ServerCommand("sm_weaponarena 2");
			}
		}
	}
}
 
DoVoteRTAMenu()
{
	if (IsVoteInProgress())
	{
		return;
	}

	new Handle:menu = CreateMenu(Handle_VoteRTAMenu);
	SetMenuTitle(menu, "Choose Weapon Arena:");
	AddMenuItem(menu, "0", "Disable Arena");
	AddMenuItem(menu, "2", "Knife Arena");
	AddMenuItem(menu, "3", "HE Arena");
	AddMenuItem(menu, "4", "Zeus Arena");
	AddMenuItem(menu, "5", "Random Arena");
	AddMenuItem(menu, "6", "Random Team Arena");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 20);
}

/**************************************************************************************

	C O N  V A R  C H A N G E

**************************************************************************************/
public OnRemoveBombChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RemoveBomb = GetConVarBool(cvar);
}

public OnRemoveHostagesChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RemoveHostages = GetConVarBool(cvar);
}

public OnInvisibleWeaponsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	InvisibleWeapons = GetConVarBool(cvar);
}

public OnRequireZeusKillChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RequireZeusKill = GetConVarBool(cvar);
}

public OnUnlimitedAmmoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UnlimitedAmmo = GetConVarBool(cvar);
}

public OnRandomTeamWeaponsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RandomTeamWeapons = GetConVarBool(cvar);
}

public OnRandomWeaponsChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	RandomWeapons = GetConVarBool(cvar);
}

public OnAllowVotesChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	AllowVotes = GetConVarBool(cvar);
}
