/*
Plugun updated for Left 4 Dead 2
Updated Daily, Tested 24/7 At
Sky's 18 VS - Hostedgameservers.com 174.142.98.77:37015

Author_Sky
mikel.toth@gmail.com

Credits:
Damizean - Created the first loot plugin.
Thraka - For the update this version was adapted from.

Version Update:

1.4.3
Fixed Bug that was causing plugin to sometimes allow
1 more than set limit of active tanks/round, due to
inaccurate recording of tanks spawned by this plugin.

1.4.2
Added Boss Restriction Support for
Tank and Witch.

New ConVars:
l4d_loot_witch_max 3 		// max witches alive/any time.
l4d_loot_witch_map_max 10 	// max witches/spawned per round.
l4d_loot_tank_max 1 		// max tanks alive/any time.
l4d_loot_tank_map_max 5 	// max tanks/spawned per round.
l4d_loot_panic_map_max 15	// max panic events per round.

l4d_loot_hunter_military_min 26
l4d_loot_hunter_military_max 30
l4d_loot_hunter_ak47_min 27
l4d_loot_hunter_ak47_max 32
l4d_loot_hunter_defibrillator_min 31
l4d_loot_hunter_defibrillator_max 35
l4d_loot_hunter_magnum_min 34
l4d_loot_hunter_magnum_max 40
l4d_loot_hunter_spas_min 37
l4d_loot_hunter_spas_max 43
l4d_loot_hunter_melee_min 40
l4d_loot_hunter_melee_max 46
l4d_loot_hunter_desert_min 43
l4d_loot_hunter_desert_max 47
l4d_loot_hunter_chainsaw_min 0
l4d_loot_hunter_chainsaw_max 0
l4d_loot_hunter_explosive_min 43
l4d_loot_hunter_explosive_max 49
l4d_loot_hunter_incendiary_min 45
l4d_loot_hunter_incendiary_max 50
l4d_loot_hunter_adrenaline_min 40
l4d_loot_hunter_adrenaline_max 50
l4d_loot_hunter_vomitjar_min 49
l4d_loot_hunter_vomitjar_max 50

(Repeat for all 8 classes)
(hunter,smoker,boomer,spitter,charger,jockey,witch,tank)
(Default Values)

1.4.1
Added Support for Left 4 Dead 2 items
and guns from North American release.
*/

#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY
#define PLUGIN_VERSION "1.4"

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_WITCH 7
#define ZOMBIECLASS_TANK 8

#define LOOT_DIENUMBER 	0
#define LOOT_DIECOUNT 1
#define LOOT_ITEM_COUNT	2

#define LOOT_KIT_MIN 3
#define LOOT_KIT_MAX 4
#define LOOT_PILLS_MIN 5
#define LOOT_PILLS_MAX 6
#define LOOT_MOLLY_MIN 7
#define LOOT_MOLLY_MAX 8
#define LOOT_PIPE_MIN 9
#define LOOT_PIPE_MAX 10

#define LOOT_PANIC_MIN 11
#define LOOT_PANIC_MAX 12
#define LOOT_TANK_MIN 13
#define LOOT_TANK_MAX 14
#define LOOT_WITCH_MIN 15
#define LOOT_WITCH_MAX 16
#define LOOT_COMMON_MIN	17
#define LOOT_COMMON_MAX	18

#define LOOT_PISTOL_MIN	19
#define LOOT_PISTOL_MAX	20
#define LOOT_SMG_MIN 21
#define LOOT_SMG_MAX 22
#define LOOT_SHOT_MIN 23
#define LOOT_SHOT_MAX 24
#define LOOT_RIFLE_MIN 25
#define LOOT_RIFLE_MAX 26
#define LOOT_AUTOSHOT_MIN 27
#define LOOT_AUTOSHOT_MAX 28
#define LOOT_SNIPER_MIN	29
#define LOOT_SNIPER_MAX	30
#define LOOT_MILITARY_MIN 31
#define LOOT_MILITARY_MAX 32
#define LOOT_AK47_MIN 33
#define LOOT_AK47_MAX 34
#define LOOT_DEFIBRILLATOR_MIN 35
#define LOOT_DEFIBRILLATOR_MAX 36
#define LOOT_MAGNUM_MIN	37
#define LOOT_MAGNUM_MAX 38
#define LOOT_SPAS_MIN 39
#define LOOT_SPAS_MAX 40
#define LOOT_MELEE_MIN 41
#define LOOT_MELEE_MAX 42
#define LOOT_DESERT_MIN	43
#define LOOT_DESERT_MAX 44
#define LOOT_CHAINSAW_MIN 45
#define LOOT_CHAINSAW_MAX 46
#define LOOT_EXPLOSIVE_MIN 47
#define LOOT_EXPLOSIVE_MAX 48
#define LOOT_INCENDIARY_MIN 49
#define LOOT_INCENDIARY_MAX 50
#define LOOT_ADRENALINE_MIN 51
#define LOOT_ADRENALINE_MAX 52
#define LOOT_VOMITJAR_MIN 53
#define LOOT_VOMITJAR_MAX 54

public Plugin myinfo = 
{
	name = "[L4D2] Infected Loot",
	author = "Sky",
	description = "L4D2 Random Infected Loot Drop System",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/groups/skyservers"
}

ConVar CVarIsEnabled;
ConVar CVarDieSides[4];

ConVar CVarHunterLoot[55];
ConVar CVarBoomerLoot[55];
ConVar CVarSmokerLoot[55];
ConVar CVarTankLoot[55];
ConVar CVarSpitterLoot[55];
ConVar CVarChargerLoot[55];
ConVar CVarJockeyLoot[55];
ConVar CVarWitchLoot[55];

ConVar tankMax;
ConVar witchMax;
ConVar witchMapMax;
ConVar tankMapMax;
ConVar panicMax;

int numTank = 0;
int numTankMax = 0;
int tankSpawn = 0;
int numWitch = 0;
int numWitchMax = 0;
int witchSpawn = 0;
int numPanic = 0;

int HunterLoot[55];
int BoomerLoot[55];
int SmokerLoot[55];
int SpitterLoot[55];
int ChargerLoot[55];
int JockeyLoot[55];
int TankLoot[55];
int WitchLoot[55];

int Dice[4];

