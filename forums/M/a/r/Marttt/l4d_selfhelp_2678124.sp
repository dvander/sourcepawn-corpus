#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "1.0.1m6"
#define SOUND_KILL1  "/weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2  "/weapons/knife/knife_deploy.wav"
#define INCAP				1
#define INCAP_GRAB			2
#define INCAP_POUNCE		3
#define INCAP_RIDE			4
#define INCAP_PUMMEL		5
#define INCAP_EDGEGRAB		6
#define TICKS				10
#define STATE_NONE			0
#define STATE_SELFHELP		1
#define STATE_OK			2
#define STATE_FAILED		3
#define TRANSLATIONS_FILENAME	"l4d_selfhelp.phrases"
new HelpState[MAXPLAYERS+1];
new HelpOtherState[MAXPLAYERS+1];
new Attacker[MAXPLAYERS+1];
new IncapType[MAXPLAYERS+1];
new Handle:Timers[MAXPLAYERS+1];
new Float:HelpStartTime[MAXPLAYERS+1];
ConVar l4d_selfhelp_delay;
ConVar l4d_selfhelp_hintdelay;
ConVar l4d_selfhelp_duration;
ConVar l4d_selfhelp_incap;
ConVar l4d_selfhelp_grab;
ConVar l4d_selfhelp_pounce;
ConVar l4d_selfhelp_ride;
ConVar l4d_selfhelp_pummel;
ConVar l4d_selfhelp_edgegrab;
ConVar l4d_selfhelp_eachother;
ConVar l4d_selfhelp_pickup;
ConVar l4d_selfhelp_kill;
ConVar l4d_selfhelp_versus;
ConVar l4d_selfhelp_bot;

new Handle:wS_Timer[MAXPLAYERS+1];

new L4D2Version=false;

public Plugin:myinfo =
{
	name = "Self Help",
	author = "Pan Xiaohai",
	description = "",
	version = PLUGIN_VERSION,
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
		return APLRes_SilentFailure;
	}

	L4D2Version = (engine == Engine_Left4Dead2);

	return APLRes_Success;
}

public OnPluginStart()
{
	LoadPluginTranslations();
	CreateConVar("l4d_selfhelp_version", PLUGIN_VERSION, " ", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	l4d_selfhelp_incap = CreateConVar("l4d_selfhelp_incap", "3", "self help for incap , 0:disable, 1:pills, 2:medkit, 3:both", FCVAR_NOTIFY);
	l4d_selfhelp_grab = CreateConVar("l4d_selfhelp_grab", "3", " self help for grab , 0:disable, 1:pills, 2:medkit, 3:both ", FCVAR_NOTIFY);
	l4d_selfhelp_pounce = CreateConVar("l4d_selfhelp_pounce", "3", " self help for pounce , 0:disable, 1:pills, 2:medkit, 3:both ", FCVAR_NOTIFY);
	l4d_selfhelp_ride = CreateConVar("l4d_selfhelp_ride", "3", " self help for ride , 0:disable, 1:pills, 2:medkit, 3:both ", FCVAR_NOTIFY);
	l4d_selfhelp_pummel = CreateConVar("l4d_selfhelp_pummel", "3", "self help for pummel , 0:disable, 1:pills, 2:medkit, 3:both", FCVAR_NOTIFY);
	l4d_selfhelp_edgegrab = CreateConVar("l4d_selfhelp_edgegrab", "3", "self help for edgegrab , 0:disable, 1:pill, 2:medkit, 3:both", FCVAR_NOTIFY);
	l4d_selfhelp_eachother = CreateConVar("l4d_selfhelp_eachother", "1", "incap help each other , 0: disable, 1 :enable", FCVAR_NOTIFY);
	l4d_selfhelp_pickup = CreateConVar("l4d_selfhelp_pickup", "1", "incap pick up , 0: disable, 1 :enable", FCVAR_NOTIFY);
	l4d_selfhelp_kill = CreateConVar("l4d_selfhelp_kill", "1", "kill attacker", FCVAR_NOTIFY);
	l4d_selfhelp_hintdelay = CreateConVar("l4d_selfhelp_hintdelay", "3.0", "hint delay", FCVAR_NOTIFY);
	l4d_selfhelp_delay = CreateConVar("l4d_selfhelp_delay", "1.0", "self help delay", FCVAR_NOTIFY);
	l4d_selfhelp_duration = CreateConVar("l4d_selfhelp_durtaion", "3.0", "self help duration", FCVAR_NOTIFY);
	l4d_selfhelp_versus = CreateConVar("l4d_selfhelp_versus", "1", "0: disable in versus, 1: enable in versus", FCVAR_NOTIFY);
	l4d_selfhelp_bot = CreateConVar("l4d_selfhelp_bot", "1", "0: disable bots using self help, 1: enable bots using self help", FCVAR_NOTIFY);

	FindConVar("mp_gamemode").AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_incap.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_grab.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_pounce.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_ride.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_pummel.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_edgegrab.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_eachother.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_pickup.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_kill.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_hintdelay.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_delay.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_duration.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_versus.AddChangeHook(Event_ConVarChanged);
	l4d_selfhelp_bot.AddChangeHook(Event_ConVarChanged);

	AutoExecConfig(true, "l4d_selfhelp");

	GameCheck();
}

void LoadPluginTranslations()
{
	LoadTranslations("common.phrases");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATIONS_FILENAME);
	if (FileExists(sPath))
		LoadTranslations(TRANSLATIONS_FILENAME);
	else
		SetFailState("Missing required translation file on 'translations/%s.txt', please re-download.", TRANSLATIONS_FILENAME);
}

