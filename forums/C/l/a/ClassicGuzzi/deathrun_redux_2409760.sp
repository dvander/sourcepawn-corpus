// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>
#include <morecolors>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
//#include <steamtools>
#include <tf2attributes>
#include <clientprefs>

#pragma newdecls required

// ---- Defines ----------------------------------------------------------------
#define DR_VERSION "0.2.1"
#define PLAYERCOND_SPYCLOAK (1<<4)
#define MAXGENERIC 25	//Used as a limit in the config file

#define TEAM_RED 2
#define TEAM_BLUE 3

#define DBD_UNDEF -1 //DBD = Don't Be Death
#define DBD_OFF 1
#define DBD_ON 2
#define DBD_THISMAP 3 // The cookie will never have this value
#define TIME_TO_ASK 30.0 //Delay between asking the client its preferences and it's connection/join.

// ---- Variables --------------------------------------------------------------
bool g_isDRmap = false;
int g_lastdeath = -1;
int g_timesplayed_asdeath[MAXPLAYERS + 1];
bool g_onPreparation = false;
int g_dontBeDeath[MAXPLAYERS+1] =
{	DBD_UNDEF,...};
bool g_canEmitSoundToDeath = true;

//GenerealConfig
bool g_diablefalldamage;
bool g_finishoffrunners;
float g_runner_speed;
float g_death_speed;
int g_runner_outline;
int g_death_outline;

//Weapon-config
bool g_MeleeOnly;
bool g_MeleeRestricted;
bool g_RestrictAll;
Handle g_RestrictedWeps;
bool g_UseDefault;
bool g_UseAllClass;
Handle g_AllClassWeps;

//Command-config
Handle g_CmdList;
Handle g_CmdTeamToBlock;
Handle g_CmdBlockOnlyOnPrep;

//Sound-config
Handle g_SndRoundStart;
Handle g_SndOnDeath;
float g_OnKillDelay;
Handle g_SndOnKill;
Handle g_SndLastAlive;

// ---- Handles ----------------------------------------------------------------
Handle g_DRCookie = INVALID_HANDLE;

// ---- Server's CVars Management ----------------------------------------------
Handle dr_queue;
Handle dr_unbalance;
Handle dr_autobalance;
Handle dr_firstblood;
Handle dr_scrambleauto;
Handle dr_airdash;
Handle dr_push;

int dr_queue_def = 0;
int dr_unbalance_def = 0;
int dr_autobalance_def = 0;
int dr_firstblood_def = 0;
int dr_scrambleauto_def = 0;
int dr_airdash_def = 0;
int dr_push_def = 0;

// ---- Plugin's Information ---------------------------------------------------
public Plugin myinfo =
{	
	name = "[TF2] Deathrun Redux",
	author = "Classic",
	description = "Deathrun plugin for TF2",
	version = DR_VERSION,
	url = "http://www.clangs.com.ar"
};

/* OnPluginStart()
 **
 ** When the plugin is loaded.
 ** -------------------------------------------------------------------------- */
