#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <smlib>

#define VERSION 		"0.0.2"

new Handle:g_hCvarMode = INVALID_HANDLE;
new Handle:g_hCvarEnabled = INVALID_HANDLE;

new bool:g_bEnabled;
new g_iMode = 2;

new g_iPingOffset;

public Plugin:myinfo = {
	name 		= "tRealPing",
	author 		= "Thrawn",
	description = "Shows the real ping values in the scoreboard",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_trealping_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_iPingOffset = FindSendPropInfo("CPlayerResource", "m_iPing");

	g_hCvarEnabled = CreateConVar("sm_trealping_enable", "1", "Enable tRealPing", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarMode = CreateConVar("sm_trealping_mode", "2", "0: GetClientLatency, 1: GetClientAvgLatency, 2: Netgraph, 3: Scoreboard;", FCVAR_PLUGIN, true, 0.0, true, 3.0);

	HookConVarChange(g_hCvarEnabled, Cvar_Changed);
	HookConVarChange(g_hCvarMode, Cvar_Changed);
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_iMode = GetConVarInt(g_hCvarMode);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnMapStart() {
	new iPlayerManager = -1;

	for(new iEntity = MaxClients+1; iEntity < GetMaxEntities(); iEntity++) {
		if(Entity_ClassNameMatches(iEntity, "_player_manager", true)) {
			iPlayerManager = iEntity;
			break;
		}
	}

	if(iPlayerManager == -1) {
		SetFailState("Unable to find \"*_player_manager\" entity");
	}

	SDKHook(iPlayerManager, SDKHook_ThinkPost, PlayerManager_OnThinkPost);
}

public PlayerManager_OnThinkPost(iEnt) {
	if(!g_bEnabled)return;

	new iPing[MAXPLAYERS+1];
	GetEntDataArray(iEnt, g_iPingOffset, iPing, MaxClients+1);

	for (new iClient = 1; iClient <= MaxClients; iClient++)	{
		if(IsClientInGame(iClient) && !IsFakeClient(iClient)) {
			switch(g_iMode)
			{
				case 0: {
					new Float:fLatency = GetClientLatency(iClient, NetFlow_Both);
					if(fLatency == -1)continue;						// Network info not available, e.g. a bot

					iPing[iClient] = RoundToNearest(fLatency * 500);
				}

				case 1: {
					new Float:fLatency = GetClientAvgLatency(iClient, NetFlow_Both);
					if(fLatency == -1)continue;						// Network info not available, e.g. a bot

					iPing[iClient] = RoundToNearest(fLatency * 500);
				}

				case 2: {
					new iFakePing = Client_GetFakePing(iClient, false);
					if(iFakePing == 0)continue;						// Network info not available, e.g. a bot
					iPing[iClient] = iFakePing;
				}

				case 3: {
					new iFakePing = Client_GetFakePing(iClient, true);
					if(iFakePing == 0)continue;						// Network info not available, e.g. a bot
					iPing[iClient] = iFakePing;
				}
			}
		}
	}

	SetEntDataArray(iEnt, g_iPingOffset, iPing, MaxClients+1);
}