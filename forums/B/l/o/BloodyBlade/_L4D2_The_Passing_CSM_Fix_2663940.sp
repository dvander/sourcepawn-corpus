#pragma semicolon 1;
#pragma newdecls required;
/* Includes */
#include <sourcemod>
#include <sdkhooks>
#include <sdktools_functions>
#include <sdktools_entoutput>
#include <sdktools_entinput>

#define PLUGIN_VERSION "2.0"

/* Plugin Information */
public Plugin myinfo = 
{
	name = "[L4D2] CSM The Passing Fix", 
	author = "DeathChaos25, Merudo", 
	description = "Fixes an Issue with The Passing campaign where map causes players who are L4D1 survivors to be teleported or kicked", 
	url = ""
}

/* Globals */
static bool IsThePassing1 = false;
static bool IsThePassing3 = false;
static bool IsThePassing  = false;
static bool IsVersus;

static bool Restore[MAXPLAYERS + 1]  = false;
static int  Survivor[MAXPLAYERS + 1] = -1;

/* Plugin Functions */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead 2 Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("round_freeze_end", Event_FreezeEnd);
	HookEvent("door_unlocked", Event_DoorUnlock, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	CreateConVar("l4d2_csm_passing_fix", PLUGIN_VERSION, "Current Version of CSM The Passing Fix", FCVAR_NOTIFY);	
}

char survivor_only_modes[23][] =
{
	"coop", "realism", "survival",  "m60s", "hardcore", "l4d1coop",
	"mutation1",	"mutation2",	"mutation3",	"mutation4",
	"mutation5",	"mutation6",	"mutation7",	"mutation8",
	"mutation9",	"mutation10",	"mutation16",	"mutation17", "mutation20",
	"community1",	"community2",	"community4",	"community5"
};

// ------------------------------------------------------------------------
// Returns true if players in team infected are allowed
// ------------------------------------------------------------------------
bool AreInfectedAllowed()
{	
	char gameMode[16];
	FindConVar("mp_gamemode").GetString(gameMode, sizeof(gameMode));
	
	for (int i = 0; i < sizeof(survivor_only_modes); i++)
	{
		if (StrEqual(gameMode, survivor_only_modes[i], false))
		{
			return false;
		}
	}
	return true;   // includes versus, realism versus, scavenge, & some mutations
}

// ------------------------------------------------------------------------
// Store information about game play mode, precache some models, & reset info
// ------------------------------------------------------------------------
public void OnMapStart()
{
	char CurrentMap[100];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	IsThePassing1 = StrEqual(CurrentMap, "c6m1_riverbank"); 
	IsThePassing3 = StrEqual(CurrentMap, "c6m3_port");
	IsThePassing  = IsThePassing1 || IsThePassing3;
	IsVersus      = AreInfectedAllowed();
	
	// Precache models that are known to cause precache errors on The Passing 1
	if (IsThePassing1)
	{
		if (!IsModelPrecached("models/infected/witch.mdl")) PrecacheModel("models/infected/witch.mdl");
		if (!IsModelPrecached("models/infected/witch_bride.mdl")) PrecacheModel("models/infected/witch_bride.mdl");
	}
	
	// Reset fix info
	for (int i = 1; i <= MaxClients; i++)
	{
		Restore[i] = false;
		Survivor[i]     = 0;
	}
}

public void Event_FreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	int Entity;
	// --------------------------------------------------------
	// On c6m1, Francis gets kicked at the shop early on the map
	// This removes the entity that causes this
	// --------------------------------------------------------
	if (IsThePassing1)
	{
		Entity = Entity_FindByHammerId(765976);     // Remove Entity that kills Francis in first shop
		if (Entity != INVALID_ENT_REFERENCE) 	RemoveEdict(Entity);
	}
}

public void Event_DoorUnlock(Event event, const char[] name, bool dontBroadcast)
{
	int Entity;
	// --------------------------------------------------------
	// On c6m3, L4D1 survivors get respawned and teleported around
	// This either removes the entities (versus) or temporary change survivors
	// --------------------------------------------------------	
	if (IsThePassing3)
	{
		Entity = Entity_FindByHammerId(397334); // teleport triggered by the stairs
		if (Entity != INVALID_ENT_REFERENCE &&  IsVersus) AcceptEntityInput(Entity, "Kill"); 
		if (Entity != INVALID_ENT_REFERENCE && !IsVersus) HookSingleEntityOutput(Entity, "OnTrigger", Event_Trigger, true);
		
		Entity = Entity_FindByHammerId(1105713); // teleport triggered by the elevator
		if (Entity != INVALID_ENT_REFERENCE &&  IsVersus) AcceptEntityInput(Entity, "Kill");  //RemoveEdict(Entity); 
		if (Entity != INVALID_ENT_REFERENCE && !IsVersus) HookSingleEntityOutput(Entity, "OnTrigger", Event_Trigger, true);
	}
}

