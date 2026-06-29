#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "3.4"

#define SOUND_KILL "weapons/knife/knife_deploy.wav"

#define INCAP 1
#define INCAP_GRAB 2
#define INCAP_POUNCE 3
#define INCAP_RIDE 4
#define INCAP_PUMMEL 5
#define INCAP_EDGEGRAB 6

#define TICKS 10
#define STATE_NONE 0
#define STATE_SELFHELP 1
#define STATE_OK 2

int HelpState[MAXPLAYERS+1], HelpOhterState[MAXPLAYERS+1], Attacker[MAXPLAYERS+1], IncapType[MAXPLAYERS+1];

Handle Timers[MAXPLAYERS+1] = INVALID_HANDLE, ReviveSelf[MAXPLAYERS+1] = INVALID_HANDLE, ReviveOther[MAXPLAYERS+1] = INVALID_HANDLE;

ConVar SelfHelp_delay, SelfHelp_hintdelay, SelfHelp_incap, SelfHelp_grab, SelfHelp_pounce, SelfHelp_ride,
	SelfHelp_pummel, SelfHelp_edgegrab, SelfHelp_eachother, SelfHelp_pickup, SelfHelp_kill, SelfHelp_versus;

int incapCount[MAXPLAYERS+1], reviveCount[MAXPLAYERS+1];

int cGM, gTC = 8;

bool incapMoving[MAXPLAYERS+1], revStart[MAXPLAYERS+1];
float lastPos[MAXPLAYERS+1][3];

public Plugin myinfo = 
{
	name = "Self Help",
	author = "Pan Xiaohai, cravenge",
	description = "Allows Incapacitated Or In Danger Survivors To Help Themselves.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	GameCheck();
	
	CreateConVar("self-help_version", PLUGIN_VERSION, "Self-Help Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	SelfHelp_incap = CreateConVar("self-help_incap", "1", "Self-Incap Help Mode: 1=Pills, 2=Medkits, 3=Both", FCVAR_NOTIFY);
	SelfHelp_grab = CreateConVar("self-help_grab", "1", "Self-Grab Help Mode: 1=Pills, 2=Medkits, 3=Both", FCVAR_NOTIFY);
	SelfHelp_pounce = CreateConVar("self-help_pounce", "1", "Self-Pounce Help Mode: 1=Pills, 2=Medkits, 3=Both", FCVAR_NOTIFY);
	SelfHelp_ride = CreateConVar("self-help_ride", "1", "Self-Ride Help Mode: 1=Pills, 2=Medkits, 3=Both", FCVAR_NOTIFY);
	SelfHelp_pummel = CreateConVar("self-help_pummel", "1", "Self-Pummel Help Mode: 1=Pills, 2=Medkits, 3=Both", FCVAR_NOTIFY);
	SelfHelp_edgegrab = CreateConVar("self-help_edgegrab", "1", "Self-Ledge Help Mode: 1=Pills, 2=Medkits, 3=Both", FCVAR_NOTIFY);
	SelfHelp_eachother = CreateConVar("self-help_eachother", "1", "Enable/Disable Incapacitated Help", FCVAR_NOTIFY);
	SelfHelp_pickup = CreateConVar("self-help_pickup", "1", "Enable/Disable Incapacitated Pick-Up", FCVAR_NOTIFY);
	SelfHelp_kill = CreateConVar("self-help_kill", "1", "Enable/Disable Kill Attacker After Self Help", FCVAR_NOTIFY);
	SelfHelp_hintdelay = CreateConVar("self-help_hintdelay", "1.0", "Delay To Give Hint", FCVAR_NOTIFY);
	SelfHelp_delay = CreateConVar("self-help_delay", "1.0", "Delay To Self Help", FCVAR_NOTIFY);
	SelfHelp_versus = CreateConVar("self-help_versus", "1", "Enable/Disable Plugin In Versus Game Modes", FCVAR_NOTIFY);	
	
	AutoExecConfig(true, "self-help");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("lunge_pounce", OnAttackerLaunch);
	HookEvent("tongue_grab", OnAttackerLaunch);
	HookEvent("jockey_ride", OnAttackerLaunch);
	HookEvent("charger_pummel_start", OnAttackerLaunch);
	HookEvent("pounce_stopped", OnAttackerGone);
	HookEvent("tongue_release", OnAttackerGone);
	HookEvent("jockey_ride_end", OnAttackerGone);
	HookEvent("charger_pummel_end", OnAttackerGone);
	HookEvent("player_incapacitated", OnPlayerIncapacitated);
	HookEvent("player_ledge_grab", OnPlayerLedgeGrab);
	HookEvent("revive_begin", OnReviveBegin);
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("heal_success", OnReset);
	HookEvent("defibrillator_used", OnReset2);
	HookEvent("player_death", OnReset3);
	HookEvent("player_bot_replace", OnReset4);
	HookEvent("bot_player_replace", OnReset4);
	HookEvent("witch_killed", OnReset5);
	
	CreateTimer(1.0, RecordLastOrigin, _, TIMER_REPEAT);
}

void GameCheck()
{
	char GameName[16];
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "left4dead2", false))
	{
		SetFailState("[SH] Plugin Supports L4D2 Only!");
	}
	
	char GameMode[16];
	FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
	if (StrEqual(GameMode, "survival", false))
	{
		cGM = 3;
	}
	else if (StrEqual(GameMode, "versus", false) || StrEqual(GameMode, "teamversus", false) || StrEqual(GameMode, "scavenge", false) || StrEqual(GameMode, "teamscavenge", false))
	{
		cGM = 2;
	}
	else if (StrEqual(GameMode, "coop", false) || StrEqual(GameMode, "realism", false))
	{
		cGM = 1;
	}
	else
	{
		cGM = 0;
 	}
}