public void OnPluginStart()
{	
	//Cvars
	CreateConVar("sm_dr_version", DR_VERSION, "Death Run Redux Version.", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	//Creation of Tries
	g_RestrictedWeps = CreateTrie();
	g_AllClassWeps = CreateTrie();
	g_CmdList = CreateTrie();
	g_CmdTeamToBlock = CreateTrie();
	g_CmdBlockOnlyOnPrep = CreateTrie();
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

	//Targets
	AddMultiTargetFilter("@runner", FilterTarget, "runners", false);
	AddMultiTargetFilter("@runners", FilterTarget, "runners", false);
	AddMultiTargetFilter("@aliverunners", FilterTarget, "alive runners", false);
	AddMultiTargetFilter("@death", FilterTarget, "death", false);

	//Preferences
	g_DRCookie = RegClientCookie("DR_dontBeDeath", "Does the client want to be the Death?", CookieAccess_Private);
	for (int i = 1; i <= MaxClients; i++)
	{	
		if (!AreClientCookiesCached(i))
		{	
			continue;
		}
		OnClientCookiesCached(i);
	}
	RegConsoleCmd("drtoggle", BeDeathMenu);
}

/* OnPluginEnd()
 **
 ** When the plugin is unloaded. Here we reset all the cvars to their normal value.
 ** -------------------------------------------------------------------------- */
public void OnPluginEnd()
{	
	//Targets
	RemoveMultiTargetFilter("@runner", FilterTarget);
	RemoveMultiTargetFilter("@runners", FilterTarget);
	RemoveMultiTargetFilter("@aliverunners", FilterTarget);
	RemoveMultiTargetFilter("@death", FilterTarget);
	ResetCvars();
}

/* OnMapStart()
 **
 ** Here we reset every global variable, and we check if the current map is a deathrun map.
 ** If it is a dr map, we get the cvars def. values and the we set up our own values.
 ** -------------------------------------------------------------------------- */
public void OnMapStart()
{	
	g_lastdeath = -1;
	for(int i = 1; i <= MaxClients; i++)
	g_timesplayed_asdeath[i]=-1;

	char mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	if (strncmp(mapname, "dr_", 3, false) == 0 || strncmp(mapname, "deathrun_", 9, false) == 0 || strncmp(mapname, "vsh_dr_", 6, false) == 0 || strncmp(mapname, "vsh_deathrun_", 6, false) == 0)
	{	
		LogMessage("Deathrun map detected. Enabling Deathrun Gamemode.");
		g_isDRmap = true;
//		Steam_SetGameDescription("DeathRun Redux");
		AddServerTag("deathrun");
		for (int i = 1; i <= MaxClients; i++)
		{	
			if (!AreClientCookiesCached(i))
			{	
				continue;
			}
			OnClientCookiesCached(i);
		}
		LoadConfigs();
		PrecacheFiles();
		ProcessListeners();
	}
	else
	{	
		LogMessage("Current map is not a deathrun map. Disabling Deathrun Gamemode.");
		g_isDRmap = false;
//		Steam_SetGameDescription("Team Fortress");	
		RemoveServerTag("deathrun");
	}
}

/* OnMapEnd()
 **
 ** Here we reset the server's cvars to their default values.
 ** -------------------------------------------------------------------------- */
public void OnMapEnd()
{	
	ResetCvars();
	for (int i = 1; i <= MaxClients; i++)
	{	
		g_dontBeDeath[i] = DBD_UNDEF;
	}
}

/* LoadConfigs()
 **
 ** Here we parse the data/deathrun/deathrun.cfg
 ** -------------------------------------------------------------------------- */
void LoadConfigs()
{
	//--DEFAULT VALUES--
	//GenerealConfig
	g_diablefalldamage = false;
	g_finishoffrunners = true;
	g_runner_speed = 300.0;
	g_death_speed = 400.0;
	g_runner_outline = 0;
	g_death_outline = -1;

	//Weapon-config
	g_MeleeOnly = true;
	g_MeleeRestricted = true;
	g_RestrictAll = true;
	ClearTrie(g_RestrictedWeps);
	g_UseDefault = true;
	g_UseAllClass = false;
	ClearTrie(g_AllClassWeps);

	//Command-config
	ClearTrie(g_CmdList);
	ClearTrie(g_CmdTeamToBlock);
	ClearTrie(g_CmdBlockOnlyOnPrep);

	//Sound-config
	ClearTrie(g_SndRoundStart);
	ClearTrie(g_SndOnDeath);
	g_OnKillDelay = 5.0;
	ClearTrie(g_SndOnKill);
	ClearTrie(g_SndLastAlive);

	char mainfile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, mainfile, sizeof(mainfile), "data/deathrun/deathrun.cfg");

	if(!FileExists(mainfile))
	{
		SetFailState("Configuration file %s not found!", mainfile);
		return;
	}
	KeyValues kv = CreateKeyValues("deathrun");
	if(!kv.ImportFromFile(mainfile))
	{
		delete kv;
		SetFailState("Improper structure for configuration file %s!", mainfile);
		return;
	}
	if(!kv.JumpToKey("default"))
	{
		g_diablefalldamage = !!kv.GetNum("DisableFallDamage", g_diablefalldamage);
		g_finishoffrunners = !!kv.GetNum("FinishOffRunners", g_finishoffrunners);
		if(kv.JumpToKey("speed"))
		{
			g_runner_speed = kv.GetFloat("runners", g_runner_speed);
			g_death_speed = kv.GetFloat("death", g_death_speed);
			kv.GoBack();
		}

		if(kv.JumpToKey("outline"))
		{
			g_runner_outline = kv.GetNum("runners", g_runner_outline);
			g_death_outline = kv.GetNum("death", g_death_outline);
			kv.GoBack();
		}
		kv.GoBack();
	}

	kv.Rewind();
	if(kv.JumpToKey("weapons"))
	{
		g_MeleeOnly = !!kv.GetNum("MeleeOnly", g_MeleeOnly);
		if(g_MeleeOnly)
		{
			g_MeleeRestricted = !!kv.GetNum("RestrictedMelee", g_MeleeRestricted);
			if(g_MeleeRestricted)
			{
				kv.JumpToKey("MeleeRestriction");
				g_RestrictAll = !!kv.GetNum("RestrictAll", g_RestrictAll);
				if(!g_RestrictAll)
				{
					kv.JumpToKey("RestrictedWeapons");
					char key[4], auxInt;
					for(int i = 1; i < MAXGENERIC; i++)
					{
						IntToString(i, key, sizeof(key));
						auxInt = kv.GetNum(key, -1);
						if(auxInt == -1)
						{
							break;
						}
						SetTrieValue(g_RestrictedWeps, key, auxInt);
					}
					kv.GoBack();
				}
				g_UseDefault = !!kv.GetNum("UseDefault", g_UseDefault);
				g_UseAllClass = !!kv.GetNum("UseAllClass", g_UseAllClass);
				if(g_UseAllClass)
				{
					kv.JumpToKey("AllClassWeapons");
					char key[4], auxInt;
					for(int i = 1; i < MAXGENERIC; i++)
					{
						IntToString(i, key, sizeof(key));
						auxInt = kv.GetNum(key, -1);
						if(auxInt == -1)
						{
							break;
						}
						SetTrieValue(g_AllClassWeps, key, auxInt);
					}
					kv.GoBack();
				}
				kv.GoBack();
			}

		}
	}

	kv.Rewind();
	kv.JumpToKey("blockcommands");
	do
	{
		char SectionName[128], CommandName[128];
		int onprep, teamToBlock;
		bool onrunners, ondeath;

		kv.GotoFirstSubKey();
		kv.GetSectionName(SectionName, sizeof(SectionName));

		kv.GetString("command", CommandName, sizeof(CommandName));
		onprep = kv.GetNum("OnlyOnPreparation", 0);
		onrunners = !!kv.GetNum("runners", 1);
		ondeath = !!kv.GetNum("death", 1);

		teamToBlock = 0;
		if((onrunners && ondeath))
		{
			teamToBlock = 1;
		} else if(onrunners && !ondeath)
		{
			teamToBlock = TEAM_RED;
		} else if(!onrunners && ondeath)
		{
			teamToBlock = TEAM_BLUE;
		}

		if(!StrEqual(CommandName, "") || teamToBlock == 0)
		{
			SetTrieString(g_CmdList, SectionName, CommandName);
			SetTrieValue(g_CmdBlockOnlyOnPrep, CommandName, onprep);
			SetTrieValue(g_CmdTeamToBlock, CommandName, teamToBlock);
		}
	} while(kv.GotoNextKey());

	kv.Rewind();
	if(kv.JumpToKey("sounds"))
	{
		char key[4], sndFile[PLATFORM_MAX_PATH];
		if(kv.JumpToKey("RoundStart"))
		{
			for(int i = 1; i < MAXGENERIC; i++)
			{
				IntToString(i, key, sizeof(key));
				kv.GetString(key, sndFile, sizeof(sndFile), "");
				if(StrEqual(sndFile, ""))
				{
					break;
				}
				SetTrieString(g_SndRoundStart, key, sndFile);
			}
			kv.GoBack();
		}

		if(kv.JumpToKey("OnDeath"))
		{
			for(int i = 1; i < MAXGENERIC; i++)
			{
				IntToString(i, key, sizeof(key));
				kv.GetString(key, sndFile, sizeof(sndFile), "");
				if(StrEqual(sndFile, ""))
				{
					break;
				}
				SetTrieString(g_SndOnDeath, key, sndFile);
			}
			kv.GoBack();
		}

		if(kv.JumpToKey("OnKill"))
		{

			g_OnKillDelay = kv.GetFloat("delay", g_OnKillDelay);
			for(int i = 1; i < MAXGENERIC; i++)
			{
				IntToString(i, key, sizeof(key));
				kv.GetString(key, sndFile, sizeof(sndFile), "");
				if(StrEqual(sndFile, ""))
				{
					break;
				}
				SetTrieString(g_SndOnKill, key, sndFile);
			}
			kv.GoBack();
		}

		if(kv.JumpToKey("LastAlive"))
		{
			for(int i = 1; i < MAXGENERIC; i++)
			{
				IntToString(i, key, sizeof(key));
				kv.GetString(key, sndFile, sizeof(sndFile), "");
				if(StrEqual(sndFile, ""))
				{
					break;
				}
				SetTrieString(g_SndLastAlive, key, sndFile);
			}
			kv.GoBack();
		}
		kv.GoBack();
	}

	kv.Rewind();
	delete kv;

	char mapfile[PLATFORM_MAX_PATH], mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	BuildPath(Path_SM, mapfile, sizeof(mapfile), "data/deathrun/maps/%s.cfg", mapname);
	if(FileExists(mapfile))
	{
		kv = CreateKeyValues("drmap");
		if(!kv.ImportFromFile(mapfile))
		{
			SetFailState("Improper structure for configuration file %s!", mapfile);
			return;
		}

		g_diablefalldamage = !!kv.GetNum("DisableFallDamage", g_diablefalldamage);
		g_finishoffrunners = !!kv.GetNum("FinishOffRunners", g_finishoffrunners);

		if(kv.JumpToKey("speed"))
		{
			g_runner_speed = kv.GetFloat("runners", g_runner_speed);
			g_death_speed = kv.GetFloat("death", g_death_speed);
			kv.GoBack();
		}
		if(kv.JumpToKey("outline"))
		{
			g_runner_outline = kv.GetNum("runners", g_runner_outline);
			g_death_outline = kv.GetNum("death", g_death_outline);
		}
		kv.Rewind();
		delete kv;
	}
}

