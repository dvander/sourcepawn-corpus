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

#define CVAR_FLAGS FCVAR_NONE
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

int numTank;
int numTankMax;
int tankSpawn;
int numWitch;
int numWitchMax;
int witchSpawn;
int numPanic;

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

	CreateConVar("l4d2_loot_ver", PLUGIN_VERSION, "Version of the infected loot drops plugins.", FCVAR_SPONLY|FCVAR_NOTIFY);

	CVarIsEnabled = CreateConVar("l4d_loot_enabled", "1", "Is the plugin enabled.");
	HookConVarChange(CVarIsEnabled, Loot_EnableDisable);

	HookEvent("round_start", Event_RoundStart); // Allow tank, witch, panic limit/round.
	
	tankMax = CreateConVar("l4d_loot_tank_max","1","Number of tanks allowed to spawn/live at a time/round.", CVAR_FLAGS, true, 0.0);
	witchMax = CreateConVar("l4d_loot_witch_max","3","Number of witches allowed to spawn/live at a time/round.", CVAR_FLAGS, true, 0.0);
	tankMapMax = CreateConVar("l4d_loot_tank_map_max","5","Total Number of Tanks plugin can spawn per map.", CVAR_FLAGS, true, 0.0);
	witchMapMax = CreateConVar("l4d_loot_witch_map_max","10","Total Number of Witches plugin can spawn per map.", CVAR_FLAGS, true, 0.0);
	panicMax = CreateConVar("l4d_loot_panic_map_max","15","Total Number of Witches plugin can spawn per map.", CVAR_FLAGS, true, 0.0);

	CVarDieSides[0] = CreateConVar("l4d_loot_dice1_sides", "50", "How many sides die 1 has.", 0);
	CVarDieSides[1] = CreateConVar("l4d_loot_dice2_sides", "50", "How many sides die 2 has.", 0);
	CVarDieSides[2] = CreateConVar("l4d_loot_dice3_sides", "40", "How many sides die 3 has.", 0);
	CVarDieSides[3] = CreateConVar("l4d_loot_dice4_sides", "100", "How many sides die 4 has.", 0);
		
	CVarHunterLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_hunter_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", 0, true, 1.0, true, 4.0);
	CVarHunterLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_hunter_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", 0, true, 1.0, true, 3.0);
	CVarHunterLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_hunter_item_count", "3", "How many items are rolled for when the witch dies.", 0, true, 0.0);	
	
	CVarHunterLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_hunter_kit_min", "1", "Min die number for a hunter to drop a kit.", 0, true, 0.0);
	CVarHunterLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_hunter_kit_max", "3", "Max die number for a hunter to drop a kit.", 0, true, 0.0);
	CVarHunterLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_hunter_pills_min",	"3", "Min die number for a hunter to drop pills.", 0, true, 0.0);
	CVarHunterLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_hunter_pills_max",	"8", "Max die number for a hunter to drop pills.", 0, true, 0.0);
	CVarHunterLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_hunter_molly_min",	"5", "Min die number for a hunter to drop a molitov.", 0, true, 0.0);
	CVarHunterLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_hunter_molly_max",	"10", "Max die number for a hunter to drop a molitov.", 0, true, 0.0);
	CVarHunterLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_hunter_pipe_min", "7", "Min die number for a hunter to drop a pipe bomb.", 0, true, 0.0);
	CVarHunterLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_hunter_pipe_max", "10", "Max die number for a hunter to drop a pipe bomb.", 0, true, 0.0);
	
	CVarHunterLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_hunter_panic_min",	"10", "Min die number for a hunter to cause a zombie panic event.", 0, true, 0.0);
	CVarHunterLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_hunter_panic_max",	"13", "Max die number for a hunter to cause a zombie panic event.", 0, true, 0.0);
	CVarHunterLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_hunter_tankspawn_min",	"13", "Min die number for a hunter to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarHunterLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_hunter_tankspawn_max",	"14", "Max die number for a hunter to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarHunterLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_hunter_witchspawn_min", "13", "Min die number for a hunter to cause a hunter to spawn nearby.", 0, true, 0.0);
	CVarHunterLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_hunter_witchspawn_max", "19", "Max die number for a hunter to cause a hunter to spawn nearby.", 0, true, 0.0);
	CVarHunterLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_hunter_common_min", "15", "Min die number for a hunter to cause common infected to spawn nearby.", 0, true, 0.0);
	CVarHunterLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_hunter_common_max", "25", "Max die number for a hunter to cause common infected to spawn nearby.", 0, true, 0.0);
	
	CVarHunterLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_hunter_pistol_min", "21", 	"Min die number for a hunter to drop a pistol.", 0, true, 0.0);
	CVarHunterLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_hunter_pistol_max", "40", 	"Max die number for a hunter to drop a pistol.", 0, true, 0.0);
	CVarHunterLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_hunter_smg_min", "22", "Min die number for a hunter to drop a small machine gun.", 0, true, 0.0);
	CVarHunterLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_hunter_smg_max", "35", "Max die number for a hunter to drop a small machine gun.", 0, true, 0.0);
	CVarHunterLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_hunter_shotgun_min", "23", "Min die number for a hunter to drop a shotgun.", 0, true, 0.0);
	CVarHunterLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_hunter_shotgun_max", "40", "Max die number for a hunter to drop a shotgun.", 0, true, 0.0);
	CVarHunterLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_hunter_rifle_min",	"24", "Min die number for a hunter to drop an auto rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_hunter_rifle_max",	"26", "Max die number for a hunter to drop an auto rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_hunter_autoshot_min", "24", "Min die number for a hunter to drop an auto shotgun.", 0, true, 0.0);
	CVarHunterLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_hunter_autoshot_max", "28", "Max die number for a hunter to drop an auto shotgun.", 0, true, 0.0);
	CVarHunterLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_hunter_sniper_min", "25", "Min die number for a hunter to drop a sniper rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_hunter_sniper_max", "28", "Max die number for a hunter to drop a sniper rifle.", 0, true, 0.0);	

	CVarHunterLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_hunter_military_min", "26", "Min die number for a hunter to drop a military rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_hunter_military_max", "30", "Max die number for a hunter to drop a military rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_hunter_ak47_min", "27", "Min die number for a hunter to drop a ak47 rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_hunter_ak47_max", "32", "Max die number for a hunter to drop a ak47 rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_hunter_defibrillator_min", "31", "Min die number for a hunter to drop a defibrillator.", 0, true, 0.0);
	CVarHunterLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_hunter_defibrillator_max", "35", "Max die number for a hunter to drop a defibrillator.", 0, true, 0.0);
	CVarHunterLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_hunter_magnum_min", "34", "Min die number for a hunter to drop a magnum.", 0, true, 0.0);
	CVarHunterLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_hunter_magnum_max", "40", "Max die number for a hunter to drop a magnum.", 0, true, 0.0);
	CVarHunterLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_hunter_spas_min", "37", "Min die number for a hunter to drop a spas shotgun.", 0, true, 0.0);
	CVarHunterLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_hunter_spas_max", "43", "Max die number for a hunter to drop a spas shotgun.", 0, true, 0.0);
	CVarHunterLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_hunter_melee_min", "40", "Min die number for a hunter to drop a melee.", 0, true, 0.0);
	CVarHunterLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_hunter_melee_max", "46", "Max die number for a hunter to drop a melee.", 0, true, 0.0);
	CVarHunterLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_hunter_desert_min", "43", "Min die number for a hunter to drop a desert rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_hunter_desert_max", "47", "Max die number for a hunter to drop a desert rifle.", 0, true, 0.0);
	CVarHunterLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_hunter_chainsaw_min", "0", "Min die number for a hunter to drop a chainsaw.", 0, true, 0.0);
	CVarHunterLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_hunter_chainsaw_max", "0", "Max die number for a hunter to drop a chainsaw.", 0, true, 0.0);
	CVarHunterLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_hunter_explosive_min", "46", "Min die number for a hunter to drop a explosive ammo.", 0, true, 0.0);
	CVarHunterLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_hunter_explosive_max", "49", "Max die number for a hunter to drop a explosive ammo.", 0, true, 0.0);
	CVarHunterLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_hunter_incendiary_min", "48", "Min die number for a hunter to drop a incendiary ammo.", 0, true, 0.0);
	CVarHunterLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_hunter_incendiary_max", "50", "Max die number for a hunter to drop a incendiary ammo.", 0, true, 0.0);
	CVarHunterLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_hunter_adrenaline_min", "40", "Min die number for a hunter to drop a adrenaline.", 0, true, 0.0);
	CVarHunterLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_hunter_adrenaline_max", "50", "Max die number for a hunter to drop a adrenaline.", 0, true, 0.0);
	CVarHunterLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_hunter_vomitjar_min", "49", "Min die number for a hunter to drop a vomitjar.", 0, true, 0.0);
	CVarHunterLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_hunter_vomitjar_max", "50", "Max die number for a hunter to drop a vomitjar.", 0, true, 0.0);

	CVarBoomerLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_boomer_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", 0, true, 1.0, true, 4.0);
	CVarBoomerLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_boomer_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", 0, true, 1.0, true, 3.0);
	CVarBoomerLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_boomer_item_count", "3", "How many items are rolled for when the witch dies.", 0, true, 0.0);	
	
	CVarBoomerLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_boomer_kit_min", "1", "Min die number for a boomer to drop a kit.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_boomer_kit_max", "3", "Max die number for a boomer to drop a kit.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_boomer_pills_min",	"2", "Min die number for a boomer to drop pills.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_boomer_pills_max",	"6", "Max die number for a boomer to drop pills.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_boomer_molly_min",	"5", "Min die number for a boomer to drop a molitov.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_boomer_molly_max",	"11", "Max die number for a boomer to drop a molitov.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_boomer_pipe_min", "7", "Min die number for a boomer to drop a pipe bomb.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_boomer_pipe_max", "15", "Max die number for a boomer to drop a pipe bomb.", 0, true, 0.0);
	
	CVarBoomerLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_boomer_panic_min",	"10", "Min die number for a boomer to cause a zombie panic event.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_boomer_panic_max",	"13", "Max die number for a boomer to cause a zombie panic event.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_boomer_tankspawn_min",	"12", "Min die number for a boomer to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_boomer_tankspawn_max",	"13", "Max die number for a boomer to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_boomer_witchspawn_min", "14", "Min die number for a boomer to cause a boomer to spawn nearby.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_boomer_witchspawn_max", "18", "Max die number for a boomer to cause a boomer to spawn nearby.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_boomer_common_min", "15", "Min die number for a boomer to cause common infected to spawn nearby.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_boomer_common_max", "25", "Max die number for a boomer to cause common infected to spawn nearby.", 0, true, 0.0);
	
	CVarBoomerLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_boomer_pistol_min", "21", 	"Min die number for a boomer to drop a pistol.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_boomer_pistol_max", "40", 	"Max die number for a boomer to drop a pistol.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_boomer_smg_min", "22", "Min die number for a boomer to drop a small machine gun.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_boomer_smg_max", "35", "Max die number for a boomer to drop a small machine gun.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_boomer_shotgun_min", "23", "Min die number for a boomer to drop a shotgun.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_boomer_shotgun_max", "40", "Max die number for a boomer to drop a shotgun.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_boomer_rifle_min",	"24", "Min die number for a boomer to drop an auto rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_boomer_rifle_max",	"30", "Max die number for a boomer to drop an auto rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_boomer_autoshot_min", "25", "Min die number for a boomer to drop an auto shotgun.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_boomer_autoshot_max", "28", "Max die number for a boomer to drop an auto shotgun.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_boomer_sniper_min", "26", "Min die number for a boomer to drop a sniper rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_boomer_sniper_max", "30", "Max die number for a boomer to drop a sniper rifle.", 0, true, 0.0);	

	CVarBoomerLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_boomer_military_min", "29", "Min die number for a boomer to drop a military rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_boomer_military_max", "32", "Max die number for a boomer to drop a military rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_boomer_ak47_min", "31", "Min die number for a boomer to drop a ak47 rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_boomer_ak47_max", "35", "Max die number for a boomer to drop a ak47 rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_boomer_defibrillator_min", "33", "Min die number for a boomer to drop a defibrillator.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_boomer_defibrillator_max", "36", "Max die number for a boomer to drop a defibrillator.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_boomer_magnum_min", "34", "Min die number for a boomer to drop a magnum.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_boomer_magnum_max", "41", "Max die number for a boomer to drop a magnum.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_boomer_spas_min", "41", "Min die number for a boomer to drop a spas shotgun.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_boomer_spas_max", "46", "Max die number for a boomer to drop a spas shotgun.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_boomer_melee_min", "42", "Min die number for a boomer to drop a melee.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_boomer_melee_max", "47", "Max die number for a boomer to drop a melee.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_boomer_desert_min", "41", "Min die number for a boomer to drop a desert rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_boomer_desert_max", "45", "Max die number for a boomer to drop a desert rifle.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_boomer_chainsaw_min", "0", "Min die number for a boomer to drop a chainsaw.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_boomer_chainsaw_max", "0", "Max die number for a boomer to drop a chainsaw.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_boomer_explosive_min", "40", "Min die number for a boomer to drop a explosive ammo.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_boomer_explosive_max", "49", "Max die number for a boomer to drop a explosive ammo.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_boomer_incendiary_min", "47", "Min die number for a boomer to drop a incendiary ammo.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_boomer_incendiary_max", "49", "Max die number for a boomer to drop a incendiary ammo.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_boomer_adrenaline_min", "47", "Min die number for a boomer to drop a adrenaline.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_boomer_adrenaline_max", "50", "Max die number for a boomer to drop a adrenaline.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_boomer_vomitjar_min", "40", "Min die number for a boomer to drop a vomitjar.", 0, true, 0.0);
	CVarBoomerLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_boomer_vomitjar_max", "50", "Max die number for a boomer to drop a vomitjar.", 0, true, 0.0);

	CVarSmokerLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_smoker_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", 0, true, 1.0, true, 4.0);
	CVarSmokerLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_smoker_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", 0, true, 1.0, true, 3.0);
	CVarSmokerLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_smoker_item_count", "3", "How many items are rolled for when the witch dies.", 0, true, 0.0);	
	
	CVarSmokerLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_smoker_kit_min", "1", "Min die number for a smoker to drop a kit.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_smoker_kit_max", "3", "Max die number for a smoker to drop a kit.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_smoker_pills_min",	"2", "Min die number for a smoker to drop pills.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_smoker_pills_max",	"8", "Max die number for a smoker to drop pills.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_smoker_molly_min",	"5", "Min die number for a smoker to drop a molitov.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_smoker_molly_max",	"11", "Max die number for a smoker to drop a molitov.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_smoker_pipe_min", "7", "Min die number for a smoker to drop a pipe bomb.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_smoker_pipe_max", "12", "Max die number for a smoker to drop a pipe bomb.", 0, true, 0.0);
	
	CVarSmokerLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_smoker_panic_min",	"8", "Min die number for a smoker to cause a zombie panic event.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_smoker_panic_max",	"11", "Max die number for a smoker to cause a zombie panic event.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_smoker_tankspawn_min",	"12", "Min die number for a smoker to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_smoker_tankspawn_max",	"13", "Max die number for a smoker to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_smoker_witchspawn_min", "12", "Min die number for a smoker to cause a smoker to spawn nearby.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_smoker_witchspawn_max", "16", "Max die number for a smoker to cause a smoker to spawn nearby.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_smoker_common_min", "15", "Min die number for a smoker to cause common infected to spawn nearby.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_smoker_common_max", "20", "Max die number for a smoker to cause common infected to spawn nearby.", 0, true, 0.0);
	
	CVarSmokerLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_smoker_pistol_min", "20", 	"Min die number for a smoker to drop a pistol.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_smoker_pistol_max", "40", 	"Max die number for a smoker to drop a pistol.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_smoker_smg_min", "22", "Min die number for a smoker to drop a small machine gun.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_smoker_smg_max", "35", "Max die number for a smoker to drop a small machine gun.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_smoker_shotgun_min", "23", "Min die number for a smoker to drop a shotgun.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_smoker_shotgun_max", "40", "Max die number for a smoker to drop a shotgun.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_smoker_rifle_min",	"24", "Min die number for a smoker to drop an auto rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_smoker_rifle_max",	"30", "Max die number for a smoker to drop an auto rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_smoker_autoshot_min", "25", "Min die number for a smoker to drop an auto shotgun.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_smoker_autoshot_max", "29", "Max die number for a smoker to drop an auto shotgun.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_smoker_sniper_min", "27", "Min die number for a smoker to drop a sniper rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_smoker_sniper_max", "30", "Max die number for a smoker to drop a sniper rifle.", 0, true, 0.0);	

	CVarSmokerLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_smoker_military_min", "29", "Min die number for a smoker to drop a military rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_smoker_military_max", "35", "Max die number for a smoker to drop a military rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_smoker_ak47_min", "28", "Min die number for a smoker to drop a ak47 rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_smoker_ak47_max", "34", "Max die number for a smoker to drop a ak47 rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_smoker_defibrillator_min", "32", "Min die number for a smoker to drop a defibrillator.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_smoker_defibrillator_max", "36", "Max die number for a smoker to drop a defibrillator.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_smoker_magnum_min", "33", "Min die number for a smoker to drop a magnum.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_smoker_magnum_max", "38", "Max die number for a smoker to drop a magnum.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_smoker_spas_min", "37", "Min die number for a smoker to drop a spas shotgun.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_smoker_spas_max", "43", "Max die number for a smoker to drop a spas shotgun.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_smoker_melee_min", "39", "Min die number for a smoker to drop a melee.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_smoker_melee_max", "45", "Max die number for a smoker to drop a melee.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_smoker_desert_min", "44", "Min die number for a smoker to drop a desert rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_smoker_desert_max", "47", "Max die number for a smoker to drop a desert rifle.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_smoker_chainsaw_min", "0", "Min die number for a smoker to drop a chainsaw.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_smoker_chainsaw_max", "0", "Max die number for a smoker to drop a chainsaw.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_smoker_explosive_min", "44", "Min die number for a smoker to drop a explosive ammo.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_smoker_explosive_max", "47", "Max die number for a smoker to drop a explosive ammo.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_smoker_incendiary_min", "45", "Min die number for a smoker to drop a incendiary ammo.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_smoker_incendiary_max", "48", "Max die number for a smoker to drop a incendiary ammo.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_smoker_adrenaline_min", "46", "Min die number for a smoker to drop a adrenaline.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_smoker_adrenaline_max", "50", "Max die number for a smoker to drop a adrenaline.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_smoker_vomitjar_min", "47", "Min die number for a smoker to drop a vomitjar.", 0, true, 0.0);
	CVarSmokerLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_smoker_vomitjar_max", "50", "Max die number for a smoker to drop a vomitjar.", 0, true, 0.0);

	CVarSpitterLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_spitter_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", 0, true, 1.0, true, 4.0);
	CVarSpitterLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_spitter_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", 0, true, 1.0, true, 3.0);
	CVarSpitterLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_spitter_item_count", "3", "How many items are rolled for when the witch dies.", 0, true, 0.0);	
	
	CVarSpitterLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_spitter_kit_min", "1", "Min die number for a spitter to drop a kit.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_spitter_kit_max", "3", "Max die number for a spitter to drop a kit.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_spitter_pills_min",	"3", "Min die number for a spitter to drop pills.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_spitter_pills_max",	"7", "Max die number for a spitter to drop pills.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_spitter_molly_min",	"8", "Min die number for a spitter to drop a molitov.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_spitter_molly_max",	"13", "Max die number for a spitter to drop a molitov.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_spitter_pipe_min", "12", "Min die number for a spitter to drop a pipe bomb.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_spitter_pipe_max", "15", "Max die number for a spitter to drop a pipe bomb.", 0, true, 0.0);
	
	CVarSpitterLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_spitter_panic_min",	"9", "Min die number for a spitter to cause a zombie panic event.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_spitter_panic_max",	"11", "Max die number for a spitter to cause a zombie panic event.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_spitter_tankspawn_min",	"12", "Min die number for a spitter to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_spitter_tankspawn_max",	"13", "Max die number for a spitter to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_spitter_witchspawn_min", "15", "Min die number for a spitter to cause a spitter to spawn nearby.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_spitter_witchspawn_max", "18", "Max die number for a spitter to cause a spitter to spawn nearby.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_spitter_common_min", "14", "Min die number for a spitter to cause common infected to spawn nearby.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_spitter_common_max", "20", "Max die number for a spitter to cause common infected to spawn nearby.", 0, true, 0.0);
	
	CVarSpitterLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_spitter_pistol_min", "20", 	"Min die number for a spitter to drop a pistol.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_spitter_pistol_max", "40", 	"Max die number for a spitter to drop a pistol.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_spitter_smg_min", "22", "Min die number for a spitter to drop a small machine gun.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_spitter_smg_max", "35", "Max die number for a spitter to drop a small machine gun.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_spitter_shotgun_min", "23", "Min die number for a spitter to drop a shotgun.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_spitter_shotgun_max", "40", "Max die number for a spitter to drop a shotgun.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_spitter_rifle_min", "24", "Min die number for a spitter to drop an auto rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_spitter_rifle_max", "30", "Max die number for a spitter to drop an auto rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_spitter_autoshot_min", "25", "Min die number for a spitter to drop an auto shotgun.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_spitter_autoshot_max", "28", "Max die number for a spitter to drop an auto shotgun.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_spitter_sniper_min", "26", "Min die number for a spitter to drop a sniper rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_spitter_sniper_max", "29", "Max die number for a spitter to drop a sniper rifle.", 0, true, 0.0);	

	CVarSpitterLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_spitter_military_min", "27", "Min die number for a spitter to drop a military rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_spitter_military_max", "30", "Max die number for a spitter to drop a military rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_spitter_ak47_min", "28", "Min die number for a spitter to drop a ak47 rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_spitter_ak47_max", "32", "Max die number for a spitter to drop a ak47 rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_spitter_defibrillator_min", "31", "Min die number for a spitter to drop a defibrillator.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_spitter_defibrillator_max", "36", "Max die number for a spitter to drop a defibrillator.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_spitter_magnum_min", "34", "Min die number for a spitter to drop a magnum.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_spitter_magnum_max", "38", "Max die number for a spitter to drop a magnum.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_spitter_spas_min", "36", "Min die number for a spitter to drop a spas shotgun.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_spitter_spas_max", "39", "Max die number for a spitter to drop a spas shotgun.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_spitter_melee_min", "39", "Min die number for a spitter to drop a melee.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_spitter_melee_max", "45", "Max die number for a spitter to drop a melee.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_spitter_desert_min", "43", "Min die number for a spitter to drop a desert rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_spitter_desert_max", "50", "Max die number for a spitter to drop a desert rifle.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_spitter_chainsaw_min", "0", "Min die number for a spitter to drop a chainsaw.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_spitter_chainsaw_max", "0", "Max die number for a spitter to drop a chainsaw.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_spitter_explosive_min", "44", "Min die number for a spitter to drop a explosive ammo.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_spitter_explosive_max", "46", "Max die number for a spitter to drop a explosive ammo.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_spitter_incendiary_min", "44", "Min die number for a spitter to drop a incendiary ammo.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_spitter_incendiary_max", "47", "Max die number for a spitter to drop a incendiary ammo.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_spitter_adrenaline_min", "45", "Min die number for a spitter to drop a adrenaline.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_spitter_adrenaline_max", "50", "Max die number for a spitter to drop a adrenaline.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_spitter_vomitjar_min", "46", "Min die number for a spitter to drop a vomitjar.", 0, true, 0.0);
	CVarSpitterLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_spitter_vomitjar_max", "50", "Max die number for a spitter to drop a vomitjar.", 0, true, 0.0);

	CVarChargerLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_charger_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", 0, true, 1.0, true, 4.0);
	CVarChargerLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_charger_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", 0, true, 1.0, true, 3.0);
	CVarChargerLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_charger_item_count", "3", "How many items are rolled for when the witch dies.", 0, true, 0.0);	
	
	CVarChargerLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_charger_kit_min", "1", "Min die number for a charger to drop a kit.", 0, true, 0.0);
	CVarChargerLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_charger_kit_max", "3", "Max die number for a charger to drop a kit.", 0, true, 0.0);
	CVarChargerLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_charger_pills_min",	"3", "Min die number for a charger to drop pills.", 0, true, 0.0);
	CVarChargerLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_charger_pills_max",	"7", "Max die number for a charger to drop pills.", 0, true, 0.0);
	CVarChargerLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_charger_molly_min",	"5", "Min die number for a charger to drop a molitov.", 0, true, 0.0);
	CVarChargerLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_charger_molly_max",	"13", "Max die number for a charger to drop a molitov.", 0, true, 0.0);
	CVarChargerLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_charger_pipe_min", "8", "Min die number for a charger to drop a pipe bomb.", 0, true, 0.0);
	CVarChargerLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_charger_pipe_max", "13", "Max die number for a charger to drop a pipe bomb.", 0, true, 0.0);
	
	CVarChargerLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_charger_panic_min",	"8", "Min die number for a charger to cause a zombie panic event.", 0, true, 0.0);
	CVarChargerLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_charger_panic_max",	"11", "Max die number for a charger to cause a zombie panic event.", 0, true, 0.0);
	CVarChargerLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_charger_tankspawn_min",	"12", "Min die number for a charger to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarChargerLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_charger_tankspawn_max",	"13", "Max die number for a charger to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarChargerLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_charger_witchspawn_min", "13", "Min die number for a charger to cause a charger to spawn nearby.", 0, true, 0.0);
	CVarChargerLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_charger_witchspawn_max", "16", "Max die number for a charger to cause a charger to spawn nearby.", 0, true, 0.0);
	CVarChargerLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_charger_common_min", "15", "Min die number for a charger to cause common infected to spawn nearby.", 0, true, 0.0);
	CVarChargerLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_charger_common_max", "22", "Max die number for a charger to cause common infected to spawn nearby.", 0, true, 0.0);
	
	CVarChargerLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_charger_pistol_min", "20", 	"Min die number for a charger to drop a pistol.", 0, true, 0.0);
	CVarChargerLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_charger_pistol_max", "40", 	"Max die number for a charger to drop a pistol.", 0, true, 0.0);
	CVarChargerLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_charger_smg_min", "22", "Min die number for a charger to drop a small machine gun.", 0, true, 0.0);
	CVarChargerLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_charger_smg_max", "35", "Max die number for a charger to drop a small machine gun.", 0, true, 0.0);
	CVarChargerLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_charger_shotgun_min", "23", "Min die number for a charger to drop a shotgun.", 0, true, 0.0);
	CVarChargerLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_charger_shotgun_max", "40", "Max die number for a charger to drop a shotgun.", 0, true, 0.0);
	CVarChargerLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_charger_rifle_min",	"24", "Min die number for a charger to drop an auto rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_charger_rifle_max",	"26", "Max die number for a charger to drop an auto rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_charger_autoshot_min", "25", "Min die number for a charger to drop an auto shotgun.", 0, true, 0.0);
	CVarChargerLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_charger_autoshot_max", "28", "Max die number for a charger to drop an auto shotgun.", 0, true, 0.0);
	CVarChargerLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_charger_sniper_min", "26", "Min die number for a charger to drop a sniper rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_charger_sniper_max", "30", "Max die number for a charger to drop a sniper rifle.", 0, true, 0.0);	

	CVarChargerLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_charger_military_min", "28", "Min die number for a charger to drop a military rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_charger_military_max", "31", "Max die number for a charger to drop a military rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_charger_ak47_min", "28", "Min die number for a charger to drop a ak47 rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_charger_ak47_max", "32", "Max die number for a charger to drop a ak47 rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_charger_defibrillator_min", "33", "Min die number for a charger to drop a defibrillator.", 0, true, 0.0);
	CVarChargerLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_charger_defibrillator_max", "35", "Max die number for a charger to drop a defibrillator.", 0, true, 0.0);
	CVarChargerLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_charger_magnum_min", "33", "Min die number for a charger to drop a magnum.", 0, true, 0.0);
	CVarChargerLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_charger_magnum_max", "38", "Max die number for a charger to drop a magnum.", 0, true, 0.0);
	CVarChargerLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_charger_spas_min", "34", "Min die number for a charger to drop a spas shotgun.", 0, true, 0.0);
	CVarChargerLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_charger_spas_max", "40", "Max die number for a charger to drop a spas shotgun.", 0, true, 0.0);
	CVarChargerLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_charger_melee_min", "38", "Min die number for a charger to drop a melee.", 0, true, 0.0);
	CVarChargerLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_charger_melee_max", "43", "Max die number for a charger to drop a melee.", 0, true, 0.0);
	CVarChargerLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_charger_desert_min", "43", "Min die number for a charger to drop a desert rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_charger_desert_max", "47", "Max die number for a charger to drop a desert rifle.", 0, true, 0.0);
	CVarChargerLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_charger_chainsaw_min", "0", "Min die number for a charger to drop a chainsaw.", 0, true, 0.0);
	CVarChargerLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_charger_chainsaw_max", "0", "Max die number for a charger to drop a chainsaw.", 0, true, 0.0);
	CVarChargerLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_charger_explosive_min", "46", "Min die number for a charger to drop a explosive ammo.", 0, true, 0.0);
	CVarChargerLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_charger_explosive_max", "49", "Max die number for a charger to drop a explosive ammo.", 0, true, 0.0);
	CVarChargerLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_charger_incendiary_min", "44", "Min die number for a charger to drop a incendiary ammo.", 0, true, 0.0);
	CVarChargerLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_charger_incendiary_max", "48", "Max die number for a charger to drop a incendiary ammo.", 0, true, 0.0);
	CVarChargerLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_charger_adrenaline_min", "45", "Min die number for a charger to drop a adrenaline.", 0, true, 0.0);
	CVarChargerLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_charger_adrenaline_max", "47", "Max die number for a charger to drop a adrenaline.", 0, true, 0.0);
	CVarChargerLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_charger_vomitjar_min", "46", "Min die number for a charger to drop a vomitjar.", 0, true, 0.0);
	CVarChargerLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_charger_vomitjar_max", "50", "Max die number for a charger to drop a vomitjar.", 0, true, 0.0);

	CVarJockeyLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_jockey_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", 0, true, 1.0, true, 4.0);
	CVarJockeyLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_jockey_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", 0, true, 1.0, true, 3.0);
	CVarJockeyLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_jockey_item_count", "3", "How many items are rolled for when the witch dies.", 0, true, 0.0);	
	
	CVarJockeyLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_jockey_kit_min", "1", "Min die number for a jockey to drop a kit.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_jockey_kit_max", "3", "Max die number for a jockey to drop a kit.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_jockey_pills_min",	"2", "Min die number for a jockey to drop pills.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_jockey_pills_max",	"6", "Max die number for a jockey to drop pills.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_jockey_molly_min",	"5", "Min die number for a jockey to drop a molitov.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_jockey_molly_max",	"8", "Max die number for a jockey to drop a molitov.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_jockey_pipe_min", "7", "Min die number for a jockey to drop a pipe bomb.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_jockey_pipe_max", "10", "Max die number for a jockey to drop a pipe bomb.", 0, true, 0.0);
	
	CVarJockeyLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_jockey_panic_min",	"11", "Min die number for a jockey to cause a zombie panic event.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_jockey_panic_max",	"14", "Max die number for a jockey to cause a zombie panic event.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_jockey_tankspawn_min",	"12", "Min die number for a jockey to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_jockey_tankspawn_max",	"13", "Max die number for a jockey to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_jockey_witchspawn_min", "11", "Min die number for a jockey to cause a jockey to spawn nearby.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_jockey_witchspawn_max", "16", "Max die number for a jockey to cause a jockey to spawn nearby.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_jockey_common_min", "15", "Min die number for a jockey to cause common infected to spawn nearby.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_jockey_common_max", "25", "Max die number for a jockey to cause common infected to spawn nearby.", 0, true, 0.0);
	
	CVarJockeyLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_jockey_pistol_min", "20", 	"Min die number for a jockey to drop a pistol.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_jockey_pistol_max", "40", 	"Max die number for a jockey to drop a pistol.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_jockey_smg_min", "23", "Min die number for a jockey to drop a small machine gun.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_jockey_smg_max", "35", "Max die number for a jockey to drop a small machine gun.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_jockey_shotgun_min", "23", "Min die number for a jockey to drop a shotgun.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_jockey_shotgun_max", "40", "Max die number for a jockey to drop a shotgun.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_jockey_rifle_min",	"25", "Min die number for a jockey to drop an auto rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_jockey_rifle_max",	"28", "Max die number for a jockey to drop an auto rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_jockey_autoshot_min", "26", "Min die number for a jockey to drop an auto shotgun.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_jockey_autoshot_max", "30", "Max die number for a jockey to drop an auto shotgun.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_jockey_sniper_min", "28", "Min die number for a jockey to drop a sniper rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_jockey_sniper_max", "32", "Max die number for a jockey to drop a sniper rifle.", 0, true, 0.0);	

	CVarJockeyLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_jockey_military_min", "31", "Min die number for a jockey to drop a military rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_jockey_military_max", "34", "Max die number for a jockey to drop a military rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_jockey_ak47_min", "31", "Min die number for a jockey to drop a ak47 rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_jockey_ak47_max", "35", "Max die number for a jockey to drop a ak47 rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_jockey_defibrillator_min", "34", "Min die number for a jockey to drop a defibrillator.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_jockey_defibrillator_max", "36", "Max die number for a jockey to drop a defibrillator.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_jockey_magnum_min", "34", "Min die number for a jockey to drop a magnum.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_jockey_magnum_max", "37", "Max die number for a jockey to drop a magnum.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_jockey_spas_min", "36", "Min die number for a jockey to drop a spas shotgun.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_jockey_spas_max", "43", "Max die number for a jockey to drop a spas shotgun.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_jockey_melee_min", "35", "Min die number for a jockey to drop a melee.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_jockey_melee_max", "46", "Max die number for a jockey to drop a melee.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_jockey_desert_min", "42", "Min die number for a jockey to drop a desert rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_jockey_desert_max", "47", "Max die number for a jockey to drop a desert rifle.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_jockey_chainsaw_min", "0", "Min die number for a jockey to drop a chainsaw.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_jockey_chainsaw_max", "0", "Max die number for a jockey to drop a chainsaw.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_jockey_explosive_min", "45", "Min die number for a jockey to drop a explosive ammo.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_jockey_explosive_max", "48", "Max die number for a jockey to drop a explosive ammo.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_jockey_incendiary_min", "46", "Min die number for a jockey to drop a incendiary ammo.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_jockey_incendiary_max", "49", "Max die number for a jockey to drop a incendiary ammo.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_jockey_adrenaline_min", "48", "Min die number for a jockey to drop a adrenaline.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_jockey_adrenaline_max", "50", "Max die number for a jockey to drop a adrenaline.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_jockey_vomitjar_min", "46", "Min die number for a jockey to drop a vomitjar.", 0, true, 0.0);
	CVarJockeyLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_jockey_vomitjar_max", "50", "Max die number for a jockey to drop a vomitjar.", 0, true, 0.0);

	CVarTankLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_tank_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", 0, true, 1.0, true, 4.0);
	CVarTankLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_tank_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", 0, true, 1.0, true, 3.0);
	CVarTankLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_tank_item_count", "5", "How many items are rolled for when the witch dies.", 0, true, 0.0);	
	
	CVarTankLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_tank_kit_min", "1", "Min die number for a tank to drop a kit.", 0, true, 0.0);
	CVarTankLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_tank_kit_max", "4", "Max die number for a tank to drop a kit.", 0, true, 0.0);
	CVarTankLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_tank_pills_min",	"5", "Min die number for a tank to drop pills.", 0, true, 0.0);
	CVarTankLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_tank_pills_max",	"9", "Max die number for a tank to drop pills.", 0, true, 0.0);
	CVarTankLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_tank_molly_min",	"5", "Min die number for a tank to drop a molitov.", 0, true, 0.0);
	CVarTankLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_tank_molly_max",	"8", "Max die number for a tank to drop a molitov.", 0, true, 0.0);
	CVarTankLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_tank_pipe_min", "8", "Min die number for a tank to drop a pipe bomb.", 0, true, 0.0);
	CVarTankLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_tank_pipe_max", "11", "Max die number for a tank to drop a pipe bomb.", 0, true, 0.0);
	
	CVarTankLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_tank_panic_min",	"12", "Min die number for a tank to cause a zombie panic event.", 0, true, 0.0);
	CVarTankLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_tank_panic_max",	"15", "Max die number for a tank to cause a zombie panic event.", 0, true, 0.0);
	CVarTankLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_tank_tankspawn_min",	"0", "Min die number for a tank to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarTankLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_tank_tankspawn_max",	"0", "Max die number for a tank to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarTankLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_tank_witchspawn_min", "15", "Min die number for a tank to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarTankLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_tank_witchspawn_max", "19", "Max die number for a tank to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarTankLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_tank_common_min", "15", "Min die number for a tank to cause common infected to spawn nearby.", 0, true, 0.0);
	CVarTankLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_tank_common_max", "22", "Max die number for a tank to cause common infected to spawn nearby.", 0, true, 0.0);
	
	CVarTankLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_tank_pistol_min", "21", 	"Min die number for a tank to drop a pistol.", 0, true, 0.0);
	CVarTankLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_tank_pistol_max", "40", 	"Max die number for a tank to drop a pistol.", 0, true, 0.0);
	CVarTankLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_tank_smg_min", "20", "Min die number for a tank to drop a small machine gun.", 0, true, 0.0);
	CVarTankLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_tank_smg_max", "35", "Max die number for a tank to drop a small machine gun.", 0, true, 0.0);
	CVarTankLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_tank_shotgun_min", "26", "Min die number for a tank to drop a shotgun.", 0, true, 0.0);
	CVarTankLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_tank_shotgun_max", "40", "Max die number for a tank to drop a shotgun.", 0, true, 0.0);
	CVarTankLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_tank_rifle_min",	"25", "Min die number for a tank to drop an auto rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_tank_rifle_max",	"28", "Max die number for a tank to drop an auto rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_tank_autoshot_min", "23", "Min die number for a tank to drop an auto shotgun.", 0, true, 0.0);
	CVarTankLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_tank_autoshot_max", "29", "Max die number for a tank to drop an auto shotgun.", 0, true, 0.0);
	CVarTankLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_tank_sniper_min", "25", "Min die number for a tank to drop a sniper rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_tank_sniper_max", "30", "Max die number for a tank to drop a sniper rifle.", 0, true, 0.0);	

	CVarTankLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_tank_military_min", "28", "Min die number for a tank to drop a military rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_tank_military_max", "33", "Max die number for a tank to drop a military rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_tank_ak47_min", "30", "Min die number for a tank to drop a ak47 rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_tank_ak47_max", "35", "Max die number for a tank to drop a ak47 rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_tank_defibrillator_min", "25", "Min die number for a tank to drop a defibrillator.", 0, true, 0.0);
	CVarTankLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_tank_defibrillator_max", "40", "Max die number for a tank to drop a defibrillator.", 0, true, 0.0);
	CVarTankLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_tank_magnum_min", "33", "Min die number for a tank to drop a magnum.", 0, true, 0.0);
	CVarTankLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_tank_magnum_max", "37", "Max die number for a tank to drop a magnum.", 0, true, 0.0);
	CVarTankLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_tank_spas_min", "36", "Min die number for a tank to drop a spas shotgun.", 0, true, 0.0);
	CVarTankLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_tank_spas_max", "41", "Max die number for a tank to drop a spas shotgun.", 0, true, 0.0);
	CVarTankLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_tank_melee_min", "40", "Min die number for a tank to drop a melee.", 0, true, 0.0);
	CVarTankLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_tank_melee_max", "48", "Max die number for a tank to drop a melee.", 0, true, 0.0);
	CVarTankLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_tank_desert_min", "42", "Min die number for a tank to drop a desert rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_tank_desert_max", "47", "Max die number for a tank to drop a desert rifle.", 0, true, 0.0);
	CVarTankLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_tank_chainsaw_min", "30", "Min die number for a tank to drop a chainsaw.", 0, true, 0.0);
	CVarTankLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_tank_chainsaw_max", "46", "Max die number for a tank to drop a chainsaw.", 0, true, 0.0);
	CVarTankLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_tank_explosive_min", "43", "Min die number for a tank to drop a explosive ammo.", 0, true, 0.0);
	CVarTankLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_tank_explosive_max", "47", "Max die number for a tank to drop a explosive ammo.", 0, true, 0.0);
	CVarTankLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_tank_incendiary_min", "44", "Min die number for a tank to drop a incendiary ammo.", 0, true, 0.0);
	CVarTankLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_tank_incendiary_max", "48", "Max die number for a tank to drop a incendiary ammo.", 0, true, 0.0);
	CVarTankLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_tank_adrenaline_min", "46", "Min die number for a tank to drop a adrenaline.", 0, true, 0.0);
	CVarTankLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_tank_adrenaline_max", "50", "Max die number for a tank to drop a adrenaline.", 0, true, 0.0);
	CVarTankLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_tank_vomitjar_min", "48", "Min die number for a tank to drop a vomitjar.", 0, true, 0.0);
	CVarTankLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_tank_vomitjar_max", "50", "Max die number for a tank to drop a vomitjar.", 0, true, 0.0);

	CVarWitchLoot[LOOT_DIENUMBER] = CreateConVar("l4d_loot_witch_dienumber", "1", "Which die (1, 2, 4, or 4) is used when rolling for the witch", 0, true, 1.0, true, 4.0);
	CVarWitchLoot[LOOT_DIECOUNT] = CreateConVar("l4d_loot_witch_diecount", "1", "How many dice can roll. Each die is added to a total. (If a die rolls 0 it is not thrown)", 0, true, 1.0, true, 3.0);
	CVarWitchLoot[LOOT_ITEM_COUNT] = CreateConVar("l4d_loot_witch_item_count", "4", "How many items are rolled for when the witch dies.", 0, true, 0.0);	
	
	CVarWitchLoot[LOOT_KIT_MIN] = CreateConVar("l4d_loot_witch_kit_min", "1", "Min die number for a witch to drop a kit.", 0, true, 0.0);
	CVarWitchLoot[LOOT_KIT_MAX] = CreateConVar("l4d_loot_witch_kit_max", "3", "Max die number for a witch to drop a kit.", 0, true, 0.0);
	CVarWitchLoot[LOOT_PILLS_MIN] = CreateConVar("l4d_loot_witch_pills_min",	"2", "Min die number for a witch to drop pills.", 0, true, 0.0);
	CVarWitchLoot[LOOT_PILLS_MAX] = CreateConVar("l4d_loot_witch_pills_max",	"6", "Max die number for a witch to drop pills.", 0, true, 0.0);
	CVarWitchLoot[LOOT_MOLLY_MIN] = CreateConVar("l4d_loot_witch_molly_min",	"4", "Min die number for a witch to drop a molitov.", 0, true, 0.0);
	CVarWitchLoot[LOOT_MOLLY_MAX] = CreateConVar("l4d_loot_witch_molly_max",	"6", "Max die number for a witch to drop a molitov.", 0, true, 0.0);
	CVarWitchLoot[LOOT_PIPE_MIN] = CreateConVar("l4d_loot_witch_pipe_min", "6", "Min die number for a witch to drop a pipe bomb.", 0, true, 0.0);
	CVarWitchLoot[LOOT_PIPE_MAX] = CreateConVar("l4d_loot_witch_pipe_max", "11", "Max die number for a witch to drop a pipe bomb.", 0, true, 0.0);
	
	CVarWitchLoot[LOOT_PANIC_MIN] = CreateConVar("l4d_loot_witch_panic_min",	"12", "Min die number for a witch to cause a zombie panic event.", 0, true, 0.0);
	CVarWitchLoot[LOOT_PANIC_MAX] = CreateConVar("l4d_loot_witch_panic_max",	"15", "Max die number for a witch to cause a zombie panic event.", 0, true, 0.0);
	CVarWitchLoot[LOOT_TANK_MIN] = CreateConVar("l4d_loot_witch_tankspawn_min",	"15", "Min die number for a witch to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarWitchLoot[LOOT_TANK_MAX] = CreateConVar("l4d_loot_witch_tankspawn_max",	"16", "Max die number for a witch to cause a tank to spawn nearby.", 0, true, 0.0);
	CVarWitchLoot[LOOT_WITCH_MIN] = CreateConVar("l4d_loot_witch_witchspawn_min", "17", "Min die number for a witch to cause a witch to spawn nearby.", 0, true, 0.0);
	CVarWitchLoot[LOOT_WITCH_MAX] = CreateConVar("l4d_loot_witch_witchspawn_max", "22", "Max die number for a witch to cause a witch to spawn nearby.", 0, true, 0.0);
	CVarWitchLoot[LOOT_COMMON_MIN] = CreateConVar("l4d_loot_witch_common_min", "18", "Min die number for a witch to cause common infected to spawn nearby.", 0, true, 0.0);
	CVarWitchLoot[LOOT_COMMON_MAX] = CreateConVar("l4d_loot_witch_common_max", "25", "Max die number for a witch to cause common infected to spawn nearby.", 0, true, 0.0);
	
	CVarWitchLoot[LOOT_PISTOL_MIN] = CreateConVar("l4d_loot_witch_pistol_min", "21", 	"Min die number for a witch to drop a pistol.", 0, true, 0.0);
	CVarWitchLoot[LOOT_PISTOL_MAX] = CreateConVar("l4d_loot_witch_pistol_max", "40", 	"Max die number for a witch to drop a pistol.", 0, true, 0.0);
	CVarWitchLoot[LOOT_SMG_MIN] = CreateConVar("l4d_loot_witch_smg_min", "22", "Min die number for a witch to drop a small machine gun.", 0, true, 0.0);
	CVarWitchLoot[LOOT_SMG_MAX] = CreateConVar("l4d_loot_witch_smg_max", "35", "Max die number for a witch to drop a small machine gun.", 0, true, 0.0);
	CVarWitchLoot[LOOT_SHOT_MIN] = CreateConVar("l4d_loot_witch_shotgun_min", "22", "Min die number for a witch to drop a shotgun.", 0, true, 0.0);
	CVarWitchLoot[LOOT_SHOT_MAX] = CreateConVar("l4d_loot_witch_shotgun_max", "35", "Max die number for a witch to drop a shotgun.", 0, true, 0.0);
	CVarWitchLoot[LOOT_RIFLE_MIN] = CreateConVar("l4d_loot_witch_rifle_min",	"24", "Min die number for a witch to drop an auto rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_RIFLE_MAX] = CreateConVar("l4d_loot_witch_rifle_max",	"29", "Max die number for a witch to drop an auto rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_AUTOSHOT_MIN] = CreateConVar("l4d_loot_witch_autoshot_min", "22", "Min die number for a witch to drop an auto shotgun.", 0, true, 0.0);
	CVarWitchLoot[LOOT_AUTOSHOT_MAX] = CreateConVar("l4d_loot_witch_autoshot_max", "27", "Max die number for a witch to drop an auto shotgun.", 0, true, 0.0);
	CVarWitchLoot[LOOT_SNIPER_MIN] = CreateConVar("l4d_loot_witch_sniper_min", "26", "Min die number for a witch to drop a sniper rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_SNIPER_MAX] = CreateConVar("l4d_loot_witch_sniper_max", "30", "Max die number for a witch to drop a sniper rifle.", 0, true, 0.0);	

	CVarWitchLoot[LOOT_MILITARY_MIN] = CreateConVar("l4d_loot_witch_military_min", "25", "Min die number for a witch to drop a military rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_MILITARY_MAX] = CreateConVar("l4d_loot_witch_military_max", "29", "Max die number for a witch to drop a military rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_AK47_MIN] = CreateConVar("l4d_loot_witch_ak47_min", "25", "Min die number for a witch to drop a ak47 rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_AK47_MAX] = CreateConVar("l4d_loot_witch_ak47_max", "30", "Max die number for a witch to drop a ak47 rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_DEFIBRILLATOR_MIN] = CreateConVar("l4d_loot_witch_defibrillator_min", "30", "Min die number for a witch to drop a defibrillator.", 0, true, 0.0);
	CVarWitchLoot[LOOT_DEFIBRILLATOR_MAX] = CreateConVar("l4d_loot_witch_defibrillator_max", "40", "Max die number for a witch to drop a defibrillator.", 0, true, 0.0);
	CVarWitchLoot[LOOT_MAGNUM_MIN] = CreateConVar("l4d_loot_witch_magnum_min", "34", "Min die number for a witch to drop a magnum.", 0, true, 0.0);
	CVarWitchLoot[LOOT_MAGNUM_MAX] = CreateConVar("l4d_loot_witch_magnum_max", "39", "Max die number for a witch to drop a magnum.", 0, true, 0.0);
	CVarWitchLoot[LOOT_SPAS_MIN] = CreateConVar("l4d_loot_witch_spas_min", "36", "Min die number for a witch to drop a spas shotgun.", 0, true, 0.0);
	CVarWitchLoot[LOOT_SPAS_MAX] = CreateConVar("l4d_loot_witch_spas_max", "40", "Max die number for a witch to drop a spas shotgun.", 0, true, 0.0);
	CVarWitchLoot[LOOT_MELEE_MIN] = CreateConVar("l4d_loot_witch_melee_min", "30", "Min die number for a witch to drop a melee.", 0, true, 0.0);
	CVarWitchLoot[LOOT_MELEE_MAX] = CreateConVar("l4d_loot_witch_melee_max", "43", "Max die number for a witch to drop a melee.", 0, true, 0.0);
	CVarWitchLoot[LOOT_DESERT_MIN] = CreateConVar("l4d_loot_witch_desert_min", "44", "Min die number for a witch to drop a desert rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_DESERT_MAX] = CreateConVar("l4d_loot_witch_desert_max", "46", "Max die number for a witch to drop a desert rifle.", 0, true, 0.0);
	CVarWitchLoot[LOOT_CHAINSAW_MIN] = CreateConVar("l4d_loot_witch_chainsaw_min", "13", "Min die number for a witch to drop a chainsaw.", 0, true, 0.0);
	CVarWitchLoot[LOOT_CHAINSAW_MAX] = CreateConVar("l4d_loot_witch_chainsaw_max", "16", "Max die number for a witch to drop a chainsaw.", 0, true, 0.0);
	CVarWitchLoot[LOOT_EXPLOSIVE_MIN] = CreateConVar("l4d_loot_witch_explosive_min", "47", "Min die number for a witch to drop a explosive ammo.", 0, true, 0.0);
	CVarWitchLoot[LOOT_EXPLOSIVE_MAX] = CreateConVar("l4d_loot_witch_explosive_max", "49", "Max die number for a witch to drop a explosive ammo.", 0, true, 0.0);
	CVarWitchLoot[LOOT_INCENDIARY_MIN] = CreateConVar("l4d_loot_witch_incendiary_min", "45", "Min die number for a witch to drop a incendiary ammo.", 0, true, 0.0);
	CVarWitchLoot[LOOT_INCENDIARY_MAX] = CreateConVar("l4d_loot_witch_incendiary_max", "48", "Max die number for a witch to drop a incendiary ammo.", 0, true, 0.0);
	CVarWitchLoot[LOOT_ADRENALINE_MIN] = CreateConVar("l4d_loot_witch_adrenaline_min", "46", "Min die number for a witch to drop a adrenaline.", 0, true, 0.0);
	CVarWitchLoot[LOOT_ADRENALINE_MAX] = CreateConVar("l4d_loot_witch_adrenaline_max", "50", "Max die number for a witch to drop a adrenaline.", 0, true, 0.0);
	CVarWitchLoot[LOOT_VOMITJAR_MIN] = CreateConVar("l4d_loot_witch_vomitjar_min", "48", "Min die number for a witch to drop a vomitjar.", 0, true, 0.0);
	CVarWitchLoot[LOOT_VOMITJAR_MAX] = CreateConVar("l4d_loot_witch_vomitjar_max", "50", "Max die number for a witch to drop a vomitjar.", 0, true, 0.0);

	RegConsoleCmd("sm_loot_sim_infected", Command_SimInfected);
	RegConsoleCmd("sm_loot_print_settings", Command_PrintSettings);
	RegConsoleCmd("sm_loot_load", Command_LoadSettings);
	
	PrintToServer("[DICE] Loading config.");
	AutoExecConfig(true, "l4d_loot_drop");
	
	// Change the enabled flag to the one the convar holds.
	if (GetConVarInt(CVarIsEnabled) == 1) 
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

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	numTank = 0;
	numWitch = 0;
	tankSpawn = 0;
	witchSpawn = 0;
	numTankMax = 0;
	numWitchMax = 0;
	numPanic = 0;
	TellAll("Tank Allowances Reset.");
}
// At round end, reset tank/witch count.

public Action Command_LoadSettings(int client, int args)
{
	PrintToServer("[DICE] Refreshing settings.");
	AutoExecConfig(false, "l4d_loot_drop");
	PullCVarValues();
}

public Action Command_PrintSettings(int client, int args)
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

void PrintSettings(diceSettings[55])
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

public Action Command_SimInfected(int client, int args)
{
	char arg[128]
	/*
	if (!IsClientConnected(client) && !IsClientInGame(client))
		return Plugin_Handled;

	if (IsClientBot(client))
		return Plugin_Handled;
	*/
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

public void Loot_EnableDisable(Handle hVariable, const char[] strOldValue, const char[] strNewValue)
{
    // Change the enabled flag to the one the convar holds.
    if (GetConVarInt(CVarIsEnabled) == 1)
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
	Dice[0] = GetConVarInt(CVarDieSides[0]);
	Dice[1] = GetConVarInt(CVarDieSides[1]);
	Dice[2] = GetConVarInt(CVarDieSides[2]);
	Dice[3] = GetConVarInt(CVarDieSides[3]);
	
	HunterLoot[LOOT_DIENUMBER] = GetConVarInt(CVarHunterLoot[LOOT_DIENUMBER])
	HunterLoot[LOOT_DIECOUNT] = GetConVarInt(CVarHunterLoot[LOOT_DIECOUNT])
	HunterLoot[LOOT_KIT_MIN] = GetConVarInt(CVarHunterLoot[LOOT_KIT_MIN])
	HunterLoot[LOOT_KIT_MAX] = GetConVarInt(CVarHunterLoot[LOOT_KIT_MAX])
	HunterLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarHunterLoot[LOOT_PILLS_MIN])
	HunterLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarHunterLoot[LOOT_PILLS_MAX])
	HunterLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarHunterLoot[LOOT_MOLLY_MIN])
	HunterLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarHunterLoot[LOOT_MOLLY_MAX])
	HunterLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarHunterLoot[LOOT_PIPE_MIN])
	HunterLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarHunterLoot[LOOT_PIPE_MAX])
	HunterLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarHunterLoot[LOOT_ITEM_COUNT])

	HunterLoot[LOOT_PANIC_MIN] = GetConVarInt(CVarHunterLoot[LOOT_PANIC_MIN])
	HunterLoot[LOOT_PANIC_MAX] = GetConVarInt(CVarHunterLoot[LOOT_PANIC_MAX])
	HunterLoot[LOOT_TANK_MIN] = GetConVarInt(CVarHunterLoot[LOOT_TANK_MIN])
	HunterLoot[LOOT_TANK_MAX] = GetConVarInt(CVarHunterLoot[LOOT_TANK_MAX])
	HunterLoot[LOOT_WITCH_MIN] = GetConVarInt(CVarHunterLoot[LOOT_WITCH_MIN])
	HunterLoot[LOOT_WITCH_MAX] = GetConVarInt(CVarHunterLoot[LOOT_WITCH_MAX])
	HunterLoot[LOOT_COMMON_MIN] = GetConVarInt(CVarHunterLoot[LOOT_COMMON_MIN])
	HunterLoot[LOOT_COMMON_MAX] = GetConVarInt(CVarHunterLoot[LOOT_COMMON_MAX])
	
	HunterLoot[LOOT_PISTOL_MIN] = GetConVarInt(CVarHunterLoot[LOOT_PISTOL_MIN])
	HunterLoot[LOOT_PISTOL_MAX] = GetConVarInt(CVarHunterLoot[LOOT_PISTOL_MAX])
	HunterLoot[LOOT_SMG_MIN] = GetConVarInt(CVarHunterLoot[LOOT_SMG_MIN])
	HunterLoot[LOOT_SMG_MAX] = GetConVarInt(CVarHunterLoot[LOOT_SMG_MAX])
	HunterLoot[LOOT_SHOT_MIN] = GetConVarInt(CVarHunterLoot[LOOT_SHOT_MIN])
	HunterLoot[LOOT_SHOT_MAX] = GetConVarInt(CVarHunterLoot[LOOT_SHOT_MAX])
	HunterLoot[LOOT_RIFLE_MIN] = GetConVarInt(CVarHunterLoot[LOOT_RIFLE_MIN])
	HunterLoot[LOOT_RIFLE_MAX] = GetConVarInt(CVarHunterLoot[LOOT_RIFLE_MAX])
	HunterLoot[LOOT_AUTOSHOT_MIN] = GetConVarInt(CVarHunterLoot[LOOT_AUTOSHOT_MIN])
	HunterLoot[LOOT_AUTOSHOT_MAX] = GetConVarInt(CVarHunterLoot[LOOT_AUTOSHOT_MAX])
	HunterLoot[LOOT_SNIPER_MIN] = GetConVarInt(CVarHunterLoot[LOOT_SNIPER_MIN])
	HunterLoot[LOOT_SNIPER_MAX] = GetConVarInt(CVarHunterLoot[LOOT_SNIPER_MAX])
	HunterLoot[LOOT_AK47_MIN] = GetConVarInt(CVarHunterLoot[LOOT_AK47_MIN])
	HunterLoot[LOOT_AK47_MAX] = GetConVarInt(CVarHunterLoot[LOOT_AK47_MAX])
	HunterLoot[LOOT_DEFIBRILLATOR_MIN] = GetConVarInt(CVarHunterLoot[LOOT_DEFIBRILLATOR_MIN])
	HunterLoot[LOOT_DEFIBRILLATOR_MAX] = GetConVarInt(CVarHunterLoot[LOOT_DEFIBRILLATOR_MAX])
	HunterLoot[LOOT_MILITARY_MIN] = GetConVarInt(CVarHunterLoot[LOOT_MILITARY_MIN])
	HunterLoot[LOOT_MILITARY_MAX] = GetConVarInt(CVarHunterLoot[LOOT_MILITARY_MAX])
	HunterLoot[LOOT_MAGNUM_MIN] = GetConVarInt(CVarHunterLoot[LOOT_MAGNUM_MIN])
	HunterLoot[LOOT_MAGNUM_MAX] = GetConVarInt(CVarHunterLoot[LOOT_MAGNUM_MAX])
	HunterLoot[LOOT_SPAS_MIN] = GetConVarInt(CVarHunterLoot[LOOT_SPAS_MIN])
	HunterLoot[LOOT_SPAS_MAX] = GetConVarInt(CVarHunterLoot[LOOT_SPAS_MAX])
	HunterLoot[LOOT_MELEE_MIN] = GetConVarInt(CVarHunterLoot[LOOT_MELEE_MIN])
	HunterLoot[LOOT_MELEE_MAX] = GetConVarInt(CVarHunterLoot[LOOT_MELEE_MAX])
	HunterLoot[LOOT_DESERT_MIN] = GetConVarInt(CVarHunterLoot[LOOT_DESERT_MIN])
	HunterLoot[LOOT_DESERT_MAX] = GetConVarInt(CVarHunterLoot[LOOT_DESERT_MAX])
	HunterLoot[LOOT_CHAINSAW_MIN] = GetConVarInt(CVarHunterLoot[LOOT_CHAINSAW_MIN])
	HunterLoot[LOOT_CHAINSAW_MAX] = GetConVarInt(CVarHunterLoot[LOOT_CHAINSAW_MAX])
	HunterLoot[LOOT_EXPLOSIVE_MIN] = GetConVarInt(CVarHunterLoot[LOOT_EXPLOSIVE_MIN])
	HunterLoot[LOOT_EXPLOSIVE_MAX] = GetConVarInt(CVarHunterLoot[LOOT_EXPLOSIVE_MAX])
	HunterLoot[LOOT_INCENDIARY_MIN] = GetConVarInt(CVarHunterLoot[LOOT_INCENDIARY_MIN])
	HunterLoot[LOOT_INCENDIARY_MAX] = GetConVarInt(CVarHunterLoot[LOOT_INCENDIARY_MAX])
	HunterLoot[LOOT_ADRENALINE_MIN] = GetConVarInt(CVarHunterLoot[LOOT_ADRENALINE_MIN])
	HunterLoot[LOOT_ADRENALINE_MAX] = GetConVarInt(CVarHunterLoot[LOOT_ADRENALINE_MAX])
	HunterLoot[LOOT_VOMITJAR_MIN] = GetConVarInt(CVarHunterLoot[LOOT_VOMITJAR_MIN])
	HunterLoot[LOOT_VOMITJAR_MAX] = GetConVarInt(CVarHunterLoot[LOOT_VOMITJAR_MAX])

	BoomerLoot[LOOT_DIENUMBER] = GetConVarInt(CVarBoomerLoot[LOOT_DIENUMBER])
	BoomerLoot[LOOT_DIECOUNT] = GetConVarInt(CVarBoomerLoot[LOOT_DIECOUNT])
	BoomerLoot[LOOT_KIT_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_KIT_MIN])
	BoomerLoot[LOOT_KIT_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_KIT_MAX])
	BoomerLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_PILLS_MIN])
	BoomerLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_PILLS_MAX])
	BoomerLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_MOLLY_MIN])
	BoomerLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_MOLLY_MAX])
	BoomerLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_PIPE_MIN])
	BoomerLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_PIPE_MAX])
	BoomerLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarBoomerLoot[LOOT_ITEM_COUNT])

	BoomerLoot[LOOT_PANIC_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_PANIC_MIN])
	BoomerLoot[LOOT_PANIC_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_PANIC_MAX])
	BoomerLoot[LOOT_TANK_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_TANK_MIN])
	BoomerLoot[LOOT_TANK_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_TANK_MAX])
	BoomerLoot[LOOT_WITCH_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_WITCH_MIN])
	BoomerLoot[LOOT_WITCH_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_WITCH_MAX])
	BoomerLoot[LOOT_COMMON_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_COMMON_MIN])
	BoomerLoot[LOOT_COMMON_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_COMMON_MAX])

	BoomerLoot[LOOT_PISTOL_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_PISTOL_MIN])
	BoomerLoot[LOOT_PISTOL_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_PISTOL_MAX])
	BoomerLoot[LOOT_SMG_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_SMG_MIN])
	BoomerLoot[LOOT_SMG_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_SMG_MAX])
	BoomerLoot[LOOT_SHOT_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_SHOT_MIN])
	BoomerLoot[LOOT_SHOT_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_SHOT_MAX])
	BoomerLoot[LOOT_RIFLE_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_RIFLE_MIN])
	BoomerLoot[LOOT_RIFLE_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_RIFLE_MAX])
	BoomerLoot[LOOT_AUTOSHOT_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_AUTOSHOT_MIN])
	BoomerLoot[LOOT_AUTOSHOT_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_AUTOSHOT_MAX])
	BoomerLoot[LOOT_SNIPER_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_SNIPER_MIN])
	BoomerLoot[LOOT_SNIPER_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_SNIPER_MAX])
	BoomerLoot[LOOT_AK47_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_AK47_MIN])
	BoomerLoot[LOOT_AK47_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_AK47_MAX])
	BoomerLoot[LOOT_DEFIBRILLATOR_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_DEFIBRILLATOR_MIN])
	BoomerLoot[LOOT_DEFIBRILLATOR_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_DEFIBRILLATOR_MAX])
	BoomerLoot[LOOT_MILITARY_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_MILITARY_MIN])
	BoomerLoot[LOOT_MILITARY_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_MILITARY_MAX])
	BoomerLoot[LOOT_MAGNUM_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_MAGNUM_MIN])
	BoomerLoot[LOOT_MAGNUM_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_MAGNUM_MAX])
	BoomerLoot[LOOT_SPAS_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_SPAS_MIN])
	BoomerLoot[LOOT_SPAS_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_SPAS_MAX])
	BoomerLoot[LOOT_MELEE_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_MELEE_MIN])
	BoomerLoot[LOOT_MELEE_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_MELEE_MAX])
	BoomerLoot[LOOT_DESERT_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_DESERT_MIN])
	BoomerLoot[LOOT_DESERT_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_DESERT_MAX])
	BoomerLoot[LOOT_CHAINSAW_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_CHAINSAW_MIN])
	BoomerLoot[LOOT_CHAINSAW_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_CHAINSAW_MAX])
	BoomerLoot[LOOT_EXPLOSIVE_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_EXPLOSIVE_MIN])
	BoomerLoot[LOOT_EXPLOSIVE_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_EXPLOSIVE_MAX])
	BoomerLoot[LOOT_INCENDIARY_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_INCENDIARY_MIN])
	BoomerLoot[LOOT_INCENDIARY_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_INCENDIARY_MAX])
	BoomerLoot[LOOT_ADRENALINE_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_ADRENALINE_MIN])
	BoomerLoot[LOOT_ADRENALINE_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_ADRENALINE_MAX])
	BoomerLoot[LOOT_VOMITJAR_MIN] = GetConVarInt(CVarBoomerLoot[LOOT_VOMITJAR_MIN])
	BoomerLoot[LOOT_VOMITJAR_MAX] = GetConVarInt(CVarBoomerLoot[LOOT_VOMITJAR_MAX])

	SmokerLoot[LOOT_DIENUMBER] = GetConVarInt(CVarSmokerLoot[LOOT_DIENUMBER])
	SmokerLoot[LOOT_DIECOUNT] = GetConVarInt(CVarSmokerLoot[LOOT_DIECOUNT])
	SmokerLoot[LOOT_KIT_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_KIT_MIN])
	SmokerLoot[LOOT_KIT_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_KIT_MAX])
	SmokerLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_PILLS_MIN])
	SmokerLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_PILLS_MAX])
	SmokerLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_MOLLY_MIN])
	SmokerLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_MOLLY_MAX])
	SmokerLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_PIPE_MIN])
	SmokerLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_PIPE_MAX])
	SmokerLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarSmokerLoot[LOOT_ITEM_COUNT])

	SmokerLoot[LOOT_PANIC_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_PANIC_MIN])
	SmokerLoot[LOOT_PANIC_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_PANIC_MAX])
	SmokerLoot[LOOT_TANK_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_TANK_MIN])
	SmokerLoot[LOOT_TANK_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_TANK_MAX])
	SmokerLoot[LOOT_WITCH_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_WITCH_MIN])
	SmokerLoot[LOOT_WITCH_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_WITCH_MAX])
	SmokerLoot[LOOT_COMMON_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_COMMON_MIN])
	SmokerLoot[LOOT_COMMON_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_COMMON_MAX])

	SmokerLoot[LOOT_PISTOL_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_PISTOL_MIN])
	SmokerLoot[LOOT_PISTOL_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_PISTOL_MAX])
	SmokerLoot[LOOT_SMG_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_SMG_MIN])
	SmokerLoot[LOOT_SMG_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_SMG_MAX])
	SmokerLoot[LOOT_SHOT_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_SHOT_MIN])
	SmokerLoot[LOOT_SHOT_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_SHOT_MAX])
	SmokerLoot[LOOT_RIFLE_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_RIFLE_MIN])
	SmokerLoot[LOOT_RIFLE_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_RIFLE_MAX])
	SmokerLoot[LOOT_AUTOSHOT_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_AUTOSHOT_MIN])
	SmokerLoot[LOOT_AUTOSHOT_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_AUTOSHOT_MAX])
	SmokerLoot[LOOT_SNIPER_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_SNIPER_MIN])
	SmokerLoot[LOOT_SNIPER_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_SNIPER_MAX])
	SmokerLoot[LOOT_AK47_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_AK47_MIN])
	SmokerLoot[LOOT_AK47_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_AK47_MAX])
	SmokerLoot[LOOT_DEFIBRILLATOR_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_DEFIBRILLATOR_MIN])
	SmokerLoot[LOOT_DEFIBRILLATOR_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_DEFIBRILLATOR_MAX])
	SmokerLoot[LOOT_MILITARY_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_MILITARY_MIN])
	SmokerLoot[LOOT_MILITARY_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_MILITARY_MAX])
	SmokerLoot[LOOT_MAGNUM_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_MAGNUM_MIN])
	SmokerLoot[LOOT_MAGNUM_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_MAGNUM_MAX])
	SmokerLoot[LOOT_SPAS_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_SPAS_MIN])
	SmokerLoot[LOOT_SPAS_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_SPAS_MAX])
	SmokerLoot[LOOT_MELEE_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_MELEE_MIN])
	SmokerLoot[LOOT_MELEE_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_MELEE_MAX])
	SmokerLoot[LOOT_DESERT_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_DESERT_MIN])
	SmokerLoot[LOOT_DESERT_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_DESERT_MAX])
	SmokerLoot[LOOT_CHAINSAW_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_CHAINSAW_MIN])
	SmokerLoot[LOOT_CHAINSAW_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_CHAINSAW_MAX])
	SmokerLoot[LOOT_EXPLOSIVE_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_EXPLOSIVE_MIN])
	SmokerLoot[LOOT_EXPLOSIVE_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_EXPLOSIVE_MAX])
	SmokerLoot[LOOT_INCENDIARY_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_INCENDIARY_MIN])
	SmokerLoot[LOOT_INCENDIARY_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_INCENDIARY_MAX])
	SmokerLoot[LOOT_ADRENALINE_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_ADRENALINE_MIN])
	SmokerLoot[LOOT_ADRENALINE_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_ADRENALINE_MAX])
	SmokerLoot[LOOT_VOMITJAR_MIN] = GetConVarInt(CVarSmokerLoot[LOOT_VOMITJAR_MIN])
	SmokerLoot[LOOT_VOMITJAR_MAX] = GetConVarInt(CVarSmokerLoot[LOOT_VOMITJAR_MAX])

	TankLoot[LOOT_DIENUMBER] = GetConVarInt(CVarTankLoot[LOOT_DIENUMBER])
	TankLoot[LOOT_DIECOUNT] = GetConVarInt(CVarTankLoot[LOOT_DIECOUNT])
	TankLoot[LOOT_KIT_MIN] = GetConVarInt(CVarTankLoot[LOOT_KIT_MIN])
	TankLoot[LOOT_KIT_MAX] = GetConVarInt(CVarTankLoot[LOOT_KIT_MAX])
	TankLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarTankLoot[LOOT_PILLS_MIN])
	TankLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarTankLoot[LOOT_PILLS_MAX])
	TankLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarTankLoot[LOOT_MOLLY_MIN])
	TankLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarTankLoot[LOOT_MOLLY_MAX])
	TankLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarTankLoot[LOOT_PIPE_MIN])
	TankLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarTankLoot[LOOT_PIPE_MAX])
	TankLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarTankLoot[LOOT_ITEM_COUNT])

	TankLoot[LOOT_PANIC_MIN] = GetConVarInt(CVarTankLoot[LOOT_PANIC_MIN])
	TankLoot[LOOT_PANIC_MAX] = GetConVarInt(CVarTankLoot[LOOT_PANIC_MAX])
	TankLoot[LOOT_TANK_MIN] = GetConVarInt(CVarTankLoot[LOOT_TANK_MIN])
	TankLoot[LOOT_TANK_MAX] = GetConVarInt(CVarTankLoot[LOOT_TANK_MAX])
	TankLoot[LOOT_WITCH_MIN] = GetConVarInt(CVarTankLoot[LOOT_WITCH_MIN])
	TankLoot[LOOT_WITCH_MAX] = GetConVarInt(CVarTankLoot[LOOT_WITCH_MAX])
	TankLoot[LOOT_COMMON_MIN] = GetConVarInt(CVarTankLoot[LOOT_COMMON_MIN])
	TankLoot[LOOT_COMMON_MAX] = GetConVarInt(CVarTankLoot[LOOT_COMMON_MAX])

	TankLoot[LOOT_PISTOL_MIN] = GetConVarInt(CVarTankLoot[LOOT_PISTOL_MIN])
	TankLoot[LOOT_PISTOL_MAX] = GetConVarInt(CVarTankLoot[LOOT_PISTOL_MAX])
	TankLoot[LOOT_SMG_MIN] = GetConVarInt(CVarTankLoot[LOOT_SMG_MIN])
	TankLoot[LOOT_SMG_MAX] = GetConVarInt(CVarTankLoot[LOOT_SMG_MAX])
	TankLoot[LOOT_SHOT_MIN] = GetConVarInt(CVarTankLoot[LOOT_SHOT_MIN])
	TankLoot[LOOT_SHOT_MAX] = GetConVarInt(CVarTankLoot[LOOT_SHOT_MAX])
	TankLoot[LOOT_RIFLE_MIN] = GetConVarInt(CVarTankLoot[LOOT_RIFLE_MIN])
	TankLoot[LOOT_RIFLE_MAX] = GetConVarInt(CVarTankLoot[LOOT_RIFLE_MAX])
	TankLoot[LOOT_AUTOSHOT_MIN] = GetConVarInt(CVarTankLoot[LOOT_AUTOSHOT_MIN])
	TankLoot[LOOT_AUTOSHOT_MAX] = GetConVarInt(CVarTankLoot[LOOT_AUTOSHOT_MAX])
	TankLoot[LOOT_SNIPER_MIN] = GetConVarInt(CVarTankLoot[LOOT_SNIPER_MIN])
	TankLoot[LOOT_SNIPER_MAX] = GetConVarInt(CVarTankLoot[LOOT_SNIPER_MAX])
	TankLoot[LOOT_AK47_MIN] = GetConVarInt(CVarTankLoot[LOOT_AK47_MIN])
	TankLoot[LOOT_AK47_MAX] = GetConVarInt(CVarTankLoot[LOOT_AK47_MAX])
	TankLoot[LOOT_DEFIBRILLATOR_MIN] = GetConVarInt(CVarTankLoot[LOOT_DEFIBRILLATOR_MIN])
	TankLoot[LOOT_DEFIBRILLATOR_MAX] = GetConVarInt(CVarTankLoot[LOOT_DEFIBRILLATOR_MAX])
	TankLoot[LOOT_MILITARY_MIN] = GetConVarInt(CVarTankLoot[LOOT_MILITARY_MIN])
	TankLoot[LOOT_MILITARY_MAX] = GetConVarInt(CVarTankLoot[LOOT_MILITARY_MAX])
	TankLoot[LOOT_MAGNUM_MIN] = GetConVarInt(CVarTankLoot[LOOT_MAGNUM_MIN])
	TankLoot[LOOT_MAGNUM_MAX] = GetConVarInt(CVarTankLoot[LOOT_MAGNUM_MAX])
	TankLoot[LOOT_SPAS_MIN] = GetConVarInt(CVarTankLoot[LOOT_SPAS_MIN])
	TankLoot[LOOT_SPAS_MAX] = GetConVarInt(CVarTankLoot[LOOT_SPAS_MAX])
	TankLoot[LOOT_MELEE_MIN] = GetConVarInt(CVarTankLoot[LOOT_MELEE_MIN])
	TankLoot[LOOT_MELEE_MAX] = GetConVarInt(CVarTankLoot[LOOT_MELEE_MAX])
	TankLoot[LOOT_DESERT_MIN] = GetConVarInt(CVarTankLoot[LOOT_DESERT_MIN])
	TankLoot[LOOT_DESERT_MAX] = GetConVarInt(CVarTankLoot[LOOT_DESERT_MAX])
	TankLoot[LOOT_CHAINSAW_MIN] = GetConVarInt(CVarTankLoot[LOOT_CHAINSAW_MIN])
	TankLoot[LOOT_CHAINSAW_MAX] = GetConVarInt(CVarTankLoot[LOOT_CHAINSAW_MAX])
	TankLoot[LOOT_EXPLOSIVE_MIN] = GetConVarInt(CVarTankLoot[LOOT_EXPLOSIVE_MIN])
	TankLoot[LOOT_EXPLOSIVE_MAX] = GetConVarInt(CVarTankLoot[LOOT_EXPLOSIVE_MAX])
	TankLoot[LOOT_INCENDIARY_MIN] = GetConVarInt(CVarTankLoot[LOOT_INCENDIARY_MIN])
	TankLoot[LOOT_INCENDIARY_MAX] = GetConVarInt(CVarTankLoot[LOOT_INCENDIARY_MAX])
	TankLoot[LOOT_ADRENALINE_MIN] = GetConVarInt(CVarTankLoot[LOOT_ADRENALINE_MIN])
	TankLoot[LOOT_ADRENALINE_MAX] = GetConVarInt(CVarTankLoot[LOOT_ADRENALINE_MAX])
	TankLoot[LOOT_VOMITJAR_MIN] = GetConVarInt(CVarTankLoot[LOOT_VOMITJAR_MIN])
	TankLoot[LOOT_VOMITJAR_MAX] = GetConVarInt(CVarTankLoot[LOOT_VOMITJAR_MAX])

	WitchLoot[LOOT_DIENUMBER] = GetConVarInt(CVarWitchLoot[LOOT_DIENUMBER])
	WitchLoot[LOOT_DIECOUNT] = GetConVarInt(CVarWitchLoot[LOOT_DIECOUNT])
	WitchLoot[LOOT_KIT_MIN] = GetConVarInt(CVarWitchLoot[LOOT_KIT_MIN])
	WitchLoot[LOOT_KIT_MAX] = GetConVarInt(CVarWitchLoot[LOOT_KIT_MAX])
	WitchLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarWitchLoot[LOOT_PILLS_MIN])
	WitchLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarWitchLoot[LOOT_PILLS_MAX])
	WitchLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarWitchLoot[LOOT_MOLLY_MIN])
	WitchLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarWitchLoot[LOOT_MOLLY_MAX])
	WitchLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarWitchLoot[LOOT_PIPE_MIN])
	WitchLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarWitchLoot[LOOT_PIPE_MAX])
	WitchLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarWitchLoot[LOOT_ITEM_COUNT])

	WitchLoot[LOOT_PANIC_MIN] = GetConVarInt(CVarWitchLoot[LOOT_PANIC_MIN])
	WitchLoot[LOOT_PANIC_MAX] = GetConVarInt(CVarWitchLoot[LOOT_PANIC_MAX])
	WitchLoot[LOOT_TANK_MIN] = GetConVarInt(CVarWitchLoot[LOOT_TANK_MIN])
	WitchLoot[LOOT_TANK_MAX] = GetConVarInt(CVarWitchLoot[LOOT_TANK_MAX])
	WitchLoot[LOOT_WITCH_MIN] = GetConVarInt(CVarWitchLoot[LOOT_WITCH_MIN])
	WitchLoot[LOOT_WITCH_MAX] = GetConVarInt(CVarWitchLoot[LOOT_WITCH_MAX])
	WitchLoot[LOOT_COMMON_MIN] = GetConVarInt(CVarWitchLoot[LOOT_COMMON_MIN])
	WitchLoot[LOOT_COMMON_MAX] = GetConVarInt(CVarWitchLoot[LOOT_COMMON_MAX])

	WitchLoot[LOOT_PISTOL_MIN] = GetConVarInt(CVarWitchLoot[LOOT_PISTOL_MIN])
	WitchLoot[LOOT_PISTOL_MAX] = GetConVarInt(CVarWitchLoot[LOOT_PISTOL_MAX])
	WitchLoot[LOOT_SMG_MIN] = GetConVarInt(CVarWitchLoot[LOOT_SMG_MIN])
	WitchLoot[LOOT_SMG_MAX] = GetConVarInt(CVarWitchLoot[LOOT_SMG_MAX])
	WitchLoot[LOOT_SHOT_MIN] = GetConVarInt(CVarWitchLoot[LOOT_SHOT_MIN])
	WitchLoot[LOOT_SHOT_MAX] = GetConVarInt(CVarWitchLoot[LOOT_SHOT_MAX])
	WitchLoot[LOOT_RIFLE_MIN] = GetConVarInt(CVarWitchLoot[LOOT_RIFLE_MIN])
	WitchLoot[LOOT_RIFLE_MAX] = GetConVarInt(CVarWitchLoot[LOOT_RIFLE_MAX])
	WitchLoot[LOOT_AUTOSHOT_MIN] = GetConVarInt(CVarWitchLoot[LOOT_AUTOSHOT_MIN])
	WitchLoot[LOOT_AUTOSHOT_MAX] = GetConVarInt(CVarWitchLoot[LOOT_AUTOSHOT_MAX])
	WitchLoot[LOOT_SNIPER_MIN] = GetConVarInt(CVarWitchLoot[LOOT_SNIPER_MIN])
	WitchLoot[LOOT_SNIPER_MAX] = GetConVarInt(CVarWitchLoot[LOOT_SNIPER_MAX])
	WitchLoot[LOOT_AK47_MIN] = GetConVarInt(CVarWitchLoot[LOOT_AK47_MIN])
	WitchLoot[LOOT_AK47_MAX] = GetConVarInt(CVarWitchLoot[LOOT_AK47_MAX])
	WitchLoot[LOOT_DEFIBRILLATOR_MIN] = GetConVarInt(CVarWitchLoot[LOOT_DEFIBRILLATOR_MIN])
	WitchLoot[LOOT_DEFIBRILLATOR_MAX] = GetConVarInt(CVarWitchLoot[LOOT_DEFIBRILLATOR_MAX])
	WitchLoot[LOOT_MILITARY_MIN] = GetConVarInt(CVarWitchLoot[LOOT_MILITARY_MIN])
	WitchLoot[LOOT_MILITARY_MAX] = GetConVarInt(CVarWitchLoot[LOOT_MILITARY_MAX])
	WitchLoot[LOOT_MAGNUM_MIN] = GetConVarInt(CVarWitchLoot[LOOT_MAGNUM_MIN])
	WitchLoot[LOOT_MAGNUM_MAX] = GetConVarInt(CVarWitchLoot[LOOT_MAGNUM_MAX])
	WitchLoot[LOOT_SPAS_MIN] = GetConVarInt(CVarWitchLoot[LOOT_SPAS_MIN])
	WitchLoot[LOOT_SPAS_MAX] = GetConVarInt(CVarWitchLoot[LOOT_SPAS_MAX])
	WitchLoot[LOOT_MELEE_MIN] = GetConVarInt(CVarWitchLoot[LOOT_MELEE_MIN])
	WitchLoot[LOOT_MELEE_MAX] = GetConVarInt(CVarWitchLoot[LOOT_MELEE_MAX])
	WitchLoot[LOOT_DESERT_MIN] = GetConVarInt(CVarWitchLoot[LOOT_DESERT_MIN])
	WitchLoot[LOOT_DESERT_MAX] = GetConVarInt(CVarWitchLoot[LOOT_DESERT_MAX])
	WitchLoot[LOOT_CHAINSAW_MIN] = GetConVarInt(CVarWitchLoot[LOOT_CHAINSAW_MIN])
	WitchLoot[LOOT_CHAINSAW_MAX] = GetConVarInt(CVarWitchLoot[LOOT_CHAINSAW_MAX])
	WitchLoot[LOOT_EXPLOSIVE_MIN] = GetConVarInt(CVarWitchLoot[LOOT_EXPLOSIVE_MIN])
	WitchLoot[LOOT_EXPLOSIVE_MAX] = GetConVarInt(CVarWitchLoot[LOOT_EXPLOSIVE_MAX])
	WitchLoot[LOOT_INCENDIARY_MIN] = GetConVarInt(CVarWitchLoot[LOOT_INCENDIARY_MIN])
	WitchLoot[LOOT_INCENDIARY_MAX] = GetConVarInt(CVarWitchLoot[LOOT_INCENDIARY_MAX])
	WitchLoot[LOOT_ADRENALINE_MIN] = GetConVarInt(CVarWitchLoot[LOOT_ADRENALINE_MIN])
	WitchLoot[LOOT_ADRENALINE_MAX] = GetConVarInt(CVarWitchLoot[LOOT_ADRENALINE_MAX])
	WitchLoot[LOOT_VOMITJAR_MIN] = GetConVarInt(CVarWitchLoot[LOOT_VOMITJAR_MIN])
	WitchLoot[LOOT_VOMITJAR_MAX] = GetConVarInt(CVarWitchLoot[LOOT_VOMITJAR_MAX])

	SpitterLoot[LOOT_DIENUMBER] = GetConVarInt(CVarSpitterLoot[LOOT_DIENUMBER])
	SpitterLoot[LOOT_DIECOUNT] = GetConVarInt(CVarSpitterLoot[LOOT_DIECOUNT])
	SpitterLoot[LOOT_KIT_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_KIT_MIN])
	SpitterLoot[LOOT_KIT_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_KIT_MAX])
	SpitterLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_PILLS_MIN])
	SpitterLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_PILLS_MAX])
	SpitterLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_MOLLY_MIN])
	SpitterLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_MOLLY_MAX])
	SpitterLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_PIPE_MIN])
	SpitterLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_PIPE_MAX])
	SpitterLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarSpitterLoot[LOOT_ITEM_COUNT])

	SpitterLoot[LOOT_PANIC_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_PANIC_MIN])
	SpitterLoot[LOOT_PANIC_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_PANIC_MAX])
	SpitterLoot[LOOT_TANK_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_TANK_MIN])
	SpitterLoot[LOOT_TANK_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_TANK_MAX])
	SpitterLoot[LOOT_WITCH_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_WITCH_MIN])
	SpitterLoot[LOOT_WITCH_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_WITCH_MAX])
	SpitterLoot[LOOT_COMMON_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_COMMON_MIN])
	SpitterLoot[LOOT_COMMON_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_COMMON_MAX])

	SpitterLoot[LOOT_PISTOL_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_PISTOL_MIN])
	SpitterLoot[LOOT_PISTOL_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_PISTOL_MAX])
	SpitterLoot[LOOT_SMG_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_SMG_MIN])
	SpitterLoot[LOOT_SMG_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_SMG_MAX])
	SpitterLoot[LOOT_SHOT_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_SHOT_MIN])
	SpitterLoot[LOOT_SHOT_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_SHOT_MAX])
	SpitterLoot[LOOT_RIFLE_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_RIFLE_MIN])
	SpitterLoot[LOOT_RIFLE_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_RIFLE_MAX])
	SpitterLoot[LOOT_AUTOSHOT_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_AUTOSHOT_MIN])
	SpitterLoot[LOOT_AUTOSHOT_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_AUTOSHOT_MAX])
	SpitterLoot[LOOT_SNIPER_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_SNIPER_MIN])
	SpitterLoot[LOOT_SNIPER_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_SNIPER_MAX])
	SpitterLoot[LOOT_AK47_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_AK47_MIN])
	SpitterLoot[LOOT_AK47_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_AK47_MAX])
	SpitterLoot[LOOT_DEFIBRILLATOR_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_DEFIBRILLATOR_MIN])
	SpitterLoot[LOOT_DEFIBRILLATOR_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_DEFIBRILLATOR_MAX])
	SpitterLoot[LOOT_MILITARY_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_MILITARY_MIN])
	SpitterLoot[LOOT_MILITARY_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_MILITARY_MAX])
	SpitterLoot[LOOT_MAGNUM_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_MAGNUM_MIN])
	SpitterLoot[LOOT_MAGNUM_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_MAGNUM_MAX])
	SpitterLoot[LOOT_SPAS_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_SPAS_MIN])
	SpitterLoot[LOOT_SPAS_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_SPAS_MAX])
	SpitterLoot[LOOT_MELEE_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_MELEE_MIN])
	SpitterLoot[LOOT_MELEE_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_MELEE_MAX])
	SpitterLoot[LOOT_DESERT_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_DESERT_MIN])
	SpitterLoot[LOOT_DESERT_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_DESERT_MAX])
	SpitterLoot[LOOT_CHAINSAW_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_CHAINSAW_MIN])
	SpitterLoot[LOOT_CHAINSAW_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_CHAINSAW_MAX])
	SpitterLoot[LOOT_EXPLOSIVE_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_EXPLOSIVE_MIN])
	SpitterLoot[LOOT_EXPLOSIVE_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_EXPLOSIVE_MAX])
	SpitterLoot[LOOT_INCENDIARY_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_INCENDIARY_MIN])
	SpitterLoot[LOOT_INCENDIARY_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_INCENDIARY_MAX])
	SpitterLoot[LOOT_ADRENALINE_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_ADRENALINE_MIN])
	SpitterLoot[LOOT_ADRENALINE_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_ADRENALINE_MAX])
	SpitterLoot[LOOT_VOMITJAR_MIN] = GetConVarInt(CVarSpitterLoot[LOOT_VOMITJAR_MIN])
	SpitterLoot[LOOT_VOMITJAR_MAX] = GetConVarInt(CVarSpitterLoot[LOOT_VOMITJAR_MAX])

	ChargerLoot[LOOT_DIENUMBER] = GetConVarInt(CVarChargerLoot[LOOT_DIENUMBER])
	ChargerLoot[LOOT_DIECOUNT] = GetConVarInt(CVarChargerLoot[LOOT_DIECOUNT])
	ChargerLoot[LOOT_KIT_MIN] = GetConVarInt(CVarChargerLoot[LOOT_KIT_MIN])
	ChargerLoot[LOOT_KIT_MAX] = GetConVarInt(CVarChargerLoot[LOOT_KIT_MAX])
	ChargerLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarChargerLoot[LOOT_PILLS_MIN])
	ChargerLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarChargerLoot[LOOT_PILLS_MAX])
	ChargerLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarChargerLoot[LOOT_MOLLY_MIN])
	ChargerLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarChargerLoot[LOOT_MOLLY_MAX])
	ChargerLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarChargerLoot[LOOT_PIPE_MIN])
	ChargerLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarChargerLoot[LOOT_PIPE_MAX])
	ChargerLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarChargerLoot[LOOT_ITEM_COUNT])
	
	ChargerLoot[LOOT_PANIC_MIN] = GetConVarInt(CVarChargerLoot[LOOT_PANIC_MIN])
	ChargerLoot[LOOT_PANIC_MAX] = GetConVarInt(CVarChargerLoot[LOOT_PANIC_MAX])
	ChargerLoot[LOOT_TANK_MIN] = GetConVarInt(CVarChargerLoot[LOOT_TANK_MIN])
	ChargerLoot[LOOT_TANK_MAX] = GetConVarInt(CVarChargerLoot[LOOT_TANK_MAX])
	ChargerLoot[LOOT_WITCH_MIN] = GetConVarInt(CVarChargerLoot[LOOT_WITCH_MIN])
	ChargerLoot[LOOT_WITCH_MAX] = GetConVarInt(CVarChargerLoot[LOOT_WITCH_MAX])
	ChargerLoot[LOOT_COMMON_MIN] = GetConVarInt(CVarChargerLoot[LOOT_COMMON_MIN])
	ChargerLoot[LOOT_COMMON_MAX] = GetConVarInt(CVarChargerLoot[LOOT_COMMON_MAX])

	ChargerLoot[LOOT_PISTOL_MIN] = GetConVarInt(CVarChargerLoot[LOOT_PISTOL_MIN])
	ChargerLoot[LOOT_PISTOL_MAX] = GetConVarInt(CVarChargerLoot[LOOT_PISTOL_MAX])
	ChargerLoot[LOOT_SMG_MIN] = GetConVarInt(CVarChargerLoot[LOOT_SMG_MIN])
	ChargerLoot[LOOT_SMG_MAX] = GetConVarInt(CVarChargerLoot[LOOT_SMG_MAX])
	ChargerLoot[LOOT_SHOT_MIN] = GetConVarInt(CVarChargerLoot[LOOT_SHOT_MIN])
	ChargerLoot[LOOT_SHOT_MAX] = GetConVarInt(CVarChargerLoot[LOOT_SHOT_MAX])
	ChargerLoot[LOOT_RIFLE_MIN] = GetConVarInt(CVarChargerLoot[LOOT_RIFLE_MIN])
	ChargerLoot[LOOT_RIFLE_MAX] = GetConVarInt(CVarChargerLoot[LOOT_RIFLE_MAX])
	ChargerLoot[LOOT_AUTOSHOT_MIN] = GetConVarInt(CVarChargerLoot[LOOT_AUTOSHOT_MIN])
	ChargerLoot[LOOT_AUTOSHOT_MAX] = GetConVarInt(CVarChargerLoot[LOOT_AUTOSHOT_MAX])
	ChargerLoot[LOOT_SNIPER_MIN] = GetConVarInt(CVarChargerLoot[LOOT_SNIPER_MIN])
	ChargerLoot[LOOT_SNIPER_MAX] = GetConVarInt(CVarChargerLoot[LOOT_SNIPER_MAX])
	ChargerLoot[LOOT_AK47_MIN] = GetConVarInt(CVarChargerLoot[LOOT_AK47_MIN])
	ChargerLoot[LOOT_AK47_MAX] = GetConVarInt(CVarChargerLoot[LOOT_AK47_MAX])
	ChargerLoot[LOOT_DEFIBRILLATOR_MIN] = GetConVarInt(CVarChargerLoot[LOOT_DEFIBRILLATOR_MIN])
	ChargerLoot[LOOT_DEFIBRILLATOR_MAX] = GetConVarInt(CVarChargerLoot[LOOT_DEFIBRILLATOR_MAX])
	ChargerLoot[LOOT_MILITARY_MIN] = GetConVarInt(CVarChargerLoot[LOOT_MILITARY_MIN])
	ChargerLoot[LOOT_MILITARY_MAX] = GetConVarInt(CVarChargerLoot[LOOT_MILITARY_MAX])
	ChargerLoot[LOOT_MAGNUM_MIN] = GetConVarInt(CVarChargerLoot[LOOT_MAGNUM_MIN])
	ChargerLoot[LOOT_MAGNUM_MAX] = GetConVarInt(CVarChargerLoot[LOOT_MAGNUM_MAX])
	ChargerLoot[LOOT_SPAS_MIN] = GetConVarInt(CVarChargerLoot[LOOT_SPAS_MIN])
	ChargerLoot[LOOT_SPAS_MAX] = GetConVarInt(CVarChargerLoot[LOOT_SPAS_MAX])
	ChargerLoot[LOOT_MELEE_MIN] = GetConVarInt(CVarChargerLoot[LOOT_MELEE_MIN])
	ChargerLoot[LOOT_MELEE_MAX] = GetConVarInt(CVarChargerLoot[LOOT_MELEE_MAX])
	ChargerLoot[LOOT_DESERT_MIN] = GetConVarInt(CVarChargerLoot[LOOT_DESERT_MIN])
	ChargerLoot[LOOT_DESERT_MAX] = GetConVarInt(CVarChargerLoot[LOOT_DESERT_MAX])
	ChargerLoot[LOOT_CHAINSAW_MIN] = GetConVarInt(CVarChargerLoot[LOOT_CHAINSAW_MIN])
	ChargerLoot[LOOT_CHAINSAW_MAX] = GetConVarInt(CVarChargerLoot[LOOT_CHAINSAW_MAX])
	ChargerLoot[LOOT_EXPLOSIVE_MIN] = GetConVarInt(CVarChargerLoot[LOOT_EXPLOSIVE_MIN])
	ChargerLoot[LOOT_EXPLOSIVE_MAX] = GetConVarInt(CVarChargerLoot[LOOT_EXPLOSIVE_MAX])
	ChargerLoot[LOOT_INCENDIARY_MIN] = GetConVarInt(CVarChargerLoot[LOOT_INCENDIARY_MIN])
	ChargerLoot[LOOT_INCENDIARY_MAX] = GetConVarInt(CVarChargerLoot[LOOT_INCENDIARY_MAX])
	ChargerLoot[LOOT_ADRENALINE_MIN] = GetConVarInt(CVarChargerLoot[LOOT_ADRENALINE_MIN])
	ChargerLoot[LOOT_ADRENALINE_MAX] = GetConVarInt(CVarChargerLoot[LOOT_ADRENALINE_MAX])
	ChargerLoot[LOOT_VOMITJAR_MIN] = GetConVarInt(CVarChargerLoot[LOOT_VOMITJAR_MIN])
	ChargerLoot[LOOT_VOMITJAR_MAX] = GetConVarInt(CVarChargerLoot[LOOT_VOMITJAR_MAX])

	JockeyLoot[LOOT_DIENUMBER] = GetConVarInt(CVarJockeyLoot[LOOT_DIENUMBER])
	JockeyLoot[LOOT_DIECOUNT] = GetConVarInt(CVarJockeyLoot[LOOT_DIECOUNT])
	JockeyLoot[LOOT_KIT_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_KIT_MIN])
	JockeyLoot[LOOT_KIT_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_KIT_MAX])
	JockeyLoot[LOOT_PILLS_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_PILLS_MIN])
	JockeyLoot[LOOT_PILLS_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_PILLS_MAX])
	JockeyLoot[LOOT_MOLLY_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_MOLLY_MIN])
	JockeyLoot[LOOT_MOLLY_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_MOLLY_MAX])
	JockeyLoot[LOOT_PIPE_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_PIPE_MIN])
	JockeyLoot[LOOT_PIPE_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_PIPE_MAX])
	JockeyLoot[LOOT_ITEM_COUNT] = GetConVarInt(CVarJockeyLoot[LOOT_ITEM_COUNT])

	JockeyLoot[LOOT_PANIC_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_PANIC_MIN])
	JockeyLoot[LOOT_PANIC_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_PANIC_MAX])
	JockeyLoot[LOOT_TANK_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_TANK_MIN])
	JockeyLoot[LOOT_TANK_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_TANK_MAX])
	JockeyLoot[LOOT_WITCH_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_WITCH_MIN])
	JockeyLoot[LOOT_WITCH_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_WITCH_MAX])
	JockeyLoot[LOOT_COMMON_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_COMMON_MIN])
	JockeyLoot[LOOT_COMMON_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_COMMON_MAX])

	JockeyLoot[LOOT_PISTOL_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_PISTOL_MIN])
	JockeyLoot[LOOT_PISTOL_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_PISTOL_MAX])
	JockeyLoot[LOOT_SMG_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_SMG_MIN])
	JockeyLoot[LOOT_SMG_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_SMG_MAX])
	JockeyLoot[LOOT_SHOT_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_SHOT_MIN])
	JockeyLoot[LOOT_SHOT_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_SHOT_MAX])
	JockeyLoot[LOOT_RIFLE_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_RIFLE_MIN])
	JockeyLoot[LOOT_RIFLE_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_RIFLE_MAX])
	JockeyLoot[LOOT_AUTOSHOT_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_AUTOSHOT_MIN])
	JockeyLoot[LOOT_AUTOSHOT_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_AUTOSHOT_MAX])
	JockeyLoot[LOOT_SNIPER_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_SNIPER_MIN])
	JockeyLoot[LOOT_SNIPER_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_SNIPER_MAX])
	JockeyLoot[LOOT_AK47_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_AK47_MIN])
	JockeyLoot[LOOT_AK47_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_AK47_MAX])
	JockeyLoot[LOOT_DEFIBRILLATOR_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_DEFIBRILLATOR_MIN])
	JockeyLoot[LOOT_DEFIBRILLATOR_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_DEFIBRILLATOR_MAX])
	JockeyLoot[LOOT_MILITARY_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_MILITARY_MIN])
	JockeyLoot[LOOT_MILITARY_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_MILITARY_MAX])
	JockeyLoot[LOOT_MAGNUM_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_MAGNUM_MIN])
	JockeyLoot[LOOT_MAGNUM_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_MAGNUM_MAX])
	JockeyLoot[LOOT_SPAS_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_SPAS_MIN])
	JockeyLoot[LOOT_SPAS_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_SPAS_MAX])
	JockeyLoot[LOOT_MELEE_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_MELEE_MIN])
	JockeyLoot[LOOT_MELEE_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_MELEE_MAX])
	JockeyLoot[LOOT_DESERT_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_DESERT_MIN])
	JockeyLoot[LOOT_DESERT_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_DESERT_MAX])
	JockeyLoot[LOOT_CHAINSAW_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_CHAINSAW_MIN])
	JockeyLoot[LOOT_CHAINSAW_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_CHAINSAW_MAX])
	JockeyLoot[LOOT_EXPLOSIVE_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_EXPLOSIVE_MIN])
	JockeyLoot[LOOT_EXPLOSIVE_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_EXPLOSIVE_MAX])
	JockeyLoot[LOOT_INCENDIARY_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_INCENDIARY_MIN])
	JockeyLoot[LOOT_INCENDIARY_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_INCENDIARY_MAX])
	JockeyLoot[LOOT_ADRENALINE_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_ADRENALINE_MIN])
	JockeyLoot[LOOT_ADRENALINE_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_ADRENALINE_MAX])
	JockeyLoot[LOOT_VOMITJAR_MIN] = GetConVarInt(CVarJockeyLoot[LOOT_VOMITJAR_MIN])
	JockeyLoot[LOOT_VOMITJAR_MAX] = GetConVarInt(CVarJockeyLoot[LOOT_VOMITJAR_MAX])
}