public Action RecordLastOrigin(Handle timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}
	
	for (int clients=1; clients<=MaxClients; clients++)
	{
		if (IsClientInGame(clients) && GetClientTeam(clients) == 2 && IsPlayerAlive(clients))
		{
			float lastOrigin[MAXPLAYERS+1][3], incapOrigin[MAXPLAYERS+1][3];
			
			if (!IsPlayerIncapped(clients))
			{
				GetEntPropVector(clients, Prop_Send, "m_vecOrigin", lastOrigin[clients]);
				lastPos[clients] = lastOrigin[clients];
			}
			else if (incapMoving[clients])
			{
				GetEntPropVector(clients, Prop_Send, "m_vecOrigin", incapOrigin[clients]);
				lastPos[clients] = incapOrigin[clients];
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnMapStart()
{
	PrecacheSound(SOUND_KILL, true);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int x = 1; x <= MaxClients; x++)
	{
 		if (IsClientInGame(x))
		{
			HelpOhterState[x] = HelpState[x] = STATE_NONE;
			Attacker[x] = 0;
			if (cGM != 2 && cGM != 3)
			{
				for (int y=1; y<=MaxClients; y++)
				{
					if (IsClientInGame(y) && x == y)
					{
						incapCount[x] = incapCount[y];
						reviveCount[x] = reviveCount[y];
					}
				}
			}
			else
			{
				incapCount[x] = 0;
				reviveCount[x] = 0;
			}
			
			incapMoving[x] = false;
			if (Timers[x] != INVALID_HANDLE)
			{
				KillTimer(Timers[x]);
				Timers[x] = INVALID_HANDLE;
			}
			
			if (ReviveSelf[x] != INVALID_HANDLE)
			{
				KillTimer(ReviveSelf[x]);
				ReviveSelf[x] = INVALID_HANDLE;
			}
			
			if (ReviveOther[x] != INVALID_HANDLE)
			{
				KillTimer(ReviveOther[x]);
				ReviveOther[x] = INVALID_HANDLE;
			}
		}
	}
}

public Action OnAttackerLaunch(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int victim = GetClientOfUserId(event.GetInt("victim"));
	int attacker = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !attacker)
	{
		return;
	}
	
	int incapCVar;
	
	Attacker[victim] = attacker;
	if (StrEqual(name, "tongue_grab"))
	{
		IncapType[victim] = INCAP_GRAB;
		incapCVar = SelfHelp_grab.IntValue;
	}
	else if (StrEqual(name, "jockey_ride"))
	{
		IncapType[victim] = INCAP_RIDE;
		incapCVar = SelfHelp_ride.IntValue;
	}
	else if (StrEqual(name, "charger_pummel_start"))
	{
		IncapType[victim] = INCAP_PUMMEL;
		incapCVar = SelfHelp_pummel.IntValue;
	}
	else if (StrEqual(name, "lunge_pounce"))
	{
		IncapType[victim] = INCAP_POUNCE;
		incapCVar = SelfHelp_pounce.IntValue;
	}
	
	if (incapCVar > 0)
	{
		CreateTimer(SelfHelp_delay.FloatValue, WatchPlayer, victim);
		if (!IsFakeClient(victim))
		{
			CreateTimer(SelfHelp_hintdelay.FloatValue, AdvertisePills, victim);
		}
	}
}

public Action OnAttackerGone(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!victim)
	{
		return;
	}
	
	if (StrEqual(name, "pounce_stopped"))
	{
		Attacker[victim] = 0;
	}
	else
	{
		int attacker = GetClientOfUserId(event.GetInt("userid"));
		if (!attacker)
		{
			return;
		}
		
		if (Attacker[victim] == attacker)
		{
			Attacker[victim] = 0;
		}
	}
}

