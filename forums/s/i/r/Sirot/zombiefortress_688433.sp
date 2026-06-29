#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define SOUND_HEART		"physics/body/body_medium_impact_soft5.wav"
#define PLUGIN_VERSION  "2.1.1"

public Plugin:myinfo = 
{
	name = "Zombie Fortress",
	author = "Sirot",
	description = "Pits a team of survivors aganist a endless onslaught of zombies.",
	version = PLUGIN_VERSION,
	url = "http://www.zf.sovietgaming.net/"
}

////GLOBAL VARIABLES

//Team Integers
new SUR = 2;
new ZOM = 3;

//Misc Variables
new zf_maxPlayers;
new zf_maxEntities;
new zf_a_history[33];
new zf_a_sentries[33];
new zf_a_zombies[33];
new zf_a_help[33];
new zf_a_drinking[33];

//Respawn Variables
new Float:zf_respawnSet[] = {1.0, 8.0, 14.0};
new Float:zf_respawnTime;
new zf_respawnCounter;

//Highscore Variables
new Float:zf_timeStart;
new zf_timeHigh;
new zf_timeGames;

//Periodic Variables
new zf_p_health;
new zf_p_ammo;
new zf_p_clip;
new zf_p_difference;
new TFClassType:zf_p_class;
new bool:zf_p_isAlone;
new zf_p_beatTimer;
new Float:zf_p_playerLocs[33][3];
new String:zf_p_netclass[64];

//Offsets
new zf_o_ammo;
new zf_o_clip;
new zf_o_sentrySapper;
new zf_o_disSapper;
new zf_o_disDisable;
new zf_o_origin;

//Booleans
new bool:zf_b_joinWindow;
new bool:zf_b_isActive;
new bool:zf_b_logDeaths;
new bool:zf_b_zombiesWin;

//Handles
new Handle:zf_cvar_ForceOn = INVALID_HANDLE;
new Handle:zf_cvar_Ratio = INVALID_HANDLE;
new Handle:zf_t_Period = INVALID_HANDLE;
new Handle:zf_t_Help = INVALID_HANDLE;
new Handle:zf_t_Recharge[33];


////CALLBACKS

