#include <multicolors>
#include <sourcemod>
#include <left4dhooks>
#include <sdktools>
//#pragma newdecls required;
#pragma tabsize 0;

#define PLUGIN_VERSION "1.0h"

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3
#define TANK			8
#define LINUX // Delete this if your server based on Windows OS

int game_difficulty = 1; // default difficulty is Normal (1)
bool VomitedSurvivor[MAXPLAYERS+1]; // Vomit status of Survivors
ConVar l4d2_sbt_high_difficulties_finish_off_incapacitated, l4d2_sbt_targets_vomited_survivor;

public Plugin myinfo = 
{
	name = "[L4D2] Smart Bot Tank",
	author = "B[R]UTUS, BHaType",
	description = "Bot-Tanks will target a nearest survivors. They can ignoring vomited players and minigunners if they are further than nearest target.",
	version = PLUGIN_VERSION,
	url = "https://vk.com/bru7us"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
    EngineVersion Engine = GetEngineVersion();

    if (Engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 2."); 
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

ArrayList g_BytesSaved;
Address g_iFixOffset;
int g_iFixCount, g_iFixMatch;
public void OnPluginStart()
{
	HookEvent("difficulty_changed", PlayerDifficultyChanged_Event);
	HookEvent("player_now_it", PlayerVomited_Event);
    HookEvent("player_no_longer_it", PlayerUnVomited_Event);
	HookEvent("mission_lost", ClearVomitStatus_Event); //Clear Vomit status of survivors
	HookEvent("map_transition", ClearVomitStatus_Event); //Clear Vomit status of survivors
	HookEvent("survivor_rescued", ClearVomitStatus_Event); //Clear Vomit status of survivors
	HookEvent("player_death", PlayerDeath_Event); //Clear Vomit status of dead survivor

	l4d2_sbt_high_difficulties_finish_off_incapacitated = CreateConVar("l4d2_sbt_high_difficulties_finish_off_incapacitated", "1", "Enable/Disable finishing off survivors who gets incapacitated on Hard/Expert difficulties", 0);
	l4d2_sbt_targets_vomited_survivor = CreateConVar("l4d2_sbt_targets_vomited_survivor", "1", "Enable/Disable targeting survivors who gets vomited", 0);
	AutoExecConfig(true, "l4d2_smart_bot_tank");

	GetCvars();
	l4d2_sbt_high_difficulties_finish_off_incapacitated.AddChangeHook(ConVarChanged_Cvars);
	l4d2_sbt_targets_vomited_survivor.AddChangeHook(ConVarChanged_Cvars);


    GameData hGameData = new GameData("l4d2_smart_bot_tank");
	if( hGameData == null ) SetFailState("Failed to load \"l4d2_smart_bot_tank.txt\" gamedata.");

	// =========================
	// PATCH - Remove ignoring players using mini gun
	// =========================
	g_iFixOffset = GameConfGetAddress(hGameData, "TankAttack::Update");
	if( !g_iFixOffset ) SetFailState("Failed to find \"TankAttack::Update\" signature.");

	int offs = GameConfGetOffset(hGameData, "TankAttack__Update_Offset");
	if( offs == -1 ) SetFailState("Failed to load \"TankAttack__Update_Offset\" offset.");

	g_iFixOffset += view_as<Address>(offs);

	g_iFixCount = GameConfGetOffset(hGameData, "TankAttack__Update_Count");
	if( g_iFixCount == -1 ) SetFailState("Failed to load \"TankAttack__Update_Count\" offset.");

	g_iFixMatch = GameConfGetOffset(hGameData, "TankAttack__Update_Match");
	if( g_iFixMatch == -1 ) SetFailState("Failed to load \"TankAttack__Update_Match\" offset.");

	g_BytesSaved = new ArrayList();

	for( int i = 0; i < g_iFixCount; i++ )
	{
		g_BytesSaved.Push(LoadFromAddress(g_iFixOffset + view_as<Address>(i), NumberType_Int8));
	}

	if( g_BytesSaved.Get(0) != g_iFixMatch ) SetFailState("Failed to load, byte mis-match @ %d (0x%02X != 0x%02X)", offs, g_BytesSaved.Get(0), g_iFixMatch);

	delete hGameData;

	PatchAddress(true);
	//--------------------------------------------------------------------------------------------------------------------------------
}

public void OnPluginEnd()
{
	PatchAddress(false);
}

//-------------------------------Cvars-------------------------------

public void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

bool g_bCvarIncapacitated, g_bCvarVomited;
void GetCvars()
{
    g_bCvarIncapacitated = l4d2_sbt_high_difficulties_finish_off_incapacitated.BoolValue;
    g_bCvarVomited = l4d2_sbt_targets_vomited_survivor.BoolValue;
}

public void ClearVomitStatus()
{
	for (int i = 1; i <= MaxClients; i++)
		VomitedSurvivor[i] = false;
}

public void OnMapStart()
{
	ClearVomitStatus();
}

public void PlayerDifficultyChanged_Event(Event event, const char[] name, bool dontBroadcast)
{
	int newDifficulty = GetEventInt(event, "newDifficulty");

	switch (newDifficulty)
    {
        case 0:
			game_difficulty = 0; // Easy

		case 1:
			game_difficulty = 1; // Normal

		case 2:
			game_difficulty = 2; // Hard
		
		case 3:
			game_difficulty = 3; // Expert
	}
}

public void PlayerVomited_Event(Event event, const char[] name, bool dontBroadcast)
{
	int vomited = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClientIndex(vomited))
	if (IsClientInGame(vomited))
    if (GetClientTeam(vomited) == TEAM_SURVIVOR)
    if (IsPlayerAlive(vomited))
		VomitedSurvivor[vomited] = true;
}

public void PlayerUnVomited_Event(Event event, const char[] name, bool dontBroadcast) 
{
	int vomited = GetClientOfUserId(GetEventInt(event, "userid")); 

	if (IsValidClientIndex(vomited))
	if (IsClientInGame(vomited))
    if (GetClientTeam(vomited) == TEAM_SURVIVOR)
    if (IsPlayerAlive(vomited))
		VomitedSurvivor[vomited] = false;
}

public void ClearVomitStatus_Event(Event event, const char[] name, bool dontBroadcast)
{
	ClearVomitStatus();
}

public void PlayerDeath_Event(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClientIndex(userid))
	if (IsClientInGame(userid))
    if (GetClientTeam(userid) == TEAM_SURVIVOR)
    if (IsPlayerAlive(userid))
		VomitedSurvivor[userid] = false;
}