static int GameMode;
GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
	}
}

static bool g_bValidGameMode;
public void OnConfigsExecuted()
{
	GameCheck();
	g_bValidGameMode = !(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0);

	HookEvents(g_bValidGameMode);
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GameCheck();
	g_bValidGameMode = !(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0);

	HookEvents(g_bValidGameMode);
}

static bool g_bEventsHooked;
public void HookEvents(bool hook)
{
	if (hook && !g_bEventsHooked)
	{
		g_bEventsHooked = true;

		HookEvent("player_incapacitated", Event_Incap);
		HookEvent("lunge_pounce", lunge_pounce);
		HookEvent("pounce_stopped", pounce_stopped);
		HookEvent("tongue_grab", tongue_grab);
		HookEvent("tongue_release", tongue_release);
		HookEvent("player_ledge_grab", player_ledge_grab);
		HookEvent("round_start", RoundStart);
		HookEvent("revive_success", Event_Revive);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("heal_success", Event_HealSuccess);
		HookEvent("player_bot_replace", Event_BotReplace);
		HookEvent("bot_player_replace", Event_PlayerReplace);

		if(L4D2Version)
		{
			HookEvent("jockey_ride", jockey_ride);
			HookEvent("jockey_ride_end", jockey_ride_end);
			HookEvent("charger_pummel_start", charger_pummel_start);
			HookEvent("charger_pummel_end", charger_pummel_end);
		}

		return;
	}

	if (!hook && g_bEventsHooked)
	{
		g_bEventsHooked = false;

		UnhookEvent("player_incapacitated", Event_Incap);
		UnhookEvent("lunge_pounce", lunge_pounce);
		UnhookEvent("pounce_stopped", pounce_stopped);
		UnhookEvent("tongue_grab", tongue_grab);
		UnhookEvent("tongue_release", tongue_release);
		UnhookEvent("player_ledge_grab", player_ledge_grab);
		UnhookEvent("round_start", RoundStart);
		UnhookEvent("revive_success", Event_Revive);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("heal_success", Event_HealSuccess);
		UnhookEvent("player_bot_replace", Event_BotReplace);
		UnhookEvent("bot_player_replace", Event_PlayerReplace);

		if(L4D2Version)
		{
			UnhookEvent("jockey_ride", jockey_ride);
			UnhookEvent("jockey_ride_end", jockey_ride_end);
			UnhookEvent("charger_pummel_start", charger_pummel_start);
			UnhookEvent("charger_pummel_end", charger_pummel_end);
		}

		return;
	}
}

public OnMapStart()
{
	if(L4D2Version)	PrecacheSound(SOUND_KILL2, true) ;
	else PrecacheSound(SOUND_KILL1, true) ;
}

public OnMapEnd()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (wS_Timer[i] != INVALID_HANDLE)
		{
			KillTimer(wS_Timer[i]);
			wS_Timer[i] = INVALID_HANDLE;
		}
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	reset();
	return Plugin_Continue;
}

public void Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	StopSoundPerm(client, "player/heartbeatloop.wav");
}

/****************************************************************************************************/
public void Event_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (!IsValidClient(client))
		return;
	if (!IsValidClient(bot))
		return;
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") != GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
		StopSoundPerm(client, "player/heartbeatloop.wav");
}

/****************************************************************************************************/
public void Event_PlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (!IsValidClient(client))
		return;
	if (!IsValidClient(bot))
		return;
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") != GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
		StopSoundPerm(client, "player/heartbeatloop.wav");
}

