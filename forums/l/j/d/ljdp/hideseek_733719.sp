#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION  "0.2"

public Plugin:myinfo = 
{
	name = "Hide n Seek",
	author = "Perky",
	description = "Pyro seekers search for spy hiders.",
	version = PLUGIN_VERSION,
	url = "http://www.ljdp.890m.com/"
}

////GLOBAL VARIABLES

//Team Integers
new HIDE = 3;
new SEEK = 2;

//Misc Variables
new hs_maxPlayers;
new hs_lastTeam[33];

//Booleans
new bool:zf_b_joinWindow;
new bool:hs_active;
new bool:hs_inPlay;
new bool:hs_hidersWin;
new bool:hs_seekersWin;

//Handles
new Handle:zf_t_Period = INVALID_HANDLE;


////CALLBACKS

public OnPluginStart()
{
	
	CreateConVar("sm_hs_version", PLUGIN_VERSION, "The Hide n Seek Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "plugin_hs");
	
	HookEvent("player_spawn", event_Spawn);
	HookEvent("teamplay_round_start", event_Start);
	HookEvent("teamplay_round_win", event_End);
	HookEvent("player_death", event_Death);
	HookEvent("tf_game_over", event_GameOver);
	
	RegAdminCmd("sm_hs_on", command_Enable, ADMFLAG_GENERIC,"Activates the Hide n Seek plugin");
	RegAdminCmd("sm_hs_off", command_Disable, ADMFLAG_GENERIC,"Deactivates the Hide n Seek plugin")
	RegConsoleCmd("equip", command_Equip); //On same class reselect
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", event_Spawn);
	UnhookEvent("teamplay_round_start", event_Start);
	UnhookEvent("teamplay_round_win", event_End);
	UnhookEvent("player_death", event_Death);
	UnhookEvent("tf_game_over", event_GameOver);
}

public OnMapStart()
{
	hs_maxPlayers = GetMaxClients();
}

public OnClientDisconnected(client)
{
	if (hs_active == false)
		return;

	if ((GetTeamClientCount(client) == 0) && (hs_inPlay == true))
	{
		new team = GetClientTeam(client);
		if (team == HIDE)
		{
		function_teamWin(SEEK);
		}
		if (team == SEEK)
		{
		function_teamWin(HIDE);
		}
	}
}


////COMMANDS

public Action: command_Enable (client, args)
{
	if (hs_active == false)
	{
		ServerCommand("mp_restartround 5");
		function_Enable ();
	}
}

public Action: command_Disable (client, args)
{
	if (hs_active == true)
	{
		ServerCommand("mp_restartround 5");
		function_Disable ();
	}
}

public Action:command_Equip(client, args) 
{
	if (hs_active == false)
		return;
	function_PlayerSpawn(client);
}


////BASIC FUNCTIONS

public function_Enable ()
{
	
	hs_active = true;
	zf_b_joinWindow = true;
	hs_inPlay = false;
	
	ServerCommand ("mp_autoteambalance 0");
	//SPY Hidden Cvars
	ServerCommand ("sm_cvar tf_spy_cloak_consume_rate 3");
	ServerCommand ("sm_cvar tf_spy_cloak_regen_rate 0.2");
	ServerCommand ("sm_cvar tf_spy_cloak_no_attack_time 0.3");
	ServerCommand ("sm_cvar tf_spy_invis_unstealth_time 0.3");
	ServerCommand ("sm_cvar tf_spy_invis_time 1.6");

	if (zf_t_Period != INVALID_HANDLE)
	{
		CloseHandle(zf_t_Period);
		zf_t_Period = INVALID_HANDLE;
	}
	zf_t_Period = CreateTimer(5.0, timer_Periodic, _, TIMER_REPEAT);
}

public function_Disable()
{
	hs_active = false;
	zf_b_joinWindow = true;
	hs_inPlay = false;
	
	ServerCommand ("mp_autoteambalance 1");
	//SPY Hidden Cvars
	ServerCommand ("sm_cvar tf_spy_cloak_consume_rate 10");
	ServerCommand ("sm_cvar tf_spy_cloak_regen_rate 2.2");
	ServerCommand ("sm_cvar tf_spy_cloak_no_attack_time 2.0");
	ServerCommand ("sm_cvar tf_spy_invis_unstealth_time 2.0");
	ServerCommand ("sm_cvar tf_spy_invis_time 1.0");

	if (zf_t_Period != INVALID_HANDLE)
	{
		CloseHandle(zf_t_Period);
		zf_t_Period = INVALID_HANDLE;
	}
}

public function_disableCp ()
{
	new edict_index
	new x = -1
	for (new i = 0; i < 5; i++)
		{
			edict_index = FindEntityByClassname(x, "trigger_capture_area")
			if (IsValidEntity(edict_index))
			{
				SetVariantInt(0)
				AcceptEntityInput(edict_index, "SetTeam")
				AcceptEntityInput(edict_index, "Disable")
				x = edict_index
			}
		}
		x = -1
		new flag_index
		for (new i = 0; i < 5; i++)
		{
			flag_index = FindEntityByClassname(x, "item_teamflag")
			if (IsValidEntity(flag_index))
			{
				AcceptEntityInput(flag_index, "Disable")
				x = flag_index
			}
		}
}

////EVENTS

public Action:event_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (hs_active == false)
		return;

	zf_b_joinWindow = true;
	hs_inPlay = false;
	hs_hidersWin = false;
	hs_seekersWin = false;
	function_disableCp();
	function_Balance();
}

