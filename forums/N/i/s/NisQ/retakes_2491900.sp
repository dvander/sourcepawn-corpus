#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <clientprefs>
#include <smlib>

#undef REQUIRE_PLUGIN
#include <updater>

public Plugin:myinfo = 
{
	name        = "Retakes",
	author      = "Ofir", 
	description = "Retake Simulation",
	version     = "1.5",
	url         = "https://forums.alliedmods.net/member.php?u=190571"
};

//Enums and Contstants
#define PREFIX " \x05[RETAKES]\x04 "
#define UPDATE_URL "https://www.dropbox.com/s/gfbtaoo902cftpy/update_info.txt"
#define SITEA 0
#define SITEB 1
#define MAXSPAWNS 64

#define FL_USED_Ct (1 << 0)
#define FL_USED_T (1 << 1)
#define GRENADESSETCOUNT 6

enum SpawnType
{
	None,
	Bomb,
	T,
	Ct
};

enum Spawn
{
	Id,
	SpawnType:Type,
	Float:Location[3],
	Float:Angles[3],
	Site,
	bool:Used
};

new const String:gs_GrenadeSets[][][64] = {
	{"weapon_hegrenade", "weapon_flashbang"},
	{"weapon_flashbang", "weapon_flashbang"},
	{"weapon_flashbang", "none"},
	{"weapon_smokegrenade", "none"},
	{"moli", "none"},
	{"none", "none"}
};

new gi_GrenadeSetsFlags[GRENADESSETCOUNT];

//Cvars Handlers
new Handle:gh_PistolRoundsCount = INVALID_HANDLE;
new Handle:gh_WinRowScramble = INVALID_HANDLE;
new Handle:gh_StrongPistolChance = INVALID_HANDLE;
new Handle:gh_DidntPlant = INVALID_HANDLE;

//Cvars Vars
new gi_PistolRoundsCount;
new gi_WinRowScramble;
new gi_StrongPistolChance;
new gi_DidntPlant;

//Players Arrays
new bool:gb_PreferenceLoaded[MAXPLAYERS+1] = {false, ...};
new gi_PistolPrefence[MAXPLAYERS+1] = {0, ...};
new gi_WantAwp[MAXPLAYERS+1] = {0, ...};
new bool:gb_WantSilencer[MAXPLAYERS+1] = {false, ...};
new gi_ChoosedSite[MAXPLAYERS+1];
new gi_DamageCount[MAXPLAYERS+1];
new gi_NextRoundTeam[MAXPLAYERS+1] = {-1, ...};
new bool:gb_Warnned[MAXPLAYERS+1] = {false, ...};
new bool:gb_PluginSwitchingTeam[MAXPLAYERS+1] = {false, ...};
new bool:gb_Voted[MAXPLAYERS+1] = {false, ...};
new Float:gf_UsedVP[MAXPLAYERS+1];

//Global Vars
new bool:gb_EditMode = false;
new bool:gb_Scrambling = false;
new bool:gb_WaitForPlayers = true;
new bool:gb_WarmUp = false;
new bool:gb_balancedTeams = false;
new bool:gb_newClientsJoined = false;
new bool:gb_BombPlanted = false;
new bool:gb_OnlyPistols = false;
new String:gs_CurrentMap[64];
new gi_MoneyOffset;
new gi_HelmetOffset;
new g_precacheLaser;
new g_precacheGlow;
new g_Spawns[MAXSPAWNS][Spawn];
new g_SpawnsCount = 0;
new gi_WinRowCounter = 0;
new gi_PlayerQueue[MAXPLAYERS+1];
new gi_QueueCounter;
new Float:gf_MapLoadTime;
new Float:gf_StartRoundTime;
new Handle:gh_MapLoadTimer;
new gi_Bomber;
new gi_Voters = 0;				// Total voters connected. Doesn't include fake clients.
new gi_Votes = 0;				// Total number of "say rtv" votes
new gi_VotesNeeded = 0;			// Necessary votes before map vote begins. (voters * percent_needed)

//Cookies
new Handle:gh_SilencedM4 = INVALID_HANDLE;
new Handle:gh_WantAwp = INVALID_HANDLE;
new Handle:gh_PistolPrefence = INVALID_HANDLE;

//Sql
new Handle:gh_Sql = INVALID_HANDLE;
new gi_ReconncetCounter = 0;

public OnPluginStart()
{
	//Convars
	gh_PistolRoundsCount = CreateConVar("retakes_pistols", "5", "How much Pistols Rounds should be. 0 to disable", _, true, 0.0);
	gh_WinRowScramble = CreateConVar("retakes_winrow", "7", "How much row the T's need to win for scramble. 0 to disable", _, true, 0.0);
	gh_StrongPistolChance = CreateConVar("retakes_strongchance", "33", "How much percent to give a awper a strong pistol by his choice. 0 to disable", _, true, 0.0, true, 100.0);
	gh_DidntPlant = CreateConVar("retakes_didntplant", "0", "How much time player should be banned if he didnt planted twice. -1 - Do nothing, 0 - Kick client", _, true, -1.0);

	gi_PistolRoundsCount = GetConVarInt(gh_PistolRoundsCount);
	gi_WinRowScramble = GetConVarInt(gh_WinRowScramble);
	gi_StrongPistolChance = GetConVarInt(gh_StrongPistolChance);
	gi_DidntPlant = GetConVarInt(gh_DidntPlant);

	HookConVarChange(gh_PistolRoundsCount, Action_OnSettingsChange);
	HookConVarChange(gh_WinRowScramble, Action_OnSettingsChange);
	HookConVarChange(gh_StrongPistolChance, Action_OnSettingsChange);
	HookConVarChange(gh_DidntPlant, Action_OnSettingsChange);

	AutoExecConfig(true, "retakes");
	//Admin Commands
	RegAdminCmd("sm_start", Command_Start, ADMFLAG_ROOT);
	RegAdminCmd("sm_scramble", Command_Scramble, ADMFLAG_ROOT);
	RegAdminCmd("sm_pistols", Command_OnlyPistols, ADMFLAG_ROOT);
	RegAdminCmd("sm_del", Command_DeleteSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_delete", Command_DeleteSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_add", Command_AddSpawn, ADMFLAG_ROOT);
	RegAdminCmd("sm_edit", Command_Edit, ADMFLAG_ROOT);
	RegAdminCmd("sm_spawns", Command_Spawns, ADMFLAG_ROOT);
	//Client Commands
	RegConsoleCmd("sm_guns", Command_Guns);
	RegConsoleCmd("sm_awp", Command_Guns);
	RegConsoleCmd("sm_m4", Command_Guns);
	RegConsoleCmd("sm_m4a1", Command_Guns);
	RegConsoleCmd("sm_m4a4", Command_Guns);
	RegConsoleCmd("sm_vp", Command_VotePistols);
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	//Events
	HookEvent("round_prestart", Event_OnRoundPreStart);
	HookEvent("round_poststart", Event_OnRoundPostStart);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("player_connect_full", Event_OnFullConnect);
	HookEvent("player_team", Event_OnPlayerChangeTeam, EventHookMode_Pre);
	HookEvent("player_hurt", Event_OnPlayerDamged);
	HookEvent("bomb_defused", Event_OnBombDefused);
	HookEvent("bomb_planted", Event_OnBombPlanted);
	HookEvent("round_freeze_end", Event_OnFreezeTimeEnd);
	//Listeners
	AddCommandListener(Hook_ChangeTeam, "jointeam");
	//Offsets
	gi_MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	gi_HelmetOffset = FindSendPropOffs("CCSPlayer", "m_bHasHelmet");
	//Coockies
	gh_WantAwp = RegClientCookie("retakes_awp", "Retakes allow player play with awp", CookieAccess_Protected);
	gh_SilencedM4 = RegClientCookie("retakes_m4", "Retakes play with m4a1s or m4a4", CookieAccess_Protected);
	gh_PistolPrefence = RegClientCookie("retakes_pistol", "Retakes pistol prefernce", CookieAccess_Protected);
	
	//Sql
	ConnectSQL();
	//Add Tag
	AddServerTag("retakes");

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}

	if(GetClientCountFix() >= 2)
	{
		gb_WaitForPlayers = false;
		SetConfig(false);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == gh_PistolRoundsCount)
	{
		gi_PistolRoundsCount = StringToInt(newvalue);
	}
	else if(cvar == gh_WinRowScramble)
	{
		gi_WinRowScramble = StringToInt(newvalue);
	}
	else if(cvar == gh_StrongPistolChance)
	{
		gi_StrongPistolChance = StringToInt(newvalue);
	}
	else if(cvar == gh_DidntPlant)
	{
		gi_DidntPlant = StringToInt(newvalue);
	}
}


