#include <sourcemod>
#include <sdktools>

#define INVALID_PLAYER_INDEX -1
new Team=2;
new Handle:sm_saxtonremainingplayers;

#define AC_ONE 	"vo/announcer_am_capenabled02.wav"

public Plugin:myinfo = {
	name = "Saxton CP",
	author = "frog",
	description = "Enables control points when there are X people left alive.",
	version = "0.9",
	url = "http://www.thehh.co.uk"
}

public OnPluginStart() {
	sm_saxtonremainingplayers = CreateConVar("sm_saxtonremainingplayers", "3", "Remaining players for CPs to be enabled", FCVAR_PLUGIN, true, 0.0, false);
	HookEvent("player_death", EventPlayer_Death);
	HookEvent("teamplay_round_win", EventRound_Win, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", EventRound_Start, EventHookMode_PostNoCopy);
}

public OnConfigsExecuted()
{
	PrecacheSound(AC_ONE, true);
}

public EventRound_Start(Handle:event, const String:name[], bool:dontBroadcast) {
	DisableControlPoints(true);
	Team = WhichTeam();
	PrintHintTextToAll("CONTROL POINT IS DISABLED UNTIL LAST %i LIVING PLAYERS",GetConVarInt(sm_saxtonremainingplayers));
}

public EventRound_Win(Handle:event, const String:name[], bool:dontBroadcast) {
	DisableControlPoints(false);
}

public Action:EventPlayer_Death(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetEventBool(event, "feign_death")) {
	CreateTimer(1.0, Death_Timer, GetClientTeam(GetClientOfUserId(GetEventInt(event, "userid"))));
	}
	return Plugin_Continue;
}

public Action:Death_Timer(Handle:timer, any:team) {
	if (GetPlayersAlive(Team) == GetConVarInt(sm_saxtonremainingplayers)) {
		DisableControlPoints(false);
		EmitSoundToAll(AC_ONE);
		PrintHintTextToAll("%i PLAYERS LEFT - CONTROL POINT IS ENABLED!",GetConVarInt(sm_saxtonremainingplayers));
	}
	if (GetPlayersAlive(Team) < GetConVarInt(sm_saxtonremainingplayers)) {
		DisableControlPoints(false);
	}
}
			

GetPlayersAlive(any:team) {
    new players;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            if (GetClientTeam(i) == team && IsPlayerAlive(i)){
                players++;
            }
        }
    }
    return players;
}

WhichTeam() {
    new red;
    new blue;
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            if (GetClientTeam(i) == 2){
                red++;
            }
            if (GetClientTeam(i) == 3){
                blue++;
            }          
        }
    }
    if (red > blue) {
    	return 2;
    	
    } else {
    	return 3;	
    }
}

public DisableControlPoints(bool:capState)
{
    new i = -1;
    new CP = 0;

    for (new n = 0; n <= 16; n++)
    {
        CP = FindEntityByClassname(i, "trigger_capture_area");
        if (IsValidEntity(CP))
        {
            if(capState)
            {
                AcceptEntityInput(CP, "Disable");
            }else{
                AcceptEntityInput(CP, "Enable");
            }
            i = CP;
        }
        else
            break;
    }
} 