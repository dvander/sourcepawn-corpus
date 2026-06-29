/****************************************************************************************************
* Plugin     : L4D Tank announce and lock door
* Version    : 1.1.7
* Game       : Left 4 Dead
* Author     : Finishlast
* Based on code  from:
* [L4D / L4D2] Lockdown System | 1.7 [Final] : Jan. 30, 2019 |
* https://forums.alliedmods.net/showthread.php?t=281305
* Aya Supay for making the code look great again
* MasterMind420 for providing a fix to check for all kinds of ending checkpoint doors
* Silvers for check for "end maps" & replacement for cooldown timer
* Marttt unethically adding support for l4d2 and timer to check tank and door checks :D
*
* Testers    : Myself / ZBzibing
* Website    : www.l4d.com
* Purpose    : This plugin announces tank spawns and locks the safehouse door until the tank is dead.
****************************************************************************************************/
public Plugin myinfo =
{
    name = "L4D - Tank Announce with automatic door locking",
    author = "finishlast",
    description = "Announce when a Tank has spawned and lock the door until Tank is dead",
    version = "1.1.7",
    url = "https://forums.alliedmods.net/showthread.php?t=321892"
}

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define UNLOCK 0
#define LOCK 1

#define TEAM_INFECTED 3
#define L4D1_ZOMBIECLASS_TANK 5
#define L4D2_ZOMBIECLASS_TANK 8

static float g_fCooldown = 0.0;
static bool g_bL4D2;
static bool g_bAliveTank;
static bool g_bIsFinale;
static int g_iTankClass;
static bool isusehooked;

int g_iCheckpointDoor = -1;


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    g_bL4D2 = (engine == Engine_Left4Dead2);
    g_iTankClass = (g_bL4D2 ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK);

    return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", Event_TankSpawn);
	
	g_bAliveTank = HasAnyTankAlive();

	CreateTimer(1.0, TimerAliveTankCheck, _, TIMER_REPEAT);
	HookEvent("round_end", event_round_end, EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
	g_fCooldown = 0.0;
}

public void event_round_end(Event event, const char[] name, bool dontBroadcast)
{
	g_fCooldown = 0.0;
}


public void OnMapStart()
{
    PrecacheSound("ui\\pickup_secret01.wav");
    PrecacheSound("player\\tank\\voice\\yell\\hulk_yell_4.wav");
}

public Action TimerAliveTankCheck(Handle timer)
{
    if (g_bAliveTank)
    {
        g_bAliveTank = HasAnyTankAlive();

        if (!g_bAliveTank)
            OnAllTanksDead();
    }

    return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bIsFinale = FindEntityByClassname(-1, "trigger_finale") != INVALID_ENT_REFERENCE;	
    isusehooked = false;
    g_fCooldown = 0.0;
    CreateTimer(1.5, CheckDelay);
}

public Action CheckDelay(Handle timer)
{
    if (g_bIsFinale != true && !IsBuggedMap())
        InitDoor();

    return Plugin_Continue;
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    g_bAliveTank = true;

    Command_Play("ui\\pickup_secret01.wav");
    Command_Play("player\\tank\\voice\\yell\\hulk_yell_4.wav");

		
    if (g_bIsFinale == true || IsBuggedMap())
    {
        PrintToChatAll("[SM] A Tank spawned!");
    }
    else
    {
        ControlDoor(LOCK);
        PrintToChatAll("[SM] A Tank spawned. The safehouse is locked!");
    }
}



void OnAllTanksDead()
{
    if (g_bIsFinale == true || IsBuggedMap())
    {
        PrintToChatAll("[SM] The Tank is dead!");
    }
    else
    {
        ControlDoor(UNLOCK);
        PrintToChatAll("[SM] The Tank is dead! The safehouse is open!");
    }
}

void ControlDoor(int iOperation)
{
    int entity = EntRefToEntIndex(g_iCheckpointDoor);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    switch (iOperation)
    {
        case LOCK:
        {	
		if(isusehooked==false){
   		HookEvent("player_use", OnPlayerUsePre, EventHookMode_Pre);
		isusehooked=true;
		}

                AcceptEntityInput(entity, "Close");
                AcceptEntityInput(entity, "Lock");
                AcceptEntityInput(entity, "ForceClosed");

                if (HasEntProp(entity, Prop_Data, "m_hasUnlockSequence"))
                    SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", LOCK);
        }
        case UNLOCK:
        {
		if(isusehooked == true){
   		UnhookEvent("player_use", OnPlayerUsePre, EventHookMode_Pre);
		isusehooked=false;
		}

                if (HasEntProp(entity, Prop_Data, "m_hasUnlockSequence"))
                    SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);

                AcceptEntityInput(entity, "Unlock");
                AcceptEntityInput(entity, "ForceClosed");
                AcceptEntityInput(entity, "Open");
        }
    }
}

void InitDoor()
{
	char targetname[20];
	int founddoor=0;
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

		if (StrEqual(targetname, "checkpoint_entrance"))
		{
			g_iCheckpointDoor = EntIndexToEntRef(entity);
			founddoor=1;
			break;
		}
	}

	char sModel[64];
	if (founddoor==0)
	{
		while((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) > -1)
		{
			if(IsValidEntity(entity))
			{
				
				GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

				if(StrContains(sModel, "checkpoint_door") > -1 && StrContains(sModel, "02") > -1)
				{
					g_iCheckpointDoor = EntIndexToEntRef(entity);
					break;
				}
			}
		}
	}
}

public Action OnPlayerUsePre(Event event, const char[] name, bool dontBroadcast)
{
	int used = event.GetInt("targetid");
	if (IsValidEnt(used))
	{
		char sEntityClass[64];
		GetEdictClassname(used, sEntityClass, sizeof(sEntityClass));
		if ( g_fCooldown > GetGameTime() || !StrEqual(sEntityClass, "prop_door_rotating_checkpoint") || EntIndexToEntRef(used) != g_iCheckpointDoor)
		{
			return Plugin_Continue;
		}
		else
		{
			g_fCooldown = GetGameTime() + 6.0;
			PrintToChatAll("[SM] You can't open the door while a tank is alive.");
		}		
	}		
	return Plugin_Continue;
}




public void Command_Play(const char[] arguments)
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        ClientCommand(client, "playgamesound %s", arguments);
    }
}

bool IsBuggedMap()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if (StrEqual(sMap, "c10m3_ranchhouse", false) //churchguy door fix
	|| StrEqual(sMap, "l4d_smalltown03_ranchhouse", false) //churchguy door fix
	|| StrEqual(sMap, "tutorial_standards", false)  //Official hidden
	|| StrEqual(sMap, "l4d_vs_smalltown03_ranchhouse", false)) //churchguy door fix
	{
	return true;
	}
	return false;
	}


bool HasAnyTankAlive()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (!IsPlayerTank(client))
            continue;

        if (IsPlayerIncapacitated(client))
            continue;

        return true;
    }

    return false;
}

bool IsPlayerTank(int client)
{
    if (GetClientTeam(client) != TEAM_INFECTED)
        return false;

    if (!IsPlayerAlive(client))
        return false;

    if (IsPlayerGhost(client))
        return false;

    if (GetZombieClass(client) != g_iTankClass)
        return false;

    return true;
}

int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

bool IsPlayerGhost(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isGhost") == 1);
}

bool IsPlayerIncapacitated(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1);
}

bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}