public OnMapStart()
{
	//Map String to LowerCase
	GetCurrentMap(gs_CurrentMap, sizeof(gs_CurrentMap));
	new len = strlen(gs_CurrentMap);
	for(new i=0;i < len;i++)
	{
		gs_CurrentMap[i] = CharToLower(gs_CurrentMap[i]);
	}
	gb_EditMode = false;
	gb_OnlyPistols = false;
	LoadSpawns(true); // Load Spawns
	//Precahche models for edit mode
	g_precacheLaser = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_precacheGlow = PrecacheModel("materials/sprites/blueflare1.vmt");
	SetConfig(true);
	gi_QueueCounter  = 0;
	for (new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			LoadClientCoockies(i);
			if(GetClientTeam(i) == 1)
			{
				AddPlayerToQueue(i);
			}
		}
	}
	
	gb_WarmUp = true;
	PrintToChatAll("%sRetakes will start in 30 seconds", PREFIX);
	gh_MapLoadTimer = CreateTimer(30.0, Timer_MapLoadDelay, _);
	gf_MapLoadTime = GetEngineTime();
	CreateTimer(0.1, Timer_PrintHintWarmup, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	gi_WinRowCounter = 0;
	gi_Voters = 0;
	gi_Votes = 0;
	gi_VotesNeeded = 0;

	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
		return;
	
	gb_Voted[client] = false;

	gi_Voters++;
	gi_VotesNeeded = RoundToFloor(float(gi_Voters) * 0.5);
	gf_UsedVP[client] = -100.0;
	return;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	if(gb_Voted[client])
	{
		gi_Votes--;
	}
	
	gi_Voters--;
	
	gi_VotesNeeded = RoundToFloor(float(gi_Voters) * 0.5);
	
	if (gi_VotesNeeded < 1)
	{
		return;	
	}
	
	if (gi_Votes && 
		gi_Voters && 
		gi_Votes >= gi_VotesNeeded 
		) 
	{
		ToggleVP();
	}	
}

LoadClientCoockies(client)
{
	if(IsFakeClient(client))
		return;
	decl String:buffer[16];
	new bool:openGunsMenu = false;

	GetClientCookie(client, gh_WantAwp, buffer, sizeof(buffer));
	if(!StrEqual(buffer, ""))
		gi_WantAwp[client] = StringToInt(buffer);
	else
		openGunsMenu = true;

	GetClientCookie(client, gh_SilencedM4, buffer, sizeof(buffer));
	if(!StrEqual(buffer, ""))
		gb_WantSilencer[client] = bool:StringToInt(buffer);
	else
		openGunsMenu = true;

	GetClientCookie(client, gh_PistolPrefence, buffer, sizeof(buffer));
	if(!StrEqual(buffer, ""))
		gi_PistolPrefence[client] = bool:StringToInt(buffer);
	else
		openGunsMenu = true;

	gb_PreferenceLoaded[client] = !openGunsMenu;
}

public OnClientCookiesCached(client)
{
	LoadClientCoockies(client);
}

public Event_OnFullConnect(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(!gb_EditMode && !gb_WarmUp)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientCountFix() > 1)
		{
			SetEntPropFloat(client, Prop_Send, "m_fForceTeam", 3600.0);
		}
		if(!gb_PreferenceLoaded[client])
		{
			Command_Guns(client, 0);
		}
	}
}

AddPlayerToQueue(client)
{
	if(IsClientSourceTV(client))
		return;
		
	for (new i = 0; i < gi_QueueCounter; i++)
	{
		if(client == gi_PlayerQueue[i])
		{
			return;
		}
	}
	gi_PlayerQueue[gi_QueueCounter] = client;
	gi_QueueCounter++;
	PrintToChat(client, "%sYou are now \x02%d\x04 place in the queue", PREFIX, gi_QueueCounter);
	if(gi_QueueCounter == MAXPLAYERS)
	{
		gi_QueueCounter = 0;
	}
	return;
}

public OnClientDisconnect_Post(client)
{
	gb_Warnned[client] = false;
	gi_NextRoundTeam[client] = -1;
	if(!gb_WaitForPlayers && GetClientCountFix() < 2)
	{
		gb_WaitForPlayers = true;
		SetConfig(true);
	}
	gb_PreferenceLoaded[client] = false;
	new index = -1;
	for (new i = 0; i < gi_QueueCounter; i++)
	{
		if(client == gi_PlayerQueue[i])
		{
			index = i;
			break;
		}
	}
	if(index != -1)
	{
		DeletePlayerFromQueue(client);
	}
}

public Action:Event_OnPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast) 
{
	dontBroadcast = true;
	if(!gb_WarmUp && gb_WaitForPlayers)
	{
		if(GetClientCountFix() >= 2)
		{
			gb_WaitForPlayers = false;
			ServerCommand("mp_restartgame 5");
			SetConfig(false);
		}
		else
		{
			PrintToChatAll("%sWaiting for players to join", PREFIX);
		}
	}
	return Plugin_Changed;
}

