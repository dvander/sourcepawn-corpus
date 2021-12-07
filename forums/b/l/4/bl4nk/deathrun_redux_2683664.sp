// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <morecolors>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>
#include <steamtools>
#include <tf2attributes>
#include <clientprefs>

// ---- Defines ----------------------------------------------------------------
#define DR_VERSION "0.3.1b"
#define PLAYERCOND_SPYCLOAK (1<<4)
#define MAXGENERIC 25	//Used as a limit in the config file

#define TEAM_SPECTATOR 1
#define TEAM_RED 2
#define TEAM_BLUE 3

#define DBD_UNDEF -1 //DBD = Don't Be Death
#define DBD_OFF 1
#define DBD_ON 2
#define DBD_THISMAP 3 // The cookie will never have this value
#define TIME_TO_ASK 30.0 //Delay between asking the client its preferences and it's connection/join.


// ---- Variables --------------------------------------------------------------
new bool:g_isDRmap = false;
new g_lastdeath = -1;
//new g_timesplayed_asdeath[MAXPLAYERS+1];
new bool:g_onPreparation = false;
new g_dontBeDeath[MAXPLAYERS+1] = {DBD_UNDEF,...};
new g_queue_Priory[MAXPLAYERS+1];
new g_queue_save[MAXPLAYERS+1][3];
new bool:g_canEmitSoundToDeath = true;

//GenerealConfig
new bool:g_disablefalldamage;
new bool:g_disableselfdamage;
new Float:g_runner_speed;
new Float:g_death_speed;
new g_runner_outline;
new g_death_outline;

//Weapon-config
new bool:g_MeleeOnly;
new bool:g_MeleeRestricted;
new bool:g_AllRestricted;
new bool:g_RestrictAll;
new Handle:g_RestrictedWeps;
new bool:g_UseDefault;
new bool:g_UseAllClass;
new Handle:g_AllClassWeps;
new bool:g_disablespycloack;
new bool:g_disabledemoshield;
new bool:g_disablescoutdrink;
new bool:g_disablemedicgunheal;
new bool:g_disablelunchheal;

//Build-config
new bool:g_disableallbuilds;
new bool:g_disabledispenser;
new bool:g_disablesentry;
new bool:g_disableteleportentr;
new bool:g_disableteleportexit;

new g_defauldhpblue = 125;


//Command-config
new Handle:g_CmdList;
// new Handle:g_CmdTeamToBlock;
// new Handle:g_CmdBlockOnlyOnPrep;

//Sound-config
new Handle:g_SndRoundStart;
new Handle:g_SndOnDeath;
new Float: g_OnKillDelay;
new Handle:g_SndOnKill;
new Handle:g_SndLastAlive;


// ---- Handles ----------------------------------------------------------------
new Handle:g_DRCookie = INVALID_HANDLE;

// ---- Server's CVars Management ----------------------------------------------
new Handle:dr_queue;
new Handle:dr_unbalance;
new Handle:dr_autobalance;
new Handle:dr_firstblood;
new Handle:dr_scrambleauto;
new Handle:dr_airdash;
new Handle:dr_push;

new dr_queue_def = 0;
new dr_unbalance_def = 0;
new dr_autobalance_def = 0;
new dr_firstblood_def = 0;
new dr_scrambleauto_def = 0;
new dr_airdash_def = 0;
new dr_push_def = 0;

// ---- Plugin's Information ---------------------------------------------------
public Plugin:myinfo =
{
	name = "[TF2] Deathrun Redux 2019",
	author = "originally made by Classic, upgraded by Kapusta and Baltica_7",
	description	= "Deathrun plugin for TF2",
	version = DR_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=316664"
};

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public OnPluginStart()
{
	//Cvars
	CreateConVar("sm_dr_version", DR_VERSION, "Death Run Redux Version.", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	//Creation of Tries
	g_RestrictedWeps = CreateTrie();
	g_AllClassWeps = CreateTrie();
	g_CmdList = CreateTrie();
	// g_CmdTeamToBlock = CreateTrie();
	// g_CmdBlockOnlyOnPrep = CreateTrie();
	g_SndRoundStart = CreateTrie();
	g_SndOnDeath = CreateTrie();
	g_SndOnKill = CreateTrie();
	g_SndLastAlive = CreateTrie();
	
	//Server's Cvars
	dr_queue = FindConVar("tf_arena_use_queue");
	dr_unbalance = FindConVar("mp_teams_unbalance_limit");
	dr_autobalance = FindConVar("mp_autoteambalance");
	dr_firstblood = FindConVar("tf_arena_first_blood");
	dr_scrambleauto = FindConVar("mp_scrambleteams_auto");
	dr_airdash = FindConVar("tf_scout_air_dash_count");
	dr_push = FindConVar("tf_avoidteammates_pushaway");

	//Hooks
	HookEvent("teamplay_round_start", OnPrepartionStart);
	HookEvent("arena_round_start", OnRoundStart); 
	HookEvent("post_inventory_application", OnPlayerInventory);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team",OnDeathChangeTeam);
	HookEvent("teamplay_round_win",OnRoundEnd);
	
	
	//Preferences
	g_DRCookie = RegClientCookie("DR_dontBeDeath", "Does the client want to be the Death?", CookieAccess_Private);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!AreClientCookiesCached(i))
			continue;
		OnClientCookiesCached(i);
	}
	RegConsoleCmd( "drmenu",  DeathMenu);
	RegConsoleCmd( "drqueue", DeathQueuePanel);
	RegConsoleCmd( "drplace", PlaceQueue);
	RegConsoleCmd( "drbedeath", BeDeathMenu);
	RegConsoleCmd( "drnext", NextDeath);
	//disable builds
	AddCommandListener(CommandListener_Build, "build");
	//disable disguise
	//AddCommandListener(CommandListener_Disguise, "disguise");
}

/* OnPluginEnd()
**
** When the plugin is unloaded. Here we reset all the cvars to their normal value.
** -------------------------------------------------------------------------- */
public OnPluginEnd()
{
	ResetCvars();
}


/* OnMapStart()
**
** Here we reset every global variable, and we check if the current map is a deathrun map.
** If it is a dr map, we get the cvars def. values and the we set up our own values.
** -------------------------------------------------------------------------- */
public OnMapStart()
{
	g_lastdeath = -1;
	//for(new i = 1; i <= MaxClients; i++)
			//g_timesplayed_asdeath[i]=-1;
			
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if (strncmp(mapname, "dr_", 3, false) == 0 || strncmp(mapname, "deathrun_", 9, false) == 0 || strncmp(mapname, "vsh_dr_", 6, false) == 0 || strncmp(mapname, "vsh_deathrun_", 6, false) == 0)
	{
		LogMessage("Deathrun map detected. Enabling Deathrun Gamemode.");
		g_isDRmap = true;
		Steam_SetGameDescription("DeathRun Redux 2019 (0.3.1)");
		AddServerTag("deathrun");
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!AreClientCookiesCached(i))
				continue;
			OnClientCookiesCached(i);
		}
		LoadConfigs();
		PrecacheFiles();
		//ProcessListeners();
	}
 	else
	{
		LogMessage("Current map is not a deathrun map. Disabling Deathrun Gamemode.");
		g_isDRmap = false;
		Steam_SetGameDescription("Team Fortress");	
		RemoveServerTag("deathrun");
	}
}

/* OnMapEnd()
**
** Here we reset the server's cvars to their default values.
** -------------------------------------------------------------------------- */
public OnMapEnd()
{
	ResetCvars();
	for (new i = 1; i <= MaxClients; i++)
	{
		g_dontBeDeath[i] = DBD_UNDEF;
	}
}