public lunge_pounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim]=INCAP_POUNCE;
	if(GetConVarInt(l4d_selfhelp_pounce)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
		if(GetConVarInt(l4d_selfhelp_bot) == 1 && IsClientBot(victim) && wS_Timer[victim] == INVALID_HANDLE)
		{
			wS_Timer[victim] = CreateTimer(GetConVarFloat(l4d_selfhelp_duration), BotsSelfHelp, victim);
		}
	}
}

public pounce_stopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	Attacker[victim] = 0;
	if(!IsPlayerIncap(victim))
	{
			if (wS_Timer[victim] != INVALID_HANDLE)
			{
				KillTimer(wS_Timer[victim]);
				wS_Timer[victim] = INVALID_HANDLE;
			}
	}
}

public tongue_grab (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim]=INCAP_GRAB;
	if(GetConVarInt(l4d_selfhelp_grab)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
		if(GetConVarInt(l4d_selfhelp_bot) == 1 && IsClientBot(victim) && wS_Timer[victim] == INVALID_HANDLE)
		{
			wS_Timer[victim] = CreateTimer(GetConVarFloat(l4d_selfhelp_duration), BotsSelfHelp, victim);
		}
	}
}

public tongue_release (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] ==attacker)
	{
		Attacker[victim] = 0;
	}
	if(!IsPlayerIncap(victim))
	{
			if (wS_Timer[victim] != INVALID_HANDLE)
			{
				KillTimer(wS_Timer[victim]);
				wS_Timer[victim] = INVALID_HANDLE;
			}
	}
}

public jockey_ride (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim]=INCAP_RIDE;
	if(GetConVarInt(l4d_selfhelp_ride)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
		if(GetConVarInt(l4d_selfhelp_bot) == 1 && IsClientBot(victim) && wS_Timer[victim] == INVALID_HANDLE)
		{
			wS_Timer[victim] = CreateTimer(GetConVarFloat(l4d_selfhelp_duration), BotsSelfHelp, victim);
		}
	}
}

public jockey_ride_end (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] ==attacker)
	{
		Attacker[victim] = 0;
	}
	if(!IsPlayerIncap(victim))
	{
			if (wS_Timer[victim] != INVALID_HANDLE)
			{
				KillTimer(wS_Timer[victim]);
				wS_Timer[victim] = INVALID_HANDLE;
			}
	}
}

public charger_pummel_start (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim]=INCAP_PUMMEL;
	if(GetConVarInt(l4d_selfhelp_pummel)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
		if(GetConVarInt(l4d_selfhelp_bot) == 1 && IsClientBot(victim) && wS_Timer[victim] == INVALID_HANDLE)
		{
			wS_Timer[victim] = CreateTimer(GetConVarFloat(l4d_selfhelp_duration), BotsSelfHelp, victim);
		}
	}
}

public charger_pummel_end (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] ==attacker)
	{
		Attacker[victim] = 0;
	}
	if(!IsPlayerIncap(victim))
	{
			if (wS_Timer[victim] != INVALID_HANDLE)
			{
				KillTimer(wS_Timer[victim]);
				wS_Timer[victim] = INVALID_HANDLE;
			}
	}
}

public Event_Incap (Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapType[victim]=INCAP;
	if(GetConVarInt(l4d_selfhelp_incap)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
		if(GetConVarInt(l4d_selfhelp_bot) == 1 && IsClientBot(victim) && wS_Timer[victim] == INVALID_HANDLE)
		{
			wS_Timer[victim] = CreateTimer(GetConVarFloat(l4d_selfhelp_duration), BotsSelfHelp, victim);
		}
	}
}

public Event_Revive(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));//userid
	if (wS_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(wS_Timer[client]);
		wS_Timer[client] = INVALID_HANDLE;
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (wS_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(wS_Timer[client]);
		wS_Timer[client] = INVALID_HANDLE;
	}
}

bool:IsClientBot(client)
{
	return IsValidClient(client) && IsFakeClient(client);
}