public Action:Event_OnPlayerDamged(Handle:event, const String:name[],bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dhealth = GetEventInt(event, "dmg_health");
	gi_DamageCount[attacker] += dhealth;
}

public Action:Event_OnBombDefused(Handle:event, const String:name[],bool:dontBroadcast)
{
	new defuser = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetTeamAliveClientCount(2) > 0)
	{
		PrintToChatAll("%sNINJA DEFUSE", PREFIX);
		gi_DamageCount[defuser] += 100;
	}
}

public Action:Event_OnBombPlanted(Handle:event, const String:name[],bool:dontBroadcast)
{
	gb_BombPlanted = true;
}

public Event_OnFreezeTimeEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
}

public Action:Hook_ChangeTeam(client, const String:command[], args)
{
	if (args < 1)
		return Plugin_Handled;

	char arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	int team_to = StringToInt(arg);
	int team_from = GetClientTeam(client);

	if ((team_from == team_to && team_from != CS_TEAM_NONE) || gb_PluginSwitchingTeam[client] || IsFakeClient(client) || gb_EditMode || gb_WaitForPlayers || gb_WarmUp) 
	{
        return Plugin_Continue;
    }
	
	if ((team_from == CS_TEAM_CT && team_to == CS_TEAM_T )
		|| (team_from == CS_TEAM_T  && team_to == CS_TEAM_CT)) 
	{
		return Plugin_Handled;
	}

	SwitchPlayerTeam(client, 1);
	AddPlayerToQueue(client);
	return Plugin_Handled;
}

public Event_OnRoundPreStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!gb_EditMode)
	{	
		if(!gb_balancedTeams)
		{
			SetQueueClients();
			gb_balancedTeams = true;
		}
		else
		{
			gb_balancedTeams = false;
		}
		if(!gb_newClientsJoined)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && gi_NextRoundTeam[i] == -1)
				{
					gi_NextRoundTeam[i] = GetClientTeam(i);
				}
			}
			BalanceTeams();
		}
		gb_newClientsJoined = false;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsClientSourceTV(i) && gi_NextRoundTeam[i] != -1)
			{
				if(gi_NextRoundTeam[i] == 1)
				{
					SwitchPlayerTeam(i, 1);
				}
				else
				{
					SwitchPlayerTeam(i, gi_NextRoundTeam[i], false);
					CS_UpdateClientModel(i);
				}
			}
		}
		for (new i = 0; i < MAXPLAYERS; i++)
		{
			gi_NextRoundTeam[i] = -1;
		}
	}
}

public Event_OnRoundPostStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	gi_Bomber = -1;
	gb_BombPlanted = false;
	if(!gb_EditMode && !gb_WaitForPlayers && !gb_WarmUp)
	{
		new site = GetRandomInt(0, 1);
		PrintToChatAll("%sRetake on Site:\x02%s", PREFIX, site == SITEA ? "A":"B");
		PrintHintText ("%sRetake on Site:\x02%s", PREFIX, site == SITEA ? "A":"B");
		gf_StartRoundTime = GetEngineTime();
		CreateTimer(0.1, Timer_PrintHintSite, site, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		//Reset spawn use and roundkills
		for (new i = 0; i < GRENADESSETCOUNT; i++)
		{
			gi_GrenadeSetsFlags[i] = 0;
		}
		for (new i = 0; i < g_SpawnsCount; i++)
		{
			g_Spawns[i][Used] = false;
		}
		for (new i = 0; i < MAXPLAYERS; i++)
		{
			gi_DamageCount[i] = 0;
		}

		//Random awper for each team
		new awpCt = GetRandomAwpPlayer(3);
		new awpT = GetRandomAwpPlayer(2);

		//Get Bomber
		gi_Bomber = GetRandomPlayerFromTeam(2);
		new randomSpawn = -1;
		new randomGrenadeSet = -1;
		new Float:loc[3], Float:ang[3];
		new bool:pistols = CS_GetTeamScore(3) + CS_GetTeamScore(2) < gi_PistolRoundsCount || gb_OnlyPistols;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsClientSourceTV(i) && GetClientTeam(i) != 1)
			{
				//Set Money to 0$
				SetEntData(i, gi_MoneyOffset, 0);
				SetEntProp(i, Prop_Data, "m_ArmorValue", 100);
				Client_RemoveAllWeapons(i);
				randomSpawn = -1;
				if(i != gi_Bomber)
				{
					randomSpawn = GetRandomSpawn(GetClientTeam(i) == 3 ? Ct : T, site);
					if(randomSpawn != -1)
					{
						Array_Copy(g_Spawns[randomSpawn][Location], loc, 3);
						Array_Copy(g_Spawns[randomSpawn][Angles], ang, 3);
						g_Spawns[randomSpawn][Used] = true;
						TeleportEntity(i, loc, ang, NULL_VECTOR);
					}
				}
				else
				{
					randomSpawn = GetRandomSpawn(Bomb, site);
					if(randomSpawn != -1)
					{
						Array_Copy(g_Spawns[randomSpawn][Location], loc, 3);
						Array_Copy(g_Spawns[randomSpawn][Angles], ang, 3);
						g_Spawns[randomSpawn][Used] = true;
						TeleportEntity(i, loc, ang, NULL_VECTOR);
					}
					GivePlayerItem(i, "weapon_c4");
				}
				//Give Grenades
				if(!pistols)
				{
					SetEntData(i, gi_HelmetOffset, 1);
					randomGrenadeSet = GetRandomGrenadeSet(GetClientTeam(i));
					if(randomGrenadeSet != -1)
					{
						if(GetClientTeam(i) == 3)
							gi_GrenadeSetsFlags[randomGrenadeSet] = gi_GrenadeSetsFlags[randomGrenadeSet] | FL_USED_Ct;
						else if(GetClientTeam(i) == 2)
							gi_GrenadeSetsFlags[randomGrenadeSet] = gi_GrenadeSetsFlags[randomGrenadeSet] | FL_USED_T;
						for (new k = 0; k < 2; k++)
						{
							if(!StrEqual("none", gs_GrenadeSets[randomGrenadeSet][k]))
							{
								if(!StrEqual("moli", gs_GrenadeSets[randomGrenadeSet][k]))
									GivePlayerItem(i, gs_GrenadeSets[randomGrenadeSet][k]);
								else if(GetClientTeam(i) == 3)
									GivePlayerItem(i, "weapon_incgrenade");
								else
									GivePlayerItem(i, "weapon_molotov");
								
							}
						}
					}
				}
				if(pistols)
				{
					SetEntData(i, gi_HelmetOffset, 0);
				}
				//Give Weapons
				GivePlayerItem(i, "weapon_knife");
				if((awpCt == i || awpT == i) && !pistols)
				{
					GivePlayerItem(i, "weapon_awp");
					if(gi_PistolPrefence[i] == 0)
					{
						if(GetClientTeam(i) == 3)
							GivePlayerItem(i, "weapon_hkp2000");
						else
							GivePlayerItem(i, "weapon_glock");
					}
					else if(gi_PistolPrefence[i] == 1)
					{
						if(GetRandomInt(1, 100) <= gi_StrongPistolChance)
						{
							if(GetClientTeam(i) == 3)
								GivePlayerItem(i, "weapon_fiveseven");
							else
								GivePlayerItem(i, "weapon_tec9");
						}
						else
							GivePlayerItem(i, "weapon_p250");
					}
					else if(gi_PistolPrefence[i] == 2)
						GivePlayerItem(i, "weapon_p250");
				}
				else
				{
					if(GetClientTeam(i) == 3)
					{
						if(!pistols)
						{
							if(!gb_WantSilencer[i])
								GivePlayerItem(i, "weapon_m4a1");
							else
								GivePlayerItem(i, "weapon_m4a1_silencer");
						}
						GivePlayerItem(i, "weapon_hkp2000");
					}
					else
					{
						if(!pistols)
						{
							GivePlayerItem(i, "weapon_ak47");
						}
						GivePlayerItem(i, "weapon_glock");
					}
				}
			}
		}	
		if(gi_Bomber != -1)
			if(IsClientInGame(gi_Bomber))
				FakeClientCommand(gi_Bomber, "use weapon_c4");
	}
}

public Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:queueplayers = true;
	if(!gb_EditMode)
	{
		gb_balancedTeams = true;
		if(!gb_BombPlanted && gi_Bomber != -1 && GetEventInt(event, "winner") == 3 && IsClientInGame(gi_Bomber))
		{
			new DamageList[MaxClients];
			new IndexList[MaxClients];
			new count = 0;
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) == 3)
					{
						DamageList[count] = GetClientFrags(i);
						IndexList[count] = i;
						count++;
					}
				}
			}
			new temp;
			new temp2;
			for (new i = 0; i < count; i++)
			{
				for (new j = i+1; j < count; j++)
				{
					if(DamageList[i] < DamageList[j])
					{
						temp = DamageList[i];
						temp2 = IndexList[i];
						DamageList[i] = DamageList[j];
						IndexList[i] = IndexList[j];
						DamageList[j] = temp;
						IndexList[j] = temp2;
					}
				}
			}
			gi_NextRoundTeam[gi_Bomber] = 3;
			gi_NextRoundTeam[IndexList[0]] = 2;
			new String:sName[64];
			GetClientName(gi_Bomber, sName, 64);
			PrintToChatAll("%s%s Failed to plant to bomb.He will be swap to \x02CT\x04", PREFIX, sName);
			if(gb_Warnned[gi_Bomber])
			{
				if(gi_DidntPlant > 0)
				{
					BanClient(gi_Bomber, gi_DidntPlant, BANFLAG_AUTO, "Didnt planted the bomb 2 times", "You didnt planted the bomb 2 times");
				}
				else if(gi_DidntPlant == 0)
				{
					KickClient(gi_Bomber, "Didnt planted the bomb twice");
				}
				gb_Warnned[gi_Bomber] = false;
			}
			else
			{
				gb_Warnned[gi_Bomber] = true;
			}
			for (new i = 1; i < MaxClients; i++)
			{
				if(IsClientInGame(i) && gi_NextRoundTeam[i] == -1)
				{
					gi_NextRoundTeam[i] = GetClientTeam(i);
				}
			}
		}
		else
		{
			if(GetEventInt(event, "winner") == 3)
			{
				gi_WinRowCounter = 0;
				//Move top Killers to T
				new DamageList[MaxClients];
				new IndexList[MaxClients];
				new count = 0;
				new terrorCount = RoundToFloor(GetClientCountFix(false) / 2.0);
				if(terrorCount > 4)
					terrorCount = 4;
				for (new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						if(GetClientTeam(i) == 3)
						{
							DamageList[count] = gi_DamageCount[i];
							IndexList[count] = i;
							count++;
						}
						else if (GetClientTeam(i) == 2)
						{
							gi_NextRoundTeam[i] = 3;
						}
					}
				}
				new temp;
				new temp2;
				for (new i = 0; i < count; i++)
				{
					for (new j = i+1; j < count; j++)
					{
						if(DamageList[i] < DamageList[j])
						{
							temp = DamageList[i];
							temp2 = IndexList[i];
							DamageList[i] = DamageList[j];
							IndexList[i] = IndexList[j];
							DamageList[j] = temp;
							IndexList[j] = temp2;
						}
					}
				}
				for (new i = 0; i < terrorCount; i++)
				{
					gi_NextRoundTeam[IndexList[i]] = 2;
				}
			}
			else if (GetEventInt(event, "winner") == 2)
			{
				gi_WinRowCounter++;
				if(gi_WinRowCounter == gi_WinRowScramble || gb_Scrambling)
				{
					//Scramble Players
					gi_WinRowCounter = 0;
					gb_Scrambling = false;
					queueplayers = false;
					ScrambleTeams(false);
				}
				else
				{
					for (new i = 1; i < MaxClients; i++)
					{
						if(IsClientInGame(i) && gi_NextRoundTeam[i] == -1)
						{
							gi_NextRoundTeam[i] = GetClientTeam(i);
						}
					}
					if(gi_WinRowCounter > gi_WinRowScramble - 3)
						PrintToChatAll("%sThe Terror need to take \x02%d\x04 more rounds in a row to scramble", PREFIX, gi_WinRowScramble - gi_WinRowCounter);
				}
			}
		}
		if(queueplayers)
			SetQueueClients();
	}
}

BalanceTeams()
{
	//Balance Team if not Balanced
	new terrorCount = RoundToFloor(GetClientCountFix(false) / 2.0);
	if(terrorCount > 4)
		terrorCount = 4;
	if(terrorCount < GetNextTeamCount(2, true))
	{
		new DamageList[MaxClients];
		new IndexList[MaxClients];
		new count = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				DamageList[count] = GetClientFrags(i);
				IndexList[count] = i;
				count++;
			}
		}
		new temp;
		new temp2;
		for (new i = 0; i < count; i++)
		{
			for (new j = i+1; j < count; j++)
			{
				if(DamageList[i] < DamageList[j])
				{
					temp = DamageList[i];
					temp2 = IndexList[i];
					DamageList[i] = DamageList[j];
					IndexList[i] = IndexList[j];
					DamageList[j] = temp;
					IndexList[j] = temp2;
				}
			}
		}
		for (new i = 0; i < GetNextTeamCount(2, true) - terrorCount; i++)
		{
			gi_NextRoundTeam[IndexList[i]] = 3;
		}
	}
	else if(terrorCount > GetNextTeamCount(2, true))
	{
		new DamageList[MaxClients];
		new IndexList[MaxClients];
		new count = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 3)
			{
				DamageList[count] = GetClientFrags(i);
				IndexList[count] = i;
				count++;
			}
		}
		new temp;
		new temp2;
		for (new i = 0; i < count; i++)
		{
			for (new j = i+1; j < count; j++)
			{
				if(DamageList[i] > DamageList[j])
				{
					temp = DamageList[i];
					temp2 = IndexList[i];
					DamageList[i] = DamageList[j];
					IndexList[i] = IndexList[j];
					DamageList[j] = temp;
					IndexList[j] = temp2;
				}
			}
		}
		for (new i = 0; i < terrorCount - GetNextTeamCount(2, true); i++)
		{
			gi_NextRoundTeam[IndexList[i]] = 2;
		}
	}
}

