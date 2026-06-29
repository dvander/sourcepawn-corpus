#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1


new bool:AfterJumpFrame[MAXPLAYERS + 1];

new FloorFrames[MAXPLAYERS + 1];

new bool:PlayerOnGround[MAXPLAYERS + 1];

new Float:AirSpeed[MAXPLAYERS + 1][3];

new BaseVelocity;

new Handle:CvarPluginEnabled;
new bool:PluginEnabled;

new Handle:CvarMaxBhopFrames;
new MaxBhopFrames;

new Handle:CvarFramePenalty;
new Float:FramePenalty;


new bool:PlayerInTriggerPush[MAXPLAYERS + 1];

public Plugin:myinfo =
{
    name = "RealBhop",
    author = "SeriTools",
    description = "SourceMod plugin that aims to recreate HL1/Quake-like bunnyhopping.",
    version = "1.1.1",
    url = "https://github.com/SeriTools/sm_realbhop"
}

public OnPluginStart()
{
    // get basevelocity offset
    BaseVelocity = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");

    // cvars

    CvarPluginEnabled = CreateConVar("sm_realbhop_enabled", "1", "Sets whether RealBhop is enabled", FCVAR_NOTIFY);
    HookConVarChange(CvarPluginEnabled, OnPluginEnabledChange);

    CvarMaxBhopFrames = CreateConVar("sm_realbhop_maxbhopframes", "12", "Sets the maximum number of frames the bhop calculation is active after touching the ground.", FCVAR_NOTIFY, true, 1.0, false);
    HookConVarChange(CvarMaxBhopFrames, OnMaxBhopFramesChange);

    CvarFramePenalty = CreateConVar("sm_realbhop_framepenalty", "0.975", "Sets the velocity penalty multiplier per frame the player jumped too late. (1.0 = no penalty)", FCVAR_NOTIFY, true, 0.0, false);
    HookConVarChange(CvarFramePenalty, OnFramePenaltyChange);

    AutoExecConfig(true, "sm_realbhop");
    PluginEnabled = GetConVarBool(CvarPluginEnabled);
    MaxBhopFrames = GetConVarInt(CvarMaxBhopFrames);
    FramePenalty = GetConVarFloat(CvarFramePenalty);

    HookEvent("round_start", Event_OnRoundStart, EventHookMode_PostNoCopy);

    // set all values to sane defaults to prevent randomness
    for (new i = 0; i <= MaxClients; i++) {
        ResetValues(i);
    }
}

public OnClientPutInServer(client)
{
    // set array values to sane defaults
    ResetValues(client);
}

public OnGameFrame()
{
    if (PluginEnabled) {
        for (new i = 1; i <= MaxClients; i++) {
            if(IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i) && !IsClientObserver(i) && !PlayerInTriggerPush[i]) {
                if(GetEntityFlags(i) & FL_ONGROUND) { // on ground
                    if (!PlayerOnGround[i]) { // first ground frame

                        // player now on ground
                        PlayerOnGround[i] = true;
                        // reset floor frame counter
                        FloorFrames[i] = 0;
                    }
                    else { // another ground frame
                        if (FloorFrames[i] <= MaxBhopFrames) {
                            FloorFrames[i]++;
                        }
                    }
                }
                else { // in air
                    if (AfterJumpFrame[i]) { // apply the boostsecond air frame
                                             // to prevent some glitchiness
                        // only apply within the maxbhopframes range
                        if (FloorFrames[i] <= MaxBhopFrames) {
                            new Float:finalvec[3];

                            // get current speed
                            GetEntPropVector(i, Prop_Data, "m_vecVelocity", finalvec);

                            // calculate difference between the speed on the last air frame
                            // before hitting the ground and the speed while in the second air frame
                            // and apply the late jump penalty to it
                            finalvec[0] = (AirSpeed[i][0] - finalvec[0]) * Pow(FramePenalty, float(FloorFrames[i]));
                            finalvec[1] = (AirSpeed[i][1] - finalvec[1]) * Pow(FramePenalty, float(FloorFrames[i]));
                            finalvec[2] = 0.0;

                            // set the difference as boost
                            SetEntDataVector(i, BaseVelocity, finalvec, true);
                        }
                        AfterJumpFrame[i] = false;
                    }

                    if (PlayerOnGround[i]) { // first air frame
                        // player not on ground anymore
                        PlayerOnGround[i] = false;
                        AfterJumpFrame[i] = true;
                    }
                    else {
                        // get air speed
                        // NOTE: this has to be done every airframe
                        // to have the last speed value of the frame _before_ landing,
                        // not of the landing frame itself, as the speed is already changed
                        // in that frame if the player lands on sloped surfaces in some
                        // angles :/
                        GetEntPropVector(i, Prop_Data, "m_vecVelocity", AirSpeed[i]);
                    }
                }
            }
        }
    }
}

public OnPluginEnabledChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    PluginEnabled = GetConVarBool(cvar);
}

ResetValues(client)
{
    FloorFrames[client] = MaxBhopFrames + 1;
    AirSpeed[client][0] = 0.0;
    AirSpeed[client][1] = 0.0;
    AfterJumpFrame[client] = false;
    PlayerInTriggerPush[client] = false;
}

public OnMaxBhopFramesChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    // "-1" so we dont have to do FloorFrames[i] = 1 and (FloorFrames[i] - 1) * 1.0
    MaxBhopFrames = StringToInt(newVal) - 1;
}

public OnFramePenaltyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
    FramePenalty = StringToFloat(newVal);
}

public OnMapStart()
{
    HookTriggerPushes();
}

public Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    HookTriggerPushes();
}

HookTriggerPushes()
{
    // hook trigger_pushes to disable velocity calculation in these, allowing
    // the push to be applied correctly
    new index = -1;
    while ((index = FindEntityByClassname2(index, "trigger_push")) != -1) {
        SDKHook(index, SDKHook_StartTouch, Event_EntityOnStartTouch);
        SDKHook(index, SDKHook_EndTouch, Event_EntityOnEndTouch);
    }
}

FindEntityByClassname2(startEnt, const String:classname[])
{
    /* If startEnt isn't valid shifting it back to the nearest valid one */
    while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
    
    return FindEntityByClassname(startEnt, classname);
}

public Event_EntityOnStartTouch(entity, client)
{
    if (client <= MAXPLAYERS
        && IsValidEntity(client)
        && IsClientInGame(client)) {
        PlayerInTriggerPush[client] = true;
    }
}

public Event_EntityOnEndTouch(entity, client)
{
    if (client <= MAXPLAYERS
        && IsValidEntity(client)
        && IsClientInGame(client)) {
        PlayerInTriggerPush[client] = false;
    }
}