stock GetSurvivorPermanentHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock bool:IsPlayerIncap(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

DangerStatus(client)
{
	new dangerSt=0;
	if(IsClientConnected(client) && IsClientInGame(client) /*&& IsPlayerIncap(client)*/ && GetClientTeam(client) == 2)
	{
		if(IsPlayerIncap(client))
		{
			new VictimHealth = GetSurvivorPermanentHealth(client);

			if(VictimHealth<150)
			{
				dangerSt+=130;
			} else
			if(VictimHealth<200)
			{
				dangerSt+=50;
			}
		}
		if(minDistanceToSurvivor(client) > 2000)
		{
			dangerSt+=50;
		}
		dangerSt+=incappedSurvivor() * 35;
		dangerSt+=deadSurvivor() * 65;
		dangerSt+=NeedHelpTeam() * 35;
		if(!HavePills(client) && (HaveKit(client) || HaveDefib(client)))
		{
			dangerSt-=20;
		}
	}
	return dangerSt;
}

NeedHelpTeam()
{
	new needhtnum=0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && Attacker[i] != 0)
		{
			needhtnum++;
		}
	}
	return needhtnum;
}

minDistanceToSurvivor(client)
{
	decl Float:pos[2][3];
	new Float:tDistance;
	new Float:dDistance=9999.0;
	GetClientAbsOrigin(client, pos[0]);
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && i!=client)
		{
			GetClientAbsOrigin(i, pos[1]);
			tDistance=SquareRoot(Pow(pos[1][0]-pos[0][0], 2.0) + Pow(pos[1][1]-pos[0][1], 2.0) + Pow(pos[1][2]-pos[0][2], 2.0));
			if(tDistance<dDistance)
			{
				dDistance = tDistance;
			}
		}
	}
	return RoundFloat(dDistance);
}

incappedSurvivor()
{
	new incapnum=0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerIncap(i))
		{
			incapnum++;
		}
	}
	return incapnum;
}

deadSurvivor()
{
	new deadnum=0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			deadnum++;
		}
	}
	return deadnum;
}

public Action:BotsSelfHelp(Handle:timer, any:client)
{
	if (!IsValidClient(client)) return;
	if (!IsPlayerAlive(client)) return;
	if (GetConVarInt(l4d_selfhelp_bot) == 0) return;

	if(CanSelfHelp(client))
	{
		//if(DangerStatus(client)>99)
		if(DangerStatus(client)>0)
		{
			SelfHelp(client);
			if(wS_Timer[client]!= INVALID_HANDLE)
			{
				KillTimer(wS_Timer[client]);
				wS_Timer[client] = INVALID_HANDLE;
			}
		}
	}
	BotPickupIncap(client);
}

BotPickupIncap(client)
{
	new haveone=0;
	new PillSlot=GetPlayerWeaponSlot(client, 4);
	new KitSlot=GetPlayerWeaponSlot(client, 3);
	if (PillSlot != -1)
	{
		haveone++;
	}
	if(KitSlot !=-1)
	{
		if(HaveKit(client))
		{
			haveone++;
		}
		else if(HaveDefib(client))
		{
			haveone++;
		}
	}
	if(haveone>0)
	{
		if(GetConVarInt(l4d_selfhelp_pickup)>0)
		{
			new bool:pickup=false;
			new Float:dis=100.0;
			new ent = -1;
			if (PillSlot == -1)
			{
				decl Float:targetVector1[3];
				decl Float:targetVector2[3];
				GetClientEyePosition(client, targetVector1);
				ent=-1;
				while ((ent = FindEntityByClassname(ent,  "weapon_pain_pills")) != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						if(GetVectorDistance(targetVector1  , targetVector2)<dis)
						{
							CheatCommand(client, "give", "pain_pills", "");
							RemoveEdict(ent);
							pickup=true;
							break;
						}
					}
				}
				if(!pickup)
				{
					ent = -1;
					while ((ent = FindEntityByClassname(ent,  "weapon_adrenaline")) != -1)
					{
						if (IsValidEntity(ent))
						{
							GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
							if(GetVectorDistance(targetVector1  , targetVector2)<dis)
							{
								CheatCommand(client, "give", "adrenaline", "");
								RemoveEdict(ent);
								pickup=true;
								break;
							}
						}
					}
				}
			}
			if (KitSlot == -1 && !pickup)
			{
				decl Float:targetVector1[3];
				decl Float:targetVector2[3];
				GetClientEyePosition(client, targetVector1);
				ent = -1;
				while ((ent = FindEntityByClassname(ent,  "weapon_first_aid_kit")) != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						if(GetVectorDistance(targetVector1  , targetVector2)<dis)
						{
							CheatCommand(client, "give", "first_aid_kit", "");
							RemoveEdict(ent);
							pickup=true;
							break;
						}
					}
				}
			}
			if (KitSlot == -1 && !pickup)
			{
				decl Float:targetVector1[3];
				decl Float:targetVector2[3];
				GetClientEyePosition(client, targetVector1);
				ent = -1;
				while ((ent = FindEntityByClassname(ent,  "weapon_defibrillator")) != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						if(GetVectorDistance(targetVector1  , targetVector2)<dis)
						{
							CheatCommand(client, "give", "defibrillator", "");
							RemoveEdict(ent);
							pickup=true;
							break;
						}
					}
				}
			}
			if (GetPlayerWeaponSlot(client, 1)==-1 && !pickup)
			{
				decl Float:targetVector1[3];
				decl Float:targetVector2[3];
				GetClientEyePosition(client, targetVector1);
				ent = -1;
				while ((ent = FindEntityByClassname(ent,  "weapon_pistol")) != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						if(GetVectorDistance(targetVector1  , targetVector2)<dis)
						{
							CheatCommand(client, "give", "pistol", "");
							RemoveEdict(ent);
							pickup=true;
							break;
						}
					}
				}
			}
		}
	}
}