ScrambleTeams(bool:includespec)
{
	PrintToChatAll("%sScrambling Teams", PREFIX);
	new terrorCount = RoundToFloor(GetClientCountFix(includespec) / 2.0);
	if(terrorCount > 4)
		terrorCount = 4;
	new randomPlayer = -1;
	for (new i = 0; i < MAXPLAYERS; i++)
	{
		gi_NextRoundTeam[i] = -1;
	}
	for (new i = 0; i < terrorCount; i++)
	{
		randomPlayer = GetRandomPlayer(includespec);
		if(randomPlayer != -1)
		{
			gi_NextRoundTeam[randomPlayer] = 2;
			if(GetClientTeam(randomPlayer) == 1)
			{
				DeletePlayerFromQueue(i);
			}
		}
	}
	new ctCount = GetClientCountFix(true) - terrorCount;
	if(ctCount > 5)
		ctCount = 5;
	for (int i = 0; i < ctCount; i++)
	{
		randomPlayer = GetRandomPlayer(includespec);
		if(randomPlayer != -1)
		{
			gi_NextRoundTeam[randomPlayer] = 3;
			if(GetClientTeam(randomPlayer) == 1)
			{
				DeletePlayerFromQueue(i);
			}
		}
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && gi_NextRoundTeam[i] == -1)
		{
			gi_NextRoundTeam[i] = 1;
			AddPlayerToQueue(i);
		}
	}
	gb_balancedTeams = true;
}

SetQueueClients()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && gi_NextRoundTeam[i] == -1 && GetClientTeam(i) != 1)
		{
			gi_NextRoundTeam[i] = GetClientTeam(i);
		}
	}
	new terror = GetNextTeamCount(2);
	new ct = GetNextTeamCount(3);
	if(terror == 0)
	{
		terror = GetTeamClientCountFix(2);
	}
	if(ct == 0)
	{
		ct = GetTeamClientCountFix(3);
	}
	new counter = gi_QueueCounter;
	new queue[counter];
	for (new i = 0; i < counter; i++)
	{
		queue[i] = gi_PlayerQueue[i];
	}
	for (new i = 0; i < counter; i++)
	{
		if(IsClientInGame(queue[i]))
		{
			if(ct > terror && terror < 4)
			{
				SwitchPlayerTeam(queue[i], 2);
				gi_NextRoundTeam[queue[i]] = 2;
				terror++;	
				DeletePlayerFromQueue(queue[i]);
				gb_newClientsJoined = true;
			}
			else if(ct < 5)
			{
				SwitchPlayerTeam(queue[i], 3);
				gi_NextRoundTeam[queue[i]] = 3;
				ct++;
				DeletePlayerFromQueue(queue[i]);
				gb_newClientsJoined = true;
			}
		}
	}
}

DeletePlayerFromQueue(client)
{
	new index = -1;
	for (new i = 0; i < gi_QueueCounter; i++)
	{
		if(client == gi_PlayerQueue[i])
		{
			index = i;
			break;
		}
	}
	if(index != -1)
	{
		for (new i = index+1; i < gi_QueueCounter; i++)
		{
			gi_PlayerQueue[i-1] = gi_PlayerQueue[i];
		}
		gi_QueueCounter--;
		if(gi_QueueCounter < 0)
		{
			gi_QueueCounter = 0;
		}
	}
}

public Action:Command_Start(client, args)
{
	gf_MapLoadTime -= 50;
	TriggerTimer(gh_MapLoadTimer, false);
	return Plugin_Handled;
}

public Action:Command_Spawns(client, args)
{
	new aCt, bCt;
	new aT, bT;
	new aB, bB;
	for (new i = 0; i < g_SpawnsCount; i++)
	{
		if(g_Spawns[i][Type] == Ct && g_Spawns[i][Site] == SITEA)
			aCt++;
		if(g_Spawns[i][Type] == Ct && g_Spawns[i][Site] == SITEB)
			bCt++;
		if(g_Spawns[i][Type] == T && g_Spawns[i][Site] == SITEA)
			aT++;
		if(g_Spawns[i][Type] == T && g_Spawns[i][Site] == SITEB)
			bT++;
		if(g_Spawns[i][Type] == Bomb && g_Spawns[i][Site] == SITEA)
			aB++;
		if(g_Spawns[i][Type] == Bomb && g_Spawns[i][Site] == SITEB)
			bB++;
	}
	PrintToChatAll("A:Ct:%d, T:%d, Bomb:%d", aCt, aT, aB);
	PrintToChatAll("B:Ct:%d, T:%d, Bomb:%d", bCt, bT, bB);
	return Plugin_Handled;
}

public Action:Command_Scramble(client, args)
{
	gb_Scrambling = true;
	return Plugin_Handled;
}

public Action:Command_OnlyPistols(client, args)
{
	gb_OnlyPistols = !gb_OnlyPistols;
	PrintToChatAll("%sPistols Only is now \x02%s", PREFIX, gb_OnlyPistols ? "Enabled":"Disabled");
	return Plugin_Handled;
}

public Action:Command_VotePistols(int client, int args)
{	
	if(GetEngineTime() - gf_UsedVP[client] < 5)
	{
		PrintToChat(client, "%s\x02sm_vp\x04 is allowed once in 5 seconds", PREFIX);
		return Plugin_Handled;
	}

	gf_UsedVP[client] = GetEngineTime();
	
	if(CS_GetTeamScore(3) + CS_GetTeamScore(2) < gi_PistolRoundsCount)
	{
		PrintToChat(client, "%ssm_vp is allowed after \x02%d\x04 rounds", PREFIX, gi_PistolRoundsCount);
		return Plugin_Handled;
	}

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	if(!gb_Voted[client])
	{
		gi_Votes++;
		PrintToChatAll("%s\x02%s\x04 wants to \x02%s%\x04 Only Pistols (%d votes, %d required)", PREFIX, name, gb_OnlyPistols ? "Disable":"Enable", gi_Votes, gi_VotesNeeded);
	}
	else
	{
		gi_Votes--;
		PrintToChatAll("%s\x02%s\x04 devoted (%d votes, %d required)", PREFIX, name, gi_Votes, gi_VotesNeeded);	
	}
	
	gb_Voted[client] = !gb_Voted[client];
	
	if (gi_Votes >= gi_VotesNeeded)
	{
		ToggleVP();
	}

	return Plugin_Handled;
}

