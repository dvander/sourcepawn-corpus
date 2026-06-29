#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION "1.01"

public Plugin:myinfo = {
	name = "ND Warmup Round",
	author = "Senseless",
	description = "Creates a warm-up round as the first round so all users can get into a game before it starts.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new wActive;
new wEnable;
new Float:wTimer;
new wMaxrounds;
new wThisround;

public OnPluginStart() {
	LogMessage("[ND Warmup Round] - Loaded");
	CreateConVar("sm_nd_warmup_enable", "1", "Enables the ND Warmup plugin (Default 1)");
	CreateConVar("sm_nd_warmup_timer", "20.0", "Time for the warmup round (Default 20)");
	CreateConVar("sm_nd_warmup_version", PLUGIN_VERSION, "ND Warmup Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	wThisround=0;
	wEnable = GetConVarInt(FindConVar("sm_nd_warmup_enable"));
	wTimer = GetConVarFloat(FindConVar("sm_nd_warmup_timer"));
	HookEvent("round_start", event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("promoted_to_commander", event_PromotedToCommander, EventHookMode_PostNoCopy);
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	if (wThisround > wMaxrounds) {
		wThisround=1;
	} else {
		wThisround=wThisround+1;
	}
	if (wEnable == 1 && wThisround == 1) {
		LogMessage("[ND Warmup] Warmup Round Starting");
		CPrintToChatAll("{green}Warmup Round Starting!");
		wActive = 1;
		new ent = -1;
		while((ent = FindEntityByClassname(ent, "nd_trigger_resource_point")) != -1) {
			AcceptEntityInput(ent, "Disable");
		}
		wMaxrounds = GetConVarInt(FindConVar("mp_maxrounds"));
		SetConVarInt(FindConVar("mp_maxrounds"), wMaxrounds + 1, false, false);
		CreateTimer(wTimer, EndWarmupRound, _);
	}
}

public event_PromotedToCommander(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, ResetCommander, _);
}

public Action:EndWarmupRound(Handle:timer) {
	LogMessage("[ND Warmup] Warmup Round Over");
	CPrintToChatAll("{green}Warmup Round Over! Restarting Round!");
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "nd_trigger_resource_point")) != -1) {
		AcceptEntityInput(ent, "Enable");
	}
	SetConVarInt(FindConVar("sm_nd_balancer_enable"), 0, false, false);
	new maxclients = MaxClients;
	for(new i=1; i <= maxclients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			new team = GetClientTeam(i);
			if (team == 2) {
				ChangeClientTeam(i, 1);
				ChangeClientTeam(i, 2);
			}
			if (team == 3) {
				ChangeClientTeam(i, 1);
				ChangeClientTeam(i, 3);
			}
		}
	}
	SetConVarInt(FindConVar("sm_nd_balancer_enable"), 1, false, false);
 	wActive = 0;
}

public Action:ResetCommander(Handle:timer) {
	if (wActive == 1) {
		GameRules_SetProp("m_hCommanders", 0, 4, 0,true);
		GameRules_SetProp("m_hCommanders", 0, 4, 1,true);
	}
}

