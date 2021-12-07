#define PLUGIN_VERSION		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Trigger Multiple Commands
*	Author	:	SilverShot
*	Descrp	:	Create trigger_multiple boxes which execute commands when entered by players.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=224121
*	Plugins	:	http://sourcemod.net/plugins.php?author=Silvers&search=1

========================================================================================
	Change Log:
	
1.1y (05-Sep-2016)
	- Added code that parses the command and replaces {me} with the clients ID.
	  this makes server commands execute commands on the player that activated the trigger 
	  (the root client command option was not working for some reason)
	
1.1 (25-Aug-2013)
	- Added command "sm_trigger_dupe" to create a trigger where you are and take the settings from another trigger.
	- Doubled the maximum string length for commands (to 128 chars).
	- Fixed the plugin not loading trigger boxes in Team Fortress 2.

1.0 (20-Aug-2013)
	- Initial release.

======================================================================================*/

#pragma semicolon 			1

#include <sdktools>

#define	CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x03[Trigger Commands] \x05"
#define CONFIG_DATA			"data/sm_trigger.cfg"
#define MAX_ENTITIES		64
#define CMD_MAX_LENGTH		512
#define MAX_TEAM			16

#define BEAM_TIME		0.3

#define REFIRE_COUNT	1
#define REFIRE_TIME		3.0
#define DELAY_TIME		0.0
#define FIRE_CHANCE		100

static	g_iTeamOne = 2, g_iTeamTwo = 3;
static	String:g_sTeamOne[MAX_TEAM] = "1", String:g_sTeamTwo[MAX_TEAM] = "2";

static	Handle:g_hMenuEdit, Handle:g_hMenuTeam, Handle:g_hMenuBots, Handle:g_hMenuType, Handle:g_hMenuAuth,
		Handle:g_hMenuExec, Handle:g_hMenuBExec, Handle:g_hMenuRefire, Handle:g_hMenuTime, Handle:g_hMenuDelay,
		Handle:g_hMenuChance, Handle:g_hMenuLeave, Handle:g_hMenuVMaxs, Handle:g_hMenuVMins, Handle:g_hMenuPos,
		Handle:g_hCvarAllow, Handle:g_hCvarColor, Handle:g_hCvarModel, Handle:g_hCvarBeam, Handle:g_hCvarHalo, Handle:g_hCvarRefire, g_iCvarRefire,
		String:g_sModelBox[PLATFORM_MAX_PATH], String:g_sMaterialBeam[PLATFORM_MAX_PATH], String:g_sMaterialHalo[PLATFORM_MAX_PATH], g_iColors[4],
		Handle:g_hTimerBeam, g_iLaserMaterial, g_iHaloMaterial, bool:g_bCvarAllow, bool:g_bLoaded, g_iEngine, g_iPlayerSpawn, g_iRoundStart, g_iSelectedTrig,
		g_iMenuEdit[MAXPLAYERS], g_iMenuSelected[MAXPLAYERS], g_iInside[MAXPLAYERS], bool:g_bStopEnd[MAX_ENTITIES], g_iTriggers[MAX_ENTITIES],
		g_iRefireCount[MAX_ENTITIES], Float:g_fRefireTime[MAX_ENTITIES], Float:g_fDelayTime[MAX_ENTITIES], g_iChance[MAX_ENTITIES],
		String:g_sCommand[MAX_ENTITIES][CMD_MAX_LENGTH], g_iCmdData[MAX_ENTITIES], Handle:g_hTimerEnable[MAX_ENTITIES];

enum ()
{
	ENGINE_ANY,
	ENGINE_CSGO,
	ENGINE_CSS,
	ENGINE_L4D,
	ENGINE_L4D2,
	ENGINE_TF2,
	ENGINE_DODS,
	ENGINE_HL2MP,
	ENGINE_INS,
	ENGINE_ZPS,
	ENGINE_AOC,
	ENGINE_DM,
	ENGINE_FF,
	ENGINE_GES,
	ENGINE_HID,
	ENGINE_NTS,
	ENGINE_ND,
	ENGINE_STLS
}

enum (<<=1)
{
	ALLOW_TEAM_1 = 1,
	ALLOW_TEAM_2,
	ALLOW_TEAMS,
	ALLOW_ALIVE,
	ALLOW_DEAD,
	ALLOW_SPEC,
	ALLOW_ALL,
	ALLOW_BOTS,
	ALLOW_REAL,
	EXEC_CLIENT,
	EXEC_ALL,
	EXEC_TEAM_1,
	EXEC_TEAM_2,
	EXEC_TEAMS,
	EXEC_ALIVE,
	EXEC_DEAD,
	EXEC_BOTS,
	EXEC_REAL,
	LEAVE_NO,
	LEAVE_YES,
	COMMAND_SERVER,
	COMMAND_CLIENT,
	COMMAND_FAKE,
	FLAGS_ANY,
	FLAGS_ADMIN,
	FLAGS_CHEAT,
	FLAGS_ADMINCHEAT
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[ANY] Trigger Multiple Commands",
	author = "SilverShot, mod by YoNer",
	description = "Create trigger_multiple boxes which execute commands when entered by players.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=224121"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	// if( strcmp(sGameName, "yourgame", false) )
	// {
		// strcopy(error, err_max, "Plugin does not support yourgame.");
		// return APLRes_SilentFailure;
	// }

	g_iEngine = ENGINE_ANY;
	if( strcmp(sGameName, "csgo", false) == 0 )					g_iEngine = ENGINE_CSGO;
	else if( strcmp(sGameName, "cstrike", false) == 0 )			g_iEngine = ENGINE_CSS;
	else if( strcmp(sGameName, "left4dead", false) == 0 )		g_iEngine = ENGINE_L4D;
	else if( strcmp(sGameName, "left4dead2", false) == 0 )		g_iEngine = ENGINE_L4D2;
	else if( strcmp(sGameName, "tf", false) == 0 )				g_iEngine = ENGINE_TF2;
	else if( strcmp(sGameName, "dod", false) == 0 )				g_iEngine = ENGINE_DODS;
	else if( strcmp(sGameName, "hl2mp", false) == 0 )			g_iEngine = ENGINE_HL2MP;
	else if( strcmp(sGameName, "ins", false) == 0 ||
			strcmp(sGameName, "insurgency", false) == 0 )		g_iEngine = ENGINE_INS;
	else if( strcmp(sGameName, "zps", false) == 0 )				g_iEngine = ENGINE_ZPS;
	else if( strcmp(sGameName, "aoc", false) == 0 )				g_iEngine = ENGINE_AOC;
	else if( strcmp(sGameName, "mmdarkmessiah", false) == 0 )	g_iEngine = ENGINE_DM;
	else if( strcmp(sGameName, "ff", false) == 0 )				g_iEngine = ENGINE_FF;
	else if( strcmp(sGameName, "gesource", false) == 0 )		g_iEngine = ENGINE_GES;
	else if( strcmp(sGameName, "hidden", false) == 0 )			g_iEngine = ENGINE_HID;
	else if( strcmp(sGameName, "nts", false) == 0 )				g_iEngine = ENGINE_NTS;
	else if( strcmp(sGameName, "nucleardawn", false) == 0 )		g_iEngine = ENGINE_ND;
	else if( strcmp(sGameName, "sgtls", false) == 0 )			g_iEngine = ENGINE_STLS;

	return APLRes_Success;
}