ToggleVP()
{
	for (int i = 0; i < MAXPLAYERS; i++)
	{
		gb_Voted[i] = false;
	}
	gi_Votes = 0;
	gi_VotesNeeded = RoundToFloor(float(gi_Voters) * 0.5);

	gb_OnlyPistols = !gb_OnlyPistols;
	PrintToChatAll("%sPistols Only is now \x02%s", PREFIX, gb_OnlyPistols ? "Enabled":"Disabled");
}


public Action:Command_Edit(client, args)
{
	gb_EditMode = !gb_EditMode;
	PrintToChatAll("%sEdit mode is now %s", PREFIX, gb_EditMode ? "Enabled":"Disabled");
	if(gb_EditMode)
	{
		CreateTimer(0.1, DrawSpawns, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	SetConfig(gb_EditMode);
	ServerCommand("mp_restartgame 1");
	return Plugin_Handled;
}

stock GetNextTeamCount(team, bool:next = true)
{
	if(!next)
		return GetTeamClientCountFix(team);
	new count = 0;
	for (new i = 1; i < MaxClients; i++)
	{
		if(gi_NextRoundTeam[i] == team)
			count++;
	}
	return count;
}

stock GetTeamClientCountFix(team)
{
	new count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team)
		{
			count++;
		}
	}
	return count;
}

stock GetTeamAliveClientCount(team)
{
	new count = 0;
	for (new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
			count++;
	}
	return count;
}

stock GetRandomAwpPlayer(team)
{
	new iClients[MaxClients];
	new numClients;

	for (new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i) && gi_WantAwp[i] > 0 && GetClientTeam(i) == team)
		{
			iClients[numClients] = i;
			numClients++;
		}
	}

	if(numClients)
	{
		new awp = iClients[GetRandomInt(0, numClients-1)];
		if(gi_WantAwp[awp] == 2 && GetRandomInt(0, 1) == 1)
		{
			numClients = 0;
			for (new i = 1; i < MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsClientSourceTV(i) && gi_WantAwp[i] == 1 && GetClientTeam(i) == team)
				{
					iClients[numClients] = i;
					numClients++;
				}
			}
			if(numClients)
			{
				return iClients[GetRandomInt(0, numClients-1)];
			}
			return -1;
		}
		return awp;
	}
	return -1;
}

stock GetRandomSpawn(SpawnType:type, site)
{
	decl iSpawns[MaxClients];
	new numSpawns;

	for (new i = 0; i < g_SpawnsCount; i++)
	{
		if(!g_Spawns[i][Used] && g_Spawns[i][Type] == type && g_Spawns[i][Site] == site)
		{
			iSpawns[numSpawns] = i;
			numSpawns++;
		}
	}

	if (numSpawns)
	{
    	return iSpawns[GetRandomInt(0, numSpawns-1)];
	}
	return -1;
}

stock GetRandomPlayer(bool:includespec = false)
{
	decl iClients[MaxClients];
	new numClients;

	for (new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i) && gi_NextRoundTeam[i] == -1 && (includespec || GetClientTeam(i) != 1))
		{
			iClients[numClients] = i;
			numClients++;
		}
	}

	if (numClients)
	{
		return iClients[GetRandomInt(0, numClients-1)];
	}
	return -1;
}

stock GetRandomPlayerFromTeam(team)
{
	decl iClients[MaxClients];
	new numClients = 0;

	for (new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i) && GetClientTeam(i) == team)
		{
			iClients[numClients] = i;
			numClients++;
		}
	}

	if (numClients)
	{
   		return iClients[GetRandomInt(0, numClients-1)];
	}
	return -1;
}

stock GetRandomGrenadeSet(team)
{
	decl iSets[MaxClients];
	new numSets;
	new flag = FL_USED_Ct;
	if(team == 2)
		flag = FL_USED_T;

	for (new i = 0; i < GRENADESSETCOUNT; i++)
	{
		if(!(gi_GrenadeSetsFlags[i] & flag))
		{
			iSets[numSets] = i;
			numSets++;
		}
	}

	if (numSets)
	{
    	return iSets[GetRandomInt(0, numSets-1)];
	}
	return -1;
}

