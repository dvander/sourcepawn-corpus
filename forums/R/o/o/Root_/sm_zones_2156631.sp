/**
* SM Zones by Root
*
* Description:
*   Defines map zones where players are not allowed to enter (with different punishments).
*
* Version 1.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

// ====[ INCLUDES ]==========================================================
#include <sdkhooks>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

// ====[ CONSTANTS ]=========================================================
#define PLUGIN_NAME       "SM Zones"
#define PLUGIN_VERSION    "1.0"

#define ZONES_MODEL       "models/error.mdl" // This model exists in any source game
#define INIT              -1
#define TEAM_SIZE         4
#define MAX_ZONE_LENGTH   64
#define LIFETIME_INTERVAL 5.0

enum // Just makes plugin readable
{
	NO_POINT,
	FIRST_POINT,
	SECOND_POINT,

	POINTS_SIZE
}

enum
{
	NO_VECTOR,
	FIRST_VECTOR,
	SECOND_VECTOR,

	VECTORS_SIZE
}

enum
{
	DEFAULT_PUNISHMENT,
	ANNOUNCE,
	BOUNCE,
	SLAY,
	NOSHOOT,
	MELEE,
	CUSTOM,

	PUNISHMENTS_SIZE
}

enum
{
	ZONE_NAME,
	ZONE_COORDS1,
	ZONE_COORDS2,
	ZONE_TEAM,
	ZONE_PUNISHMENT,

	ZONEARRAY_SIZE
}

// ====[ VARIABLES ]=========================================================
new	Handle:AdminMenuHandle  = INVALID_HANDLE,
	Handle:ZonesArray       = INVALID_HANDLE,
	Handle:zones_enabled    = INVALID_HANDLE,
	Handle:zones_punishment = INVALID_HANDLE,
	Handle:admin_immunity   = INVALID_HANDLE,
	Handle:show_messages    = INVALID_HANDLE,
	Handle:show_zones       = INVALID_HANDLE;

// ====[ ARRAYS ]============================================================
new	EditingZone[MAXPLAYERS + 1]           = { INIT,     ... },
	EditingVector[MAXPLAYERS + 1]         = { INIT,     ... },
	ZonePoint[MAXPLAYERS + 1]             = { NO_POINT, ... },
	bool:NamesZone[MAXPLAYERS + 1]        = { false,    ... },
	bool:RenamesZone[MAXPLAYERS + 1]      = { false,    ... },
	bool:WeaponPunishment[MAXPLAYERS + 1] = { false,    ... },
	Float:FirstZoneVector[MAXPLAYERS + 1][3],
	Float:SecondZoneVector[MAXPLAYERS + 1][3];

// ====[ GLOBALS ]===========================================================
new	bool:bLate,
	m_hMyWeapons,
	m_flNextPrimaryAttack,
	m_flNextSecondaryAttack,
	MAX_WEAPONS,
	LaserMaterial,
	HaloMaterial,
	GlowSprite,
	String:map[64],
	String:PREFIX[32],
	TeamZones[TEAM_SIZE],
	TeamColors[TEAM_SIZE][4],
	EngineVersion:CurrentVersion,
	Handle:OnEnteredProtectedZone,
	Handle:OnLeftProtectedZone;

// ====[ PLUGIN ]============================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root (based on \"Anti Rush\" plugin by Jannik 'Peace-Maker' Hartung)",
	description = "Defines map zones where players are not allowed to enter (with different punishments)",
	version     = PLUGIN_VERSION,
	url         = "http://www.dodsplugins.com/, http://www.wcfan.de/",
}


/* APLRes:AskPluginLoad2()
 *
 * Called before the plugin starts up.
 * ----------------------------------------------------------------- */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// late-loading support for plugin
	bLate = late;
}

/**
 * --------------------------------------------------------------------------
 *     ____           ______                  __  _
 *    / __ \____     / ____/__  ______  _____/ /_(_)____  ____  _____
 *   / / / / __ \   / /_   / / / / __ \/ ___/ __/ // __ \/ __ \/ ___/
 *  / /_/ / / / /  / __/  / /_/ / / / / /__/ /_/ // /_/ / / / (__  )
 *  \____/_/ /_/  /_/     \__,_/_/ /_/\___/\__/_/ \____/_/ /_/____/
 *
 * --------------------------------------------------------------------------
*/

/* OnPluginStart()
 *
 * When the plugin starts up.
 * -------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Find required send property offsets for the plugin
	m_hMyWeapons            = FindSendPropOffsEx("CBasePlayer",       "m_hMyWeapons");
	m_flNextPrimaryAttack   = FindSendPropOffsEx("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	m_flNextSecondaryAttack = FindSendPropOffsEx("CBaseCombatWeapon", "m_flNextSecondaryAttack");

	// Create plugin ConVars
	CreateConVar("dod_zones_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	zones_enabled    = CreateConVar("sm_zones_enable",         "1", "Whether or not enable Zones plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	zones_punishment = CreateConVar("sm_zones_punishment",     "2", "Determines how plugin should handle players who entered a zone (by default):\n1 = Announce in chat\n2 = Bounce back\n3 = Slay player\n4 = Dont allow to shoot\n5 = Allow only melee weapon\n6 = Custom punishment", FCVAR_PLUGIN, true, 1.0, true, 6.0);
	admin_immunity   = CreateConVar("sm_zones_admin_immunity", "0", "Whether or not allow admins to across zones without any punishments and notificaions", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	show_messages    = CreateConVar("sm_zones_show_messages",  "1", "Whether or not show messages in chat to player that entered protected zone", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	show_zones       = CreateConVar("sm_zones_show",           "0", "Whether or not show the zones on a map all the times", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Register admin commands to control zones
	RegAdminCmd("sm_zones",     Command_SetupZones,     ADMFLAG_CONFIG, "Opens the zones main menu");
	RegAdminCmd("sm_actzone",   Command_ActivateZone,   ADMFLAG_CONFIG, "Activates a zone (by name)");
	RegAdminCmd("sm_diactzone", Command_DiactivateZone, ADMFLAG_CONFIG, "Diactivates a zone (by name)");

	// Prevent weapon dropping for weapon punishments
	AddCommandListener(Command_Drop, "drop");

	// Hook plugin events
	HookEvent("player_spawn",  OnPlayerEvents);
	HookEvent("player_death",  OnPlayerEvents);
	HookEventEx("round_start", OnRoundStart, EventHookMode_PostNoCopy); // Doesnt exists in TF2, but HookEventEx wont give an error

	// Default MAX_WEAPONS value for most games
	MAX_WEAPONS = 48;

	// Set default colors of zones per team
	TeamColors[CS_TEAM_NONE] = { 255, 255, 255, 255 }; // White
	TeamColors[CS_TEAM_T]    = { 255, 0,   0,   255 }; // Red
	TeamColors[CS_TEAM_CT]   = { 0,   0, 255,   255 }; // Blue

	// OnClientSayCommand() forward exists in SM 1.5+ as well as GetEngineVersion() native
	CurrentVersion = GetEngineVersion();
	switch (CurrentVersion)
	{
		case Engine_CSS:
		{
			PREFIX = "\x01[\x04CS:S Zones\x01] >> \x07FFFF00";
		}
		case Engine_DODS:
		{
			PREFIX = "\x01[\x04DoD:S Zones\x01] >> \x07FFFF00";

			// Colors of Allies team in DoD:S is green
			TeamColors[CS_TEAM_CT] = { 0, 255, 0, 255 };

			// round_start event exists in DoD:S, but fired only once after mapchange
			HookEvent("dod_round_start", OnRoundStart, EventHookMode_PostNoCopy);
		}
		case Engine_TF2:
		{
			// Set boolean for optimizations purpose
			PREFIX = "\x01[\x04TF2 Zones\x01] >> \x07FFFF00";

			// In TF2 hook voicemenu command to check whether or not 'medic' command was used
			AddCommandListener(Command_VoiceMenu, "voicemenu");

			// Also hook tf2-specific round start event
			HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
		}
		case Engine_CSGO:
		{
			MAX_WEAPONS = 64; // CS:GO got 64 weapons max
			PREFIX = "\x01[\x04CS:GO Zones\x01] >> \x03";
		}
		case Engine_Insurgency:
		{
			// +USE command is not bound in Insurgency
			AddCommandListener(Command_Leaning, "+leanright");
			PREFIX = "\x01[\x04INS Zones\x01] >> \x03";
		}
		default:
		{
			// Use default prefix for other games
			PREFIX = "\x01[\x04Zones\x01] >> \x03";
		}
	}

	// Load some plugin translations
	LoadTranslations("common.phrases");
	LoadTranslations("playercommands.phrases");
	LoadTranslations("sm_zones.phrases");

	// Adminmenu integration when menu is ready
	new Handle:topmenu = INVALID_HANDLE;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}

	// Create a zones array
	ZonesArray = CreateArray();

	// Global forwards for custom punishment
	OnEnteredProtectedZone = CreateGlobalForward("OnEnteredProtectedZone", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	OnLeftProtectedZone    = CreateGlobalForward("OnLeftProtectedZone",    ET_Ignore, Param_Cell, Param_Cell, Param_String);

	// And create/load plugin's config
	AutoExecConfig(true, "sm_zones");

	// Get the zones path
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "data/zones");

	// If there are no 'zones' folder - create it
	if (!DirExists(path))
	{
		// After creating a zones folder set its permissions to allow plugin to create/load/edit configs from this directory
		CreateDirectory(path, FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_EXEC);
	}
}

/* OnAdminMenuReady()
 *
 * Called when the admin menu is ready to have items added.
 * -------------------------------------------------------------------------- */
public OnAdminMenuReady(Handle:topmenu)
{
	// Block menu handle from being called twice
	if (topmenu == AdminMenuHandle)
	{
		return;
	}

	AdminMenuHandle = topmenu;

	// If the category is third party, it will have its own unique name
	new TopMenuObject:server_commands = FindTopMenuCategory(AdminMenuHandle, ADMINMENU_SERVERCOMMANDS);

	if (server_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}

	// Add 'Setup Zones' category to "ServerCommands" menu
	AddToTopMenu(AdminMenuHandle, "sm_zones", TopMenuObject_Item, AdminMenu_Zones, server_commands, "sm_zones_immunity", ADMFLAG_CONFIG);
}