/* PrecacheFiles()
 **
 ** We precache and add to the download table every sound file found on the config file.
 ** -------------------------------------------------------------------------- */
void PrecacheFiles()
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
void PrecacheSoundFromTrie(Handle sndTrie)
{
	int trieSize = GetTrieSize(sndTrie);
	char soundString[PLATFORM_MAX_PATH], downloadString[PLATFORM_MAX_PATH], key[4];
	for(int i = 1; i <= trieSize; i++)
	{
		IntToString(i, key, sizeof(key));
		if(GetTrieString(sndTrie, key, soundString, sizeof(soundString)))
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
 ** -------------------------------------------------------------------------- */
void ProcessListeners(bool removeListerners = false)
{
	int trieSize = GetTrieSize(g_CmdList);
	char command[PLATFORM_MAX_PATH], key[4];
	for(int i = 1; i <= trieSize; i++)
	{
		IntToString(i, key, sizeof(key));
		if(GetTrieString(g_CmdList, key, command, sizeof(command)))
		{
			if(StrEqual(command, ""))
			{
				break;
			}

			if(removeListerners)
			{
				RemoveCommandListener(Command_Block, command);
			} else
			{
				AddCommandListener(Command_Block, command);
			}
		}
	}
}

/* OnClientPutInServer()
 **
 ** We set on zero the time played as death when the client enters the server.
 ** -------------------------------------------------------------------------- */
public void OnClientPutInServer(int client)
{
	g_timesplayed_asdeath[client] = 0;
}

/* OnClientDisconnect()
 **
 ** We set as minus one the time played as death when the client leaves.
 ** When searching for a Death we ignore every client with the -1 value.
 ** We also set as undef the preference value
 ** -------------------------------------------------------------------------- */
public void OnClientDisconnect(int client)
{
	g_timesplayed_asdeath[client] =-1;
	g_dontBeDeath[client] = DBD_UNDEF;
}

/* OnClientCookiesCached()
 **
 ** We look if the client have a saved value
 ** -------------------------------------------------------------------------- */
public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, g_DRCookie, sValue, sizeof(sValue));
	int nValue = StringToInt(sValue);

	if( nValue != DBD_OFF && nValue != DBD_ON) //If cookie is not valid we ask for a preference.
	{
		CreateTimer(TIME_TO_ASK, AskMenuTimer, client);
	}
	else //client has a valid cookie
	{
		g_dontBeDeath[client] = nValue;
	}
}