public OnPluginStart()
{
	// COMMANDS
	RegAdminCmd("sm_trigger",			CmdTriggerMenu,		ADMFLAG_ROOT,	"Displays a menu with options to edit and position triggers.");
	RegAdminCmd("sm_trigger_add",		CmdTriggerAdd,		ADMFLAG_ROOT,	"Add a command to the currently selected trigger. Usage: sm_trigger_add <command>");
	RegAdminCmd("sm_trigger_dupe",		CmdTriggerDupe,		ADMFLAG_ROOT,	"Create a trigger where you are standing and duplicate the settings from another trigger.");
	RegAdminCmd("sm_trigger_flags",		CmdTriggerFlags,	ADMFLAG_ROOT,	"Usage: sm_trigger_flags <flags>. Displays the bit sum flags (from data config), eg: sm_trigger_flags 17039624");
	RegAdminCmd("sm_trigger_reload",	CmdTriggerReload,	ADMFLAG_ROOT,	"Resets the plugin, removing all triggers and reloading the maps data config.");

	// CVARS
	g_hCvarAllow =	CreateConVar("sm_trigger_allow",		"1",									"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarColor =	CreateConVar("sm_trigger_color",		"255 0 0",								"Color of the laser box when displaying the trigger. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS);
	g_hCvarBeam =	CreateConVar("sm_trigger_mat_beam",		"materials/sprites/laserbeam.vmt",		"Used for the laser beam to display Trigger Boxes.", CVAR_FLAGS);
	g_hCvarHalo =	CreateConVar("sm_trigger_mat_halo",		"materials/sprites/halo01.vmt",			"Used for the laser beam to display Trigger Boxes.", CVAR_FLAGS);
	g_hCvarModel =	CreateConVar("sm_trigger_model",		"models/props/cs_militia/silo_01.mdl",	"The model to use for the bounding box, the larger the better, will be invisible and is used as the maximum size for a trigger box.", CVAR_FLAGS);
	g_hCvarRefire =	CreateConVar("sm_trigger_refire",		"0",									"How does the Activate Chance affect the Refire Count when the chance fails to activate? 0=Do not add to the Refire Count. 1=Add to the Refire Count on Chance fail.", CVAR_FLAGS);
	CreateConVar("sm_trigger_version",		PLUGIN_VERSION,											"Trigger Multiple Commands plugin version",	CVAR_FLAGS|FCVAR_DONTRECORD);

	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarColor,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarModel,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarBeam,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHalo,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRefire,			ConVarChanged_Cvars);


	decl String:sTemp[64];

	// Menu team names
	if( g_iEngine == ENGINE_CSGO || g_iEngine == ENGINE_CSS )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Counter Terrorist");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Terrorist");
	}
	else if( g_iEngine == ENGINE_L4D || g_iEngine == ENGINE_L4D2 ) 
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Survivor");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Infected");
	}
	else if( g_iEngine == ENGINE_TF2 || g_iEngine == ENGINE_FF )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Blu");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Red");
	}
	else if( g_iEngine == ENGINE_DODS )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Allies");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Axis");
	}
	else if( g_iEngine == ENGINE_HL2MP )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Rebels");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Combine");
	}
	else if( g_iEngine == ENGINE_INS )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Marines");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Insurgents");
	}
	else if( g_iEngine == ENGINE_ZPS )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Survivors");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Zombies");
	}
	else if( g_iEngine == ENGINE_AOC )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Agatha Knights");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Mason Order");
	}
	else if( g_iEngine == ENGINE_DM )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Humans");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Undead");
	}
	else if( g_iEngine == ENGINE_GES )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "MI6");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Janus");
	}
	else if( g_iEngine == ENGINE_HID )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Hidden");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "IRIS");
	}
	else if( g_iEngine == ENGINE_NTS )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "NSF");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Jinrai");
	}
	else if( g_iEngine == ENGINE_ND )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Consortium");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Empire");
	}
	else if( g_iEngine == ENGINE_STLS )
	{
		Format(g_sTeamOne, sizeof(g_sTeamOne), "Tauri");
		Format(g_sTeamTwo, sizeof(g_sTeamTwo), "Goauld");
	}


	// MENUS
	g_hMenuEdit = CreateMenu(EditMenuHandler);
	AddMenuItem(g_hMenuEdit, "", "Type Of Command To Exec");
	AddMenuItem(g_hMenuEdit, "", "Command Flags (Admin/Cheat)");
	AddMenuItem(g_hMenuEdit, "", "Who Can Activate");
	AddMenuItem(g_hMenuEdit, "", "Who Executes The Command");
	AddMenuItem(g_hMenuEdit, "", "Refire Count");
	AddMenuItem(g_hMenuEdit, "", "Refire Time");
	AddMenuItem(g_hMenuEdit, "", "Command Delay");
	AddMenuItem(g_hMenuEdit, "", "Activate Chance");
	AddMenuItem(g_hMenuEdit, "", "Leave Box");
	SetMenuTitle(g_hMenuEdit, "TMC: Edit Options");
	SetMenuExitBackButton(g_hMenuEdit, true);

	g_hMenuType = CreateMenu(DataMenuHandler);
	AddMenuItem(g_hMenuType, "", "Server Command (executes the command on the server)");
	AddMenuItem(g_hMenuType, "", "Client Command (executes the command client side)");
	AddMenuItem(g_hMenuType, "", "Fake Client Command (executes the command on the server as if the client had sent)");
	SetMenuTitle(g_hMenuType, "TMC: Command Type\nWhich type of command do you want to execute?");
	SetMenuExitBackButton(g_hMenuType, true);

	g_hMenuAuth = CreateMenu(DataMenuHandler);
	AddMenuItem(g_hMenuAuth, "", "Standard");
	AddMenuItem(g_hMenuAuth, "", "Remove Cheat Flags");
	AddMenuItem(g_hMenuAuth, "", "Execute as Root Admin");
	AddMenuItem(g_hMenuAuth, "", "Execute as Root Admin and Remove Cheat Flags");
	SetMenuTitle(g_hMenuAuth, "TMC: Command Flags\nDo you want to remove the cheat flag and/or give the user Root admin rights when executing the command?");
	SetMenuExitBackButton(g_hMenuAuth, true);

	g_hMenuTeam = CreateMenu(DataMenuHandler);
	AddMenuItem(g_hMenuTeam, "", "Alive Players");
	Format(sTemp, sizeof(sTemp), "Team %s", g_sTeamOne);
	AddMenuItem(g_hMenuTeam, "", sTemp);
	Format(sTemp, sizeof(sTemp), "Team %s", g_sTeamTwo);
	AddMenuItem(g_hMenuTeam, "", sTemp);
	Format(sTemp, sizeof(sTemp), "Team %s + %s", g_sTeamOne, g_sTeamTwo);
	AddMenuItem(g_hMenuTeam, "", sTemp);
	AddMenuItem(g_hMenuTeam, "", "Dead Players");
	AddMenuItem(g_hMenuTeam, "", "Spectators");
	AddMenuItem(g_hMenuTeam, "", "All Players");
	SetMenuTitle(g_hMenuTeam, "TMC: Who Activates the Trigger");
	SetMenuExitBackButton(g_hMenuTeam, true);

	g_hMenuBots = CreateMenu(DataMenuHandler);
	AddMenuItem(g_hMenuBots, "", "All");
	AddMenuItem(g_hMenuBots, "", "Only Humans");
	AddMenuItem(g_hMenuBots, "", "Only Bots");
	SetMenuTitle(g_hMenuBots, "TMC: Who Activates the Trigger");
	SetMenuExitBackButton(g_hMenuBots, true);

	g_hMenuExec = CreateMenu(DataMenuHandler);
	AddMenuItem(g_hMenuExec, "", "Activator Only");
	AddMenuItem(g_hMenuExec, "", "Everyone");
	Format(sTemp, sizeof(sTemp), "Team %s", g_sTeamOne);
	AddMenuItem(g_hMenuExec, "", sTemp);
	Format(sTemp, sizeof(sTemp), "Team %s", g_sTeamTwo);
	AddMenuItem(g_hMenuExec, "", sTemp);
	Format(sTemp, sizeof(sTemp), "Team %s + %s", g_sTeamOne, g_sTeamTwo);
	AddMenuItem(g_hMenuExec, "", sTemp);
	AddMenuItem(g_hMenuExec, "", "Alive Players");
	AddMenuItem(g_hMenuExec, "", "Dead Players");
	SetMenuTitle(g_hMenuExec, "TMC: Command Execute\nDo you want the command to run on all players or only the activator?");
	SetMenuExitBackButton(g_hMenuExec, true);

	g_hMenuBExec = CreateMenu(DataMenuHandler);
	AddMenuItem(g_hMenuBExec, "", "All");
	AddMenuItem(g_hMenuBExec, "", "Only Humans");
	AddMenuItem(g_hMenuBExec, "", "Only Bots");
	SetMenuTitle(g_hMenuBExec, "TMC: Who To Execute On");
	SetMenuExitBackButton(g_hMenuBExec, true);

	g_hMenuRefire = CreateMenu(RefireMenuHandler);
	AddMenuItem(g_hMenuRefire, "0", "Unlimited");
	AddMenuItem(g_hMenuRefire, "-", "- 1");
	AddMenuItem(g_hMenuRefire, "+", "+ 1");
	AddMenuItem(g_hMenuRefire, "1", "1");
	AddMenuItem(g_hMenuRefire, "2", "2");
	AddMenuItem(g_hMenuRefire, "3", "3");
	AddMenuItem(g_hMenuRefire, "4", "4");
	AddMenuItem(g_hMenuRefire, "5", "5");
	AddMenuItem(g_hMenuRefire, "10", "10");
	AddMenuItem(g_hMenuRefire, "15", "15");
	AddMenuItem(g_hMenuRefire, "20", "20");
	AddMenuItem(g_hMenuRefire, "25", "25");
	AddMenuItem(g_hMenuRefire, "30", "30");
	AddMenuItem(g_hMenuRefire, "50", "50");
	SetMenuTitle(g_hMenuRefire, "TMC: Refire Count\nHow many times can the trigger be activated");
	SetMenuExitBackButton(g_hMenuRefire, true);

	g_hMenuTime = CreateMenu(TimeMenuHandler);
	AddMenuItem(g_hMenuTime, "0.5", "0.5 (minimum)");
	AddMenuItem(g_hMenuTime, "-", "- 1.0");
	AddMenuItem(g_hMenuTime, "+", "+ 1.0");
	AddMenuItem(g_hMenuTime, "1.0", "1.0");
	AddMenuItem(g_hMenuTime, "1.5", "1.5");
	AddMenuItem(g_hMenuTime, "2.0", "2.0");
	AddMenuItem(g_hMenuTime, "5.0", "5.0");
	AddMenuItem(g_hMenuTime, "10.0", "10.0");
	AddMenuItem(g_hMenuTime, "15.0", "15.0");
	AddMenuItem(g_hMenuTime, "20.0", "20.0");
	AddMenuItem(g_hMenuTime, "25.0", "25.0");
	AddMenuItem(g_hMenuTime, "30.0", "30.0");
	AddMenuItem(g_hMenuTime, "45.0", "45.0");
	AddMenuItem(g_hMenuTime, "60.0", "60.0");
	SetMenuTitle(g_hMenuTime, "TMC: Refire Time\nHow soon after the trigger is activated to re-enable the trigger");
	SetMenuExitBackButton(g_hMenuTime, true);

	g_hMenuDelay = CreateMenu(DelayMenuHandler);
	AddMenuItem(g_hMenuDelay, "0.0", "Instant - No delay");
	AddMenuItem(g_hMenuDelay, "-", "- 1.0");
	AddMenuItem(g_hMenuDelay, "+", "+ 1.0");
	AddMenuItem(g_hMenuDelay, "0.5", "0.5");
	AddMenuItem(g_hMenuDelay, "1.0", "1.0");
	AddMenuItem(g_hMenuDelay, "2.0", "2.0");
	AddMenuItem(g_hMenuDelay, "3.0", "3.0");
	AddMenuItem(g_hMenuDelay, "5.0", "5.0");
	AddMenuItem(g_hMenuDelay, "10.0", "10.0");
	AddMenuItem(g_hMenuDelay, "15.0", "15.0");
	AddMenuItem(g_hMenuDelay, "20.0", "20.0");
	AddMenuItem(g_hMenuDelay, "25.0", "25.0");
	AddMenuItem(g_hMenuDelay, "30.0", "30.0");
	AddMenuItem(g_hMenuDelay, "45.0", "45.0");
	SetMenuTitle(g_hMenuDelay, "TMC: Command Delay\nExecute the command instantly after triggering or set delay in seconds");
	SetMenuExitBackButton(g_hMenuDelay, true);

	g_hMenuChance = CreateMenu(ChanceMenuHandler);
	AddMenuItem(g_hMenuChance, "100", "Always 100%");
	AddMenuItem(g_hMenuChance, "95", "95%");
	AddMenuItem(g_hMenuChance, "90", "90%");
	AddMenuItem(g_hMenuChance, "80", "80%");
	AddMenuItem(g_hMenuChance, "75", "75%");
	AddMenuItem(g_hMenuChance, "50", "50%");
	AddMenuItem(g_hMenuChance, "30", "30%");
	AddMenuItem(g_hMenuChance, "25", "25%");
	AddMenuItem(g_hMenuChance, "20", "20%");
	AddMenuItem(g_hMenuChance, "15", "15%");
	AddMenuItem(g_hMenuChance, "10", "10%");
	AddMenuItem(g_hMenuChance, "5", "5%");
	AddMenuItem(g_hMenuChance, "3", "3%");
	AddMenuItem(g_hMenuChance, "1", "1%");
	SetMenuTitle(g_hMenuChance, "TMC: Activate Chance\nDo you want this trigger to always fire or based on random chance?");
	SetMenuExitBackButton(g_hMenuChance, true);

	g_hMenuLeave = CreateMenu(DataMenuHandler);
	AddMenuItem(g_hMenuLeave, "", "Yes");
	AddMenuItem(g_hMenuLeave, "", "No");
	SetMenuTitle(g_hMenuLeave, "TMC: Leave Box\nShould clients have to leave the trigger box before they can activate it again?");
	SetMenuExitBackButton(g_hMenuLeave, true);

	g_hMenuVMaxs = CreateMenu(VMaxsMenuHandler);
	AddMenuItem(g_hMenuVMaxs, "", "10 x 10 x 100");
	AddMenuItem(g_hMenuVMaxs, "", "25 x 25 x 100");
	AddMenuItem(g_hMenuVMaxs, "", "50 x 50 x 100");
	AddMenuItem(g_hMenuVMaxs, "", "100 x 100 x 100");
	AddMenuItem(g_hMenuVMaxs, "", "150 x 150 x 100");
	AddMenuItem(g_hMenuVMaxs, "", "200 x 200 x 100");
	AddMenuItem(g_hMenuVMaxs, "", "250 x 250 x 100");
	SetMenuTitle(g_hMenuVMaxs, "TMC: VMaxs");
	SetMenuExitBackButton(g_hMenuVMaxs, true);

	g_hMenuVMins = CreateMenu(VMinsMenuHandler);
	AddMenuItem(g_hMenuVMins, "", "-10 x -10 x 0");
	AddMenuItem(g_hMenuVMins, "", "-25 x -25 x 0");
	AddMenuItem(g_hMenuVMins, "", "-50 x -50 x 0");
	AddMenuItem(g_hMenuVMins, "", "-100 x -100 x 0");
	AddMenuItem(g_hMenuVMins, "", "-150 x -150 x 0");
	AddMenuItem(g_hMenuVMins, "", "-200 x -200 x 0");
	AddMenuItem(g_hMenuVMins, "", "-250 x -250 x 0");
	SetMenuTitle(g_hMenuVMins, "TMC: VMins");
	SetMenuExitBackButton(g_hMenuVMins, true);

	g_hMenuPos = CreateMenu(PosMenuHandler);
	AddMenuItem(g_hMenuPos, "", "X + 1.0");
	AddMenuItem(g_hMenuPos, "", "Y + 1.0");
	AddMenuItem(g_hMenuPos, "", "Z + 1.0");
	AddMenuItem(g_hMenuPos, "", "X - 1.0");
	AddMenuItem(g_hMenuPos, "", "Y - 1.0");
	AddMenuItem(g_hMenuPos, "", "Z - 1.0");
	AddMenuItem(g_hMenuPos, "", "SAVE");
	SetMenuTitle(g_hMenuPos, "TMC: Origin");
	SetMenuExitBackButton(g_hMenuPos, true);
}