public Action:player_ledge_grab(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapType[victim]=INCAP_EDGEGRAB;
	if(GetConVarInt(l4d_selfhelp_edgegrab)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
		if(IsClientBot(victim) && wS_Timer[victim] == INVALID_HANDLE)
		{
			wS_Timer[victim] = CreateTimer(GetConVarFloat(l4d_selfhelp_duration), BotsSelfHelp, victim);
		}
	}
}

public Action:WatchPlayer(Handle:timer, any:client)
{
	if (!IsValidClient(client)) return;
	if (!IsPlayerAlive(client)) return;
	if (!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0)return;
	if(Timers[client]!=INVALID_HANDLE)return;

	HelpOtherState[client]=HelpState[client]=STATE_NONE;
	Timers[client]=CreateTimer(1.0/TICKS, PlayerTimer, client, TIMER_REPEAT);
}

public Action:AdvertisePills(Handle:timer, any:client)
{
	if (!IsValidClient(client)) return;
	if (!IsPlayerAlive(client)) return;

	if(CanSelfHelp(client))
		PrintToChat(client, "%t", "Keyboard Key Self Help");
}

bool:CanSelfHelp(client)
{
	new bool:pills=HavePills(client);
	new bool:adrenaline=HaveAdrenaline(client);
	new bool:kit=HaveKit(client);
	new bool:defib=HaveDefib(client);
	new bool:ok=false;
	new self;
	if(IncapType[client]==INCAP)
	{
		self=GetConVarInt( l4d_selfhelp_incap);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && (kit || defib))ok=true;
	}
	else if(IncapType[client]== INCAP_EDGEGRAB)
	{
		self=GetConVarInt( l4d_selfhelp_edgegrab);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && (kit || defib))ok=true;
	}
	else if(IncapType[client]== INCAP_GRAB)
	{
		self=GetConVarInt( l4d_selfhelp_grab);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && (kit || defib))ok=true;
	}
	else if(IncapType[client]== INCAP_POUNCE)
	{
		self=GetConVarInt( l4d_selfhelp_pounce);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && (kit || defib))ok=true;
	}
	else if(IncapType[client]== INCAP_RIDE)
	{
		self=GetConVarInt( l4d_selfhelp_ride);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && (kit || defib))ok=true;
	}
	else if(IncapType[client]== INCAP_PUMMEL)
	{
		self=GetConVarInt( l4d_selfhelp_pummel);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && (kit || defib))ok=true;
	}
	return ok;
}

SelfHelpUseSlot(client)
{
	new pills = GetPlayerWeaponSlot(client, 4);
	new kit=GetPlayerWeaponSlot(client, 3);
	new slot=-1;
	new self;
	if(IncapType[client]==INCAP)
	{
		self=GetConVarInt( l4d_selfhelp_incap);
		if((self==1 || self==3) && pills!=-1)slot=4;
		else if ((self==2 || self==3) && kit)slot=3;
	}
	else if(IncapType[client]== INCAP_EDGEGRAB)
	{
		self=GetConVarInt( l4d_selfhelp_edgegrab);
		if((self==1 || self==3) && pills!=-1)slot=4;
		else if ((self==2 || self==3) && kit)slot=3;
	}
	else if(IncapType[client]== INCAP_GRAB)
	{
		self=GetConVarInt( l4d_selfhelp_grab);
		if((self==1 || self==3) && pills!=-1)slot=4;
		else if ((self==2 || self==3) && kit)slot=3;
	}
	else if(IncapType[client]== INCAP_POUNCE)
	{
		self=GetConVarInt( l4d_selfhelp_pounce);
		if((self==1 || self==3) && pills!=-1)slot=4;
		else if ((self==2 || self==3) && kit)slot=3;
	}
	else if(IncapType[client]== INCAP_RIDE)
	{
		self=GetConVarInt( l4d_selfhelp_ride);
		if((self==1 || self==3) && pills!=-1)slot=4;
		else if ((self==2 || self==3) && kit)slot=3;
	}
	else if(IncapType[client]== INCAP_PUMMEL)
	{
		self=GetConVarInt( l4d_selfhelp_pummel);
		if((self==1 || self==3) && pills!=-1)slot=4;
		else if ((self==2 || self==3) && kit)slot=3;
	}
	return slot;
}