public Action:Command_Say(client, const String:command[], argc)
{
	decl String:sText[192];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	if(StrEqual(sText, "guns") || StrEqual(sText, "weapons") || StrEqual(sText, "weps"))
	{
		Command_Guns(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Command_Guns(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_M4, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Choose Ct Weapon:");
	AddMenuItem(menu, "0", "M4A4");
	AddMenuItem(menu, "1", "M4A1-S");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_M4(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:sArg[6];
		GetMenuItem(menu, param2, sArg, sizeof(sArg));
		gb_WantSilencer[param1] = bool:StringToInt(sArg);
		new convInt = gb_WantSilencer[param1] ? 1 : 0;
		decl String:buffer[16];
		IntToString(convInt, buffer, sizeof(buffer));
		SetClientCookie(param1, gh_SilencedM4, buffer);
		
		new Handle:hmenu = CreateMenu(MenuHandler_Awp, MENU_ACTIONS_ALL);
		SetMenuTitle(hmenu, "Do you want to play with Awp:");
		AddMenuItem(hmenu, "1", "Always");
		AddMenuItem(hmenu, "2", "Sometimes");
		AddMenuItem(hmenu, "0", "Never");
		DisplayMenu(hmenu, param1, MENU_TIME_FOREVER);
	}
}

public MenuHandler_Awp(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:sArg[6];
		GetMenuItem(menu, param2, sArg, sizeof(sArg));
		gi_WantAwp[param1] = StringToInt(sArg);
		decl String:buffer[16];
		IntToString(gi_WantAwp[param1], buffer, sizeof(buffer));
		SetClientCookie(param1, gh_WantAwp, buffer);
		if(gi_WantAwp[param1] != 0)
		{
			new Handle:hmenu = CreateMenu(MenuHandler_Pistol, MENU_ACTIONS_ALL);
			SetMenuTitle(hmenu, "Which Pistol you want with Awp:");
			AddMenuItem(hmenu, "0", "P2000/Glock");
			if(gi_StrongPistolChance == 100)
				AddMenuItem(hmenu, "1", "FiveSeven/Tec9");
			else if(gi_StrongPistolChance > 0)
				AddMenuItem(hmenu, "1", "FiveSeven/Tec9/P250");
			AddMenuItem(hmenu, "2", "P250");
			DisplayMenu(hmenu, param1, MENU_TIME_FOREVER);
		}
	}
}

public MenuHandler_Pistol(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:sArg[6];
		GetMenuItem(menu, param2, sArg, sizeof(sArg));
		gi_PistolPrefence[param1] = StringToInt(sArg);
		decl String:buffer[16];
		IntToString(gi_PistolPrefence[param1], buffer, sizeof(buffer));
		SetClientCookie(param1, gh_PistolPrefence, buffer);
	}
}

public Action:Command_DeleteSpawn(client, args)
{
	new Handle:hmenu = CreateMenu(MenuHandler_Teleport);
	SetMenuTitle(hmenu, "Select Spawn");
	if(g_SpawnsCount > 0)
	{
		decl String:sDisplay[64];
		decl String:sInfo[64];
		for (new i = 0; i < g_SpawnsCount; i++)
		{
			FormatEx(sDisplay, sizeof(sDisplay), "Site:%s, Type:", g_Spawns[i][Site] == SITEA ? "A":"B");
			if(g_Spawns[i][Type] == Bomb)
				FormatEx(sDisplay, sizeof(sDisplay), "%sBomb", sDisplay);
			else if(g_Spawns[i][Type] == T)
				FormatEx(sDisplay, sizeof(sDisplay), "%sT", sDisplay);
			else if(g_Spawns[i][Type] == Ct)
				FormatEx(sDisplay, sizeof(sDisplay), "%sCt", sDisplay);
			FormatEx(sInfo, sizeof(sInfo), "%d", i);
			AddMenuItem(hmenu, sInfo, sDisplay);
		}
		SetMenuExitButton(hmenu, true);
	}
	else
	{
		return Plugin_Handled;
	}
	DisplayMenu(hmenu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_Teleport(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:sInfo[32];		
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		new spawnNum = StringToInt(sInfo);
		new Float:loc[3], Float:ang[3];
		Array_Copy(g_Spawns[spawnNum][Location], loc, 3);
		Array_Copy(g_Spawns[spawnNum][Angles], ang, 3);
		TeleportEntity(param1, loc, ang, NULL_VECTOR);
		new Handle:hmenu = CreateMenu(MenuHandler_Delete);
		SetMenuTitle(hmenu, "Delete this spawn:");
		FormatEx(sInfo, sizeof(sInfo), "%d", g_Spawns[spawnNum][Id]);
		AddMenuItem(hmenu, sInfo, "Yes");
		AddMenuItem(hmenu, "-1", "No");
		DisplayMenu(hmenu, param1, MENU_TIME_FOREVER);
	}
}

public MenuHandler_Delete(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Select)
	{
		decl String:sInfo[32];		
		GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
		new spawnNum = StringToInt(sInfo);
		if(spawnNum == -1)
		{
			Command_DeleteSpawn(param1, 0);
		}
		else
		{
			decl String:sQuery[64];
			FormatEx(sQuery, sizeof(sQuery), "DELETE FROM spawns WHERE id = %d", spawnNum);
			SQL_TQuery(gh_Sql, DeleteSpawnCallBack, sQuery, param1, DBPrio_High);
		}
	}
}

public DeleteSpawnCallBack(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error on DeleteSpawn: %s", error);
		return;
	}
	
	LoadSpawns();
	
	if (IsClientInGame(data))
	{
		PrintToChat(data, "%sDeleted spawn", PREFIX);
	}
}

public Action:Command_AddSpawn(client, args)
{
	new Handle:menu = CreateMenu(MenuHandler_Site, MENU_ACTIONS_ALL);
	SetMenuTitle(menu, "Choose Site:");
	AddMenuItem(menu, "0", "A");
	AddMenuItem(menu, "1", "B");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_Site(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:sArg[6];
		GetMenuItem(menu, param2, sArg, sizeof(sArg));
		gi_ChoosedSite[param1] = StringToInt(sArg);
		new Handle:hmenu = CreateMenu(MenuHandler_Type, MENU_ACTIONS_ALL);
		SetMenuTitle(hmenu, "Choose Spawn Type:");
		AddMenuItem(hmenu, "1", "Bomber");
		AddMenuItem(hmenu, "2", "T");
		AddMenuItem(hmenu, "3", "CT");
		SetMenuExitBackButton(hmenu, true);
		DisplayMenu(hmenu, param1, MENU_TIME_FOREVER);

	}
}

public MenuHandler_Type(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:sArg[6];
		GetMenuItem(menu, param2, sArg, sizeof(sArg));
		new type = StringToInt(sArg);

		decl String:sQuery[512];
		new Float:loc[3], Float:ang[3];
		GetClientAbsOrigin(param1, loc);
		GetClientEyeAngles(param1, ang);
		FormatEx(sQuery, sizeof(sQuery), "INSERT INTO spawns (map, type, site, posx, posy, posz, angx) VALUES ('%s', '%d', '%d', %f, %f, %f, %f);", gs_CurrentMap, type, gi_ChoosedSite[param1], loc[0], loc[1], loc[2], ang[1]);
		SQL_TQuery(gh_Sql, AddSpawnCallback, sQuery, param1, DBPrio_Normal);
	}
	else if(action == MenuAction_Cancel)
	{
		Command_AddSpawn(param1, 0);
	}
}

public AddSpawnCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error on AddSpawn: %s", error);
		return;
	}

	Command_AddSpawn(data, 0);
	LoadSpawns();
}

stock GetClientCountFix(bool:includespec = true)
{
	new counter = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i) && (includespec || GetClientTeam(i) != 1))
		{
			counter++;
		}
	}
	return counter;
}