public OnPluginStart()
{
	for (new i = 0; i < 33; i++)
	{
		zf_t_Recharge[i] = INVALID_HANDLE;
	}
	
	zf_o_clip = FindSendPropOffs("CTFWeaponBase", "m_iClip1");
	zf_o_ammo = FindSendPropOffs("CTFPlayer", "m_iAmmo");
	zf_o_sentrySapper = FindSendPropInfo("CObjectSentrygun", "m_bHasSapper");
	zf_o_disSapper = FindSendPropInfo("CObjectDispenser", "m_bHasSapper");
	zf_o_disDisable = FindSendPropInfo("CObjectDispenser", "m_bDisabled");
	zf_o_origin = FindSendPropOffs("CBasePlayer","m_vecOrigin");
	
	CreateConVar("sm_zf_version", PLUGIN_VERSION, "The Zombie Fortress Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	zf_cvar_ForceOn = CreateConVar("sm_zf_force_on", "0", "On \"1\" ZF remains action on non-ZF map change.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	zf_cvar_Ratio = CreateConVar("sm_zf_ratio", "0.60", "Percentage of players on the survivor team at start (0.60 = 60%).", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AutoExecConfig(true, "plugin_zf");
	HookEvent("player_spawn", event_Spawn);
	HookEvent("player_builtobject", event_Build);
	HookEvent("teamplay_round_start", event_Start);
	HookEvent("teamplay_round_win", event_End);
	HookEvent("player_death", event_Death);
	HookEvent("player_say", event_Chat);
	
	RegAdminCmd("sm_zf_enable", command_Enable, ADMFLAG_GENERIC,"Activates the Zombie Fortress plugin");
	RegAdminCmd("sm_zf_disable", command_Disable, ADMFLAG_GENERIC,"Deactivates the Zombie Fortress plugin")
	RegConsoleCmd("equip", command_Equip); //On same class reselect
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", event_Spawn);
	UnhookEvent("player_builtobject", event_Build);
	UnhookEvent("teamplay_round_start", event_Start);
	UnhookEvent("teamplay_round_win", event_End);
	UnhookEvent("player_death", event_Death);
	UnhookEvent("player_say ", event_Chat);
}

public OnMapStart()
{
	zf_maxPlayers = GetMaxClients();
	zf_maxEntities = GetMaxEntities();
	function_ResetHistory();
	
	new String:Map[256];
	GetCurrentMap(Map, sizeof(Map));
	if (StrContains(Map, "zf_", false) != -1)
	{
		if (zf_b_isActive == false)
			function_Enable ();
	}
	else
	{
		if ((zf_b_isActive == true) && (GetConVarInt(zf_cvar_ForceOn) == 0))
			function_Disable ();
	}
}

public onMapEnd()
{
	new String:Map[256];
	GetCurrentMap(Map, sizeof(Map));
	if (StrContains(Map, "zf_", false) != -1)
	{
		if ((zf_b_isActive == true) && (GetConVarInt(zf_cvar_ForceOn) == 0))
			function_Disable ();
	}
}

public OnClientDisconnected(client)
{
	if (zf_b_isActive == false)
		return;
	zf_a_history[client] = 0;
	zf_a_zombies[client] = 0;
	if ((GetTeamClientCount(client) == 0) && (zf_b_logDeaths == true))
	{
		function_ZombieWin();
	}
}


////COMMANDS

public Action: command_Enable (client, args)
{
	if (zf_b_isActive == false)
	{
		ServerCommand("mp_restartround 5");
		function_Enable ();
	}
}

public Action: command_Disable (client, args)
{
	if (zf_b_isActive == true)
	{
		ServerCommand("mp_restartround 5");
		function_Disable ();
	}
}

public Action:command_Equip(client, args) 
{
	if (zf_b_isActive == false)
		return;
	function_PlayerSpawn(client);
}

public Action:OnClientCommand(client, args)
{
	if (zf_b_isActive != false)
	{
		new String:cmd0[91];
		new String:cmd1[91];
		new String:cmd2[91]
		GetCmdArg(0, cmd0, sizeof(cmd0));
		GetCmdArg(1, cmd1, sizeof(cmd1));
		GetCmdArg(2, cmd2, sizeof(cmd2));
		if ((StrEqual(cmd0, "voicemenu")) && (StrEqual(cmd1, "0")) && (StrEqual(cmd2, "0")))
		{
			new TFClassType:class = TF2_GetPlayerClass(client);
			if (class == TFClass_Scout)
			{
				if ((GetClientHealth(client) == 125) && (zf_t_Recharge[client] == INVALID_HANDLE))
				{
					zf_t_Recharge[client] = CreateTimer(30.0, timer_Recharge, client);
					ClientCommand(client, "voicemenu 2 1");
					PrintHintText(client, "Overheal Active");
					SetEntityHealth(client, 200);
				}
				else
				{
					ClientCommand(client, "voicemenu 2 5");
				}
				return Plugin_Handled;
			}
			else if (class == TFClass_Heavy) 
			{
				if ((GetClientHealth(client) == 300) && (zf_t_Recharge[client] == INVALID_HANDLE))
				{
					zf_t_Recharge[client] = CreateTimer(30.0, timer_Recharge, client);
					ClientCommand(client, "voicemenu 2 1");
					PrintHintText(client, "Overheal Active");
					SetEntityHealth(client, 450);
				}
				else
				{
					ClientCommand(client, "voicemenu 2 5");
				}
				return Plugin_Handled;
			}
			else if (class == TFClass_Spy) 
			{
				if (zf_t_Recharge[client] == INVALID_HANDLE)
				{
					if (GetEntPropFloat(client,Prop_Send,"m_flCloakMeter") != 100)
					{
						zf_t_Recharge[client] = CreateTimer(30.0, timer_Recharge, client);
						ClientCommand(client, "voicemenu 2 1");
						PrintHintText(client, "Cloak Recharged");
						SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
					}
					else
					{
						ClientCommand(client, "voicemenu 2 5");
						PrintHintText(client, "Cloak is already full.");
					}
				}
				else
				{
					ClientCommand(client, "voicemenu 2 5");
				}
				return Plugin_Handled;
			}
		}
		else if (StrEqual(cmd0, "taunt"))
		{
			if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
			{
				new String:weapon[34];
				GetClientWeapon(client, weapon, 34); 
				if ((strcmp(weapon, "tf_weapon_bottle", false)) == 0)
				{
					if (zf_a_drinking[client] == 0)
					{
						zf_a_drinking[client] = 1;
						CreateTimer(2.2, timer_DrinkingHeal, client);
						CreateTimer(4.5, timer_FinishedDrinking, client);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}


////BASIC FUNCTIONS

public function_Enable ()
{
	function_ResetZombies();
	function_ResetHistory();
	zf_b_joinWindow = true;
	zf_b_isActive = true;
	zf_b_logDeaths = false;
	ServerCommand ("mp_autoteambalance 0");
	ServerCommand ("sm_cvar tf_max_health_boost 1.25");
	ServerCommand ("sm_cvar tf_boost_drain_time 3600");
	//SPY Hidden Cvars
	ServerCommand ("sm_cvar tf_spy_cloak_consume_rate 25.0");
	ServerCommand ("sm_cvar tf_spy_cloak_regen_rate 0");
	ServerCommand ("sm_cvar tf_spy_cloak_no_attack_time 1.0");
	ServerCommand ("sm_cvar tf_spy_invis_unstealth_time 0.1");
	ServerCommand ("sm_cvar tf_spy_invis_time 0.1");
	function_DisableResupply(true);
	if (zf_t_Help != INVALID_HANDLE)
	{
		CloseHandle(zf_t_Help);
		zf_t_Help = INVALID_HANDLE;
	}
	zf_t_Help = CreateTimer(300.0, timer_Help, _, TIMER_REPEAT);
	if (zf_t_Period != INVALID_HANDLE)
	{
		CloseHandle(zf_t_Period);
		zf_t_Period = INVALID_HANDLE;
	}
	zf_t_Period = CreateTimer(1.0, timer_Periodic, _, TIMER_REPEAT);
}

public function_Disable()
{
	function_ResetZombies();
	function_ResetHistory();
	zf_b_isActive = false;
	zf_b_logDeaths = false;
	ServerCommand ("mp_autoteambalance 1");
	ServerCommand ("sm_cvar tf_max_health_boost 1.5");
	ServerCommand ("sm_cvar tf_boost_drain_time 15");
	//SPY Hidden Cvars
	ServerCommand ("sm_cvar tf_spy_cloak_consume_rate 10");
	ServerCommand ("sm_cvar tf_spy_cloak_regen_rate 3.3");
	ServerCommand ("sm_cvar tf_spy_cloak_no_attack_time 2.0");
	ServerCommand ("sm_cvar tf_spy_invis_unstealth_time 2.0");
	ServerCommand ("sm_cvar tf_spy_invis_time 1.0");
	function_DisableResupply(false);
	if (zf_t_Help != INVALID_HANDLE)
	{
		CloseHandle(zf_t_Help);
		zf_t_Help = INVALID_HANDLE;
	}
	if (zf_t_Period != INVALID_HANDLE)
	{
		CloseHandle(zf_t_Period);
		zf_t_Period = INVALID_HANDLE;
	}
}

function_DisableResupply(bool:activate) 
{
	new search = -1;
	if (activate == true)
	{
		while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
			AcceptEntityInput(search, "Disable");
	}
	else
	{
		while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
			AcceptEntityInput(search, "Enable");
	}
}

public function_ResetZombies()
{
	for (new i = 0; i < sizeof(zf_a_zombies); i++)
	{
		zf_a_zombies[i] = 0;
	}
}

public function_ResetHistory()
{
	zf_timeHigh = 0;
	zf_timeGames = 0;
	for (new i = 0; i < sizeof(zf_a_zombies); i++)
	{
		zf_a_history[i] = 0;
		zf_a_help[i] = 0;
	}
}


////EVENTS

public Action:event_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (zf_b_isActive == false)
		return;
	function_DisableResupply(true);
	function_Balance();
	
	//Get time for leaderboard.
	zf_timeStart = GetGameTime();
	
	//Reset wave times
	zf_respawnTime = zf_respawnSet[1];
	zf_respawnCounter = 1;
	function_RespawnTime();
	
	//Mark current players of the Zombie Team and log player's team histories.
	for (new i = 1; i <= zf_maxPlayers; i++)
	{
		if (IsClientInGame(i)) 
		{
			if (GetClientTeam(i) == ZOM)
			{
				if (zf_a_history[i] < 0)
				{
					zf_a_history[i] = 0;
				}
				zf_a_history[i]++;
				zf_a_zombies[i] = 1;
			}
			else
			{
				if (zf_a_history[i] > 0)
				{
					zf_a_history[i] = 0;
				}
				zf_a_history[i]--;
			}
			function_checkHelp(i);
		}
	}
	zf_b_logDeaths = true;
	zf_b_zombiesWin = false;
}

public Action:event_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (zf_b_isActive == false)
		return;
	new winner = GetEventInt(event, "team");
	new gameTime = RoundToFloor(GetGameTime() - zf_timeStart);
	if (winner == ZOM)
	{
		if (zf_timeHigh == 0)
		{
			PrintToChatAll("\x05[ZF] [Announcement]\x01 Current survival record now set at \x03%d:%d\x01.", gameTime / 60, gameTime % 60);
			zf_timeHigh = gameTime;
		}
		else if (gameTime > zf_timeHigh)
		{
			PrintToChatAll("\x05[ZF] [Announcement]\x01 New survival record set at \x03%d:%d\x01.", gameTime / 60, gameTime % 60);
			PrintToChatAll("\x05\x01Previous survival record was \x03%d:%d\x01 and was held for \x03%d\x01 games.", zf_timeHigh / 60, zf_timeHigh % 60, zf_timeGames);
			zf_timeHigh = gameTime;
			zf_timeGames = 0;
		}
		else if (gameTime < zf_timeHigh)
		{
			zf_timeGames++;
			PrintToChatAll("\x05[ZF] [Announcement]\x01 Current survival record is \x03%i:%i\x01 and was held for \x03%i\x01 games.", zf_timeHigh / 60, zf_timeHigh % 60, zf_timeGames);
			PrintToChatAll("\x05\x01Your survival time was \x03%d:%d\x01.", gameTime / 60, gameTime % 60);
		}
	}
	else if (winner == SUR)
	{
		zf_timeHigh = 0;
		zf_timeGames = 0;
	}
	
	zf_b_logDeaths = false;
}

public Action:event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (zf_b_isActive == false)
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	function_PlayerSpawn(client);
}

public Action:event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((zf_b_isActive == false) || (zf_b_logDeaths == false))
		return;
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	if (team == SUR)
	{
		if (zf_respawnTime == zf_respawnSet[1])
		{
			zf_respawnCounter = 0;
		}
		CreateTimer(0.1, timer_Zombify, client);
		zf_a_zombies[client] = 1;
	}
	else if (team == ZOM)
	{
		//Zombie Respawn Stuff
		if (zf_respawnTime == zf_respawnSet[0])
		{
			zf_respawnCounter--;
		}
		
		//Remove ammopack drops from zombies.
		decl String:netclass[32];
		for (new i = zf_maxPlayers + 1; i <= zf_maxEntities; i++)
		{
			if (IsValidEntity(i))
			{
				GetEntityNetClass(i, netclass, sizeof(netclass));
				if (strcmp(netclass, "CTFAmmoPack", false) == 0)
				{
					if (GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client)
					{
						AcceptEntityInput(i, "Kill");
					}
				}
			}
		}
		
		if ((IsValidEntity(killer)) && (killer > 0))
		{
			if (IsClientInGame(killer))
			{
				if (TF2_GetPlayerClass(killer) == TFClass_Sniper)
				{
					CreateTimer(0.5, timer_Sniper, killer);
				}
				else if (TF2_GetPlayerClass(killer) == TFClass_Soldier)
				{
					SetEntData(killer, zf_o_ammo + 4, GetEntData(killer, zf_o_ammo + 4) + 2);
				}
				new assist = GetClientOfUserId(GetEventInt(event, "assister"));
				if ((IsValidEntity(assist)) && (assist > 0))
				{
					if (IsClientInGame(assist))
					{
						if (TF2_GetPlayerClass(assist) == TFClass_Sniper)
						{
							CreateTimer(0.5, timer_Sniper, assist);
						}
						else if (TF2_GetPlayerClass(assist) == TFClass_Soldier)
						{
							SetEntData(assist, zf_o_ammo + 4, GetEntData(assist, zf_o_ammo + 4) + 2);
						}
					}
				}
			}
		}
		
		//If the first death this round, disable players from joing red.
		if (zf_b_joinWindow == true)
		{
			if (killer != client)
			{
				zf_b_joinWindow = false;
				PrintToChatAll("\x05[ZF] [Announcement]\x01 Someone has been killed. Spectators can now only join the zombie team.");
			}
		}
	}
}

public Action:event_Build(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (zf_b_isActive == false)
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:object[54];
	GetEventString(event, "object", object, 54);
	if ((strcmp(object,"0") == 0) || (strcmp(object,"3") == 0))
	{
		for (new i = zf_maxPlayers + 1; i <= zf_maxEntities; i++)
		{
			if (IsValidEntity(i))
			{
				decl String:netclass[32];
				GetEntityNetClass(i, netclass, sizeof(netclass));
				if (strcmp(netclass, "CObjectDispenser") == 0)
				{
					SetEntData(i, zf_o_disSapper, 2);
					CreateTimer(21.5, timer_Disable, i);
				}
				else if (strcmp(netclass, "CObjectSentrygun") == 0)
				{
					if (GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client)
					{
						zf_a_sentries[client] = i;
					}
				}
			}
		}
	}
}

////GAMEPLAY FUNCTIONS

public function_Balance()
{
	function_ResetZombies();
	zf_b_joinWindow = true;
	zf_b_logDeaths = false;
	
	//Makes a list of current players.
	new clientList [zf_maxPlayers];
	new clientPointer = 0;
	for (new i = 1; i <= zf_maxPlayers; i++)
	{
		if (IsValidEntity(i))
		{
			if (IsClientInGame(i)) 
			{
				clientList[clientPointer] = i;
				clientPointer++;
			}
		}
	}
	
	//Calculates team size ratios.
	new Float:ratio = GetConVarFloat(zf_cvar_Ratio);
	new teams = GetTeamClientCount(SUR) + GetTeamClientCount(ZOM);
	new teamS = RoundToNearest((teams*ratio)+0.01);
	new teamZ = RoundToNearest(teams*(1 - ratio));
	
	//Distributes players accordingly.
	new rand;
	new temp;
	new historyList[zf_maxPlayers];
	new historyPointer = 0;
	
	//Fill survivor team.
	for (new i = 0; i < clientPointer; i++)
	{
		if(zf_a_history[i] > 1)
		{
			historyList[historyPointer] = i;
			historyPointer++;
		}
	}
	while (teamS > 0)
	{
		if (historyPointer > 0)
		{
			rand = GetRandomInt(0, historyPointer - 1);
			temp = historyList[rand]
			historyList[rand] = historyList[historyPointer - 1];
			historyPointer--;
			for (new i = 0; i < clientPointer; i++)
			{
				if(clientList[i] == temp)
				{
					rand = i;
					i = clientPointer;
					zf_a_history[temp] = 0;
				}
			}
		}
		else
		{
			rand = GetRandomInt(0, clientPointer - 1);
		}
		if (GetClientTeam(clientList[rand]) != SUR)
		{
			SetEntProp(clientList[rand], Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(clientList[rand],SUR);
			TF2_RespawnPlayer(clientList[rand]);
			SetEntProp(clientList[rand], Prop_Send, "m_lifeState", 0);
		}
		else
		{
			TF2_RespawnPlayer(clientList[rand]);
		}
		clientList[rand] = clientList[clientPointer - 1];
		clientPointer--;
		teamS--;
	}
	
	//Fill zombie team.
	historyPointer = 0;
	for (new i = 0; i < clientPointer; i++)
	{
		if(zf_a_history[i] < -2)
		{
			historyList[historyPointer] = i;
			historyPointer++;
		}
	}
	while (teamZ > 0)
	{
		if (historyPointer > 0)
		{
			rand = GetRandomInt(0, historyPointer - 1);
			temp = historyList[rand]
			historyList[rand] = historyList[historyPointer - 1];
			historyPointer--;
			for (new i = 0; i < clientPointer; i++)
			{
				if(clientList[i] == temp)
				{
					rand = i;
					i = clientPointer;
					zf_a_history[temp] = 0;
				}
			}
		}
		else
		{
			rand = GetRandomInt(0, clientPointer - 1);
		}
		if (GetClientTeam(clientList[rand]) != ZOM)
		{
			SetEntProp(clientList[rand], Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(clientList[rand],ZOM);
			TF2_RespawnPlayer(clientList[rand]);
			SetEntProp(clientList[rand], Prop_Send, "m_lifeState", 0);
		}
		else
		{
			TF2_RespawnPlayer(clientList[rand]);
		}
		clientList[rand] = clientList[clientPointer - 1];
		clientPointer--;
		teamZ--;
	}
}

public function_ZombieWin ()
{
	if (zf_b_isActive == false)
		return;
	if (zf_b_zombiesWin == false)
	{
		zf_b_zombiesWin = true;
		new search = -1;
		while ((search = FindEntityByClassname(search, "game_round_win")) != -1)
		{
			SetVariantInt(ZOM);
			AcceptEntityInput(search, "SetTeam");
			AcceptEntityInput(search, "RoundWin");
		}
	}
}

public function_RespawnTime ()
{
	new gameRules = FindEntityByClassname(-1, "tf_gamerules");
	SetVariantFloat(zf_respawnTime);
	AcceptEntityInput(gameRules, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
}

//On player spawn or equip, check that they are on the right team and class.
public function_PlayerSpawn(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new team = GetClientTeam(client);
	new rand;
	
	// Survivors
	if (team == SUR)
	{
		SetEntityRenderColor(client, 255, 255, 255);
		if ((zf_a_zombies[client] == 0)  && (zf_b_joinWindow == true))
		{
			if ((class == TFClass_Scout) || (class == TFClass_Heavy)|| (class == TFClass_Spy))
			{
				if (zf_b_logDeaths == true)
				{
					PrintToChat(client, "\x05[ZF] [Error]\x01 Survivors can only be soldiers, pyros, demomen, snipers, medics or engineers.");
				}
				new bool:swapped = false;
				while (!swapped)
				{
					rand = GetRandomInt(1, 9);
					if (rand != 1 && rand != 6 && rand != 8)
					{
						TF2_SetPlayerClass(client, TFClassType:rand, false, true);
						swapped = true;
					}
				} 
			}
		}
		else
		{
			if (zf_b_logDeaths == true)
			{
				PrintToChat(client, "\x05[ZF] [Error]\x01 You cannot switch to a survivor if you have been zombified.");
				ChangeClientTeam(client,ZOM);
				TF2_RespawnPlayer(client);
				return;
			}
		}
	}
	// Zombies
	else if (team == ZOM)
	{
		SetEntityRenderColor(client, 0, 100, 0);
		if (zf_a_zombies[client] == 0)
		{
			zf_a_zombies[client] = 1;
		}
		if ((class != TFClass_Scout) && (class != TFClass_Heavy) && (class != TFClass_Spy))
		{
			if (zf_b_logDeaths == true)
			{
				PrintToChat(client, "\x05[ZF] [Error]\x01 Zombies can only be scouts, spies or heavies.");
			}
			rand = GetRandomInt(1, 3);
			switch (rand)
			{
				case 1:
				{
					TF2_SetPlayerClass(client, TFClass_Scout, false, true);
				}
				case 2:
				{
					TF2_SetPlayerClass(client, TFClass_Heavy, false, true);
				}
				case 3:
				{
					TF2_SetPlayerClass(client, TFClass_Spy, false, true);
				}
			}
		}
		ClientCommand(client, "slot3");
	}
	CreateTimer(0.1, timer_SetPlayers, client);
	CreateTimer(0.5, timer_SetPlayers, client);
}

////TIMERS

public Action:timer_FinishedDrinking(Handle:timer, any:client)
{
	if (zf_b_isActive != false)
	{
		zf_a_drinking[client] = 0;
	}
	return Plugin_Continue;
}

public Action:timer_DrinkingHeal(Handle:timer, any:client)
{
	if (zf_b_isActive != false)
	{
		if (IsValidEntity(client))
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				new health = GetClientHealth(client);
				if ((health >= 150) && (health < 175))
				{
					SetEntityHealth(client, 175);
				}
				else if (health < 150)
				{
					SetEntityHealth(client, health + 25);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:timer_Sniper(Handle:timer, any:client)
{
	if (zf_b_isActive != false)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			new ammo = GetEntData(client, zf_o_ammo + 4);
			if (ammo > 20)
			{
				SetEntData(client, zf_o_ammo + 4, 25);
			}
			else
			{
				SetEntData(client, zf_o_ammo + 4, ammo + 5);
			}
			ammo = GetEntData(client, zf_o_ammo + 8);
			if (ammo > 50)
			{
				SetEntData(client, zf_o_ammo + 8, 75);
			}
			else
			{
				SetEntData(client, zf_o_ammo + 8, ammo + 25);
			}
		}
	}
	return Plugin_Continue;
}

public Action:timer_Zombify(Handle:timer, any:client)
{
	if (zf_b_isActive != false)
	{
		if ((IsValidEntity(client)) && (client > 0))
		{
			if (IsClientInGame(client)) 
			{
				ChangeClientTeam(client,ZOM);
				
				new rand = GetRandomInt(1, 3);
				switch (rand)
				{
					case 1:
					{
						TF2_SetPlayerClass(client, TFClass_Scout, false, true);
					}
					case 2:
					{
						TF2_SetPlayerClass(client, TFClass_Heavy, false, true);
					}
					case 3:
					{
						TF2_SetPlayerClass(client, TFClass_Spy, false, true);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:timer_SetPlayers(Handle:timer, any:client)
{	
	if (zf_b_isActive != false)
	{
		if (IsValidEntity(client))
		{
			if (IsClientInGame(client) && IsPlayerAlive(client)) 
			{
				new team = GetClientTeam(client);
				new TFClassType:class = TF2_GetPlayerClass(client);
				if (team == ZOM)
				{
					ClientCommand(client, "slot3");
					TF2_RemoveWeaponSlot(client, 0);
					TF2_RemoveWeaponSlot(client, 3);
					TF2_RemoveWeaponSlot(client, 4);
					TF2_RemoveWeaponSlot(client, 5);
					if (class == TFClass_Heavy)
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 280.0);
						//Check Sandvitch
						new weapon = GetPlayerWeaponSlot(client, 1);
						if (IsValidEntity(weapon))
						{
							if (GetEntProp(weapon, Prop_Send, "m_iEntityQuality") != 3)
							{
								TF2_RemoveWeaponSlot(client, 1);
							}
						}
					}
					else if (class == TFClass_Spy)
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 260.0);
						TF2_RemoveWeaponSlot(client, 1);
					}
					else
					{
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 340.0);
						TF2_RemoveWeaponSlot(client, 1);
					}
					ClientCommand(client, "slot3");
					if (zf_t_Recharge[client] != INVALID_HANDLE)
					{
						KillTimer(zf_t_Recharge[client]);
					}
					zf_t_Recharge[client] = INVALID_HANDLE;
				}
				else if (class == TFClass_Soldier)
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 280.0);
				}
				else if (class == TFClass_Pyro)
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 240.0);
				}
				
				if (team == SUR)
				{
					function_displayInfo(class, client);
				}
			}
		}
	}
	return Plugin_Continue;
}

//Activates after a dispenser finishes construction.
public Action:timer_Disable(Handle:timer, any:object)
{
	if (zf_b_isActive != false)
	{
		if (IsValidEntity(object))
		{
			SetEntData(object, zf_o_disDisable, 1);
			SetEntData(object, zf_o_disSapper, 0);
		}
	}
	return Plugin_Continue;
}

public bool:function_anyDead()
{
	for (new i = 1; i <= zf_maxPlayers; i++)
	{
		if (IsValidEntity(i))
		{
			if (IsClientInGame(i) && (GetClientTeam(i) == ZOM) && !IsPlayerAlive(i))
			{
				return true;
			}
		}
	}
	return false;
}

public Action:timer_Periodic(Handle:timer)
{
	if (zf_b_isActive != false)
	{
		//Sentry decay.
		for (new i = 1; i <= zf_maxPlayers; i++)
		{
			if (IsValidEntity(zf_a_sentries[i]))
			{
				GetEntityNetClass(zf_a_sentries[i], zf_p_netclass, sizeof(zf_p_netclass));
				if (strcmp(zf_p_netclass, "CObjectSentrygun") == 0)
				{
					if (GetEntPropFloat(zf_a_sentries[i], Prop_Send, "m_flPercentageConstructed") == 1.0)
					{
						if (GetEntData(zf_a_sentries[i], zf_o_sentrySapper) != 2)
						{
							SetEntData(zf_a_sentries[i], zf_o_sentrySapper, 2);
						}
						new ammo = GetEntProp(zf_a_sentries[i], Prop_Send, "m_iAmmoShells");
						if (ammo > 60)
						{
							SetEntProp(zf_a_sentries[i], Prop_Send, "m_iAmmoShells", 60);
						}
						else if (ammo < 60)
						{
							if (ammo == 0)
							{
								SetVariantInt(100);
							}
							else
							{
								SetVariantInt(7);
							}
							AcceptEntityInput(zf_a_sentries[i], "RemoveHealth");
						}
					}
				}
			}
		}
		
		//Zombie regeneration and pyro ammo degeneration.
		for (new i = 1; i <= zf_maxPlayers; i++)
		{
			if (IsValidEntity(i))
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					GetEntDataVector(i, zf_o_origin, zf_p_playerLocs[i]);
					zf_p_class = TF2_GetPlayerClass(i);
					if (zf_p_class == TFClass_Spy)
					{
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 260.0);
						zf_p_health = GetClientHealth(i);
						if ((zf_p_health >= 123) && (zf_p_health < 125))
						{
							SetEntityHealth(i, 125);
						}
						else if (zf_p_health < 123)
						{
							SetEntityHealth(i, zf_p_health + 2);
						}
					}
					else if ((zf_p_class == TFClass_Scout))
					{
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 400.0);
						zf_p_health = GetClientHealth(i);
						if (zf_p_health != 125)
						{
							if ((zf_p_health >= 123) && (zf_p_health < 125))
							{
								SetEntityHealth(i, 125);
							}
							else if (zf_p_health < 123)
							{
								SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 340.0);
								SetEntityHealth(i, zf_p_health + 2);
								
							}
							else if ((zf_p_health > 125) && (zf_p_health < 130))
							{
								SetEntityHealth(i, 125);
							}
							else
							{
								SetEntityHealth(i, zf_p_health - 5);
							}
						}
					}
					else if (zf_p_class == TFClass_Heavy)
					{
						SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 280.0);
						zf_p_health = GetClientHealth(i);
						if (zf_p_health != 300)
						{
							if ((zf_p_health >= 293) && (zf_p_health < 300))
							{
								SetEntityHealth(i, 300);
							}
							else if (zf_p_health < 293)
							{
								SetEntityHealth(i, zf_p_health + 2);
								SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 240.0);
							}
							else if ((zf_p_health > 300) && (zf_p_health < 310))
							{
								SetEntityHealth(i, 300);
							}
							else
							{
								SetEntityHealth(i, zf_p_health - 10);
							}
						}
					}
					else if (zf_p_class == TFClass_Pyro)
					{
						zf_p_ammo = GetEntData(i, zf_o_ammo + 4);
						if ((zf_p_ammo > 100) && (zf_p_ammo <= 110))
						{
							SetEntData(i, zf_o_ammo + 4, 100);
						}
						else if (zf_p_ammo > 100)
						{
							SetEntData(i, zf_o_ammo + 4, zf_p_ammo - 10);
						}
					}
					else if (zf_p_class == TFClass_Sniper)
					{
						zf_p_clip = GetEntData(GetPlayerWeaponSlot(i, 1), zf_o_clip);
						zf_p_ammo = GetEntData(i, zf_o_ammo + 8);
						if (zf_p_clip < 25)
						{
							zf_p_difference = 25 - zf_p_clip;
							if (zf_p_ammo >= zf_p_difference)
							{
								SetEntData(i, zf_o_ammo + 8, zf_p_ammo - zf_p_difference);
								SetEntData(GetPlayerWeaponSlot(i, 1), zf_o_clip, 25);
							}
							else
							{
								SetEntData(i, zf_o_ammo + 8, 0);
								SetEntData(GetPlayerWeaponSlot(i, 1), zf_o_clip, zf_p_clip + zf_p_ammo);
							}
						}
					}
				}
			}
		}
		
		//Zombie Respawn Time
		if (zf_respawnTime == zf_respawnSet[0])
		{
			if (zf_respawnCounter < 1)
			{
				if (function_anyDead() == false)
				{
					zf_respawnCounter = 60;
					zf_respawnTime = zf_respawnSet[2];
					function_RespawnTime();
					PrintCenterTextAll("The horde rests... %d second respawn time.", RoundToZero(zf_respawnTime));
				}
			}
		}
		else if (zf_respawnTime == zf_respawnSet[1])
		{
			if (zf_respawnCounter == 0)
			{
				zf_respawnCounter = zf_maxPlayers;
				zf_respawnTime = zf_respawnSet[0];
				function_RespawnTime();
				PrintCenterTextAll("The horde is frenzied! %d second respawn time.", RoundToZero(zf_respawnTime));
			}
		}
		else if (zf_respawnTime == zf_respawnSet[2])
		{
			if (zf_respawnCounter < 1)
			{
				if (function_anyDead() == false)
				{
					zf_respawnCounter = 1;
					zf_respawnTime = zf_respawnSet[1];
					function_RespawnTime();
					PrintCenterTextAll("The horde hungers... %d second respawn time.", RoundToZero(zf_respawnTime));
				}
			}
			else
			{
				zf_respawnCounter--;
			}
		}
		
		//Checks the distance between each zombie player and sets their horde value.
		if (zf_p_beatTimer > 0)
		{
			zf_p_beatTimer--;
		}
		else
		{
			zf_p_beatTimer = 1;
			for (new i = 1; i <= zf_maxPlayers; i++)
			{
				if (IsValidEntity(i))
				{
					if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == SUR))
					{
						zf_p_isAlone = true;
						for (new j = 1; j <= zf_maxPlayers; j++)
						{
							if (IsValidEntity(j))
							{
								if (IsClientInGame(j) && IsPlayerAlive(j) && (GetClientTeam(j) == SUR) && (j != i))
								{
									if (GetVectorDistance(zf_p_playerLocs[i], zf_p_playerLocs[j]) <= 600)
									{
										zf_p_isAlone = false;
									}
								}
							}
						}
						if (zf_p_isAlone == true)
						{
							EmitAmbientSound(SOUND_HEART, zf_p_playerLocs[i], i, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, 90, 0.0);
						}
						
					}
				}
			}
		}
		
		//Check if any survivors are alive
		if ((GetTeamClientCount(SUR) == 0) && (GetTeamClientCount(ZOM) > 0))
		{
			function_ZombieWin();
		}
	}
}