public Action AskMenuTimer(Handle timer, int client)
{
	BeDeathMenu(client,0);
}

public Action BeDeathMenu(int client,int args)
{
	if (client == 0 || (!IsClientInGame(client)))
	{
		return Plugin_Handled;
	}
	Menu menu = new Menu(BeDeathMenuHandler);
	menu.SetTitle( "Be the Death toggle");
	menu.AddItem( "0", "Select me as Death");
	menu.AddItem( "1", "Don't select me as Death");
	menu.AddItem( "2", "Don't be Death in this map");
	menu.ExitButton = true;
	menu.Display(client, 30);

	return Plugin_Handled;
}

public int BeDeathMenuHandler(Menu menu, MenuAction action, int client, int buttonnum)
{
	if (action == MenuAction_Select)
	{
		if (buttonnum == 0)
		{
			g_dontBeDeath[client] = DBD_OFF;
			char sPref[2];
			IntToString(DBD_OFF, sPref, sizeof(sPref));
			SetClientCookie(client, g_DRCookie, sPref);
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can be selected as Death.");
		}
		else if (buttonnum == 1)
		{
			g_dontBeDeath[client] = DBD_ON;
			char sPref[2];
			IntToString(DBD_ON, sPref, sizeof(sPref));
			SetClientCookie(client, g_DRCookie, sPref);
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can't be selected as Death.");
		}
		else if (buttonnum == 2)
		{
			g_dontBeDeath[client] = DBD_THISMAP;
			CPrintToChat(client,"{black}[DR]{DEFAULT} You can't be selected as Death for this map.");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/* OnPrepartionStart()
 **
 ** We setup the cvars again, balance the teams and we freeze the players.
 ** -------------------------------------------------------------------------- */
public Action OnPrepartionStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_isDRmap)
	{
		g_onPreparation = true;

		//We force the cvars values needed every round (to override if any cvar was changed).
		SetupCvars();

		//We move the players to the corresponding team.
		BalanceTeams();

		//Players shouldn't move until the round starts
		for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityMoveType(i, MOVETYPE_NONE);
		}

		EmitRandomSound(g_SndRoundStart);
	}
}