public void OnPluginStart()
{
	SetRandomSeed(GetSysTickCount());

	CreateConVar("l4d2_loot_ver", PLUGIN_VERSION, "Version of the infected loot drops plugins.", CVAR_FLAGS|FCVAR_DONTRECORD);

	CVarIsEnabled = CreateConVar("l4d_loot_enabled", "1", "Is the plugin enabled.");
	CVarIsEnabled.AddChangeHook(Loot_EnableDisable);

	HookEvent("round_start", Event_RoundStart); // Allow tank, witch, panic limit/round.
	
	tankMax = CreateConVar("l4d_loot_tank_max","1","Number of tanks allowed to spawn/live at a time/round.", CVAR_FLAGS, true, 0.0);
	witchMax = CreateConVar("l4d_loot_witch_max","3","Number of witches allowed to spawn/live at a time/round.", CVAR_FLAGS, true, 0.0);
	tankMapMax = CreateConVar("l4d_loot_tank_map_max","5","Total Number of Tanks plugin can spawn per map.", CVAR_FLAGS, true, 0.0);
	witchMapMax = CreateConVar("l4d_loot_witch_map_max","10","Total Number of Witches plugin can spawn per map.", CVAR_FLAGS, true, 0.0);
	panicMax = CreateConVar("l4d_loot_panic_map_max","15","Total Number of Witches plugin can spawn per map.", CVAR_FLAGS, true, 0.0);

	CVarDieSides[0] = CreateConVar("l4d_loot_dice1_sides", "50", "How many sides die 1 has.", CVAR_FLAGS);
	CVarDieSides[1] = CreateConVar("l4d_loot_dice2_sides", "50", "How many sides die 2 has.", CVAR_FLAGS);
	CVarDieSides[2] = CreateConVar("l4d_loot_dice3_sides", "40", "How many sides die 3 has.", CVAR_FLAGS);
	CVarDieSides[3] = CreateConVar("l4d_loot_dice4_sides", "100", "How many sides die 4 has.", CVAR_FLAGS);
		
	CVarHunterLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_hunter_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", CVAR_FLAGS, true, 1.0, true, 4.0);
	CVarHunterLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_hunter_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", CVAR_FLAGS, true, 1.0, true, 3.0);
	CVarHunterLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_hunter_item_count", "3", "How many items are rolled for when the witch dies.", CVAR_FLAGS, true, 0.0);	
	
	CVarHunterLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_hunter_kit_min", "1", "Min die number for a hunter to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_hunter_kit_max", "3", "Max die number for a hunter to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_hunter_pills_min",	"3", "Min die number for a hunter to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_hunter_pills_max",	"8", "Max die number for a hunter to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_hunter_molly_min",	"5", "Min die number for a hunter to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_hunter_molly_max",	"10", "Max die number for a hunter to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_hunter_pipe_min", "7", "Min die number for a hunter to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_hunter_pipe_max", "10", "Max die number for a hunter to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	
	CVarHunterLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_hunter_panic_min",	"10", "Min die number for a hunter to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_hunter_panic_max",	"13", "Max die number for a hunter to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_hunter_tankspawn_min",	"13", "Min die number for a hunter to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_hunter_tankspawn_max",	"14", "Max die number for a hunter to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_hunter_witchspawn_min", "13", "Min die number for a hunter to cause a hunter to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_hunter_witchspawn_max", "19", "Max die number for a hunter to cause a hunter to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_hunter_common_min", "15", "Min die number for a hunter to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_hunter_common_max", "25", "Max die number for a hunter to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	
	CVarHunterLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_hunter_pistol_min", "21", 	"Min die number for a hunter to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_hunter_pistol_max", "40", 	"Max die number for a hunter to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_hunter_smg_min", "22", "Min die number for a hunter to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_hunter_smg_max", "35", "Max die number for a hunter to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_hunter_shotgun_min", "23", "Min die number for a hunter to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_hunter_shotgun_max", "40", "Max die number for a hunter to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_hunter_rifle_min",	"24", "Min die number for a hunter to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_hunter_rifle_max",	"26", "Max die number for a hunter to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_hunter_autoshot_min", "24", "Min die number for a hunter to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_hunter_autoshot_max", "28", "Max die number for a hunter to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_hunter_sniper_min", "25", "Min die number for a hunter to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_hunter_sniper_max", "28", "Max die number for a hunter to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);	

	CVarHunterLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_hunter_military_min", "26", "Min die number for a hunter to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_hunter_military_max", "30", "Max die number for a hunter to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_hunter_ak47_min", "27", "Min die number for a hunter to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_hunter_ak47_max", "32", "Max die number for a hunter to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_hunter_defibrillator_min", "31", "Min die number for a hunter to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_hunter_defibrillator_max", "35", "Max die number for a hunter to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_hunter_magnum_min", "34", "Min die number for a hunter to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_hunter_magnum_max", "40", "Max die number for a hunter to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_hunter_spas_min", "37", "Min die number for a hunter to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_hunter_spas_max", "43", "Max die number for a hunter to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_hunter_melee_min", "40", "Min die number for a hunter to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_hunter_melee_max", "46", "Max die number for a hunter to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_hunter_desert_min", "43", "Min die number for a hunter to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_hunter_desert_max", "47", "Max die number for a hunter to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_hunter_chainsaw_min", "0", "Min die number for a hunter to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_hunter_chainsaw_max", "0", "Max die number for a hunter to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_hunter_explosive_min", "46", "Min die number for a hunter to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_hunter_explosive_max", "49", "Max die number for a hunter to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_hunter_incendiary_min", "48", "Min die number for a hunter to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_hunter_incendiary_max", "50", "Max die number for a hunter to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_hunter_adrenaline_min", "40", "Min die number for a hunter to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_hunter_adrenaline_max", "50", "Max die number for a hunter to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_hunter_vomitjar_min", "49", "Min die number for a hunter to drop a vomitjar.", CVAR_FLAGS, true, 0.0);
	CVarHunterLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_hunter_vomitjar_max", "50", "Max die number for a hunter to drop a vomitjar.", CVAR_FLAGS, true, 0.0);

	CVarBoomerLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_boomer_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", CVAR_FLAGS, true, 1.0, true, 4.0);
	CVarBoomerLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_boomer_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", CVAR_FLAGS, true, 1.0, true, 3.0);
	CVarBoomerLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_boomer_item_count", "3", "How many items are rolled for when the witch dies.", CVAR_FLAGS, true, 0.0);	
	
	CVarBoomerLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_boomer_kit_min", "1", "Min die number for a boomer to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_boomer_kit_max", "3", "Max die number for a boomer to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_boomer_pills_min",	"2", "Min die number for a boomer to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_boomer_pills_max",	"6", "Max die number for a boomer to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_boomer_molly_min",	"5", "Min die number for a boomer to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_boomer_molly_max",	"11", "Max die number for a boomer to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_boomer_pipe_min", "7", "Min die number for a boomer to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_boomer_pipe_max", "15", "Max die number for a boomer to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	
	CVarBoomerLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_boomer_panic_min",	"10", "Min die number for a boomer to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_boomer_panic_max",	"13", "Max die number for a boomer to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_boomer_tankspawn_min",	"12", "Min die number for a boomer to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_boomer_tankspawn_max",	"13", "Max die number for a boomer to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_boomer_witchspawn_min", "14", "Min die number for a boomer to cause a boomer to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_boomer_witchspawn_max", "18", "Max die number for a boomer to cause a boomer to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_boomer_common_min", "15", "Min die number for a boomer to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_boomer_common_max", "25", "Max die number for a boomer to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	
	CVarBoomerLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_boomer_pistol_min", "21", 	"Min die number for a boomer to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_boomer_pistol_max", "40", 	"Max die number for a boomer to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_boomer_smg_min", "22", "Min die number for a boomer to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_boomer_smg_max", "35", "Max die number for a boomer to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_boomer_shotgun_min", "23", "Min die number for a boomer to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_boomer_shotgun_max", "40", "Max die number for a boomer to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_boomer_rifle_min",	"24", "Min die number for a boomer to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_boomer_rifle_max",	"30", "Max die number for a boomer to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_boomer_autoshot_min", "25", "Min die number for a boomer to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_boomer_autoshot_max", "28", "Max die number for a boomer to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_boomer_sniper_min", "26", "Min die number for a boomer to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_boomer_sniper_max", "30", "Max die number for a boomer to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);	

	CVarBoomerLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_boomer_military_min", "29", "Min die number for a boomer to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_boomer_military_max", "32", "Max die number for a boomer to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_boomer_ak47_min", "31", "Min die number for a boomer to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_boomer_ak47_max", "35", "Max die number for a boomer to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_boomer_defibrillator_min", "33", "Min die number for a boomer to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_boomer_defibrillator_max", "36", "Max die number for a boomer to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_boomer_magnum_min", "34", "Min die number for a boomer to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_boomer_magnum_max", "41", "Max die number for a boomer to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_boomer_spas_min", "41", "Min die number for a boomer to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_boomer_spas_max", "46", "Max die number for a boomer to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_boomer_melee_min", "42", "Min die number for a boomer to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_boomer_melee_max", "47", "Max die number for a boomer to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_boomer_desert_min", "41", "Min die number for a boomer to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_boomer_desert_max", "45", "Max die number for a boomer to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_boomer_chainsaw_min", "0", "Min die number for a boomer to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_boomer_chainsaw_max", "0", "Max die number for a boomer to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_boomer_explosive_min", "40", "Min die number for a boomer to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_boomer_explosive_max", "49", "Max die number for a boomer to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_boomer_incendiary_min", "47", "Min die number for a boomer to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_boomer_incendiary_max", "49", "Max die number for a boomer to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_boomer_adrenaline_min", "47", "Min die number for a boomer to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_boomer_adrenaline_max", "50", "Max die number for a boomer to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_boomer_vomitjar_min", "40", "Min die number for a boomer to drop a vomitjar.", CVAR_FLAGS, true, 0.0);
	CVarBoomerLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_boomer_vomitjar_max", "50", "Max die number for a boomer to drop a vomitjar.", CVAR_FLAGS, true, 0.0);

	CVarSmokerLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_smoker_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", CVAR_FLAGS, true, 1.0, true, 4.0);
	CVarSmokerLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_smoker_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", CVAR_FLAGS, true, 1.0, true, 3.0);
	CVarSmokerLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_smoker_item_count", "3", "How many items are rolled for when the witch dies.", CVAR_FLAGS, true, 0.0);	
	
	CVarSmokerLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_smoker_kit_min", "1", "Min die number for a smoker to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_smoker_kit_max", "3", "Max die number for a smoker to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_smoker_pills_min",	"2", "Min die number for a smoker to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_smoker_pills_max",	"8", "Max die number for a smoker to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_smoker_molly_min",	"5", "Min die number for a smoker to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_smoker_molly_max",	"11", "Max die number for a smoker to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_smoker_pipe_min", "7", "Min die number for a smoker to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_smoker_pipe_max", "12", "Max die number for a smoker to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	
	CVarSmokerLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_smoker_panic_min",	"8", "Min die number for a smoker to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_smoker_panic_max",	"11", "Max die number for a smoker to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_smoker_tankspawn_min",	"12", "Min die number for a smoker to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_smoker_tankspawn_max",	"13", "Max die number for a smoker to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_smoker_witchspawn_min", "12", "Min die number for a smoker to cause a smoker to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_smoker_witchspawn_max", "16", "Max die number for a smoker to cause a smoker to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_smoker_common_min", "15", "Min die number for a smoker to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_smoker_common_max", "20", "Max die number for a smoker to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	
	CVarSmokerLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_smoker_pistol_min", "20", 	"Min die number for a smoker to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_smoker_pistol_max", "40", 	"Max die number for a smoker to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_smoker_smg_min", "22", "Min die number for a smoker to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_smoker_smg_max", "35", "Max die number for a smoker to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_smoker_shotgun_min", "23", "Min die number for a smoker to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_smoker_shotgun_max", "40", "Max die number for a smoker to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_smoker_rifle_min",	"24", "Min die number for a smoker to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_smoker_rifle_max",	"30", "Max die number for a smoker to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_smoker_autoshot_min", "25", "Min die number for a smoker to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_smoker_autoshot_max", "29", "Max die number for a smoker to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_smoker_sniper_min", "27", "Min die number for a smoker to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_smoker_sniper_max", "30", "Max die number for a smoker to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);	

	CVarSmokerLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_smoker_military_min", "29", "Min die number for a smoker to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_smoker_military_max", "35", "Max die number for a smoker to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_smoker_ak47_min", "28", "Min die number for a smoker to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_smoker_ak47_max", "34", "Max die number for a smoker to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_smoker_defibrillator_min", "32", "Min die number for a smoker to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_smoker_defibrillator_max", "36", "Max die number for a smoker to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_smoker_magnum_min", "33", "Min die number for a smoker to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_smoker_magnum_max", "38", "Max die number for a smoker to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_smoker_spas_min", "37", "Min die number for a smoker to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_smoker_spas_max", "43", "Max die number for a smoker to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_smoker_melee_min", "39", "Min die number for a smoker to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_smoker_melee_max", "45", "Max die number for a smoker to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_smoker_desert_min", "44", "Min die number for a smoker to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_smoker_desert_max", "47", "Max die number for a smoker to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_smoker_chainsaw_min", "0", "Min die number for a smoker to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_smoker_chainsaw_max", "0", "Max die number for a smoker to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_smoker_explosive_min", "44", "Min die number for a smoker to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_smoker_explosive_max", "47", "Max die number for a smoker to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_smoker_incendiary_min", "45", "Min die number for a smoker to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_smoker_incendiary_max", "48", "Max die number for a smoker to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_smoker_adrenaline_min", "46", "Min die number for a smoker to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_smoker_adrenaline_max", "50", "Max die number for a smoker to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_smoker_vomitjar_min", "47", "Min die number for a smoker to drop a vomitjar.", CVAR_FLAGS, true, 0.0);
	CVarSmokerLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_smoker_vomitjar_max", "50", "Max die number for a smoker to drop a vomitjar.", CVAR_FLAGS, true, 0.0);

	CVarSpitterLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_spitter_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", CVAR_FLAGS, true, 1.0, true, 4.0);
	CVarSpitterLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_spitter_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", CVAR_FLAGS, true, 1.0, true, 3.0);
	CVarSpitterLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_spitter_item_count", "3", "How many items are rolled for when the witch dies.", CVAR_FLAGS, true, 0.0);	
	
	CVarSpitterLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_spitter_kit_min", "1", "Min die number for a spitter to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_spitter_kit_max", "3", "Max die number for a spitter to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_spitter_pills_min",	"3", "Min die number for a spitter to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_spitter_pills_max",	"7", "Max die number for a spitter to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_spitter_molly_min",	"8", "Min die number for a spitter to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_spitter_molly_max",	"13", "Max die number for a spitter to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_spitter_pipe_min", "12", "Min die number for a spitter to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_spitter_pipe_max", "15", "Max die number for a spitter to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	
	CVarSpitterLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_spitter_panic_min",	"9", "Min die number for a spitter to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_spitter_panic_max",	"11", "Max die number for a spitter to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_spitter_tankspawn_min",	"12", "Min die number for a spitter to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_spitter_tankspawn_max",	"13", "Max die number for a spitter to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_spitter_witchspawn_min", "15", "Min die number for a spitter to cause a spitter to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_spitter_witchspawn_max", "18", "Max die number for a spitter to cause a spitter to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_spitter_common_min", "14", "Min die number for a spitter to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_spitter_common_max", "20", "Max die number for a spitter to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	
	CVarSpitterLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_spitter_pistol_min", "20", 	"Min die number for a spitter to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_spitter_pistol_max", "40", 	"Max die number for a spitter to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_spitter_smg_min", "22", "Min die number for a spitter to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_spitter_smg_max", "35", "Max die number for a spitter to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_spitter_shotgun_min", "23", "Min die number for a spitter to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_spitter_shotgun_max", "40", "Max die number for a spitter to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_spitter_rifle_min", "24", "Min die number for a spitter to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_spitter_rifle_max", "30", "Max die number for a spitter to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_spitter_autoshot_min", "25", "Min die number for a spitter to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_spitter_autoshot_max", "28", "Max die number for a spitter to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_spitter_sniper_min", "26", "Min die number for a spitter to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_spitter_sniper_max", "29", "Max die number for a spitter to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);	

	CVarSpitterLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_spitter_military_min", "27", "Min die number for a spitter to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_spitter_military_max", "30", "Max die number for a spitter to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_spitter_ak47_min", "28", "Min die number for a spitter to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_spitter_ak47_max", "32", "Max die number for a spitter to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_spitter_defibrillator_min", "31", "Min die number for a spitter to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_spitter_defibrillator_max", "36", "Max die number for a spitter to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_spitter_magnum_min", "34", "Min die number for a spitter to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_spitter_magnum_max", "38", "Max die number for a spitter to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_spitter_spas_min", "36", "Min die number for a spitter to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_spitter_spas_max", "39", "Max die number for a spitter to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_spitter_melee_min", "39", "Min die number for a spitter to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_spitter_melee_max", "45", "Max die number for a spitter to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_spitter_desert_min", "43", "Min die number for a spitter to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_spitter_desert_max", "50", "Max die number for a spitter to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_spitter_chainsaw_min", "0", "Min die number for a spitter to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_spitter_chainsaw_max", "0", "Max die number for a spitter to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_spitter_explosive_min", "44", "Min die number for a spitter to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_spitter_explosive_max", "46", "Max die number for a spitter to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_spitter_incendiary_min", "44", "Min die number for a spitter to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_spitter_incendiary_max", "47", "Max die number for a spitter to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_spitter_adrenaline_min", "45", "Min die number for a spitter to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_spitter_adrenaline_max", "50", "Max die number for a spitter to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_spitter_vomitjar_min", "46", "Min die number for a spitter to drop a vomitjar.", CVAR_FLAGS, true, 0.0);
	CVarSpitterLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_spitter_vomitjar_max", "50", "Max die number for a spitter to drop a vomitjar.", CVAR_FLAGS, true, 0.0);

	CVarChargerLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_charger_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", CVAR_FLAGS, true, 1.0, true, 4.0);
	CVarChargerLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_charger_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", CVAR_FLAGS, true, 1.0, true, 3.0);
	CVarChargerLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_charger_item_count", "3", "How many items are rolled for when the witch dies.", CVAR_FLAGS, true, 0.0);	
	
	CVarChargerLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_charger_kit_min", "1", "Min die number for a charger to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_charger_kit_max", "3", "Max die number for a charger to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_charger_pills_min",	"3", "Min die number for a charger to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_charger_pills_max",	"7", "Max die number for a charger to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_charger_molly_min",	"5", "Min die number for a charger to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_charger_molly_max",	"13", "Max die number for a charger to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_charger_pipe_min", "8", "Min die number for a charger to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_charger_pipe_max", "13", "Max die number for a charger to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	
	CVarChargerLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_charger_panic_min",	"8", "Min die number for a charger to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_charger_panic_max",	"11", "Max die number for a charger to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_charger_tankspawn_min",	"12", "Min die number for a charger to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_charger_tankspawn_max",	"13", "Max die number for a charger to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_charger_witchspawn_min", "13", "Min die number for a charger to cause a charger to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_charger_witchspawn_max", "16", "Max die number for a charger to cause a charger to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_charger_common_min", "15", "Min die number for a charger to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_charger_common_max", "22", "Max die number for a charger to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	
	CVarChargerLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_charger_pistol_min", "20", 	"Min die number for a charger to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_charger_pistol_max", "40", 	"Max die number for a charger to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_charger_smg_min", "22", "Min die number for a charger to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_charger_smg_max", "35", "Max die number for a charger to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_charger_shotgun_min", "23", "Min die number for a charger to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_charger_shotgun_max", "40", "Max die number for a charger to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_charger_rifle_min",	"24", "Min die number for a charger to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_charger_rifle_max",	"26", "Max die number for a charger to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_charger_autoshot_min", "25", "Min die number for a charger to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_charger_autoshot_max", "28", "Max die number for a charger to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_charger_sniper_min", "26", "Min die number for a charger to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_charger_sniper_max", "30", "Max die number for a charger to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);	

	CVarChargerLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_charger_military_min", "28", "Min die number for a charger to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_charger_military_max", "31", "Max die number for a charger to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_charger_ak47_min", "28", "Min die number for a charger to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_charger_ak47_max", "32", "Max die number for a charger to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_charger_defibrillator_min", "33", "Min die number for a charger to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_charger_defibrillator_max", "35", "Max die number for a charger to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_charger_magnum_min", "33", "Min die number for a charger to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_charger_magnum_max", "38", "Max die number for a charger to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_charger_spas_min", "34", "Min die number for a charger to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_charger_spas_max", "40", "Max die number for a charger to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_charger_melee_min", "38", "Min die number for a charger to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_charger_melee_max", "43", "Max die number for a charger to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_charger_desert_min", "43", "Min die number for a charger to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_charger_desert_max", "47", "Max die number for a charger to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_charger_chainsaw_min", "0", "Min die number for a charger to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_charger_chainsaw_max", "0", "Max die number for a charger to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_charger_explosive_min", "46", "Min die number for a charger to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_charger_explosive_max", "49", "Max die number for a charger to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_charger_incendiary_min", "44", "Min die number for a charger to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_charger_incendiary_max", "48", "Max die number for a charger to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_charger_adrenaline_min", "45", "Min die number for a charger to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_charger_adrenaline_max", "47", "Max die number for a charger to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_charger_vomitjar_min", "46", "Min die number for a charger to drop a vomitjar.", CVAR_FLAGS, true, 0.0);
	CVarChargerLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_charger_vomitjar_max", "50", "Max die number for a charger to drop a vomitjar.", CVAR_FLAGS, true, 0.0);

	CVarJockeyLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_jockey_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", CVAR_FLAGS, true, 1.0, true, 4.0);
	CVarJockeyLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_jockey_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", CVAR_FLAGS, true, 1.0, true, 3.0);
	CVarJockeyLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_jockey_item_count", "3", "How many items are rolled for when the witch dies.", CVAR_FLAGS, true, 0.0);	
	
	CVarJockeyLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_jockey_kit_min", "1", "Min die number for a jockey to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_jockey_kit_max", "3", "Max die number for a jockey to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_jockey_pills_min",	"2", "Min die number for a jockey to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_jockey_pills_max",	"6", "Max die number for a jockey to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_jockey_molly_min",	"5", "Min die number for a jockey to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_jockey_molly_max",	"8", "Max die number for a jockey to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_jockey_pipe_min", "7", "Min die number for a jockey to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_jockey_pipe_max", "10", "Max die number for a jockey to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	
	CVarJockeyLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_jockey_panic_min",	"11", "Min die number for a jockey to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_jockey_panic_max",	"14", "Max die number for a jockey to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_jockey_tankspawn_min",	"12", "Min die number for a jockey to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_jockey_tankspawn_max",	"13", "Max die number for a jockey to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_jockey_witchspawn_min", "11", "Min die number for a jockey to cause a jockey to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_jockey_witchspawn_max", "16", "Max die number for a jockey to cause a jockey to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_jockey_common_min", "15", "Min die number for a jockey to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_jockey_common_max", "25", "Max die number for a jockey to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	
	CVarJockeyLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_jockey_pistol_min", "20", 	"Min die number for a jockey to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_jockey_pistol_max", "40", 	"Max die number for a jockey to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_jockey_smg_min", "23", "Min die number for a jockey to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_jockey_smg_max", "35", "Max die number for a jockey to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_jockey_shotgun_min", "23", "Min die number for a jockey to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_jockey_shotgun_max", "40", "Max die number for a jockey to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_jockey_rifle_min",	"25", "Min die number for a jockey to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_jockey_rifle_max",	"28", "Max die number for a jockey to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_jockey_autoshot_min", "26", "Min die number for a jockey to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_jockey_autoshot_max", "30", "Max die number for a jockey to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_jockey_sniper_min", "28", "Min die number for a jockey to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_jockey_sniper_max", "32", "Max die number for a jockey to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);	

	CVarJockeyLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_jockey_military_min", "31", "Min die number for a jockey to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_jockey_military_max", "34", "Max die number for a jockey to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_jockey_ak47_min", "31", "Min die number for a jockey to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_jockey_ak47_max", "35", "Max die number for a jockey to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_jockey_defibrillator_min", "34", "Min die number for a jockey to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_jockey_defibrillator_max", "36", "Max die number for a jockey to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_jockey_magnum_min", "34", "Min die number for a jockey to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_jockey_magnum_max", "37", "Max die number for a jockey to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_jockey_spas_min", "36", "Min die number for a jockey to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_jockey_spas_max", "43", "Max die number for a jockey to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_jockey_melee_min", "35", "Min die number for a jockey to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_jockey_melee_max", "46", "Max die number for a jockey to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_jockey_desert_min", "42", "Min die number for a jockey to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_jockey_desert_max", "47", "Max die number for a jockey to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_jockey_chainsaw_min", "0", "Min die number for a jockey to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_jockey_chainsaw_max", "0", "Max die number for a jockey to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_jockey_explosive_min", "45", "Min die number for a jockey to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_jockey_explosive_max", "48", "Max die number for a jockey to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_jockey_incendiary_min", "46", "Min die number for a jockey to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_jockey_incendiary_max", "49", "Max die number for a jockey to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_jockey_adrenaline_min", "48", "Min die number for a jockey to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_jockey_adrenaline_max", "50", "Max die number for a jockey to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_jockey_vomitjar_min", "46", "Min die number for a jockey to drop a vomitjar.", CVAR_FLAGS, true, 0.0);
	CVarJockeyLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_jockey_vomitjar_max", "50", "Max die number for a jockey to drop a vomitjar.", CVAR_FLAGS, true, 0.0);

	CVarTankLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_tank_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", CVAR_FLAGS, true, 1.0, true, 4.0);
	CVarTankLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_tank_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", CVAR_FLAGS, true, 1.0, true, 3.0);
	CVarTankLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_tank_item_count", "5", "How many items are rolled for when the witch dies.", CVAR_FLAGS, true, 0.0);	
	
	CVarTankLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_tank_kit_min", "1", "Min die number for a tank to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_tank_kit_max", "4", "Max die number for a tank to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_tank_pills_min",	"5", "Min die number for a tank to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_tank_pills_max",	"9", "Max die number for a tank to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_tank_molly_min",	"5", "Min die number for a tank to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_tank_molly_max",	"8", "Max die number for a tank to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_tank_pipe_min", "8", "Min die number for a tank to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_tank_pipe_max", "11", "Max die number for a tank to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	
	CVarTankLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_tank_panic_min",	"12", "Min die number for a tank to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_tank_panic_max",	"15", "Max die number for a tank to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_tank_tankspawn_min",	"0", "Min die number for a tank to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_tank_tankspawn_max",	"0", "Max die number for a tank to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_tank_witchspawn_min", "15", "Min die number for a tank to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_tank_witchspawn_max", "19", "Max die number for a tank to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_tank_common_min", "15", "Min die number for a tank to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_tank_common_max", "22", "Max die number for a tank to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	
	CVarTankLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_tank_pistol_min", "21", 	"Min die number for a tank to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_tank_pistol_max", "40", 	"Max die number for a tank to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_tank_smg_min", "20", "Min die number for a tank to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_tank_smg_max", "35", "Max die number for a tank to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_tank_shotgun_min", "26", "Min die number for a tank to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_tank_shotgun_max", "40", "Max die number for a tank to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_tank_rifle_min",	"25", "Min die number for a tank to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_tank_rifle_max",	"28", "Max die number for a tank to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_tank_autoshot_min", "23", "Min die number for a tank to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_tank_autoshot_max", "29", "Max die number for a tank to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_tank_sniper_min", "25", "Min die number for a tank to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_tank_sniper_max", "30", "Max die number for a tank to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);	

	CVarTankLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_tank_military_min", "28", "Min die number for a tank to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_tank_military_max", "33", "Max die number for a tank to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_tank_ak47_min", "30", "Min die number for a tank to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_tank_ak47_max", "35", "Max die number for a tank to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_tank_defibrillator_min", "25", "Min die number for a tank to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_tank_defibrillator_max", "40", "Max die number for a tank to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_tank_magnum_min", "33", "Min die number for a tank to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_tank_magnum_max", "37", "Max die number for a tank to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_tank_spas_min", "36", "Min die number for a tank to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_tank_spas_max", "41", "Max die number for a tank to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_tank_melee_min", "40", "Min die number for a tank to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_tank_melee_max", "48", "Max die number for a tank to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_tank_desert_min", "42", "Min die number for a tank to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_tank_desert_max", "47", "Max die number for a tank to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_tank_chainsaw_min", "30", "Min die number for a tank to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_tank_chainsaw_max", "46", "Max die number for a tank to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_tank_explosive_min", "43", "Min die number for a tank to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_tank_explosive_max", "47", "Max die number for a tank to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_tank_incendiary_min", "44", "Min die number for a tank to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_tank_incendiary_max", "48", "Max die number for a tank to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_tank_adrenaline_min", "46", "Min die number for a tank to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_tank_adrenaline_max", "50", "Max die number for a tank to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_tank_vomitjar_min", "48", "Min die number for a tank to drop a vomitjar.", CVAR_FLAGS, true, 0.0);
	CVarTankLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_tank_vomitjar_max", "50", "Max die number for a tank to drop a vomitjar.", CVAR_FLAGS, true, 0.0);

	CVarWitchLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_witch_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", CVAR_FLAGS, true, 1.0, true, 4.0);
	CVarWitchLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_witch_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", CVAR_FLAGS, true, 1.0, true, 3.0);
	CVarWitchLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_witch_item_count", "4", "How many items are rolled for when the witch dies.", CVAR_FLAGS, true, 0.0);	
	
	CVarWitchLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_witch_kit_min", "1", "Min die number for a witch to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_witch_kit_max", "3", "Max die number for a witch to drop a kit.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_witch_pills_min",	"2", "Min die number for a witch to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_witch_pills_max",	"6", "Max die number for a witch to drop pills.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_witch_molly_min",	"4", "Min die number for a witch to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_witch_molly_max",	"6", "Max die number for a witch to drop a molitov.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_witch_pipe_min", "6", "Min die number for a witch to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_witch_pipe_max", "11", "Max die number for a witch to drop a pipe bomb.", CVAR_FLAGS, true, 0.0);
	
	CVarWitchLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_witch_panic_min",	"12", "Min die number for a witch to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_witch_panic_max",	"15", "Max die number for a witch to cause a zombie panic event.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_witch_tankspawn_min",	"15", "Min die number for a witch to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_witch_tankspawn_max",	"16", "Max die number for a witch to cause a tank to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_witch_witchspawn_min", "17", "Min die number for a witch to cause a witch to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_witch_witchspawn_max", "22", "Max die number for a witch to cause a witch to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_witch_common_min", "18", "Min die number for a witch to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_witch_common_max", "25", "Max die number for a witch to cause common infected to spawn nearby.", CVAR_FLAGS, true, 0.0);
	
	CVarWitchLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_witch_pistol_min", "21", 	"Min die number for a witch to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_witch_pistol_max", "40", 	"Max die number for a witch to drop a pistol.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_witch_smg_min", "22", "Min die number for a witch to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_witch_smg_max", "35", "Max die number for a witch to drop a small machine gun.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_witch_shotgun_min", "22", "Min die number for a witch to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_witch_shotgun_max", "35", "Max die number for a witch to drop a shotgun.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_witch_rifle_min",	"24", "Min die number for a witch to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_witch_rifle_max",	"29", "Max die number for a witch to drop an auto rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_witch_autoshot_min", "22", "Min die number for a witch to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_witch_autoshot_max", "27", "Max die number for a witch to drop an auto shotgun.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_witch_sniper_min", "26", "Min die number for a witch to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_witch_sniper_max", "30", "Max die number for a witch to drop a sniper rifle.", CVAR_FLAGS, true, 0.0);	

	CVarWitchLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_witch_military_min", "25", "Min die number for a witch to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_witch_military_max", "29", "Max die number for a witch to drop a military rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_witch_ak47_min", "25", "Min die number for a witch to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_witch_ak47_max", "30", "Max die number for a witch to drop a ak47 rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_witch_defibrillator_min", "30", "Min die number for a witch to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_witch_defibrillator_max", "40", "Max die number for a witch to drop a defibrillator.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_witch_magnum_min", "34", "Min die number for a witch to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_witch_magnum_max", "39", "Max die number for a witch to drop a magnum.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_witch_spas_min", "36", "Min die number for a witch to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_witch_spas_max", "40", "Max die number for a witch to drop a spas shotgun.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_witch_melee_min", "30", "Min die number for a witch to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_witch_melee_max", "43", "Max die number for a witch to drop a melee.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_witch_desert_min", "44", "Min die number for a witch to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_witch_desert_max", "46", "Max die number for a witch to drop a desert rifle.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_witch_chainsaw_min", "13", "Min die number for a witch to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_witch_chainsaw_max", "16", "Max die number for a witch to drop a chainsaw.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_witch_explosive_min", "47", "Min die number for a witch to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_witch_explosive_max", "49", "Max die number for a witch to drop a explosive ammo.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_witch_incendiary_min", "45", "Min die number for a witch to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_witch_incendiary_max", "48", "Max die number for a witch to drop a incendiary ammo.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_witch_adrenaline_min", "46", "Min die number for a witch to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_witch_adrenaline_max", "50", "Max die number for a witch to drop a adrenaline.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_witch_vomitjar_min", "48", "Min die number for a witch to drop a vomitjar.", CVAR_FLAGS, true, 0.0);
	CVarWitchLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_witch_vomitjar_max", "50", "Max die number for a witch to drop a vomitjar.", CVAR_FLAGS, true, 0.0);

	RegConsoleCmd("sm_loot_sim_infected", Command_SimInfected);
	RegConsoleCmd("sm_loot_print_settings", Command_PrintSettings);
	RegConsoleCmd("sm_loot_load", Command_LoadSettings);
	
	PrintToServer("[DICE] Loading config.");
	AutoExecConfig(true, "l4d_loot_drop");
	
	// Change the enabled flag to the one the convar holds.
	if (CVarIsEnabled.BoolValue) 
	{
		HookEvent("player_death", Event_PlayerDeath);
		PullCVarValues();
	}
	else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

