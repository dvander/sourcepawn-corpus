#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <l4d2_maps>
#include <colors>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY
#define MAXLENGTH 128

#define UNLOCK 0
#define LOCK 1

#define STARTROOM_MAX_DIST		1000
#define FLAG_IGNORE_USE			32768

#define PANIC_SOUND "npc/mega_mob/mega_mob_incoming.wav"

#define SAFEDOOR_MODEL_01 "checkpoint_door_01.mdl"
#define SAFEDOOR_MODEL_02 "checkpoint_door_-01.mdl"

ConVar sm_ar_announce;
ConVar sm_ar_lock_tankalive;
ConVar sm_ar_lock_antitank_time;
ConVar sm_ar_DoorLock;
ConVar sm_ar_DoorLockShow;
ConVar sm_ar_AntySpam;

int nShowType;
int g_iCountDown;
int g_iUseCounter;
int g_iSeconds;

bool g_bDoorStartOpening;
bool g_bRoundEnd;
bool g_bWaitTank;
bool g_bTimerStart;

int g_iSafetyLock;
int g_iIdGoal;

char g_sKeyman[MAXLENGTH];
char g_sMap[64];

Handle g_TimerOne = null;
Handle g_TimerTwo = null;

static const char SoundNotice[MAXLENGTH] = "doors/latchlocked2.wav";
static const char SoundDoorOpen[MAXLENGTH] = "doors/door_squeek1.wav";

public Plugin myinfo = 
{
	name = "[L4D2] Anti-Runner System (Versus edition)",
	author = "ztar (modified by SupermenCJ for versus)",
	description = "Only Keyman can open saferoom door.",
	version = PLUGIN_VERSION,
	url = "http://ztar.blog7.fc2.com/"
}

public void OnPluginStart()
{
	LoadTranslations("keyman.phrases"); 

	sm_ar_announce = CreateConVar("sm_ar_announce","1", "Announce plugin info(0:OFF 1:ON)", CVAR_FLAGS);
	sm_ar_lock_tankalive = CreateConVar("sm_ar_lock_tankalive","1", "Lock door if any Tank is alive(0:OFF 1:ON)", CVAR_FLAGS);
	sm_ar_lock_antitank_time = CreateConVar("sm_ar_lock_antitank_time","180", "Период, в течении которого выжившие не смогут разблокировать двери при живо танке", CVAR_FLAGS);
	sm_ar_DoorLock = CreateConVar("sm_ar_doorlock_sec", "60", "number of seconds", CVAR_FLAGS, true, 5.0, true, 300.0);
	sm_ar_DoorLockShow = CreateConVar("sm_ar_doorlock_show", "0", "countdown type (def:0 / center text:0 / hint text:1)", CVAR_FLAGS, true, 0.0, true, 1.0);
	sm_ar_AntySpam = CreateConVar("sm_ar_door_lock_spam", "3", "Survovors can close the door one time per <your choice> sec");
	HookEvent("player_use", Event_PlayerUse);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("player_left_checkpoint", Event_LeftSaferoom, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd);
	
	RegAdminCmd("sm_initdoor", Command_InintDoor, ADMFLAG_CONFIG);
	
	CreateTimer(1.0, MapStart);
}

forward Action Lock_CheckpointDoorStartOpened();

public Action MapStart(Handle timer)
{
	OnMapStart();
}

public void OnMapStart()
{
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	
	PrecacheSound(SoundNotice, true);
	PrecacheSound(SoundDoorOpen, true);
	PrecacheSound("ambient/alarms/klaxon1.wav", true);
	PrecacheSound(PANIC_SOUND, true);
}

public Action Event_LeftSaferoom(Event event, const char[] name, bool dontBroadcast)
{
	if (!GB_IsFirstMapInScenario())
		return;
	if (g_bTimerStart)
		return;
	
	g_bTimerStart = true;
	CreateTimer(25.0, LockSafeRoom, _);
}

public Action Lock_CheckpointDoorStartOpened()
{
	if (g_bTimerStart)
		return;
	
	g_bTimerStart = true;
	CreateTimer(12.0, LockSafeRoom, _);
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	g_bDoorStartOpening = false;
	g_bRoundEnd = false;
	g_bTimerStart = false;
	g_bWaitTank = true;
	
	g_iCountDown = sm_ar_DoorLock.IntValue;
	g_iSeconds = sm_ar_lock_antitank_time.IntValue;
	g_iUseCounter = 0;
	
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bRoundEnd)
		g_bRoundEnd = true;
	
	g_iUseCounter = 0;
	
	if (g_TimerOne != null)
	{
		KillTimer(g_TimerOne);
		g_TimerOne = null;
	}
	if (g_TimerTwo != null)
	{
		KillTimer(g_TimerTwo);
		g_TimerTwo = null;
	}

	return Plugin_Continue;
}

