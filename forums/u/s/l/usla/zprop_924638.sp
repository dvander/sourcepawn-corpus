/**
 * ====================
 *       ZProp
 *   Author: Greyscale
 * ==================== 
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define VERSION "1.0"

new offsEyeAngle0;

new g_iCredits[MAXPLAYERS+1];

new Handle:kvProps = INVALID_HANDLE;

new Handle:cvarCreditsMax = INVALID_HANDLE;
new Handle:cvarCreditsConnect = INVALID_HANDLE;
new Handle:cvarCreditsSpawn = INVALID_HANDLE;
new Handle:cvarCreditsInfect = INVALID_HANDLE;
new Handle:cvarCreditsKill = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Last Man Standing",
    author = "Greyscale",
    description = "To be made",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{
    LoadTranslations("zprop.phrases");
    
    // ======================================================================
    
    HookEvent("player_spawn", PlayerSpawn);
    HookEvent("player_death", PlayerDeath);
    HookEvent("player_team", PlayerTeam);
    
    // ======================================================================
    
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);
    
    // ======================================================================
    
    offsEyeAngle0 = FindSendPropInfo("CCSPlayer", "m_angEyeAngles[0]");
    if (offsEyeAngle0 == -1)
    {
        SetFailState("Couldn't find \"m_angEyeAngles[0]\"!");
    }
    
    // ======================================================================
    
    cvarCreditsMax = CreateConVar("zprop_credits_max", "15", "Max credits that can be attained (0: No limit)");
    cvarCreditsConnect = CreateConVar("zprop_credits_connect", "4", "The number of free credits a player received when they join the game");
    cvarCreditsSpawn = CreateConVar("zprop_credits_spawn", "3", "The number of free credits given on spawn");
    cvarCreditsInfect = CreateConVar("zprop_credits_infect", "1", "The number of credits given for infecting a human as zombie");
    cvarCreditsKill = CreateConVar("zprop_credits_kill", "5", "The number of credits given for killing a zombie as human");
    
    CreateConVar("gs_zprop_version", VERSION, "[ZProp] Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    AutoExecConfig(true, "zprop");
}

public OnMapStart()
{
    if (kvProps != INVALID_HANDLE)
        CloseHandle(kvProps);
    
    kvProps = CreateKeyValues("zprops");
    
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/zprops.txt");
    
    if (!FileToKeyValues(kvProps, path))
    {
        SetFailState("\"%s\" missing from server", path);
    }
}

public OnClientPutInServer(client)
{
    g_iCredits[client] = -1;
}

public Action:Command_Say(client, argc)
{
    decl String:args[192];
    
    GetCmdArgString(args, sizeof(args));
    ReplaceString(args, sizeof(args), "\"", "");
    
    if (StrEqual(args, "!zprops", false))
    {
        if (!IsPlayerAlive(client))
            return Plugin_Handled;
        
if (GetUserFlagBits(client) && ADMFLAG_CUSTOM2)
   MainMenu(client);
else
   PrintToChat(client, "[SM] Not Authorized"); 
    }
    
    return Plugin_Continue;
}

MainMenu(client)
{
    new Handle:menu_main = CreateMenu(MainMenuHandle);
    
    SetGlobalTransTarget(client);
    
    SetMenuTitle(menu_main, "%t\n ", "Menu title", g_iCredits[client]);
    
    decl String:propname[64];
    decl String:display[64];
    
    KvRewind(kvProps);
    if (KvGotoFirstSubKey(kvProps))
    {
        do
        {
            KvGetSectionName(kvProps, propname, sizeof(propname));
            new cost = KvGetNum(kvProps, "cost");
            Format(display, sizeof(display), "%t", "Menu option", propname, cost);
            
            if (g_iCredits[client] >= cost)
            {
                AddMenuItem(menu_main, propname, display);
            }
            else
            {
                AddMenuItem(menu_main, propname, display, ITEMDRAW_DISABLED);
            }
        } while (KvGotoNextKey(kvProps));
    }
    
    DisplayMenu(menu_main, client, MENU_TIME_FOREVER);
}

public MainMenuHandle(Handle:menu_main, MenuAction:action, client, slot)
{
    if (action == MenuAction_Select)
    {
        decl String:propname[64];
        if (GetMenuItem(menu_main, slot, propname, sizeof(propname)))
        {
            KvRewind(kvProps);
            if (KvJumpToKey(kvProps, propname))
            {
                new cost = KvGetNum(kvProps, "cost");
                if (g_iCredits[client] < cost)
                {
                    PrintToChat(client, "\x04[%t] \x01%t", "ZProp", "Insufficient credits", g_iCredits[client], cost);
                    MainMenu(client);
                    
                    return;
                }
                
                new Float:vecOrigin[3];
                new Float:vecAngles[3];
                
                GetClientAbsOrigin(client, vecOrigin);
                GetClientAbsAngles(client, vecAngles);
                
                vecAngles[0] = GetEntDataFloat(client, offsEyeAngle0);
                
                vecOrigin[2] += 50;
                
                decl Float:vecFinal[3];
                AddInFrontOf(vecOrigin, vecAngles, 35, vecFinal);
  
                decl String:propmodel[128];
                KvGetString(kvProps, "model", propmodel, sizeof(propmodel));
                
                new prop = CreateEntityByName("prop_physics_override");
                
                PrecacheModel(propmodel);
                SetEntityModel(prop, propmodel);
                
                DispatchSpawn(prop);
                
                TeleportEntity(prop, vecFinal, NULL_VECTOR, NULL_VECTOR);
                
                g_iCredits[client] -= cost;
                
                ZProp_HudHint(client, "Credits left spend", cost, g_iCredits[client]);
                PrintToChat(client, "\x04[%t] \x01%t", "ZProp", "Spawn prop", propname);
            }
        }
    }
    if (action == MenuAction_End)
    {
        CloseHandle(menu_main);
    }
}

AddInFrontOf(Float:vecOrigin[3], Float:vecAngle[3], units, Float:output[3])
{
    new Float:vecView[3];
    GetViewVector(vecAngle, vecView);
    
    output[0] = vecView[0] * units + vecOrigin[0];
    output[1] = vecView[1] * units + vecOrigin[1];
    output[2] = vecView[2] * units + vecOrigin[2];
}
 
GetViewVector(Float:vecAngle[3], Float:output[3])
{
    output[0] = Cosine(vecAngle[1] / (180 / FLOAT_PI));
    output[1] = Sine(vecAngle[1] / (180 / FLOAT_PI));
    output[2] = -Sine(vecAngle[0] / (180 / FLOAT_PI));
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    
    new team = GetClientTeam(index);
    if (team != CS_TEAM_T && team != CS_TEAM_CT)
        return;
    
    new credits_max = GetConVarInt(cvarCreditsMax);
    new credits_spawn = GetConVarInt(cvarCreditsSpawn);
    
    g_iCredits[index] += credits_spawn;
    
    if (g_iCredits[index] < credits_max)
    {
        ZProp_HudHint(index, "Credits left gain", credits_spawn, g_iCredits[index]);
    }
    else
    {
        g_iCredits[index] = credits_max;
        ZProp_HudHint(index, "Credits left max", credits_spawn, g_iCredits[index]);
    }
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    if (!attacker)
        return;
    
    decl String:weapon[32];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    new credits_earned = StrEqual(weapon, "zombie_claws_of_death") ? GetConVarInt(cvarCreditsInfect) : GetConVarInt(cvarCreditsKill);
    new credits_max = GetConVarInt(cvarCreditsMax);
    
    g_iCredits[attacker] += credits_earned;
    
    if (g_iCredits[attacker] < credits_max)
    {
        ZProp_HudHint(attacker, "Credits left gain", credits_earned, g_iCredits[attacker]);
    }
    else
    {
        g_iCredits[attacker] = credits_max;
        ZProp_HudHint(attacker, "Credits left max", credits_earned, g_iCredits[attacker]);
    }
}

public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new index = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (!index)
        return;
    
    if (g_iCredits[index] == -1)
    {
        new credits_connect = GetConVarInt(cvarCreditsConnect);
        g_iCredits[index] = credits_connect;
        
        PrintToChat(index, "\x04[%t] \x01%t", "ZProp", "Join message");
    }
}

ZProp_HudHint(client, any:...)
{
    SetGlobalTransTarget(client);
    
    decl String:phrase[192];
    
    VFormat(phrase, sizeof(phrase), "%t", 2);
    
    new Handle:hHintText = StartMessageOne("HintText", client);
    if (hHintText != INVALID_HANDLE)
    {
        BfWriteByte(hHintText, -1); 
        BfWriteString(hHintText, phrase);
        EndMessage();
    }
}