/* OnRoundStart()
 **
 ** We unfreeze every player.
 ** -------------------------------------------------------------------------- */
public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_isDRmap)
	{
		for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntityMoveType(i, MOVETYPE_WALK);
			if((GetClientTeam(i) == TEAM_RED && g_runner_outline == 0)||(GetClientTeam(i) == TEAM_BLUE && g_death_outline == 0))
			{
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
		g_onPreparation = false;
	}
}

/* TF2Items_OnGiveNamedItem_Post()
 **
 ** Here we check for the demoshield and the sapper.
 ** -------------------------------------------------------------------------- */
public int TF2Items_OnGiveNamedItem_Post(int client, char[] classname,int index,int level, int quality, int ent)
{
	if(g_isDRmap && g_MeleeOnly)
	{
		if(StrEqual(classname,"tf_weapon_builder", false) || StrEqual(classname,"tf_wearable_demoshield", false))
		{
			CreateTimer(0.1, Timer_RemoveWep, EntIndexToEntRef(ent));
		}
	}
}

/* Timer_RemoveWep()
 **
 ** We kill the demoshield/sapper
 ** -------------------------------------------------------------------------- */
public Action Timer_RemoveWep(Handle timer, int ref)
{
	int ent = EntRefToEntIndex(ref);
	if( IsValidEntity(ent) && ent > MaxClients)
	{
		AcceptEntityInput(ent, "Kill");
	}
}

/* OnPlayerInventory()
 **
 ** Here we strip players weapons (if we have to).
 ** Also we give special melee weapons (again, if we have to).
 ** -------------------------------------------------------------------------- */