/* OnMapStart()
 *
 * When the map starts.
 * -------------------------------------------------------------------------- */
public OnMapStart()
{
	// Get the current map
	decl String:curmap[64];
	GetCurrentMap(curmap, sizeof(curmap));

	// Does current map string is contains a "workshop" word?
	if (strncmp(curmap, "workshop", 8) == 0)
	{
		// If yes - skip the first 19 characters to avoid comparing the "workshop/12345678" prefix
		strcopy(map, sizeof(map), curmap[19]);
	}
	else
	{
		// Not a workshop map
		strcopy(map, sizeof(map), curmap);
	}

	// Setup tempent effects for zones
	switch (CurrentVersion)
	{
		case Engine_Left4Dead, Engine_Left4Dead2, Engine_AlienSwarm, Engine_CSGO, Engine_Insurgency:
		{
			// Paths for materials are different for some engines
			LaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
			HaloMaterial  = PrecacheModel("materials/sprites/glow01.vmt");
			GlowSprite    = PrecacheModel("materials/sprites/blueflare1.vmt"); // Actually there are no 'glow sprite' for Insurgency
		}
		default:
		{
			// Generic effects are used in OB engine and earlier (?)
			LaserMaterial = PrecacheModel("materials/sprites/laser.vmt");
			HaloMaterial  = PrecacheModel("materials/sprites/halo01.vmt");
			GlowSprite    = PrecacheModel("sprites/blueglow2.vmt");
		}
	}

	// Precache zones model
	PrecacheModel(ZONES_MODEL, true);

	// Prepare a config for new map
	ParseZoneConfig();

	// Create global repeatable timer to show zones
	CreateTimer(LIFETIME_INTERVAL, Timer_ShowZones, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	// Plugin were late loaded
	if (bLate)
	{
		// Yea, so loop through all clients on a server
		for (new client = 1; client <= MaxClients; client++)
		{
			// OnMapStart() is called after plugin reloads, so now we should
			if (IsClientInGame(client))
			{
				// Hook 'em
				OnClientPutInServer(client);
			}
		}
	}
}

/* OnClientPutInServer()
 *
 * Called when a client is entering the game.
 * -------------------------------------------------------------------------- */
public OnClientPutInServer(client)
{
	// Dont make weapon hooks for TF2
	if (CurrentVersion != Engine_TF2)
	{
		// Optionally hook some weapon forwards for weapon punishments
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponUsage);
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponUsage);
		SDKHook(client, SDKHook_WeaponEquip,  OnWeaponUsage);
	}

	// Reset everything when the player connects
	EditingZone[client] =
	EditingVector[client] = INIT;
	ZonePoint[client] =
	NamesZone[client] =
	RenamesZone[client] =
	WeaponPunishment[client] = false;
}

/* OnPlayerRunCmd()
 *
 * When a clients movement buttons are being processed.
 * -------------------------------------------------------------------------- */
public Action:OnPlayerRunCmd(client, &buttons)
{
	// Use this intead of a global
	static bool:PressedUse[MAXPLAYERS + 1] = false;

	// Make sure player is pressing +USE button
	if (buttons & IN_USE)
	{
		// Also check if player is about to create new zones
		if (!PressedUse[client] && ZonePoint[client] != NO_POINT)
		{
			decl Float:origin[3];
			GetClientAbsOrigin(client, origin);

			// Player is creating first corner
			if (ZonePoint[client] == FIRST_POINT)
			{
				// Set point for second one
				ZonePoint[client] = SECOND_POINT;
				FirstZoneVector[client][0] = origin[0];
				FirstZoneVector[client][1] = origin[1];
				FirstZoneVector[client][2] = origin[2];

				PrintToChat(client, "%s%t", PREFIX, "Zone Edge");
			}
			else if (ZonePoint[client] == SECOND_POINT)
			{
				// Player is creating second point now
				ZonePoint[client] = NO_POINT;
				SecondZoneVector[client][0] = origin[0];
				SecondZoneVector[client][1] = origin[1];
				SecondZoneVector[client][2] = origin[2];

				// Notify client and set name boolean to 'true' to hook player chat for naming zone
				PrintToChat(client, "%s%t", PREFIX, "Type Zone Name");
				NamesZone[client] = true;
			}
		}

		// Sort of cooldown
		PressedUse[client] = true;
	}

	// Player not IN_USE
	else PressedUse[client] = false;
}

/* OnRoundStart()
 *
 * Called when the round starts.
 * -------------------------------------------------------------------------- */
public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Does plugin is enabled?
	if (GetConVarBool(zones_enabled))
	{
		decl String:class[MAX_ZONE_LENGTH], zone, z;

		// Faster and better than for (new i = MaxClients; i < GetMaxEntities(); i++)
		zone = INIT;
		while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != INIT)
		{
			// Kill all previous zones
			if (IsValidEdict(zone)
			&& GetEntPropString(zone, Prop_Data, "m_iName", class, sizeof(class))
			&& strncmp(class, "sm_zone", 7) == 0) // Compare first 7 characters
			{
				AcceptEntityInput(zone, "Kill");
			}
		}

		// Then re-create zones depends on array size
		for (z = 0; z < GetArraySize(ZonesArray); z++)
		{
			SpawnZone(z);
		}

		// Reset weapon punishments for all clients when round starts
		for (z = 1; z <= MaxClients; z++)
		{
			// Because its called before player spawns
			WeaponPunishment[z] = false;
		}
	}
}

/* OnPlayerEvents()
 *
 * Called when the player respawns or dies.
 * -------------------------------------------------------------------------- */
public OnPlayerEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	// When player dies or respawns, allow player to use all weapons again
	WeaponPunishment[GetClientOfUserId(GetEventInt(event, "userid"))] = false;
}

/* OnTouch()
 *
 * Called when the player touches a zone.
 * -------------------------------------------------------------------------- */
public OnTouch(const String:output[], caller, activator, Float:delay)
{
	// Check whether or not plugin is enabled
	if (GetConVarBool(zones_enabled))
	{
		if (1 <= activator <= MaxClients)
		{
			if (IsClientInGame(activator))
			{
				// Ignore immune admins
				if (GetConVarBool(admin_immunity) && CheckCommandAccess(activator, "sm_zones_immunity", ADMFLAG_CONFIG, true))
				{
					return;
				}

				// Get the name of a zone
				decl String:targetname[MAX_ZONE_LENGTH+9], String:ZoneName[MAX_ZONE_LENGTH], i;
				GetEntPropString(caller, Prop_Data, "m_iName", targetname, sizeof(targetname));

				// Prepare zone team, punishments and other useful stuff
				new team = CS_TEAM_NONE;
				new punishment = INIT;
				new real_punishment = GetConVarInt(zones_punishment);

				// Check whether or not that was StartTouch callback. Check if player is alive there as well
				new bool:StartTouch = (StrEqual(output, "OnStartTouch", false) && IsPlayerAlive(activator));
				new bool:IsTF2      = (CurrentVersion == Engine_TF2);
				new bool:messages   = GetConVarBool(show_messages);

				// Loop through all available zones
				for (i = 0; i < GetArraySize(ZonesArray); i++)
				{
					new Handle:hZone = GetArrayCell(ZonesArray, i);
					GetArrayString(hZone, ZONE_NAME, ZoneName, sizeof(ZoneName));

					// Ignore 'sm_zone ' prefix and check what zone we touched
					if (StrEqual(ZoneName, targetname[8], false))
					{
						// Then retrieve team and punishment
						team       = GetArrayCell(hZone, ZONE_TEAM);
						punishment = GetArrayCell(hZone, ZONE_PUNISHMENT);
						if (team  != CS_TEAM_NONE && GetClientTeam(activator) != team)
						{
							// If team doesnt match, skip punishments
							return;
						}
					}
				}

				// If any punishment is used, assign real punishment
				if (INIT < punishment < PUNISHMENTS_SIZE)
				{
					real_punishment = punishment;
				}

				switch (real_punishment)
				{
					case ANNOUNCE:
					{
						if (StartTouch)
						{
							// Just tell to everybody that some player entered protected zone
							PrintToChatAll("%s%t", PREFIX, "Player Entered Zone", activator, targetname[8]);
						}
					}
					case BOUNCE:
					{
						if (StartTouch)
						{
							// Bounce activator back
							decl Float:vel[3];

							vel[0] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[0]");
							vel[0] *= -2.0;
							vel[1] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[1]");
							vel[1] *= -2.0;
							vel[2] = GetEntPropFloat(activator, Prop_Send, "m_vecVelocity[2]");

							// Always bounce back with at least 200 velocity
							if (vel[1] > 0.0 && vel[1] < 200.0)
								vel[1] = 200.0;
							else if (vel[1] < 0.0 && vel[1] > -200.0)
								vel[1] = -200.0;
							if (vel[2] > 0.0) // Never push the activator up
								vel[2] *= -0.1;

							// So move it
							TeleportEntity(activator, NULL_VECTOR, NULL_VECTOR, vel);

							// Set collision group to COLLISION_GROUP_PUSHAWAY if team is ANY or matches
							SetEntProp(caller, Prop_Send, "m_CollisionGroup", team == CS_TEAM_NONE || team == GetClientTeam(activator) ? 17 : 11);

							// Notify player about not allowing to enter there by default phrase from resources
							if (CurrentVersion == Engine_DODS) PrintHintText(activator, "#Dod_wrong_way");
						}
						else // Otherwise return proper value for collision group
							SetEntProp(caller, Prop_Send, "m_CollisionGroup", 11);
					}
					case SLAY:
					{
						// Check to prevent doubled message
						if (StartTouch)
						{
							// Oh and check whether or not show that zone
							if (messages) PrintToChatAll("%s%t", PREFIX, "Player Slayed", activator, targetname[8]);
							if (CurrentVersion == Engine_DODS)
							{
								// Kill player using this native, because sometimes players wont die in DoD:S
								SDKHooks_TakeDamage(activator, 0, 0, float(GetClientHealth(activator)));
							}
							else
							{
								// For other games use ForcePlayerSuicide
								ForcePlayerSuicide(activator);
							}
						}
					}
					case NOSHOOT:
					{
						if (StartTouch)
						{
							// Notify player that he is not allowed to shoot
							if (messages) PrintToChat(activator, "%s%t", PREFIX, "Can't shoot");
							if (!IsTF2)   WeaponPunishment[activator] = true;
						}
						else // Nope - player just left zone
						{
							// Dont set weapon punishments for TF2 because players cant drop/equip weapons
							if (messages) PrintToChat(activator, "%s%t", PREFIX, "Can shoot");
							if (!IsTF2)   WeaponPunishment[activator] = false;
						}

						new weapons = -1, Float:time = GetGameTime();
						for (i = 0; i < MAX_WEAPONS; i += 4)
						{
							// Retrieve all player weapons
							if ((weapons = GetEntDataEnt2(activator, m_hMyWeapons + i)) != -1)
							{
								// Checking for 'alive player' is also required
								if (StartTouch)
								{
									// Set very very big (an unlimited) cooldown for weapons to prevent shooting
									SetEntDataFloat(weapons, m_flNextPrimaryAttack,   time + 999.9);
									SetEntDataFloat(weapons, m_flNextSecondaryAttack, time + 999.9);
								}
								else // If player dies in that zone, he will not able to shoot on respawn, so checking for alive player does the trick
								{
									// Setup default timestamp to allow shooting by weapons
									SetEntDataFloat(weapons, m_flNextPrimaryAttack,   time);
									SetEntDataFloat(weapons, m_flNextSecondaryAttack, time);
								}
							}
						}
					}
					case MELEE: // Only allow the usage of the melee weapons
					{
						if (StartTouch)
						{
							// Manually change player's weapon to melee
							new weapon = GetPlayerWeaponSlot(activator, TFWeaponSlot_Melee);
							if (IsValidEdict(weapon))
							{
								decl String:class[MAX_NAME_LENGTH * 2]; // * 2
								GetEdictClassname(weapon, class, sizeof(class));

								// Smoothly set player weapon to melee
								FakeClientCommand(activator, "use %s", class);

								// If its wont work, force to change it over network
								SetEntPropEnt(activator, Prop_Data, "m_hActiveWeapon", weapon);
							}

							if (IsTF2)
							{
								// For TF2 set existed condition to dont allow player to go away from melee weapon
								TF2_AddCondition(activator, TFCond:TFCond_RestrictToMelee, 999.9);
							}
							else
							{
								// Set boolean for weapon usage in other games
								WeaponPunishment[activator] = true;
							}
							if (messages) PrintToChat(activator, "%s%t", PREFIX, "Can use melee only");
						}
						else
						{
							if (IsTF2)
							{
								// Remove TFCond_RestrictToMelee condition when leaving a zone
								TF2_RemoveCondition(activator, TFCond:TFCond_RestrictToMelee);
							}
							else
							{
								// Allow weapons usage in other games using SDKHooks
								WeaponPunishment[activator] = false;
							}
							if (messages) PrintToChat(activator, "%s%t", PREFIX, "Can use any weapon");
						}
					}
					case CUSTOM:
					{
						// Start appropriate OnEntered/Left zone forwards in custom punishment to deal with other plugins
						Call_StartForward(StartTouch ? OnEnteredProtectedZone : OnLeftProtectedZone);

						// Add zone (caller) entity index
						Call_PushCell(caller);

						// Add the client id when its passing a zone
						Call_PushCell(activator);

						// Add zones prefix for this forward too, so plugins can print messages with proper prefix
						Call_PushString(PREFIX);

						// And finally call the forward
						Call_Finish();
					}
				}
			}
		}
	}
}