public Action:PlayerTimer(Handle:timer, any:client)
{
	if(!g_bValidGameMode)
	{
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	new Float:time=GetEngineTime();
	if (client==0)
	{
		HelpOtherState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		HelpOtherState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0)
	{
		HelpOtherState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]!=0)
	{
		if (!IsClientInGame(Attacker[client]) || !IsPlayerAlive(Attacker[client]))
		{
			HelpOtherState[client]=HelpState[client]=STATE_NONE;
			Timers[client]=INVALID_HANDLE;
			Attacker[client]=0;
			return Plugin_Stop;
		}
	}
	if(HelpState[client]==STATE_OK)
	{
		HelpOtherState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	new buttons = GetClientButtons(client);
	new haveone=0;
	new PillSlot = GetPlayerWeaponSlot(client, 4);
	new KitSlot=GetPlayerWeaponSlot(client, 3);
	if (PillSlot != -1)
	{
		haveone++;
	}
	if(KitSlot !=-1)
	{
		if(HaveKit(client))
		{
			haveone++;
		}
		else if(HaveDefib(client))
		{
			haveone++;
		}
	}
	if(haveone>0)
	{
		if((buttons & IN_DUCK) ||  (buttons & IN_USE))
		{
			if(CanSelfHelp(client))
			{
				if(L4D2Version)
				{
					if(HelpState[client]==STATE_NONE)
					{
						HelpStartTime[client]=time;
						SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_duration));
						PrintHintText(client, "%t", "Helping Yourself");
					}
				}
				else
				{
					if(HelpState[client]==STATE_NONE) HelpStartTime[client]=time;
					ShowBar(client,"self help ", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration));
				}
				HelpState[client]=STATE_SELFHELP;

				if(time-HelpStartTime[client]>GetConVarFloat(l4d_selfhelp_duration))
				{
					if(HelpState[client]!=STATE_OK)
					{
						SelfHelp(client);
						if(L4D2Version)KillProgressBar(client);
					}
				}
			}
			else if(HelpState[client]==STATE_SELFHELP)
			{
				if(L4D2Version)KillProgressBar(client);
				HelpState[client]=STATE_NONE;
			}
		}
		else
		{
			if(HelpState[client]==STATE_SELFHELP)
			{
				if(L4D2Version)
				{
					KillProgressBar(client);
				}
				else
				{
					ShowBar(client, "self help ", 0.0, GetConVarFloat(l4d_selfhelp_duration));
				}
				HelpState[client]=STATE_NONE;
			}
		}
	}
	else if(GetConVarInt(l4d_selfhelp_eachother)>0)
	{
		if ((buttons & IN_DUCK) ||  (buttons & IN_USE))
		{
			new Float:dis=50.0;
			new Float:pos[3];
			new Float:targetVector[3];
			GetClientEyePosition(client, pos);
			new bool:findone=false;
			new other=0;
			for (new target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target) && target!=client)
				{
					if (IsPlayerAlive(target))
					{
						if(GetClientTeam(target)==2 && (IsPlayerIncapped(target) || IsPlayerGrapEdge(target)))
						{
							GetClientAbsOrigin(target, targetVector);
							new Float:distance = GetVectorDistance(targetVector, pos);
							if(distance<dis)
							{
								findone=true;
								other=target;
								break;
							}
						}
					}
				}
			}
			if(findone)
			{
				char msg[250];
				Format(msg, sizeof(msg), "%t", "Helping Target", other);
				if(HelpOtherState[client]==STATE_NONE)
				{
					if(L4D2Version)
					{
						SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_duration));
						PrintHintText(client, msg);
					}
					PrintHintText(other, "%t", "Helping You", other);
					HelpStartTime[client]=time;
				}
				HelpOtherState[client]=STATE_SELFHELP;
				if(!L4D2Version) ShowBar(client, msg, time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration));
				if(time-HelpStartTime[client]>GetConVarFloat(l4d_selfhelp_duration))
				{
					HelpOther(other, client);
					HelpOtherState[client]=STATE_NONE;
					if(L4D2Version) KillProgressBar(client);
				}
			}
			else
			{
				if(HelpOtherState[client]!=STATE_NONE)
				{
					if(L4D2Version) KillProgressBar(client);
					else ShowBar(client, "help other", 0.0, GetConVarFloat(l4d_selfhelp_duration));
				}
				HelpOtherState[client]=STATE_NONE;
			}
		}
		else
		{
			if(HelpOtherState[client]!=STATE_NONE)
			{
				if(L4D2Version) KillProgressBar(client);
				else ShowBar(client, "help other", 0.0, GetConVarFloat(l4d_selfhelp_duration));
			}
			HelpOtherState[client]=STATE_NONE;
		}
	}
	if ((buttons & IN_DUCK) && GetConVarInt(l4d_selfhelp_pickup)>0)
	{
		new bool:pickup=false;
		new Float:dis=100.0;
		new ent = -1;
		if (PillSlot == -1)
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent=-1;
			while ((ent = FindEntityByClassname(ent,  "weapon_pain_pills")) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{
						CheatCommand(client, "give", "pain_pills", "");
						RemoveEdict(ent);
						pickup=true;
						PrintHintText(client, "%t", "Found Pills");
						break;
					}
				}
			}
			if(!pickup)
			{
				ent = -1;
				while ((ent = FindEntityByClassname(ent,  "weapon_adrenaline")) != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						if(GetVectorDistance(targetVector1  , targetVector2)<dis)
						{
							CheatCommand(client, "give", "adrenaline", "");
							RemoveEdict(ent);
							pickup=true;
							PrintHintText(client, "%t", "Found Adrenaline");
							break;
						}
					}
				}
			}
		}
		if (KitSlot == -1 && !pickup)
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent = -1;
			while ((ent = FindEntityByClassname(ent,  "weapon_first_aid_kit")) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{
						CheatCommand(client, "give", "first_aid_kit", "");
						RemoveEdict(ent);
						pickup=true;
						PrintHintText(client, "%t", "Found Medkit");
						break;
					}
				}
			}
		}
		if (KitSlot == -1 && !pickup)
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent = -1;
			while ((ent = FindEntityByClassname(ent,  "weapon_defibrillator")) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{
						CheatCommand(client, "give", "defibrillator", "");
						RemoveEdict(ent);
						pickup=true;
						PrintHintText(client, "%t", "Found Defibrillator");
						break;
					}
				}
			}
		}
		if (GetPlayerWeaponSlot(client, 1)==-1 && !pickup)
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent = -1;
			while ((ent = FindEntityByClassname(ent,  "weapon_pistol")) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{
						CheatCommand(client, "give", "pistol", "");
						RemoveEdict(ent);
						pickup=true;
						PrintHintText(client, "%t", "Found Pistol");
						break;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

SelfHelp(client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0)
	{
		return;
	}
	new bool:pills=HavePills(client);
	new bool:adrenaline=HaveAdrenaline(client);
	new bool:kit=HaveKit(client);
	new bool:defib=HaveDefib(client);
	new slot=SelfHelpUseSlot(client);
	if(slot!=-1)
	{
		new weaponslot=GetPlayerWeaponSlot(client, slot);
		if(slot ==4)
		{
			if(GetConVarInt(l4d_selfhelp_kill)>0) KillAttack(client);
			RemovePlayerItem(client, weaponslot);
			ReviveClientWithPills(client);
			HelpState[client]=STATE_OK;
			if(adrenaline)	PrintToChatAll("%t", "Self Help with Adrenaline", client);
			if(pills)	PrintToChatAll("%t", "Self Help with Pills", client);
			//EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound
		}
		else if(slot==3)
		{
			if(GetConVarInt(l4d_selfhelp_kill)>0) KillAttack(client);
			RemovePlayerItem(client, weaponslot);
			ReviveClientWithKit(client);
			HelpState[client]=STATE_OK;
			if(kit)PrintToChatAll("%t", "Self Help with Medkit", client);
			if(defib)PrintToChatAll("%t", "Self Help with Defibrillator", client);
			//EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound
		}
	}
	else
	{
		PrintHintText(client, "%t", "Self Help Failed");
		HelpState[client]=STATE_FAILED;
	}
}

HelpOther(client, helper)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0)
		return;

	int revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", revivecount + 1);
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		if (L4D2Version)
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	}
	else
		StopSoundPerm(client, "player/heartbeatloop.wav");

	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("pain_pills_health_value")));
	SetEntityHealth(client, 1);

	PrintToChatAll("%t", "Self Help Other", helper, client);
}