public Action L4D2_OnChooseVictim(int specialInfected, int &curTarget)
{	
	if (!IsClientTank(specialInfected)) // If Special Infected isn't a Tank...
		return Plugin_Continue;

	if (!IsValidClientAlive(curTarget)) // If Client isn't valid or isn't alive...
		return Plugin_Continue;
	
    curTarget = FindNearestSurvivor(specialInfected); // Find the nearest target for Tank and changing active target to nearest target (survivor).
    return Plugin_Changed;
}

public int FindNearestSurvivor(int Finder)
{
    float NearestSurvivor = 0.0;
    int NearestClient = 0;

	int Targets[MAXPLAYERS+1];
	int Counter = 0;

	if (!IsValidClientAlive(Finder))
		return 0;
	
	float fPos1[3], fPos2[3];
	GetClientAbsOrigin(Finder, fPos1);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        if (GetClientTeam(i) == TEAM_SURVIVOR)
        if (IsPlayerAlive(i))
        {
			if (g_bCvarIncapacitated && !g_bCvarVomited) // If the only Incap Cvar is True...
			{
				if (game_difficulty == 2 || game_difficulty == 3) // If difficulty "Hard" or "Expert"...
				{
					if (GetEntProp(i, Prop_Send, "m_isIncapacitated") == 1) // Tank specially finish off the incapacitated survivor because he can do it fast.
					{
						Counter++;
						Targets[Counter] = i; // Add to targets this survivor
					}
					else
					{
						GetClientAbsOrigin(i, fPos2);

						if (NearestSurvivor == 0.0)
						{
							NearestSurvivor = GetVectorDistance(fPos1, fPos2);
							NearestClient = i;
						}

						if (NearestSurvivor > 0.0)
						{
							if (NearestSurvivor > GetVectorDistance(fPos1, fPos2))
							{
								NearestSurvivor = GetVectorDistance(fPos1, fPos2)
								NearestClient = i;
							}
						}
					}
				}
				else
				{
					GetClientAbsOrigin(i, fPos2);

					if (NearestSurvivor == 0.0)
					{
						NearestSurvivor = GetVectorDistance(fPos1, fPos2);
						NearestClient = i;
					}

					if (NearestSurvivor > 0.0)
					{
						if (NearestSurvivor > GetVectorDistance(fPos1, fPos2))
						{
							NearestSurvivor = GetVectorDistance(fPos1, fPos2)
							NearestClient = i;
						}
					}
				}
			}

			if (!g_bCvarIncapacitated && g_bCvarVomited) // If the only Vomit Cvar is True...
			{
				if (VomitedSurvivor[i]) // Tank specially targeting and finish off the vomited survivor.
				{
					Counter++;
					Targets[Counter] = i; // Add to targets this survivor
				}
				else
				{
					GetClientAbsOrigin(i, fPos2);

					if (NearestSurvivor == 0.0)
					{
						NearestSurvivor = GetVectorDistance(fPos1, fPos2);
						NearestClient = i;
					}

					if (NearestSurvivor > 0.0)
					{
						if (NearestSurvivor > GetVectorDistance(fPos1, fPos2))
						{
							NearestSurvivor = GetVectorDistance(fPos1, fPos2)
							NearestClient = i;
						}
					}
				}
			}

			if (g_bCvarIncapacitated && g_bCvarVomited) // If two Cvars is True
			{
				if (game_difficulty == 2 || game_difficulty == 3) // If difficulty "Hard" or "Expert"...
				{
					if (GetEntProp(i, Prop_Send, "m_isIncapacitated") == 1)
					{
						Counter++;
						Targets[Counter] = i;
						//CPrintToChatAll("Added {blue}%N{default} to {green}INCAP{default} targets...", Targets[Counter]);
					}

					if (VomitedSurvivor[i])
					{
						Counter++;
						Targets[Counter] = i;
						//CPrintToChatAll("Added {blue}%N{default} to {green}VOMIT{default} targets...", Targets[Counter]);
					}

					if (Counter == 0)
					{
						GetClientAbsOrigin(i, fPos2);

						if (NearestSurvivor == 0.0)
						{
							NearestSurvivor = GetVectorDistance(fPos1, fPos2);
							NearestClient = i;
						}

						if (NearestSurvivor > 0.0)
						{
							if (NearestSurvivor > GetVectorDistance(fPos1, fPos2))
							{
								NearestSurvivor = GetVectorDistance(fPos1, fPos2)
								NearestClient = i;
							}
						}
					}
				}
				else
				{
					if (VomitedSurvivor[i]) 
					{
						Counter++;
						Targets[Counter] = i;
					}
					else
					{
						if (GetEntProp(i, Prop_Send, "m_isIncapacitated") == 1)
							continue;

						GetClientAbsOrigin(i, fPos2);

						if (NearestSurvivor == 0.0)
						{
							NearestSurvivor = GetVectorDistance(fPos1, fPos2);
							NearestClient = i;
						}

						if (NearestSurvivor > 0.0)
						{
							if (NearestSurvivor > GetVectorDistance(fPos1, fPos2))
							{
								NearestSurvivor = GetVectorDistance(fPos1, fPos2)
								NearestClient = i;
							}
						}
					}
				}
			}

			if (!g_bCvarIncapacitated && !g_bCvarVomited) // If all Cvars is False
			{
				if (GetEntProp(i, Prop_Send, "m_isIncapacitated") == 1)
					continue; // Tank ignores the incapacitated survivor because he will be killing him very long and lost much health.

				GetClientAbsOrigin(i, fPos2);

				if (NearestSurvivor == 0.0)
				{
					NearestSurvivor = GetVectorDistance(fPos1, fPos2);
					NearestClient = i;
				}

				if (NearestSurvivor > 0.0)
				{
					if (NearestSurvivor > GetVectorDistance(fPos1, fPos2))
					{
						NearestSurvivor = GetVectorDistance(fPos1, fPos2)
						NearestClient = i;
					}
				}
			}
		}
    }
	
	if (g_bCvarIncapacitated || g_bCvarVomited) // If one of Cvars is True...
	{
		if (Counter > 1) // If Vomited/Incapacitated survivors more than 1...
			return FindNearestSurvivorSpecial(Targets, Finder, Counter);
		if (Counter == 1) // If the only Vomited/Incapacitated survivor...
			return Targets[1];
	}

	return NearestClient; // return nearest survivor's ID if no Vomited/Incapacitated survivors...
}