public Action Command_InintDoor(int client, int args)
{
	InitDoor();
	return Plugin_Handled;
}

public void InitDoor()
{
	if (GB_IsMissionFinalMap())
		return;
	
	if (StrContains(g_sMap, "c1m1", true) > -1 || StrContains(g_sMap, "c1m2", true) > -1 || StrContains(g_sMap, "c1m3", true) > -1 || 
		StrContains(g_sMap, "c2m1", true) > -1 || StrContains(g_sMap, "c2m2", true) > -1 || StrContains(g_sMap, "c2m3", true) > -1 || 
		StrContains(g_sMap, "c2m4", true) > -1 || StrContains(g_sMap, "c3m1", true) > -1 || StrContains(g_sMap, "c3m2", true) > -1 || 
		StrContains(g_sMap, "c3m3", true) > -1 || StrContains(g_sMap, "c4m1", true) > -1 || StrContains(g_sMap, "c4m2", true) > -1 || 
		StrContains(g_sMap, "c4m3", true) > -1 || StrContains(g_sMap, "c4m4", true) > -1 || StrContains(g_sMap, "c5m1", true) > -1 || 
		StrContains(g_sMap, "c5m2", true) > -1 || StrContains(g_sMap, "c5m3", true) > -1 || StrContains(g_sMap, "c5m4", true) > -1 || 
		StrContains(g_sMap, "c6m1", true) > -1 || StrContains(g_sMap, "c6m2", true) > -1 || StrContains(g_sMap, "c7m1", true) > -1 || 
		StrContains(g_sMap, "c7m2", true) > -1 || StrContains(g_sMap, "c8m1", true) > -1 || StrContains(g_sMap, "c8m2", true) > -1 || 
		StrContains(g_sMap, "c8m3", true) > -1 || StrContains(g_sMap, "c8m4", true) > -1 || StrContains(g_sMap, "c9m1", true) > -1 || 
		StrContains(g_sMap, "c10m1", true) > -1 || StrContains(g_sMap, "c11m1", true) > -1 || 
		StrContains(g_sMap, "c11m2", true) > -1 || StrContains(g_sMap, "c11m3", true) > -1 || StrContains(g_sMap, "c11m4", true) > -1 || 
		StrContains(g_sMap, "12m1", true) > -1 || StrContains(g_sMap, "12m2", true) > -1 || StrContains(g_sMap, "12m3", true) > -1 || 
		StrContains(g_sMap, "12m4", true) > -1 || StrContains(g_sMap, "c13m1", true) > -1 || StrContains(g_sMap, "c13m2", true) > -1 || 
		StrContains(g_sMap, "c13m3", true) > -1 || StrContains(g_sMap, "l4d_yama_2", true) > -1)
	{
		int Entity = -1;
		while((Entity = FindEntityByClassname(Entity, "prop_door_rotating_checkpoint")) != -1)
		{
			char model[255];
			GetEntPropString(Entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrContains(model, SAFEDOOR_MODEL_01, false) != -1 || StrContains(model, SAFEDOOR_MODEL_02, false) != -1)
				continue;
			
			if (GetEntProp(Entity, Prop_Data, "m_hasUnlockSequence") == UNLOCK)
			{
				g_iIdGoal = Entity;
				ControlDoor(Entity, LOCK);
				break;
			}
		}
		g_iSafetyLock = LOCK;
		return;
	}
	
	float vSurvivor[3], vDoor[3];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, vSurvivor);
			
			if (vSurvivor[0] != 0 && vSurvivor[1] != 0 && vSurvivor[2] != 0)
				break;
		}
	}
	
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "prop_door_rotating_checkpoint")) != INVALID_ENT_REFERENCE)
	{
		char model[255];
		GetEntPropString(iEnt, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrContains(model, SAFEDOOR_MODEL_01, false) != -1 || StrContains(model, SAFEDOOR_MODEL_02, false) != -1)
			continue;
		if (GetEntProp(iEnt, Prop_Data, "m_spawnflags") == FLAG_IGNORE_USE)
			continue;
		
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vDoor);
		
		if (GetVectorDistance(vSurvivor, vDoor) < STARTROOM_MAX_DIST)
			continue;
		
		g_iIdGoal = iEnt;
		ControlDoor(iEnt, LOCK);
		break;
	}
	g_iSafetyLock = LOCK;
}


