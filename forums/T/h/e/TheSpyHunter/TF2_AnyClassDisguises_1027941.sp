// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <adt>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Sourcemod constants --------------------------------------------------------
#define PLUGIN_NAME         "[TF2] Any Class Disguises"
#define PLUGIN_AUTHOR       "Damizean & TheSpyHunter"
#define PLUGIN_VERSION      "1.0"
#define PLUGIN_CONTACT      "elgigantedeyeso@gmail.com"
#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_NOTIF

// *********************************************************************************
// VARIABLES
// *********************************************************************************
new bool:g_bDisguised[MAXPLAYERS+1];
new Handle:g_hSdkRegenerate;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_NAME,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

// *********************************************************************************
// METHODS
// *********************************************************************************
    
/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**    ______              
**   / ____/___  ________ 
**  / /   / __ \/ ___/ _ \
** / /___/ /_/ / /  /  __/
** \____/\____/_/   \___/
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public OnPluginStart()
{
    // Check if the plugin is being run on the proper mod.
    decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf")) SetFailState("This plugin is only for Team Fortress 2.");
   
    // Startup SDK
    SetupSDK();
    
    // Hook events
    HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
    
    // Create command
    RegAdminCmd("sm_spyme", CmdDisguise, ADMFLAG_SLAY);
}

/* SetupSDK()
**
** Registers the SDK methods.
** -------------------------------------------------------------------------- */
stock SetupSDK()
{
    new Handle:hGameConf = LoadGameConfigFile("sm-tf2.resupply");
    if (hGameConf != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Signature,"Regenerate");
        g_hSdkRegenerate = EndPrepSDKCall();
        
        CloseHandle(hGameConf);
    } else {
        SetFailState("Couldn't load SDK functions.");
    }
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**     __  ___                                                  __ 
**    /  |/  /___ _____  ____ _____ ____  ____ ___  ___  ____  / /_
**   / /|_/ / __ `/ __ \/ __ `/ __ `/ _ \/ __ `__ \/ _ \/ __ \/ __/
**  / /  / / /_/ / / / / /_/ / /_/ /  __/ / / / / /  __/ / / / /_  
** /_/  /_/\__,_/_/ /_/\__,_/\__, /\___/_/ /_/ /_/\___/_/ /_/\__/  
**                          /____/                                 
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* EventPlayerSpawn()
**
** 
** -------------------------------------------------------------------------- */
public EventPlayerSpawn(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if (!IsValidClient(iClient, true)) return;    

    // Remove the disguised flag.
    g_bDisguised[iClient] = false;
}

/* OnGameFrame()
**
** Checks if the disguised clients are still disguised.
** -------------------------------------------------------------------------- */
public OnGameFrame()
{
    for (new iClient = 1; iClient <= MaxClients; iClient++)
    {       
        if (!IsValidClient(iClient, true, true)) continue;
        if (!g_bDisguised[iClient]) continue;
        
        // Remove the disguise whenever the attack or attack2 are used.
        if (GetClientButtons(iClient) & (IN_ATTACK|IN_ATTACK2))
        {
            DisguiseAs(iClient, iClient);
        }
    }    
}

/* DisguiseAs()
**
** Makes the client disguise as the other.
** -------------------------------------------------------------------------- */
stock DisguiseAs(iClient, iOther)
{
    if (!IsValidClient(iClient, true, true)) return;
    
    if (iClient == iOther)
    {
        if (g_bDisguised[iClient] == true)
        {
            // Remove disguise condition
            TF2_RemoveCond(iClient, 3);
            
            // Regenerate
            Regenerate(iClient);
            
            // Done
            g_bDisguised[iClient] = false;
        }
    }
    else
    {
        if (!IsValidClient(iOther, true, true)) return;
        
        // Retrieve class and team
        new TFClassType:tfcClass = TF2_GetPlayerClass(iOther);
        new iTeam = GetClientTeam(iOther);
        
        // Set all the properties
        SetEntProp(iClient, Prop_Send, "m_nDisguiseClass", tfcClass);
        SetEntProp(iClient, Prop_Send, "m_nDesiredDisguiseClass", tfcClass);
        SetEntProp(iClient, Prop_Send, "m_nMaskClass", tfcClass);
        SetEntProp(iClient, Prop_Send, "m_nDisguiseTeam", iTeam);
        SetEntProp(iClient, Prop_Send, "m_nDesiredDisguiseTeam", iTeam);
        SetEntProp(iClient, Prop_Send, "m_iDisguiseTargetIndex", iOther);
        SetEntProp(iClient, Prop_Send, "m_iDisguiseHealth", GetClientHealth(iOther));
        
        // Set disguise condition
        TF2_AddCond(iClient, 3);
    
        // Regenerate
        Regenerate(iClient);
        
        // Done
        g_bDisguised[iClient] = true;
    }
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**    ______                                          __    
**   / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
**  / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
** / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  ) 
** \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/  
**                                                       
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* CmdDisguise()
**
** Command for a client to disguise.
** -------------------------------------------------------------------------- */
public Action:CmdDisguise(iClient, iArgs)
{
    new Handle:hMenu = CreateMenu(MenuDisguise);
    SetMenuTitle(hMenu, "Choose other player:");
        
    AddMenuItem(hMenu, "", "RED", ITEMDRAW_RAWLINE);
    for (new iOther = 1; iOther <= MaxClients; iOther++)
    {
        if (!IsValidClient(iOther)) continue;
        if (GetClientTeam(iClient) != 2) continue;
        
        decl String:strName[255], String:strInfo[4];
        GetClientName(iOther, strName, sizeof(strName));
        IntToString(iOther, strInfo, sizeof(strInfo));
        
        AddMenuItem(hMenu, strInfo, strName);
    }

    AddMenuItem(hMenu, "", "BLU", ITEMDRAW_RAWLINE);
    for (new iOther = 1; iOther <= MaxClients; iOther++)
    {
        if (!IsValidClient(iOther)) continue;
        if (GetClientTeam(iClient) != 3) continue;
        
        decl String:strName[255], String:strInfo[4];
        GetClientName(iOther, strName, sizeof(strName));
        IntToString(iOther, strInfo, sizeof(strInfo));
        
        AddMenuItem(hMenu, strInfo, strName);
    }
    
    DisplayMenu(hMenu, iClient, 0);
    return Plugin_Handled;
}