public int FindNearestSurvivorSpecial(int Targets[MAXPLAYERS+1], int Finder, int TargetCount) // Finding the nearest survivors between incapacitated and vomited if it need...
{
	float NearestSurvivor = 0.0;
    int NearestClient = 0;

	if (!IsValidClientAlive(Finder))
		return 0;
	
	float fPos1[3], fPos2[3];
	GetClientAbsOrigin(Finder, fPos1);

	for (int i = 1; i <= TargetCount; i++)
    {
        if (IsClientInGame(Targets[i]))
        if (GetClientTeam(Targets[i]) == TEAM_SURVIVOR)
        if (IsPlayerAlive(Targets[i]))
        {
			GetClientAbsOrigin(Targets[i], fPos2);

			if (NearestSurvivor == 0.0)
			{
				NearestSurvivor = GetVectorDistance(fPos1, fPos2);
				NearestClient = Targets[i];
			}

			if (NearestSurvivor > 0.0)
			{
				if (NearestSurvivor > GetVectorDistance(fPos1, fPos2))
				{
					NearestSurvivor = GetVectorDistance(fPos1, fPos2)
					NearestClient = Targets[i];
				}
			}
		}
	}

	return NearestClient;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	if (IsClientInGame(client))
		return 1;
	
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index > 0 && index <= MaxClients)
		return 1;

	return 0;
}

stock bool IsValidClientAlive(int client)
{
	if (!IsValidClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
	
	return true;
}

stock bool IsClientTank(int client)
{
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == TANK)
		return true;
	
	return false;
}

public void OnClientDisconnect(client)
{
	if (IsValidClientIndex(client))
	if (IsClientInGame(client))
    if (GetClientTeam(client) == TEAM_SURVIVOR)
    if (IsPlayerAlive(client))
		VomitedSurvivor[client] = false;
}

void PatchAddress(bool patch)
{
	static bool patched;

	if( !patched && patch )
	{
		patched = true;

		for( int i = 0; i < g_iFixCount; i++ )
		{
			StoreToAddress(g_iFixOffset + view_as<Address>(i), 0x90, NumberType_Int8);
		}
	}
	else if( patched && !patch )
	{
		patched = false;

		for( int i = 0; i < g_iFixCount; i++ )
		{
			StoreToAddress(g_iFixOffset + view_as<Address>(i), g_BytesSaved.Get(i), NumberType_Int8);
		}
	}
}