#include <tf2_stocks>
#include <sourcemod>

#define CURRENTVERSION "public 1.0"

new bool:AllowSuicide = true;

public Plugin:myinfo = {
    name = "Start/End Simple Suicide Blocker",
    author = "Darthmule",
    description = "Blocks the 'kill' and 'explode' command when a round has started and didn't end.",
    version = CURRENTVERSION,
};

public OnPluginStart()
{
    HookEvent("teamplay_setup_finished", event_roundsetup_finished);    // If the round really started, so when players can do stuff!
    HookEvent("teamplay_round_win", event_round_end);                   // If round has ended
    AddCommandListener(BlockCommand, "kill");
    AddCommandListener(BlockCommand, "explode");
    AddCommandListener(BlockCommand, "retry");
}

public Action:event_roundsetup_finished(Handle:event, const String:name[], bool:dontBroadcast)
{
    AllowSuicide = false;
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
    AllowSuicide = true;
}

public Action:BlockCommand(client, const String:command[], args)
{
    if (!AllowSuicide) {  // if AllowSuicide is equaled false, block the command.
        return Plugin_Handled;
    }
    
    else
        return Plugin_Stop;
}