/* OnWeaponUsage()
 *
 * Called when the player uses specified weapon.
 * -------------------------------------------------------------------------- */
public Action:OnWeaponUsage(client, weapon)
{
	// Block weapon usage if player is punished, otherwise use weapons as usual
	return (WeaponPunishment[client] && IsValidEdict(weapon)) ? Plugin_Handled : Plugin_Continue;
}


/**
 * --------------------------------------------------------------------------
 *     ______                                          __
 *    / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
 *   / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
 *  / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  )
 *  \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/
 *
 * --------------------------------------------------------------------------
*/

/* Command_Chat()
 *
 * When the say/say_team commands are used.
 * -------------------------------------------------------------------------- */
public Action:OnClientSayCommand(client, const String:command[], const String:sArgs[])
{
	decl String:text[MAX_ZONE_LENGTH];

	// Copy original message
	strcopy(text, sizeof(text), sArgs);

	// Remove quotes from dest string
	StripQuotes(text);

	// When player is about to name a zone
	if (NamesZone[client])
	{
		// Set boolean after sending a text
		NamesZone[client] = false;

		// Or cancel renaming
		if (StrEqual(text, "!stop", false) || StrEqual(text, "!cancel", false))
		{
			PrintToChat(client, "%s%t", PREFIX, "Abort Zone Name");

			// Reset vector settings for new zone
			ClearVector(FirstZoneVector[client]);
			ClearVector(SecondZoneVector[client]);
			return Plugin_Handled;
		}

		// Show save menu after sending a name.
		ShowSaveZoneMenu(client, text);

		// Don't show new zone name in chat
		return Plugin_Handled;
	}
	else if (RenamesZone[client])
	{
		// Player is about to rename a zone
		decl String:OldZoneName[MAX_ZONE_LENGTH];
		RenamesZone[client] = false;

		if (StrEqual(text, "!stop", false) || StrEqual(text, "!cancel", false))
		{
			PrintToChat(client, "%s%t", PREFIX, "Abort Zone Rename");

			// When renaming is cancelled - redraw zones menu
			ShowZoneOptionsMenu(client);
			return Plugin_Handled;
		}

		// Kill the previous zone (its really better than just renaming via config)
		KillZone(EditingZone[client]);

		new Handle:hZone = GetArrayCell(ZonesArray, EditingZone[client]);

		// Get the old name of a zone
		GetArrayString(hZone, ZONE_NAME, OldZoneName, sizeof(OldZoneName));

		// And set to a new one
		SetArrayString(hZone, ZONE_NAME, text);

		// Re-spawn an entity again
		SpawnZone(EditingZone[client]);

		// Update the config file
		decl String:config[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, config, sizeof(config), "data/zones/%s.cfg", map);

		PrintToChat(client, "%s%t", PREFIX, "Name Edited");

		// Read the config
		new Handle:kv = CreateKeyValues("Zones");
		FileToKeyValues(kv, config);
		if (!KvGotoFirstSubKey(kv))
		{
			// Log an error if cant save zones config
			PrintToChat(client, "%s%t", PREFIX, "Cant save", map);
			CloseHandle(kv);

			// Redraw menu and discard changes
			ShowZoneOptionsMenu(client);
			return Plugin_Handled;
		}

		// Otherwise find the zone to edit
		decl String:buffer[MAX_ZONE_LENGTH];
		KvGetSectionName(kv, buffer, sizeof(buffer));
		do
		{
			// Compare name to make sure we gonna edit correct zone
			KvGetString(kv, "zone_ident", buffer, sizeof(buffer));
			if (StrEqual(buffer, OldZoneName, false))
			{
				// Write the new name in config
				KvSetString(kv, "zone_ident", text);
				break;
			}
		}
		while (KvGotoNextKey(kv));

		KvRewind(kv);
		KeyValuesToFile(kv, config);
		CloseHandle(kv);

		ShowZoneOptionsMenu(client);

		// Don't show new zone name in chat
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/* Command_Drop()
 *
 * When the drop weapon commands are used.
 * -------------------------------------------------------------------------- */
public Action:Command_Drop(client, const String:command[], args)
{
	// Dont allow player to drop a weapon if No Shoot punishment is performed
	return WeaponPunishment[client] ? Plugin_Handled : Plugin_Continue;
}

/* Command_VoiceMenu()
 *
 * When the voice command is used.
 * -------------------------------------------------------------------------- */
public Action:Command_VoiceMenu(client, const String:command[], args)
{
	// Get full string of voicemenu command
	decl String:buffer[8];
	GetCmdArgString(buffer, sizeof(buffer));

	// Check whether medic command is used
	if (StrEqual(buffer, "0 0", false))
	{
		if (ZonePoint[client] != NO_POINT /*&& CheckCommandAccess(client, "sm_zones_immunity", ADMFLAG_CONFIG, true)*/)
		{
			// Yea, retrieve his origin
			decl Float:origin[3];
			GetClientAbsOrigin(client, origin);

			// Player is editing first point
			if (ZonePoint[client] == FIRST_POINT)
			{
				ZonePoint[client] = SECOND_POINT;
				FirstZoneVector[client][0] = origin[0];
				FirstZoneVector[client][1] = origin[1];
				FirstZoneVector[client][2] = origin[2];

				// Set zone vectors at player current position
				PrintToChat(client, "%s%t", PREFIX, "Zone Edge");
			}
			else if (ZonePoint[client] == SECOND_POINT)
			{
				ZonePoint[client] = NO_POINT;
				SecondZoneVector[client][0] = origin[0];
				SecondZoneVector[client][1] = origin[1];
				SecondZoneVector[client][2] = origin[2];

				// Notify player that he done editing a zone
				PrintToChat(client, "%s%t", PREFIX, "Type Zone Name");
				NamesZone[client] = true;
			}

			// Dont perform 'medic' voice command
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

/* Command_Leaning()
 *
 * When the leaning command is used.
 * -------------------------------------------------------------------------- */
public Action:Command_Leaning(client, const String:command[], args)
{
	if (ZonePoint[client] != NO_POINT /*&& CheckCommandAccess(client, "sm_zones_immunity", ADMFLAG_CONFIG, true)*/)
	{
		decl Float:origin[3];
		GetClientAbsOrigin(client, origin);

		// Player is editing first point
		if (ZonePoint[client] == FIRST_POINT)
		{
			ZonePoint[client] = SECOND_POINT;
			FirstZoneVector[client][0] = origin[0];
			FirstZoneVector[client][1] = origin[1];
			FirstZoneVector[client][2] = origin[2];
			PrintToChat(client, "%s%t", PREFIX, "Zone Edge");
		}
		else if (ZonePoint[client] == SECOND_POINT)
		{
			ZonePoint[client] = NO_POINT;
			SecondZoneVector[client][0] = origin[0];
			SecondZoneVector[client][1] = origin[1];
			SecondZoneVector[client][2] = origin[2];
			PrintToChat(client, "%s%t", PREFIX, "Type Zone Name");
			NamesZone[client] = true;
		}

		return Plugin_Handled;
	}

	return Plugin_Continue;
}

/* Command_SetupZones()
 *
 * Shows a zones menu to a client.
 * -------------------------------------------------------------------------- */
public Action:Command_SetupZones(client, args)
{
	// Make sure valid client used a command
	if (!client)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}

	// Show a menu on zones command
	ShowZonesMainMenu(client);
	return Plugin_Handled;
}

/* Command_ActivateZone()
 *
 * Activates an inactive zone.
 * -------------------------------------------------------------------------- */
public Action:Command_ActivateZone(client, args)
{
	// Once again check if server was used this command
	if (!client && args == 1)
	{
		decl String:text[MAX_ZONE_LENGTH];
		GetCmdArg(1, text, sizeof(text));
		ActivateZone(text);
	}

	// Show diactivated zones menu to valid client
	ShowDiactivatedZonesMenu(client);
	return Plugin_Handled;
}

/* Command_DiactivateZone()
 *
 * Diactivates an active zone.
 * Note: It just disabling zones, not killing them at all.
 * -------------------------------------------------------------------------- */
public Action:Command_DiactivateZone(client, args)
{
	// Check whether or not argument (name) is sent
	if (!client && args == 1)
	{
		// If server is used a command, just diactivate zone by name
		decl String:text[MAX_ZONE_LENGTH];
		GetCmdArg(1, text, sizeof(text));
		DiactivateZone(text);
	}

	ShowActivatedZonesMenu(client);

	// Block the command to prevent showing 'Unknown command' in client's console
	return Plugin_Handled;
}


/**
 * --------------------------------------------------------------------------
 *      __  ___
 *     /  |/  /___  ___  __  ________
 *    / /|_/ / _ \/ __ \/ / / // ___/
 *   / /  / /  __/ / / / /_/ /(__  )
 *  /_/  /_/\___/_/ /_/\__,_/_____/
 *
 * --------------------------------------------------------------------------
*/

/* AdminMenu_Zones()
 *
 * Shows a "Setup Zones" category in Server Commands menu.
 * -------------------------------------------------------------------------- */
public AdminMenu_Zones(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		// A name of the 'ServerCommands' category
		case TopMenuAction_DisplayOption: Format(buffer, maxlength, "%T", "Setup Zones", param);
		case TopMenuAction_SelectOption:  ShowZonesMainMenu(param);
	}
}


/* ShowZonesMainMenu()
 *
 * Creates a menu handler to setup zones.
 * -------------------------------------------------------------------------- */
ShowZonesMainMenu(client)
{
	// When main menu is called, reset everything related to menu info
	EditingZone[client] = INIT;
	ZonePoint[client] =
	NamesZone[client] =
	RenamesZone[client] = false;

	ClearVector(FirstZoneVector[client]);
	ClearVector(SecondZoneVector[client]);

	// Create menu with translated items
	decl String:translation[128];
	new Handle:menu = CreateMenu(Menu_Zones);

	// Set menu title
	SetMenuTitle(menu, "%T\n \n", "Setup Zones For", client, map);

	// Translate a string and add menu items
	Format(translation, sizeof(translation), "%T", "Add Zones", client);
	AddMenuItem(menu, "add_zone", translation);

	Format(translation, sizeof(translation), "%T\n \n", "Active Zones", client);
	AddMenuItem(menu, "active_zones", translation);

	// Also add Activate/Diactivate zone items
	Format(translation, sizeof(translation), "%T", "Activate Zones", client);
	AddMenuItem(menu, "activate_zones", translation);

	Format(translation, sizeof(translation), "%T", "Diactivate Zones", client);
	AddMenuItem(menu, "diactivate_zones", translation);

	// Add exit button, and display menu as long as possible
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/* Menu_Zones()
 *
 * Main menu to setup zones.
 * -------------------------------------------------------------------------- */
public Menu_Zones(Handle:menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		decl String:info[17];

		// Retrieve info of menu item
		GetMenuItem(menu, param, info, sizeof(info));

		// Player selected 'Add Zone' menu
		if (StrEqual(info, "add_zone", false))
		{
			// Print an instruction in player's chat
			PrintToChat(client, "%s%t", PREFIX, "Add Zone Instruction");

			// Allow player to define zones by E button
			ZonePoint[client] = FIRST_POINT;
		}

		// No, maybe that was an 'Active zones' ?
		else if (StrEqual(info, "active_zones", false))
		{
			ShowActiveZonesMenu(client);
		}

		// Nope, that was 'Activate zones' item
		else if (StrEqual(info, "activate_zones", false))
		{
			ShowDiactivatedZonesMenu(client);
		}

		// If not - then its a lates one, I believe
		else if (StrEqual(info, "diactivate_zones", false))
		{
			// Diactivate zones
			ShowActivatedZonesMenu(client);
		}
	}
	else if (action == MenuAction_End)
	{
		// Close menu handle on menu ending
		CloseHandle(menu);
	}
}


/* ShowActiveZonesMenu()
 *
 * Creates a menu handler to setup active zones.
 * -------------------------------------------------------------------------- */
ShowActiveZonesMenu(client)
{
	new Handle:menu = CreateMenu(Menu_ActiveZones);

	// Set menu title
	SetMenuTitle(menu, "%T:", "Active Zones", client);

	decl String:name[PLATFORM_MAX_PATH], String:strnum[8];
	for (new i; i < GetArraySize(ZonesArray); i++)
	{
		// Loop through all zones in array
		new Handle:hZone = GetArrayCell(ZonesArray, i);
		GetArrayString(hZone, ZONE_NAME, name, sizeof(name));

		// Add every zone as a menu item
		IntToString(i, strnum, sizeof(strnum));
		AddMenuItem(menu, strnum, name);
	}

	// Add exit button
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/* Menu_ActiveZones()
 *
 * Menu handler to select/edit active zones.
 * -------------------------------------------------------------------------- */
public Menu_ActiveZones(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[8], zone;
			GetMenuItem(menu, param, info, sizeof(info));

			// Define a zone number
			zone = StringToInt(info);

			// Store the zone index for further reference
			EditingZone[client] = zone;

			// Show zone menu
			ShowZoneOptionsMenu(client);
		}
		case MenuAction_Cancel:
		{
			// When player is pressed 'Back' button
			if (param == MenuCancel_ExitBack)
			{
				ShowZonesMainMenu(client);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}


/* ShowActivateZonesMenuMenu()
 *
 * Creates a menu handler to setup diactivated zones.
 * -------------------------------------------------------------------------- */
ShowActivatedZonesMenu(client)
{
	new Handle:menu = CreateMenu(Menu_ActivatedZones);
	SetMenuTitle(menu, "%T:", "Diactivated Zones", client);

	// Initialize classname string and the zone to search
	decl String:class[MAX_ZONE_LENGTH], zone; zone = INIT;
	while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != INIT)
	{
		if (IsValidEdict(zone) && !GetEntProp(zone, Prop_Data, "m_bDisabled") // Dont add diactivated zones to menu
		&& GetEntPropString(zone, Prop_Data, "m_iName", class, sizeof(class))
		&& strncmp(class, "sm_zone", 7) == 0)
		{
			// Set menu title and item info same as m_iName without sm_zone prefix
			AddMenuItem(menu, class[8], class[8]);
		}
	}

	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/* Menu_ActivatedZones()
 *
 * Menu handler to diactivate a zone.
 * -------------------------------------------------------------------------- */
public Menu_ActivatedZones(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select: // When item was selected
		{
			decl String:info[MAX_ZONE_LENGTH];
			GetMenuItem(menu, param, info, sizeof(info));

			// Diactivate zone by info from menu item
			DiactivateZone(info);
			ShowActivatedZonesMenu(client);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
			{
				// Show zones main menu then
				ShowZonesMainMenu(client);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}


/* ShowDiactivatedZonesMenu()
 *
 * Creates a menu handler to setup activated zones.
 * -------------------------------------------------------------------------- */
ShowDiactivatedZonesMenu(client)
{
	new Handle:menu = CreateMenu(Menu_DiactivatedZones);
	SetMenuTitle(menu, "%T:", "Activated Zones", client);

	// Search for any zones on a map
	decl String:class[MAX_ZONE_LENGTH], zone; zone = INIT;
	while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != INIT)
	{
		// If we found a zone, make sure its diactivated
		if (IsValidEdict(zone) && GetEntProp(zone, Prop_Data, "m_bDisabled")
		&& GetEntPropString(zone, Prop_Data, "m_iName", class, sizeof(class))
		&& strncmp(class, "sm_zone", 7) == 0) // Does name contains 'sm_zone' prefix?
		{
			// Add every disabled zone into diactivated menu
			AddMenuItem(menu, class[8], class[8]);
		}
	}

	SetMenuExitBackButton(menu, true);

	// Display menu as long as possible
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/* Menu_DiactivatedZones()
 *
 * Menu handler to activate diactivated zones.
 * -------------------------------------------------------------------------- */
public Menu_DiactivatedZones(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[MAX_ZONE_LENGTH];
			GetMenuItem(menu, param, info, sizeof(info));

			// Otherwise activate a zone
			ActivateZone(info);
			ShowDiactivatedZonesMenu(client);
		}

		// When menu was cancelled, re-draw main menu (because there may be no diactivated items)
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
			{
				ShowZonesMainMenu(client);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}


/* ShowZoneOptionsMenu()
 *
 * Creates a menu handler to setup zones options.
 * -------------------------------------------------------------------------- */
ShowZoneOptionsMenu(client)
{
	// Make sure player is not editing any other zone at this moment
	if (EditingZone[client] != INIT)
	{
		decl String:ZoneName[MAX_ZONE_LENGTH], String:translation[128], String:buffer[128], team;

		new Handle:hZone = GetArrayCell(ZonesArray, EditingZone[client]);
		GetArrayString(hZone, ZONE_NAME, ZoneName, sizeof(ZoneName));

		// Get zone team restrictions
		team = GetArrayCell(hZone, ZONE_TEAM);

		// Create menu handler and set menu title
		new Handle:menu = CreateMenu(Menu_ZoneOptions);
		SetMenuTitle(menu, "%T", "Manage Zone", client, ZoneName);

		// Add 7 items to main menu to edit
		Format(translation, sizeof(translation), "%T", "Edit First Point", client);
		AddMenuItem(menu, "vec1", translation);

		Format(translation, sizeof(translation), "%T", "Edit Second Point", client);
		AddMenuItem(menu, "vec2", translation);

		Format(translation, sizeof(translation), "%T", "Edit Name", client);
		AddMenuItem(menu, "zone_ident", translation);

		Format(translation, sizeof(translation), "%T", "Teleport To", client);

		// Also appripriately set info for every menu item
		AddMenuItem(menu, "teleport", translation);

		// If team is more than 0, show team names
		if (CS_TEAM_NONE < team < TEAM_SIZE)
		{
			GetTeamName(team, buffer, sizeof(buffer));
		}
		else Format(buffer, sizeof(buffer), "%T", "Both", client);

		Format(translation, sizeof(translation), "%T", "Trigger Team", client, buffer);
		AddMenuItem(menu, "team", translation);

		// Retrieve a punishment
		switch (GetArrayCell(hZone, ZONE_PUNISHMENT))
		{
			// No individual zones_punishment selected. Using default one (which is defined in ConVar)
			case ANNOUNCE: Format(buffer, sizeof(buffer), "%T", "Print Message",     client);
			case BOUNCE:   Format(buffer, sizeof(buffer), "%T", "Bounce Back",       client);
			case SLAY:     Format(buffer, sizeof(buffer), "%T", "Slay player",       client);
			case NOSHOOT:  Format(buffer, sizeof(buffer), "%T", "No shooting",       client);
			case MELEE:    Format(buffer, sizeof(buffer), "%T", "Only Melee",        client);
			case CUSTOM:   Format(buffer, sizeof(buffer), "%T", "Custom Punishment", client);
			default:       Format(buffer, sizeof(buffer), "%T", "Default",           client);
		}

		// Update punishment info
		Format(translation, sizeof(translation), "%T %s", "Punishment", client, buffer);
		AddMenuItem(menu, "punishment", translation);

		// Add 'delete zone' option
		Format(translation, sizeof(translation), "%T", "Delete Zone", client);
		AddMenuItem(menu, "delete", translation);

		// Display menu and add 'Exit' button
		SetMenuExitBackButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

/* Menu_ZoneOptions()
 *
 * Menu handler to fully edit a zone.
 * -------------------------------------------------------------------------- */
public Menu_ZoneOptions(Handle:menu, MenuAction:action, client, param)
{
	// Retrieve the menu action
	switch (action)
	{
		case MenuAction_Select:
		{
			// Get a config, menu item info and initialize everything else
			decl String:config[PLATFORM_MAX_PATH], String:ZoneName[MAX_ZONE_LENGTH], String:info[11], Float:vec1[3], Float:vec2[3], team;
			GetMenuItem(menu, param, info, sizeof(info));
			BuildPath(Path_SM, config, sizeof(config), "data/zones/%s.cfg", map);

			// Retrieve zone which player is editing right now
			new Handle:hZone = GetArrayCell(ZonesArray, EditingZone[client]);

			// Retrieve vectors and a name
			GetArrayArray(hZone,  FIRST_VECTOR,  vec1, VECTORS_SIZE);
			GetArrayArray(hZone,  SECOND_VECTOR, vec2, VECTORS_SIZE);
			GetArrayString(hZone, ZONE_NAME,     ZoneName, sizeof(ZoneName));

			// Get the team restrictions
			team = GetArrayCell(hZone, ZONE_TEAM);

			// Now teleport player in center of a zone
			if (StrEqual(info, "teleport", false))
			{
				decl Float:origin[3];
				GetMiddleOfABox(vec1, vec2, origin);
				TeleportEntity(client, origin, NULL_VECTOR, Float:{0.0, 0.0, 0.0});

				// Redisplay the menu
				ShowZoneOptionsMenu(client);
			}
			else if (StrEqual(info, "team", false))
			{
				// When team is selected, decrease TeamZones number
				switch (team)
				{
					case CS_TEAM_NONE:
					{
						TeamZones[CS_TEAM_T]--;
						TeamZones[CS_TEAM_CT]--;
					}
					case CS_TEAM_T:  TeamZones[CS_TEAM_T]--;
					case CS_TEAM_CT: TeamZones[CS_TEAM_CT]--;
				}

				team++;

				// If team is overbounding, make zones punishment for both teams
				if (team > CS_TEAM_CT)
				{
					team = CS_TEAM_NONE;
				}
				else if (team < CS_TEAM_T)
				{
					// Same here, but set lowerbounds to first available team
					team = CS_TEAM_T;
				}

				// Increase zone count on matches now
				switch (team)
				{
					case CS_TEAM_NONE:
					{
						TeamZones[CS_TEAM_T]++;
						TeamZones[CS_TEAM_CT]++;
					}
					case CS_TEAM_T:  TeamZones[CS_TEAM_T]++;
					case CS_TEAM_CT: TeamZones[CS_TEAM_CT]++;
				}

				// Set the team in array
				SetArrayCell(hZone, ZONE_TEAM, team);

				// Write changes into config
				new Handle:kv = CreateKeyValues("Zones");
				FileToKeyValues(kv, config);
				if (!KvGotoFirstSubKey(kv))
				{
					// Config is not available or broken? Dont do anything then
					CloseHandle(kv);
					ShowZoneOptionsMenu(client);
					PrintToChat(client, "%s%t", PREFIX, "Cant save", map);
					return;
				}

				// Get the section name
				decl String:buffer[MAX_ZONE_LENGTH];
				KvGetSectionName(kv, buffer, sizeof(buffer));
				do
				{
					// Does zone names is not the same?
					KvGetString(kv, "zone_ident", buffer, sizeof(buffer));
					if (StrEqual(buffer, ZoneName, false))
					{
						// Don't add punishments section if no punishment is defined
						if (team == CS_TEAM_NONE)
						{
							KvDeleteKey(kv, "restrict_team");
						}
						else KvSetNum(kv, "restrict_team", team);
						break;
					}
				}
				while (KvGotoNextKey(kv));

				// Get back to the top
				KvRewind(kv);
				KeyValuesToFile(kv, config);
				CloseHandle(kv);

				// Re-show options menu on every selection
				ShowZoneOptionsMenu(client);
			}

			// Change zone punishments
			else if (StrEqual(info, "punishment", false))
			{
				// Switch through the zones_punishments
				new real_punishment = GetArrayCell(hZone, ZONE_PUNISHMENT) + 1;

				if (real_punishment > CUSTOM)
				{
					// Re-init punishments on overbounds
					real_punishment = INIT;
				}
				else if (real_punishment < ANNOUNCE)
				{
					real_punishment = ANNOUNCE;
				}

				// Set punishment in array
				SetArrayCell(hZone, ZONE_PUNISHMENT, real_punishment);

				new Handle:kv = CreateKeyValues("Zones");
				FileToKeyValues(kv, config);

				// Setup changes in config
				if (!KvGotoFirstSubKey(kv))
				{
					CloseHandle(kv);
					ShowZoneOptionsMenu(client);
					PrintToChat(client, "%s%t", PREFIX, "Cant save", map);
					return;
				}

				// Get the name of a zone in KeyValues config
				decl String:buffer[MAX_ZONE_LENGTH];
				KvGetSectionName(kv, buffer, sizeof(buffer));
				do
				{
					KvGetString(kv, "zone_ident", buffer, sizeof(buffer));
					if (StrEqual(buffer, ZoneName, false))
					{
						// Don't add punishments section if no punishment is defined
						if (real_punishment == INIT)
						{
							KvDeleteKey(kv, "punishment");
						}
						else KvSetNum(kv, "punishment", real_punishment);
						break;
					}
				}
				while (KvGotoNextKey(kv));

				KvRewind(kv);

				// Save config and close KV handle
				KeyValuesToFile(kv, config);
				CloseHandle(kv);

				ShowZoneOptionsMenu(client);
			}

			// Zone coordinates is editing
			else if (StrEqual(info, "vec1", false) || StrEqual(info, "vec2", false))
			{
				if (StrEqual(info, "vec1", false))
					 EditingVector[client] = FIRST_VECTOR;
				else EditingVector[client] = SECOND_VECTOR;

				if (IsVectorZero(FirstZoneVector[client]) && IsVectorZero(SecondZoneVector[client]))
				{
					// Clear vectors on every selection
					ClearVector(FirstZoneVector[client]);
					ClearVector(SecondZoneVector[client]);

					// And increase on every selection
					AddVectors(FirstZoneVector[client],  vec1, FirstZoneVector[client]);
					AddVectors(SecondZoneVector[client], vec2, SecondZoneVector[client]);
				}

				// Always show a zone box
				TE_SendBeamBoxToClient(client, FirstZoneVector[client], SecondZoneVector[client], LaserMaterial, HaloMaterial, 0, 30, LIFETIME_INTERVAL, 5.0, 5.0, 2, 1.0, TeamColors[team], 0);

				// Highlight the currently edited edge for players editing a zone
				if (EditingVector[client] == FIRST_VECTOR)
				{
					TE_SetupGlowSprite(FirstZoneVector[client], GlowSprite, LIFETIME_INTERVAL, 1.0, 100);
					TE_SendToClient(client);
				}
				else //if (EditingVector[client] == SECOND_VECTOR)
				{
					TE_SetupGlowSprite(SecondZoneVector[client], GlowSprite, LIFETIME_INTERVAL, 1.0, 100);
					TE_SendToClient(client);
				}

				// Don't close vectors edit menu on every selection
				ShowZoneVectorEditMenu(client);
			}
			else if (StrEqual(info, "zone_ident", false))
			{
				// Set rename bool to deal with say/say_team callbacks and retrieve name string
				PrintToChat(client, "%s%t", PREFIX, "Type Zone Name");
				RenamesZone[client] = true;
			}
			else if (StrEqual(info, "delete", false))
			{
				// Create confirmation panel
				new Handle:panel = CreatePanel();

				decl String:buffer[128];

				// Draw a panel with only 'Yes/No' options
				Format(buffer, sizeof(buffer), "%T", "Confirm Delete Zone", client, ZoneName);
				SetPanelTitle(panel, buffer);

				Format(buffer, sizeof(buffer), "%T", "Yes", client);
				DrawPanelItem(panel, buffer);

				Format(buffer, sizeof(buffer), "%T", "No", client);
				DrawPanelItem(panel, buffer);

				// Send panel
				SendPanelToClient(panel, client, Panel_Confirmation, MENU_TIME_FOREVER);

				// Close panel handler just now
				CloseHandle(panel);
			}
		}
		case MenuAction_Cancel:
		{
			// Set player to not editing something when menu is closed
			EditingZone[client] = EditingVector[client] = INIT;

			// Clear vectors that client has changed before
			ClearVector(FirstZoneVector[client]);
			ClearVector(SecondZoneVector[client]);

			// When client pressed 'Back' option
			if (param == MenuCancel_ExitBack)
			{
				// Show active zones menu
				ShowActiveZonesMenu(client);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}


/* ShowZoneVectorEditMenu()
 *
 * Creates a menu handler to setup zone coordinations.
 * -------------------------------------------------------------------------- */
ShowZoneVectorEditMenu(client)
{
	// Make sure player is not editing any other zone at this moment
	if (EditingZone[client] != INIT || EditingVector[client] != INIT)
	{
		// Initialize translation string
		decl String:ZoneName[MAX_ZONE_LENGTH], String:translation[128];

		// Get the zone name
		new Handle:hZone = GetArrayCell(ZonesArray, EditingZone[client]);
		GetArrayString(hZone, ZONE_NAME, ZoneName, sizeof(ZoneName));

		new Handle:menu = CreateMenu(Menu_ZoneVectorEdit);
		SetMenuTitle(menu, "%T", "Edit Zone", client, ZoneName, EditingVector[client]);

		Format(translation, sizeof(translation), "%T", "Add to X", client);
		AddMenuItem(menu, "ax", translation);

		Format(translation, sizeof(translation), "%T", "Add to Y", client);

		// Set every menu item as unique
		AddMenuItem(menu, "ay", translation);

		Format(translation, sizeof(translation), "%T", "Add to Z", client);
		AddMenuItem(menu, "az", translation);

		Format(translation, sizeof(translation), "%T", "Subtract from X", client);
		AddMenuItem(menu, "sx", translation);

		Format(translation, sizeof(translation), "%T", "Subtract from Y", client);
		AddMenuItem(menu, "sy", translation);

		Format(translation, sizeof(translation), "%T", "Subtract from Z", client);
		AddMenuItem(menu, "sz", translation);

		// Add save option
		Format(translation, sizeof(translation), "%T\n \n", "Save", client);
		AddMenuItem(menu, "save", translation);

		// Add \n \n in save option to make spacer between 7 and 8 buttons
		Format(translation, sizeof(translation), "%T", "Back", client);
		AddMenuItem(menu, "back", translation);

		// Also add 'Back' button and show menu as long as possible
		//SetMenuExitBackButton(menu, true);

		// Set no pagination so we have 'save' button as 7th param
		SetMenuPagination(menu, MENU_NO_PAGINATION);
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

/* Menu_ZoneVectorEdit()
 *
 * Menu handler to edit zone coordinates/vectors.
 * -------------------------------------------------------------------------- */
public Menu_ZoneVectorEdit(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Get the menu item
			decl String:info[5];
			GetMenuItem(menu, param, info, sizeof(info));

			// Fix for 'array index is out of bounds'
			new team = CS_TEAM_NONE;

			// Save the new coordinates to the file and the array
			if (StrEqual(info, "save", false))
			{
				decl String:ZoneName[MAX_ZONE_LENGTH];
				new Handle:hZone = GetArrayCell(ZonesArray, EditingZone[client]);

				// Retrieve zone name and appropriately set zone vector (client info) on every selection
				GetArrayString(hZone, ZONE_NAME,     ZoneName, sizeof(ZoneName));
				SetArrayArray(hZone,  FIRST_VECTOR,  FirstZoneVector[client],  VECTORS_SIZE);
				SetArrayArray(hZone,  SECOND_VECTOR, SecondZoneVector[client], VECTORS_SIZE);

				team = GetArrayCell(hZone, ZONE_TEAM);

				// Re-spawn zone when its saved (its better, trust me)
				KillZone(EditingZone[client]);
				SpawnZone(EditingZone[client]);

				// Notify client about saving position
				PrintToChat(client, "%s%t", PREFIX, "Saved");

				// Write changes into config file
				decl String:config[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, config, sizeof(config), "data/zones/%s.cfg", map);

				new Handle:kv = CreateKeyValues("Zones");
				FileToKeyValues(kv, config);

				// But before make sure config is not corrupted
				if (!KvGotoFirstSubKey(kv))
				{
					CloseHandle(kv);
					ShowZoneVectorEditMenu(client);

					// Error
					PrintToChat(client, "%s%t", PREFIX, "Cant save", map);
					return;
				}

				decl String:buffer[MAX_ZONE_LENGTH];
				KvGetSectionName(kv, buffer, sizeof(buffer));

				// Go thru KV config
				do
				{
					// Set coordinates for zone
					KvGetString(kv, "zone_ident", buffer, sizeof(buffer));
					if (StrEqual(buffer, ZoneName, false))
					{
						// Set appropriate section for KV config
						KvSetVector(kv, "coordinates 1", FirstZoneVector[client]);
						KvSetVector(kv, "coordinates 2", SecondZoneVector[client]);
						break;
					}
				}

				// Until config is ended
				while (KvGotoNextKey(kv));

				KvRewind(kv);
				KeyValuesToFile(kv, config);
				CloseHandle(kv);
			}

			// Add X
			else if (StrEqual(info, "ax", false))
			{
				// Add to the x axis
				if (EditingVector[client] == FIRST_VECTOR)
				{
					// Move zone for 5 units on every selection
					FirstZoneVector[client][0] += 5.0;
				}
				else SecondZoneVector[client][0] += 5.0;
			}
			else if (StrEqual(info, "ay", false))
			{
				// Add to the y axis
				if (EditingVector[client] == FIRST_VECTOR)
				{
					FirstZoneVector[client][1] += 5.0;
				}
				else SecondZoneVector[client][1] += 5.0;
			}
			else if (StrEqual(info, "az", false))
			{
				// Add to the z axis
				if (EditingVector[client] == FIRST_VECTOR)
				{
					FirstZoneVector[client][2] += 5.0;
				}
				else SecondZoneVector[client][2] += 5.0;
			}

			// Subract X
			else if (StrEqual(info, "sx", false))
			{
				// Subtract from the x axis
				if (EditingVector[client] == FIRST_VECTOR)
				{
					FirstZoneVector[client][0] -= 5.0;
				}
				else SecondZoneVector[client][0] -= 5.0;
			}
			else if (StrEqual(info, "sy", false))
			{
				// Subtract from the y axis
				if (EditingVector[client] == FIRST_VECTOR)
				{
					FirstZoneVector[client][1] -= 5.0;
				}
				else SecondZoneVector[client][1] -= 5.0;
			}
			else if (StrEqual(info, "sz", false))
			{
				// Subtract from the z axis
				if (EditingVector[client] == FIRST_VECTOR)
				{
					FirstZoneVector[client][2] -= 5.0;
				}
				else SecondZoneVector[client][2] -= 5.0;
			}

			// Always show a zone box on every selection
			TE_SendBeamBoxToClient(client, FirstZoneVector[client], SecondZoneVector[client], LaserMaterial, HaloMaterial, 0, 30, LIFETIME_INTERVAL, 5.0, 5.0, 2, 1.0, TeamColors[team], 0);

			// Highlight the currently edited edge for players editing a zone
			if (EditingVector[client] == FIRST_VECTOR)
			{
				TE_SetupGlowSprite(FirstZoneVector[client], GlowSprite, LIFETIME_INTERVAL, 1.0, 100);
				TE_SendToClient(client);
			}
			else //if (EditingVector[client] == SECOND_VECTOR)
			{
				TE_SetupGlowSprite(SecondZoneVector[client], GlowSprite, LIFETIME_INTERVAL, 1.0, 100);
				TE_SendToClient(client);
			}

			if (!StrEqual(info, "back", false))
			{
				// Redisplay the menu if no 'back' button were pressed
				ShowZoneVectorEditMenu(client);
			}
			else ShowZoneOptionsMenu(client); // Otherwise go into main menu
		}
		case MenuAction_Cancel:
		{
			// When player is presset 'back' button
			if (param == MenuCancel_ExitBack)
			{
				// Redraw zone options menu
				ShowZoneOptionsMenu(client);
			}
			else EditingZone[client] = INIT; // When player just pressed Exit button, make sure player is not editing any zone anymore
		}
		case MenuAction_End: CloseHandle(menu);
	}
}


/* ShowSaveZoneMenu()
 *
 * Creates a menu handler to save or discard new zone.
 * -------------------------------------------------------------------------- */
ShowSaveZoneMenu(client, const String:name[])
{
	decl String:translation[128];

	// Confirm the new zone after naming
	new Handle:menu = CreateMenu(Menu_SaveZone);
	SetMenuTitle(menu, "%T", "Adding Zone", client);

	// Add 2 options to menu - Save & Discard
	Format(translation, sizeof(translation), "%T", "Save", client);
	AddMenuItem(menu, name, translation);
	Format(translation, sizeof(translation), "%T", "Discard", client);
	AddMenuItem(menu, "discard", translation);

	// Dont show 'Exit' button here
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

/* Menu_SaveZone()
 *
 * Menu handler to save new created zone.
 * -------------------------------------------------------------------------- */
public Menu_SaveZone(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:info[MAX_ZONE_LENGTH];
			GetMenuItem(menu, param, info, sizeof(info));

			// Don't save the new zone if player pressed 'Discard' option
			if (StrEqual(info, "discard", false))
			{
				// Clear vectors
				ClearVector(FirstZoneVector[client]);
				ClearVector(SecondZoneVector[client]);

				// Notify player
				PrintToChat(client, "%s%t", PREFIX, "Discarded");
			}
			else // Save the new zone, because any other item is selected
			{
				// Save new zone in config
				decl String:config[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, config, sizeof(config), "data/zones/%s.cfg", map);

				// Get "Zones" config
				new Handle:kv = CreateKeyValues("Zones"), number;
				FileToKeyValues(kv, config);

				decl String:buffer[MAX_ZONE_LENGTH], String:strnum[8], temp;
				if (KvGotoFirstSubKey(kv))
				{
					do
					{
						// Get the highest numer and increase it by 1
						KvGetSectionName(kv, buffer, sizeof(buffer));
						temp = StringToInt(buffer);

						// Saving every zone as a number is faster and safer
						if (temp >= number)
						{
							// Set another increased number for zone in config
							number = ++temp;
						}

						// Oops there is already a zone with this name
						KvGetString(kv, "zone_ident", buffer, sizeof(buffer));
						if (StrEqual(buffer, info, false))
						{
							// Notify player about that and hook say/say_team callbacks to allow player to give new name
							PrintToChat(client, "%s%t", PREFIX, "Name Already Taken", info);
							NamesZone[client] = true;
							return;
						}
					}
					while (KvGotoNextKey(kv));
					KvGoBack(kv);
				}

				// Convert number to a string (we're dealing with KV)
				IntToString(number, strnum, sizeof(strnum));

				// Jump to zone number
				KvJumpToKey(kv, strnum, true);

				// Set name and coordinates
				KvSetString(kv, "zone_ident",    info);
				KvSetVector(kv, "coordinates 1", FirstZoneVector[client]);
				KvSetVector(kv, "coordinates 2", SecondZoneVector[client]);

				// Get back to the top, save config and close KV handle again
				KvRewind(kv);
				KeyValuesToFile(kv, config);
				CloseHandle(kv);

				// Store the current vectors to the array
				new Handle:TempArray = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));

				// Set the name
				PushArrayString(TempArray, info);

				// Set the first coordinates
				PushArrayArray(TempArray, FirstZoneVector[client], VECTORS_SIZE);

				// Set the second coordinates
				PushArrayArray(TempArray, SecondZoneVector[client], VECTORS_SIZE);

				// Set the team to both by default
				PushArrayCell(TempArray, CS_TEAM_NONE);

				// Set the zones_punishment to default (defined by ConVar)
				PushArrayCell(TempArray, INIT);

				// Set editing zone for a player
				EditingZone[client] = PushArrayCell(ZonesArray, TempArray);

				// Spawn the trigger_multiple entity (zone)
				SpawnZone(EditingZone[client]);

				// Notify client about successfull saving
				PrintToChat(client, "%s%t", PREFIX, "Saved");

				// Show edit zone options for client
				ShowZoneOptionsMenu(client);
			}
		}
		case MenuAction_Cancel:
		{
			// When menu is ended - reset everything
			EditingZone[client] = EditingVector[client] = INIT;

			ClearVector(FirstZoneVector[client]);
			ClearVector(SecondZoneVector[client]);

			if (param == MenuCancel_ExitBack)
			{
				// If player pressed back button, show active zones menu (again)
				ShowActiveZonesMenu(client);
			}
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

/* Panel_Confirmation()
 *
 * Panel handler to confirm zone deletion.
 * -------------------------------------------------------------------------- */
public Panel_Confirmation(Handle:menu, MenuAction:action, client, param)
{
	// Client pressed a button
	if (action == MenuAction_Select)
	{
		// 'Yes' - so delete zone
		if (param == 1)
		{
			// Kill the trigger_multiple entity (a box)
			KillZone(EditingZone[client]);

			// Delete from cache array
			decl String:ZoneName[MAX_ZONE_LENGTH];
			new Handle:hZone = GetArrayCell(ZonesArray, EditingZone[client]);

			// Close array handle
			GetArrayString(hZone, ZONE_NAME, ZoneName, sizeof(ZoneName));
			CloseHandle(hZone);

			// Remove info from array
			RemoveFromArray(ZonesArray, EditingZone[client]);

			// Reset edited zone appropriately
			EditingZone[client] = INIT;

			// Delete zone from config file
			decl String:config[PLATFORM_MAX_PATH];
			BuildPath(Path_SM, config, sizeof(config), "data/zones/%s.cfg", map);

			new Handle:kv = CreateKeyValues("Zones");
			FileToKeyValues(kv, config);
			if (!KvGotoFirstSubKey(kv))
			{
				// Something was wrong - stop and draw active zones again
				CloseHandle(kv);
				ShowActiveZonesMenu(client);
				return;
			}

			decl String:buffer[MAX_ZONE_LENGTH];
			KvGetSectionName(kv, buffer, sizeof(buffer));
			do
			{
				// Compare zone names
				KvGetString(kv, "zone_ident", buffer, sizeof(buffer));
				if (StrEqual(buffer, ZoneName, false))
				{
					// Delete the whole zone section on match
					KvDeleteThis(kv);
					break;
				}
			}
			while (KvGotoNextKey(kv));

			KvRewind(kv);
			KeyValuesToFile(kv, config);
			CloseHandle(kv);

			// Notify client and show active zones menu
			PrintToChat(client, "%s%t", PREFIX, "Deleted Zone", ZoneName);
			ShowActiveZonesMenu(client);
		}
		else
		{
			// Player pressed 'No' button - cancel deletion and redraw previous menu
			PrintToChat(client, "%s%t", PREFIX, "Canceled Zone Deletion");
			ShowZoneOptionsMenu(client);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// Cancel deletion if menu was closed
		PrintToChat(client, "%s%t", PREFIX, "Canceled Zone Deletion");

		ShowZoneOptionsMenu(client);
	}

	// Since its just a panel - no need to check MenuAction_End action to close handle
}


/**
 * --------------------------------------------------------------------------
 *      ______                  __  _
 *     / ____/__  ______  _____/ /_(_)____  ____  _____
 *    / /_   / / / / __ \/ ___/ __/ // __ \/ __ \/ ___/
 *   / __/  / /_/ / / / / /__/ /_/ // /_/ / / / (__  )
 *  /_/     \__,_/_/ /_/\___/\__/_/ \____/_/ /_/____/
 *
 * --------------------------------------------------------------------------
*/

/* Timer_ShowZones()
 *
 * Repeatable timer to redraw zones on a map.
 * -------------------------------------------------------------------------- */
public Action:Timer_ShowZones(Handle:timer)
{
	// Do the stuff if plugin is enabled
	if (GetConVarBool(zones_enabled))
	{
		// Get all zones
		for (new i; i < GetArraySize(ZonesArray); i++)
		{
			// Initialize positions, team index and other stuff
			decl Float:pos1[3], Float:pos2[3], team, client;
			new Handle:hZone = GetArrayCell(ZonesArray, i);

			// Retrieve positions from array
			GetArrayArray(hZone, FIRST_VECTOR,  pos1, VECTORS_SIZE);
			GetArrayArray(hZone, SECOND_VECTOR, pos2, VECTORS_SIZE);

			// Get team
			team = GetArrayCell(hZone, ZONE_TEAM);

			// Loop through all clients
			for (client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
				{
					// If player is editing a zones - show all zones then
					if (EditingZone[client] != INIT)
					{
						TE_SendBeamBoxToClient(client, pos1, pos2, LaserMaterial, HaloMaterial, 0, 30, LIFETIME_INTERVAL, 5.0, 5.0, 2, 1.0, TeamColors[team], 0);
					}

					// Otherwise always show zones if plugin is set it to true
					else if (GetConVarBool(show_zones) && (team == CS_TEAM_NONE || (GetClientTeam(client) == team)))
					{
						// Also dont show friendly zones at all
						TE_SendBeamBoxToClient(client, pos1, pos2, LaserMaterial, HaloMaterial, 0, 30, LIFETIME_INTERVAL, 5.0, 5.0, 2, 1.0, TeamColors[team], 0);
					}
				}
			}
		}
	}
}

/* ParseZoneConfig()
 *
 * Prepares a zones config at every map change.
 * -------------------------------------------------------------------------- */
ParseZoneConfig()
{
	// Clear previous info
	CloseHandleArray(ZonesArray);
	ClearArray(ZonesArray);

	// Get the config
	decl String:config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "data/zones/%s.cfg", map);

	if (FileExists(config))
	{
		// Load config for this map if exists
		new Handle:kv = CreateKeyValues("Zones");
		FileToKeyValues(kv, config);
		if (!KvGotoFirstSubKey(kv))
		{
			CloseHandle(kv);
			return;
		}

		// Initialize everything, also get the section names
		decl String:buffer[MAX_ZONE_LENGTH], Float:vector[3], zoneIndex, real_punishment;
		KvGetSectionName(kv, buffer, sizeof(buffer));

		// Go through config for this map
		do
		{
			// Create temporary array
			new Handle:TempArray = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));

			// Retrieve zone name, and push name into temp array
			KvGetString(kv, "zone_ident", buffer, sizeof(buffer));
			PushArrayString(TempArray, buffer);

			// Get first coordinations
			KvGetVector(kv, "coordinates 1", vector);
			PushArrayArray(TempArray, vector, VECTORS_SIZE);

			// Second coordinations
			KvGetVector(kv, "coordinates 2", vector);
			PushArrayArray(TempArray, vector, VECTORS_SIZE);

			// Get the team restrictions
			new team = KvGetNum(kv, "restrict_team", CS_TEAM_NONE);
			PushArrayCell(TempArray, team);

			// Increase zone count on match
			switch(team)
			{
				// For both teams
				case CS_TEAM_NONE:
				{
					TeamZones[CS_TEAM_T]++;
					TeamZones[CS_TEAM_CT]++;
				}
				case CS_TEAM_T:  TeamZones[CS_TEAM_T]++;
				case CS_TEAM_CT: TeamZones[CS_TEAM_CT]++;
			}

			// Get the punishments
			real_punishment = KvGetNum(kv, "punishment", INIT);

			// Add punishments into temporary array
			PushArrayCell(TempArray, real_punishment);

			// Get the zone index
			zoneIndex = PushArrayCell(ZonesArray, TempArray);

			// Spawn a zone each time KV got a config for
			SpawnZone(zoneIndex);
		}

		// Until keyvalues config is ended
		while (KvGotoNextKey(kv));

		// Get back to the top
		KvGoBack(kv);

		// And close KeyValues handler
		CloseHandle(kv);
	}
}

/* ActivateZone()
 *
 * Activates an inactive zone by name.
 * -------------------------------------------------------------------------- */
ActivateZone(const String:text[])
{
	// Make sure at least one zone entity is exists
	decl String:class[MAX_ZONE_LENGTH+9], zone; zone = INIT;
	while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != INIT)
	{
		if (IsValidEdict(zone)
		&& GetEntPropString(zone, Prop_Data, "m_iName", class, sizeof(class))
		&& StrEqual(class[8], text, false)) // Skip first 8 characters to avoid comparing with 'sm_zone' prefix
		{
			// Found - activate a zone and break the loop (optimizations)
			AcceptEntityInput(zone, "Enable");
			break;
		}
	}
}

/* DiactivateZone()
 *
 * Diactivates a zone by name.
 * -------------------------------------------------------------------------- */
DiactivateZone(const String:text[])
{
	decl String:class[MAX_ZONE_LENGTH+9], zone; zone = INIT;
	while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != INIT)
	{
		if (IsValidEdict(zone)
		&& GetEntPropString(zone, Prop_Data, "m_iName", class, sizeof(class))
		&& StrEqual(class[8], text, false))
		{
			// Retrieve names of every entity, and if name contains "sm_zone" text - just disable this entity
			AcceptEntityInput(zone, "Disable");
			break;
		}
	}
}

/* SpawnZone()
 *
 * Spawns a trigger_multiple entity (zone)
 * -------------------------------------------------------------------------- */
SpawnZone(zoneIndex)
{
	decl Float:middle[3], Float:m_vecMins[3], Float:m_vecMaxs[3], String:ZoneName[MAX_ZONE_LENGTH+9];

	// Get zone index from array
	new Handle:hZone = GetArrayCell(ZonesArray, zoneIndex);
	GetArrayArray(hZone,  FIRST_VECTOR,  m_vecMins, VECTORS_SIZE);
	GetArrayArray(hZone,  SECOND_VECTOR, m_vecMaxs, VECTORS_SIZE);
	GetArrayString(hZone, ZONE_NAME,     ZoneName, sizeof(ZoneName));

	// Create a zone (best entity for that is trigger_multiple)
	new zone = CreateEntityByName("trigger_multiple");

	// Set name
	Format(ZoneName, sizeof(ZoneName), "sm_zone %s", ZoneName);
	DispatchKeyValue(zone, "targetname", ZoneName);
	DispatchKeyValue(zone, "spawnflags", "64");
	DispatchKeyValue(zone, "wait",       "0");

	// Spawn an entity
	DispatchSpawn(zone);

	// Since its brush entity, use ActivateEntity as well
	ActivateEntity(zone);

	// Set datamap spawnflags (value means copy origin and angles)
	SetEntProp(zone, Prop_Data, "m_spawnflags", 64);

	// Get the middle of zone
	GetMiddleOfABox(m_vecMins, m_vecMaxs, middle);

	// Move zone entity in middle of a box
	TeleportEntity(zone, middle, NULL_VECTOR, NULL_VECTOR);

	// Set the model (yea, its also required for brush model)
	SetEntityModel(zone, ZONES_MODEL);

	// Have the m_vecMins always be negative
	m_vecMins[0] = m_vecMins[0] - middle[0];
	if (m_vecMins[0] > 0.0)
		m_vecMins[0] *= -1.0;
	m_vecMins[1] = m_vecMins[1] - middle[1];
	if (m_vecMins[1] > 0.0)
		m_vecMins[1] *= -1.0;
	m_vecMins[2] = m_vecMins[2] - middle[2];
	if (m_vecMins[2] > 0.0)
		m_vecMins[2] *= -1.0;

	// And the m_vecMaxs always be positive
	m_vecMaxs[0] = m_vecMaxs[0] - middle[0];
	if (m_vecMaxs[0] < 0.0)
		m_vecMaxs[0] *= -1.0;
	m_vecMaxs[1] = m_vecMaxs[1] - middle[1];
	if (m_vecMaxs[1] < 0.0)
		m_vecMaxs[1] *= -1.0;
	m_vecMaxs[2] = m_vecMaxs[2] - middle[2];
	if (m_vecMaxs[2] < 0.0)
		m_vecMaxs[2] *= -1.0;

	// Set mins and maxs for entity
	SetEntPropVector(zone, Prop_Send, "m_vecMins", m_vecMins);
	SetEntPropVector(zone, Prop_Send, "m_vecMaxs", m_vecMaxs);

	// Enable touch functions and set it as non-solid for everything
	SetEntProp(zone, Prop_Send, "m_usSolidFlags",  152);
	SetEntProp(zone, Prop_Send, "m_CollisionGroup", 11);

	// Make the zone visible by removing EF_NODRAW flag
	new m_fEffects = GetEntProp(zone, Prop_Send, "m_fEffects");
	m_fEffects |= 0x020;
	SetEntProp(zone, Prop_Send, "m_fEffects", m_fEffects);

	// Hook touch entity outputs
	HookSingleEntityOutput(zone, "OnStartTouch", OnTouch);
	HookSingleEntityOutput(zone, "OnEndTouch",   OnTouch);
}

/* KillZone()
 *
 * Removes a trigger_multiple entity (zone) from a world.
 * -------------------------------------------------------------------------- */
KillZone(zoneIndex)
{
	decl String:ZoneName[MAX_ZONE_LENGTH], String:class[MAX_ZONE_LENGTH+9], zone;

	// Get the zone index and name of a zone
	new Handle:hZone = GetArrayCell(ZonesArray, zoneIndex);
	GetArrayString(hZone, ZONE_NAME, ZoneName, sizeof(ZoneName));

	zone = INIT;
	while ((zone = FindEntityByClassname(zone, "trigger_multiple")) != INIT)
	{
		if (IsValidEdict(zone)
		&& GetEntPropString(zone, Prop_Data, "m_iName", class, sizeof(class)) // Get m_iName datamap
		&& StrEqual(class[8], ZoneName, false)) // And check if m_iName is equal to name from array
		{
			// Unhook touch callback, kill an entity and break the loop
			UnhookSingleEntityOutput(zone, "OnStartTouch", OnTouch);
			UnhookSingleEntityOutput(zone, "OnEndTouch",   OnTouch);
			AcceptEntityInput(zone, "Kill");
			break;
		}
	}
}

/**
 * --------------------------------------------------------------------------
 *      __  ___
 *     /  |/  (_)__________
 *    / /|_/ / // ___/ ___/
 *   / /  / / /(__  ) /__
 *  /_/  /_/_//____/\___/
 *
 * --------------------------------------------------------------------------
*/

/* CloseHandleArray()
 *
 * Closes active adt_array handles.
 * -------------------------------------------------------------------------- */
CloseHandleArray(Handle:adt_array)
{
	// Loop through all array handles
	for (new i; i < GetArraySize(adt_array); i++)
	{
		// Retrieve cell value from array, and close it
		new Handle:hZone = GetArrayCell(adt_array, i);
		CloseHandle(hZone);
	}
}

/* ClearVector()
 *
 * Resets vector to 0.0
 * -------------------------------------------------------------------------- */
ClearVector(Float:vec[3])
{
	vec[0] = vec[1] = vec[2] = 0.0;
}

/* IsVectorZero()
 *
 * SourceMod Anti-Cheat stock.
 * -------------------------------------------------------------------------- */
bool:IsVectorZero(const Float:vec[3])
{
	return vec[0] == 0.0 && vec[1] == 0.0 && vec[2] == 0.0;
}

/* GetMiddleOfABox()
 *
 * Retrieves a real center of zone box.
 * -------------------------------------------------------------------------- */
GetMiddleOfABox(const Float:vec1[3], const Float:vec2[3], Float:buffer[3])
{
	// Just make vector from points and half-divide it
	decl Float:mid[3];
	MakeVectorFromPoints(vec1, vec2, mid);
	mid[0] = mid[0] / 2.0;
	mid[1] = mid[1] / 2.0;
	mid[2] = mid[2] / 2.0;
	AddVectors(vec1, mid, buffer);
}

/**
 * Sets up a boxed beam effect.
 *
 * Ported from eventscripts vecmath library
 *
 * @param client		The client to show the box to.
 * @param upc			One upper corner of the box.
 * @param btc			One bottom corner of the box.
 * @param ModelIndex	Precached model index.
 * @param HaloIndex		Precached model index.
 * @param StartFrame	Initital frame to render.
 * @param FrameRate		Beam frame rate.
 * @param Life			Time duration of the beam.
 * @param Width			Initial beam width.
 * @param EndWidth		Final beam width.
 * @param FadeLength	Beam fade time duration.
 * @param Amplitude		Beam amplitude.
 * @param color			Color array (r, g, b, a).
 * @param Speed			Speed of the beam.
 * @noreturn
  * -------------------------------------------------------------------------- */
TE_SendBeamBoxToClient(client, const Float:upc[3], const Float:btc[3], ModelIndex, HaloIndex, StartFrame, FrameRate, const Float:Life, const Float:Width, const Float:EndWidth, FadeLength, const Float:Amplitude, const Color[4], Speed)
{
	// Create the additional corners of the box
	decl Float:tc1[] = {0.0, 0.0, 0.0};
	decl Float:tc2[] = {0.0, 0.0, 0.0};
	decl Float:tc3[] = {0.0, 0.0, 0.0};
	decl Float:tc4[] = {0.0, 0.0, 0.0};
	decl Float:tc5[] = {0.0, 0.0, 0.0};
	decl Float:tc6[] = {0.0, 0.0, 0.0};

	AddVectors(tc1, upc, tc1);
	AddVectors(tc2, upc, tc2);
	AddVectors(tc3, upc, tc3);
	AddVectors(tc4, btc, tc4);
	AddVectors(tc5, btc, tc5);
	AddVectors(tc6, btc, tc6);

	tc1[0] = btc[0];
	tc2[1] = btc[1];
	tc3[2] = btc[2];
	tc4[0] = upc[0];
	tc5[1] = upc[1];
	tc6[2] = upc[2];

	// Draw all the edges
	TE_SetupBeamPoints(upc, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(upc, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(upc, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc6, btc, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, btc, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, btc, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, tc1, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc5, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, tc3, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
	TE_SetupBeamPoints(tc4, tc2, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed);
	TE_SendToClient(client);
}

/* FindSendPropOffsEx()
 *
 * Returns the offset of the specified network property.
 * --------------------------------------------------------------------------- */
FindSendPropOffsEx(const String:serverClass[64], const String:propName[64])
{
	new offset = FindSendPropOffs(serverClass, propName);

	// Disable plugin if a networkable send property offset was not found
	if (offset <= 0)
	{
		SetFailState("Unable to find offset: \"%s::%s\"!", serverClass, propName);
	}

	return offset;
}