public OnPluginEnd()
{
	ResetPlugin();
}

public OnMapStart()
{
	GetCvars();
	if( strcmp(g_sMaterialBeam, "") ) g_iLaserMaterial = PrecacheModel(g_sMaterialBeam);
	if( strcmp(g_sMaterialHalo, "") ) g_iHaloMaterial = PrecacheModel(g_sMaterialHalo);
	if( strcmp(g_sModelBox, "") ) PrecacheModel(g_sModelBox, true);
}

public OnMapEnd()
{
	ResetPlugin();
}

ResetPlugin()
{
	g_iSelectedTrig = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_bLoaded = false;

	for( new i = 0; i < MAXPLAYERS; i++ )
	{
		g_iMenuSelected[i] = 0;
		g_iMenuEdit[i] = 0;
		g_iInside[i] = 0;
	}

	for( new i = 0; i < MAX_ENTITIES; i++ )
	{
		g_bStopEnd[i] = false;
		g_iChance[i] = FIRE_CHANCE;
		g_iRefireCount[i] = REFIRE_COUNT;
		g_fRefireTime[i] = REFIRE_TIME;
		g_fDelayTime[i] = DELAY_TIME;

		if( IsValidEntRef(g_iTriggers[i]) ) AcceptEntityInput(g_iTriggers[i], "Kill");
		g_iTriggers[i] = 0;

		if( g_hTimerEnable[i] != INVALID_HANDLE ) CloseHandle(g_hTimerEnable[i]);
		g_hTimerEnable[i] = INVALID_HANDLE;
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
{
	GetCvars();
	IsAllowed();
}

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetCvars();
	IsAllowed();
}

GetCvars()
{
	GetColor(g_hCvarColor);
	GetConVarString(g_hCvarModel, g_sModelBox, sizeof(g_sModelBox));
	GetConVarString(g_hCvarBeam, g_sMaterialBeam, sizeof(g_sMaterialBeam));
	GetConVarString(g_hCvarHalo, g_sMaterialHalo, sizeof(g_sMaterialHalo));
	g_iCvarRefire = GetConVarInt(g_hCvarRefire);
}

GetColor(Handle:cvar)
{
	decl String:sTemp[12], String:sColors[3][4];
	GetConVarString(cvar, sTemp, sizeof(sTemp));
	ExplodeString(sTemp, " ", sColors, 3, 4);

	g_iColors[0] = StringToInt(sColors[0]);
	g_iColors[1] = StringToInt(sColors[1]);
	g_iColors[2] = StringToInt(sColors[2]);
	g_iColors[3] = 255;
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);

	if( g_bCvarAllow == false && bCvarAllow == true )
	{
		g_bCvarAllow = true;

		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);

		if( g_iEngine == ENGINE_TF2 )
		{
			HookEvent("teamplay_round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
			HookEvent("stats_resetround",			Event_RoundEnd,		EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_win",			Event_RoundEnd,		EventHookMode_PostNoCopy);
			HookEvent("teamplay_win_panel",			Event_RoundEnd,		EventHookMode_PostNoCopy);
		} else {
			HookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
			HookEvent("round_end",					Event_RoundEnd,		EventHookMode_PostNoCopy);
		}

		LoadDataConfig();
	}

	else if( g_bCvarAllow == true && bCvarAllow == false )
	{
		ResetPlugin();
		g_bCvarAllow = false;

		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);

		if( g_iEngine == ENGINE_TF2 )
		{
			UnhookEvent("teamplay_round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
			UnhookEvent("stats_resetround",			Event_RoundEnd,		EventHookMode_PostNoCopy);
			UnhookEvent("teamplay_round_win",		Event_RoundEnd,		EventHookMode_PostNoCopy);
			UnhookEvent("teamplay_win_panel",		Event_RoundEnd,		EventHookMode_PostNoCopy);
		} else {
			UnhookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
			UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetPlugin();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 ) CreateTimer(1.0, TimerLoad, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 ) CreateTimer(1.0, TimerLoad, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action:TimerLoad(Handle:timer)
{
	LoadDataConfig();
}



// ====================================================================================================
//					LOAD
// ====================================================================================================
LoadDataConfig()
{
	if( g_bLoaded == true ) return;
	g_bLoaded = true;

	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_DATA);
	if( !FileExists(sPath) ) return;

	new Handle:hFile = CreateKeyValues("triggers");
	KvSetEscapeSequences(hFile, true);
	FileToKeyValues(hFile, sPath);

	decl String:sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !KvJumpToKey(hFile, sMap) )
	{
		CloseHandle(hFile);
		return;
	}

	decl String:sTemp[16], Float:vPos[3], Float:vMax[3], Float:vMin[3];

	for( new i = 0; i < MAX_ENTITIES; i++ )
	{
		IntToString(i+1, sTemp, sizeof(sTemp));

		if( KvJumpToKey(hFile, sTemp, false) )
		{
			// TRIGGER BOXES
			KvGetVector(hFile, "vpos", vPos);
			if( vPos[0] != 0.0 && vPos[1] != 0.0 && vPos[2] != 0.0 )
			{
				KvGetVector(hFile, "vmin", vMin);
				KvGetVector(hFile, "vmax", vMax);
				g_iChance[i] = KvGetNum(hFile, "chance", FIRE_CHANCE);
				g_iRefireCount[i] = KvGetNum(hFile, "refire_count", REFIRE_COUNT);
				g_fRefireTime[i] = KvGetFloat(hFile, "refire_time", REFIRE_TIME);
				g_fDelayTime[i] = KvGetFloat(hFile, "delay_time", DELAY_TIME);
				KvGetString(hFile, "command", g_sCommand[i], CMD_MAX_LENGTH);
				g_iCmdData[i] = KvGetNum(hFile, "data", 1);
				if( g_iCmdData[i] & LEAVE_NO != LEAVE_NO && g_iCmdData[i] & LEAVE_YES != LEAVE_YES )
				{
					g_iCmdData[i] = g_iCmdData[i] | LEAVE_YES;
				}

				CreateTriggerMultiple(i, vPos, vMax, vMin, true);
			}

			KvGoBack(hFile);
		}
	}

	CloseHandle(hFile);
}



// ====================================================================================================
//					COMMAND - RELOAD
// ====================================================================================================
public Action:CmdTriggerReload(client, args)
{
	g_bCvarAllow = false;
	ResetPlugin();
	GetCvars();
	IsAllowed();
	if( client )	PrintToChat(client, "%sPlugin reset.", CHAT_TAG);
	else			PrintToConsole(client, "[Trigger Commands] Plugin reset.");
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMAND - FLAGS
// ====================================================================================================
public Action:CmdTriggerDupe(client, args)
{
	ShowMenuTrigList(client, 7);
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMAND - FLAGS
// ====================================================================================================
public Action:CmdTriggerFlags(client, args)
{
	decl String:sTemp[256];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	new flags = StringToInt(sTemp);

	GetFlags(flags, sTemp, sizeof(sTemp));

	if( client )	PrintToChat(client, sTemp);
	else			PrintToConsole(client, sTemp);

	return Plugin_Handled;
}

GetFlags(flags, String:sTemp[], size)
{
	Format(sTemp, size, "");
	if( flags & ALLOW_TEAM_1 ==		ALLOW_TEAM_1 )		StrCat(sTemp, size, "ALLOW_TEAM_1|");
	if( flags & ALLOW_TEAM_2 ==		ALLOW_TEAM_2 )		StrCat(sTemp, size, "ALLOW_TEAM_2|");
	if( flags & ALLOW_TEAMS ==		ALLOW_TEAMS )		StrCat(sTemp, size, "ALLOW_TEAMS|");
	if( flags & ALLOW_ALIVE ==		ALLOW_ALIVE )		StrCat(sTemp, size, "ALLOW_ALIVE|");
	if( flags & ALLOW_DEAD ==		ALLOW_DEAD )		StrCat(sTemp, size, "ALLOW_DEAD|");
	if( flags & ALLOW_SPEC ==		ALLOW_SPEC )		StrCat(sTemp, size, "ALLOW_SPEC|");
	if( flags & ALLOW_ALL ==		ALLOW_ALL )			StrCat(sTemp, size, "ALLOW_ALL|");
	if( flags & ALLOW_BOTS ==		ALLOW_BOTS )		StrCat(sTemp, size, "ALLOW_BOTS|");
	if( flags & ALLOW_REAL ==		ALLOW_REAL )		StrCat(sTemp, size, "ALLOW_REAL|");
	if( flags & EXEC_CLIENT ==		EXEC_CLIENT )		StrCat(sTemp, size, "EXEC_CLIENT|");
	if( flags & EXEC_ALL ==			EXEC_ALL )			StrCat(sTemp, size, "EXEC_ALL|");
	if( flags & EXEC_TEAM_1 ==		EXEC_TEAM_1 )		StrCat(sTemp, size, "EXEC_TEAM_1|");
	if( flags & EXEC_TEAM_2 ==		EXEC_TEAM_2 )		StrCat(sTemp, size, "EXEC_TEAM_2|");
	if( flags & EXEC_TEAMS ==		EXEC_TEAMS )		StrCat(sTemp, size, "EXEC_TEAMS|");
	if( flags & EXEC_ALIVE ==		EXEC_ALIVE )		StrCat(sTemp, size, "EXEC_ALIVE|");
	if( flags & EXEC_DEAD ==		EXEC_DEAD )			StrCat(sTemp, size, "EXEC_DEAD|");
	if( flags & EXEC_BOTS ==		EXEC_BOTS )			StrCat(sTemp, size, "EXEC_BOTS|");
	if( flags & EXEC_REAL ==		EXEC_REAL )			StrCat(sTemp, size, "EXEC_REAL|");
	if( flags & LEAVE_NO ==			LEAVE_NO )			StrCat(sTemp, size, "LEAVE_NO|");
	if( flags & LEAVE_YES ==		LEAVE_YES )			StrCat(sTemp, size, "LEAVE_YES|");
	if( flags & COMMAND_SERVER ==	COMMAND_SERVER )	StrCat(sTemp, size, "COMMAND_SERVER|");
	if( flags & COMMAND_CLIENT ==	COMMAND_CLIENT )	StrCat(sTemp, size, "COMMAND_CLIENT|");
	if( flags & COMMAND_FAKE ==		COMMAND_FAKE )		StrCat(sTemp, size, "COMMAND_FAKE|");
	if( flags & FLAGS_ANY ==		FLAGS_ANY )			StrCat(sTemp, size, "FLAGS_ANY|");
	if( flags & FLAGS_ADMIN ==		FLAGS_ADMIN )		StrCat(sTemp, size, "FLAGS_ADMIN|");
	if( flags & FLAGS_CHEAT ==		FLAGS_CHEAT )		StrCat(sTemp, size, "FLAGS_CHEAT|");
	if( flags & FLAGS_ADMINCHEAT ==	FLAGS_ADMINCHEAT )	StrCat(sTemp, size, "FLAGS_ADMINCHEAT|");

	new len = strlen(sTemp);
	if( len > 1 ) sTemp[len-1] = '\x0';
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
public Action:CmdTriggerAdd(client, args)
{
	if( client == 0 )
	{
		PrintToConsole(client, "[Trigger Commands] This command can only be used in-game on a dedicated server.");
		return Plugin_Handled;
	}

	decl String:sCmd[256];
	GetCmdArgString(sCmd, sizeof(sCmd));

	StripQuotes(sCmd);

	CreateTrigger(client, sCmd);

	g_iMenuEdit[client] = 0;

	SetMenuExitBackButton(g_hMenuType, false);
	DisplayMenu(g_hMenuType, client, MENU_TIME_FOREVER);

	PrintToChat(client, "%sIf you exit the menu, the trigger you are adding will be deleted.", CHAT_TAG);
	return Plugin_Handled;
}

public Action:CmdTriggerMenu(client, args)
{
	if( client == 0 )
	{
		PrintToConsole(client, "[Trigger Commands] This command can only be used in-game on a dedicated server.");
		return Plugin_Handled;
	}

	ShowMainMenu(client);
	return Plugin_Handled;
}



// ====================================================================================================
//					MENUS
// ====================================================================================================
ShowMainMenu(client)
{
	g_iMenuEdit[client] = 0;

	new Handle:hMenu = CreateMenu(TrigMenuHandler);

	if( g_hTimerBeam == INVALID_HANDLE )	AddMenuItem(hMenu, "1", "Show");
	else									AddMenuItem(hMenu, "1", "Hide");
	AddMenuItem(hMenu, "2", "Edit Trigger");
	AddMenuItem(hMenu, "3", "Set VMaxs");
	AddMenuItem(hMenu, "4", "Set VMins");
	AddMenuItem(hMenu, "5", "Set Origin");
	AddMenuItem(hMenu, "6", "Go To Trigger");
	AddMenuItem(hMenu, "7", "Delete");
	SetMenuTitle(hMenu, "TMC - Trigger Box:");
	SetMenuExitButton(hMenu, true);

	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public TrigMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
	{
		CloseHandle(menu);
	}
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	ShowMainMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		if( index == 0 )
		{
			if( g_hTimerBeam != INVALID_HANDLE )
			{
				CloseHandle(g_hTimerBeam);
				g_hTimerBeam = INVALID_HANDLE;
				g_iSelectedTrig = 0;
			}
			ShowMenuTrigList(client, index);
		}
		else
		{
			ShowMenuTrigList(client, index);
		}
	}
}

ShowMenuTrigList(client, index)
{
	g_iMenuSelected[client] = index;

	new count;
	new Handle:hMenu = CreateMenu(TrigListMenuHandler);
	decl String:sIndex[8], String:sTemp[64];

	g_iMenuEdit[client] = 0;

	for( new i = 0; i < MAX_ENTITIES; i++ )
	{
		if( IsValidEntRef(g_iTriggers[i]) == true )
		{
			count++;
			Format(sTemp, sizeof(sTemp), "Trigger %d (%s)", i+1, g_sCommand[i]);

			IntToString(i, sIndex, sizeof(sIndex));
			AddMenuItem(hMenu, sIndex, sTemp);
		}
	}

	if( count == 0 )
	{
		PrintToChat(client, "%sError: No saved Triggers were found. Create a new one using the command sm_trigger_add.", CHAT_TAG);
		CloseHandle(hMenu);
		ShowMainMenu(client);
		return;
	}

	if( index == 0 )		SetMenuTitle(hMenu, "TMC: Trigger Box - Show:");
	else if( index == 1 )	SetMenuTitle(hMenu, "TMC: Trigger Box - Edit Options:");
	else if( index == 2 )	SetMenuTitle(hMenu, "TMC: Trigger Box - Maxs:");
	else if( index == 3 )	SetMenuTitle(hMenu, "TMC: Trigger Box - Mins:");
	else if( index == 4 )	SetMenuTitle(hMenu, "TMC: Trigger Box - Origin:");
	else if( index == 5 )	SetMenuTitle(hMenu, "TMC: Trigger Box - Go To:");
	else if( index == 6 )	SetMenuTitle(hMenu, "TMC: Trigger Box - Delete:");
	else if( index == 7 )	SetMenuTitle(hMenu, "TMC: Trigger Box - Duplicate:");

	SetMenuExitBackButton(hMenu, true);
	DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
}

public TrigListMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_End )
	{
		CloseHandle(menu);
	}
	else if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	ShowMainMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		new type = g_iMenuSelected[client];
		decl String:sTemp[4];
		GetMenuItem(menu, index, sTemp, sizeof(sTemp));
		index = StringToInt(sTemp);

		if( type == 0 )
		{
			g_iSelectedTrig = g_iTriggers[index];

			if( IsValidEntRef(g_iSelectedTrig) )	g_hTimerBeam = CreateTimer(BEAM_TIME, TimerBeam, _, TIMER_REPEAT);
			else									g_iSelectedTrig = 0;

			ShowMainMenu(client);
		}
		else if( type == 1 )
		{
			g_iMenuSelected[client] = index;
			DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);

			new flags = g_iCmdData[index];
			decl String:sFlags[256];
			GetFlags(flags, sFlags, sizeof(sFlags));
			PrintToChat(client, "%sCurrent flags: (%d) %s", CHAT_TAG, flags, sFlags);
		}
		else if( type == 2 )
		{
			g_iMenuSelected[client] = index;
			DisplayMenu(g_hMenuVMaxs, client, MENU_TIME_FOREVER);
		}
		else if( type == 3 )
		{
			g_iMenuSelected[client] = index;
			DisplayMenu(g_hMenuVMins, client, MENU_TIME_FOREVER);
		}
		else if( type == 4 )
		{
			g_iMenuSelected[client] = index;
			DisplayMenu(g_hMenuPos, client, MENU_TIME_FOREVER);
		}
		else if( type == 5 )
		{
			new trigger = g_iTriggers[index];
			if( IsValidEntRef(trigger) )
			{
				new Float:vPos[3];
				GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", vPos);

				if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 )
				{
					PrintToChat(client, "%sCannot teleport you, the Target Zone is missing.", CHAT_TAG);
				}
				else
				{
					vPos[2] += 10.0;
					TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
			ShowMainMenu(client);
		}
		else if( type == 6 )
		{
			DeleteTrigger(client, index+1);
			ShowMainMenu(client);
		}
		else if( type == 7 )
		{
			DupeTrigger(client, index);
			ShowMainMenu(client);
		}
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - EDIT OPTIONS
// ====================================================================================================
public EditMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	ShowMainMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		g_iMenuEdit[client] = index + 1;

		if( index == 0 )
		{
			SetMenuExitButton(g_hMenuType, true);
			SetMenuExitBackButton(g_hMenuType, true);
			DisplayMenu(g_hMenuType, client, MENU_TIME_FOREVER);
		}
		else if( index == 1 )
		{
			SetMenuExitButton(g_hMenuAuth, true);
			SetMenuExitBackButton(g_hMenuAuth, true);
			DisplayMenu(g_hMenuAuth, client, MENU_TIME_FOREVER);
		}
		else if( index == 2 )
		{
			SetMenuExitButton(g_hMenuTeam, true);
			SetMenuExitBackButton(g_hMenuTeam, true);
			DisplayMenu(g_hMenuTeam, client, MENU_TIME_FOREVER);
		}
		else if( index == 3 )
		{
			SetMenuExitButton(g_hMenuExec, true);
			SetMenuExitBackButton(g_hMenuExec, true);
			DisplayMenu(g_hMenuExec, client, MENU_TIME_FOREVER);
		}
		else if( index == 4 )
		{
			SetMenuExitBackButton(g_hMenuRefire, true);
			DisplayMenu(g_hMenuRefire, client, MENU_TIME_FOREVER);
		}
		else if( index == 5 )
		{
			SetMenuExitBackButton(g_hMenuTime, true);
			DisplayMenu(g_hMenuTime, client, MENU_TIME_FOREVER);
		}
		else if( index == 6 )
		{
			SetMenuExitBackButton(g_hMenuDelay, true);
			DisplayMenu(g_hMenuDelay, client, MENU_TIME_FOREVER);
		}
		else if( index == 7 )
		{
			SetMenuExitBackButton(g_hMenuChance, true);
			DisplayMenu(g_hMenuChance, client, MENU_TIME_FOREVER);
		}
		else if( index == 8 )
		{
			SetMenuExitBackButton(g_hMenuLeave, true);
			DisplayMenu(g_hMenuLeave, client, MENU_TIME_FOREVER);
		}
	}
}



// ====================================================================================================
//					MENU - DATA HANDLER
// ====================================================================================================
public DataMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
		else if( index == MenuCancel_Exit && g_iMenuEdit[client] == 0 )	KillTriggerCreation(client);
	}
	else if( action == MenuAction_Select )
	{
		new cfgindex = g_iMenuSelected[client];

		new Handle:hFile = ConfigOpen();

		if( hFile != INVALID_HANDLE )
		{
			decl String:sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp) == true )
			{
				IntToString(cfgindex+1, sTemp, sizeof(sTemp));

				if( KvJumpToKey(hFile, sTemp) == true )
				{
					new data = KvGetNum(hFile, "data", 0);
					new bool:show = false;

					if( menu == g_hMenuType )
					{
						if( g_iMenuEdit[client] )
						{
							data &= ~COMMAND_SERVER;
							data &= ~COMMAND_CLIENT;
							data &= ~COMMAND_FAKE;
						} else {
							data = 0; // Setting up trigger, clear data for first time menu.
						}

						switch (index)
						{
							case 0: data |= COMMAND_SERVER;
							case 1: data |= COMMAND_CLIENT;
							case 2: data |= COMMAND_FAKE;
						}

						if( g_iMenuEdit[client] == 0 )
						{
							SetMenuExitBackButton(g_hMenuAuth, false);
							DisplayMenu(g_hMenuAuth, client, MENU_TIME_FOREVER);
						}
					}
					else if( menu == g_hMenuAuth )
					{
						if( g_iMenuEdit[client] )
						{
							data &= ~FLAGS_ANY;
							data &= ~FLAGS_CHEAT;
							data &= ~FLAGS_ADMIN;
							data &= ~FLAGS_ADMINCHEAT;
						}

						switch (index)
						{
							case 0: data |= FLAGS_ANY;
							case 1: data |= FLAGS_CHEAT;
							case 2: data |= FLAGS_ADMIN;
							case 3: data |= FLAGS_ADMINCHEAT;
						}

						if( g_iMenuEdit[client] == 0 )
						{
							SetMenuExitBackButton(g_hMenuTeam, false);
							DisplayMenu(g_hMenuTeam, client, MENU_TIME_FOREVER);
						} else {
							SetMenuExitBackButton(g_hMenuRefire, false);
							DisplayMenu(g_hMenuRefire, client, MENU_TIME_FOREVER);
						}
					}
					else if( menu == g_hMenuTeam )
					{
						if( g_iMenuEdit[client] )
						{
							data &= ~ALLOW_ALIVE;
							data &= ~ALLOW_TEAM_1;
							data &= ~ALLOW_TEAM_2;
							data &= ~ALLOW_TEAMS;
							data &= ~ALLOW_DEAD;
							data &= ~ALLOW_SPEC;
							data &= ~ALLOW_ALL;
						}

						switch (index)
						{
							case 0: data |= ALLOW_ALIVE;
							case 1: data |= ALLOW_TEAM_1;
							case 2: data |= ALLOW_TEAM_2;
							case 3: data |= ALLOW_TEAMS;
							case 4: data |= ALLOW_DEAD;
							case 5: data |= ALLOW_SPEC;
							case 6: data |= ALLOW_ALL;
						}

						show = true;
						SetMenuExitBackButton(g_hMenuBots, false);
						DisplayMenu(g_hMenuBots, client, MENU_TIME_FOREVER);
					}
					else if( menu == g_hMenuBots )
					{
						if( g_iMenuEdit[client] )
						{
							data &= ~ALLOW_REAL;
							data &= ~ALLOW_BOTS;
						}

						switch (index)
						{
							case 1: data |= ALLOW_REAL;
							case 2: data |= ALLOW_BOTS;
						}

						if( data & COMMAND_SERVER != COMMAND_SERVER )
						{
							if( g_iMenuEdit[client] == 0 )
							{
								SetMenuExitBackButton(g_hMenuExec, false);
								DisplayMenu(g_hMenuExec, client, MENU_TIME_FOREVER);
							}
						}
						else
						{
							if( g_iMenuEdit[client] == 0 )
							{
								SetMenuExitBackButton(g_hMenuRefire, false);
								DisplayMenu(g_hMenuRefire, client, MENU_TIME_FOREVER);
							}
						}
					}
					else if( menu == g_hMenuExec )
					{
						if( g_iMenuEdit[client] )
						{
							data &= ~EXEC_CLIENT;
							data &= ~EXEC_ALL;
							data &= ~EXEC_TEAM_1;
							data &= ~EXEC_TEAM_2;
							data &= ~EXEC_TEAMS;
							data &= ~EXEC_ALIVE;
							data &= ~EXEC_DEAD;
						}

						switch (index)
						{
							case 0: data |= EXEC_CLIENT;
							case 1: data |= EXEC_ALL;
							case 2: data |= EXEC_TEAM_1;
							case 3: data |= EXEC_TEAM_2;
							case 4: data |= EXEC_TEAMS;
							case 5: data |= EXEC_ALIVE;
							case 6: data |= EXEC_DEAD;
						}

						if( !(data & EXEC_CLIENT == EXEC_CLIENT) )
						{
							show = true;
							SetMenuExitBackButton(g_hMenuBExec, false);
							DisplayMenu(g_hMenuBExec, client, MENU_TIME_FOREVER);
						}
						else
						{
							if( g_iMenuEdit[client] == 0 )
							{
								SetMenuExitBackButton(g_hMenuRefire, false);
								DisplayMenu(g_hMenuRefire, client, MENU_TIME_FOREVER);
							}
						}
					}
					else if( menu == g_hMenuBExec )
					{
						if( g_iMenuEdit[client] )
						{
							data &= ~EXEC_REAL;
							data &= ~EXEC_BOTS;
						}

						switch (index)
						{
							case 0: data |= EXEC_REAL;
							case 1: data |= EXEC_BOTS;
						}

						if( g_iMenuEdit[client] == 0 )
						{
							SetMenuExitBackButton(g_hMenuRefire, false);
							DisplayMenu(g_hMenuRefire, client, MENU_TIME_FOREVER);
						}
					}
					else if( menu == g_hMenuLeave )
					{
						if( g_iMenuEdit[client] )
						{
							data &= ~LEAVE_YES;
							data &= ~LEAVE_NO;
						}

						switch (index)
						{
							case 0: data |= LEAVE_YES;
							case 1: data |= LEAVE_NO;
						}


						if( g_iMenuEdit[client] == 0 )
						{
							PrintToChat(client, "%sAll done, your trigger has been setup!", CHAT_TAG);

							new entity = g_iTriggers[cfgindex];
							if( IsValidEntRef(entity) )	AcceptEntityInput(entity, "Enable");

							ShowMainMenu(client);

							if( g_hTimerBeam != INVALID_HANDLE )
							{
								CloseHandle(g_hTimerBeam);
								g_hTimerBeam = INVALID_HANDLE;
								g_iSelectedTrig = 0;
							}
						}
					}

					g_iCmdData[cfgindex] = data;
					KvSetNum(hFile, "data", data);
					ConfigSave(hFile);

					if( g_iMenuEdit[client] )
					{
						if( !show )
							DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
						PrintToChat(client, "%sTrigger options modified and saved!", CHAT_TAG);

						decl String:sFlags[256];
						GetFlags(data, sFlags, sizeof(sFlags));
						PrintToChat(client, "%sCurrent flags: (%d) %s", CHAT_TAG, data, sFlags);
					}
				}
			}

			CloseHandle(hFile);
		}
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - REFIRE COUNT
// ====================================================================================================
public RefireMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
		else if( index == MenuCancel_Exit && g_iMenuEdit[client] == 0 )	KillTriggerCreation(client);
	}
	else if( action == MenuAction_Select )
	{
		new cfgindex = g_iMenuSelected[client];

		new value;
		if( index == 1 )		value = g_iRefireCount[cfgindex] - 1;
		else if( index == 2 )	value = g_iRefireCount[cfgindex] + 1;
		else
		{
			decl String:sMenu[8];
			GetMenuItem(menu, index, sMenu, sizeof(sMenu));
			value = StringToInt(sMenu);
		}
		if( value < 0 )			value = 0;

		if( g_iMenuEdit[client] == 0 && (index == 1 || index == 2) )
		{
			PrintToChat(client, "%sCannot select + or - when setting up, please choose a default value.", CHAT_TAG);
			DisplayMenu(g_hMenuRefire, client, MENU_TIME_FOREVER);
			return;
		}


		new Handle:hFile = ConfigOpen();

		if( hFile != INVALID_HANDLE )
		{
			decl String:sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp) == true )
			{
				IntToString(cfgindex+1, sTemp, sizeof(sTemp));

				if( KvJumpToKey(hFile, sTemp) == true )
				{
					new trigger = g_iTriggers[cfgindex];
					g_iRefireCount[cfgindex] = value;
					KvSetNum(hFile, "refire_count", value);
					PrintToChat(client, "%sSet trigger box '\x03%d\x05' refire count to \x03%d", CHAT_TAG, cfgindex+1, value);

					if( g_iMenuEdit[client] != 0 && IsValidEntRef(trigger) && GetEntProp(trigger, Prop_Data, "m_iHammerID") <= value )
					{
						AcceptEntityInput(trigger, "Enable");
						g_bStopEnd[cfgindex] = false;
					}

					ConfigSave(hFile);
				}
			}

			CloseHandle(hFile);
		}

		if( g_iMenuEdit[client] == 0 )
		{
			if( value == 1 )
			{
				SetMenuExitBackButton(g_hMenuDelay, false);
				DisplayMenu(g_hMenuDelay, client, MENU_TIME_FOREVER);
			}
			else
			{
				SetMenuExitBackButton(g_hMenuTime, false);
				DisplayMenu(g_hMenuTime, client, MENU_TIME_FOREVER);
			}
		}
		else if( index == 1 || index == 2 ) DisplayMenu(g_hMenuRefire, client, MENU_TIME_FOREVER);
		else DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - REFIRE TIME
