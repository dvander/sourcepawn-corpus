#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
native void Heartbeat_SetRevives(int client, int reviveCount, bool reviveLogic = true);

#define SOUND_HEARTBEAT	"player/heartbeatloop.wav"

Action cmd_test(int client, int args)
{
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        Heartbeat_SetRevives(client, 1);
        //SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		//StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
    }
    return Plugin_Handled;
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_revive", cmd_test);
}