/* LoadConfigs()
**
** Here we parse the data/deathrun/deathrun.cfg
** -------------------------------------------------------------------------- */
LoadConfigs()
{
	//--DEFAULT VALUES--
	//GenerealConfig
	g_disablefalldamage = false;
	g_disableselfdamage = false;
	g_runner_speed = 300.0;
	g_death_speed = 400.0;
	g_runner_outline = 0;
	g_death_outline = -1;

	//Weapon-config
	g_MeleeOnly = true;
	g_MeleeRestricted = true;
	g_AllRestricted = true;
	g_RestrictAll = true;
	ClearTrie(g_RestrictedWeps);
	g_UseDefault = true;
	g_UseAllClass = false;
	g_disablespycloack = false;
	g_disabledemoshield = false;
	g_disablescoutdrink = false;
	g_disablemedicgunheal = false;
	g_disablelunchheal = false;
	ClearTrie(g_AllClassWeps);
	
	//build config
	g_disableallbuilds = false;
	g_disabledispenser = false;
	g_disablesentry = false;
	g_disableteleportentr = false;
	g_disableteleportexit = false;
	
	//Command-config
	ClearTrie(g_CmdList);
	//ClearTrie(g_CmdTeamToBlock);
	// ClearTrie(g_CmdBlockOnlyOnPrep);

	//Sound-config
	ClearTrie(g_SndRoundStart);
	ClearTrie(g_SndOnDeath);
	g_OnKillDelay = 5.0;
	ClearTrie(g_SndOnKill);
	ClearTrie(g_SndLastAlive);
	
	decl String:mainfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mainfile, sizeof(mainfile), "data/deathrun/deathrun.cfg");
	
	if(!FileExists(mainfile))
	{
		SetFailState("Configuration file %s not found!", mainfile);
		return;
	}
	new Handle:hDR = CreateKeyValues("deathrun");
	if(!FileToKeyValues(hDR, mainfile))
	{
		SetFailState("Improper structure for configuration file %s!", mainfile);
		return;
	}
	if(KvJumpToKey(hDR,"default"))
	{
		g_disablefalldamage = bool:KvGetNum(hDR, "DisableFallDamage", _:g_disablefalldamage);
		g_disableselfdamage = bool:KvGetNum(hDR, "DisableSelfDamage",_:g_disableselfdamage);

		if(KvJumpToKey(hDR,"speed"))
		{
			g_runner_speed = KvGetFloat(hDR,"runners",g_runner_speed);
			g_death_speed = KvGetFloat(hDR,"death",g_death_speed);
			KvGoBack(hDR);
		}
		
		if(KvJumpToKey(hDR,"outline"))
		{
			g_runner_outline = KvGetNum(hDR,"runners",g_runner_outline);
			g_death_outline = KvGetNum(hDR,"death",g_death_outline);
			KvGoBack(hDR);
		}
		KvGoBack(hDR);
	}
	
	
	KvRewind(hDR);
	if(KvJumpToKey(hDR,"weapons"))
	{
	g_MeleeOnly = bool:KvGetNum(hDR, "MeleeOnly", _:g_MeleeOnly);
	g_disablespycloack = bool:KvGetNum(hDR, "DisableSpyCloackandDisguise", _:g_disablespycloack);
	g_disabledemoshield = bool:KvGetNum(hDR, "DisableDemoShield",_:g_disabledemoshield);
	g_disablescoutdrink = bool:KvGetNum(hDR, "DisableScoutDrink",_:g_disablescoutdrink);
	g_disablemedicgunheal = bool:KvGetNum(hDR, "DisableMedicGunHeal",_:g_disablemedicgunheal);
	g_disablelunchheal = bool:KvGetNum(hDR, "DisableLunchBoxHeal",_:g_disablelunchheal);
	g_MeleeRestricted = bool:KvGetNum(hDR, "RestrictedMelee",_:g_MeleeRestricted);
	g_AllRestricted = bool:KvGetNum(hDR, "RestrictedAll",_:g_AllRestricted);
	
	if(g_MeleeRestricted)
			{
				KvJumpToKey(hDR,"AllRestriction");
				g_RestrictAll = bool:KvGetNum(hDR, "RestrictAll", _:g_RestrictAll);
				if(!g_RestrictAll)
				{
					KvJumpToKey(hDR,"RestrictedWeapons");
					new String:key[4], auxInt;
					for(new i=1; i<MAXGENERIC; i++)
					{
						IntToString(i, key, sizeof(key));
						auxInt = KvGetNum(hDR, key, -1);
						if(auxInt == -1)
						{
							break;
						}
						SetTrieValue(g_RestrictedWeps,key,auxInt);
					}
					KvGoBack(hDR);
				}
				g_UseDefault = bool:KvGetNum(hDR, "UseDefault", _:g_UseDefault);
				g_UseAllClass = bool:KvGetNum(hDR, "UseAllClass", _:g_UseAllClass);
				if(g_UseAllClass)
				{
					KvJumpToKey(hDR,"AllClassWeapons");
					new String:key[4], auxInt;
					for(new i=1; i<MAXGENERIC; i++)
					{
						IntToString(i, key, sizeof(key));
						auxInt = KvGetNum(hDR, key, -1);
						if(auxInt == -1)
						{
							break;
						}
						SetTrieValue(g_AllClassWeps,key,auxInt);
					}
					KvGoBack(hDR);
				}
				KvGoBack(hDR);
			}
			
	}
	
	/*KvRewind(hDR);
	KvJumpToKey(hDR,"blockcommands");
	do
	{
		decl String:SectionName[128], String:CommandName[128];
		new onprep, bool:onrunners, bool:ondeath, teamToBlock;
		KvGotoFirstSubKey(hDR);
		KvGetSectionName(hDR, SectionName, sizeof(SectionName));
		
		KvGetString(hDR, "command", CommandName, sizeof(CommandName));
		onprep = KvGetNum(hDR, "OnlyOnPreparation", 0);
		onrunners = !!KvGetNum(hDR,"runners",1);
		ondeath = !!KvGetNum(hDR,"death",1);
		
		teamToBlock = 0;
		if((onrunners && ondeath))
			teamToBlock = 1;
		else if(onrunners && !ondeath)
			teamToBlock = TEAM_RED;
		else if(!onrunners && ondeath)
			teamToBlock = TEAM_BLUE;
		
		if(!StrEqual(CommandName, "") || teamToBlock == 0)
		{
			SetTrieString(g_CmdList,SectionName,CommandName);
			SetTrieValue(g_CmdBlockOnlyOnPrep,CommandName,onprep);
			SetTrieValue(g_CmdTeamToBlock,CommandName,teamToBlock);
		}
	} 
	*/
	//while(KvGotoNextKey(hDR));
	
	KvRewind(hDR);
	if(KvJumpToKey(hDR,"BlockBuilds"))
	{
		g_disableallbuilds = bool:KvGetNum(hDR, "DisableAllBuilds", _:g_disableallbuilds);
		g_disabledispenser = bool:KvGetNum(hDR, "DisableDispenser", _:g_disabledispenser);
		g_disablesentry = bool:KvGetNum(hDR, "DisableSentry", _:g_disablesentry);
		g_disableteleportentr = bool:KvGetNum(hDR, "DisableTpEntr", _:g_disableteleportentr);
		g_disableteleportexit = bool:KvGetNum(hDR, "DisableTpExit", _:g_disableteleportexit);
		KvGoBack(hDR);
	}
	
	
	KvRewind(hDR);
	if(KvJumpToKey(hDR,"sounds"))
	{
		new String:key[4], String:sndFile[PLATFORM_MAX_PATH];
		if(KvJumpToKey(hDR,"RoundStart"))
		{
			for(new i=1; i<MAXGENERIC; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(hDR, key, sndFile, sizeof(sndFile),"");
				if(StrEqual(sndFile, ""))
					break;			
				SetTrieString(g_SndRoundStart,key,sndFile);
			}
			KvGoBack(hDR);
		}
		
		if(KvJumpToKey(hDR,"OnDeath"))
		{
			for(new i=1; i<MAXGENERIC; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(hDR, key, sndFile, sizeof(sndFile),"");
				if(StrEqual(sndFile, ""))
					break;			
				SetTrieString(g_SndOnDeath,key,sndFile);
			}
			KvGoBack(hDR);
		}
		
		if(KvJumpToKey(hDR,"OnKill"))
		{
			
			g_OnKillDelay = KvGetFloat(hDR,"delay",g_OnKillDelay);
			for(new i=1; i<MAXGENERIC; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(hDR, key, sndFile, sizeof(sndFile),"");
				if(StrEqual(sndFile, ""))
					break;			
				SetTrieString(g_SndOnKill,key,sndFile);
			}
			KvGoBack(hDR);
		}
		
		if(KvJumpToKey(hDR,"LastAlive"))
		{
			for(new i=1; i<MAXGENERIC; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(hDR, key, sndFile, sizeof(sndFile),"");
				if(StrEqual(sndFile, ""))
					break;			
				SetTrieString(g_SndLastAlive,key,sndFile);
			}
			KvGoBack(hDR);
		}
		KvGoBack(hDR);
	}
	
	KvRewind(hDR);
	CloseHandle(hDR);
	
	decl String:mapfile[PLATFORM_MAX_PATH],String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, mapfile, sizeof(mapfile), "data/deathrun/maps/%s.cfg",mapname);
	if(FileExists(mapfile))
	{
		hDR = CreateKeyValues("drmap");
		if(!FileToKeyValues(hDR, mapfile))
		{
			SetFailState("Improper structure for configuration file %s!", mapfile);
			return;
		}
		
		g_disablefalldamage = bool:KvGetNum(hDR, "DisableFallDamage", _:g_disablefalldamage);
		g_disableselfdamage = bool:KvGetNum(hDR, "DisableSelfDamage",_:g_disableselfdamage);

		if(KvJumpToKey(hDR,"speed"))
		{
			g_runner_speed = KvGetFloat(hDR,"runners",g_runner_speed);
			g_death_speed = KvGetFloat(hDR,"death",g_death_speed);
			
			KvGoBack(hDR);
		}
		if(KvJumpToKey(hDR,"outline"))
		{
			g_runner_outline = KvGetNum(hDR,"runners",g_runner_outline);
			g_death_outline = KvGetNum(hDR,"death",g_death_outline);
		}
		KvRewind(hDR);
		CloseHandle(hDR);
	}
}