// ====================================================================================================
public TimeMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
		else if( index == MenuCancel_Exit && g_iMenuEdit[client] == 0 )	KillTriggerCreation(client);
	}
	else if( action == MenuAction_Select )
	{
		new cfgindex = g_iMenuSelected[client];

		new Float:value;
		if( index == 1 )		value = g_fRefireTime[cfgindex] - 1.0;
		else if( index == 2 )	value = g_fRefireTime[cfgindex] + 1.0;
		else
		{
			decl String:sMenu[8];
			GetMenuItem(menu, index, sMenu, sizeof(sMenu));
			value = StringToFloat(sMenu);
		}
		if( value < 0.5 )		value = 0.5;

		if( g_iMenuEdit[client] == 0 && (index == 1 || index == 2) )
		{
			PrintToChat(client, "%sCannot select + or - when setting up, please choose a default value.", CHAT_TAG);
			DisplayMenu(g_hMenuTime, client, MENU_TIME_FOREVER);
			return;
		}


		new Handle:hFile = ConfigOpen();

		if( hFile != INVALID_HANDLE )
		{
			decl String:sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp) == true )
			{
				IntToString(cfgindex+1, sTemp, sizeof(sTemp));

				if( KvJumpToKey(hFile, sTemp) == true )
				{
					g_fRefireTime[cfgindex] = value;
					KvSetFloat(hFile, "refire_time", value);
					PrintToChat(client, "%sSet trigger box '\x03%d\x05' refire time to \x03%0.1f", CHAT_TAG, cfgindex+1, value);

					ConfigSave(hFile);
				}
			}

			CloseHandle(hFile);
		}

		if( g_iMenuEdit[client] == 0 )
		{
			SetMenuExitBackButton(g_hMenuDelay, false);
			DisplayMenu(g_hMenuDelay, client, MENU_TIME_FOREVER);
		}
		else if( index == 1 || index == 2 ) DisplayMenu(g_hMenuTime, client, MENU_TIME_FOREVER);
		else DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - REFIRE TIME