// --------------------------------------------------------
// On c6m3 coop, this changes L4D1 survivors for .1 sec so they don't get teleported away
// --------------------------------------------------------	
public void Event_Trigger(const char[] output, int caller, int activator, float delay)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		ChangeSurvivor(i);
		if (IsClientInGame(i)) CreateTimer(0.1, timer_RestoreSurvivor, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
	}
}

// --------------------------------------------------------
// On c6m1 (coop & versus), there is a player kick/teleport for L4D1 survivors if survivors lose
// This turns L4D1 survivors into L4D2 temporarily to avoid the bug
// It happens before Event_RoundEnd, so this needs to happen at death of last survivor
// On Versus, restore is on round end, on coop, its when survivor respawn
// --------------------------------------------------------
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (IsThePassing1 && CountSurvivorsLeft() == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			ChangeSurvivor(i, true);
			if (Restore[i] && !IsVersus) PrintHintText(i, "Your survivor has been changed to prevent a bug on this map.\nYour character will be restored once you respawn!");
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// --------------------------------------------------------
	// On c6m3 (coop), there is a player kick/teleport for L4D1 survivors if survivors lose
	// This turns L4D1 survivors into L4D2 temporarily to avoid the bug
	// --------------------------------------------------------
	if (IsThePassing3 && !IsVersus)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			ChangeSurvivor(i, true);
			if (Restore[i]) PrintHintText(i, "Your survivor has been changed to prevent a bug on this map.\nYour character will be restored once you respawn!");
		}
	}
	
	// --------------------------------------------------------
	// On c6m1 (versus), we can restore the survivor now
	// --------------------------------------------------------	
	if (IsThePassing1 && IsVersus)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			RestoreSurvivor(i);
		}
	}
}

// --------------------------------------
// If need restore at spawn, do it
// --------------------------------------
public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (IsThePassing && !IsVersus) CreateTimer(3.0, timer_RestoreSurvivor, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
}

// --------------------------------------
// Attempt to restore character
// --------------------------------------
public Action timer_RestoreSurvivor(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	RestoreSurvivor(client);
}

void ChangeSurvivor(int client, bool Bill = false)
{
	Restore[client] = false;
	Survivor[client] = 0;

	if (IsSurvivor(client))
	{
		int Prop = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if ((Prop == 4 && Bill) || Prop == 5 || Prop == 6 || Prop == 7)
		{
			Survivor[client] = Prop;
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
			Restore[client] = true;
		}
	}
}

char survivor_names[8][] = {"Nick", "Rochelle", "Coach", "Ellis", "Bill", "Zoey", "Francis", "Louis"};
void RestoreSurvivor(int client)
{
	if (IsSurvivor(client) && Restore[client])
	{
		if (Survivor[client] == 4 || Survivor[client] == 5 || Survivor[client] == 6 || Survivor[client] == 7 )
		{
			if (IsFakeClient(client))  SetClientInfo(client, "name", survivor_names[Survivor[client]]);		
			SetEntProp(client, Prop_Send, "m_survivorCharacter", Survivor[client]);
		}
	}
	Restore[client] = false;
	Survivor[client] = 0;
}

bool IsSurvivor(int client)
{
	return(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

int CountSurvivorsLeft()
{
	int count = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			count = count + 1;
		}
	}
	return count;
}

int Entity_FindByHammerId(int hammerId, const char[] class = "")
{
    if (class[0] == '\0')
	{
        // Hack: Double the limit to gets none-networked entities too.
        int realMaxEntities = GetMaxEntities() * 2;
        for (int entity=0; entity < realMaxEntities; entity++)
		{                
            if (!IsValidEntity(entity)) continue;
            if (Entity_GetHammerId(entity) == hammerId) return entity;
        }
	}
    else
    {
        int entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, class)) != INVALID_ENT_REFERENCE)
		{            
                if (Entity_GetHammerId(entity) == hammerId) return entity;
        }
	}
    return INVALID_ENT_REFERENCE;
}

int Entity_GetHammerId(int entity)
{       
    return GetEntProp(entity, Prop_Data, "m_iHammerID");
}