/* PrecacheFiles()
**
** We precache and add to the download table every sound file found on the config file.
** -------------------------------------------------------------------------- */
PrecacheFiles()
{
	PrecacheSoundFromTrie(g_SndRoundStart);
	PrecacheSoundFromTrie(g_SndOnDeath);
	PrecacheSoundFromTrie(g_SndOnKill);
	PrecacheSoundFromTrie(g_SndLastAlive);
}

/* PrecacheFiles()
**
** We precache and add to the download table, reading every value of a Trie.
** -------------------------------------------------------------------------- */
PrecacheSoundFromTrie(Handle:sndTrie)
{
	new trieSize = GetTrieSize(sndTrie);
	decl String:soundString[PLATFORM_MAX_PATH],String:downloadString[PLATFORM_MAX_PATH],String:key[4];
	for(new i = 1; i <= trieSize; i++)
	{
		IntToString(i,key,sizeof(key));
		if(GetTrieString(sndTrie,key,soundString, sizeof(soundString)))
		{
			if(PrecacheSound(soundString))
			{
				Format(downloadString, sizeof(downloadString), "sound/%s", soundString);
				AddFileToDownloadsTable(downloadString);
			}
		}
	}
}


/* ProcessListeners()
**
** Here we add the listeners to block the commands defined on the config file.
** -------------------------------------------------------------------------- 
ProcessListeners(bool:removeListerners=false)
{
	new trieSize = GetTrieSize(g_CmdList);
	decl String:command[PLATFORM_MAX_PATH],String:key[4];
	for(new i = 1; i <= trieSize; i++)
	{
		IntToString(i,key,sizeof(key));
		if(GetTrieString(g_CmdList,key,command, sizeof(command)))
		{
			if(StrEqual(command, ""))
					break;		
					
			if(removeListerners)	
				RemoveCommandListener(Command_Block,command);
			else 
				AddCommandListener(Command_Block,command);
				
					
			GetTrieValue(g_CmdBlockOnlyOnPrep,key,PreparationOnly);
			if(removeListerners)
			{
				if(PreparationOnly == 1)
					RemoveCommandListener(Command_Block_PreparationOnly,command);
				else
					RemoveCommandListener(Command_Block,command);
			}
			else
			{
				if(PreparationOnly == 1)
					AddCommandListener(Command_Block_PreparationOnly,command);
				else
					AddCommandListener(Command_Block,command);
			}
			
			
		}
	}
}
*/

/* OnClientPutInServer()
**
** We set on zero the time played as death when the client enters the server.
** -------------------------------------------------------------------------- */
public OnClientPutInServer(client)
{
	//g_timesplayed_asdeath[client] = 0;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); //for disable self damage
	new kol = 1;
	do
	{
		if (g_queue_save[kol][1] == GetSteamAccountID(client, true))
			g_queue_Priory[client] = g_queue_save[kol][2];
		kol++;
	}
	while (g_queue_save[kol][2] != 0);
	if (g_queue_Priory[client] == 0)
			g_queue_Priory[client]++;
	
}

/* OnClientDisconnect()
**
** We set as minus one the time played as death when the client leaves.
** When searching for a Death we ignore every client with the -1 value.
** We also set as undef the preference value
** -------------------------------------------------------------------------- */
public OnClientDisconnect(client)
{
	new kol = 1;
	//g_timesplayed_asdeath[client] =-1;
	if (g_dontBeDeath[client] == DBD_THISMAP)
		g_dontBeDeath[client] = DBD_UNDEF;
	if (g_onPreparation) {
		if (client == g_lastdeath)
			BalanceTeams();
	}
	do
	{
		kol++;
	}
	while (g_queue_save[kol][2] != 0);
	g_queue_save[kol][1] = GetSteamAccountID(client, true);
	g_queue_save[kol][2] = g_queue_Priory[client];
	g_queue_Priory[client] = 0;
}

/* OnClientCookiesCached()
**
** We look if the client have a saved value
** -------------------------------------------------------------------------- */
public OnClientCookiesCached(client)
{
	decl String:sValue[8];
	GetClientCookie(client, g_DRCookie, sValue, sizeof(sValue));
	new nValue = StringToInt(sValue);

	if( nValue != DBD_OFF && nValue != DBD_ON) //If cookie is not valid we ask for a preference.
		CreateTimer(TIME_TO_ASK, AskMenuTimer, client);
	else //client has a valid cookie
		g_dontBeDeath[client] = nValue;
}

public Action:AskMenuTimer(Handle:timer, any:client)
{
	DeathMenu(client,0);
}