// ====================================================================================================
public DelayMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
		else if( index == MenuCancel_Exit && g_iMenuEdit[client] == 0 )	KillTriggerCreation(client);
	}
	else if( action == MenuAction_Select )
	{
		new cfgindex = g_iMenuSelected[client];

		new Float:value;
		if( index == 1 )		value = g_fDelayTime[cfgindex] - 1.0;
		else if( index == 2 )	value = g_fDelayTime[cfgindex] + 1.0;
		else
		{
			decl String:sMenu[8];
			GetMenuItem(menu, index, sMenu, sizeof(sMenu));
			value = StringToFloat(sMenu);
		}
		if( value < 0.0 )		value = 0.0;

		if( g_iMenuEdit[client] == 0 && (index == 1 || index == 2) )
		{
			PrintToChat(client, "%sCannot select + or - when setting up, please choose a default value.", CHAT_TAG);
			DisplayMenu(g_hMenuDelay, client, MENU_TIME_FOREVER);
			return;
		}


		new Handle:hFile = ConfigOpen();

		if( hFile != INVALID_HANDLE )
		{
			decl String:sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp) == true )
			{
				IntToString(cfgindex+1, sTemp, sizeof(sTemp));

				if( KvJumpToKey(hFile, sTemp) == true )
				{
					if( value == 0.0 )
					{
						g_fDelayTime[cfgindex] = value;
						KvSetFloat(hFile, "delay_time", value);
						PrintToChat(client, "%sSet trigger box '\x03%d\x05' delay time to no delay. Executes the command without delay.", CHAT_TAG, cfgindex+1);
					}
					else
					{
						g_fDelayTime[cfgindex] = value;
						KvSetFloat(hFile, "delay_time", value);
						PrintToChat(client, "%sSet trigger box '\x03%d\x05' delay time to \x03%0.1f", CHAT_TAG, cfgindex+1, value);

						ConfigSave(hFile);
					}
				}
			}

			CloseHandle(hFile);
		}

		if( g_iMenuEdit[client] == 0 )
		{
			SetMenuExitBackButton(g_hMenuChance, false);
			DisplayMenu(g_hMenuChance, client, MENU_TIME_FOREVER);
		}
		else if( index == 1 || index == 2 ) DisplayMenu(g_hMenuDelay, client, MENU_TIME_FOREVER);
		else DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - FIRE CHANCE