public Action:event_End(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (hs_active == false)
		return;
}

public Action:event_GameOver(Handle:event, const String:name[], bool:dontBroadcast)
{
	if((hs_hidersWin == true) || (hs_seekersWin == true))
		return;
		
	new seek_count = function_CountThem(HIDE);
	new hide_count = function_CountThem(SEEK);
	if (seek_count > hide_count)
	{
		function_teamWin(HIDE);
	}
	else if (seek_count < hide_count)
	{
		function_teamWin(SEEK);
	}
}

public function_CountThem(team)
{
	new counter = 0;
	for (new i = 1; i <= hs_maxPlayers; i++)
	{
		if (IsValidEntity(i))
		{
			if ((IsClientInGame(i)) && (GetClientTeam(i) == team))
			{
				counter++;
			}
		}
	}
	return counter;
}

public Action:event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (hs_active == false)
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	function_PlayerSpawn(client);
}


public Action:event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (hs_active == false)
		return;

	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	if (killer != client)
	{
	if (team == HIDE)
	{
		CreateTimer(0.1, timer_Zombify, client);
	}
	else if (team == SEEK)
	{
		CreateTimer(0.1, timer_Seekerfy, client);
	}
	}
	
	//If the first death this round, disable players from joing red.
	if (zf_b_joinWindow == true)
	{
		if (killer != client)
		{
			zf_b_joinWindow = false;
			hs_inPlay  = true;
			ServerCommand ("mp_autoteambalance 0");
			PrintToChatAll("\x05[HS] [Announcement]\x01 First kill. No team Changing.");
		}
	}
}

////GAMEPLAY FUNCTIONS

public function_Balance()
{
	//Makes a list of current players.
	new clientList [hs_maxPlayers];
	new clientPointer = 0;
	
	for (new i = 1; i <= hs_maxPlayers; i++)
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
	
	new rand;
	new temp;
	for (new i = 0; i < clientPointer; i++)
	{
		rand = GetRandomInt(i, clientPointer - 1);
		temp = clientList[i];
		clientList[i] = clientList[rand];
		clientList[rand] = temp;
	}
	
	new teamToggle = 0;
	for (new i = 0; i < clientPointer; i++)
	{
		if (teamToggle != 0)
		{
			if (GetClientTeam(clientList[i]) != SEEK)
			{
				SetEntProp(clientList[i], Prop_Send, "m_lifeState", 2);
				ChangeClientTeam(clientList[i],SEEK);
				TF2_RespawnPlayer(clientList[i]);
				hs_lastTeam[clientList[i]] = SEEK;
				SetEntProp(clientList[i], Prop_Send, "m_lifeState", 0);
			}
		}
		else
		{
			if (GetClientTeam(clientList[i]) != HIDE)
			{
				SetEntProp(clientList[i], Prop_Send, "m_lifeState", 2);
				ChangeClientTeam(clientList[i],HIDE);
				TF2_RespawnPlayer(clientList[i]);
				hs_lastTeam[clientList[i]] = HIDE;
				SetEntProp(clientList[i], Prop_Send, "m_lifeState", 0);
			}
		}
		
		teamToggle++;
		if (teamToggle > 2)
			teamToggle = 0;
	}
}

