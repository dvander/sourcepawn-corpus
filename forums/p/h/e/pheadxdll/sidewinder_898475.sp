/**
 * vim: set ai et ts=4 sw=4 :
 * File: sidewinder.sp
 * Description: Housekeeping tasks for the sidewinder extension.
 * Author(s): -=|JFH|=-Naris
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <sidewinder>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Sidewinder",
	author = "-=|JFH|=-Naris",
	description = "Housekeeping tasks for the sidewinder extension.",
	version = PLUGIN_VERSION,
	url = "http://www.jigglysfunhouse.net"
};

public OnPluginStart()
{
    if (!HookEventEx("teamplay_round_start",ResetClientForEvent,EventHookMode_PostNoCopy))
        SetFailState("Could not hook the teamplay_round_start event.");

    if (!HookEventEx("arena_round_start",ResetClientForEvent,EventHookMode_PostNoCopy))
        SetFailState("Could not hook the arena_round_start event.");

    CreateConVar("sm_sidewinder_version", PLUGIN_VERSION, "sidewinder housekeeping", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    SidewinderControl(true);
}



public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    SidewinderTrackChance(client, 0);
    SidewinderSentryCritChance(client, 0);
    SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows |
                            NormalFlares | NormalPipes | NormalSyringe, true);
    return true;
}

public OnClientDisconnect(client)
{
    SidewinderTrackChance(client, 0);
    SidewinderSentryCritChance(client, 0);
    SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows |
                            NormalFlares | NormalPipes | NormalSyringe, true);
}

public ResetClientForEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    for(new client=1;client<=MaxClients;client++)
    {
        SidewinderTrackChance(client, 0);
        SidewinderSentryCritChance(client, 0);
        SidewinderFlags(client, NormalSentryRockets | NormalRockets | NormalArrows |
                        NormalFlares | NormalPipes | NormalSyringe, true);
    }
}