public Action:timer_Recharge(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		if (IsClientInGame(client) && IsPlayerAlive(client)) 
		{
			PrintHintText(client, "Ability Recharged");
		}
	}
	zf_t_Recharge[client] = INVALID_HANDLE;
	return Plugin_Continue;
}



////HELP INFORMATION

public function_checkHelp(client)
{
	if (zf_a_help[client] == 4)
		return;
	new team = GetClientTeam(client);
	if (zf_a_help[client] == 0)
	{
		zf_a_help[client] = team;
		PrintToChat(client, "\x05[ZF] [Help]\x01 You have joined a server running the Zombie Fortress %s plugin.", PLUGIN_VERSION);
		function_Help(client, team);
	}
	else if (zf_a_help[client] == SUR)
	{
		if (team != SUR)
		{
			function_Help(client, team);
			zf_a_help[client] = 4;
		}
	}
	else if (zf_a_help[client] == ZOM)
	{
		if (team != ZOM)
		{
			function_Help(client, team);
			zf_a_help[client] = 4;
		}
	}
}

//Broadcasts the help message.
public Action:timer_Help(Handle:timer)
{
	if (zf_b_isActive != false)
	{
		PrintToChatAll("\x05[ZF] [Announcement]\x01 Zombie Fortress %s is currently active. Type in \"zf_help\" in chat to receive information about your team and \"zf_class\" about your class.", PLUGIN_VERSION);
		PrintToChatAll("Have any comments? Head over to www.zf.sovietgaming.net and hit the forums.");
	}
	return Plugin_Continue;
}