public void OnMapStart()
{
	PrintToServer("[DICE] Starting map, refreshing settings.");
	PullCVarValues();

	numTank = 0;
	numWitch = 0;
	tankSpawn = 0;
	witchSpawn = 0;
	numTankMax = 0;
	numWitchMax = 0;
}
//HookEvent("round_end", Event_RoundEnd);
// Debugging purposes (above)

Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	numTank = 0;
	numWitch = 0;
	tankSpawn = 0;
	witchSpawn = 0;
	numTankMax = 0;
	numWitchMax = 0;
	numPanic = 0;
	TellAll("Tank Allowances Reset.");
	return Plugin_Continue;
}
// At round end, reset tank/witch count.

Action Command_LoadSettings(int client, int args)
{
	PrintToServer("[DICE] Refreshing settings.");
	AutoExecConfig(false, "l4d_loot_drop");
	PullCVarValues();
	return Plugin_Handled;
}

Action Command_PrintSettings(int client, int args)
{
	char arg[128]
	GetCmdArg(1, arg, sizeof(arg))
	if (StrEqual(arg, "hunter", false))
	{
		PrintToServer("[DICE SETTINGS] Hunter");
		PrintSettings(HunterLoot);
	}
	else if (StrEqual(arg, "smoker", false))
	{
		PrintToServer("[DICE SETTINGS] Smoker");
		PrintSettings(SmokerLoot);
	}
	else if (StrEqual(arg, "boomer", false))
	{
		PrintToServer("[DICE SETTINGS] Boomer");
		PrintSettings(BoomerLoot);
	}
	else if (StrEqual(arg, "tank", false))
	{
		PrintToServer("[DICE SETTINGS] Tank");
		PrintSettings(TankLoot);
	}
	else if (StrEqual(arg, "witch", false))
	{
		PrintToServer("[DICE SETTINGS] Witch");
		PrintSettings(WitchLoot);
	}
	else if (StrEqual(arg, "spitter", false))
	{
		PrintToServer("[DICE SETTINGS] Spitter");
		PrintSettings(SpitterLoot);
	}
	else if (StrEqual(arg, "charger", false))
	{
		PrintToServer("[DICE SETTINGS] Charger");
		PrintSettings(ChargerLoot);
	}
	else if (StrEqual(arg, "jockey", false))
	{
		PrintToServer("[DICE SETTINGS] Jockey");
		PrintSettings(JockeyLoot);
	}
	else if (StrEqual(arg, "dice", false))
	{
		PrintToServer("[DICE SETTINGS] Dice");
		PrintToServer("Die 1: %i", Dice[0]);
		PrintToServer("Die 2: %i", Dice[1]);
		PrintToServer("Die 3: %i", Dice[2]);
		PrintToServer("Die 4: %i", Dice[3]);
	}
	return Plugin_Handled;
}

void PrintSettings(int diceSettings[55])
{
	PrintToServer("Die Number: id = %i, of %i sides", diceSettings[LOOT_DIENUMBER], Dice[ diceSettings[LOOT_DIENUMBER] - 1]);
	PrintToServer("Dice To Roll: %i", diceSettings[LOOT_DIECOUNT]);
	PrintToServer("Item Count: %i", diceSettings[LOOT_ITEM_COUNT]);
	PrintToServer("Kit Min-Max: %i-%i", diceSettings[LOOT_KIT_MIN], diceSettings[LOOT_KIT_MAX]);
	PrintToServer("Pills Min-Max: %i-%i", diceSettings[LOOT_PILLS_MIN], diceSettings[LOOT_PILLS_MAX]);
	PrintToServer("Molly Min-Max: %i-%i", diceSettings[LOOT_MOLLY_MIN], diceSettings[LOOT_MOLLY_MAX]);
	PrintToServer("Pipe Min-Max: %i-%i", diceSettings[LOOT_PIPE_MIN], diceSettings[LOOT_PIPE_MAX]);
	PrintToServer("Pistol Min-Max: %i-%i", diceSettings[LOOT_PISTOL_MIN], diceSettings[LOOT_PISTOL_MAX]);
	PrintToServer("SMG Min-Max: %i-%i", diceSettings[LOOT_SMG_MIN], diceSettings[LOOT_SMG_MAX]);
	PrintToServer("Shotgun Min-Max: %i-%i", diceSettings[LOOT_SHOT_MIN], diceSettings[LOOT_SHOT_MAX]);
	PrintToServer("Rifle Min-Max: %i-%i", diceSettings[LOOT_RIFLE_MIN], diceSettings[LOOT_RIFLE_MAX]);
	PrintToServer("Auto Shotgun Min-Max: %i-%i", diceSettings[LOOT_AUTOSHOT_MIN], diceSettings[LOOT_AUTOSHOT_MAX]);
	PrintToServer("Sniper Rifle Min-Max: %i-%i", diceSettings[LOOT_SNIPER_MIN], diceSettings[LOOT_SNIPER_MAX]);
	PrintToServer("Panic Event Min-Max: %i-%i", diceSettings[LOOT_PANIC_MIN], diceSettings[LOOT_PANIC_MAX]);
	PrintToServer("Tank Spawn Min-Max: %i-%i", diceSettings[LOOT_TANK_MIN], diceSettings[LOOT_TANK_MAX]);
	PrintToServer("Witch Spawn Min-Max: %i-%i", diceSettings[LOOT_WITCH_MIN], diceSettings[LOOT_WITCH_MAX]);
	PrintToServer("Common Infected Spawn Min-Max: %i-%i", diceSettings[LOOT_COMMON_MIN], diceSettings[LOOT_COMMON_MAX]);	
	PrintToServer("AK47 Spawn Min-Max: %i-%i", diceSettings[LOOT_AK47_MIN], diceSettings[LOOT_AK47_MAX]);
	PrintToServer("DEFIBRILLATOR Spawn Min-Max: %i-%i", diceSettings[LOOT_DEFIBRILLATOR_MIN], diceSettings[LOOT_DEFIBRILLATOR_MAX]);
	PrintToServer("MILITARY RIFLE Spawn Min-Max: %i-%i", diceSettings[LOOT_MILITARY_MIN], diceSettings[LOOT_MILITARY_MAX]);
	PrintToServer("MAGNUM PISTOL Spawn Min-Max: %i-%i", diceSettings[LOOT_MAGNUM_MIN], diceSettings[LOOT_MAGNUM_MAX]);
	PrintToServer("SPAS SHOTGUN Spawn Min-Max: %i-%i", diceSettings[LOOT_SPAS_MIN], diceSettings[LOOT_SPAS_MAX]);
	PrintToServer("MELEE Spawn Min-Max: %i-%i", diceSettings[LOOT_MELEE_MIN], diceSettings[LOOT_MELEE_MAX]);
	PrintToServer("DESERT RIFLE Spawn Min-Max: %i-%i", diceSettings[LOOT_DESERT_MIN], diceSettings[LOOT_DESERT_MAX]);
	PrintToServer("CHAINSAW Spawn Min-Max: %i-%i", diceSettings[LOOT_CHAINSAW_MIN], diceSettings[LOOT_CHAINSAW_MAX]);
	PrintToServer("EXPLOSIVE AMMO Spawn Min-Max: %i-%i", diceSettings[LOOT_EXPLOSIVE_MIN], diceSettings[LOOT_EXPLOSIVE_MAX]);
	PrintToServer("INCENDIARY AMMO Spawn Min-Max: %i-%i", diceSettings[LOOT_INCENDIARY_MIN], diceSettings[LOOT_INCENDIARY_MAX]);
	PrintToServer("ADRENALINE Spawn Min-Max: %i-%i", diceSettings[LOOT_ADRENALINE_MIN], diceSettings[LOOT_ADRENALINE_MAX]);
	PrintToServer("Vomitjar Spawn Min-Max: %i-%i", diceSettings[LOOT_VOMITJAR_MIN], diceSettings[LOOT_VOMITJAR_MAX]);
}