public Action:DeathMenu(client,args)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return Plugin_Handled;
	}
	new Handle:menu = CreateMenu(DeathMenuHandler);
	SetMenuTitle(menu, "Death info");
        AddMenuItem(menu, "0", "Death queue");
	AddMenuItem(menu, "1", "My place in queue");
	AddMenuItem(menu, "2", "Be death menu");
	AddMenuItem(menu, "3", "Next death");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
	
	return Plugin_Handled;
}
public DeathMenuHandler(Handle:menu, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0)
		{
			DeathQueuePanel(client,0);
		}
		else if (buttonnum == 1)
		{
			PlaceQueue(client,0);
		}
		else if (buttonnum == 2)
		{
			BeDeathMenu(client,0);
		}
		else if (buttonnum == 3)
		{
			NextDeath(client,0);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:DeathQueuePanel(client,args)
{
	char name[32];
	char num[32];
	if (client == 0 || (!IsClientInGame(client)))
	{
		return Plugin_Handled;
	}
	new Handle:menuQ = CreateMenu(DeathQMenuHandler);
	SetMenuTitle(menuQ, "Death queue");	
	new dqueue[MAXPLAYERS+1][MAXPLAYERS+1];
	new points = 0;
	new pos = 0;
	new kol = 0;
	for (new i = 1; i<=MaxClients; i++) {
		if (IsClientInGame(i)&&IsClientConnected(i)&&(GetClientTeam(i) == TEAM_RED)){
	    dqueue[i][2] = g_queue_Priory[i];
	    dqueue[i][1] = i;
	    kol++;
		}
	}
	for (new i = 1; i<=MAXPLAYERS; i++) {
		for (new j = 1; j<=MAXPLAYERS; j++) {
			if (dqueue[i][2] >= dqueue[j][2]){
				points = dqueue[i][2];
				pos = dqueue[i][1];
				dqueue[i][2] = dqueue[j][2];
				dqueue[i][1] = dqueue[j][1];
				dqueue[j][2] = points;
				dqueue[j][1] = pos;
			}
		}
	}
		//AddMenuItem(menuQ, "0", "current death:");
	new death = GetLastPlayer(TEAM_BLUE);
	if (death != -1)
	{
		GetClientName(death, name,sizeof(name));
		char nameDeath[128];
		Format(nameDeath,sizeof(nameDeath),"%s \n ---------------",name);
		AddMenuItem(menuQ, "1", nameDeath);
	}
	else
	{
		AddMenuItem(menuQ, "1", "death not select \n ---------------");
	}
		//AddMenuItem(menuQ, "2", "-----------");
	for (new i = 1; i<=kol; i++) {
		if ((IsClientInGame(dqueue[i][1])) && (IsClientConnected(dqueue[i][1]))){
			if (GetClientCount(true)>4){
			if (g_dontBeDeath[dqueue[i][1]] == DBD_ON || g_dontBeDeath[dqueue[i][1]] == DBD_THISMAP){
				continue;
			}
			else
			{
		GetClientName(dqueue[i][1], name,sizeof(name));
		IntToString(i,num,sizeof(num));
		AddMenuItem(menuQ, num, name);
			}
			}
			else
			{
		GetClientName(dqueue[i][1], name,sizeof(name));
		IntToString(i,num,sizeof(num));
		AddMenuItem(menuQ, num, name);
			}
		}
	}
		
		/*for (new j = 1; j<=MAXPLAYERS; j++) {
			if (Max<=dqueue[j][2]&&IsClientInGame(dqueue[j][1])&&IsClientConnected(dqueue[j][1])) {
				Max = dqueue[j][2];
				pos = dqueue[j][1];
			}
		}
				dqueue[i][2] = 0;
				char name[32];
				char num[32];
				//char points[32];
				GetClientName(pos, name,sizeof(name));
				IntToString(i,num,sizeof(num));
				if (Max > 0) {
				AddMenuItem(menuQ, num, name);
	}
	}
	*/
	SetMenuExitBackButton(menuQ, true);
	SetMenuExitButton(menuQ, true);
	DisplayMenu(menuQ, client, 30);
	return Plugin_Handled;
}
public DeathQMenuHandler(Handle:menuQ, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack) 
		{
			DeathMenu(client,0);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuQ);
	}
}
public Action:PlaceQueue(client,args)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return Plugin_Handled;
	}
	new Handle:menuPQ = CreateMenu(DeathPQMenuHandler);
	SetMenuTitle(menuPQ, "Place in queue");	
	new dqueue[MAXPLAYERS+1][MAXPLAYERS+1];
	new points = 0;
	new pos = 0;
	for (new i = 1; i<=MaxClients; i++) {
		if (IsClientInGame(i)&&IsClientConnected(i)&&(i != GetLastPlayer(TEAM_BLUE))&&(GetClientTeam(i) != TEAM_SPECTATOR)) {
			if (GetClientCount(true)>4){
				if ((g_dontBeDeath[i] != DBD_ON)&&(g_dontBeDeath[i] != DBD_THISMAP)) {
					dqueue[i][2] = g_queue_Priory[i];
					dqueue[i][1] = i;
			    }
				else 
				{
			    continue;
				}
		    }
			else 
		    {
				dqueue[i][2] = g_queue_Priory[i];
				dqueue[i][1] = i;	
		    }
		}
		else
		{
			dqueue[i][2] = 0;
		}
	}
	for (new i = 1; i<=MAXPLAYERS-1; i++) {
		for (new j = 1; j<=MAXPLAYERS-1; j++) {
			if ((dqueue[i][2] >= dqueue[j][2])&&(dqueue[i][2]>0)&&(dqueue[j][2]>0)){
				points = dqueue[i][2];
				pos = dqueue[i][1];
				dqueue[i][2] = dqueue[j][2];
				dqueue[i][1] = dqueue[j][1];
				dqueue[j][2] = points;
				dqueue[j][1] = pos;
			}
		}
	}
	if (client == GetLastPlayer(TEAM_BLUE)) {
				AddMenuItem(menuPQ, "0", "You are playing as death now!");
			}
			else
			{
				if (GetClientTeam(client) == TEAM_SPECTATOR) {
					AddMenuItem(menuPQ, "0", "You in team spectator and are not in queue");
				}
				else
				{
			if ((g_dontBeDeath[client] == DBD_ON || g_dontBeDeath[client] == DBD_THISMAP)&&(GetClientCount(true) > 4)) {
				AddMenuItem(menuPQ, "0", "You chose not to be death and are not in queue");
			}
			else
			{
	for (new i = 1; i<=MAXPLAYERS-1; i++) {
		if (dqueue[i][1] == client) {
			char num[32];
			IntToString(i,num,sizeof(num));
			AddMenuItem(menuPQ, "Your place", num);
				}
			}
				}
			}
}
	SetMenuExitBackButton(menuPQ, true);
	SetMenuExitButton(menuPQ, true);
	DisplayMenu(menuPQ, client, 30);
	return Plugin_Handled;
}
public DeathPQMenuHandler(Handle:menuPQ, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack) 
		{
			DeathMenu(client,0);
		}
	}
	else
	if (action == MenuAction_End)
	{
		CloseHandle(menuPQ);
	}
}

public Action:NextDeath(client,args)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return Plugin_Handled;
	}
	new Handle:menuDRN = CreateMenu(NextDeathHandler);
	SetMenuTitle(menuDRN, "Next Death");
	new dqueue[MAXPLAYERS+1][MAXPLAYERS+1];
	new pos = 1;
	for (new i = 1; i<=MaxClients; i++) {
		if (IsClientInGame(i)&&IsClientConnected(i)&&(i != GetLastPlayer(TEAM_BLUE))&&(GetClientTeam(i) != TEAM_SPECTATOR)) {
			if (GetClientCount(true)>4){
				if ((g_dontBeDeath[i] != DBD_ON)&&(g_dontBeDeath[i] != DBD_THISMAP)) {
					dqueue[i][2] = g_queue_Priory[i];
					dqueue[i][1] = i;
			    }
				else 
				{
			    continue;
				}
		    }
			else 
		    {
				dqueue[i][2] = g_queue_Priory[i];
				dqueue[i][1] = i;	
		    }
		}
		else
		{
			dqueue[i][2] = 0;
		}
	}
	new max = dqueue[1][2];
	
	for (new i = 1; i<=MaxClients; i++) {
		if (max <= dqueue[i][2]) {
			max = dqueue[i][2];
			pos = dqueue[i][1];
		}
			
	}
	if (pos != client) {
	char name[32];
	GetClientName(pos, name,sizeof(name));
	AddMenuItem(menuDRN, "1", name);
	}
	else
	{
		AddMenuItem(menuDRN, "1", "You are going to be death in the next round!");
	}
	SetMenuExitBackButton(menuDRN, true);
	SetMenuExitButton(menuDRN, true);
	DisplayMenu(menuDRN, client, 30);
	return Plugin_Handled;
}

public NextDeathHandler(Handle:menuDRN, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack) 
		{
			DeathMenu(client,0);
		}
	}
	else
	if (action == MenuAction_End)
	{
		CloseHandle(menuDRN);
	}
}

public Action:BeDeathMenu(client,args)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return Plugin_Handled;
	}
	new Handle:menuDBD = CreateMenu(BeDeathMenuHandler);
	SetMenuTitle(menuDBD, "Be the Death toggle");
	AddMenuItem(menuDBD, "0", "Select me as Death");
	AddMenuItem(menuDBD, "1", "Don't select me as Death");
	AddMenuItem(menuDBD, "2", "Don't be Death in this map");
	SetMenuExitBackButton(menuDBD, true);
	SetMenuExitButton(menuDBD, true);
	DisplayMenu(menuDBD, client, 30);
	
	return Plugin_Handled;
}

public BeDeathMenuHandler(Handle:menuDBD, MenuAction:action, client, buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0)
		{
			g_dontBeDeath[client] = DBD_OFF;
			decl String:sPref[2];
			IntToString(DBD_OFF, sPref, sizeof(sPref));
			SetClientCookie(client, g_DRCookie, sPref);
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can be selected as Death.");
		}
		else if (buttonnum == 1)
		{
			g_dontBeDeath[client] = DBD_ON;
			decl String:sPref[2];
			IntToString(DBD_ON, sPref, sizeof(sPref));
			SetClientCookie(client, g_DRCookie, sPref);
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can't be selected as Death.");
		}
		else if (buttonnum == 2)
		{
			g_dontBeDeath[client] = DBD_THISMAP;
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can't be selected as Death for this map.");
		}
		
		if (buttonnum == 8)
		{
			DeathMenu(client,0);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (buttonnum == MenuCancel_ExitBack) 
		{
			DeathMenu(client,0);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menuDBD);
	}
}

/* OnPrepartionStart()
**
** We setup the cvars again, balance the teams and we freeze the players.
** -------------------------------------------------------------------------- */
public Action:OnPrepartionStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{
		g_onPreparation = true;
		
		//We force the cvars values needed every round (to override if any cvar was changed).
		SetupCvars();
		for(new i = 1; i <= MaxClients; i++){
			if ((IsClientInGame(i))&&(IsPlayerAlive(i)))
				g_queue_Priory[i] = g_queue_Priory[i]+10;
		}
		//We move the players to the corresponding team.
		BalanceTeams();
		new currentDeath = GetLastPlayer(TEAM_BLUE);
		
		//Players shouldn't move until the round starts
		for(new i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
				SetEntityMoveType(i, MOVETYPE_NONE);	

		EmitRandomSound(g_SndRoundStart);
		if(!g_MeleeOnly){
			TF2Attrib_RemoveByName(currentDeath, "max health additive bonus");
			SetEntityHealth(currentDeath, 125);
			TF2_RegeneratePlayer(currentDeath);
		}
	}
}

