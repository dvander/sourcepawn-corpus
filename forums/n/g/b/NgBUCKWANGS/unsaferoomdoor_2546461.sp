//# vim: set filetype=cpp :

/*
 * license = "https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html#SEC1",
 */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_NAME "UnsafeRoomDoor"
#define PLUGIN_VERSION "0.0.2"

float g_timeouts[MAXPLAYERS + 1];

public Plugin myinfo= {
    name = PLUGIN_NAME,
    author = "Victor \"NgBUCKWANGS\" Gonzalez",
    description = "SI Can Open Safe Room Doors",
    version = PLUGIN_VERSION,
    url = ""
}

bool IsEntityValid(int ent) {
    return (ent > MaxClients && ent <= 2048 && IsValidEntity(ent));
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) {

    static float distance;
    static float[3] clientVector;
    static float[3] targetVector;
    static float engineTime;
    static char clsName[64];
    static int target;

    if (GetClientTeam(client) == 3 && buttons & 32) {
        if (GetEntProp(client, Prop_Send, "m_isGhost") == 1) {
            return;
        }

        engineTime = GetEngineTime();
        if (engineTime < g_timeouts[client]) {
            return;
        }

        target = GetClientAimTarget(client, false);

        if (IsEntityValid(target)) {
            GetEntityClassname(target, clsName, sizeof(clsName));

            if (clsName[0] == 'p' && StrEqual(clsName, "prop_door_rotating_checkpoint")) {
                GetClientAbsOrigin(client, clientVector);
                GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetVector);
                distance = GetVectorDistance(clientVector, targetVector, true);

                if (distance < 11000.0) {
                    AcceptEntityInput(target, "Toggle");
                    g_timeouts[client] = engineTime + 2.0;
                }
            }
        }
    }
}