ReviveClientWithKit(client)
{
	int revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", revivecount + 1);
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		if (L4D2Version)
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	}
	else
		StopSoundPerm(client, "player/heartbeatloop.wav");

	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("first_aid_heal_percent"))*100.0);
	SetEntityHealth(client, 1);
}

ReviveClientWithPills(client)
{
	int revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);
	SetEntProp(client, Prop_Send, "m_currentReviveCount", revivecount + 1);
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		if (L4D2Version)
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	}
	else
		StopSoundPerm(client, "player/heartbeatloop.wav");

	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("pain_pills_health_value")));
	SetEntityHealth(client, 1);
}

KillAttack(client)
{
	new a=Attacker[client];
	if(GetConVarInt(l4d_selfhelp_kill)==1 && a!=0)
	{
		if(IsClientInGame(a) && GetClientTeam(a)==3 &&  IsPlayerAlive(a))
		{
			ForcePlayerSuicide(a);
			if(L4D2Version)	EmitSoundToAll(SOUND_KILL2, client);
			else EmitSoundToAll(SOUND_KILL1, client);
		}
	}
}

new String:Gauge1[2] = "-";
new String:Gauge3[2] = "#";
ShowBar(client, String:msg[], Float:pos, Float:max)
{
	new i ;
	new String:ChargeBar[100];
	Format(ChargeBar, sizeof(ChargeBar), "");
	new Float:GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum<0.0)
		GaugeNum = 0.0;
	for(i=0; i<100; i++)
		ChargeBar[i] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	if(p>=0 && p<100)ChargeBar[p] = Gauge3[0];
	/* Display gauge */
	PrintCenterText(client, "%s  %3.0f %\n<< %s >>", msg, GaugeNum, ChargeBar);
}