public Action OnPlayerInventory(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_isDRmap)
	{
		if(g_MeleeOnly)
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));

			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Grenade);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Building);
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_PDA);

			if(g_MeleeRestricted)
			{
				bool replacewep = false;
				if(g_RestrictAll)
				{
					replacewep=true;
				}
				else
				{
					int wepEnt = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
					int wepIndex = GetEntProp(wepEnt, Prop_Send, "m_iItemDefinitionIndex");
					int rwSize = GetTrieSize(g_RestrictedWeps);
					char key[4], auxIndex;
					for(int i = 1; i <= rwSize; i++)
					{
						IntToString(i,key,sizeof(key));
						if(GetTrieValue(g_RestrictedWeps,key,auxIndex))
						{
							if(wepIndex == auxIndex)
							{
								replacewep=true;
							}
						}
					}

				}
				if(replacewep)
				{
					TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
					int weaponToUse = -1;
					if(g_UseAllClass)
					{
						int acwSize = GetTrieSize(g_AllClassWeps);
						int rndNum;
						if(g_UseDefault)
						{
							rndNum = GetRandomInt(1,acwSize+1);
						}
						else
						{
							rndNum = GetRandomInt(1,acwSize);
						}

						if(rndNum <= acwSize)
						{
							char key[4];
							IntToString(rndNum,key,sizeof(key));
							GetTrieValue(g_AllClassWeps,key,weaponToUse);
						}

					}
					Handle hItem = TF2Items_CreateItem(FORCE_GENERATION | OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES);

					//Here we give a melee to every class
					int iClass = view_as<int>(TF2_GetPlayerClass(client));
					switch(iClass)
					{
						case TFClass_Scout:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_bat");
							if(weaponToUse == -1)
							{
								weaponToUse = 190;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case TFClass_Sniper:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_club");
							if(weaponToUse == -1)
							{
								weaponToUse = 193;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case TFClass_Soldier:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_shovel");
							if(weaponToUse == -1)
							{
								weaponToUse = 196;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case TFClass_DemoMan:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_bottle");
							if(weaponToUse == -1)
							{
								weaponToUse = 191;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case TFClass_Medic:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_bonesaw");
							if(weaponToUse == -1)
							{
								weaponToUse = 198;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case TFClass_Heavy:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_fists");
							if(weaponToUse == -1)
							{
								weaponToUse = 195;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case TFClass_Pyro:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_fireaxe");
							if(weaponToUse == -1)
							{
								weaponToUse = 192;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case TFClass_Spy:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_knife");
							if(weaponToUse == -1)
							{
								weaponToUse = 194;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
						case TFClass_Engineer:
						{
							TF2Items_SetClassname(hItem, "tf_weapon_wrench");
							if(weaponToUse == -1)
							{
								weaponToUse = 197;
							}
							TF2Items_SetItemIndex(hItem, weaponToUse);
						}
					}

					TF2Items_SetLevel(hItem, 69);
					TF2Items_SetQuality(hItem, 6);
					TF2Items_SetAttribute(hItem, 0, 150, 1.0); //Turn to gold on kill
					TF2Items_SetNumAttributes(hItem, 1);
					int iWeapon = TF2Items_GiveNamedItem(client, hItem);
					CloseHandle(hItem);

					EquipPlayerWeapon(client, iWeapon);
				}
			}
			TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
		}
	}
}

/* OnPlayerSpawn()
 **
 ** Here we enable the glow (if we need to), we set the spy cloak and we move the death player.
 ** -------------------------------------------------------------------------- */
public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_isDRmap)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(g_diablefalldamage)
		{
			TF2Attrib_SetByName(client, "cancel falling damage", 1.0);
		}
		if(g_MeleeOnly)
		{
			int cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");

			if (cond & PLAYERCOND_SPYCLOAK)
			{
				SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
			}
		}

		if(GetClientTeam(client) == TEAM_BLUE && client != g_lastdeath)
		{
			ChangeAliveClientTeam(client, TEAM_RED);
			CreateTimer(0.2, RespawnRebalanced, GetClientUserId(client));
		}

		if(g_onPreparation)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}

	}
}

/* OnPlayerDeath()
 **
 ** Here we reproduce sounds if needed and activate the glow effect if needed
 ** -------------------------------------------------------------------------- */
public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(g_isDRmap)
	{
		if(!g_onPreparation)
		{
			int client = GetClientOfUserId(GetEventInt(event, "userid"));
			int aliveRunners = GetAlivePlayersCount(TEAM_RED,client);

			if(GetClientTeam(client) == TEAM_RED && aliveRunners > 0)
			{
				EmitRandomSound(g_SndOnDeath,client);
			}

			if(aliveRunners == 1)
			{
				EmitRandomSound(g_SndLastAlive,GetLastPlayer(TEAM_RED,client));
			}

			int currentDeath = GetLastPlayer(TEAM_BLUE);
			if(currentDeath > 0 && currentDeath <= MaxClients && IsClientInGame(currentDeath) && g_finishoffrunners)
			{
				SetEventInt(event,"attacker",GetClientUserId(currentDeath));
			}
			if(g_canEmitSoundToDeath)
			{
				if(currentDeath > 0 && currentDeath <= MaxClients)
				EmitRandomSound(g_SndOnKill,currentDeath);
				g_canEmitSoundToDeath = false;
				CreateTimer(g_OnKillDelay, ReenableDeathSound);
			}

			if(aliveRunners == g_runner_outline)
			{

				for(int i=1; i<=MaxClients; i++)
				{
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) == TEAM_RED)
					{
						SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
					}
				}

			}

			if(aliveRunners == g_death_outline)
			{
				for(int i=1; i<=MaxClients; i++)
				{
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) == TEAM_BLUE)
					{
						SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
					}
				}
			}
		}

	}
	return Plugin_Continue;
}

public Action ReenableDeathSound(Handle timer, int data)
{
	g_canEmitSoundToDeath = true;
}

/* BalanceTeams()
 **
 ** Moves players to their int team in this round.
 ** -------------------------------------------------------------------------- */