// ====================================================================================================
public ChanceMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
		else if( index == MenuCancel_Exit && g_iMenuEdit[client] == 0 )	KillTriggerCreation(client);
	}
	else if( action == MenuAction_Select )
	{
		new cfgindex = g_iMenuSelected[client];

		new value;
		decl String:sMenu[8];
		GetMenuItem(menu, index, sMenu, sizeof(sMenu));
		value = StringToInt(sMenu);


		new Handle:hFile = ConfigOpen();

		if( hFile != INVALID_HANDLE )
		{
			decl String:sTemp[64];
			GetCurrentMap(sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp) == true )
			{
				IntToString(cfgindex+1, sTemp, sizeof(sTemp));

				if( KvJumpToKey(hFile, sTemp) == true )
				{
					g_iChance[cfgindex] = value;
					KvSetNum(hFile, "chance", value);
					PrintToChat(client, "%sSet trigger box '\x03%d\x05' chance to \x03%d\%", CHAT_TAG, cfgindex+1, value);
					ConfigSave(hFile);
				}
			}

			CloseHandle(hFile);
		}

		if( g_iMenuEdit[client] == 0 )
		{
			if( g_iRefireCount[cfgindex] == 1 )
			{
				PrintToChat(client, "%sAll done, your trigger has been setup!", CHAT_TAG);

				new entity = g_iTriggers[cfgindex];
				if( IsValidEntRef(entity) )	AcceptEntityInput(entity, "Enable");

				ShowMainMenu(client);

				if( g_hTimerBeam != INVALID_HANDLE )
				{
					CloseHandle(g_hTimerBeam);
					g_hTimerBeam = INVALID_HANDLE;
					g_iSelectedTrig = 0;
				}
			}
			else
			{
				SetMenuExitBackButton(g_hMenuLeave, false);
				DisplayMenu(g_hMenuLeave, client, MENU_TIME_FOREVER);
			}
		}
		else DisplayMenu(g_hMenuEdit, client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					MENU - TRIGGER BOX - VMINS/VMAXS/VPOS - CALLBACKS
// ====================================================================================================
public VMaxsMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	ShowMainMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		decl Float:vVec[3];

		if( index == 0 )		vVec = Float:{ 10.0, 10.0, 100.0 };
		else if( index == 1 )	vVec = Float:{ 25.0, 25.0, 100.0 };
		else if( index == 2 )	vVec = Float:{ 50.0, 50.0, 100.0 };
		else if( index == 3 )	vVec = Float:{ 100.0, 100.0, 100.0 };
		else if( index == 4 )	vVec = Float:{ 150.0, 150.0, 100.0 };
		else if( index == 5 )	vVec = Float:{ 200.0, 200.0, 100.0 };
		else if( index == 6 )	vVec = Float:{ 300.0, 300.0, 100.0 };

		new cfgindex = g_iMenuSelected[client];
		new trigger = g_iTriggers[cfgindex];

		SaveTrigger(INVALID_HANDLE, client, cfgindex + 1, "vmax", vVec);

		if( IsValidEntRef(trigger) )
		{
			SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", vVec);

			g_iSelectedTrig = trigger;
			if( g_hTimerBeam == INVALID_HANDLE )	g_hTimerBeam = CreateTimer(BEAM_TIME, TimerBeam, _, TIMER_REPEAT);
		}

		DisplayMenu(g_hMenuVMaxs, client, MENU_TIME_FOREVER);
	}
}

public VMinsMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	ShowMainMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		decl Float:vVec[3];

		if( index == 0 )		vVec = Float:{ -10.0, -10.0, -100.0 };
		else if( index == 1 )	vVec = Float:{ -25.0, -25.0, -100.0 };
		else if( index == 2 )	vVec = Float:{ -50.0, -50.0, -100.0 };
		else if( index == 3 )	vVec = Float:{ -100.0, -100.0, -100.0 };
		else if( index == 4 )	vVec = Float:{ -150.0, -150.0, -100.0 };
		else if( index == 5 )	vVec = Float:{ -200.0, -200.0, -100.0 };
		else if( index == 6 )	vVec = Float:{ -300.0, -300.0, -100.0 };

		new cfgindex = g_iMenuSelected[client];
		new trigger = g_iTriggers[cfgindex];

		SaveTrigger(INVALID_HANDLE, client, cfgindex + 1, "vmin", vVec);

		if( IsValidEntRef(trigger) )
		{
			SetEntPropVector(trigger, Prop_Send, "m_vecMins", vVec);

			g_iSelectedTrig = trigger;
			if( g_hTimerBeam == INVALID_HANDLE )	g_hTimerBeam = CreateTimer(BEAM_TIME, TimerBeam, _, TIMER_REPEAT);
		}

		DisplayMenu(g_hMenuVMins, client, MENU_TIME_FOREVER);
	}
}

public PosMenuHandler(Handle:menu, MenuAction:action, client, index)
{
	if( action == MenuAction_Cancel )
	{
		if( index == MenuCancel_ExitBack )	ShowMainMenu(client);
	}
	else if( action == MenuAction_Select )
	{
		new cfgindex = g_iMenuSelected[client];
		new trigger = g_iTriggers[cfgindex];

		if( IsValidEntRef(trigger) )
		{
			decl Float:vPos[3];
			GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", vPos);

			if( index == 0 )			vPos[0] += 1.0;
			else if( index == 1 )		vPos[1] += 1.0;
			else if( index == 2 )		vPos[2] += 1.0;
			else if( index == 3 )		vPos[0] -= 1.0;
			else if( index == 4 )		vPos[1] -= 1.0;
			else if( index == 5 )		vPos[2] -= 1.0;

			if( index != 6 )	TeleportEntity(trigger, vPos, NULL_VECTOR, NULL_VECTOR);
			else				SaveTrigger(INVALID_HANDLE, client, cfgindex + 1, "vpos", vPos);

			g_iSelectedTrig = trigger;
			if( g_hTimerBeam == INVALID_HANDLE )	g_hTimerBeam = CreateTimer(BEAM_TIME, TimerBeam, _, TIMER_REPEAT);
		} else {
			PrintToChat(client, "%sError: Trigger (%d) not found.", cfgindex);
		}

		DisplayMenu(g_hMenuPos, client, MENU_TIME_FOREVER);
	}
}



// ====================================================================================================
//					TRIGGER BOX - SAVE / DELETE / DUPE
// ====================================================================================================
SaveTrigger(Handle:hOpen, client, index, String:sKey[], Float:vVec[3])
{
	new Handle:hFile;
	if( hOpen == INVALID_HANDLE ) hFile = ConfigOpen();
	else hFile = hOpen;

	if( hFile != INVALID_HANDLE )
	{
		decl String:sTemp[64];
		GetCurrentMap(sTemp, sizeof(sTemp));
		if( KvJumpToKey(hFile, sTemp, true) )
		{
			IntToString(index, sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp, true) )
			{
				KvSetVector(hFile, sKey, vVec);

				ConfigSave(hFile);

				if( client )	PrintToChat(client, "%s\x01(\x05%d\x01) - Saved trigger '%s'.", CHAT_TAG, index, sKey);
			}
			else if( client )
			{
				PrintToChat(client, "%s\x01(\x05%d\x01) - Failed to save trigger(A) '%s'.", CHAT_TAG, index, sKey);
			}
		}
		else if( client )
		{
			PrintToChat(client, "%s\x01(\x05%d\x01) - Failed to save trigger(B) '%s'.", CHAT_TAG, index, sKey);
		}

		if( hOpen == INVALID_HANDLE ) CloseHandle(hFile);
	}

}

SaveData(Handle:hOpen, client, index, String:sKey[], String:sVal[])
{
	new Handle:hFile;
	if( hOpen == INVALID_HANDLE ) hFile = ConfigOpen();
	else hFile = hOpen;

	if( hFile != INVALID_HANDLE )
	{
		decl String:sTemp[64];
		GetCurrentMap(sTemp, sizeof(sTemp));
		if( KvJumpToKey(hFile, sTemp, true) )
		{
			IntToString(index, sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp, true) )
			{
				KvSetString(hFile, sKey, sVal);

				ConfigSave(hFile);

				if( client )	PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Saved trigger '%s'.", CHAT_TAG, index, MAX_ENTITIES, sKey);
			}
			else if( client )
			{
				PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Failed to save trigger(C) '%s'.", CHAT_TAG, index, MAX_ENTITIES, sKey);
			}
		}
		else if( client )
		{
			PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Failed to save trigger(D) '%s'.", CHAT_TAG, index, MAX_ENTITIES, sKey);
		}

		if( hOpen == INVALID_HANDLE ) CloseHandle(hFile);
	}
}