//Sql
ConnectSQL()
{
	if (gh_Sql != INVALID_HANDLE)
	{
		CloseHandle(gh_Sql);
	}
	
	gh_Sql = INVALID_HANDLE;
	
	if (SQL_CheckConfig("retakes"))
	{
		SQL_TConnect(ConnectSQLCallback, "retakes");
	}
	else
	{
		SetFailState("PLUGIN STOPPED - Reason: no config entry found for 'retakes' in databases.cfg - PLUGIN STOPPED");
	}
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (gi_ReconncetCounter >= 5)
	{
		LogError("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Connection to SQL database has failed, Reason: %s", error);
		
		gi_ReconncetCounter++;
		ConnectSQL();
		
		return;
	}
	
	decl String:sDriver[16];
	SQL_GetDriverIdent(owner, sDriver, sizeof(sDriver));
	
	gh_Sql = CloneHandle(hndl);		
	
	if (StrEqual(sDriver, "mysql", false))
	{
		SQL_TQuery(gh_Sql, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `spawns` (`id` int(11) NOT NULL AUTO_INCREMENT, `type` int(11) NOT NULL, `site` int(11) NOT NULL, `map` varchar(32) NOT NULL, `posx` float NOT NULL, `posy` float NOT NULL, `posz` float NOT NULL, `angx` float NOT NULL, PRIMARY KEY (`id`));");
		//SQL_TQuery(gh_Sql, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `players` (`auth` varchar(24) NOT NULL PRIMARY KEY, `kills` int(11) NOT NULL, `deaths` int(11) NOT NULL);");
	}
	else if (StrEqual(sDriver, "sqlite", false))
	{
		SQL_TQuery(gh_Sql, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `spawns` (`id` INTEGER PRIMARY KEY, `type` INTEGER NOT NULL, `site` INTEGER NOT NULL, `map` varchar(32) NOT NULL, `posx` float NOT NULL, `posy` float NOT NULL, `posz` float NOT NULL, `angx` float NOT NULL);");
	}
	
	gi_ReconncetCounter = 1;
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (owner == INVALID_HANDLE)
	{		
		LogError("SQL:Reconnect");
		gi_ReconncetCounter++;
		ConnectSQL();
		
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL CreateTable:%s", error);
		return;
	}
	
	LoadSpawns();
}

LoadSpawns(bool:mapstart = false)
{
	if (gh_Sql == INVALID_HANDLE)
	{
		ConnectSQL();
	}
	else
	{
		decl String:sQuery[384];
		FormatEx(sQuery, sizeof(sQuery), "SELECT id, type, site, posx, posy, posz, angx FROM spawns WHERE map = '%s'", gs_CurrentMap);
		SQL_TQuery(gh_Sql, LoadSpawnsCallBack, sQuery, mapstart, DBPrio_High);
	}
}

public LoadSpawnsCallBack(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("SQL Error on LoadDest: %s", error);
		return;
	}
	
	g_SpawnsCount = 0;
	while (SQL_FetchRow(hndl) && g_SpawnsCount < MAXSPAWNS)
	{		
		g_Spawns[g_SpawnsCount][Id] = SQL_FetchInt(hndl, 0);
		g_Spawns[g_SpawnsCount][Type] = SpawnType:SQL_FetchInt(hndl, 1);
		g_Spawns[g_SpawnsCount][Site] = SQL_FetchInt(hndl, 2);
		g_Spawns[g_SpawnsCount][Location][0] = SQL_FetchFloat(hndl, 3);
		g_Spawns[g_SpawnsCount][Location][1] = SQL_FetchFloat(hndl, 4);
		g_Spawns[g_SpawnsCount][Location][2] = SQL_FetchFloat(hndl, 5);
		g_Spawns[g_SpawnsCount][Angles][0] = 0.0;
		g_Spawns[g_SpawnsCount][Angles][1] = SQL_FetchFloat(hndl, 6);
		g_Spawns[g_SpawnsCount][Angles][2] = 0.0;

		g_SpawnsCount++;
	}


	if(data)
	{
		if(g_SpawnsCount == 0)
		{
			gb_EditMode = true;
			PrintToChatAll("%sEdit mode is now Enabled becuase there is no spawns", PREFIX);
			CreateTimer(0.1, DrawSpawns, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			gb_EditMode = false;
		}
	}

}

public Action:DrawSpawns(Handle:timer)
{
	if (!gb_EditMode)
	{
		return Plugin_Stop;
	}
	new g_DrawColor[4];
	new Float:Point1[3];
	new Float:Point2[3];
	for (new i = 0; i < g_SpawnsCount; i++)
	{
		//Set Color
		if(g_Spawns[i][Type] == Ct)
		{
			g_DrawColor[0] = 0;
			g_DrawColor[1] = 255;
			g_DrawColor[2] = 255;
		}
		else if (g_Spawns[i][Type] == T)
		{
			g_DrawColor[0] = 255;
			g_DrawColor[1] = 0;
			g_DrawColor[2] = 0;
		}
		else if (g_Spawns[i][Type] == Bomb)
		{
			g_DrawColor[0] = 255;
			g_DrawColor[1] = 255;
			g_DrawColor[2] = 0;
		}
		g_DrawColor[3] = 255;
		//Set Points
		Array_Copy(g_Spawns[i][Location], Point1, 3);
		Array_Copy(Point1, Point2, 3);
		Point2[2] += 100.0;
		//Draw Beam
		TE_SetupBeamPoints(Point1, Point2, g_precacheLaser, 0, 0, 0, 0.1, 3.0, 3.0, 10, 0.0, g_DrawColor, 0);TE_SendToAll(0.0);
		//Draw Light Ball if site == A
		if(g_Spawns[i][Site] == SITEA)
		{
			Point2[0] = 0.0;
			Point2[1] = 0.0;
			Point2[2] = 0.0;
			TE_SetupGlowSprite(Point1, g_precacheGlow, 0.1, 1.0, 255);TE_SendToAll(0.0);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_MapLoadDelay(Handle:timer)
{
	if(GetClientCountFix() >= 2)
	{
		gb_WaitForPlayers = false;
		gb_balancedTeams = false;
		ScrambleTeams(true);
		SetConfig(false);
		ServerCommand("mp_restartgame 1");
		ServerCommand("mp_warmup_end");
	}
	else
	{
		PrintToChatAll("%sWaiting for more players to join", PREFIX);
	}
	gb_WarmUp = false;
}

public Action:Timer_PrintHintWarmup(Handle:timer)
{
	if(GetEngineTime() - gf_MapLoadTime >= 30)
		return Plugin_Stop;
	PrintHintTextToAll("\n<font size='22'>Retakes will start in:</font><font size='22' color='#E22C56'>%.00f seconds</font>", 30 - (GetEngineTime() - gf_MapLoadTime));
	return Plugin_Continue;
}

public Action:Timer_PrintHintSite(Handle:timer, any:site)
{
	if(GetEngineTime() - gf_StartRoundTime >= 3)
		return Plugin_Stop;
	PrintHintTextToAll("       <font size='22'> <font color = '#01A9DB'>%d CT</font> vs <font color = '#FE2E2E'> %d T</font>\n Retake on Site:<font color='#E22C56'>%s</font></font>", GetTeamClientCountFix(3), GetTeamClientCountFix(2), site == SITEA ? "A":"B");
	return Plugin_Continue;
}

SetConfig(bool:warmup)
{
	ServerCommand("exec retakes.cfg");
	if(!warmup)
	{
		ServerCommand("exec retakes_live.cfg");
		ServerCommand("mp_defuser_allocation 2");
	}
	else
	{
		ServerCommand("exec retakes_warmup.cfg");
	}
}

stock void SwitchPlayerTeam(int client, int team, bool change = true) 
{
	if (GetClientTeam(client) == team)
	return;

	gb_PluginSwitchingTeam[client] = true;
	if (!change) 
	{
		CS_SwitchTeam(client, team);
		CS_UpdateClientModel(client);
	} 
	else 
	{
		ChangeClientTeam(client, team);
	}
	gb_PluginSwitchingTeam[client] = false;
}