public Action LockSafeRoom(Handle timer)
{
	if (StrEqual(g_sMap, "2ee_03", false) || 
		StrEqual(g_sMap, "bhm3_station", false) || 
		StrEqual(g_sMap, "ec03_village", false) || 
		StrEqual(g_sMap, "re3m1", false) || 
		StrEqual(g_sMap, "re3m2", false) || 
		StrEqual(g_sMap, "re3m3", false) || 
		StrEqual(g_sMap, "re3m4", false) || 
		StrEqual(g_sMap, "re3m5", false) || 
		StrEqual(g_sMap, "re3m6", false) || 
		StrEqual(g_sMap, "nt03_moria", false))
		return;
	if (GB_IsMissionFinalMap())
		return;

	float vSurvivor[3];
	float vDoor[3];
	
	if (StrEqual(g_sMap, "c5m1_waterfront", false) || 
		StrEqual(g_sMap, "c7m1_docks", false) || 
		StrEqual(g_sMap, "c10m1_caves", false) || 
		StrEqual(g_sMap, "l4d_yama_2", false))
	{
		int Entity = -1;
		while((Entity = FindEntityByClassname(Entity, "prop_door_rotating_checkpoint")) != -1)
		{
			char model[255];
			GetEntPropString(Entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrContains(model, SAFEDOOR_MODEL_01, false) != -1 || StrContains(model, SAFEDOOR_MODEL_02, false) != -1)
				continue;
			
			if (GetEntProp(Entity, Prop_Data, "m_hasUnlockSequence") == UNLOCK)
			{
				g_iIdGoal = Entity;
				ControlDoor(Entity, LOCK);
				break;
			}
		}
		g_iSafetyLock = LOCK;
		return;
	}
	
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			GetClientAbsOrigin(i, vSurvivor);

			if (vSurvivor[0] != 0 && vSurvivor[1] != 0 && vSurvivor[2] != 0)
				break;
		}
		i += 1;
	}

	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "prop_door_rotating_checkpoint")) != INVALID_ENT_REFERENCE)
	{
		char model[255];
		GetEntPropString(iEnt, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrContains(model, SAFEDOOR_MODEL_01, false) != -1 || StrContains(model, SAFEDOOR_MODEL_02, false) != -1)
			continue;
		if (GetEntProp(iEnt, Prop_Data, "m_spawnflags") == FLAG_IGNORE_USE)
			continue;
		
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vDoor);
		
		if (GetVectorDistance(vSurvivor, vDoor) < STARTROOM_MAX_DIST)
			continue;

		g_iIdGoal = iEnt;
		ControlDoor(iEnt, LOCK);
		break;
	}
	g_iSafetyLock = LOCK;
}

