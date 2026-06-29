#include <sdktools>
#include <tf2_stocks>
#pragma newdecls required

public Plugin myinfo =
{
    name = "Balancer Fix",
    author = "VOLK_RuS",
    description = "Destroy engi buildings on balance.",
    version = "0.2",
    url = "awpcountry.ru"
} 

public void OnPluginStart()
{
    HookEvent("player_team", Player_Team);
}
public void Player_Team(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsValidClient(client) && TF2_GetPlayerClass(client) == TFClass_Engineer){
        DestroyBuildings(client);
    }
}

stock int DestroyBuildings(int client)
{
    char strObjects[3][] = {"obj_sentrygun","obj_dispenser","obj_teleporter"};
    for( int o = 0; o < sizeof(strObjects); o++ ){
        int iEnt = -1;
        while( ( iEnt = FindEntityByClassname( iEnt, strObjects[o] ) ) != -1 )
        if (client == GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder"))
        {
            if( IsValidEdict(iEnt) )
            {
                SetEntityHealth( iEnt, 100 );
                SetVariantInt( 1488 );
                AcceptEntityInput( iEnt, "RemoveHealth" );
            }
        }
    }
}
stock bool IsValidClient(int client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    return true;
}