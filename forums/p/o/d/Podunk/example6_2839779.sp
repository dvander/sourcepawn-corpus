#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required
float            g_oneshotAnimStartedTime = 0.0;
#define PLUGIN_VERSION "1.0"
#define MAX_LAYERS     15
#define DEBUG          true

#define USE_HACK       true

enum struct AntData
{
    int owner;
    int entity;
}

ArrayList g_Ants;
int       g_TestSeq[MAXPLAYERS + 1];

int  seq;
int  cnt;
bool _oneshot;

enum AnimationLayer
{
    LayerSequence = 0,
    LayerCycle,
    LayerWeight,
    LayerPlaybackRate,
    LayerPrevCycle,
    LayerSequenceVis,    // bool as int
    LayerOrder
}

public Plugin myinfo =
{
    name        = "Oneshot TF2 Animation",
    author      = "Podunk",
    description = "demonstration of clientside looping animations, serverside oneshot animations, and semi-serverside HACK oneshot animations",
    version     = PLUGIN_VERSION,
    url         = ""
};

public void OnPluginStart()
{
    g_Ants = new ArrayList();
    RegAdminCmd("sm_tf2_animdemo_spawn", Command_SpawnAntlion, ADMFLAG_ROOT, "Spawns a prop_dynamic_override with models/antlion.mdl at your aim position.");
    RegAdminCmd("sm_tf2_animdemo_menu", Command_SetAntlionAnim, ADMFLAG_ROOT, "Opens test menu to set animations on your current antlion.");
}

public void OnPluginEnd()
{
    delete g_Ants;
}

public void OnClientDisconnect(int client)
{
    for (int i = g_Ants.Length - 1; i >= 0; i--)
    {
        Handle        h = g_Ants.Get(i);
        AntData data;
        GetTrieArray(h, "data", data, sizeof(data));
        if (data.owner == client)
        {
            if (IsValidEntity(data.entity))
            {
                AcceptEntityInput(data.entity, "Kill");
            }
            delete h;
            g_Ants.Erase(i);
        }
    }
    g_TestSeq[client] = 0;
}

public void OnEntityDestroyed(int entity)
{
    if (entity <= 0) return;

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));
    if (StrContains(classname, "prop_", false) == -1) return;

    for (int i = g_Ants.Length - 1; i >= 0; i--)
    {
        Handle        h = g_Ants.Get(i);
        AntData data;
        GetTrieArray(h, "data", data, sizeof(data));
        if (data.entity == entity)
        {
            delete h;
            g_Ants.Erase(i);
        }
    }
}

public Action Command_SpawnAntlion(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }

    if (!IsPlayerAlive(client))
    {
        ReplyToCommand(client, "[SM] You must be alive to spawn the antlion prop.");
        return Plugin_Handled;
    }

    // Get spawn position: Player's eye position + forward
    float eyePos[3], eyeAng[3], forwardVec[3], spawnPos[3];
    GetClientEyePosition(client, eyePos);
    GetClientEyeAngles(client, eyeAng);
    GetAngleVectors(eyeAng, forwardVec, NULL_VECTOR, NULL_VECTOR);
    ScaleVector(forwardVec, 100.0);    // Distance from player
    AddVectors(eyePos, forwardVec, spawnPos);

    // Trace to ground for better placement
    TR_TraceRayFilter(eyePos, spawnPos, MASK_SOLID, RayType_EndPoint, TraceFilter_NotSelf, client);
    if (TR_DidHit())
    {
        TR_GetEndPosition(spawnPos);
        spawnPos[2] += 10.0;    // Slight offset above ground
    }

    // Create prop
    int prop = CreateEntityByName("prop_dynamic_override");
    if (prop == -1)
    {
        ReplyToCommand(client, "[SM] Failed to create prop_dynamic_override.");
        return Plugin_Handled;
    }
    // LoadVScript("anim");
    SetVScript(prop, "anim.nut");

    DispatchKeyValue(prop, "model", "models/antlion.mdl");
    DispatchKeyValue(prop, "solid", "6");             // VPhysics solid
    DispatchKeyValue(prop, "disableshadows", "1");    // Optional
    SetEntProp(prop, Prop_Send, "m_bClientSideAnimation", 1);
    DispatchSpawn(prop);
    ActivateEntity(prop);
    TeleportEntity(prop, spawnPos, NULL_VECTOR, NULL_VECTOR);

    // Add to ant list
    Handle        h = CreateTrie();
    AntData data;
    data.owner  = client;
    data.entity = prop;
    SetTrieArray(h, "data", data, sizeof(data));
    g_Ants.Push(h);

    seq = 0;
    cnt = client;
    _oneshot =false;
    Anim();

    ReplyToCommand(client, "[SM]Spawned antlion prop (entity ID: %d). Use sm_set_antlion_anim to test animations.", prop);

    return Plugin_Handled;
}

public Action Command_SetAntlionAnim(int client, int args)
{
    if (client == 0)
    {
        ReplyToCommand(client, "[SM] This command can only be used in-game.");
        return Plugin_Handled;
    }

    ShowTestMenu(client);
    return Plugin_Handled;
}

public bool TraceFilter_NotSelf(int entity, int contentsMask, any data)
{
    return entity != data;
}

stock void ShowTestMenu(int client)
{
    Menu menu = new Menu(MenuHandler_TestAnim);
    char title[64];
    Format(title, sizeof(title), "Test Sequence: %d\nSelect to adjust:", g_TestSeq[client]);
    menu.SetTitle(title);
    menu.AddItem("+1", "+1");
    menu.AddItem("-1", "-1");
    menu.AddItem("+10", "+10");
    menu.AddItem("-10", "-10");
    menu.AddItem("9", "oneshot");
    menu.AddItem("0", "Reset to 0");
    menu.ExitButton     = true;
    menu.ExitBackButton = false;
    menu.Display(client, MENU_TIME_FOREVER);
}