stock void BalanceTeams()
{
	if(GetClientCount(true) > 1)
	{
		int new_death = GetRandomValid();
		if(new_death == -1)
		{
			CPrintToChatAll("{black}[DR]{DEFAULT} Couldn't found a valid Death.");
			return;
		}
		g_lastdeath = new_death;
		int team, i;
		for(i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i))
			{
				continue;
			}
			team = GetClientTeam(i);
			if(team != TEAM_BLUE && team != TEAM_RED)
			{
				continue;
			}

			if(i == new_death)
			{
				if(team != TEAM_BLUE)
				{
					ChangeAliveClientTeam(i, TEAM_BLUE);
				}

				int iClass = view_as<int>(TF2_GetPlayerClass(i));
				if(iClass == view_as<int>(TFClass_Unknown))
				{
					TF2_SetPlayerClass(i, TFClass_Scout, false, true);
				}
			} else if(team != TEAM_RED)
			{
				ChangeAliveClientTeam(i, TEAM_RED);
			}
			CreateTimer(0.2, RespawnRebalanced, GetClientUserId(i));
		}
		if(!IsClientConnected(new_death) || !IsClientInGame(new_death))
		{
			CPrintToChatAll("{black}[DR]{DEFAULT} Death isn't in game.");
			return;
		}
		CPrintToChatAll("{black}[DR]{gold}%N {DEFAULT}is the Death", new_death);
		g_timesplayed_asdeath[g_lastdeath]++;

	} else
	{
		CPrintToChatAll("{black}[DR]{DEFAULT} This game-mode requires at least two people to start");
	}
}

/* GetRandomValid()
 **
 ** Gets a random player that didn't play as death recently.
 ** -------------------------------------------------------------------------- */
public int GetRandomValid()
{
	int possiblePlayers[MAXPLAYERS+1];
	int possibleNumber = 0;
	int team;
	int min = GetMinTimesPlayed(false);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || i == g_lastdeath)
		{
			continue;
		}
		team = GetClientTeam(i);
		if(team != TEAM_BLUE && team != TEAM_RED)
		{
			continue;
		}
		if(g_timesplayed_asdeath[i] != min)
		{
			continue;
		}
		if(g_dontBeDeath[i] == DBD_ON || g_dontBeDeath[i] == DBD_THISMAP)
		{
			continue;
		}

		possiblePlayers[possibleNumber] = i;
		possibleNumber++;

	}

	//If there are zero people available we ignore the preferences.
	if(possibleNumber == 0)
	{
		min = GetMinTimesPlayed(true);
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || !IsClientInGame(i) || IsFakeClient(i) || i == g_lastdeath )
			{
				continue;
			}
			team = GetClientTeam(i);
			if(team != TEAM_BLUE && team != TEAM_RED)
			{
				continue;
			}
			if(g_timesplayed_asdeath[i] != min)
			{
				continue;
			}
			possiblePlayers[possibleNumber] = i;
			possibleNumber++;
		}
		if(possibleNumber == 0)
		{
			return -1;
		}
	}

	return possiblePlayers[ GetRandomInt(0,possibleNumber-1)];

}

/* GetMinTimesPlayed()
 **
 ** Get the minimum "times played", if ignorePref is true, we ignore the don't be death preference
 ** -------------------------------------------------------------------------- */
stock int GetMinTimesPlayed(bool ignorePref)
{
	int min = -1;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsClientInGame(i) || g_timesplayed_asdeath[i] == -1 || IsFakeClient(i))
		{
			continue;
		}
		if(i == g_lastdeath)
		{
			continue;
		}
		int team = GetClientTeam(i);
		if(team != TEAM_BLUE && team != TEAM_RED)
		{
			continue;
		}
		if(!ignorePref)
		{
			if(g_dontBeDeath[i] == DBD_ON || g_dontBeDeath[i] == DBD_THISMAP)
			{
				continue;
			}
		}
		if(min == -1)
		{
			min = g_timesplayed_asdeath[i];
		} else if(min > g_timesplayed_asdeath[i])
		{
			min = g_timesplayed_asdeath[i];
		}
	}
	return min;

}

/* OnGameFrame()
 **
 ** We set the player max speed on every frame, and also we set the spy's cloak on empty.
 ** -------------------------------------------------------------------------- */
public void OnGameFrame()
{
	if(g_isDRmap)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == TEAM_RED )
				{
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", g_runner_speed);
				}
				else if(GetClientTeam(i) == TEAM_BLUE)
				{
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", g_death_speed);
				}

				if(g_MeleeOnly)
				{
					if(TF2_GetPlayerClass(i) == TFClass_Spy)
					{
						SetCloak(i, 1.0);
					}
				}
			}
		}
	}
}

/* TF2_SwitchtoSlot()
 **
 ** Changes the client's slot to the desired one.
 ** -------------------------------------------------------------------------- */