/* MenuDisguise()
**
** Menu handler for the disguise menu.
** -------------------------------------------------------------------------- */
public MenuDisguise(Handle:hMenu, MenuAction:maAction, iClient, iResult)
{
    if (maAction == MenuAction_Select)
    {
        new String:strOther[32];
        GetMenuItem(hMenu, iResult, strOther, sizeof(strOther));
        new iOther = StringToInt(strOther);
        
        DisguiseAs(iClient, iOther);
    }
    else if (maAction == MenuAction_End)
    {
        CloseHandle(hMenu);
    }
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**   ______            __    
**  /_  __/___  ____  / /____
**   / / / __ \/ __ \/ / ___/
**  / / / /_/ / /_/ / (__  ) 
** /_/  \____/\____/_/____/  
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* Regenerate()
**
** Regenerates the player withtout altering the health or ammo.
** -------------------------------------------------------------------------- */
stock Regenerate(iClient)
{    
    // Store all the values
    new iHealth = GetClientHealth(iClient);
    new iAmmo[8];
    new iClips[8][2];
    new iAmmoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
    new iCurrentWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
    new iCurrentSlot   = 0;
    
    for (new iSlot = 0; iSlot < 8; iSlot++)
    {
        new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
        if (iWeapon != -1)
        {
            iAmmo[iSlot] = GetEntData(iClient, iAmmoOffset+GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 8)*4, 2);
            iClips[iSlot][0] = GetEntProp(iWeapon, Prop_Send, "m_iClip1", 1);
            iClips[iSlot][1] = GetEntProp(iWeapon, Prop_Send, "m_iClip2", 1);
            
            if (iWeapon == iCurrentWeapon) iCurrentSlot = iSlot;
            
            TF2_RemoveWeaponSlot(iClient, iSlot);
        }
    }
    
    // Regenerate
    SDKCall(g_hSdkRegenerate, iClient);
    
    // Set all the values previously stored
    SetEntityHealth(iClient, iHealth);
    for (new iSlot = 0; iSlot < 8; iSlot++)
    {
        new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
        if (iWeapon != -1)
        {
            SetEntData(iClient, iAmmoOffset+GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType", 8)*4, iAmmo[iSlot], 2, true);
            SetEntProp(iWeapon, Prop_Send, "m_iClip1", iClips[iSlot][0], 1);
            SetEntProp(iWeapon, Prop_Send, "m_iClip2", iClips[iSlot][1], 2);
            
            if (iSlot == iCurrentSlot) SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
        }
    }    
}

/* TF2_AddCond()
**
** -------------------------------------------------------------------------- */
stock TF2_AddCond(Client, Condition)
{
    new Handle:Cvar = FindConVar("sv_cheats");
    new bool:Enabled = GetConVarBool(Cvar);
    new Flags = GetConVarFlags(Cvar);
    
    // Check if the sv_cheats cvar needs to be activated.
    if(!Enabled) {
        SetConVarFlags(Cvar, Flags & ~(FCVAR_NOTIFY|FCVAR_REPLICATED));
        SetConVarBool(Cvar, true);
    }
    
    // Add condition.
    FakeClientCommand(Client, "addcond %i", Condition);
    
    // Deactivate sv_cheats.
    if(!Enabled) {
        SetConVarBool(Cvar, false);
        SetConVarFlags(Cvar, Flags);
    }
}

/* TF2_RemoveCond()
**
** -------------------------------------------------------------------------- */
stock TF2_RemoveCond(Client, Condition)
{
    new Handle:Cvar = FindConVar("sv_cheats");
    new bool:Enabled = GetConVarBool(Cvar);    new Flags = GetConVarFlags(Cvar);
    
    // Check if the sv_cheats cvar needs to be activated.
    if(!Enabled) {
        SetConVarFlags(Cvar, Flags & ~(FCVAR_NOTIFY|FCVAR_REPLICATED));
        SetConVarBool(Cvar, true);
    }
    
    // Add condition.
    FakeClientCommand(Client, "removecond %i", Condition);
    
    // Deactivate sv_cheats.
    if(!Enabled) {
        SetConVarBool(Cvar, false);
        SetConVarFlags(Cvar, Flags);
    }
}  

/* IsValidClient()
**
** Determines if the given client is valid (valid index, connected and in-game).
** -------------------------------------------------------------------------- */
bool:IsValidClient(iClient, bool:bCheckTeams=false, bool:bCheckAlive=false)
{
    if (iClient < 0 || iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    if (!IsClientInGame(iClient)) return false;
    if (bCheckTeams == true)
    {
        new iTeam = GetClientTeam(iClient);
        if (iTeam < 2 || iTeam > 3) return false;
    }
    if (bCheckAlive == true)
    {
        if (!IsPlayerAlive(iClient)) return false;
    }
    return true;
}