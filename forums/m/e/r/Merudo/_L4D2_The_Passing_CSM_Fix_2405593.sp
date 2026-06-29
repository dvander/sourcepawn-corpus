/* Includes */
#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1;
#pragma newdecls required;

#define PLUGIN_VERSION "1.2"

/* Plugin Information */
public Plugin myinfo =  {
	name = "[L4D2] CSM The Passing Fix", 
	author = "DeathChaos25, Merudo", 
	description = "Fixes an Issue with The Passing campaign where map restarts causes players who are L4D1 survivors to teleport to the bridge", 
	url = ""
}

/* Globals */
static bool IsThePassing1 = false;
static bool IsThePassing3 = false;
static bool IsThePassing  = false;
static bool IsVersus;

static bool FixNeeded[MAXPLAYERS + 1]    = false;
static bool SpawnRestore[MAXPLAYERS + 1] = false;
static int  Survivor[MAXPLAYERS + 1]     = -1;

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

char survivor_only_modes[23][] =
{
	"coop", "realism", "survival",
	"m60s", "hardcore", "l4d1coop",
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

public void OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	CreateTimer(1.0, CSMFix, _, TIMER_REPEAT);
	CreateConVar("l4d2_csm_passing_fix", PLUGIN_VERSION, "Current Version of CSM The Passing Fix", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);	
}

public void OnMapStart()
{
	char CurrentMap[100];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	IsThePassing1 = StrEqual(CurrentMap, "c6m1_riverbank"); 
	IsThePassing3 = StrEqual(CurrentMap, "c6m3_port");
	IsThePassing  = IsThePassing1 || IsThePassing3;
	IsVersus      = AreInfectedAllowed();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		SpawnRestore[i] = false;
		FixNeeded[i]    = IsThePassing3;
		Survivor[i]     = 0;
	}
}

// --------------------------------------------------------
// On c6m3 (coop), there is a player kick/teleport for L4D1 survivors if survivors lose
// This turns L4D1 survivors into L4D2 temporarily to avoid the bug
// --------------------------------------------------------
public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if (IsThePassing3 && !IsVersus)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			SpawnRestore[i] = false;
			FixNeeded[i]    = true;
			Survivor[i]     = 0;
			ChangeSurvivor(i);
		}
	}
}

// --------------------------------------------------------
// On c6m1 (coop & versus), there is a player kick/teleport for L4D1 survivors if survivors lose
// This turns L4D1 survivors into L4D2 temporarily to avoid the bug
// It happens before Event_RoundEnd, so this needs to happen at death of last survivor
// --------------------------------------------------------
public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if (IsThePassing1 && CountSurvivorsLeft() == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			SpawnRestore[i] = true;
			FixNeeded[i]    = false;
			Survivor[i]     = 0;
			ChangeSurvivor(i);
		}
	}
}

public void OnClientConnected(int client)
{
	SpawnRestore[client] = false;
	FixNeeded[client]    = IsThePassing3;
	Survivor[client]     = 0;
}

// --------------------------------------------------------
// On c6m1 & c6m3, L4D1 survivors are teleported/kicked at some points on the map
// This turns L4D1 survivors into L4D2 temporarily to avoid the bug
// --------------------------------------------------------
public Action CSMFix(Handle timer)
{
	if (!IsServerProcessing() || !IsThePassing)
	{
		return Plugin_Continue;
	}

	int Stage = IsThePassing3 ? GetStagePassing3() : GetStagePassing1();
	
	// If passed the bug point 
	if (Stage == 2)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsSurvivor(client) && IsPlayerAlive(client) && FixNeeded[client])
			{
				RestoreSurvivor(client, IsThePassing1);
				FixNeeded[client] = false;
			}
		}
	}
	else if (Stage == 1)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsSurvivor(client) && IsPlayerAlive(client))
			{
				if (FixNeeded[client] || IsThePassing1 )
				{
					ChangeSurvivor(client, IsThePassing1);
					FixNeeded[client] = true;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

// --------------------------------------
// If need restore at spawn, do it
// --------------------------------------
public Action PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsThePassing1 && SpawnRestore[client])
	{
		CreateTimer(3.0, timer_RestoreSurvivor, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action timer_RestoreSurvivor(Handle timer, int client)
{
	if (SpawnRestore[client])
	{
		SpawnRestore[client] = false;
		RestoreSurvivor(client);
	}
}

void ChangeSurvivor(int client, bool FrancisZoeyOnly = false)
{
	if (IsSurvivor(client))
	{
		int Prop = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		
		if (Prop == 5 || Prop == 6 || (Prop == 7 && !FrancisZoeyOnly))
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
			Survivor[client] = Prop;
			PrintHintText(client, "Your survivor has been changed to prevent a bug on this map.\nYour character will be restored once the bug has been prevented!");
		}
	}
}

void RestoreSurvivor(int client, bool FrancisZoeyOnly = false)
{
	if (IsSurvivor(client))
	{
		if (Survivor[client] == 5 || Survivor[client] == 6 || (Survivor[client] == 7 && !FrancisZoeyOnly))
		{
			SetEntProp(client, Prop_Send, "m_survivorCharacter", Survivor[client]);
			Survivor[client] = 0;
			PrintHintText(client, "The Bug has been prevented.\nYour survivor character has been restored!");
		}
	}
}

bool IsSurvivor(int client)
{
	return(client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

int GetStagePassing3()  
{
	float Origin[3]; float Button[3]; float Stairs[3];
	// setpos_exact -695.448181 -573.218567 0.461658;
	Button[0] = -695.448181;
	Button[1] = -573.218567;
	Button[2] = 0.461658;
	
	if (!IsVersus)  // Bug happens around the stairs + elevator in coop
	{
		Stairs[0] = -2015.213989;
		Stairs[1] = -723.742432;
		Stairs[2] = -191.968750;
	} else			// Bug happens in the elevator for versus
	{
		Stairs[0] = -774.789367;
		Stairs[1] = -575.831359;
		Stairs[2] =  320.031250;
	}	
	
	float minDistance2 = 400.0;
	float distance     = 400.0;
	float distance2    = 400.0;
 
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", Origin);
			distance  = GetVectorDistance(Button, Origin);
			distance2 = GetVectorDistance(Stairs, Origin);
			
			if (distance  < 150) break;
			if (distance2 < minDistance2) minDistance2 = distance2; 
		}
	}
	
	if (distance < 150) return 2;
	else if (minDistance2 < 200) return 1;
	return 0;
}

int GetStagePassing1()
{
	float Origin[3]; float Bottom[3]; float Upstairs[3];

	Bottom[0]	= 3452.633544;
	Bottom[1]	= 2193.183593;
	Bottom[2]	=   56.031250;

	Upstairs[0] =  3631.158203;
	Upstairs[1] =  2188.947753;
	Upstairs[2] =  207.190124;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", Origin);
			
			if (GetVectorDistance(Bottom, Origin) < 400.0 || GetVectorDistance(Upstairs, Origin) < 400.0 )
			{
				return 1;
			}
		}
	}
	return 2;
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