public Action OnPlayerRunCmd(int client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !IsPlayerIncapped(client))
	{
		return Plugin_Continue;
	}
	
	if (FindConVar("survivor_allow_crawling").IntValue == 0 || FindConVar("survivor_crawl_speed").IntValue == 0)
	{
		return Plugin_Continue;
	}
	
	if (buttons & IN_FORWARD)
	{
		incapMoving[client] = true;
	}
	else
	{
		incapMoving[client] = false;
	}
	
	return Plugin_Continue;
}
 
public Action OnPlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || GetEntProp(victim, Prop_Send, "m_zombieClass") == gTC)
	{
		return;
	}
	
	IncapType[victim] = INCAP;
	if (SelfHelp_incap.IntValue > 0)
	{
		CreateTimer(SelfHelp_delay.FloatValue, WatchPlayer, victim);
		if (!IsFakeClient(victim))
		{
			CreateTimer(SelfHelp_hintdelay.FloatValue, AdvertisePills, victim);
			PrintHintText(victim, "Help Other Incapacitated Survivors By Pressing RELOAD!");
		}
	}
	
	if (incapCount[victim] < FindConVar("survivor_max_incapacitated_count").IntValue)
	{
		incapCount[victim] += 1;
		PrintToChat(victim, "\x03[SH] \x01You Got Incapacitated! [\x04%d\x01/\x04%i\x01]", incapCount[victim], FindConVar("survivor_max_incapacitated_count").IntValue);
		if (incapCount[victim] == 4)
		{
			for (int client=1; client<=MaxClients; client++)
			{
				if (IsClientInGame(client) && GetClientTeam(client) == GetClientTeam(victim) && client != victim)
				{
					PrintHintText(client, "%N Will Be B/W After Revive!", victim);
				}
			}
		}
	}
}

public Action OnPlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	IncapType[victim] = INCAP_EDGEGRAB;
	if (SelfHelp_edgegrab.IntValue > 0)
	{
		CreateTimer(SelfHelp_delay.FloatValue, WatchPlayer, victim);
		if (!IsFakeClient(victim))
		{
			CreateTimer(SelfHelp_hintdelay.FloatValue, AdvertisePills, victim);
		}
 	}
}

public Action OnReset(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int healed = GetClientOfUserId(event.GetInt("subject"));
	if (healed <= 0 || healed > MaxClients || !IsClientInGame(healed) || GetClientTeam(healed) != 2)
	{
		return;
	}
	
	incapCount[healed] = 0;
	reviveCount[healed] = 0;
}

public Action OnReset2(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int defibbed = GetClientOfUserId(event.GetInt("subject"));
	if (defibbed <= 0 || defibbed > MaxClients || !IsClientInGame(defibbed) || GetClientTeam(defibbed) != 2)
	{
		return;
	}
	
	if (FindConVar("bw_on_defib-l4d2_version") != INVALID_HANDLE)
	{
		incapCount[defibbed] = FindConVar("bw_on_defib-l4d2_incaps").IntValue;
		reviveCount[defibbed] = FindConVar("bw_on_defib-l4d2_incaps").IntValue;
	}
}

public Action OnReset3(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (died <= 0 || died > MaxClients || !IsClientInGame(died))
	{
		return;
	}
	
	if (GetClientTeam(died) == 2)
	{
		incapCount[died] = 0;
		reviveCount[died] = 0;
	}
	else if (GetClientTeam(died) == 3 && GetEntProp(died, Prop_Send, "m_zombieClass") == gTC)
	{
		if (FindConVar("hp_rewards_version") == INVALID_HANDLE)
		{
			return;
		}
		
		if (FindConVar("hp_rewards_tank_type").IntValue == 1)
		{
			for (int murderer=1; murderer<=MaxClients; murderer++)
			{
				if (IsClientInGame(murderer) && GetClientTeam(murderer) == 2 && IsPlayerAlive(murderer) && !IsPlayerIncapped(murderer))
				{
					incapCount[murderer] = 0;
					reviveCount[murderer] = 0;
				}
			}
		}
		else
		{
			int shooter = GetClientOfUserId(event.GetInt("attacker"));
			if (shooter <= 0 || shooter > MaxClients || !IsClientInGame(shooter) || GetClientTeam(shooter) != 2 || !IsPlayerAlive(shooter) || IsPlayerIncapped(shooter))
			{
				return;
			}
			
			incapCount[shooter] = 0;
			reviveCount[shooter] = 0;
		}
	}
}

