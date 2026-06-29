#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

#define MAX_SPAWNPOINTS 64
#define PLUGIN_VERSION "1.3.2"
//enum
//{
	//Team_Allies = 0,
	//Team_Axis
//}

enum struct ConVars
{
	Handle Enabled;
	Handle MaxDistance;
	Handle DisplayMessage;
}

ConVars g_iConVar;

new g_iOffset_Origin;
new g_iOffset_StunDuration;

new g_iSpawnCount[2];

static const String:g_szGrenades[][] =
{
	"frag_us",
	"frag_ger",
	"riflegren_us",
	"riflegren_ger"
};

static const String:g_szSpawnPoints[][] =
{
	"info_player_allies",
	"info_player_axis"
};

new Float:g_vecSpawnPositions[2][MAX_SPAWNPOINTS][3];

public Plugin:myinfo =
{
	name = "Grenade Spawn Protection",
	author = "Andersso modif Micmacx",
	description = "Blocks damage from grenades in spawn",
	version = PLUGIN_VERSION,
	url = "http://www.dodsourceplugins.net/"
};

public OnPluginStart()
{
	LoadTranslations("grenadeprotection.phrases");
	
	CreateConVar("sm_grenadeprotection", PLUGIN_VERSION, "Grenade Spawn Protection Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_iConVar.Enabled = CreateConVar("sm_grenadeprotection_enabled", "1", "Enable/Disable Grenade Protection.");
	g_iConVar.MaxDistance = CreateConVar("sm_grenadeprotection_maxdistance", "500", "Maximum distance a player can be away from spawn without taking any damage from grenades.");
	g_iConVar.DisplayMessage = CreateConVar("sm_grenadeprotection_displaymessage", "1", "Enable/Disable showing text message to attacker.");
	
	if ((g_iOffset_Origin = FindSendPropInfo("CBaseEntity", "m_vecOrigin")) == -1)
	{
		SetFailState("Fatal Error: Unable to find prop offset \"CBaseEntity::m_vecOrigin\"!");
	}
	
	if ((g_iOffset_StunDuration = FindSendPropInfo("CDODPlayer", "m_flStunDuration")) == -1)
	{
		SetFailState("Fatal Error: Unable to find prop offset \"CDODPlayer::m_flStunDuration\"!");
	}
	AutoExecConfig(true, "dod_grenadeprotection", "dod_grenadeprotection");
}

public OnMapStart()
{
	new iEntity;
	
	for (new i = 0; i < sizeof(g_szSpawnPoints); i++)
	{
		g_iSpawnCount[i] = 0;
		
		iEntity = -1;
		
		while ((iEntity = FindEntityByClassname(iEntity, g_szSpawnPoints[i])) != -1)
		{
			if (g_iSpawnCount[i] < MAX_SPAWNPOINTS)
			{
				GetEntDataVector(iEntity, g_iOffset_Origin, g_vecSpawnPositions[i][g_iSpawnCount[i]++]);
			}
		}
	}
}

public OnClientPutInServer(iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(iClient, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType)
{
	if (GetConVarBool(g_iConVar.Enabled))
	{
		if (iClient != iAttacker && iInflictor > MaxClients && IsValidEdict(iInflictor) && iDamageType & DMG_BLAST)
		{
			decl String:szInflictorName[64];
			GetEdictClassname(iInflictor, szInflictorName, sizeof(szInflictorName));
			
			if (ReplaceString(szInflictorName, sizeof(szInflictorName), "grenade_", NULL_STRING) >= 1)
			{
				for (new i = 0; i < sizeof(g_szGrenades); i++)
				{
					if (StrEqual(szInflictorName, g_szGrenades[i]) && IsPlayerNearSpawn(iClient))
					{
						if (GetConVarBool(g_iConVar.DisplayMessage) && IsClientInGame(iAttacker))
						{
							PrintCenterText(iAttacker, "%t", "Attacker Message");
						}
						
						SetEntDataFloat(iClient, g_iOffset_StunDuration, 0.0);
						
						return Plugin_Handled;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

bool:IsPlayerNearSpawn(iClient)
{
	decl Float:vecOrigin[3];
	GetClientAbsOrigin(iClient, vecOrigin);
	
	new iTeam = GetClientTeam(iClient) - 2;
	
	for (new i = 0; i < g_iSpawnCount[iTeam]; i++)
	{
		if (GetVectorDistance(g_vecSpawnPositions[iTeam][i], vecOrigin) <= GetConVarFloat(g_iConVar.MaxDistance))
		{
			return true;
		}
	}
	
	return false;
}