public Action Event_PlayerDeath(Handle hEvent, const char[] strName, bool DontBroadcast)
{
	char strBuffer[55];
	//qwerty search key
	int ClientId    = 0;
	ClientId = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (ClientId == 0) 
	{
		// We had 0 so it MAY be a witch, check.
		GetEntityNetClass(GetEventInt(hEvent, "entityid"), strBuffer, sizeof(strBuffer));
		if (StrEqual(strBuffer, "Witch", false))
		{
			/*
			// TODO: Add witch functionallity
			// Witch Functionality Added Below,
			// This segment left in for error testing.
			//TellAll("entityid check");
			// Visual Check
			//LogMessage("entityid check");
			// Log Check
			*/
		}
		return Plugin_Continue;
	}

	int class = GetEntProp(ClientId, Prop_Send, "m_zombieClass");
	if (class == ZOMBIECLASS_HUNTER)
	{
		LogMessage("[DICE] Hunter killed: Rolling for %i items.", HunterLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < HunterLoot[LOOT_ITEM_COUNT]; i++)
		{
			LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[HunterLoot[LOOT_DIENUMBER] - 1], HunterLoot[LOOT_DIECOUNT]);

			SpawnItemFromDieResult(ClientId, HunterLoot, RollDice(HunterLoot[LOOT_DIECOUNT], HunterLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_SMOKER)
	{
		LogMessage("[DICE] Smoker killed: Rolling for %i items.", SmokerLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < SmokerLoot[LOOT_ITEM_COUNT]; i++)
		{
			LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[SmokerLoot[LOOT_DIENUMBER] - 1], SmokerLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, SmokerLoot, RollDice(SmokerLoot[LOOT_DIECOUNT], SmokerLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_BOOMER)
	{
		LogMessage("[DICE] Boomer killed: Rolling for %i items.", BoomerLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < BoomerLoot[LOOT_ITEM_COUNT]; i++)
		{
			LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[BoomerLoot[LOOT_DIENUMBER] - 1], BoomerLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, BoomerLoot, RollDice(BoomerLoot[LOOT_DIECOUNT], BoomerLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_SPITTER)
	{
		LogMessage("[DICE] Spitter killed: Rolling for %i items.", SpitterLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < SpitterLoot[LOOT_ITEM_COUNT]; i++)
		{
			LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[SpitterLoot[LOOT_DIENUMBER] - 1], SpitterLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, SpitterLoot, RollDice(SpitterLoot[LOOT_DIECOUNT], SpitterLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_CHARGER)
	{
		LogMessage("[DICE] Charger killed: Rolling for %i items.", ChargerLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < ChargerLoot[LOOT_ITEM_COUNT]; i++)
		{
			LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[ChargerLoot[LOOT_DIENUMBER] - 1], ChargerLoot[LOOT_DIECOUNT]);
			SpawnItemFromDieResult(ClientId, ChargerLoot, RollDice(ChargerLoot[LOOT_DIECOUNT], ChargerLoot[LOOT_DIENUMBER]));
		}
	}
	else if (class == ZOMBIECLASS_JOCKEY)
	{
		LogMessage("[DICE] Jockey killed: Rolling for %i items.", JockeyLoot[LOOT_ITEM_COUNT]);
		for (int i = 0; i < JockeyLoot[LOOT_ITEM_COUNT]; i++)
		{
			LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[JockeyLoot[LOOT_DIENUMBER] - 1], JockeyLoot[LOOT_DIECOUNT]);
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
		LogMessage("[DICE] Witch killed: Rolling for %i items.", WitchLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < WitchLoot[LOOT_ITEM_COUNT]; i++)
		{
			LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[WitchLoot[LOOT_DIENUMBER] - 1], WitchLoot[LOOT_DIECOUNT]);
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
		LogMessage("[DICE] Tank killed: Rolling for %i items.", TankLoot[LOOT_ITEM_COUNT]);

		for (int i = 0; i < TankLoot[LOOT_ITEM_COUNT]; i++)
		{
			LogMessage("[DICE] Rolling item %i, die has %i sides, %i dice will be rolled.", i + 1, Dice[TankLoot[LOOT_DIENUMBER] - 1], TankLoot[LOOT_DIECOUNT]);
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
		LogMessage("[DICE] Spawned %s.", itemId);

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
			LogMessage("[DICE] Die %i, Result: %i, Total: %i", i + 1, tempResult, result);
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
		PrintSettings(diceSettings);
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
					LogMessage("[DICE] Spawned Panic Event.");
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
						LogMessage("[DICE] Spawned Tank.");
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
						LogMessage("[DICE] Spawned Witch.");
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

				LogMessage("[DICE] Spawned Commons.");
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