//When a player says something - check if he asked for help.
public Action:event_Chat(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (zf_b_isActive != false)
	{
		decl String:chatText[191];
		GetEventString(event, "text", chatText, sizeof(chatText));
		if ((strcmp(chatText, "zf_help", false)) == 0)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new team = GetClientTeam(client);
			function_Help(client, team)
		}
		else if ((strcmp(chatText, "zf_class", false)) == 0)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			new TFClassType:class = TF2_GetPlayerClass(client);
			function_displayInfo(class, client);
		}
		else if ((strcmp(chatText, "zf_sentry", false)) == 0)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (IsValidEntity(zf_a_sentries[client]))
			{
				GetEntityNetClass(zf_a_sentries[client], zf_p_netclass, sizeof(zf_p_netclass));
				if (strcmp(zf_p_netclass, "CObjectSentrygun") == 0)
				{
					SetVariantInt(100);
					AcceptEntityInput(zf_a_sentries[client], "RemoveHealth");
					return;
				}
			}
			PrintToChat(client, "\x05[ZF] [Error]\x01 You don't have a Sentry constructed.");
		}
	}
}

public function_Help(client, team)
{
	if (team == SUR)
	{
		PrintToChat(client, "\x05[ZF] [Help]\x01 The survivors team includes all classes aside for the scout, spy and heavy. Complete the map's objectives to win. If you are killed you become a zombie.");
		PrintToChat(client, "When you are alone, you emit an audible heartbeat that other survivors and zombies can find you with.");
	}
	else if (team == ZOM)
	{
		PrintToChat(client, "\x05[ZF] [Help]\x01 The zombie team is made up of melee-only scouts, spies and heavies. Your objective is to kill all the survivors and turn them into zombies. Only zombies can respawn.");
	}
}