bool:HaveKit(client)
{
	decl String:weapon[32];
	new KitSlot=GetPlayerWeaponSlot(client, 3);
	if(KitSlot !=-1)
	{
		GetEdictClassname(KitSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_first_aid_kit"))
			return true;
	}
	return false;
}

bool:HaveDefib(client)
{
	decl String:weapon[32];
	new KitSlot=GetPlayerWeaponSlot(client, 3);
	if(KitSlot !=-1)
	{
		GetEdictClassname(KitSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_defibrillator"))
			return true;
	}
	return false;
}

bool:HavePills(client)
{
	decl String:weapon[32];
	new KitSlot=GetPlayerWeaponSlot(client, 4);
	if(KitSlot !=-1)
	{
		GetEdictClassname(KitSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_pain_pills"))
			return true;
	}
	return false;
}

bool:HaveAdrenaline(client)
{
	decl String:weapon[32];
	new KitSlot=GetPlayerWeaponSlot(client, 4);
	if(KitSlot !=-1)
	{
		GetEdictClassname(KitSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_adrenaline"))
			return true;
	}
	return false;
}

stock CheatCommand(client, String:command[], String:parameter1[], String:parameter2[])
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

bool:IsPlayerGrapEdge(client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}

reset()
{
	for(new i = 1; i <= MaxClients; i++)
	{
			HelpOtherState[i]=HelpState[i]=STATE_NONE;
			Attacker[i]=0;
			HelpStartTime[i]=0.0;
			if(Timers[i]!=INVALID_HANDLE)
			{
				KillTimer(Timers[i]);
			}
			Timers[i]=INVALID_HANDLE;
	}
}

stock SetupProgressBar(client, Float:time)
{
	//KillProgressBar(client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", client);
}

stock KillProgressBar(client)
{
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", 0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", 0);
}

stock StopSoundPerm(client, String:sound[])
{
	StopSound(client, SNDCHAN_REPLACE, sound);
	StopSound(client, SNDCHAN_AUTO, sound);
	StopSound(client, SNDCHAN_WEAPON, sound);
	StopSound(client, SNDCHAN_VOICE, sound);
	StopSound(client, SNDCHAN_ITEM, sound);
	StopSound(client, SNDCHAN_BODY, sound);
	StopSound(client, SNDCHAN_STREAM, sound);
	StopSound(client, SNDCHAN_STATIC, sound); //Remove heartbeat
	StopSound(client, SNDCHAN_VOICE_BASE, sound);
	StopSound(client, SNDCHAN_USER_BASE, sound);
}

/**
 * Validates if is a valid client.
 *
 * @param client		Client index.
 * @return			  True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}