/* OnRoundStart()
**
** We unfreeze every player.
** -------------------------------------------------------------------------- */
public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{
		for(new i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
					SetEntityMoveType(i, MOVETYPE_WALK);
					if((GetClientTeam(i) == TEAM_RED && g_runner_outline == 0)||(GetClientTeam(i) == TEAM_BLUE && g_death_outline == 0))
						SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);	
			}
		g_onPreparation = false;
		
		if(!g_MeleeOnly){
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new aliveRunners = GetAlivePlayersCount(TEAM_RED,client);
			new currentDeath = GetLastPlayer(TEAM_BLUE);
			g_defauldhpblue = GetClientHealth(currentDeath);
			new HealthBlue = GetClientHealth(currentDeath);
			if(aliveRunners>=30){
				HealthBlue = 2000-HealthBlue;
				TF2Attrib_SetByName(currentDeath, "max health additive bonus", float(HealthBlue));
				TF2_RegeneratePlayer(currentDeath);
			}
			if((aliveRunners>=20)&&(aliveRunners<30)){
			 HealthBlue = 1700-HealthBlue;
			 TF2Attrib_SetByName(currentDeath, "max health additive bonus", float(HealthBlue));
			 TF2_RegeneratePlayer(currentDeath);
			}
			if((aliveRunners>=15)&&(aliveRunners<20)){
			HealthBlue = 1500-HealthBlue;
			TF2Attrib_SetByName(currentDeath, "max health additive bonus", float(HealthBlue));
			TF2_RegeneratePlayer(currentDeath);
			}
			if((aliveRunners>=10)&&(aliveRunners<15)){
			 HealthBlue = 1000-HealthBlue;
			 TF2Attrib_SetByName(currentDeath, "max health additive bonus", float(HealthBlue));
			 TF2_RegeneratePlayer(currentDeath);
			}
			if((aliveRunners>=5)&&(aliveRunners<10)){
			  HealthBlue = 700-HealthBlue;
			  TF2Attrib_SetByName(currentDeath, "max health additive bonus", float(HealthBlue));
			  TF2_RegeneratePlayer(currentDeath);
			}
			if((aliveRunners>=2)&&(aliveRunners<5)){
			  HealthBlue = 500-HealthBlue;
			  TF2Attrib_SetByName(currentDeath, "max health additive bonus", float(HealthBlue));
			  TF2_RegeneratePlayer(currentDeath);
			}
			if(aliveRunners == 1){
			  HealthBlue = 200-HealthBlue;
			  TF2Attrib_SetByName(currentDeath, "max health additive bonus", float(HealthBlue));
			  TF2_RegeneratePlayer(currentDeath);
			}		
		}
			
			
	}
}

/* TF2Items_OnGiveNamedItem_Post()
**
** Here we disable all builds
** -------------------------------------------------------------------------- */
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, ent)
{
	if(g_isDRmap)
	{
		if(g_disableallbuilds)
		if(StrEqual(classname,"tf_weapon_builder", false))
			CreateTimer(0.1, Timer_RemoveWep, EntIndexToEntRef(ent));  
	}
}

/* Timer_RemoveWep()
**
** We kill builder
** -------------------------------------------------------------------------- */
public Action:Timer_RemoveWep(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if( IsValidEntity(ent) && ent > MaxClients)
		AcceptEntityInput(ent, "Kill");
} 



