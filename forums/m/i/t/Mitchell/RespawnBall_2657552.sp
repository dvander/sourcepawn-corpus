#include <sdktools>
#pragma newdecls required
#pragma semicolon 1

#define Middle_Stadium view_as<float>({-2764.00, -1024.00, 80.00})
#define GOAL_POST1_MIN view_as<float>({-2865.986816, -228.250336, 60.00})
#define GOAL_POST1_MAX view_as<float>({-2660.006348, -173.291168, 120.00})
#define GOAL_POST2_MIN view_as<float>({-2867.968750, -1874.708740, 60.00})
#define GOAL_POST2_MAX view_as<float>({-2662.000244, -1819.318726, 120.00})

int ballRef;

public Plugin myinfo = {
    name = "Respawn Ball",
    author = "Had3s99",
    description = "Respawn Balle Foot",
    version = "1.1",
    url = "lastfate.fr"
};

public void OnMapStart() {
    char mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    if(StrContains(mapname, "ba_jail_electric_razor_v6", false) == 0 || 
       StrContains(mapname, "ba_jail_electric_razor_go", false) == 0) {
        CreateTimer(0.1, EnterOrNot, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action EnterOrNot(Handle timer) {
    char entName[64];
    float entPos[3];
    int ballIndex = EntRefToEntIndex(ballRef);
    if(ballIndex == -1 || !IsValidEntity(ballIndex)) {
        for(int i = MaxClients; i <= 2048; i++) {
            if(IsValidEntity(i)) {
                GetEntPropString(i, Prop_Send, "m_iName", entName, sizeof(entName));
                if(StrContains(entName, "ballon") != -1) {
                    ballRef = EntIndexToEntRef(i);
                    ballIndex = i;
                    break;
                }
            }
        }
    }
    if(ballIndex != -1 && IsValidEntity(ballIndex)) {
        GetEntPropVector(ballIndex, Prop_Send, "m_vecOrigin", entPos);
        if(posInBox(entPos, GOAL_POST1_MIN, GOAL_POST1_MAX) || posInBox(entPos, GOAL_POST2_MIN, GOAL_POST2_MAX)) {
            TeleportEntity(ballIndex, Middle_Stadium, NULL_VECTOR, NULL_VECTOR);
        }
    }
}

bool posInBox(float pos[3], float min[3], float max[3]) {
    return (pos[0] >= min[0] && pos[0] <= max[0] && pos[1] >= min[1] && pos[1] <= max[1] && pos[2] >= min[2] && pos[2] <= max[2]);
}