public Action OnReset4(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int bot = GetClientOfUserId(event.GetInt("bot"));
	int player = GetClientOfUserId(event.GetInt("player"));
	if (player <= 0 || !IsClientInGame(player) || IsFakeClient(player))
	{
		return;
	}
	
	if (StrEqual(name, "player_bot_replace"))
	{
		incapCount[bot] = incapCount[player];
		reviveCount[bot] = reviveCount[player];
	}
	else if (StrEqual(name, "bot_player_replace"))
	{
		incapCount[player] = incapCount[bot];
		reviveCount[player] = reviveCount[bot];
	}
}

public Action OnReset5(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	if (FindConVar("hp_rewards_version") == INVALID_HANDLE)
	{
		return;
	}
	
	int killer = GetClientOfUserId(event.GetInt("userid"));
	if (killer <= 0 || killer > MaxClients || !IsClientInGame(killer) || GetClientTeam(killer) != 2 || IsPlayerIncapped(killer))
	{
		return;
	}
	
	incapCount[killer] = 0;
	reviveCount[killer] = 0;
}

public Action OnReviveBegin(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	int revivee = GetClientOfUserId(event.GetInt("subject"));
	if (revivee <= 0 || revivee > MaxClients || !IsClientInGame(revivee) || GetClientTeam(revivee) != 2)
	{
		return;
	}
	
	revStart[revivee] = true;
}

public Action OnReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (cGM == 2 && !SelfHelp_versus.BoolValue)
	{
		return;
	}
	
	if (event.GetBool("ledge_hang"))
	{
		return;
	}
	
	int reviver = GetClientOfUserId(event.GetInt("userid"));
	if (reviver <= 0 || reviver > MaxClients || !IsClientInGame(reviver) || GetClientTeam(reviver) != 2)
	{
		return;
	}
	
	int revivee = GetClientOfUserId(event.GetInt("subject"));
	if (revivee <= 0 || revivee > MaxClients || !IsClientInGame(revivee) || GetClientTeam(revivee) != 2)
	{
		return;
	}
	
	revStart[revivee] = false;
	
	if (reviver == revivee)
	{
		return;
	}
	
	if (reviveCount[revivee] < GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
	{
		reviveCount[revivee] += 1;
		PrintToChat(reviver, "\x03[SH]\x01 You Helped \x05%N\x01! [\x04%d\x01/\x04%i\x01]", revivee, reviveCount[revivee], GetConVarInt(FindConVar("survivor_max_incapacitated_count")));
		PrintToChat(revivee, "\x03[SH] \x05%N\x01 Helped You! [\x04%d\x01/\x04%i\x01]", reviver, reviveCount[revivee], GetConVarInt(FindConVar("survivor_max_incapacitated_count")));
	}
}

public Action WatchPlayer(Handle timer, any client)
{
 	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || Timers[client] != INVALID_HANDLE)
	{
		return Plugin_Stop;
	}
	
	HelpOhterState[client] = HelpState[client] = STATE_NONE;
	Timers[client] = CreateTimer(1.0 / TICKS, PlayerTimer, client, TIMER_REPEAT);
	
	return Plugin_Stop;
}

public Action AdvertisePills(Handle timer, any client)
{
 	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}
	
	if (!IsPlayerIncapped(client) && !IsPlayerHanging(client) && Attacker[client] == 0)
	{
		return Plugin_Stop;
	}
	
	if (CanSelfHelp(client))
	{
		PrintToChat(client, "\x05[SH]\x03 Press \x04CTRL\x03 To Self-Help!");
	}
	
	return Plugin_Stop;
}

bool CanSelfHelp(int client)
{
	bool pills = HaveSupplies(client, 4, "weapon_pain_pills");
	bool kid = HaveSupplies(client, 3, "weapon_first_aid_kit");
	bool adrenaline = HaveSupplies(client, 4, "weapon_adrenaline");
	
	bool ok = false;
	
	int self;
	if (IncapType[client] == INCAP)
	{
		self = SelfHelp_incap.IntValue;
	}
	else if (IncapType[client] == INCAP_EDGEGRAB)
	{
		self = SelfHelp_edgegrab.IntValue;
	}
	else if (IncapType[client] == INCAP_GRAB)
	{
		self = SelfHelp_grab.IntValue;
	}
	else if (IncapType[client] == INCAP_POUNCE)
	{
		self = SelfHelp_pounce.IntValue;
	}
	else if (IncapType[client] == INCAP_RIDE)
	{
		self = SelfHelp_ride.IntValue;
	}
	else if (IncapType[client] == INCAP_PUMMEL)
	{
		self = SelfHelp_pummel.IntValue;
	}
	
	if ((self == 1 || self == 3) && (pills || adrenaline))
	{
		ok = true;
	}
	else if ((self == 2 || self == 3) && kid)
	{
		ok = true;
	}
	
	return ok;
}

