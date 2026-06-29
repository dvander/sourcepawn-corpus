/**
 * Companion plugin to fix setup time detection for bots.
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools>

#pragma newdecls required

public void OnPluginStart() {
	HookEvent("teamplay_round_active", OnRoundActive, EventHookMode_PostNoCopy);
}

public void OnRoundActive(Event event, const char[] name, bool dontBroadcast) {
	// some maps activate their timers right after this event is fired, so we need to delay
	CreateTimer(0.25, OnRoundFullyActive, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnRoundFullyActive(Handle timer) {
	if (GameRules_GetProp("m_bInSetup")) {
		bool bReallyIsSetup;
		
		int roundTimer = -1;
		while ((roundTimer = (FindEntityByClassname(roundTimer, "team_round_timer"))) != -1) {
			bool bDisabled = !!GetEntProp(roundTimer, Prop_Data, "m_bIsDisabled");
			int nSetupTimeLength = GetEntProp(roundTimer, Prop_Data, "m_nSetupTimeLength");
			
			if (!bDisabled && nSetupTimeLength > 0) {
				bReallyIsSetup = true;
			}
		}
		
		GameRules_SetProp("m_bInSetup", bReallyIsSetup);
	}
}