/* OnPlayerInventory()
**
** Here we strip players weapons (if we have to).
** Also we give special melee weapons (again, if we have to).
** -------------------------------------------------------------------------- */
public Action:OnPlayerInventory(Handle:event, const String:name[], bool:dontBroadcast)
{
if(g_isDRmap)
	{
	new Handle:hItem = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
	new Handle:hItem2 = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
	new Handle:hItem3 = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new TFClassType:iClass = TF2_GetPlayerClass(client);
	if(g_MeleeOnly)
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);
			
			
			if(g_MeleeRestricted)
			{
				new bool:replacewep = false;
				if(g_RestrictAll)
					replacewep=true;
				else
				{
					new wepEnt = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
					new wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex"); 
					new rwSize = GetTrieSize(g_RestrictedWeps);
					new String:key[4], auxIndex;
					for(new i = 1; i <= rwSize; i++)
					{
						IntToString(i,key,sizeof(key));
						if(GetTrieValue(g_RestrictedWeps,key,auxIndex))
							if(wepIndex == auxIndex)
								replacewep=true;
					}
				
				}
				if(replacewep)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					new weaponToUse = -1;
					if(g_UseAllClass)
					{
						new acwSize = GetTrieSize(g_AllClassWeps);
						new rndNum;
						if(g_UseDefault)
							rndNum = GetRandomInt(1,acwSize+1);
						else
							rndNum = GetRandomInt(1,acwSize);
						
						if(rndNum <= acwSize)
						{
							new String:key[4];
							IntToString(rndNum,key,sizeof(key));
							GetTrieValue(g_AllClassWeps,key,weaponToUse);
						}
						
					}
					
					//Here we give a melee to every class
					switch(iClass)
					{
						case TFClass_Scout:{
							TF2Items_SetClassname(hItem, "tf_weapon_bat");
							if(weaponToUse == -1)
								weaponToUse = 190;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Sniper:{
							TF2Items_SetClassname(hItem, "tf_weapon_club");
							if(weaponToUse == -1)
								weaponToUse = 190;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							TF2Items_SetItemIndex(hItem, 193);
							}
						case TFClass_Soldier:{
							TF2Items_SetClassname(hItem, "tf_weapon_shovel");
							if(weaponToUse == -1)
								weaponToUse = 196;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_DemoMan:{
							TF2Items_SetClassname(hItem, "tf_weapon_bottle");
							if(weaponToUse == -1)
								weaponToUse = 191;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Medic:{
							TF2Items_SetClassname(hItem, "tf_weapon_bonesaw");
							if(weaponToUse == -1)
								weaponToUse = 198;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Heavy:{
							TF2Items_SetClassname(hItem, "tf_weapon_fists");
							if(weaponToUse == -1)
								weaponToUse = 195;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Pyro:{
							TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
							if(weaponToUse == -1)
								weaponToUse = 192;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Spy:{
							TF2Items_SetClassname(hItem, "tf_weapon_knife");
							if(weaponToUse == -1)
								weaponToUse = 194;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Engineer:{
							TF2Items_SetClassname(hItem, "tf_weapon_wrench");
							if(weaponToUse == -1)
								weaponToUse = 197;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						}
							
					TF2Items_SetLevel(hItem, 69);
					TF2Items_SetQuality(hItem, 6);
					TF2Items_SetAttribute(hItem, 0, 150, 1.0); //Turn to gold on kill
					TF2Items_SetNumAttributes(hItem, 1);
					new iWeapon = TF2Items_GiveNamedItem(client, hItem);
					CloseHandle(hItem);
					
					EquipPlayerWeapon(client, iWeapon);
				}
			}
			TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
		}
	if (!g_MeleeOnly)
		{
		if(g_AllRestricted)
			{
				new bool:replacewep = false;
				new bool:replacewep2 = false;
				new bool:replacewep3 = false;
				new bool: wep3 = false;
				if(g_RestrictAll)
					replacewep=true;
				else
				{
					new wepEnt = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
					new wepEnt2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if (wepEnt2 == -1)
					wep3 = true;
					new wepEnt3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
					new wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex"); 
					new wepIndex2 = 1;
					if (!wep3)
						wepIndex2 = GetEntProp(wepEnt2, Prop_Send, "m_iItemDefinitionIndex");
					else
						wepIndex2 = 0;				
					new wepIndex3 = GetEntProp(wepEnt3, Prop_Send, "m_iItemDefinitionIndex");
					new rwSize = GetTrieSize(g_RestrictedWeps);
					new String:key[4], auxIndex;
					for(new i = 1; i <= rwSize; i++)
					{
						IntToString(i,key,sizeof(key));
						if(GetTrieValue(g_RestrictedWeps,key,auxIndex)) {
							if(wepIndex == auxIndex)
								replacewep = true;
							if(wepIndex2 == auxIndex)
								replacewep2=true;
							if(wepIndex3 == auxIndex)
								replacewep3=true;
						}
					}
				
				}
				if(replacewep)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					new weaponToUse = -1;
					if(g_UseAllClass)
					{
						new acwSize = GetTrieSize(g_AllClassWeps);
						new rndNum;
						if(g_UseDefault)
							rndNum = GetRandomInt(1,acwSize+1);
						else
							rndNum = GetRandomInt(1,acwSize);
						
						if(rndNum <= acwSize)
						{
							new String:key[4];
							IntToString(rndNum,key,sizeof(key));
							GetTrieValue(g_AllClassWeps,key,weaponToUse);
						}
						
					}
					//Here we give a melee to every class
					switch(iClass)
					{
						case TFClass_Scout:{
							TF2Items_SetClassname(hItem, "tf_weapon_bat");
							if(weaponToUse == -1)
								weaponToUse = 190;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Sniper:{
							TF2Items_SetClassname(hItem, "tf_weapon_club");
							if(weaponToUse == -1)
								weaponToUse = 190;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							TF2Items_SetItemIndex(hItem, 193);
							}
						case TFClass_Soldier:{
							TF2Items_SetClassname(hItem, "tf_weapon_shovel");
							if(weaponToUse == -1)
								weaponToUse = 196;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_DemoMan:{
							TF2Items_SetClassname(hItem, "tf_weapon_bottle");
							if(weaponToUse == -1)
								weaponToUse = 191;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Medic:{
							TF2Items_SetClassname(hItem, "tf_weapon_bonesaw");
							if(weaponToUse == -1)
								weaponToUse = 198;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Heavy:{
							TF2Items_SetClassname(hItem, "tf_weapon_fists");
							if(weaponToUse == -1)
								weaponToUse = 195;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Pyro:{
							TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
							if(weaponToUse == -1)
								weaponToUse = 192;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Spy:{
							TF2Items_SetClassname(hItem, "tf_weapon_knife");
							if(weaponToUse == -1)
								weaponToUse = 194;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						case TFClass_Engineer:{
							TF2Items_SetClassname(hItem, "tf_weapon_wrench");
							if(weaponToUse == -1)
								weaponToUse = 197;
							TF2Items_SetItemIndex(hItem, weaponToUse);
							}
						}
							
					TF2Items_SetLevel(hItem, 69);
					TF2Items_SetQuality(hItem, 6);
					TF2Items_SetAttribute(hItem, 0, 150, 1.0); //Turn to gold on kill
					TF2Items_SetNumAttributes(hItem, 1);
					new iWeapon = TF2Items_GiveNamedItem(client, hItem);
					CloseHandle(hItem);
					
					EquipPlayerWeapon(client, iWeapon);
				}
				if(replacewep2)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
					new weaponToUse = -1;
					
					//Here we give a secondary to every class
					switch(iClass)
					{
						case TFClass_Scout:{
							TF2Items_SetClassname(hItem2, "tf_weapon_pistol");
							if(weaponToUse == -1)
								weaponToUse = 22;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						case TFClass_Sniper:{
							TF2Items_SetClassname(hItem2, "tf_weapon_smg");
							if(weaponToUse == -1)
								weaponToUse = 16;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						case TFClass_Soldier:{
							TF2Items_SetClassname(hItem2, "tf_weapon_shotgun_soldier");
							if(weaponToUse == -1)
								weaponToUse = 10;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						case TFClass_DemoMan:{
							TF2Items_SetClassname(hItem2, "tf_weapon_pipebomblauncher");
							if(weaponToUse == -1)
								weaponToUse = 20;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						case TFClass_Medic:{
							TF2Items_SetClassname(hItem2, "tf_weapon_medigun");
							if(weaponToUse == -1)
								weaponToUse = 29;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						case TFClass_Heavy:{
							TF2Items_SetClassname(hItem2, "tf_weapon_shotgun_hwg");
							if(weaponToUse == -1)
								weaponToUse = 11;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						case TFClass_Pyro:{
							TF2Items_SetClassname(hItem2, "tf_weapon_shotgun_pyro");
							if(weaponToUse == -1)
								weaponToUse = 12;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						case TFClass_Spy:{
							TF2Items_SetClassname(hItem2, "tf_weapon_revolver");
							if(weaponToUse == -1)
								weaponToUse = 24;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						case TFClass_Engineer:{
							TF2Items_SetClassname(hItem2, "tf_weapon_pistol");
							if(weaponToUse == -1)
								weaponToUse = 22;
							TF2Items_SetItemIndex(hItem2, weaponToUse);
							}
						}
							
					TF2Items_SetLevel(hItem2, 69);
					TF2Items_SetQuality(hItem2, 6);
					TF2Items_SetAttribute(hItem2, 0, 150, 1.0); //Turn to gold on kill
					TF2Items_SetNumAttributes(hItem2, 1);
					new iWeapon2 = TF2Items_GiveNamedItem(client, hItem2);
					CloseHandle(hItem2);
					
					EquipPlayerWeapon(client, iWeapon2);
				}
				if(replacewep3)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
					new weaponToUse = -1;
					
					//Here we give a primary to every class
					switch(iClass)
					{
						case TFClass_Scout:{
							TF2Items_SetClassname(hItem3, "tf_weapon_scattergun");
							if(weaponToUse == -1)
								weaponToUse = 13;
							TF2Items_SetItemIndex(hItem3, weaponToUse);
							}
						case TFClass_Sniper:{
							TF2Items_SetClassname(hItem3, "tf_weapon_sniperrifle");
							if(weaponToUse == -1)
								weaponToUse = 14;
							TF2Items_SetItemIndex(hItem3, weaponToUse);
							}
						case TFClass_Soldier:{
							TF2Items_SetClassname(hItem3, "tf_weapon_rocketlauncher");
							if(weaponToUse == -1)
								weaponToUse = 18;
							TF2Items_SetItemIndex(hItem3, weaponToUse);
							}
						case TFClass_DemoMan:{
							TF2Items_SetClassname(hItem3, "tf_weapon_grenadelauncher");
							if(weaponToUse == -1)
								weaponToUse = 19;
							TF2Items_SetItemIndex(hItem3, weaponToUse);
							}
						case TFClass_Medic:{
							TF2Items_SetClassname(hItem3, "tf_weapon_syringegun_medic");
							if(weaponToUse == -1)
								weaponToUse = 17;
							TF2Items_SetItemIndex(hItem3, weaponToUse);
							}
						case TFClass_Heavy:{
							TF2Items_SetClassname(hItem3, "tf_weapon_minigun");
							if(weaponToUse == -1)
								weaponToUse = 15;
							TF2Items_SetItemIndex(hItem3, weaponToUse);
							}
						case TFClass_Pyro:{
							TF2Items_SetClassname(hItem3, "tf_weapon_flamethrower");
							if(weaponToUse == -1)
								weaponToUse = 21;
							TF2Items_SetItemIndex(hItem3, weaponToUse);
							}
						case TFClass_Engineer:{
							TF2Items_SetClassname(hItem3, "tf_weapon_shotgun_primary");
							if(weaponToUse == -1)
								weaponToUse = 9;
							TF2Items_SetItemIndex(hItem3, weaponToUse);
							}
						}
					TF2Items_SetLevel(hItem3, 69);
					TF2Items_SetQuality(hItem3, 6);
					TF2Items_SetAttribute(hItem3, 0, 150, 1.0); //Turn to gold on kill
					TF2Items_SetNumAttributes(hItem3, 1);
					new iWeapon3 = TF2Items_GiveNamedItem(client, hItem3);
					CloseHandle(hItem3);
					EquipPlayerWeapon(client, iWeapon3);
				}
			}
		TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
		//disable medic guns heal
		if(g_disablemedicgunheal)
		if (iClass == TFClass_Medic){
		    TF2Attrib_SetByName(client, "heal rate penalty", 0.0);
		    TF2Attrib_SetByName(client, "ubercharge rate penalty", 0.0);
		}
		if(g_disablelunchheal)
		    if(iClass == TFClass_Heavy)
			    TF2Attrib_SetByName(client, "lunchbox healing decreased", 0.0);
		if(g_disablespycloack)
		    TF2Attrib_SetByName(client, "mod_disguise_consumes_cloak", 1.0);
		}
	}
}

/* OnPlayerSpawn()
**
** Here we enable the glow (if we need to), we set the spy cloak and we move the death player.
** -------------------------------------------------------------------------- */
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_disablefalldamage)
			TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
		new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		if (cond & PLAYERCOND_SPYCLOAK)
		{
			SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
		}
		if(GetClientTeam(client) == TEAM_BLUE && client != g_lastdeath)
		{
			ChangeAliveClientTeam(client, TEAM_RED);
			CreateTimer(0.2, RespawnRebalanced,  GetClientUserId(client));
		}
		if(g_onPreparation)
			SetEntityMoveType(client, MOVETYPE_NONE);	
		
	}
}

/* Disable Self Damage
**
** Here we disable damage by yourself
** -------------------------------------------------------------------------- */

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
 {
	if (g_disableselfdamage) {
	  if(client == attacker)
	  {
			return Plugin_Handled;
	  }
	}
	return Plugin_Continue;
 }
 
/* OnPlayerDeath()
**
** Here we reproduce sounds if needed and activate the glow effect if needed
** -------------------------------------------------------------------------- */
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap)
	{
		if(!g_onPreparation)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new aliveRunners = GetAlivePlayersCount(TEAM_RED,client);
			if(GetClientTeam(client) == TEAM_RED && aliveRunners > 0)
				EmitRandomSound(g_SndOnDeath,client);
				
			if(aliveRunners == 1)
				EmitRandomSound(g_SndLastAlive,GetLastPlayer(TEAM_RED,client));
				
			new currentDeath = GetLastPlayer(TEAM_BLUE);
			if(currentDeath > 0 && currentDeath <= MaxClients && IsClientInGame(currentDeath))
				SetEventInt(event,"attacker",GetClientUserId(currentDeath));
			if(g_canEmitSoundToDeath)
			{
				if(currentDeath > 0 && currentDeath <= MaxClients)
					EmitRandomSound(g_SndOnKill,currentDeath);
				g_canEmitSoundToDeath = false;
				CreateTimer(g_OnKillDelay, ReenableDeathSound);
			}
			
			
			if(aliveRunners == g_runner_outline)
				for(new i=1 ; i<=MaxClients ; i++)
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) == TEAM_RED)
						SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
					
			if(aliveRunners == g_death_outline)
				for(new i=1 ; i<=MaxClients ; i++)
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) == TEAM_BLUE)
						SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
					
			if(!g_MeleeOnly){
				new SetHPBlue = GetClientHealth(currentDeath);
				TF2Attrib_RemoveByName(currentDeath, "max health additive bonus");
				SetEntityHealth(currentDeath,g_defauldhpblue);
				new HealthBlue = GetClientHealth(currentDeath);
				if((aliveRunners>=20)&&(aliveRunners<30)){
					HealthBlue = 1700-HealthBlue;
					TF2Attrib_SetByName(currentDeath,"max health additive bonus",float(HealthBlue));
					SetEntityHealth(currentDeath,SetHPBlue);
			    }
				if((aliveRunners>=15)&&(aliveRunners<20)){
					HealthBlue = 1500-HealthBlue;
					TF2Attrib_SetByName(currentDeath,"max health additive bonus",float(HealthBlue));
					SetEntityHealth(currentDeath,SetHPBlue);
			    }
				if((aliveRunners>=10)&&(aliveRunners<15)){
					HealthBlue = 1000-HealthBlue;
					TF2Attrib_SetByName(currentDeath,"max health additive bonus",float(HealthBlue));
					SetEntityHealth(currentDeath,SetHPBlue);
			    }
				if((aliveRunners>=5)&&(aliveRunners<10)){
					HealthBlue = 700-HealthBlue;
					TF2Attrib_SetByName(currentDeath,"max health additive bonus",float(HealthBlue));
					SetEntityHealth(currentDeath,SetHPBlue);
			    }
				if((aliveRunners>=2)&&(aliveRunners<5)){
					HealthBlue = 500-HealthBlue;
					TF2Attrib_SetByName(currentDeath,"max health additive bonus",float(HealthBlue));
					SetEntityHealth(currentDeath,SetHPBlue);
		        }
				if(aliveRunners == 1){
					HealthBlue = 200-HealthBlue;
					TF2Attrib_SetByName(currentDeath,"max health additive bonus",float(HealthBlue));
					SetEntityHealth(currentDeath,SetHPBlue);
			    }
			}
		}
		
	}
	return Plugin_Continue;
}


public Action:ReenableDeathSound(Handle:timer, any:data)
{
	g_canEmitSoundToDeath = true;
}


/* BalanceTeams()
**
** Moves players to their new team in this round.
** -------------------------------------------------------------------------- */
stock BalanceTeams()
{
	if (g_isDRmap){
	if(GetClientCount(true) > 4)
	{
		new maxPionts = 1;
		for (new i = 1; i <= MaxClients; i++){
		if ((maxPionts < g_queue_Priory[i])&&(IsClientConnected(i))&&(IsClientInGame(i))){
			if(g_dontBeDeath[i] == DBD_ON || g_dontBeDeath[i] == DBD_THISMAP)
			     continue;
			 else
		    maxPionts = g_queue_Priory[i];
		}
		}
		new new_death = -1;
		for (new i = 1; i <= MaxClients; i++){
			if ((maxPionts == g_queue_Priory[i])&&(IsClientConnected(i))&&(IsClientInGame(i))) {
              if(g_dontBeDeath[i] == DBD_ON || g_dontBeDeath[i] == DBD_THISMAP)
			     continue;
			 else
		         new_death = i;
			}
		}
		
		if(new_death == -1)
		{
			CPrintToChatAll("{black}[DR]{DEFAULT} Couldn't found a valid Death.");
			return;
		}
		g_lastdeath  = new_death;
		new team;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || !IsClientInGame(i))
				continue;
			team = GetClientTeam(i);
			if(team != TEAM_BLUE && team != TEAM_RED)
				continue;
				
			if(i == new_death)
			{
				if(team != TEAM_BLUE)
				ChangeAliveClientTeam(i, TEAM_BLUE);
				
				new TFClassType:iClass = TF2_GetPlayerClass(i);
				if (iClass == TFClass_Unknown)
				{
					TF2_SetPlayerClass(i, TFClass_Scout, false, true);
				}
				g_queue_Priory[i] = 1;
			}
			else if(team != TEAM_RED )
			{
				ChangeAliveClientTeam(i, TEAM_RED);
			}
			CreateTimer(0.2, RespawnRebalanced,  GetClientUserId(i));
		}
		if(!IsClientConnected(new_death) || !IsClientInGame(new_death)) 
		{
			CPrintToChatAll("{black}[DR]{DEFAULT} Death isn't in game.");
			return;
		}
		
		CPrintToChatAll("{black}[DR]{gold}%N {DEFAULT}is the Death", new_death);
		//g_timesplayed_asdeath[g_lastdeath]++;

	}
	else
	if (GetClientCount(true) <= 4) 
	{
		CPrintToChatAll("{black}[DR]{DEFAULT} Few people, don't be death setting is disabled");
		new maxPionts = 1;
		for (new i = 1; i <= MaxClients; i++){
		    if ((maxPionts < g_queue_Priory[i])&&(IsClientConnected(i))&&(IsClientInGame(i))){
		        maxPionts = g_queue_Priory[i];
		    }
		}
		new new_death = -1;
		for (new i = 1; i <= MaxClients; i++){
			if ((maxPionts == g_queue_Priory[i])&&(IsClientConnected(i))&&(IsClientInGame(i))) {
		        new_death = i;
			}
		}
		
		if(new_death == -1)
		{
			CPrintToChatAll("{black}[DR]{DEFAULT} Couldn't found a valid Death.");
			return;
		}
		g_lastdeath  = new_death;
		new team;
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || !IsClientInGame(i))
				continue;
			team = GetClientTeam(i);
			if(team != TEAM_BLUE && team != TEAM_RED)
				continue;
				
			if(i == new_death)
			{
				if(team != TEAM_BLUE)
				ChangeAliveClientTeam(i, TEAM_BLUE);
				
				new TFClassType:iClass = TF2_GetPlayerClass(i);
				if (iClass == TFClass_Unknown)
				{
					TF2_SetPlayerClass(i, TFClass_Scout, false, true);
				}
				g_queue_Priory[i] = 1;
			}
			else if(team != TEAM_RED )
			{
				ChangeAliveClientTeam(i, TEAM_RED);
			}
			CreateTimer(0.2, RespawnRebalanced,  GetClientUserId(i));
		}
		if(!IsClientConnected(new_death) || !IsClientInGame(new_death)) 
		{
			CPrintToChatAll("{black}[DR]{DEFAULT} Death isn't in game.");
			return;
		}
		
		CPrintToChatAll("{black}[DR]{gold}%N {DEFAULT}is the Death", new_death);
		//g_timesplayed_asdeath[g_lastdeath]++;
		}
	else
	if (GetClientCount(true) < 2)
	{
		CPrintToChatAll("{black}[DR]{DEFAULT} This game-mode requires at least two people to start");
	}
	}
}

/* OnGameFrame()
**
** We set the player max speed on every frame, and also we set the spy's cloak, scout drink and charge demoshield on empty.
** -------------------------------------------------------------------------- */
public OnGameFrame()
{
	if(g_isDRmap)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == TEAM_RED )
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", g_runner_speed);
				else 
					if(GetClientTeam(i) == TEAM_BLUE)
					   SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", g_death_speed);
				// if you want disable spy cloack, set "DisableSpyCloack" "1" in deathrun.cfg
				if (g_disablespycloack)
					if(TF2_GetPlayerClass(i) == TFClass_Spy)
						SetCloak(i, 1.0);
				// if you want disable scout drink, set "DisableScoutDrink" "1" in deathrun.cfg
				if (g_disablescoutdrink)
					if(TF2_GetPlayerClass(i) == TFClass_Scout)
						SetDrink(i, 0.1);
				// if you want disable demo shield, set "DisableDemoShield" "1" in deathrun.cfg
				if (g_disabledemoshield)
					if ((TF2_GetPlayerClass(i) == TFClass_DemoMan) && (!TF2_IsPlayerInCondition(i, TFCond_Charging)))
					    SetCharge(i,1.0);
			}
		}
	}
}