DeleteTrigger(client, cfgindex)
{
	new Handle:hFile = ConfigOpen();

	if( hFile != INVALID_HANDLE )
	{
		decl String:sMap[64];
		GetCurrentMap(sMap, sizeof(sMap));

		if( KvJumpToKey(hFile, sMap) )
		{
			decl String:sTemp[16];
			IntToString(cfgindex, sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp) )
			{
				if( IsValidEntRef(g_iTriggers[cfgindex-1]) )	AcceptEntityInput(g_iTriggers[cfgindex-1], "Kill");
				g_iTriggers[cfgindex-1] = 0;

				KvDeleteKey(hFile, "vpos");
				KvDeleteKey(hFile, "vmax");
				KvDeleteKey(hFile, "vmin");
				KvDeleteKey(hFile, "data");
				KvDeleteKey(hFile, "command");
				KvDeleteKey(hFile, "chance");
				KvDeleteKey(hFile, "refire_count");
				KvDeleteKey(hFile, "refire_time");
				KvDeleteKey(hFile, "delay_time");

				decl Float:vPos[3];
				KvGetVector(hFile, "pos", vPos);

				KvGoBack(hFile);

				if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 )
				{
					for( new i = cfgindex; i < MAX_ENTITIES; i++ )
					{
						g_iTriggers[i-1] = g_iTriggers[i];
						g_iTriggers[i] = 0;

						g_bStopEnd[i-1] = g_bStopEnd[i];
						g_bStopEnd[i] = false;

						g_iRefireCount[i-1] = g_iRefireCount[i];
						g_iRefireCount[i] = REFIRE_COUNT;

						g_fRefireTime[i-1] = g_fRefireTime[i];
						g_fRefireTime[i] = REFIRE_TIME;

						g_fDelayTime[i-1] = g_fDelayTime[i];
						g_fDelayTime[i] = DELAY_TIME;

						g_iChance[i-1] = g_iChance[i];
						g_iChance[i] = FIRE_CHANCE;

						g_iCmdData[i-1] = g_iCmdData[i];
						g_iCmdData[i] = 0;

						g_hTimerEnable[i-1] = g_hTimerEnable[i];
						g_hTimerEnable[i] = INVALID_HANDLE;

						strcopy(g_sCommand[i-1], CMD_MAX_LENGTH, g_sCommand[i]);
						strcopy(g_sCommand[i], CMD_MAX_LENGTH, "");


						IntToString(i+1, sTemp, sizeof(sTemp));

						if( KvJumpToKey(hFile, sTemp) )
						{
							IntToString(i, sTemp, sizeof(sTemp));
							KvSetSectionName(hFile, sTemp);
							KvGoBack(hFile);
						}
					}
				}

				ConfigSave(hFile);

				PrintToChat(client, "%sTrigger removed from config.", CHAT_TAG);
			}
		}

		CloseHandle(hFile);
	}
}

KillTriggerCreation(client)
{
	new cfgindex = g_iMenuSelected[client] + 1;
	DeleteTrigger(client, cfgindex);
	PrintToChat(client, "%sYou exited the menu, the trigger '\x03%d\x05' you were creating has been deleted from the config.", CHAT_TAG, cfgindex);
}


DupeTrigger(client, cfgindex)
{

	new index = -1;

	for( new i = 0; i < MAX_ENTITIES; i++ )
	{
		if( IsValidEntRef(g_iTriggers[i]) == false )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sError: Cannot create a new group, too many placed (Limit: %d). Replace/delete triggers.", CHAT_TAG, MAX_ENTITIES);
		return;
	}


	strcopy(g_sCommand[index], CMD_MAX_LENGTH, g_sCommand[cfgindex]);
	g_iRefireCount[index] = g_iRefireCount[cfgindex];
	g_fRefireTime[index] = g_fRefireTime[cfgindex];
	g_fDelayTime[index] = g_fDelayTime[cfgindex];
	g_iChance[index] = g_iChance[cfgindex];
	g_iCmdData[index] = g_iCmdData[cfgindex];
	g_hTimerEnable[index] = INVALID_HANDLE;
	g_bStopEnd[index] = false;

	decl Float:vPos[3];
	GetClientAbsOrigin(client, vPos);

	CreateTriggerMultiple(index, vPos, Float:{ 25.0, 25.0, 100.0}, Float:{ -25.0, -25.0, 0.0 }, true);

	new Handle:hFile = ConfigOpen();
	if( hFile != INVALID_HANDLE )
	{
		decl String:sTemp[64];
		GetCurrentMap(sTemp, sizeof(sTemp));
		if( KvJumpToKey(hFile, sTemp, true) )
		{
			IntToString(index+1, sTemp, sizeof(sTemp));

			if( KvJumpToKey(hFile, sTemp, true) )
			{
				KvSetVector(hFile, "vpos", vPos);
				KvSetVector(hFile, "vmax", Float:{ 25.0, 25.0, 100.0});
				KvSetVector(hFile, "vmin", Float:{ -25.0, -25.0, 0.0 });
				KvSetString(hFile, "command", g_sCommand[index]);
				KvSetNum(hFile, "refire_count", g_iRefireCount[index]);
				KvSetFloat(hFile, "refire_time", g_fRefireTime[index]);
				KvSetFloat(hFile, "delay_time", g_fDelayTime[index]);
				KvSetNum(hFile, "chance", g_iChance[index]);
				KvSetNum(hFile, "data", g_iCmdData[index]);

				ConfigSave(hFile);

				PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Saved duplicated trigger.", CHAT_TAG, index+1, MAX_ENTITIES, cfgindex+1);
			}
			else
			{
				PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Failed to dupe trigger(A) '%d'.", CHAT_TAG, index+1, MAX_ENTITIES, cfgindex+1);
			}
		}
		else
		{
			PrintToChat(client, "%s\x01(\x05%d/%d\x01) - Failed to dupe trigger(B) '%d'.", CHAT_TAG, index+1, MAX_ENTITIES, cfgindex+1);
		}

		CloseHandle(hFile);
	} else {
		LogError("Error opening config(A)? %s", CONFIG_DATA);
		PrintToChat(client, "%sFailed to save data(A), check your data config file.", CHAT_TAG);
	}

	g_iSelectedTrig = g_iTriggers[index];

	if( g_hTimerBeam == INVALID_HANDLE )
		g_hTimerBeam = CreateTimer(BEAM_TIME, TimerBeam, _, TIMER_REPEAT);
}



// ====================================================================================================
//					TRIGGER BOX - SPAWN TRIGGER / TOUCH CALLBACK
// ====================================================================================================
CreateTrigger(client, String:sCmd[])
{
	new index = -1;

	for( new i = 0; i < MAX_ENTITIES; i++ )
	{
		if( IsValidEntRef(g_iTriggers[i]) == false )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sError: Cannot create a new group, too many placed (Limit: %d). Replace/delete triggers.", CHAT_TAG, MAX_ENTITIES);
		return;
	}

	decl Float:vPos[3];
	GetClientAbsOrigin(client, vPos);

	strcopy(g_sCommand[index], CMD_MAX_LENGTH, sCmd);
	g_iMenuSelected[client] = index;
	g_iSelectedTrig = g_iTriggers[index];
	g_iChance[index] = FIRE_CHANCE;
	g_iRefireCount[index] = REFIRE_COUNT;
	g_fRefireTime[index] = REFIRE_TIME;
	g_fDelayTime[index] = DELAY_TIME;
	g_bStopEnd[index] = false;

	CreateTriggerMultiple(index, vPos, Float:{ 25.0, 25.0, 100.0}, Float:{ -25.0, -25.0, 0.0 }, false);
	index += 1;

	new Handle:hFile = ConfigOpen();
	if( hFile != INVALID_HANDLE )
	{
		SaveTrigger(hFile, client, index, "vpos", vPos);
		SaveTrigger(hFile, client, index, "vmax", Float:{ 25.0, 25.0, 100.0});
		SaveTrigger(hFile, client, index, "vmin", Float:{ -25.0, -25.0, 0.0 });
		SaveData(hFile, client, index, "command", sCmd);
		CloseHandle(hFile);
	} else {
		LogError("Error opening config(B)? %s", CONFIG_DATA);
		PrintToChat(client, "%sFailed to save data(B), check your data config file.", CHAT_TAG);
	}

	if( g_hTimerBeam == INVALID_HANDLE )
		g_hTimerBeam = CreateTimer(BEAM_TIME, TimerBeam, _, TIMER_REPEAT);
}

CreateTriggerMultiple(index, Float:vPos[3], Float:vMaxs[3], Float:vMins[3], bool:autoload)
{
	new trigger = CreateEntityByName("trigger_multiple");
	DispatchKeyValue(trigger, "StartDisabled", "1");
	DispatchKeyValue(trigger, "spawnflags", "1");

	SetEntityModel(trigger, g_sModelBox);

	TeleportEntity(trigger, vPos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(trigger);
	SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", vMaxs);
	SetEntPropVector(trigger, Prop_Send, "m_vecMins", vMins);
	SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);

	if( autoload )
	{
		AcceptEntityInput(trigger, "Enable");
	} else {
		g_iSelectedTrig = EntIndexToEntRef(trigger);
	}

	HookSingleEntityOutput(trigger, "OnStartTouch", OnStartTouch);
	HookSingleEntityOutput(trigger, "OnEndTouch", OnEndTouch);
	g_iTriggers[index] = EntIndexToEntRef(trigger);
}

public Action:TimerEnable(Handle:timer, any:index)
{
	g_hTimerEnable[index] = INVALID_HANDLE;
	g_bStopEnd[index] = false;

	if( g_iCmdData[index] & LEAVE_NO == LEAVE_NO )
	{
		new trigger = g_iTriggers[index];
		if( IsValidEntRef(trigger) )
		{
			AcceptEntityInput(trigger, "Enable");
		}
	}
}

public OnEndTouch(const String:output[], caller, activator, Float:delay)
{
	if( activator > 0 && activator <= MaxClients ) g_iInside[activator] = 0;
}