stock void TF2_SwitchtoSlot(int client, int slot)
{
	if(slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char classname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if(wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
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
stock void SetCloak(int client, float value)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", value);
}

/* RespawnRebalanced()
 **
 ** Timer used to spawn a client if he/she is in game and if it isn't alive.
 ** -------------------------------------------------------------------------- */
public Action RespawnRebalanced(Handle timer, int data)
{
	int client = GetClientOfUserId(data);
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
public void OnConfigsExecuted()
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
public void SetupCvars()
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
public void ResetCvars()
{
	SetConVarInt(dr_queue, dr_queue_def);
	SetConVarInt(dr_unbalance, dr_unbalance_def);
	SetConVarInt(dr_autobalance, dr_autobalance_def);
	SetConVarInt(dr_firstblood, dr_firstblood_def);
	SetConVarInt(dr_scrambleauto, dr_scrambleauto_def);
	SetConVarInt(dr_airdash, dr_airdash_def);
	SetConVarInt(dr_push, dr_push_def);

	//We clear the tries
	ProcessListeners(true);
	ClearTrie(g_RestrictedWeps);
	ClearTrie(g_AllClassWeps);
	ClearTrie(g_CmdList);
	ClearTrie(g_CmdTeamToBlock);
	ClearTrie(g_CmdBlockOnlyOnPrep);
	ClearTrie(g_SndRoundStart);
	ClearTrie(g_SndOnDeath);
	ClearTrie(g_SndOnKill);
	ClearTrie(g_SndLastAlive);
}

/* FilterTarget()
 **
 ** Filters the clients if they are runners, aliverunners or the death.
 ** -------------------------------------------------------------------------- */
public bool FilterTarget(const char[] strPattern, Handle hClients)
{
	int team = TEAM_RED;
	bool aliveOnly = false;
	if(StrContains(strPattern, "death", false) != -1)
	{
		team = TEAM_BLUE;
	}
	if(StrContains(strPattern, "alive", false) != -1)
	{
		aliveOnly = true;
	}

	for(int i = 1; i <= MaxClients; i ++)
	{
		if(!IsClientInGame(i))
		{
			continue;
		}

		if(aliveOnly && !IsPlayerAlive(i))
		{
			continue;
		}

		if(GetClientTeam(i) != team)
		{
			continue;
		}

		PushArrayCell(hClients, i);
	}

	return true;
}

/* Command_Block()
 **
 ** Blocks a command, check teams and if it's on preparation.
 ** -------------------------------------------------------------------------- */
public Action Command_Block(int client, char[] command,int argc)
{
	if(g_isDRmap)
	{
		int PreparationOnly, blockteam;
		GetTrieValue(g_CmdBlockOnlyOnPrep,command,PreparationOnly);
		//If the command must be blocked only on preparation
		//and we aren't on preparation time, we let the client run the command.
		if(!g_onPreparation && PreparationOnly == 0)
		{
			return Plugin_Continue;
		}

		GetTrieValue(g_CmdTeamToBlock,command,blockteam);
		//If the client has the same team as "g_CmdTeamToBlock"
		//or it's for both teams, we block the command.
		if(GetClientTeam(client) == blockteam || blockteam == 1)
		{
			return Plugin_Stop;
		}

	}
	return Plugin_Continue;
}

/* EmitRandomSound()
 **
 ** Emits a random sound from a trie, it will be emitted for everyone is a client isn't passed.
 ** -------------------------------------------------------------------------- */
void EmitRandomSound(Handle sndTrie, int client = -1)
{
	int trieSize = GetTrieSize(sndTrie);

	char key[4], sndFile[PLATFORM_MAX_PATH];
	IntToString(GetRandomInt(1, trieSize), key, sizeof(key));

	if(GetTrieString(sndTrie, key, sndFile, sizeof(sndFile)))
	{
		if(StrEqual(sndFile, ""))
			return;

		if(client != -1)
		{
			if(client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
			{
				EmitSoundToClient(client, sndFile, _, _, SNDLEVEL_TRAIN);
			} else
			{
				return;
			}
		} else
		{
			EmitSoundToAll(sndFile, _, _, SNDLEVEL_TRAIN);
		}
	}
}

int GetAlivePlayersCount(int team, int ignore)
{
	int count = 0, i;

	for(i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team && i != ignore)
		{
			count++;
		}
	}

	return count;
}

int GetLastPlayer(int team, int ignore = -1)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team && i != ignore)
		{
			return i;
		}
	}
	return -1;
}

public void ChangeAliveClientTeam(int client,int newTeam)
{
	int oldTeam = GetClientTeam(client);

	if (oldTeam != newTeam)
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 2);
		ChangeClientTeam(client, newTeam);
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
		TF2_RespawnPlayer(client);
	}
}