/* TF2_SwitchtoSlot()
**
** Changes the client's slot to the desired one.
** -------------------------------------------------------------------------- */
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}
/* SetCloak()
**
** Function used to set the spy's cloak meter.
** -------------------------------------------------------------------------- */
stock SetCloak(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", value);
}

stock SetDrink(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", value);
}

stock SetCharge(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", value);
}
/* RespawnRebalanced()
**
** Timer used to spawn a client if he/she is in game and if it isn't alive.
** -------------------------------------------------------------------------- */
public Action:RespawnRebalanced(Handle:timer, any:data)
{
	new client = GetClientOfUserId(data);
	if(IsClientInGame(client))
	{
		if(!IsPlayerAlive(client))
		{
			TF2_RespawnPlayer(client);
		}
	}
}

/* OnConfigsExecuted()
**
** Here we get the default values of the CVars that the plugin is going to modify.
** -------------------------------------------------------------------------- */
public OnConfigsExecuted()
{
	dr_queue_def= GetConVarInt(dr_queue);
	dr_unbalance_def = GetConVarInt(dr_unbalance);
	dr_autobalance_def = GetConVarInt(dr_autobalance);
	dr_firstblood_def = GetConVarInt(dr_firstblood);
	dr_scrambleauto_def = GetConVarInt(dr_scrambleauto);
	dr_airdash_def = GetConVarInt(dr_airdash);
	dr_push_def = GetConVarInt(dr_push);
}