/*
public Action LockSafeRoom(Handle timer)
{
	if (GB_IsMissionFinalMap())
		return;
	
	if (StrContains(g_sMap, "c1m1", true) > -1 || StrContains(g_sMap, "c1m2", true) > -1 || StrContains(g_sMap, "c1m3", true) > -1 || 
		StrContains(g_sMap, "c2m1", true) > -1 || StrContains(g_sMap, "c2m2", true) > -1 || StrContains(g_sMap, "c2m3", true) > -1 || 
		StrContains(g_sMap, "c2m4", true) > -1 || StrContains(g_sMap, "c3m1", true) > -1 || StrContains(g_sMap, "c3m2", true) > -1 || 
		StrContains(g_sMap, "c3m3", true) > -1 || StrContains(g_sMap, "c4m1", true) > -1 || StrContains(g_sMap, "c4m2", true) > -1 || 
		StrContains(g_sMap, "c4m3", true) > -1 || StrContains(g_sMap, "c4m4", true) > -1 || StrContains(g_sMap, "c5m1", true) > -1 || 
		StrContains(g_sMap, "c5m2", true) > -1 || StrContains(g_sMap, "c5m3", true) > -1 || StrContains(g_sMap, "c5m4", true) > -1 || 
		StrContains(g_sMap, "c6m1", true) > -1 || StrContains(g_sMap, "c6m2", true) > -1 || StrContains(g_sMap, "c7m1", true) > -1 || 
		StrContains(g_sMap, "c7m2", true) > -1 || StrContains(g_sMap, "c8m1", true) > -1 || StrContains(g_sMap, "c8m2", true) > -1 || 
		StrContains(g_sMap, "c8m3", true) > -1 || StrContains(g_sMap, "c8m4", true) > -1 || StrContains(g_sMap, "c9m1", true) > -1 || 
		StrContains(g_sMap, "c10m1", true) > -1 || StrContains(g_sMap, "c11m1", true) > -1 || 
		StrContains(g_sMap, "c11m2", true) > -1 || StrContains(g_sMap, "c11m3", true) > -1 || StrContains(g_sMap, "c11m4", true) > -1 || 
		StrContains(g_sMap, "12m1", true) > -1 || StrContains(g_sMap, "12m2", true) > -1 || StrContains(g_sMap, "12m3", true) > -1 || 
		StrContains(g_sMap, "12m4", true) > -1 || StrContains(g_sMap, "c13m1", true) > -1 || StrContains(g_sMap, "c13m2", true) > -1 || 
		StrContains(g_sMap, "c13m3", true) > -1 || StrContains(g_sMap, "l4d_yama_2", true) > -1)
	{
		int Entity = -1;
		while((Entity = FindEntityByClassname(Entity, "prop_door_rotating_checkpoint")) != -1)
		{
			char model[255];
			GetEntPropString(Entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrContains(model, SAFEDOOR_MODEL_01, false) != -1 || StrContains(model, SAFEDOOR_MODEL_02, false) != -1)
				continue;
			
			if (GetEntProp(Entity, Prop_Data, "m_hasUnlockSequence") == UNLOCK)
			{
				g_iIdGoal = Entity;
				ControlDoor(Entity, LOCK);
				break;
			}
		}
		g_iSafetyLock = LOCK;
		return;
	}
	
	float vSurvivor[3], vDoor[3];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, vSurvivor);

			if (vSurvivor[0] != 0 && vSurvivor[1] != 0 && vSurvivor[2] != 0)
				break;
		}
	}
	
	int iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "prop_door_rotating_checkpoint")) != INVALID_ENT_REFERENCE)
	{
		char model[255];
		GetEntPropString(iEnt, Prop_Data, "m_ModelName", model, sizeof(model));
		if (StrContains(model, SAFEDOOR_MODEL_01, false) != -1 || StrContains(model, SAFEDOOR_MODEL_02, false) != -1)
			continue;
		if (GetEntProp(iEnt, Prop_Data, "m_spawnflags") == FLAG_IGNORE_USE)
			continue;

		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vDoor);

		if (GetVectorDistance(vSurvivor, vDoor) < STARTROOM_MAX_DIST)
			continue;

		g_iIdGoal = iEnt;
		ControlDoor(iEnt, LOCK);
		break;
	}
	g_iSafetyLock = LOCK;
}
*/

public Action Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int Entity = event.GetInt("targetid");
	
	if (IsValidEntity(Entity) && IsValidEdict(Entity) && (g_iSafetyLock == LOCK) && (Entity == g_iIdGoal))
	{
		char entname[MAXLENGTH];
		if (GetEdictClassname(Entity, entname, sizeof(entname)))
		{
			if (StrEqual(entname, "prop_door_rotating_checkpoint"))
			{
				if (!g_bDoorStartOpening)
				{
					g_iUseCounter++;
					CheckUseCounter();
				}
				
				if (IsAnyTanksAlive() && sm_ar_lock_tankalive.BoolValue && g_bWaitTank)
				{
					EmitSoundToAll(SoundNotice, Entity);
					PrintHintText(client, "%t!", "All tanks");
					return Plugin_Continue;
				}
				
				AcceptEntityInput(Entity, "Lock");
				SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
				
				if (client)
				{				
					if (!g_bDoorStartOpening)
					{
						g_bDoorStartOpening = true;
						nShowType = GetConVarBool(sm_ar_DoorLockShow);
						if (g_TimerOne != null)
						{
							KillTimer(g_TimerOne);
							g_TimerOne = null;
						}
						g_TimerOne = CreateTimer(1.0, TimerDoorCountDown, Entity, TIMER_REPEAT);
						GetClientName(client, g_sKeyman, sizeof(g_sKeyman));
					}
				}
				
				if (sm_ar_AntySpam.BoolValue)
					HookSingleEntityOutput(Entity, "OnFullyOpen", DL_OutPutOnFullyOpen);
			}
		}
	}
	return Plugin_Continue;
}