public OnStartTouch(const String:output[], caller, activator, Float:delay)
{
	if( IsClientInGame(activator) )
	{
		caller = EntIndexToEntRef(caller);

		for( new i = 0; i < MAX_ENTITIES; i++ )
		{
			if( caller == g_iTriggers[i] )
			{
				if( g_bStopEnd[i] == false )
				{
					new bool:executed = false;
					new data = g_iCmdData[i];

					// Require users to leave the box before re-trigger
					if( data & LEAVE_NO != LEAVE_NO && g_iInside[activator] == caller ) return;

					g_iInside[activator] = caller;

					if( !(data & ALLOW_ALL == ALLOW_ALL) )
					{
						new bool:alive = IsPlayerAlive(activator);
						if( data & ALLOW_ALIVE == ALLOW_ALIVE && !alive ) return;
						if( data & ALLOW_DEAD == ALLOW_DEAD && alive ) return;

						new team = GetClientTeam(activator);
						if( data & ALLOW_SPEC == ALLOW_SPEC && team != 1 ) return;
						if( data & ALLOW_TEAMS == ALLOW_TEAMS && team == 1 ) return;
						if( data & ALLOW_TEAM_1 == ALLOW_TEAM_1 && team != 2 ) return;
						if( data & ALLOW_TEAM_2 == ALLOW_TEAM_2 && team != 3 ) return;
					}

					new bool:bot = IsFakeClient(activator);
					if( data & ALLOW_BOTS == ALLOW_BOTS && !bot ) return;
					if( data & ALLOW_REAL == ALLOW_REAL && bot ) return;

					new chance = g_iChance[i];
					if( chance == 100 || GetRandomInt(0, 100) <= chance ) // Chance to exec
					{
						g_bStopEnd[i] = true;

						if( g_iRefireCount[i] == 0 ) // Unlimited refires, create timer to enable the trigger.
						{
							executed = true;
							if( g_fDelayTime[i] > 0.0 )
							{
								CreateTimer(g_fDelayTime[i], tmrExecuteCommand, GetClientUserId(activator) | (i << 7));
							} else {
								ExecuteCommand(activator, i);
							}

							if( g_fRefireTime[i] > 0.0 )
							{
								if( g_hTimerEnable[i] != INVALID_HANDLE )	CloseHandle(g_hTimerEnable[i]);
								g_hTimerEnable[i] = CreateTimer(g_fRefireTime[i], TimerEnable, i);
								if( data & LEAVE_NO == LEAVE_NO )	AcceptEntityInput(caller, "Disable");
							} else {
								g_bStopEnd[i] = false;
							}
						}
						else // Limited refires
						{
							new fired = GetEntProp(caller, Prop_Data, "m_iHammerID");

							if( g_iRefireCount[i] > fired )
							{
								executed = true;
								if( g_fDelayTime[i] > 0.0 )
								{
									CreateTimer(g_fDelayTime[i], tmrExecuteCommand, GetClientUserId(activator) | (i << 7));
								} else {
									ExecuteCommand(activator, i);
								}

								SetEntProp(caller, Prop_Data, "m_iHammerID", fired + 1);
								if( fired + 1 != g_iRefireCount[i] ) // Enable again if allowed
								{
									if( g_fRefireTime[i] > 0.0 )
									{
										if( g_hTimerEnable[i] != INVALID_HANDLE )	CloseHandle(g_hTimerEnable[i]);
										g_hTimerEnable[i] = CreateTimer(g_fRefireTime[i], TimerEnable, i);
										if( data & LEAVE_NO == LEAVE_NO )	AcceptEntityInput(caller, "Disable");
									} else {
										g_bStopEnd[i] = false;
									}
								}
							} else {
								g_bStopEnd[i] = true;
								AcceptEntityInput(caller, "Disable");
							}
						}

						if( !executed && g_iCvarRefire == 1 && g_iRefireCount[i] != 0 )
						{
							new fired = GetEntProp(caller, Prop_Data, "m_iHammerID");
							SetEntProp(caller, Prop_Data, "m_iHammerID", fired + 1);
						}
					} else { // Chance fail, do we add to refire?
						if( g_iCvarRefire == 1 && g_iRefireCount[i] != 0 )
						{
							new fired = GetEntProp(caller, Prop_Data, "m_iHammerID");
							if( g_iRefireCount[i] > fired )
							{
								SetEntProp(caller, Prop_Data, "m_iHammerID", fired + 1);
							} else {
								g_bStopEnd[i] = true;
								AcceptEntityInput(caller, "Disable");
							}
						}
					}

					break;
				}
			}
		}
	}
}

public Action:tmrExecuteCommand(Handle:timer, any:bits)
{
	new client = bits & 0x7F;
	new index = bits >> 7;

	client = GetClientOfUserId(client);

	if( client && IsClientInGame(client) )
	{
		ExecuteCommand(client, index);
	}
}

ExecuteCommand(client, index)
{
	decl String:sCommand[CMD_MAX_LENGTH];
	strcopy(sCommand, sizeof(sCommand), g_sCommand[index]);

	decl String:sComm[CMD_MAX_LENGTH];
	new pos = StrContains(sCommand, " ");
	strcopy(sComm, sizeof(sComm), sCommand);
	if( pos != -1 ) sComm[pos] = '\x0';

	new data = g_iCmdData[index];
	new flags, bits, bool:pass;
	new num = 1;
	new team;
	new bool:bot;

	if( !(data & COMMAND_SERVER == COMMAND_SERVER) && !(data & EXEC_CLIENT == EXEC_CLIENT) ) num = MaxClients;

	for( new i = 1; i <= num; i++ )
	{
		if( num == MaxClients )
		{
			pass = false;
			client = i;
			if( IsClientInGame(client) )
			{
				bot = IsFakeClient(client);
				team = GetClientTeam(client);

				if( data & EXEC_ALL == EXEC_ALL )													pass = true;
				else if( data & EXEC_DEAD == EXEC_DEAD && !IsPlayerAlive(client) )					pass = true;
				else if( data & EXEC_ALIVE == EXEC_ALIVE && IsPlayerAlive(client) )					pass = true;
				else if( data & EXEC_TEAM_1 == EXEC_TEAM_1 && team == g_iTeamOne )					pass = true;
				else if( data & EXEC_TEAM_2 == EXEC_TEAM_2 && team == g_iTeamTwo )					pass = true;
				else if( data & EXEC_TEAMS == EXEC_TEAMS )
				{
					if( team == g_iTeamOne || team == g_iTeamTwo )									pass = true;
				}

				if( !pass )
				{
					if( data & EXEC_BOTS == EXEC_BOTS && bot )										pass = true;
					if( data & EXEC_REAL == EXEC_REAL && !bot )										pass = true;
				} else {
					if( data & EXEC_BOTS == EXEC_BOTS && !bot )										pass = false;
					if( data & EXEC_REAL == EXEC_REAL && bot )										pass = false;
				}
			}
		} else {
			pass = true;
		}
		
		//Get the targets id and replace {me} with the client's id
		decl String:id[32];
		Format(id, sizeof(id), "#%d", GetClientUserId(client));
		
		ReplaceString(sCommand, sizeof(sCommand), "{me}", id, false);
	 

		if( pass )
		{
			bot = IsFakeClient(client);
			// COMMAND CHEAT FLAG
			if( data & FLAGS_CHEAT == FLAGS_CHEAT || data & FLAGS_ADMINCHEAT == FLAGS_ADMINCHEAT )
			{
				flags = GetCommandFlags(sComm);
				SetCommandFlags(sComm, flags & ~FCVAR_CHEAT);
			}
			// USER ADMIN BITS
			if( data & FLAGS_ADMIN == FLAGS_ADMIN || data & FLAGS_ADMINCHEAT == FLAGS_ADMINCHEAT )
			{
				bits = GetUserFlagBits(client);
				SetUserFlagBits(client, ADMFLAG_ROOT);
			}
			// SERVER COMMAND
			if( data & COMMAND_SERVER == COMMAND_SERVER )
			{
				ServerCommand(sCommand);
			}
			else if( data & COMMAND_CLIENT == COMMAND_CLIENT )
			{
				ClientCommand(client, sCommand);
			}
			else if( data & COMMAND_FAKE == COMMAND_FAKE )
			{
				FakeClientCommand(client, sCommand);
			}

			// RESTORE COMMAND FLAGS
			if( data & FLAGS_CHEAT == FLAGS_CHEAT || data & FLAGS_ADMINCHEAT == FLAGS_ADMINCHEAT )
			{
				SetCommandFlags(sComm, flags);
			}
			// RESTORE USER BITS
			if( data & FLAGS_ADMIN == FLAGS_ADMIN || data & FLAGS_ADMINCHEAT == FLAGS_ADMINCHEAT )
			{
				SetUserFlagBits(client, bits);
			}
		}
	}
}



// ====================================================================================================
//					TRIGGER BOX - DISPLAY BEAM BOX
// ====================================================================================================
public Action:TimerBeam(Handle:timer)
{
	if( IsValidEntRef(g_iSelectedTrig) )
	{
		decl Float:vMaxs[3], Float:vMins[3], Float:vPos[3];
		GetEntPropVector(g_iSelectedTrig, Prop_Send, "m_vecOrigin", vPos);
		GetEntPropVector(g_iSelectedTrig, Prop_Send, "m_vecMaxs", vMaxs);
		GetEntPropVector(g_iSelectedTrig, Prop_Send, "m_vecMins", vMins);
		AddVectors(vPos, vMaxs, vMaxs);
		AddVectors(vPos, vMins, vMins);
		TE_SendBox(vMins, vMaxs);
		return Plugin_Continue;
	}

	g_hTimerBeam = INVALID_HANDLE;
	return Plugin_Stop;
}

TE_SendBox(Float:vMins[3], Float:vMaxs[3])
{
	decl Float:vPos1[3], Float:vPos2[3], Float:vPos3[3], Float:vPos4[3], Float:vPos5[3], Float:vPos6[3];
	vPos1 = vMaxs;
	vPos1[0] = vMins[0];
	vPos2 = vMaxs;
	vPos2[1] = vMins[1];
	vPos3 = vMaxs;
	vPos3[2] = vMins[2];
	vPos4 = vMins;
	vPos4[0] = vMaxs[0];
	vPos5 = vMins;
	vPos5[1] = vMaxs[1];
	vPos6 = vMins;
	vPos6[2] = vMaxs[2];
	TE_SendBeam(vMaxs, vPos1);
	TE_SendBeam(vMaxs, vPos2);
	TE_SendBeam(vMaxs, vPos3);
	TE_SendBeam(vPos6, vPos1);
	TE_SendBeam(vPos6, vPos2);
	TE_SendBeam(vPos6, vMins);
	TE_SendBeam(vPos4, vMins);
	TE_SendBeam(vPos5, vMins);
	TE_SendBeam(vPos5, vPos1);
	TE_SendBeam(vPos5, vPos3);
	TE_SendBeam(vPos4, vPos3);
	TE_SendBeam(vPos4, vPos2);
}

TE_SendBeam(const Float:vMins[3], const Float:vMaxs[3])
{
	TE_SetupBeamPoints(vMins, vMaxs, g_iLaserMaterial, g_iHaloMaterial, 0, 0, BEAM_TIME + 0.1, 1.0, 1.0, 1, 0.0, g_iColors, 0);
	TE_SendToAll();
}



// ====================================================================================================
//					CONFIG - OPEN / SAVE
// ====================================================================================================
Handle:ConfigOpen()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_DATA);

	if( !FileExists(sPath) || FileSize(sPath) == 0 )
	{
		new Handle:hCfg = OpenFile(sPath, "w");
		WriteFileLine(hCfg, "");
		CloseHandle(hCfg);
	}

	new Handle:hFile = CreateKeyValues("triggers");
	KvSetEscapeSequences(hFile, true);
	if( !FileToKeyValues(hFile, sPath) )
	{
		CloseHandle(hFile);
		return INVALID_HANDLE;
	}


	return hFile;
}

ConfigSave(Handle:hFile)
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s", CONFIG_DATA);

	if( !FileExists(sPath) ) return;

	KvRewind(hFile);
	KeyValuesToFile(hFile, sPath);
}



// ====================================================================================================
//					OTHER
// ====================================================================================================
bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}