/* SetupCvars()
**
** Modify several values of the CVars that the plugin needs to work properly.
** -------------------------------------------------------------------------- */
public SetupCvars()
{
	SetConVarInt(dr_queue, 0);
	SetConVarInt(dr_unbalance, 0);
	SetConVarInt(dr_autobalance, 0);
	SetConVarInt(dr_firstblood, 0);
	SetConVarInt(dr_scrambleauto, 0);
	SetConVarInt(dr_airdash, 0);
	SetConVarInt(dr_push, 0);
}

/* ResetCvars()
**
** Reset the values of the CVars that the plugin used to their default values.
** -------------------------------------------------------------------------- */
public ResetCvars()
{
	SetConVarInt(dr_queue, dr_queue_def);
	SetConVarInt(dr_unbalance, dr_unbalance_def);
	SetConVarInt(dr_autobalance, dr_autobalance_def);
	SetConVarInt(dr_firstblood, dr_firstblood_def);
	SetConVarInt(dr_scrambleauto, dr_scrambleauto_def);
	SetConVarInt(dr_airdash, dr_airdash_def);
	SetConVarInt(dr_push, dr_push_def);
	
	//We clear the tries
	//ProcessListeners(true);
	ClearTrie(g_RestrictedWeps);
	ClearTrie(g_AllClassWeps);
	ClearTrie(g_CmdList);
	// ClearTrie(g_CmdTeamToBlock);
	// ClearTrie(g_CmdBlockOnlyOnPrep);
	ClearTrie(g_SndRoundStart);
	ClearTrie(g_SndOnDeath);
	ClearTrie(g_SndOnKill);
	ClearTrie(g_SndLastAlive);
}

/* Command_Block()
**
** Blocks a command, check teams and if it's on preparation.
** -------------------------------------------------------------------------- 
public Action:Command_Block(client, const String:command[], argc)
{
	if(g_isDRmap)
	{
		new PreparationOnly, blockteam;
		GetTrieValue(g_CmdBlockOnlyOnPrep,command,PreparationOnly);
		//If the command must be blocked only on preparation 
		//and we aren't on preparation time, we let the client run the command.
		if(!g_onPreparation && PreparationOnly == 1)
			return Plugin_Stop;
		
		GetTrieValue(g_CmdTeamToBlock,command,blockteam);
		//If the client has the same team as "g_CmdTeamToBlock" 
		//or it's for both teams, we block the command.
		if(GetClientTeam(client) == blockteam  || blockteam == 1)
			return Plugin_Stop;
		
	}
	return Plugin_Continue;
}
*/

/* EmitRandomSound()
**
** Emits a random sound from a trie, it will be emitted for everyone is a client isn't passed.
** -------------------------------------------------------------------------- */
stock EmitRandomSound(Handle:sndTrie,client = -1)
{
	new trieSize = GetTrieSize(sndTrie);
	
	new String:key[4], String:sndFile[PLATFORM_MAX_PATH];
	IntToString(GetRandomInt(1,trieSize),key,sizeof(key));

	if(GetTrieString(sndTrie,key,sndFile,sizeof(sndFile)))
	{
		if(StrEqual(sndFile, ""))
			return;
			
		if(client != -1)
		{
			if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
				EmitSoundToClient(client,sndFile,_,_, SNDLEVEL_TRAIN);
			else
				return;
		}
		else	
			EmitSoundToAll(sndFile, _, _, SNDLEVEL_TRAIN);
	}
}

stock GetAlivePlayersCount(team,ignore=-1) 
{ 
	new count = 0, i;

	for( i = 1; i <= MaxClients; i++ ) 
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team && i != ignore) 
			count++; 

	return count; 
}  

stock GetLastPlayer(team,ignore=-1) 
{ 
	for(new i = 1; i <= MaxClients; i++ ) 
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team && i != ignore) 
			return i;
	return -1;
}  

stock ChangeAliveClientTeam(client, newTeam)
{
	new oldTeam = GetClientTeam(client);

	if (oldTeam != newTeam)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, newTeam);
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
		TF2_RespawnPlayer(client);
	}
}
/* DisableBuilds
**
** Disable engineer buidls.
** -------------------------------------------------------------------------- */
public Action:CommandListener_Build(client, const String:command[], argc)
{	
if (!g_disableallbuilds){
	decl String:sObjectMode[2], String:sObjectType[2];
	GetCmdArg(1, sObjectType, sizeof(sObjectType));
	GetCmdArg(2, sObjectMode, sizeof(sObjectMode));
	new iObjectMode = StringToInt(sObjectMode), iObjectType = StringToInt(sObjectType);
	if (g_disabledispenser)
		if ((iObjectType == 0) && (iObjectMode == 0))
			return Plugin_Handled;
	if (g_disablesentry)
		if ((iObjectType == 2) && (iObjectMode == 0))
			return Plugin_Handled;
	if (g_disableteleportentr)
		if ((iObjectType == 1) && (iObjectMode == 0))
			return Plugin_Handled;
	if (g_disableteleportexit)
		if ((iObjectType == 1) && (iObjectMode == 1))
			return Plugin_Handled;
}
	
return Plugin_Continue;
}

/* OnDeathChangeTeam
**
** When death chage team we change death.
** -------------------------------------------------------------------------- */
public Action:OnDeathChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_isDRmap){
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetEventInt(event, "team");
		TF2Attrib_RemoveByName(client, "max health additive bonus");
		if (g_onPreparation) {
		    if ((client == g_lastdeath)&&((team == TEAM_RED)||(team == TEAM_SPECTATOR)))
			    BalanceTeams();
	}
	}
	return Plugin_Continue;
}

/* OnDeathChangeTeam
**
** Add "points" on red team when round end.
** -------------------------------------------------------------------------- */
public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	if(team == TEAM_RED){
		for(new i = 1; i <= MaxClients; i++){
			if ((IsClientInGame(i))&&(IsClientConnected(i))&&(GetClientTeam(i) == TEAM_RED)){
				g_queue_Priory[i] = g_queue_Priory[i]+10;
				if (IsPlayerAlive(i))
					g_queue_Priory[i] = g_queue_Priory[i]+10;
		    }
		}
	}
}
		