public int MenuHandler_TestAnim(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char info[8];
            menu.GetItem(param2, info, sizeof(info));
            bool oneshot = false;
            int  delta;
            if (StrEqual(info, "0"))
            {
                g_TestSeq[param1] = 0;
            }
            else
            {
                delta = StringToInt(info);
                if (delta == 9)
                {
                    delta   = 0;
                    oneshot = true;
                }
                g_TestSeq[param1] += delta;
            }

            _oneshot = oneshot;
            seq      = g_TestSeq[param1];
            cnt      = param1;
            Anim();

            // Redisplay menu
            ShowTestMenu(param1);
        }
        case MenuAction_Cancel:
        {
            if (param2 == MenuCancel_Exit)
            {
                PrintToChat(param1, "[SM] Animation test menu closed.");
            }
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
    return 0;
}

public void Anim()
{
    int entity = -1;
    for (int i = 0; i < g_Ants.Length; i++)
    {
        Handle h = g_Ants.Get(i);
        if (h == INVALID_HANDLE)
        {
            continue;
        }
        AntData data;
        if (!GetTrieArray(h, "data", data, sizeof(data)))
        {
            continue;
        }
        if (data.owner == cnt && IsValidEntity(data.entity))
        {
            entity = data.entity;
            break;
        }
    }
    if (entity != -1)
    {
        float time = GetGameTime();
        if (_oneshot)
        {
            // float tickInterval = GetTickInterval();
            // int   simTicks     = RoundToNearest(time / tickInterval);

            g_oneshotAnimStartedTime = GetTickedTime();
            RunVScriptCode(entity, "ResetSequence(%d)", seq);
            SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 0);
            SetEntProp(entity, Prop_Send, "m_nSequence", seq);
            SetEntPropFloat(entity, Prop_Send, "m_flCycle", 0.0);
            SetEntPropFloat(entity, Prop_Data, "m_flAnimTime", time);
            // SetEntProp(entity, Prop_Send, "m_flSimulationTime", simTicks);
            RunVScriptCode(entity, "StudioFrameAdvance()");    // makes it smoother looking

            CreateTimer(0.1, Timer_Anim, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

            PrintToChat(cnt, "[SM] Set oneshot sequence to %d.", seq);
        }
        else
        {
            SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 1);
            SetEntProp(entity, Prop_Send, "m_nSequence", seq);
            SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 1.0);
            SetEntPropFloat(entity, Prop_Send, "m_flCycle", 0.0);
            // int   simTicks = GetGameTickCount();
            SetEntPropFloat(entity, Prop_Data, "m_flAnimTime", time);
            // SetEntProp(entity, Prop_Send, "m_flSimulationTime", simTicks);
            PrintToChat(cnt, "[SM] Set sequence to %d.", seq);
        }
    }
    else
    {
        PrintToChat(cnt, "[SM] Ant not found, cannot set sequence.");
    }
}

public bool UseHack()
{
    return USE_HACK;    // to beat compiler warnings
}

public Action Timer_Anim(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity)) return Plugin_Stop;
    float k   = GetTickedTime() - g_oneshotAnimStartedTime;
    float cyc = k / 1.1;

    // TF2 Oneshot animation hack:
    // server side to client side animation
    // instead of runnign our serverside timer through the entire animation sequence we can
    // trick the engine into going server side, set the cycle to zero, and then after long enough
    // delay (0.1s-0.2s without ResetSequence; 0.001?s with ResetSequence) switch to playing the animation client side
    // i tried and running the non-oneshot code directly after oneshot-setup without a timer doesn't work
    if (UseHack() && cyc >= 0.01)
    {    // network needs enough time for cycle change to kick in
        // seq = 0;
        _oneshot = false;
        Anim();
        return Plugin_Stop;
    }
    else if (!UseHack() && cyc >= 1.0) {
        return Plugin_Stop;
    }
    PrintToChatAll("%f", cyc);
    SetEntPropFloat(entity, Prop_Send, "m_flCycle", cyc);
    RunVScriptCode(entity, "StudioFrameAdvance()");    // makes it look smooth
    // RunVScriptCode(entity, "StudioFrameAdvanceManual(%f)", cyc);

    if (cyc >= 1)
    {
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

public void RunVScriptCode(int entity, const char[] format, any...)
{
    char scriptCmd[128];
    VFormat(scriptCmd, sizeof(scriptCmd), format, 3);    // 3 is the 1-based index of the '...' in this function's parameters
    SetVariantString(scriptCmd);
    AcceptEntityInput(entity, "RunScriptCode");
}

public void SetVScript(int entity, const char[] format, any...)
{
    char vscriptPath[128];
    VFormat(vscriptPath, sizeof(vscriptPath), format, 3);    // 3 is the 1-based index of the '...' in this function's parameters
#if DEBUG
    PrintToServer("vscriptPath: %s", vscriptPath);
#endif
    DispatchKeyValue(entity, "vscripts", vscriptPath);
}

public void LoadVScript(const char[] format, any...)
{
    char scriptNam[128];
    VFormat(scriptNam, sizeof(scriptNam), format, 2);    // 2 is the 1-based index of the '...' in this function's parameters
    char scriptCmd[128];
    Format(scriptCmd, sizeof(scriptCmd), "script_execute %s", scriptNam);
#if DEBUG
    PrintToServer("LoadVScript: %s", scriptCmd);
#endif
    ServerCommand(scriptCmd);
}