int SelfHelpUseSlot(int client)
{
	int solt = -1;
	
	int self;
	if (IncapType[client] == INCAP)
	{
		self = GetConVarInt(SelfHelp_incap);
	}
	else if (IncapType[client] == INCAP_EDGEGRAB)
	{
		self = GetConVarInt(SelfHelp_edgegrab);
	}
	else if(IncapType[client] == INCAP_GRAB)
	{
		self = GetConVarInt(SelfHelp_grab);
	}
	else if (IncapType[client] == INCAP_POUNCE)
	{
		self = GetConVarInt(SelfHelp_pounce);
	}
	else if(IncapType[client] == INCAP_RIDE)
	{
		self = GetConVarInt(SelfHelp_ride);
	}
	else if(IncapType[client] == INCAP_PUMMEL)
	{
		self = GetConVarInt(SelfHelp_pummel);
	}
	
	if ((self == 1 || self == 3) && (HaveSupplies(client, 4, "weapon_adrenaline") || HaveSupplies(client, 4, "weapon_pain_pills")))
	{
		solt = 4;
	}
	else if ((self == 2 || self == 3) && HaveSupplies(client, 3, "weapon_first_aid_kit"))
	{
		solt = 3;
	}
	return solt;
}

public Action PlayerTimer(Handle timer, any client)
{
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || revStart[client] || HelpState[client] == STATE_OK)
	{
		HelpOhterState[client] = HelpState[client] = STATE_NONE;
		Timers[client] = INVALID_HANDLE;
		
		if (ReviveSelf[client] != INVALID_HANDLE)
		{
			KillTimer(ReviveSelf[client]);
			ReviveSelf[client] = INVALID_HANDLE;
		}
 		return Plugin_Stop;
	}
	
	if (!IsPlayerIncapped(client) && !IsPlayerHanging(client))
	{
		if (Attacker[client] == 0 || (Attacker[client] != 0 && (!IsClientInGame(Attacker[client]) || !IsPlayerAlive(Attacker[client]))))
		{
			HelpOhterState[client] = HelpState[client] = STATE_NONE;
			Timers[client] = INVALID_HANDLE;
			Attacker[client] = 0;
			KillProgressBar(client);
			
			if (ReviveSelf[client] != INVALID_HANDLE)
			{
				KillTimer(ReviveSelf[client]);
				ReviveSelf[client] = INVALID_HANDLE;
			}
			return Plugin_Stop;
		}
	}
	
	int buttons = GetClientButtons(client);
	
	if (CanSelfHelp(client))
	{
		if (buttons & IN_DUCK)
		{
			if (HelpState[client] == STATE_NONE)
			{
				SetupProgressBar(client, FindConVar("survivor_revive_duration").FloatValue);
				PrintHintText(client, "Self-Helping!");
				
				HelpState[client] = STATE_SELFHELP;
				
				if (ReviveSelf[client] == INVALID_HANDLE)
				{
					Handle selfRevive = CreateDataPack();
					WritePackCell(selfRevive, GetClientUserId(client));
					ReviveSelf[client] = CreateTimer(FindConVar("survivor_revive_duration").FloatValue, FinishSelfRevive, selfRevive, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
				}
			}
		}
		else
		{
			if (HelpState[client] == STATE_SELFHELP)
			{
				KillProgressBar(client);
				HelpState[client] = STATE_NONE;
				if (ReviveSelf[client] != INVALID_HANDLE)
				{
					KillTimer(ReviveSelf[client]);
					ReviveSelf[client] = INVALID_HANDLE;
				}
			}
		}
	}
	
	if (SelfHelp_eachother.IntValue > 0)
	{
		if (buttons & IN_RELOAD)
		{
			float dis = 50.0;
			
			float pos[3], targetVector[3];
			GetClientEyePosition(client, pos);
			
			int other = 0;
			for (int target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target) && IsPlayerIncapped(target) && target != client)
				{
					GetClientAbsOrigin(target, targetVector);
					
					float distance = GetVectorDistance(targetVector, pos);
					if (distance < dis)
					{
						other = target;
						break;
					}
				}
			}
			if (other != 0)
			{
				if (HelpOhterState[client] == STATE_NONE)
				{
					SetupProgressBar(client, FindConVar("survivor_revive_duration").FloatValue);
					SetupProgressBar(other, FindConVar("survivor_revive_duration").FloatValue);
					
					PrintHintText(client, "You Are Helping %N", other);
					PrintHintText(other, "%N Is Helping You!", client);
					
					HelpOhterState[client] = STATE_SELFHELP;
					
					if (ReviveOther[client] == INVALID_HANDLE)
					{
						Handle reviveOther = CreateDataPack();
						WritePackCell(reviveOther, GetClientUserId(client));
						WritePackCell(reviveOther, GetClientUserId(other));
						ReviveOther[client] = CreateTimer(FindConVar("survivor_revive_duration").FloatValue, FinishOtherRevive, reviveOther, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
					}
				}
			}
		}
		else
		{
			if (HelpOhterState[client] == STATE_SELFHELP)
			{
				KillProgressBar(client);
				HelpOhterState[client] = STATE_NONE;
				if (ReviveOther[client] != INVALID_HANDLE)
				{
					KillTimer(ReviveOther[client]);
					ReviveOther[client] = INVALID_HANDLE;
				}
			}
		}
	}
	
	if ((buttons & IN_DUCK) && SelfHelp_pickup.IntValue > 0) 
	{	
		bool pickup = false;
		float dis = 100.0;
 		int ent = -1;
		
 		float targetVector1[3], targetVector2[3];
		GetClientEyePosition(client, targetVector1);
		
		if (!pickup)
		{
			if (GetPlayerWeaponSlot(client, 4) == -1 || !IsValidEntity(GetPlayerWeaponSlot(client, 4)) || !IsValidEdict(GetPlayerWeaponSlot(client, 4)))
			{
				if (!HaveSupplies(client, 4, "weapon_pain_pills"))
				{
					while ((ent = FindEntityByClassname(ent, "weapon_pain_pills")) != -1)
					{
						if (IsValidEntity(ent))
						{
							GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
							if (GetVectorDistance(targetVector1, targetVector2) < dis)
							{
								CheatCommand(client, "give", "pain_pills", "");
								PrintHintText(client, "Grabbed Pills!");
								
								RemoveEdict(ent);
								
								pickup = true;
								break;
							}
						}
					}
				}
				else if (!HaveSupplies(client, 4, "weapon_adrenaline"))
				{
					while ((ent = FindEntityByClassname(ent, "weapon_adrenaline")) != -1)
					{
						if (IsValidEntity(ent))
						{
							GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
							if (GetVectorDistance(targetVector1, targetVector2) < dis)
							{
								CheatCommand(client, "give", "adrenaline", "");
								PrintHintText(client, "Grabbed Adrenaline!");
								
								RemoveEdict(ent);
								
								pickup = true;
								break;
							}
						}
					}
				}
			}
			else if (!HaveSupplies(client, 3, "weapon_first_aid_kit"))
			{
				while ((ent = FindEntityByClassname(ent, "weapon_first_aid_kit")) != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						if (GetVectorDistance(targetVector1, targetVector2) < dis)
						{
							CheatCommand(client, "give", "first_aid_kit", "");
							PrintHintText(client, "Grabbed Medkit!");
							
							RemoveEdict(ent);
							
							pickup = true;
							break;
						}
					}
				}
			}
		}
	}
	
 	return Plugin_Continue;
}

