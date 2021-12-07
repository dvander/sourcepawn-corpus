#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME_SHORT "Finale Finish Godmode"
#define PLUGIN_NAME "[L4D2] Finale Finish Godmode"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Give godmode to survivors upon finale vehicle leaving."
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL ""

#define CVAR_INCAPMAX "survivor_max_incapacitated_count"

//static bool g_isSequel = false;
//static bool isTheSacrifice = false;
static bool hasFinaleEnded = false;

ConVar version_cvar;
//ConVar releaseFromPos;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead)
	{
		//g_isSequel = false;
		return APLRes_Success;
	}
	else if(GetEngineVersion() == Engine_Left4Dead2)
	{
		//g_isSequel = true;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	char cvar_str[500];
	Format(cvar_str, sizeof(cvar_str), "%s plugin version.", PLUGIN_NAME_SHORT);
	version_cvar = CreateConVar("sm_finalefinish_godmode_version", PLUGIN_VERSION, cvar_str, 0|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	//releaseFromPos = CreateConVar("sm_finalefinish_start_releasefrompos", "1.0", "Release survivors from position on start?", FCVAR_ARCHIVE, true, 0.0, true, 1.0);

	HookEvent("finale_vehicle_leaving", finale_vehicle_leaving, EventHookMode_Pre);
}

public void OnMapStart()
{
	char CurrentMap[100];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	//isTheSacrifice = StrEqual(CurrentMap, "c7m3_port", false);
	hasFinaleEnded = false;
	
	if (StrEqual(CurrentMap, "c7m3_port", false))
	{
		int check_if_extra = FindEntityByClassname(-1, "info_survivor_position");
		bool has_Found_Extra = false;
		
		for (int i = 1; i <= 8; i++) {
			if (IsValidEntity(check_if_extra))
			{
				char name[128];
				GetEntPropString(check_if_extra, Prop_Data, "m_iName", name, sizeof(name));
				if (StrEqual(name, "survivor_positions_extra", false))
				{ has_Found_Extra = true; break; }
				else
				{
					int temp = FindEntityByClassname(check_if_extra, "info_survivor_position");
					if (!IsValidEntity(temp)) break;
					check_if_extra = temp;
				}
			}
			else
			{ break; }
		}
		
		if (!has_Found_Extra)
		{
			for (int i = 1; i <= 4; i++) {
				//PrintToChatAll("yes");
				//0 370 330
				int rescue_pos = CreateEntityByName("info_survivor_position");
				TeleportEntity(rescue_pos, view_as<float>({0.0, 370.0, 330.0}), NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValue(rescue_pos, "targetname", "survivor_positions_extra");
				DispatchSpawn(rescue_pos);
				ActivateEntity(rescue_pos);
				/*if (i >= 4)
				{
					
				}*/
			}
		}
	}
}

void finale_vehicle_leaving(Handle event, const char[] name, bool dontBroadcast)
{
	if (hasFinaleEnded) return;
	hasFinaleEnded = true;
	
	int finale_ent = FindEntityByClassname(-1, "trigger_finale");
	int finale_ent_dlc3 = FindEntityByClassname(-1, "trigger_finale_dlc3");
	if (!IsValidEntity(finale_ent) || IsValidEntity(finale_ent_dlc3)) return;
	
	bool isSacrificeFinale = view_as<bool>(GetEntProp(finale_ent, Prop_Data, "m_bIsSacrificeFinale"));
	if (isSacrificeFinale) return;
	
	for (int loopclient = 1; loopclient <= MAXPLAYERS; loopclient++) {
		if (!IsValidClient(loopclient)) continue;
		if (!IsSurvivor(loopclient) || !IsPlayerAlive(loopclient)) continue;
		int takedamage = GetEntProp(loopclient, Prop_Data, "m_takedamage");
		if (takedamage <= 0) continue;
		SetEntProp(loopclient, Prop_Send, "m_currentReviveCount", GetConVarInt(FindConVar(CVAR_INCAPMAX)));
		SetEntProp(loopclient, Prop_Data, "m_takedamage", 0);
	}
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (!IsValidEntity(client)) return false;
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) == 2) return true;
	return false;
}