//On player spawn or equip, check that they are on the right team and class.
public function_PlayerSpawn(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new team = GetClientTeam(client);
	
	if (team != hs_lastTeam[client] && hs_inPlay == true)
	{
		PrintToChat(client, "\x05[HS] [Note]\x01 You can not change team now.");
		ChangeClientTeam(client,hs_lastTeam[client]);
		TF2_RespawnPlayer(client);
	}
	else
	{
	// Seekers
	if (team == HIDE)
	{
		if (class != TFClass_Pyro)
		{	
			PrintToChat(client, "\x05[HS] [Note]\x01 Seekers can only be pyro.");
			TF2_SetPlayerClass(client, TFClass_Pyro, false, true);
		}
	}
	// Hiders
	else if (team == SEEK)
	{
		if (class != TFClass_Spy)
		{

			PrintToChat(client, "\x05[HS] [Note]\x01 Hiders can only be spy.");
			TF2_SetPlayerClass(client, TFClass_Spy, false, true);
		}
		ClientCommand(client, "slot3");
	}
	}
	
	CreateTimer(0.1, timer_SetPlayers, client);
	CreateTimer(0.5, timer_SetPlayers, client);
}

public function_teamWin (team)
{
	if (hs_active == false)
		return;
	if (hs_seekersWin == true || hs_hidersWin == true)
		return;
		
		new edict_index = FindEntityByClassname(-1, "team_control_point_master");
        if (edict_index == -1)
        {
            new g_ctf = CreateEntityByName("team_control_point_master");
            DispatchSpawn(g_ctf);
            AcceptEntityInput(g_ctf, "Enable");
        }
		
		new search = FindEntityByClassname(-1, "team_control_point_master")
		SetVariantInt(team);
		AcceptEntityInput(search, "SetWinner");
			//AcceptEntityInput(search, "SetTeam");
			//AcceptEntityInput(search, "RoundWin");
			//AcceptEntityInput(search, "kill");
		
	if (team == SEEK)
		hs_hidersWin = true;
	if (team == HIDE)
		hs_seekersWin = true;
}

////TIMERS

public Action:timer_Zombify(Handle:timer, any:client)
{
	if (hs_active != false)
	{
		if ((IsValidEntity(client)) && (client > 0))
		{
			if (IsClientInGame(client)) 
			{
				TF2_SetPlayerClass(client, TFClass_Spy, false, true);
				ChangeClientTeam(client,SEEK);
				hs_lastTeam[client] = SEEK;
			}
		}
	}
	return Plugin_Continue;
}

public Action:timer_Seekerfy(Handle:timer, any:client)
{
	if (hs_active != false)
	{
		if ((IsValidEntity(client)) && (client > 0))
		{
			if (IsClientInGame(client)) 
			{
				TF2_SetPlayerClass(client, TFClass_Pyro, false, true);
				ChangeClientTeam(client,HIDE);
				hs_lastTeam[client] = HIDE;
			}
		}
	}
	return Plugin_Continue;
}

public Action:timer_SetPlayers(Handle:timer, any:client)
{	
	if (hs_active != false)
	{
		if (IsValidEntity(client))
		{
			if (IsClientInGame(client) && IsPlayerAlive(client)) 
			{
				new team = GetClientTeam(client);
				new TFClassType:class = TF2_GetPlayerClass(client);
				if (team == SEEK)
				{
					if (class == TFClass_Spy)
					{
						PrintToChat(client, "\x05[Hide n Seek]\x01 You are a hider, hide or kill all pyros to win.");
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 253.0);
						ClientCommand(client, "slot3");
					}
				}
				else if (team == HIDE)
				{
					if (class == TFClass_Pyro)
					{
						PrintToChat(client, "\x05[Hide n Seek]\x01 You are a seeker, kill all spys to win.");
						SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 270.0);
						ClientCommand(client, "slot1");
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:timer_Periodic(Handle:timer)
{
	if ((hs_active != false) && (hs_inPlay == true))
	{	
		//Check if any survivors are alive
		if (GetTeamClientCount(HIDE) == 0)
		{
			function_teamWin(SEEK);
		}
		
		//Check if any hiders are alive
		if (GetTeamClientCount(SEEK) == 0)
		{
			function_teamWin(HIDE);
		}
	}
}

//Dummy panel handler.
public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	return;
}