public Action FinishSelfRevive(Handle timer, Handle selfRevive)
{
	ResetPack(selfRevive);
	
	int client = GetClientOfUserId(ReadPackCell(selfRevive));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
	{
		KillTimer(ReviveSelf[client]);
		ReviveSelf[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if (ReviveSelf[client] == INVALID_HANDLE)
	{
		return Plugin_Stop;
	}
	
	if (IsPlayerIncapped(client))
	{
		Event reviveSuccessEvent = CreateEvent("revive_success");
		reviveSuccessEvent.SetInt("userid", GetClientUserId(client));
		reviveSuccessEvent.SetInt("subject", GetClientUserId(client));
		reviveSuccessEvent.Fire(false);
	}
	SelfHelp(client);
	if (reviveCount[client] < FindConVar("survivor_max_incapacitated_count").IntValue)
	{
		incapCount[client] += 1;
		reviveCount[client] += 1;
		PrintToChat(client, "\x03[SH]\x01 You Helped Yourself! [\x04%d\x01/\x04%i\x01]", reviveCount[client], GetConVarInt(FindConVar("survivor_max_incapacitated_count")));
		if (reviveCount[client] == 3)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client) && i != client)
				{
					PrintHintText(i, "%N Will Be B/W After Self-Help!", client);
				}
			}
		}
	}
	KillTimer(ReviveSelf[client]);
	ReviveSelf[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action FinishOtherRevive(Handle timer, Handle reviveOther)
{
	ResetPack(reviveOther);
	
	int client = GetClientOfUserId(ReadPackCell(reviveOther));
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !IsPlayerIncapped(client))
	{
		KillTimer(ReviveOther[client]);
		ReviveOther[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if (ReviveOther[client] == INVALID_HANDLE)
	{
		return Plugin_Stop;
	}
	
	int teammate = GetClientOfUserId(ReadPackCell(reviveOther));
	if (teammate <= 0 || teammate > MaxClients || !IsClientInGame(teammate) || GetClientTeam(teammate) != 2 || !IsPlayerAlive(teammate) || !IsPlayerIncapped(teammate))
	{
		KillTimer(ReviveOther[client]);
		ReviveOther[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	Event eventReviveSuccess = CreateEvent("revive_success");
	eventReviveSuccess.SetInt("userid", GetClientUserId(client));
	eventReviveSuccess.SetInt("subject", GetClientUserId(teammate));
	eventReviveSuccess.Fire(false);
	
	HelpOther(teammate, client);
	
	KillTimer(ReviveOther[client]);
	ReviveOther[client] = INVALID_HANDLE;
	return Plugin_Stop;
}

void SelfHelp(int client)
{
	int slot = SelfHelpUseSlot(client);
	if (slot == -1)
	{
		return;
	}
	
	bool adrenaline = HaveSupplies(client, 4, "weapon_adrenaline");
	
	int weaponslot = GetPlayerWeaponSlot(client, slot);
	if (weaponslot != -1 && IsValidEntity(weaponslot) && IsValidEdict(weaponslot))
	{
		KillAttack(client);		
		HelpState[client] = STATE_OK;
		
		if (slot == 4)
		{
			if (!adrenaline)
			{
				Event OnPillsUsed = CreateEvent("pills_used", true);
				OnPillsUsed.SetInt("userid", GetClientUserId(client));
				OnPillsUsed.SetInt("subject", GetClientUserId(client));
				OnPillsUsed.Fire(false);
			}
			else
			{
				Event OnAdrenalineUsed = CreateEvent("pills_used", true);
				OnAdrenalineUsed.SetInt("userid", GetClientUserId(client));
				OnAdrenalineUsed.Fire(false);
			}
			
			ReviveWithTempHealths(client);
			PrintToChatAll("\x03[SH] \x04%N\x03 Self-Helped With %s!", client, (adrenaline) ? "Adrenaline" : "Pills");
		}
		else if (slot == 3)
		{
			Event OnHealSuccess = CreateEvent("heal_success");
			OnHealSuccess.SetInt("userid", GetClientUserId(client));
			OnHealSuccess.SetInt("subject", GetClientUserId(client));
			OnHealSuccess.Fire(false);
			
			ReviveWithMedkit(client);
			PrintToChatAll("\x03[SH] \x04%N\x03 Self-Helped With Medkit!", client);
		}
	}
}

void HelpOther(int client, int helper)
{
	int cRC = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	int sMIC = FindConVar("survivor_max_incapacitated_count").IntValue;
	if (cRC >= sMIC - 1)
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", sMIC);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		
		SetEntProp(client, Prop_Send, "m_iGlowType", 3);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 16777215);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", cRC + 1);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	}
	
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	if (IsPlayerHanging(client))
	{
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
	}
	
	TeleportEntity(client, lastPos[client], NULL_VECTOR, NULL_VECTOR);
	
	ConVar revivehealth = FindConVar("pain_pills_health_value");
	new temphpoffset = FindSendPropOffs("CTerrorPlayer", "m_healthBuffer");
	
	SetEntDataFloat(client, temphpoffset, revivehealth.FloatValue * 2.0, true);
	SetEntityHealth(client, 1);
	SetEntProp(client, Prop_Send, "m_iMaxHealth", FindConVar("survivor_revive_health").IntValue, 1);
	
 	PrintToChatAll("\x03[SH] \x04%N\x03 Helped\x04 %N \x03Even In Incapacitated State!", helper, client);
}

void ReviveWithMedkit(int client)
{
	int cRC = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	int sMIC = FindConVar("survivor_max_incapacitated_count").IntValue;
	if (cRC >= sMIC - 1)
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", sMIC);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		
		SetEntProp(client, Prop_Send, "m_iGlowType", 3);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 16777215);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", cRC + 1);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	}
	
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	if (IsPlayerHanging(client))
	{
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
	}
	
	TeleportEntity(client, lastPos[client], NULL_VECTOR, NULL_VECTOR);
	
	ConVar revivehealth = FindConVar("first_aid_heal_percent");
	new temphpoffset = FindSendPropOffs("CTerrorPlayer", "m_healthBuffer");
	
	SetEntDataFloat(client, temphpoffset, revivehealth.FloatValue * 200.0, true);
	SetEntityHealth(client, 1);
	SetEntProp(client, Prop_Send, "m_iMaxHealth", FindConVar("survivor_revive_health").IntValue, 1);
}

void ReviveWithTempHealths(int client)
{
	int cRC = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	int sMIC = FindConVar("survivor_max_incapacitated_count").IntValue;
	if (cRC >= sMIC - 1)
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", sMIC);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		
		SetEntProp(client, Prop_Send, "m_iGlowType", 3);
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 16777215);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", cRC + 1);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	}
	
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	if (IsPlayerHanging(client))
	{
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
	}
	
	TeleportEntity(client, lastPos[client], NULL_VECTOR, NULL_VECTOR);
	
	ConVar revivehealth = FindConVar("pain_pills_health_value");  
	new temphpoffset = FindSendPropOffs("CTerrorPlayer", "m_healthBuffer");
	
	SetEntDataFloat(client, temphpoffset, revivehealth.FloatValue * 4.0, true);
	SetEntityHealth(client, 1);
	SetEntProp(client, Prop_Send, "m_iMaxHealth", FindConVar("survivor_revive_health").IntValue, 1);
}
 
void KillAttack(int client)
{
	if (SelfHelp_kill.IntValue == 0)
	{
		return;
	}
	
	int a = Attacker[client];
	if (a != 0 && IsClientInGame(a) && GetClientTeam(a) == 3 && IsPlayerAlive(a))
	{
		switch (GetEntProp(a, Prop_Send, "m_zombieClass"))
		{
			case 1:
			{
				Event OnTonguePullStopped = CreateEvent("tongue_pull_stopped", true);
				OnTonguePullStopped.SetInt("userid", GetClientUserId(client));
				OnTonguePullStopped.SetInt("victim", GetClientUserId(client));
				OnTonguePullStopped.SetInt("smoker", GetClientUserId(a));
				OnTonguePullStopped.Fire(false);
			}
			case 3:
			{
				Event pounceStoppedEvent = CreateEvent("pounce_stopped");
				pounceStoppedEvent.SetInt("userid", GetClientUserId(client));
				pounceStoppedEvent.SetInt("victim", GetClientUserId(client));
				pounceStoppedEvent.Fire(false);
			}
			case 5:
			{
				Event rideEndEvent = CreateEvent("jockey_ride_end");
				rideEndEvent.SetInt("userid", GetClientUserId(a));
				rideEndEvent.SetInt("victim", GetClientUserId(client));
				rideEndEvent.SetInt("rescuer", GetClientUserId(client));
				rideEndEvent.Fire(false);
			}
			case 6:
			{
				Event OnChargerKilled = CreateEvent("charger_killed", true);
				OnChargerKilled.SetInt("userid", GetClientUserId(a));
				OnChargerKilled.SetInt("attacker", GetClientUserId(client));
				OnChargerKilled.Fire(false);
			}
		}
		Event playerDeathEvent = CreateEvent("player_death");
		playerDeathEvent.SetInt("userid", GetClientUserId(a));
		playerDeathEvent.SetInt("attacker", GetClientUserId(client));
		playerDeathEvent.Fire(false);
		
		ForcePlayerSuicide(a);
		EmitSoundToAll(SOUND_KILL, client);
	}
}

bool HaveSupplies(int client, int itemSlot, char[] itemClass)
{
	int SupplySlot = GetPlayerWeaponSlot(client, itemSlot);
	if (SupplySlot > 0 && IsValidEntity(SupplySlot) && IsValidEdict(SupplySlot))
	{
		char weapon[32];
		GetEdictClassname(SupplySlot, weapon, 32);
		if (StrEqual(weapon, itemClass, false))
		{
			return true;
		}
 	}
	
	return false;
}
 
stock void CheatCommand(int client, char[] command, char[] parameter1, char[] parameter2)
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
}

bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
 	return false;
}

bool IsPlayerHanging(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))
	{
		return true;
	}
 	return false;
}

stock void SetupProgressBar(int client, float time)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

stock void KillProgressBar(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}