public Action TimerDoorCountDown(Handle timer, any Entity)
{
	if (g_iCountDown > 0)
	{
		EmitSoundToAll("ambient/alarms/klaxon1.wav", Entity, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_LOW, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		
		if (!nShowType)
			PrintCenterTextAll("[DOOR OPEN] %d sec", g_iCountDown);
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
					PrintHintText(i, "[DOOR OPEN] %d sec", g_iCountDown);
			}
		}
		g_iCountDown--;
		return Plugin_Continue;
	}
	g_TimerOne = null;

	EmitSoundToAll(SoundDoorOpen, Entity);
	g_iSafetyLock = UNLOCK;
	ControlDoor(Entity, UNLOCK);
	ServerCommand("exec checkpointreached.cfg");
	CreateTimer(10.0, TimerLoadOnEnd);

	if (sm_ar_announce.BoolValue)
		CPrintToChatAll("%t!", "The player %s reached the safe room", g_sKeyman);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			PrintHintText(i, "DOOR OPENED");
	}
	return Plugin_Stop;
}

public void ControlDoor(int Entity, int Operation)
{
	if (Operation == LOCK)
	{
		/* Close and lock */
		AcceptEntityInput(Entity, "Close");
		AcceptEntityInput(Entity, "Lock");
		AcceptEntityInput(Entity, "ForceClosed");
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", LOCK);
	}
	else if (Operation == UNLOCK)
	{
		/* Unlock and open */
		SetEntProp(Entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
		AcceptEntityInput(Entity, "Unlock");
		AcceptEntityInput(Entity, "ForceClosed");
		AcceptEntityInput(Entity, "Open");
	}
}

public void DL_OutPutOnFullyOpen(const char[] output, int caller, int activator, float delay)
{
	if (g_bDoorStartOpening)
	{
		AcceptEntityInput(activator, "Lock");
		SetEntProp(activator, Prop_Data, "m_hasUnlockSequence", 1);
		CreateTimer(sm_ar_AntySpam.FloatValue, DL_t_UnlockSafeRoom, EntIndexToEntRef(activator));
	}
}

public Action DL_t_UnlockSafeRoom(Handle timer, any entity)
{
	if ((entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE)
	{
		SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", 0);
		AcceptEntityInput(entity, "Unlock");
	}
}

bool IsAnyTanksAlive()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && !IsIncapacitated(i) && FindZombieClass(i) == 8) 
			return true;
	}
	return false;
}

int FindZombieClass(int client)
{
	return view_as<int>(GetEntProp(client, Prop_Send, "m_zombieClass"));
}

bool IsIncapacitated(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated"))
		return true;
	return false;
}

public Action TimerLoadOnEnd(Handle timer, any client)
{
	if (g_bDoorStartOpening)
		Panic();
	
	return Plugin_Stop;
}

void Panic()
{
	EmitSoundToAll(PANIC_SOUND);
	
	int bot = CreateFakeClient("mob");
	
	if (bot > 0)
	{
		if (IsFakeClient(bot))
		{
			SpawntyCommand(bot, "z_spawn_old", "mob auto");
			KickClient(bot);
		}
	}
}

void SpawntyCommand(int client, char[] command, char arguments[] = "")
{
	if (client)
	{
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

void CheckUseCounter()
{
	if (g_iUseCounter == 2)
	{
		g_iSeconds = sm_ar_lock_antitank_time.IntValue;
		if (g_TimerTwo != null)
		{
			KillTimer(g_TimerTwo);
			g_TimerTwo = null;
		}
		g_TimerTwo = CreateTimer(1.0, TimerAntiFarmStart, _, TIMER_REPEAT);
	}
	else if ((g_iUseCounter % 30) == 0)
		Panic();
}

public Action TimerAntiFarmStart(Handle timer)
{
	if (g_bRoundEnd)
		return Plugin_Stop;
	
	if (g_iSeconds > 0 && g_iUseCounter > 1)
	{
		if (!g_bDoorStartOpening)
			PrintCenterTextAll("[ANTITANK] %d сек.", g_iSeconds);
	}
	else if (g_iSeconds == 0)
	{
		if (g_iUseCounter > 1)
		{
			if (!g_bDoorStartOpening)
				g_bWaitTank = false;
		}
	}
	else if (g_iSeconds < 0 || g_iUseCounter < 2)
	{
		g_TimerTwo = null;
		return Plugin_Stop;
	}
	g_iSeconds--;
	
	return Plugin_Continue;
}
