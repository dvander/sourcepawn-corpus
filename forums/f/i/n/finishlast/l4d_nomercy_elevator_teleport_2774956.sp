#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define TEAM_SURVIVOR 2
#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
    name = "L4D1 No Mercy Elevator Teleport",
    author = "",
    description = "",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnMapStart()
{
}

public void OnPluginStart()
{
    HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{
    static char sMap[32], sName[64];
    int entity = -1;
    int client = anyClient();

       GetCurrentMap(sMap, sizeof(sMap));

    if (strcmp(sMap, "l4d_vs_hospital04_interior") == 0 || strcmp(sMap, "l4d_hospital04_interior") == 0  || strcmp(sMap, "c8m4_interior") == 0)
        {
        while (-1 != (entity = FindEntityByClassname(entity, "func_button")))
        {
            GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
            if (strcmp(sName, "elevator_button") == 0)
            {
		AcceptEntityInput(entity, "unlock", client);
                HookSingleEntityOutput(entity, "OnPressed",  OnReachedBottom, true);
                break;
            }
        }
    }
}


stock void OnReachedBottom(const char[] output, int caller, int activator, float delay)
{    
    float vpos[3]; 
    vpos[0] = 13435.0;
    vpos[1] = 15267.0; 
    vpos[2] = 487.0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
       {
    PrintToChat(i, "Teleport Player: %N", i); //print to every player in loop - %N show nickname
    if(activator!=i){
        TeleportEntity(i, vpos, NULL_VECTOR, NULL_VECTOR); 
       }
    }
} 
}

int anyClient(){
	for(int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 3 && IsPlayerAlive(i)) {
			return i;
		}
	}
} 