#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <smlib>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#include <sendproxy>


#define VERSION 		"0.0.3-preview"

new Handle:g_hCvarMode = INVALID_HANDLE;
new Handle:g_hCvarEnabled = INVALID_HANDLE;

new bool:g_bEnabled;
new g_iMode = 2;

new g_iPingOffset;

new bool:g_bSendProxy = false;

public Plugin:myinfo = {
	name 		= "tRealPing",
	author 		= "Thrawn",
	description = "Shows the real ping values in the scoreboard",
	version 	= VERSION,
};

public OnPluginStart() {
	//g_bSendProxy = LibraryExists("sendproxy");
	g_bSendProxy = (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "SendProxy_HookArrayProp") == FeatureStatus_Available);

	if(!LibraryExists("sdkhooks") && !g_bSendProxy) {
		SetFailState("You need either SDKHooks or the SendProxy extension to run this plugin.");
	}

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

	if(g_bSendProxy) {
		for(new iClient = 1; iClient <= MaxClients; iClient++) {
			SendProxy_HookArrayProp(iPlayerManager, "m_iPing", iClient, Prop_Int, PlayerManager_OnSendProp);
		}
	} else {
		SDKHook(iPlayerManager, SDKHook_ThinkPost, PlayerManager_OnThinkPost);
	}
}

public Action:PlayerManager_OnSendProp(iPlayerManager, const String:sPropName[], &iPing, iClient) {
	if(!g_bEnabled)return Plugin_Continue;
	if(!IsClientInGame(iClient) || IsFakeClient(iClient))return Plugin_Continue;

	new iRealPing = GetClientPing(iClient);
	if(iRealPing == -1)return Plugin_Continue;

	iPing = iRealPing;

	return Plugin_Changed;
}

public PlayerManager_OnThinkPost(iPlayerManager) {
	if(!g_bEnabled)return;

	new iPing[MAXPLAYERS+1];
	GetEntDataArray(iPlayerManager, g_iPingOffset, iPing, MaxClients+1);

	for (new iClient = 1; iClient <= MaxClients; iClient++)	{
		if(IsClientInGame(iClient) && !IsFakeClient(iClient)) {
			iPing[iClient] = GetClientPing(iClient);
		}
	}

	SetEntDataArray(iPlayerManager, g_iPingOffset, iPing, MaxClients+1);
}

GetClientPing(iClient) {
	switch(g_iMode)
	{
		case 0: {
			new Float:fLatency = GetClientLatency(iClient, NetFlow_Both);
			if(fLatency == -1)return -1;

			return RoundToNearest(fLatency * 500);
		}

		case 1: {
			new Float:fLatency = GetClientAvgLatency(iClient, NetFlow_Both);
			if(fLatency == -1)return -1;

			return RoundToNearest(fLatency * 500);
		}

		case 2: {
			new iFakePing = Client_GetFakePing(iClient, false);
			if(iFakePing == 0)return -1;

			return iFakePing;
		}

		case 3: {
			new iFakePing = Client_GetFakePing(iClient, true);
			if(iFakePing == 0)return -1;

			return iFakePing;
		}
	}

	return -1;
}