Action Command_SimInfected(int client, int args)
{
	char arg[128]
	GetCmdArg(1, arg, sizeof(arg))
	if (StrEqual(arg, "hunter", false))
	{
		PrintToServer("[DICE SIM] Hunter killed: Rolling for %i items.", HunterLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < HunterLoot[LOOT_ITEM_COUNT]; i++)
		{
			PrintToServer("[DICE SIM] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[HunterLoot[LOOT_DIENUMBER] - 1], HunterLoot[LOOT_DIECOUNT]);

			SpawnItemFromDieResult(client, HunterLoot, RollDice(HunterLoot[LOOT_DIECOUNT], HunterLoot[LOOT_DIENUMBER], true), true);
		}
	}
	else if (StrEqual(arg, "smoker", false))
	{
		PrintToServer("[DICE SIM] Smoker killed: Rolling for %i items.", SmokerLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < SmokerLoot[LOOT_ITEM_COUNT]; i++)
		{
			PrintToServer("[DICE SIM] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[SmokerLoot[LOOT_DIENUMBER] - 1], SmokerLoot[LOOT_DIECOUNT]);
		
			SpawnItemFromDieResult(client, SmokerLoot, RollDice(SmokerLoot[LOOT_DIECOUNT], SmokerLoot[LOOT_DIENUMBER], true), true);
		}
	}
	else if (StrEqual(arg, "boomer", false))
	{
		PrintToServer("[DICE SIM] Boomer killed: Rolling for %i items.", BoomerLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < BoomerLoot[LOOT_ITEM_COUNT]; i++)
		{
			PrintToServer("[DICE SIM] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[BoomerLoot[LOOT_DIENUMBER] - 1], BoomerLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(client, BoomerLoot, RollDice(BoomerLoot[LOOT_DIECOUNT], BoomerLoot[LOOT_DIENUMBER], true), true);
		}
	}
	else if (StrEqual(arg, "tank", false))
	{
		PrintToServer("[DICE SIM] Tank killed: Rolling for %i items.", TankLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < TankLoot[LOOT_ITEM_COUNT]; i++)
		{
			PrintToServer("[DICE SIM] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[TankLoot[LOOT_DIENUMBER] - 1], TankLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(client, TankLoot, RollDice(TankLoot[LOOT_DIECOUNT], TankLoot[LOOT_DIENUMBER], true), true);
		}
	}
	else if (StrEqual(arg, "witch", false))
	{
		PrintToServer("[DICE SIM] Witch killed: Rolling for %i items.", WitchLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < WitchLoot[LOOT_ITEM_COUNT]; i++)
		{
			PrintToServer("[DICE SIM] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[WitchLoot[LOOT_DIENUMBER] - 1], WitchLoot[LOOT_DIECOUNT]);

			SpawnItemFromDieResult(client, WitchLoot, RollDice(WitchLoot[LOOT_DIECOUNT], WitchLoot[LOOT_DIENUMBER], true), true);
		}
	}
	else if (StrEqual(arg, "spitter", false))
	{
		PrintToServer("[DICE SIM] Spitter killed: Rolling for %i items.", SpitterLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < SpitterLoot[LOOT_ITEM_COUNT]; i++)
		{
			PrintToServer("[DICE SIM] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[SpitterLoot[LOOT_DIENUMBER] - 1], SpitterLoot[LOOT_DIECOUNT]);

			SpawnItemFromDieResult(client, SpitterLoot, RollDice(SpitterLoot[LOOT_DIECOUNT], SpitterLoot[LOOT_DIENUMBER], true), true);
		}
	}
	else if (StrEqual(arg, "charger", false))
	{
		PrintToServer("[DICE SIM] Charger killed: Rolling for %i items.", ChargerLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < ChargerLoot[LOOT_ITEM_COUNT]; i++)
		{
			PrintToServer("[DICE SIM] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[ChargerLoot[LOOT_DIENUMBER] - 1], ChargerLoot[LOOT_DIECOUNT]);

			SpawnItemFromDieResult(client, ChargerLoot, RollDice(ChargerLoot[LOOT_DIECOUNT], ChargerLoot[LOOT_DIENUMBER], true), true);
		}
	}
	else if (StrEqual(arg, "jockey", false))
	{
		PrintToServer("[DICE SIM] Jockey killed: Rolling for %i items.", JockeyLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < JockeyLoot[LOOT_ITEM_COUNT]; i++)
		{
			PrintToServer("[DICE SIM] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[JockeyLoot[LOOT_DIENUMBER] - 1], JockeyLoot[LOOT_DIECOUNT]);

			SpawnItemFromDieResult(client, JockeyLoot, RollDice(JockeyLoot[LOOT_DIECOUNT], JockeyLoot[LOOT_DIENUMBER], true), true);
		}
	}
	return Plugin_Handled;
}

void Loot_EnableDisable(ConVar hVariable, const char[] strOldValue, const char[] strNewValue)
{
    // Change the enabled flag to the one the convar holds.
    if (CVarIsEnabled.BoolValue)
	{
		HookEvent("player_death", Event_PlayerDeath);
	}
    else
	{
		UnhookEvent("player_death", Event_PlayerDeath);
	}
}

void PullCVarValues()
{
	Dice[0] = CVarDieSides[0].IntValue;
	Dice[1] = CVarDieSides[1].IntValue;
	Dice[2] = CVarDieSides[2].IntValue;
	Dice[3] = CVarDieSides[3].IntValue;
	
	HunterLoot[LOOT_DIENUMBER] = CVarHunterLoot[LOOT_DIENUMBER].IntValue;
	HunterLoot[LOOT_DIECOUNT] = CVarHunterLoot[LOOT_DIECOUNT].IntValue;
	HunterLoot[LOOT_KIT_MIN] = CVarHunterLoot[LOOT_KIT_MIN].IntValue;
	HunterLoot[LOOT_KIT_MAX] = CVarHunterLoot[LOOT_KIT_MAX].IntValue;
	HunterLoot[LOOT_PILLS_MIN] = CVarHunterLoot[LOOT_PILLS_MIN].IntValue;
	HunterLoot[LOOT_PILLS_MAX] = CVarHunterLoot[LOOT_PILLS_MAX].IntValue;
	HunterLoot[LOOT_MOLLY_MIN] = CVarHunterLoot[LOOT_MOLLY_MIN].IntValue;
	HunterLoot[LOOT_MOLLY_MAX] = CVarHunterLoot[LOOT_MOLLY_MAX].IntValue;
	HunterLoot[LOOT_PIPE_MIN] = CVarHunterLoot[LOOT_PIPE_MIN].IntValue;
	HunterLoot[LOOT_PIPE_MAX] = CVarHunterLoot[LOOT_PIPE_MAX].IntValue;
	HunterLoot[LOOT_ITEM_COUNT] = CVarHunterLoot[LOOT_ITEM_COUNT].IntValue;

	HunterLoot[LOOT_PANIC_MIN] = CVarHunterLoot[LOOT_PANIC_MIN].IntValue;
	HunterLoot[LOOT_PANIC_MAX] = CVarHunterLoot[LOOT_PANIC_MAX].IntValue;
	HunterLoot[LOOT_TANK_MIN] = CVarHunterLoot[LOOT_TANK_MIN].IntValue;
	HunterLoot[LOOT_TANK_MAX] = CVarHunterLoot[LOOT_TANK_MAX].IntValue;
	HunterLoot[LOOT_WITCH_MIN] = CVarHunterLoot[LOOT_WITCH_MIN].IntValue;
	HunterLoot[LOOT_WITCH_MAX] = CVarHunterLoot[LOOT_WITCH_MAX].IntValue;
	HunterLoot[LOOT_COMMON_MIN] = CVarHunterLoot[LOOT_COMMON_MIN].IntValue;
	HunterLoot[LOOT_COMMON_MAX] = CVarHunterLoot[LOOT_COMMON_MAX].IntValue;
	
	HunterLoot[LOOT_PISTOL_MIN] = CVarHunterLoot[LOOT_PISTOL_MIN].IntValue;
	HunterLoot[LOOT_PISTOL_MAX] = CVarHunterLoot[LOOT_PISTOL_MAX].IntValue;
	HunterLoot[LOOT_SMG_MIN] = CVarHunterLoot[LOOT_SMG_MIN].IntValue;
	HunterLoot[LOOT_SMG_MAX] = CVarHunterLoot[LOOT_SMG_MAX].IntValue;
	HunterLoot[LOOT_SHOT_MIN] = CVarHunterLoot[LOOT_SHOT_MIN].IntValue;
	HunterLoot[LOOT_SHOT_MAX] = CVarHunterLoot[LOOT_SHOT_MAX].IntValue;
	HunterLoot[LOOT_RIFLE_MIN] = CVarHunterLoot[LOOT_RIFLE_MIN].IntValue;
	HunterLoot[LOOT_RIFLE_MAX] = CVarHunterLoot[LOOT_RIFLE_MAX].IntValue;
	HunterLoot[LOOT_AUTOSHOT_MIN] = CVarHunterLoot[LOOT_AUTOSHOT_MIN].IntValue;
	HunterLoot[LOOT_AUTOSHOT_MAX] = CVarHunterLoot[LOOT_AUTOSHOT_MAX].IntValue;
	HunterLoot[LOOT_SNIPER_MIN] = CVarHunterLoot[LOOT_SNIPER_MIN].IntValue;
	HunterLoot[LOOT_SNIPER_MAX] = CVarHunterLoot[LOOT_SNIPER_MAX].IntValue;
	HunterLoot[LOOT_AK47_MIN] = CVarHunterLoot[LOOT_AK47_MIN].IntValue;
	HunterLoot[LOOT_AK47_MAX] = CVarHunterLoot[LOOT_AK47_MAX].IntValue;
	HunterLoot[LOOT_DEFIBRILLATOR_MIN] = CVarHunterLoot[LOOT_DEFIBRILLATOR_MIN].IntValue;
	HunterLoot[LOOT_DEFIBRILLATOR_MAX] = CVarHunterLoot[LOOT_DEFIBRILLATOR_MAX].IntValue;
	HunterLoot[LOOT_MILITARY_MIN] = CVarHunterLoot[LOOT_MILITARY_MIN].IntValue;
	HunterLoot[LOOT_MILITARY_MAX] = CVarHunterLoot[LOOT_MILITARY_MAX].IntValue;
	HunterLoot[LOOT_MAGNUM_MIN] = CVarHunterLoot[LOOT_MAGNUM_MIN].IntValue;
	HunterLoot[LOOT_MAGNUM_MAX] = CVarHunterLoot[LOOT_MAGNUM_MAX].IntValue;
	HunterLoot[LOOT_SPAS_MIN] = CVarHunterLoot[LOOT_SPAS_MIN].IntValue;
	HunterLoot[LOOT_SPAS_MAX] = CVarHunterLoot[LOOT_SPAS_MAX].IntValue;
	HunterLoot[LOOT_MELEE_MIN] = CVarHunterLoot[LOOT_MELEE_MIN].IntValue;
	HunterLoot[LOOT_MELEE_MAX] = CVarHunterLoot[LOOT_MELEE_MAX].IntValue;
	HunterLoot[LOOT_DESERT_MIN] = CVarHunterLoot[LOOT_DESERT_MIN].IntValue;
	HunterLoot[LOOT_DESERT_MAX] = CVarHunterLoot[LOOT_DESERT_MAX].IntValue;
	HunterLoot[LOOT_CHAINSAW_MIN] = CVarHunterLoot[LOOT_CHAINSAW_MIN].IntValue;
	HunterLoot[LOOT_CHAINSAW_MAX] = CVarHunterLoot[LOOT_CHAINSAW_MAX].IntValue;
	HunterLoot[LOOT_EXPLOSIVE_MIN] = CVarHunterLoot[LOOT_EXPLOSIVE_MIN].IntValue;
	HunterLoot[LOOT_EXPLOSIVE_MAX] = CVarHunterLoot[LOOT_EXPLOSIVE_MAX].IntValue;
	HunterLoot[LOOT_INCENDIARY_MIN] = CVarHunterLoot[LOOT_INCENDIARY_MIN].IntValue;
	HunterLoot[LOOT_INCENDIARY_MAX] = CVarHunterLoot[LOOT_INCENDIARY_MAX].IntValue;
	HunterLoot[LOOT_ADRENALINE_MIN] = CVarHunterLoot[LOOT_ADRENALINE_MIN].IntValue;
	HunterLoot[LOOT_ADRENALINE_MAX] = CVarHunterLoot[LOOT_ADRENALINE_MAX].IntValue;
	HunterLoot[LOOT_VOMITJAR_MIN] = CVarHunterLoot[LOOT_VOMITJAR_MIN].IntValue;
	HunterLoot[LOOT_VOMITJAR_MAX] = CVarHunterLoot[LOOT_VOMITJAR_MAX].IntValue;

	BoomerLoot[LOOT_DIENUMBER] = CVarBoomerLoot[LOOT_DIENUMBER].IntValue;
	BoomerLoot[LOOT_DIECOUNT] = CVarBoomerLoot[LOOT_DIECOUNT].IntValue;
	BoomerLoot[LOOT_KIT_MIN] = CVarBoomerLoot[LOOT_KIT_MIN].IntValue;
	BoomerLoot[LOOT_KIT_MAX] = CVarBoomerLoot[LOOT_KIT_MAX].IntValue;
	BoomerLoot[LOOT_PILLS_MIN] = CVarBoomerLoot[LOOT_PILLS_MIN].IntValue;
	BoomerLoot[LOOT_PILLS_MAX] = CVarBoomerLoot[LOOT_PILLS_MAX].IntValue;
	BoomerLoot[LOOT_MOLLY_MIN] = CVarBoomerLoot[LOOT_MOLLY_MIN].IntValue;
	BoomerLoot[LOOT_MOLLY_MAX] = CVarBoomerLoot[LOOT_MOLLY_MAX].IntValue;
	BoomerLoot[LOOT_PIPE_MIN] = CVarBoomerLoot[LOOT_PIPE_MIN].IntValue;
	BoomerLoot[LOOT_PIPE_MAX] = CVarBoomerLoot[LOOT_PIPE_MAX].IntValue;
	BoomerLoot[LOOT_ITEM_COUNT] = CVarBoomerLoot[LOOT_ITEM_COUNT].IntValue;

	BoomerLoot[LOOT_PANIC_MIN] = CVarBoomerLoot[LOOT_PANIC_MIN].IntValue;
	BoomerLoot[LOOT_PANIC_MAX] = CVarBoomerLoot[LOOT_PANIC_MAX].IntValue;
	BoomerLoot[LOOT_TANK_MIN] = CVarBoomerLoot[LOOT_TANK_MIN].IntValue;
	BoomerLoot[LOOT_TANK_MAX] = CVarBoomerLoot[LOOT_TANK_MAX].IntValue;
	BoomerLoot[LOOT_WITCH_MIN] = CVarBoomerLoot[LOOT_WITCH_MIN].IntValue;
	BoomerLoot[LOOT_WITCH_MAX] = CVarBoomerLoot[LOOT_WITCH_MAX].IntValue;
	BoomerLoot[LOOT_COMMON_MIN] = CVarBoomerLoot[LOOT_COMMON_MIN].IntValue;
	BoomerLoot[LOOT_COMMON_MAX] = CVarBoomerLoot[LOOT_COMMON_MAX].IntValue;

	BoomerLoot[LOOT_PISTOL_MIN] = CVarBoomerLoot[LOOT_PISTOL_MIN].IntValue;
	BoomerLoot[LOOT_PISTOL_MAX] = CVarBoomerLoot[LOOT_PISTOL_MAX].IntValue;
	BoomerLoot[LOOT_SMG_MIN] = CVarBoomerLoot[LOOT_SMG_MIN].IntValue;
	BoomerLoot[LOOT_SMG_MAX] = CVarBoomerLoot[LOOT_SMG_MAX].IntValue;
	BoomerLoot[LOOT_SHOT_MIN] = CVarBoomerLoot[LOOT_SHOT_MIN].IntValue;
	BoomerLoot[LOOT_SHOT_MAX] = CVarBoomerLoot[LOOT_SHOT_MAX].IntValue;
	BoomerLoot[LOOT_RIFLE_MIN] = CVarBoomerLoot[LOOT_RIFLE_MIN].IntValue;
	BoomerLoot[LOOT_RIFLE_MAX] = CVarBoomerLoot[LOOT_RIFLE_MAX].IntValue;
	BoomerLoot[LOOT_AUTOSHOT_MIN] = CVarBoomerLoot[LOOT_AUTOSHOT_MIN].IntValue;
	BoomerLoot[LOOT_AUTOSHOT_MAX] = CVarBoomerLoot[LOOT_AUTOSHOT_MAX].IntValue;
	BoomerLoot[LOOT_SNIPER_MIN] = CVarBoomerLoot[LOOT_SNIPER_MIN].IntValue;
	BoomerLoot[LOOT_SNIPER_MAX] = CVarBoomerLoot[LOOT_SNIPER_MAX].IntValue;
	BoomerLoot[LOOT_AK47_MIN] = CVarBoomerLoot[LOOT_AK47_MIN].IntValue;
	BoomerLoot[LOOT_AK47_MAX] = CVarBoomerLoot[LOOT_AK47_MAX].IntValue;
	BoomerLoot[LOOT_DEFIBRILLATOR_MIN] = CVarBoomerLoot[LOOT_DEFIBRILLATOR_MIN].IntValue;
	BoomerLoot[LOOT_DEFIBRILLATOR_MAX] = CVarBoomerLoot[LOOT_DEFIBRILLATOR_MAX].IntValue;
	BoomerLoot[LOOT_MILITARY_MIN] = CVarBoomerLoot[LOOT_MILITARY_MIN].IntValue;
	BoomerLoot[LOOT_MILITARY_MAX] = CVarBoomerLoot[LOOT_MILITARY_MAX].IntValue;
	BoomerLoot[LOOT_MAGNUM_MIN] = CVarBoomerLoot[LOOT_MAGNUM_MIN].IntValue;
	BoomerLoot[LOOT_MAGNUM_MAX] = CVarBoomerLoot[LOOT_MAGNUM_MAX].IntValue;
	BoomerLoot[LOOT_SPAS_MIN] = CVarBoomerLoot[LOOT_SPAS_MIN].IntValue;
	BoomerLoot[LOOT_SPAS_MAX] = CVarBoomerLoot[LOOT_SPAS_MAX].IntValue;
	BoomerLoot[LOOT_MELEE_MIN] = CVarBoomerLoot[LOOT_MELEE_MIN].IntValue;
	BoomerLoot[LOOT_MELEE_MAX] = CVarBoomerLoot[LOOT_MELEE_MAX].IntValue;
	BoomerLoot[LOOT_DESERT_MIN] = CVarBoomerLoot[LOOT_DESERT_MIN].IntValue;
	BoomerLoot[LOOT_DESERT_MAX] = CVarBoomerLoot[LOOT_DESERT_MAX].IntValue;
	BoomerLoot[LOOT_CHAINSAW_MIN] = CVarBoomerLoot[LOOT_CHAINSAW_MIN].IntValue;
	BoomerLoot[LOOT_CHAINSAW_MAX] = CVarBoomerLoot[LOOT_CHAINSAW_MAX].IntValue;
	BoomerLoot[LOOT_EXPLOSIVE_MIN] = CVarBoomerLoot[LOOT_EXPLOSIVE_MIN].IntValue;
	BoomerLoot[LOOT_EXPLOSIVE_MAX] = CVarBoomerLoot[LOOT_EXPLOSIVE_MAX].IntValue;
	BoomerLoot[LOOT_INCENDIARY_MIN] = CVarBoomerLoot[LOOT_INCENDIARY_MIN].IntValue;
	BoomerLoot[LOOT_INCENDIARY_MAX] = CVarBoomerLoot[LOOT_INCENDIARY_MAX].IntValue;
	BoomerLoot[LOOT_ADRENALINE_MIN] = CVarBoomerLoot[LOOT_ADRENALINE_MIN].IntValue;
	BoomerLoot[LOOT_ADRENALINE_MAX] = CVarBoomerLoot[LOOT_ADRENALINE_MAX].IntValue;
	BoomerLoot[LOOT_VOMITJAR_MIN] = CVarBoomerLoot[LOOT_VOMITJAR_MIN].IntValue;
	BoomerLoot[LOOT_VOMITJAR_MAX] = CVarBoomerLoot[LOOT_VOMITJAR_MAX].IntValue;

	SmokerLoot[LOOT_DIENUMBER] = CVarSmokerLoot[LOOT_DIENUMBER].IntValue;
	SmokerLoot[LOOT_DIECOUNT] = CVarSmokerLoot[LOOT_DIECOUNT].IntValue;
	SmokerLoot[LOOT_KIT_MIN] = CVarSmokerLoot[LOOT_KIT_MIN].IntValue;
	SmokerLoot[LOOT_KIT_MAX] = CVarSmokerLoot[LOOT_KIT_MAX].IntValue;
	SmokerLoot[LOOT_PILLS_MIN] = CVarSmokerLoot[LOOT_PILLS_MIN].IntValue;
	SmokerLoot[LOOT_PILLS_MAX] = CVarSmokerLoot[LOOT_PILLS_MAX].IntValue;
	SmokerLoot[LOOT_MOLLY_MIN] = CVarSmokerLoot[LOOT_MOLLY_MIN].IntValue;
	SmokerLoot[LOOT_MOLLY_MAX] = CVarSmokerLoot[LOOT_MOLLY_MAX].IntValue;
	SmokerLoot[LOOT_PIPE_MIN] = CVarSmokerLoot[LOOT_PIPE_MIN].IntValue;
	SmokerLoot[LOOT_PIPE_MAX] = CVarSmokerLoot[LOOT_PIPE_MAX].IntValue;
	SmokerLoot[LOOT_ITEM_COUNT] = CVarSmokerLoot[LOOT_ITEM_COUNT].IntValue;

	SmokerLoot[LOOT_PANIC_MIN] = CVarSmokerLoot[LOOT_PANIC_MIN].IntValue;
	SmokerLoot[LOOT_PANIC_MAX] = CVarSmokerLoot[LOOT_PANIC_MAX].IntValue;
	SmokerLoot[LOOT_TANK_MIN] = CVarSmokerLoot[LOOT_TANK_MIN].IntValue;
	SmokerLoot[LOOT_TANK_MAX] = CVarSmokerLoot[LOOT_TANK_MAX].IntValue;
	SmokerLoot[LOOT_WITCH_MIN] = CVarSmokerLoot[LOOT_WITCH_MIN].IntValue;
	SmokerLoot[LOOT_WITCH_MAX] = CVarSmokerLoot[LOOT_WITCH_MAX].IntValue;
	SmokerLoot[LOOT_COMMON_MIN] = CVarSmokerLoot[LOOT_COMMON_MIN].IntValue;
	SmokerLoot[LOOT_COMMON_MAX] = CVarSmokerLoot[LOOT_COMMON_MAX].IntValue;

	SmokerLoot[LOOT_PISTOL_MIN] = CVarSmokerLoot[LOOT_PISTOL_MIN].IntValue;
	SmokerLoot[LOOT_PISTOL_MAX] = CVarSmokerLoot[LOOT_PISTOL_MAX].IntValue;
	SmokerLoot[LOOT_SMG_MIN] = CVarSmokerLoot[LOOT_SMG_MIN].IntValue;
	SmokerLoot[LOOT_SMG_MAX] = CVarSmokerLoot[LOOT_SMG_MAX].IntValue;
	SmokerLoot[LOOT_SHOT_MIN] = CVarSmokerLoot[LOOT_SHOT_MIN].IntValue;
	SmokerLoot[LOOT_SHOT_MAX] = CVarSmokerLoot[LOOT_SHOT_MAX].IntValue;
	SmokerLoot[LOOT_RIFLE_MIN] = CVarSmokerLoot[LOOT_RIFLE_MIN].IntValue;
	SmokerLoot[LOOT_RIFLE_MAX] = CVarSmokerLoot[LOOT_RIFLE_MAX].IntValue;
	SmokerLoot[LOOT_AUTOSHOT_MIN] = CVarSmokerLoot[LOOT_AUTOSHOT_MIN].IntValue;
	SmokerLoot[LOOT_AUTOSHOT_MAX] = CVarSmokerLoot[LOOT_AUTOSHOT_MAX].IntValue;
	SmokerLoot[LOOT_SNIPER_MIN] = CVarSmokerLoot[LOOT_SNIPER_MIN].IntValue;
	SmokerLoot[LOOT_SNIPER_MAX] = CVarSmokerLoot[LOOT_SNIPER_MAX].IntValue;
	SmokerLoot[LOOT_AK47_MIN] = CVarSmokerLoot[LOOT_AK47_MIN].IntValue;
	SmokerLoot[LOOT_AK47_MAX] = CVarSmokerLoot[LOOT_AK47_MAX].IntValue;
	SmokerLoot[LOOT_DEFIBRILLATOR_MIN] = CVarSmokerLoot[LOOT_DEFIBRILLATOR_MIN].IntValue;
	SmokerLoot[LOOT_DEFIBRILLATOR_MAX] = CVarSmokerLoot[LOOT_DEFIBRILLATOR_MAX].IntValue;
	SmokerLoot[LOOT_MILITARY_MIN] = CVarSmokerLoot[LOOT_MILITARY_MIN].IntValue;
	SmokerLoot[LOOT_MILITARY_MAX] = CVarSmokerLoot[LOOT_MILITARY_MAX].IntValue;
	SmokerLoot[LOOT_MAGNUM_MIN] = CVarSmokerLoot[LOOT_MAGNUM_MIN].IntValue;
	SmokerLoot[LOOT_MAGNUM_MAX] = CVarSmokerLoot[LOOT_MAGNUM_MAX].IntValue;
	SmokerLoot[LOOT_SPAS_MIN] = CVarSmokerLoot[LOOT_SPAS_MIN].IntValue;
	SmokerLoot[LOOT_SPAS_MAX] = CVarSmokerLoot[LOOT_SPAS_MAX].IntValue;
	SmokerLoot[LOOT_MELEE_MIN] = CVarSmokerLoot[LOOT_MELEE_MIN].IntValue;
	SmokerLoot[LOOT_MELEE_MAX] = CVarSmokerLoot[LOOT_MELEE_MAX].IntValue;
	SmokerLoot[LOOT_DESERT_MIN] = CVarSmokerLoot[LOOT_DESERT_MIN].IntValue;
	SmokerLoot[LOOT_DESERT_MAX] = CVarSmokerLoot[LOOT_DESERT_MAX].IntValue;
	SmokerLoot[LOOT_CHAINSAW_MIN] = CVarSmokerLoot[LOOT_CHAINSAW_MIN].IntValue;
	SmokerLoot[LOOT_CHAINSAW_MAX] = CVarSmokerLoot[LOOT_CHAINSAW_MAX].IntValue;
	SmokerLoot[LOOT_EXPLOSIVE_MIN] = CVarSmokerLoot[LOOT_EXPLOSIVE_MIN].IntValue;
	SmokerLoot[LOOT_EXPLOSIVE_MAX] = CVarSmokerLoot[LOOT_EXPLOSIVE_MAX].IntValue;
	SmokerLoot[LOOT_INCENDIARY_MIN] = CVarSmokerLoot[LOOT_INCENDIARY_MIN].IntValue;
	SmokerLoot[LOOT_INCENDIARY_MAX] = CVarSmokerLoot[LOOT_INCENDIARY_MAX].IntValue;
	SmokerLoot[LOOT_ADRENALINE_MIN] = CVarSmokerLoot[LOOT_ADRENALINE_MIN].IntValue;
	SmokerLoot[LOOT_ADRENALINE_MAX] = CVarSmokerLoot[LOOT_ADRENALINE_MAX].IntValue;
	SmokerLoot[LOOT_VOMITJAR_MIN] = CVarSmokerLoot[LOOT_VOMITJAR_MIN].IntValue;
	SmokerLoot[LOOT_VOMITJAR_MAX] = CVarSmokerLoot[LOOT_VOMITJAR_MAX].IntValue;

	TankLoot[LOOT_DIENUMBER] = CVarTankLoot[LOOT_DIENUMBER].IntValue;
	TankLoot[LOOT_DIECOUNT] = CVarTankLoot[LOOT_DIECOUNT].IntValue;
	TankLoot[LOOT_KIT_MIN] = CVarTankLoot[LOOT_KIT_MIN].IntValue;
	TankLoot[LOOT_KIT_MAX] = CVarTankLoot[LOOT_KIT_MAX].IntValue;
	TankLoot[LOOT_PILLS_MIN] = CVarTankLoot[LOOT_PILLS_MIN].IntValue;
	TankLoot[LOOT_PILLS_MAX] = CVarTankLoot[LOOT_PILLS_MAX].IntValue;
	TankLoot[LOOT_MOLLY_MIN] = CVarTankLoot[LOOT_MOLLY_MIN].IntValue;
	TankLoot[LOOT_MOLLY_MAX] = CVarTankLoot[LOOT_MOLLY_MAX].IntValue;
	TankLoot[LOOT_PIPE_MIN] = CVarTankLoot[LOOT_PIPE_MIN].IntValue;
	TankLoot[LOOT_PIPE_MAX] = CVarTankLoot[LOOT_PIPE_MAX].IntValue;
	TankLoot[LOOT_ITEM_COUNT] = CVarTankLoot[LOOT_ITEM_COUNT].IntValue;

	TankLoot[LOOT_PANIC_MIN] = CVarTankLoot[LOOT_PANIC_MIN].IntValue;
	TankLoot[LOOT_PANIC_MAX] = CVarTankLoot[LOOT_PANIC_MAX].IntValue;
	TankLoot[LOOT_TANK_MIN] = CVarTankLoot[LOOT_TANK_MIN].IntValue;
	TankLoot[LOOT_TANK_MAX] = CVarTankLoot[LOOT_TANK_MAX].IntValue;
	TankLoot[LOOT_WITCH_MIN] = CVarTankLoot[LOOT_WITCH_MIN].IntValue;
	TankLoot[LOOT_WITCH_MAX] = CVarTankLoot[LOOT_WITCH_MAX].IntValue;
	TankLoot[LOOT_COMMON_MIN] = CVarTankLoot[LOOT_COMMON_MIN].IntValue;
	TankLoot[LOOT_COMMON_MAX] = CVarTankLoot[LOOT_COMMON_MAX].IntValue;

	TankLoot[LOOT_PISTOL_MIN] = CVarTankLoot[LOOT_PISTOL_MIN].IntValue;
	TankLoot[LOOT_PISTOL_MAX] = CVarTankLoot[LOOT_PISTOL_MAX].IntValue;
	TankLoot[LOOT_SMG_MIN] = CVarTankLoot[LOOT_SMG_MIN].IntValue;
	TankLoot[LOOT_SMG_MAX] = CVarTankLoot[LOOT_SMG_MAX].IntValue;
	TankLoot[LOOT_SHOT_MIN] = CVarTankLoot[LOOT_SHOT_MIN].IntValue;
	TankLoot[LOOT_SHOT_MAX] = CVarTankLoot[LOOT_SHOT_MAX].IntValue;
	TankLoot[LOOT_RIFLE_MIN] = CVarTankLoot[LOOT_RIFLE_MIN].IntValue;
	TankLoot[LOOT_RIFLE_MAX] = CVarTankLoot[LOOT_RIFLE_MAX].IntValue;
	TankLoot[LOOT_AUTOSHOT_MIN] = CVarTankLoot[LOOT_AUTOSHOT_MIN].IntValue;
	TankLoot[LOOT_AUTOSHOT_MAX] = CVarTankLoot[LOOT_AUTOSHOT_MAX].IntValue;
	TankLoot[LOOT_SNIPER_MIN] = CVarTankLoot[LOOT_SNIPER_MIN].IntValue;
	TankLoot[LOOT_SNIPER_MAX] = CVarTankLoot[LOOT_SNIPER_MAX].IntValue;
	TankLoot[LOOT_AK47_MIN] = CVarTankLoot[LOOT_AK47_MIN].IntValue;
	TankLoot[LOOT_AK47_MAX] = CVarTankLoot[LOOT_AK47_MAX].IntValue;
	TankLoot[LOOT_DEFIBRILLATOR_MIN] = CVarTankLoot[LOOT_DEFIBRILLATOR_MIN].IntValue;
	TankLoot[LOOT_DEFIBRILLATOR_MAX] = CVarTankLoot[LOOT_DEFIBRILLATOR_MAX].IntValue;
	TankLoot[LOOT_MILITARY_MIN] = CVarTankLoot[LOOT_MILITARY_MIN].IntValue;
	TankLoot[LOOT_MILITARY_MAX] = CVarTankLoot[LOOT_MILITARY_MAX].IntValue;
	TankLoot[LOOT_MAGNUM_MIN] = CVarTankLoot[LOOT_MAGNUM_MIN].IntValue;
	TankLoot[LOOT_MAGNUM_MAX] = CVarTankLoot[LOOT_MAGNUM_MAX].IntValue;
	TankLoot[LOOT_SPAS_MIN] = CVarTankLoot[LOOT_SPAS_MIN].IntValue;
	TankLoot[LOOT_SPAS_MAX] = CVarTankLoot[LOOT_SPAS_MAX].IntValue;
	TankLoot[LOOT_MELEE_MIN] = CVarTankLoot[LOOT_MELEE_MIN].IntValue;
	TankLoot[LOOT_MELEE_MAX] = CVarTankLoot[LOOT_MELEE_MAX].IntValue;
	TankLoot[LOOT_DESERT_MIN] = CVarTankLoot[LOOT_DESERT_MIN].IntValue;
	TankLoot[LOOT_DESERT_MAX] = CVarTankLoot[LOOT_DESERT_MAX].IntValue;
	TankLoot[LOOT_CHAINSAW_MIN] = CVarTankLoot[LOOT_CHAINSAW_MIN].IntValue;
	TankLoot[LOOT_CHAINSAW_MAX] = CVarTankLoot[LOOT_CHAINSAW_MAX].IntValue;
	TankLoot[LOOT_EXPLOSIVE_MIN] = CVarTankLoot[LOOT_EXPLOSIVE_MIN].IntValue;
	TankLoot[LOOT_EXPLOSIVE_MAX] = CVarTankLoot[LOOT_EXPLOSIVE_MAX].IntValue;
	TankLoot[LOOT_INCENDIARY_MIN] = CVarTankLoot[LOOT_INCENDIARY_MIN].IntValue;
	TankLoot[LOOT_INCENDIARY_MAX] = CVarTankLoot[LOOT_INCENDIARY_MAX].IntValue;
	TankLoot[LOOT_ADRENALINE_MIN] = CVarTankLoot[LOOT_ADRENALINE_MIN].IntValue;
	TankLoot[LOOT_ADRENALINE_MAX] = CVarTankLoot[LOOT_ADRENALINE_MAX].IntValue;
	TankLoot[LOOT_VOMITJAR_MIN] = CVarTankLoot[LOOT_VOMITJAR_MIN].IntValue;
	TankLoot[LOOT_VOMITJAR_MAX] = CVarTankLoot[LOOT_VOMITJAR_MAX].IntValue;

	WitchLoot[LOOT_DIENUMBER] = CVarWitchLoot[LOOT_DIENUMBER].IntValue;
	WitchLoot[LOOT_DIECOUNT] = CVarWitchLoot[LOOT_DIECOUNT].IntValue;
	WitchLoot[LOOT_KIT_MIN] = CVarWitchLoot[LOOT_KIT_MIN].IntValue;
	WitchLoot[LOOT_KIT_MAX] = CVarWitchLoot[LOOT_KIT_MAX].IntValue;
	WitchLoot[LOOT_PILLS_MIN] = CVarWitchLoot[LOOT_PILLS_MIN].IntValue;
	WitchLoot[LOOT_PILLS_MAX] = CVarWitchLoot[LOOT_PILLS_MAX].IntValue;
	WitchLoot[LOOT_MOLLY_MIN] = CVarWitchLoot[LOOT_MOLLY_MIN].IntValue;
	WitchLoot[LOOT_MOLLY_MAX] = CVarWitchLoot[LOOT_MOLLY_MAX].IntValue;
	WitchLoot[LOOT_PIPE_MIN] = CVarWitchLoot[LOOT_PIPE_MIN].IntValue;
	WitchLoot[LOOT_PIPE_MAX] = CVarWitchLoot[LOOT_PIPE_MAX].IntValue;
	WitchLoot[LOOT_ITEM_COUNT] = CVarWitchLoot[LOOT_ITEM_COUNT].IntValue;

	WitchLoot[LOOT_PANIC_MIN] = CVarWitchLoot[LOOT_PANIC_MIN].IntValue;
	WitchLoot[LOOT_PANIC_MAX] = CVarWitchLoot[LOOT_PANIC_MAX].IntValue;
	WitchLoot[LOOT_TANK_MIN] = CVarWitchLoot[LOOT_TANK_MIN].IntValue;
	WitchLoot[LOOT_TANK_MAX] = CVarWitchLoot[LOOT_TANK_MAX].IntValue;
	WitchLoot[LOOT_WITCH_MIN] = CVarWitchLoot[LOOT_WITCH_MIN].IntValue;
	WitchLoot[LOOT_WITCH_MAX] = CVarWitchLoot[LOOT_WITCH_MAX].IntValue;
	WitchLoot[LOOT_COMMON_MIN] = CVarWitchLoot[LOOT_COMMON_MIN].IntValue;
	WitchLoot[LOOT_COMMON_MAX] = CVarWitchLoot[LOOT_COMMON_MAX].IntValue;

	WitchLoot[LOOT_PISTOL_MIN] = CVarWitchLoot[LOOT_PISTOL_MIN].IntValue;
	WitchLoot[LOOT_PISTOL_MAX] = CVarWitchLoot[LOOT_PISTOL_MAX].IntValue;
	WitchLoot[LOOT_SMG_MIN] = CVarWitchLoot[LOOT_SMG_MIN].IntValue;
	WitchLoot[LOOT_SMG_MAX] = CVarWitchLoot[LOOT_SMG_MAX].IntValue;
	WitchLoot[LOOT_SHOT_MIN] = CVarWitchLoot[LOOT_SHOT_MIN].IntValue;
	WitchLoot[LOOT_SHOT_MAX] = CVarWitchLoot[LOOT_SHOT_MAX].IntValue;
	WitchLoot[LOOT_RIFLE_MIN] = CVarWitchLoot[LOOT_RIFLE_MIN].IntValue;
	WitchLoot[LOOT_RIFLE_MAX] = CVarWitchLoot[LOOT_RIFLE_MAX].IntValue;
	WitchLoot[LOOT_AUTOSHOT_MIN] = CVarWitchLoot[LOOT_AUTOSHOT_MIN].IntValue;
	WitchLoot[LOOT_AUTOSHOT_MAX] = CVarWitchLoot[LOOT_AUTOSHOT_MAX].IntValue;
	WitchLoot[LOOT_SNIPER_MIN] = CVarWitchLoot[LOOT_SNIPER_MIN].IntValue;
	WitchLoot[LOOT_SNIPER_MAX] = CVarWitchLoot[LOOT_SNIPER_MAX].IntValue;
	WitchLoot[LOOT_AK47_MIN] = CVarWitchLoot[LOOT_AK47_MIN].IntValue;
	WitchLoot[LOOT_AK47_MAX] = CVarWitchLoot[LOOT_AK47_MAX].IntValue;
	WitchLoot[LOOT_DEFIBRILLATOR_MIN] = CVarWitchLoot[LOOT_DEFIBRILLATOR_MIN].IntValue;
	WitchLoot[LOOT_DEFIBRILLATOR_MAX] = CVarWitchLoot[LOOT_DEFIBRILLATOR_MAX].IntValue;
	WitchLoot[LOOT_MILITARY_MIN] = CVarWitchLoot[LOOT_MILITARY_MIN].IntValue;
	WitchLoot[LOOT_MILITARY_MAX] = CVarWitchLoot[LOOT_MILITARY_MAX].IntValue;
	WitchLoot[LOOT_MAGNUM_MIN] = CVarWitchLoot[LOOT_MAGNUM_MIN].IntValue;
	WitchLoot[LOOT_MAGNUM_MAX] = CVarWitchLoot[LOOT_MAGNUM_MAX].IntValue;
	WitchLoot[LOOT_SPAS_MIN] = CVarWitchLoot[LOOT_SPAS_MIN].IntValue;
	WitchLoot[LOOT_SPAS_MAX] = CVarWitchLoot[LOOT_SPAS_MAX].IntValue;
	WitchLoot[LOOT_MELEE_MIN] = CVarWitchLoot[LOOT_MELEE_MIN].IntValue;
	WitchLoot[LOOT_MELEE_MAX] = CVarWitchLoot[LOOT_MELEE_MAX].IntValue;
	WitchLoot[LOOT_DESERT_MIN] = CVarWitchLoot[LOOT_DESERT_MIN].IntValue;
	WitchLoot[LOOT_DESERT_MAX] = CVarWitchLoot[LOOT_DESERT_MAX].IntValue;
	WitchLoot[LOOT_CHAINSAW_MIN] = CVarWitchLoot[LOOT_CHAINSAW_MIN].IntValue;
	WitchLoot[LOOT_CHAINSAW_MAX] = CVarWitchLoot[LOOT_CHAINSAW_MAX].IntValue;
	WitchLoot[LOOT_EXPLOSIVE_MIN] = CVarWitchLoot[LOOT_EXPLOSIVE_MIN].IntValue;
	WitchLoot[LOOT_EXPLOSIVE_MAX] = CVarWitchLoot[LOOT_EXPLOSIVE_MAX].IntValue;
	WitchLoot[LOOT_INCENDIARY_MIN] = CVarWitchLoot[LOOT_INCENDIARY_MIN].IntValue;
	WitchLoot[LOOT_INCENDIARY_MAX] = CVarWitchLoot[LOOT_INCENDIARY_MAX].IntValue;
	WitchLoot[LOOT_ADRENALINE_MIN] = CVarWitchLoot[LOOT_ADRENALINE_MIN].IntValue;
	WitchLoot[LOOT_ADRENALINE_MAX] = CVarWitchLoot[LOOT_ADRENALINE_MAX].IntValue;
	WitchLoot[LOOT_VOMITJAR_MIN] = CVarWitchLoot[LOOT_VOMITJAR_MIN].IntValue;
	WitchLoot[LOOT_VOMITJAR_MAX] = CVarWitchLoot[LOOT_VOMITJAR_MAX].IntValue;

	SpitterLoot[LOOT_DIENUMBER] = CVarSpitterLoot[LOOT_DIENUMBER].IntValue;
	SpitterLoot[LOOT_DIECOUNT] = CVarSpitterLoot[LOOT_DIECOUNT].IntValue;
	SpitterLoot[LOOT_KIT_MIN] = CVarSpitterLoot[LOOT_KIT_MIN].IntValue;
	SpitterLoot[LOOT_KIT_MAX] = CVarSpitterLoot[LOOT_KIT_MAX].IntValue;
	SpitterLoot[LOOT_PILLS_MIN] = CVarSpitterLoot[LOOT_PILLS_MIN].IntValue;
	SpitterLoot[LOOT_PILLS_MAX] = CVarSpitterLoot[LOOT_PILLS_MAX].IntValue;
	SpitterLoot[LOOT_MOLLY_MIN] = CVarSpitterLoot[LOOT_MOLLY_MIN].IntValue;
	SpitterLoot[LOOT_MOLLY_MAX] = CVarSpitterLoot[LOOT_MOLLY_MAX].IntValue;
	SpitterLoot[LOOT_PIPE_MIN] = CVarSpitterLoot[LOOT_PIPE_MIN].IntValue;
	SpitterLoot[LOOT_PIPE_MAX] = CVarSpitterLoot[LOOT_PIPE_MAX].IntValue;
	SpitterLoot[LOOT_ITEM_COUNT] = CVarSpitterLoot[LOOT_ITEM_COUNT].IntValue;

	SpitterLoot[LOOT_PANIC_MIN] = CVarSpitterLoot[LOOT_PANIC_MIN].IntValue;
	SpitterLoot[LOOT_PANIC_MAX] = CVarSpitterLoot[LOOT_PANIC_MAX].IntValue;
	SpitterLoot[LOOT_TANK_MIN] = CVarSpitterLoot[LOOT_TANK_MIN].IntValue;
	SpitterLoot[LOOT_TANK_MAX] = CVarSpitterLoot[LOOT_TANK_MAX].IntValue;
	SpitterLoot[LOOT_WITCH_MIN] = CVarSpitterLoot[LOOT_WITCH_MIN].IntValue;
	SpitterLoot[LOOT_WITCH_MAX] = CVarSpitterLoot[LOOT_WITCH_MAX].IntValue;
	SpitterLoot[LOOT_COMMON_MIN] = CVarSpitterLoot[LOOT_COMMON_MIN].IntValue;
	SpitterLoot[LOOT_COMMON_MAX] = CVarSpitterLoot[LOOT_COMMON_MAX].IntValue;

	SpitterLoot[LOOT_PISTOL_MIN] = CVarSpitterLoot[LOOT_PISTOL_MIN].IntValue;
	SpitterLoot[LOOT_PISTOL_MAX] = CVarSpitterLoot[LOOT_PISTOL_MAX].IntValue;
	SpitterLoot[LOOT_SMG_MIN] = CVarSpitterLoot[LOOT_SMG_MIN].IntValue;
	SpitterLoot[LOOT_SMG_MAX] = CVarSpitterLoot[LOOT_SMG_MAX].IntValue;
	SpitterLoot[LOOT_SHOT_MIN] = CVarSpitterLoot[LOOT_SHOT_MIN].IntValue;
	SpitterLoot[LOOT_SHOT_MAX] = CVarSpitterLoot[LOOT_SHOT_MAX].IntValue;
	SpitterLoot[LOOT_RIFLE_MIN] = CVarSpitterLoot[LOOT_RIFLE_MIN].IntValue;
	SpitterLoot[LOOT_RIFLE_MAX] = CVarSpitterLoot[LOOT_RIFLE_MAX].IntValue;
	SpitterLoot[LOOT_AUTOSHOT_MIN] = CVarSpitterLoot[LOOT_AUTOSHOT_MIN].IntValue;
	SpitterLoot[LOOT_AUTOSHOT_MAX] = CVarSpitterLoot[LOOT_AUTOSHOT_MAX].IntValue;
	SpitterLoot[LOOT_SNIPER_MIN] = CVarSpitterLoot[LOOT_SNIPER_MIN].IntValue;
	SpitterLoot[LOOT_SNIPER_MAX] = CVarSpitterLoot[LOOT_SNIPER_MAX].IntValue;
	SpitterLoot[LOOT_AK47_MIN] = CVarSpitterLoot[LOOT_AK47_MIN].IntValue;
	SpitterLoot[LOOT_AK47_MAX] = CVarSpitterLoot[LOOT_AK47_MAX].IntValue;
	SpitterLoot[LOOT_DEFIBRILLATOR_MIN] = CVarSpitterLoot[LOOT_DEFIBRILLATOR_MIN].IntValue;
	SpitterLoot[LOOT_DEFIBRILLATOR_MAX] = CVarSpitterLoot[LOOT_DEFIBRILLATOR_MAX].IntValue;
	SpitterLoot[LOOT_MILITARY_MIN] = CVarSpitterLoot[LOOT_MILITARY_MIN].IntValue;
	SpitterLoot[LOOT_MILITARY_MAX] = CVarSpitterLoot[LOOT_MILITARY_MAX].IntValue;
	SpitterLoot[LOOT_MAGNUM_MIN] = CVarSpitterLoot[LOOT_MAGNUM_MIN].IntValue;
	SpitterLoot[LOOT_MAGNUM_MAX] = CVarSpitterLoot[LOOT_MAGNUM_MAX].IntValue;
	SpitterLoot[LOOT_SPAS_MIN] = CVarSpitterLoot[LOOT_SPAS_MIN].IntValue;
	SpitterLoot[LOOT_SPAS_MAX] = CVarSpitterLoot[LOOT_SPAS_MAX].IntValue;
	SpitterLoot[LOOT_MELEE_MIN] = CVarSpitterLoot[LOOT_MELEE_MIN].IntValue;
	SpitterLoot[LOOT_MELEE_MAX] = CVarSpitterLoot[LOOT_MELEE_MAX].IntValue;
	SpitterLoot[LOOT_DESERT_MIN] = CVarSpitterLoot[LOOT_DESERT_MIN].IntValue;
	SpitterLoot[LOOT_DESERT_MAX] = CVarSpitterLoot[LOOT_DESERT_MAX].IntValue;
	SpitterLoot[LOOT_CHAINSAW_MIN] = CVarSpitterLoot[LOOT_CHAINSAW_MIN].IntValue;
	SpitterLoot[LOOT_CHAINSAW_MAX] = CVarSpitterLoot[LOOT_CHAINSAW_MAX].IntValue;
	SpitterLoot[LOOT_EXPLOSIVE_MIN] = CVarSpitterLoot[LOOT_EXPLOSIVE_MIN].IntValue;
	SpitterLoot[LOOT_EXPLOSIVE_MAX] = CVarSpitterLoot[LOOT_EXPLOSIVE_MAX].IntValue;
	SpitterLoot[LOOT_INCENDIARY_MIN] = CVarSpitterLoot[LOOT_INCENDIARY_MIN].IntValue;
	SpitterLoot[LOOT_INCENDIARY_MAX] = CVarSpitterLoot[LOOT_INCENDIARY_MAX].IntValue;
	SpitterLoot[LOOT_ADRENALINE_MIN] = CVarSpitterLoot[LOOT_ADRENALINE_MIN].IntValue;
	SpitterLoot[LOOT_ADRENALINE_MAX] = CVarSpitterLoot[LOOT_ADRENALINE_MAX].IntValue;
	SpitterLoot[LOOT_VOMITJAR_MIN] = CVarSpitterLoot[LOOT_VOMITJAR_MIN].IntValue;
	SpitterLoot[LOOT_VOMITJAR_MAX] = CVarSpitterLoot[LOOT_VOMITJAR_MAX].IntValue;

	ChargerLoot[LOOT_DIENUMBER] = CVarChargerLoot[LOOT_DIENUMBER].IntValue;
	ChargerLoot[LOOT_DIECOUNT] = CVarChargerLoot[LOOT_DIECOUNT].IntValue;
	ChargerLoot[LOOT_KIT_MIN] = CVarChargerLoot[LOOT_KIT_MIN].IntValue;
	ChargerLoot[LOOT_KIT_MAX] = CVarChargerLoot[LOOT_KIT_MAX].IntValue;
	ChargerLoot[LOOT_PILLS_MIN] = CVarChargerLoot[LOOT_PILLS_MIN].IntValue;
	ChargerLoot[LOOT_PILLS_MAX] = CVarChargerLoot[LOOT_PILLS_MAX].IntValue;
	ChargerLoot[LOOT_MOLLY_MIN] = CVarChargerLoot[LOOT_MOLLY_MIN].IntValue;
	ChargerLoot[LOOT_MOLLY_MAX] = CVarChargerLoot[LOOT_MOLLY_MAX].IntValue;
	ChargerLoot[LOOT_PIPE_MIN] = CVarChargerLoot[LOOT_PIPE_MIN].IntValue;
	ChargerLoot[LOOT_PIPE_MAX] = CVarChargerLoot[LOOT_PIPE_MAX].IntValue;
	ChargerLoot[LOOT_ITEM_COUNT] = CVarChargerLoot[LOOT_ITEM_COUNT].IntValue;
	
	ChargerLoot[LOOT_PANIC_MIN] = CVarChargerLoot[LOOT_PANIC_MIN].IntValue;
	ChargerLoot[LOOT_PANIC_MAX] = CVarChargerLoot[LOOT_PANIC_MAX].IntValue;
	ChargerLoot[LOOT_TANK_MIN] = CVarChargerLoot[LOOT_TANK_MIN].IntValue;
	ChargerLoot[LOOT_TANK_MAX] = CVarChargerLoot[LOOT_TANK_MAX].IntValue;
	ChargerLoot[LOOT_WITCH_MIN] = CVarChargerLoot[LOOT_WITCH_MIN].IntValue;
	ChargerLoot[LOOT_WITCH_MAX] = CVarChargerLoot[LOOT_WITCH_MAX].IntValue;
	ChargerLoot[LOOT_COMMON_MIN] = CVarChargerLoot[LOOT_COMMON_MIN].IntValue;
	ChargerLoot[LOOT_COMMON_MAX] = CVarChargerLoot[LOOT_COMMON_MAX].IntValue;

	ChargerLoot[LOOT_PISTOL_MIN] = CVarChargerLoot[LOOT_PISTOL_MIN].IntValue;
	ChargerLoot[LOOT_PISTOL_MAX] = CVarChargerLoot[LOOT_PISTOL_MAX].IntValue;
	ChargerLoot[LOOT_SMG_MIN] = CVarChargerLoot[LOOT_SMG_MIN].IntValue;
	ChargerLoot[LOOT_SMG_MAX] = CVarChargerLoot[LOOT_SMG_MAX].IntValue;
	ChargerLoot[LOOT_SHOT_MIN] = CVarChargerLoot[LOOT_SHOT_MIN].IntValue;
	ChargerLoot[LOOT_SHOT_MAX] = CVarChargerLoot[LOOT_SHOT_MAX].IntValue;
	ChargerLoot[LOOT_RIFLE_MIN] = CVarChargerLoot[LOOT_RIFLE_MIN].IntValue;
	ChargerLoot[LOOT_RIFLE_MAX] = CVarChargerLoot[LOOT_RIFLE_MAX].IntValue;
	ChargerLoot[LOOT_AUTOSHOT_MIN] = CVarChargerLoot[LOOT_AUTOSHOT_MIN].IntValue;
	ChargerLoot[LOOT_AUTOSHOT_MAX] = CVarChargerLoot[LOOT_AUTOSHOT_MAX].IntValue;
	ChargerLoot[LOOT_SNIPER_MIN] = CVarChargerLoot[LOOT_SNIPER_MIN].IntValue;
	ChargerLoot[LOOT_SNIPER_MAX] = CVarChargerLoot[LOOT_SNIPER_MAX].IntValue;
	ChargerLoot[LOOT_AK47_MIN] = CVarChargerLoot[LOOT_AK47_MIN].IntValue;
	ChargerLoot[LOOT_AK47_MAX] = CVarChargerLoot[LOOT_AK47_MAX].IntValue;
	ChargerLoot[LOOT_DEFIBRILLATOR_MIN] = CVarChargerLoot[LOOT_DEFIBRILLATOR_MIN].IntValue;
	ChargerLoot[LOOT_DEFIBRILLATOR_MAX] = CVarChargerLoot[LOOT_DEFIBRILLATOR_MAX].IntValue;
	ChargerLoot[LOOT_MILITARY_MIN] = CVarChargerLoot[LOOT_MILITARY_MIN].IntValue;
	ChargerLoot[LOOT_MILITARY_MAX] = CVarChargerLoot[LOOT_MILITARY_MAX].IntValue;
	ChargerLoot[LOOT_MAGNUM_MIN] = CVarChargerLoot[LOOT_MAGNUM_MIN].IntValue;
	ChargerLoot[LOOT_MAGNUM_MAX] = CVarChargerLoot[LOOT_MAGNUM_MAX].IntValue;
	ChargerLoot[LOOT_SPAS_MIN] = CVarChargerLoot[LOOT_SPAS_MIN].IntValue;
	ChargerLoot[LOOT_SPAS_MAX] = CVarChargerLoot[LOOT_SPAS_MAX].IntValue;
	ChargerLoot[LOOT_MELEE_MIN] = CVarChargerLoot[LOOT_MELEE_MIN].IntValue;
	ChargerLoot[LOOT_MELEE_MAX] = CVarChargerLoot[LOOT_MELEE_MAX].IntValue;
	ChargerLoot[LOOT_DESERT_MIN] = CVarChargerLoot[LOOT_DESERT_MIN].IntValue;
	ChargerLoot[LOOT_DESERT_MAX] = CVarChargerLoot[LOOT_DESERT_MAX].IntValue;
	ChargerLoot[LOOT_CHAINSAW_MIN] = CVarChargerLoot[LOOT_CHAINSAW_MIN].IntValue;
	ChargerLoot[LOOT_CHAINSAW_MAX] = CVarChargerLoot[LOOT_CHAINSAW_MAX].IntValue;
	ChargerLoot[LOOT_EXPLOSIVE_MIN] = CVarChargerLoot[LOOT_EXPLOSIVE_MIN].IntValue;
	ChargerLoot[LOOT_EXPLOSIVE_MAX] = CVarChargerLoot[LOOT_EXPLOSIVE_MAX].IntValue;
	ChargerLoot[LOOT_INCENDIARY_MIN] = CVarChargerLoot[LOOT_INCENDIARY_MIN].IntValue;
	ChargerLoot[LOOT_INCENDIARY_MAX] = CVarChargerLoot[LOOT_INCENDIARY_MAX].IntValue;
	ChargerLoot[LOOT_ADRENALINE_MIN] = CVarChargerLoot[LOOT_ADRENALINE_MIN].IntValue;
	ChargerLoot[LOOT_ADRENALINE_MAX] = CVarChargerLoot[LOOT_ADRENALINE_MAX].IntValue;
	ChargerLoot[LOOT_VOMITJAR_MIN] = CVarChargerLoot[LOOT_VOMITJAR_MIN].IntValue;
	ChargerLoot[LOOT_VOMITJAR_MAX] = CVarChargerLoot[LOOT_VOMITJAR_MAX].IntValue;

	JockeyLoot[LOOT_DIENUMBER] = CVarJockeyLoot[LOOT_DIENUMBER].IntValue;
	JockeyLoot[LOOT_DIECOUNT] = CVarJockeyLoot[LOOT_DIECOUNT].IntValue;
	JockeyLoot[LOOT_KIT_MIN] = CVarJockeyLoot[LOOT_KIT_MIN].IntValue;
	JockeyLoot[LOOT_KIT_MAX] = CVarJockeyLoot[LOOT_KIT_MAX].IntValue;
	JockeyLoot[LOOT_PILLS_MIN] = CVarJockeyLoot[LOOT_PILLS_MIN].IntValue;
	JockeyLoot[LOOT_PILLS_MAX] = CVarJockeyLoot[LOOT_PILLS_MAX].IntValue;
	JockeyLoot[LOOT_MOLLY_MIN] = CVarJockeyLoot[LOOT_MOLLY_MIN].IntValue;
	JockeyLoot[LOOT_MOLLY_MAX] = CVarJockeyLoot[LOOT_MOLLY_MAX].IntValue;
	JockeyLoot[LOOT_PIPE_MIN] = CVarJockeyLoot[LOOT_PIPE_MIN].IntValue;
	JockeyLoot[LOOT_PIPE_MAX] = CVarJockeyLoot[LOOT_PIPE_MAX].IntValue;
	JockeyLoot[LOOT_ITEM_COUNT] = CVarJockeyLoot[LOOT_ITEM_COUNT].IntValue;

	JockeyLoot[LOOT_PANIC_MIN] = CVarJockeyLoot[LOOT_PANIC_MIN].IntValue;
	JockeyLoot[LOOT_PANIC_MAX] = CVarJockeyLoot[LOOT_PANIC_MAX].IntValue;
	JockeyLoot[LOOT_TANK_MIN] = CVarJockeyLoot[LOOT_TANK_MIN].IntValue;
	JockeyLoot[LOOT_TANK_MAX] = CVarJockeyLoot[LOOT_TANK_MAX].IntValue;
	JockeyLoot[LOOT_WITCH_MIN] = CVarJockeyLoot[LOOT_WITCH_MIN].IntValue;
	JockeyLoot[LOOT_WITCH_MAX] = CVarJockeyLoot[LOOT_WITCH_MAX].IntValue;
	JockeyLoot[LOOT_COMMON_MIN] = CVarJockeyLoot[LOOT_COMMON_MIN].IntValue;
	JockeyLoot[LOOT_COMMON_MAX] = CVarJockeyLoot[LOOT_COMMON_MAX].IntValue;

	JockeyLoot[LOOT_PISTOL_MIN] = CVarJockeyLoot[LOOT_PISTOL_MIN].IntValue;
	JockeyLoot[LOOT_PISTOL_MAX] = CVarJockeyLoot[LOOT_PISTOL_MAX].IntValue;
	JockeyLoot[LOOT_SMG_MIN] = CVarJockeyLoot[LOOT_SMG_MIN].IntValue;
	JockeyLoot[LOOT_SMG_MAX] = CVarJockeyLoot[LOOT_SMG_MAX].IntValue;
	JockeyLoot[LOOT_SHOT_MIN] = CVarJockeyLoot[LOOT_SHOT_MIN].IntValue;
	JockeyLoot[LOOT_SHOT_MAX] = CVarJockeyLoot[LOOT_SHOT_MAX].IntValue;
	JockeyLoot[LOOT_RIFLE_MIN] = CVarJockeyLoot[LOOT_RIFLE_MIN].IntValue;
	JockeyLoot[LOOT_RIFLE_MAX] = CVarJockeyLoot[LOOT_RIFLE_MAX].IntValue;
	JockeyLoot[LOOT_AUTOSHOT_MIN] = CVarJockeyLoot[LOOT_AUTOSHOT_MIN].IntValue;
	JockeyLoot[LOOT_AUTOSHOT_MAX] = CVarJockeyLoot[LOOT_AUTOSHOT_MAX].IntValue;
	JockeyLoot[LOOT_SNIPER_MIN] = CVarJockeyLoot[LOOT_SNIPER_MIN].IntValue;
	JockeyLoot[LOOT_SNIPER_MAX] = CVarJockeyLoot[LOOT_SNIPER_MAX].IntValue;
	JockeyLoot[LOOT_AK47_MIN] = CVarJockeyLoot[LOOT_AK47_MIN].IntValue;
	JockeyLoot[LOOT_AK47_MAX] = CVarJockeyLoot[LOOT_AK47_MAX].IntValue;
	JockeyLoot[LOOT_DEFIBRILLATOR_MIN] = CVarJockeyLoot[LOOT_DEFIBRILLATOR_MIN].IntValue;
	JockeyLoot[LOOT_DEFIBRILLATOR_MAX] = CVarJockeyLoot[LOOT_DEFIBRILLATOR_MAX].IntValue;
	JockeyLoot[LOOT_MILITARY_MIN] = CVarJockeyLoot[LOOT_MILITARY_MIN].IntValue;
	JockeyLoot[LOOT_MILITARY_MAX] = CVarJockeyLoot[LOOT_MILITARY_MAX].IntValue;
	JockeyLoot[LOOT_MAGNUM_MIN] = CVarJockeyLoot[LOOT_MAGNUM_MIN].IntValue;
	JockeyLoot[LOOT_MAGNUM_MAX] = CVarJockeyLoot[LOOT_MAGNUM_MAX].IntValue;
	JockeyLoot[LOOT_SPAS_MIN] = CVarJockeyLoot[LOOT_SPAS_MIN].IntValue;
	JockeyLoot[LOOT_SPAS_MAX] = CVarJockeyLoot[LOOT_SPAS_MAX].IntValue;
	JockeyLoot[LOOT_MELEE_MIN] = CVarJockeyLoot[LOOT_MELEE_MIN].IntValue;
	JockeyLoot[LOOT_MELEE_MAX] = CVarJockeyLoot[LOOT_MELEE_MAX].IntValue;
	JockeyLoot[LOOT_DESERT_MIN] = CVarJockeyLoot[LOOT_DESERT_MIN].IntValue;
	JockeyLoot[LOOT_DESERT_MAX] = CVarJockeyLoot[LOOT_DESERT_MAX].IntValue;
	JockeyLoot[LOOT_CHAINSAW_MIN] = CVarJockeyLoot[LOOT_CHAINSAW_MIN].IntValue;
	JockeyLoot[LOOT_CHAINSAW_MAX] = CVarJockeyLoot[LOOT_CHAINSAW_MAX].IntValue;
	JockeyLoot[LOOT_EXPLOSIVE_MIN] = CVarJockeyLoot[LOOT_EXPLOSIVE_MIN].IntValue;
	JockeyLoot[LOOT_EXPLOSIVE_MAX] = CVarJockeyLoot[LOOT_EXPLOSIVE_MAX].IntValue;
	JockeyLoot[LOOT_INCENDIARY_MIN] = CVarJockeyLoot[LOOT_INCENDIARY_MIN].IntValue;
	JockeyLoot[LOOT_INCENDIARY_MAX] = CVarJockeyLoot[LOOT_INCENDIARY_MAX].IntValue;
	JockeyLoot[LOOT_ADRENALINE_MIN] = CVarJockeyLoot[LOOT_ADRENALINE_MIN].IntValue;
	JockeyLoot[LOOT_ADRENALINE_MAX] = CVarJockeyLoot[LOOT_ADRENALINE_MAX].IntValue;
	JockeyLoot[LOOT_VOMITJAR_MIN] = CVarJockeyLoot[LOOT_VOMITJAR_MIN].IntValue;
	JockeyLoot[LOOT_VOMITJAR_MAX] = CVarJockeyLoot[LOOT_VOMITJAR_MAX].IntValue;
}

Action Event_PlayerDeath(Event hEvent, const char[] strName, bool DontBroadcast)
{
	char strBuffer[55];
	//qwerty search key
	int ClientId    = 0;
	ClientId = GetClientOfUserId(hEvent.GetInt("userid"));
	if (ClientId == 0) 
	{
		// We had 0 so it MAY be a witch, check.
		GetEntityNetClass(hEvent.GetInt("entityid"), strBuffer, sizeof(strBuffer));
		if (StrEqual(strBuffer, "Witch", false))
		{
			/*
			// TODO: Add witch functionallity
			// Witch Functionality Added Below,
			// This segment left in for error testing.
			//TellAll("entityid check");
			// Visual Check
			////LogMessage("entityid check");
			// Log Check
			*/
		}
		return Plugin_Continue;
	}

	int class = GetEntProp(ClientId, Prop_Send, "m_zombieClass");
	if (class == ZOMBIECLASS_HUNTER)
	{
		//LogMessage("[DICE] Hunter killed: Rolling for %i items.", HunterLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < HunterLoot[LOOT_ITEM_COUNT]; i++)
		{
			//LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[HunterLoot[LOOT_DIENUMBER] - 1], HunterLoot[LOOT_DIECOUNT]);

			SpawnItemFromDieResult(ClientId, HunterLoot, RollDice(HunterLoot[LOOT_DIECOUNT], HunterLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_SMOKER)
	{
		//LogMessage("[DICE] Smoker killed: Rolling for %i items.", SmokerLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < SmokerLoot[LOOT_ITEM_COUNT]; i++)
		{
			//LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[SmokerLoot[LOOT_DIENUMBER] - 1], SmokerLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, SmokerLoot, RollDice(SmokerLoot[LOOT_DIECOUNT], SmokerLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_BOOMER)
	{
		//LogMessage("[DICE] Boomer killed: Rolling for %i items.", BoomerLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < BoomerLoot[LOOT_ITEM_COUNT]; i++)
		{
			//LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[BoomerLoot[LOOT_DIENUMBER] - 1], BoomerLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, BoomerLoot, RollDice(BoomerLoot[LOOT_DIECOUNT], BoomerLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_SPITTER)
	{
		//LogMessage("[DICE] Spitter killed: Rolling for %i items.", SpitterLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < SpitterLoot[LOOT_ITEM_COUNT]; i++)
		{
			//LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[SpitterLoot[LOOT_DIENUMBER] - 1], SpitterLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, SpitterLoot, RollDice(SpitterLoot[LOOT_DIECOUNT], SpitterLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_CHARGER)
	{
		//LogMessage("[DICE] Charger killed: Rolling for %i items.", ChargerLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < ChargerLoot[LOOT_ITEM_COUNT]; i++)
		{
			//LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[ChargerLoot[LOOT_DIENUMBER] - 1], ChargerLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, ChargerLoot, RollDice(ChargerLoot[LOOT_DIECOUNT], ChargerLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_JOCKEY)
	{
		//LogMessage("[DICE] Jockey killed: Rolling for %i items.", JockeyLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < JockeyLoot[LOOT_ITEM_COUNT]; i++)
		{
			//LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[JockeyLoot[LOOT_DIENUMBER] - 1], JockeyLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, JockeyLoot, RollDice(JockeyLoot[LOOT_DIECOUNT], JockeyLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_WITCH)
	{
		if (witchSpawn != 0)
		{
			numWitch -= 1;
			witchSpawn -= 1;
			if (witchSpawn < 0)
			{
				witchSpawn = 0;
			}
			TellHumans("Witch Lottery Enabled!");
		}
		else
		{
			TellHumans("Didn't Kill My Witch...");
		}
		//LogMessage("[DICE] Witch killed: Rolling for %i items.", WitchLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < WitchLoot[LOOT_ITEM_COUNT]; i++)
		{
			//LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[WitchLoot[LOOT_DIENUMBER] - 1], WitchLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, WitchLoot, RollDice(WitchLoot[LOOT_DIECOUNT], WitchLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_TANK)
	{
		if (tankSpawn != 0)
		{
			numTank -= 1;
			tankSpawn -= 1;
			if (tankSpawn < 0)
			{
				tankSpawn = 0;
			}
			TellHumans("Tank Lottery Enabled!");
		}
		else
		{
			TellHumans("Didn't Kill My Tank...");
		}
		//LogMessage("[DICE] Tank killed: Rolling for %i items.", TankLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < TankLoot[LOOT_ITEM_COUNT]; i++)
		{
			//LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[TankLoot[LOOT_DIENUMBER] - 1], TankLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, TankLoot, RollDice(TankLoot[LOOT_DIECOUNT], TankLoot[LOOT_DIENUMBER]));
		}
	}
	return Plugin_Continue;
}

void ExecuteCommand(int Client, char[] strCommand, char[] strParam1)
{
	int flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}

void ForcePanicEvent(int client)
{
	char command[] = "director_force_panic_event";
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, command);
	SetCommandFlags(command, flags);
}

void TellHumans(char[] msg)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) == 2) PrintHintText(i, msg);
	}
}

void TellInfected(char[] msg)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) == 3) PrintHintText(i, msg);
	}
}

void TellAll(char[] msg)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i) > 1) PrintHintText(i, msg);
	}
}

void Give(int Client, char[] itemId, char[] playerMsg, bool sim = false)
{
	if (sim == false)
	{
		ExecuteCommand(Client, "give", itemId);
		//LogMessage("[DICE] Spawned %s.", itemId);
		if (!StrEqual(playerMsg, "")) TellHumans(playerMsg);
	}
	else PrintToServer("[DICE SIM] Spawned %s.", itemId);
}

int RollDice(int dieCount, int dieId, bool sim = false)
{
	if (dieId == 0) return 0;
	
	int dieSides = Dice[dieId - 1];
	int result = 0;
	for (int i = 0; i < dieCount; i++)
	{
		int tempResult = GetRandomInt(0, dieSides);
		if (tempResult != 0)
		{
			result += tempResult;
		}

		if (sim == false)
		{
			//LogMessage("[DICE] Die %i, Result: %i, Total: %i", i + 1, tempResult, result);
		}
		else
		{
			PrintToServer("[DICE SIM] Die %i, Result: %i, Total: %i", i + 1, tempResult, result);
		}
	}
	return result;
}

void SpawnItemFromDieResult(int client, int diceSettings[55], int dieResult, bool sim = false)
{
	if (dieResult != 0)
	{
//		PrintSettings(diceSettings);
		if (dieResult >= diceSettings[LOOT_KIT_MIN] && dieResult <= diceSettings[LOOT_KIT_MAX])
			Give(client, "first_aid_kit", "", sim);
		else if (dieResult >= diceSettings[LOOT_MOLLY_MIN] && dieResult <= diceSettings[LOOT_MOLLY_MAX])
			Give(client, "molotov", "", sim);
		else if (dieResult >= diceSettings[LOOT_PIPE_MIN] && dieResult <= diceSettings[LOOT_PIPE_MAX])
			Give(client, "pipe_bomb", "", sim);
		else if (dieResult >= diceSettings[LOOT_PILLS_MIN] && dieResult <= diceSettings[LOOT_PILLS_MAX])
			Give(client, "pain_pills", "", sim);
		else if (dieResult >= diceSettings[LOOT_DEFIBRILLATOR_MIN] && dieResult <= diceSettings[LOOT_DEFIBRILLATOR_MAX])
			Give(client, "defibrillator", "", sim);
		else if (dieResult >= diceSettings[LOOT_EXPLOSIVE_MIN] && dieResult <= diceSettings[LOOT_EXPLOSIVE_MAX])
			Give(client, "upgradepack_explosive", "", sim);
		else if (dieResult >= diceSettings[LOOT_INCENDIARY_MIN] && dieResult <= diceSettings[LOOT_INCENDIARY_MAX])
			Give(client, "upgradepack_incendiary", "", sim);
		else if (dieResult >= diceSettings[LOOT_ADRENALINE_MIN] && dieResult <= diceSettings[LOOT_ADRENALINE_MAX])
			Give(client, "adrenaline", "", sim);
		else if (dieResult >= diceSettings[LOOT_VOMITJAR_MIN] && dieResult <= diceSettings[LOOT_VOMITJAR_MAX])
			Give(client, "vomitjar", "", sim);
		else if (dieResult >= diceSettings[LOOT_PANIC_MIN] && dieResult <= diceSettings[LOOT_PANIC_MAX])
		{
			if (!sim)
			{
				if (numPanic < GetConVarInt(panicMax) + 1)
				{
					numPanic += 1;
					ForcePanicEvent(client);
					TellHumans("Incoming Panic Event...");
					TellInfected("The Zombies Are Panicking...");
					//LogMessage("[DICE] Spawned Panic Event.");
				}
				else
				{
					TellAll("Panic Event Round Lottery Limit Reached...");
				}
			}
			else
			{
				PrintToServer("[DICE SIM] Spawned Panic Event");
			}
		}
		else if (dieResult >= diceSettings[LOOT_TANK_MIN] && dieResult <= diceSettings[LOOT_TANK_MAX])
		{
			if (!sim)
			{
				//Check to see if tank map limit reached.
				if (numTankMax < GetConVarInt(tankMapMax))
				{
					//Increase numTankMax to force tank map spawn restriction.
					numTankMax += 1;
					//Check to see if tank alive limit reached.
					//If not, spawn a tank.
					if (numTank < GetConVarInt(tankMax))
					// was (tankMax) +1 )
					{
						tankSpawn += 1;
						numTank += 1;
						ExecuteCommand(client, "z_spawn", "tank auto");
						TellHumans("A Tank Is Coming...");
						TellInfected("Tank...");
						//LogMessage("[DICE] Spawned Tank.");
					}
					else
					{
						TellAll("Tank Lottery Allowance Detected...");
					}
				}
				else
				{
					TellAll("Tank Round Lottery Limit Reached...");
				}
			}
			else
			{
				PrintToServer("[DICE SIM] Spawned Tank");
			}
		}
		else if (dieResult >= diceSettings[LOOT_WITCH_MIN] && dieResult <= diceSettings[LOOT_WITCH_MAX])
		{
			if (!sim)
			{
				//Check to see if witch map limit reached.
				if (numWitchMax < GetConVarInt(witchMapMax))
				{
					//Increase numWitchMax to force witch map spawn restriction.
					numWitchMax += 1;
					//Check to see if witch alive limit reached.
					//If not, spawn a witch.
					if (numWitch < GetConVarInt(witchMax))
					{
						// was (witchMax) + 1)
						witchSpawn += 1;
						numWitch += 1;
						ExecuteCommand(client, "z_spawn", "witch auto");
						TellHumans("A Witch Has Appeared...");
						TellInfected("Witch...");
						//LogMessage("[DICE] Spawned Witch.");
					}
					else
					{
						TellAll("Witch Lottery Allowance Detected...");
					}
				}
				else
				{
					TellAll("Witch Round Lottery Limit Reached...");
				}
			}
			else
			{
				PrintToServer("[DICE SIM] Spawned Witch");
			}
		}
		else if (dieResult >= diceSettings[LOOT_COMMON_MIN] && dieResult <= diceSettings[LOOT_COMMON_MAX])
		{
			if (!sim)
			{
				ExecuteCommand(client, "z_spawn", "common");
				ExecuteCommand(client, "z_spawn", "common");
				ExecuteCommand(client, "z_spawn", "common auto");
				ExecuteCommand(client, "z_spawn", "common");
				ExecuteCommand(client, "z_spawn", "common");
				ExecuteCommand(client, "z_spawn", "common auto");
				ExecuteCommand(client, "z_spawn", "common");
				ExecuteCommand(client, "z_spawn", "common");
				ExecuteCommand(client, "z_spawn", "common auto");
				ExecuteCommand(client, "z_spawn", "common");

				//LogMessage("[DICE] Spawned Commons.");
			}
			else
			{
				PrintToServer("[DICE SIM] Spawned Commons");
			}
		}
		else if (dieResult >= diceSettings[LOOT_PISTOL_MIN] && dieResult <= diceSettings[LOOT_PISTOL_MAX])
			Give(client, "pistol", "", sim);
		else if (dieResult >= diceSettings[LOOT_SMG_MIN] && dieResult <= diceSettings[LOOT_SMG_MAX])
			Give(client, "smg", "", sim);
		else if (dieResult >= diceSettings[LOOT_SHOT_MIN] && dieResult <= diceSettings[LOOT_SHOT_MAX])
			Give(client, "pumpshotgun", "", sim);
		else if (dieResult >= diceSettings[LOOT_RIFLE_MIN] && dieResult <= diceSettings[LOOT_RIFLE_MAX])
			Give(client, "rifle", "", sim);
		else if (dieResult >= diceSettings[LOOT_AUTOSHOT_MIN] && dieResult <= diceSettings[LOOT_AUTOSHOT_MAX])
			Give(client, "autoshotgun", "", sim);
		else if (dieResult >= diceSettings[LOOT_SNIPER_MIN] && dieResult <= diceSettings[LOOT_SNIPER_MAX])
			Give(client, "hunting_rifle", "", sim);
		else if (dieResult >= diceSettings[LOOT_AK47_MIN] && dieResult <= diceSettings[LOOT_AK47_MAX])
			Give(client, "rifle_ak47", "", sim);
		else if (dieResult >= diceSettings[LOOT_MILITARY_MIN] && dieResult <= diceSettings[LOOT_MILITARY_MAX])
			Give(client, "sniper_military", "", sim);
		else if (dieResult >= diceSettings[LOOT_SPAS_MIN] && dieResult <= diceSettings[LOOT_SPAS_MAX])
			Give(client, "shotgun_spas", "", sim);
		else if (dieResult >= diceSettings[LOOT_MAGNUM_MIN] && dieResult <= diceSettings[LOOT_MAGNUM_MAX])
			Give(client, "pistol_magnum", "", sim);
		else if (dieResult >= diceSettings[LOOT_MELEE_MIN] && dieResult <= diceSettings[LOOT_MELEE_MAX])
			Give(client, "melee", "", sim);
		else if (dieResult >= diceSettings[LOOT_DESERT_MIN] && dieResult <= diceSettings[LOOT_DESERT_MAX])
			Give(client, "rifle_desert", "", sim);
		else if (dieResult >= diceSettings[LOOT_CHAINSAW_MIN] && dieResult <= diceSettings[LOOT_CHAINSAW_MAX])
			Give(client, "chainsaw", "", sim);
	}
}