//Displays a class information panel to a client depending on their class.
public function_displayInfo(TFClassType:class, client)
{
	new Handle:panel = CreatePanel();
	switch(class)
	{
		case TFClass_Sniper:
		{
			SetPanelTitle(panel, "Sniper [Survivor/Support]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>Regains 5 rifle and 25 SMG rounds");
			DrawPanelText(panel, "every time the sniper kills a zombie.");
			DrawPanelText(panel, ">>The SMG does not need to reload.");
		}
		case TFClass_Medic:
		{
			SetPanelTitle(panel, "Medic [Survivor/Support]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>The Medigun's overheal is capped");
			DrawPanelText(panel, "at 125 (-25) percent health.");
			DrawPanelText(panel, ">>The Medigun's overheal does not");
			DrawPanelText(panel, "degenerate.");
		}
		case TFClass_Soldier:
		{
			SetPanelTitle(panel, "Soldier [Survivor/Assualt]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>Movement speed increased to");
			DrawPanelText(panel, "280 (+40).");
			DrawPanelText(panel, ">>Regains 2 rockets every time the");
			DrawPanelText(panel, "soldier kills a zombie.");
		}
		case TFClass_Pyro:
		{
			SetPanelTitle(panel, "Pyro [Survivor/Assualt]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>Movement speed decreased to");
			DrawPanelText(panel, "240 (-60).");
			DrawPanelText(panel, ">>The flamethrower canister will");
			DrawPanelText(panel, "leak if it has more than 100 ammo.");
		}
		case TFClass_DemoMan:
		{
			SetPanelTitle(panel, "Demoman [Survivor/Assualt]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>Bottle taunt heals 25 health.");
		}
		case TFClass_Engineer:
		{
			SetPanelTitle(panel, "Engineer [Survivor/Support]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>Sentries cannot be repaired,");
			DrawPanelText(panel, "upgraded or demolished.");
			DrawPanelText(panel, ">>Sentries lose health over time,");
			DrawPanelText(panel, "after their first shot, lasting");
			DrawPanelText(panel, "aprox. 22 seconds before exploding.");
			DrawPanelText(panel, ">>Sentries explode when out of ammo.");
			DrawPanelText(panel, ">>Dispensers do not supply and");
			DrawPanelText(panel, "instead act as barricades.");
			DrawPanelText(panel, ">>Type \"zf_sentry\" to destroy");
			DrawPanelText(panel, "your sentry.");
		}
		case TFClass_Spy:
		{
			SetPanelTitle(panel, "Spy [Zombie/Support]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>Press \"call for medic\" to recharge");
			DrawPanelText(panel, "the spy's cloak. 30s Cooldown.");
			DrawPanelText(panel, ">>Movement speed decreased to");
			DrawPanelText(panel, "260 (-40).");
			DrawPanelText(panel, ">>Melee only.");
			DrawPanelText(panel, ">>Cloak does not regenerate.");
			DrawPanelText(panel, ">>Can cloak for 4 seconds.");
			DrawPanelText(panel, ">>Cloaking effect instantaneous.");
			DrawPanelText(panel, ">>Regains 2 health every second.");
			DrawPanelText(panel, ">>Respawn time reduced by 1 sec for");
			DrawPanelText(panel, "every nearby zombie (min 10 sec).");
		}
		case TFClass_Scout:
		{
			SetPanelTitle(panel, "Scout [Zombie/Assualt]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>Press \"call for medic\"to activate");
			DrawPanelText(panel, "Overheal when at full health. 30s CD.");
			DrawPanelText(panel, ">>Movement speed decreased to ");
			DrawPanelText(panel, ">>340 (-60), 400 at full health.");
			DrawPanelText(panel, ">>Melee only.");
			DrawPanelText(panel, ">>Regains 2 health every second.");
			DrawPanelText(panel, ">>Respawn time reduced by 1 sec for");
			DrawPanelText(panel, "every nearby zombie (min 10 sec).");
		}
		case TFClass_Heavy:
		{
			SetPanelTitle(panel, "Heavy [Zombie/Assualt]");
			DrawPanelText(panel, "---------------------------------");
			DrawPanelText(panel, ">>Press \"call for medic\"to activate");
			DrawPanelText(panel, "Overheal when at full health. 30s CD.");
			DrawPanelText(panel, ">>Movement speed increased to ");
			DrawPanelText(panel, ">>240 (+10), 280 at full health.");
			DrawPanelText(panel, ">>Melee and Sandvitch only.");
			DrawPanelText(panel, ">>Regains 2 health every second.");
			DrawPanelText(panel, ">>Respawn time reduced by 1 sec for");
			DrawPanelText(panel, "every nearby zombie (min 10 sec).");
		}
	}
	DrawPanelText(panel, "---------------------------------");
	DrawPanelText(panel, "This messages fades in 8 seconds.");
	DrawPanelItem(panel, "Hide Class Information.");
	SendPanelToClient(panel, client, PanelHandler, 8);
	
	CloseHandle(panel);
}

//Dummy panel handler.
public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
}
