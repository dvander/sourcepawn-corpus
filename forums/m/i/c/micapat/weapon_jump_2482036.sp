
/* ========================================================================= */
/* INCLUDES                                                                  */
/* ========================================================================= */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls  required

/* ========================================================================= */
/* DEFINES                                                                   */
/* ========================================================================= */

/* Plugin version                                                            */
#define C_PLUGIN_VERSION                "3.1.0"

/* ------------------------------------------------------------------------- */

/* Knockback weapon property                                                 */
#define C_WEAPON_PROPERTY_KNOCKBACK     (0)
/* Velocity weapon property                                                  */
#define C_WEAPON_PROPERTY_VELOCITY      (1)
/* Ground weapon property                                                    */
#define C_WEAPON_PROPERTY_GROUND        (2)
/* Maximum weapon property                                                   */
#define C_WEAPON_PROPERTY_MAXIMUM       (3)

/* ========================================================================= */
/* GLOBAL CONSTANTS                                                          */
/* ========================================================================= */

/* Plugin information                                                        */
public Plugin myinfo =
{
    name        = "Weapon Jump",
    author      = "Nyuu",
    description = "Knockback the players when shooting",
    version     = C_PLUGIN_VERSION,
    url         = "https://forums.alliedmods.net/showthread.php?t=292151"
}

/* ========================================================================= */
/* GLOBAL VARIABLES                                                          */
/* ========================================================================= */

/* Plugin late loading                                                       */
bool      gl_bPluginLateLoading;

/* Players weapon jump                                                       */
bool      gl_bPlayerWeaponJump        [MAXPLAYERS + 1];
/* Players weapon jump velocity                                              */
float     gl_vPlayerWeaponJumpVelocity[MAXPLAYERS + 1][3];

/* Weapon properties stringmap                                               */
StringMap gl_hMapWeaponProperties;

/* ------------------------------------------------------------------------- */

/* Plugin enable cvar                                                        */
ConVar    gl_hCvarPluginEnable;

/* Plugin enable cvar value                                                  */
bool      gl_bCvarPluginEnable;

/* ========================================================================= */
/* FUNCTIONS                                                                 */
/* ========================================================================= */

/* ------------------------------------------------------------------------- */
/* Plugin                                                                    */
/* ------------------------------------------------------------------------- */

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrorMaxLen)
{
    // Cache plugin late loading status
    gl_bPluginLateLoading = bLate;
    
    return APLRes_Success;
}

public void OnPluginStart()
{
    // Initialize the cvars
    CvarInitialize();

    // Create the weapon properties stringmap
    gl_hMapWeaponProperties = new StringMap();
    
    // Hook the weapon fire event
    HookEvent("weapon_fire", OnWeaponFirePost, EventHookMode_Post);
    
    // Check for plugin late loading
    if (gl_bPluginLateLoading)
    {
        PluginStartLate();
    }
}

void PluginStartLate()
{
    // Process the players already on the server
    for (int iPlayer = 1 ; iPlayer <= MaxClients ; iPlayer++)
    {
        // Check if the player is connected
        if (IsClientConnected(iPlayer))
        {
            // Call the client connected forward
            OnClientConnected(iPlayer);
                
            // Check if the player is in game
            if (IsClientInGame(iPlayer))
            {
                // Call the client put in server forward
                OnClientPutInServer(iPlayer);
            }
        }
    }
}

/* ------------------------------------------------------------------------- */
/* Configuration                                                             */
/* ------------------------------------------------------------------------- */

public void OnConfigsExecuted()
{
    char szConfigFile[PLATFORM_MAX_PATH];
    
    // Create the configuration keyvalues
    KeyValues kvConfig = new KeyValues("weapons");
    
    // Clear the weapon properties stringmap
    gl_hMapWeaponProperties.Clear();
    
    // Build the path of the configuration file
    BuildPath(Path_SM, szConfigFile, sizeof(szConfigFile), "configs/weapon_jump.cfg");
    
    // Import the configuration file
    if (kvConfig.ImportFromFile(szConfigFile))
    {
        LogMessage("Start to read the configuration file...");
        
        // Go to the first weapon properties section
        if (kvConfig.GotoFirstSubKey())
        {
            char szWeaponName[32];
            int  arrWeaponProperty[C_WEAPON_PROPERTY_MAXIMUM];
            
            do
            {
                // Read the weapon name
                if (kvConfig.GetSectionName(szWeaponName, sizeof(szWeaponName)))
                {
                    // Get the weapon properties
                    float flKnockback = kvConfig.GetFloat("knockback", 0.00);
                    float flVelocity  = kvConfig.GetFloat("velocity",  0.00);
                    int   iGround     = kvConfig.GetNum  ("ground",    0);
                    bool  bGround     = false;
                    
                    // Check & clamp the weapon properties
                    if (flVelocity < 0.00)
                    {
                        flVelocity = 0.00;
                    }
                    else if (flVelocity > 1.00)
                    {
                        flVelocity = 1.00;
                    }
                    
                    if (iGround)
                    {
                        bGround = true;
                    }
                    
                    // Convert the weapon properties
                    arrWeaponProperty[C_WEAPON_PROPERTY_KNOCKBACK] = view_as<int>(flKnockback);
                    arrWeaponProperty[C_WEAPON_PROPERTY_VELOCITY]  = view_as<int>(flVelocity);
                    arrWeaponProperty[C_WEAPON_PROPERTY_GROUND]    = view_as<int>(bGround);
                    
                    // Push the weapon properties in the stringmap
                    gl_hMapWeaponProperties.SetArray(szWeaponName, arrWeaponProperty, C_WEAPON_PROPERTY_MAXIMUM);
                    
                    LogMessage("Read \"%s\" (Knockback: %0.2f | Velocity: %0.2f | Ground: %d).", 
                        szWeaponName, flKnockback, flVelocity, bGround);
                }
                
                // Go to the next weapon properties section
            } while (kvConfig.GotoNextKey());
        }
        
        LogMessage("Finish to read the configuration file (%d weapons read) !", gl_hMapWeaponProperties.Size);
    }
    else
    {
        LogError("Can't import the configuration file !");
        LogError("> Path: %s", szConfigFile);
    }
    
    delete kvConfig;
}

/* ------------------------------------------------------------------------- */
/* Cvar                                                                      */
/* ------------------------------------------------------------------------- */

void CvarInitialize()
{
    // Create the version cvar
    CreateConVar("sm_weapon_jump_version", C_PLUGIN_VERSION, "Display the plugin version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY);
    
    // Create the custom cvars
    gl_hCvarPluginEnable = CreateConVar("sm_weapon_jump_enable", "1", "Enable the plugin", _, true, 0.0, true, 1.0);
    
    // Cache the custom cvars values
    gl_bCvarPluginEnable = gl_hCvarPluginEnable.BoolValue;
    
    // Hook the custom cvars change
    gl_hCvarPluginEnable.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
    // Cache the custom cvars values
    if (gl_hCvarPluginEnable == hCvar) gl_bCvarPluginEnable = gl_hCvarPluginEnable.BoolValue;
}

/* ------------------------------------------------------------------------- */
/* Client                                                                    */
/* ------------------------------------------------------------------------- */

public void OnClientConnected(int iClient)
{
    // Initialize the client data
    gl_bPlayerWeaponJump        [iClient]    = false;
    gl_vPlayerWeaponJumpVelocity[iClient][0] = 0.0;
    gl_vPlayerWeaponJumpVelocity[iClient][1] = 0.0;
    gl_vPlayerWeaponJumpVelocity[iClient][2] = 0.0;
}

public void OnClientPutInServer(int iClient)
{
    // Hook the client postthink function
    SDKHook(iClient, SDKHook_PostThinkPost, OnPlayerPostThinkPost);
}

public void OnClientDisconnect(int iClient)
{
    // Clear the client data
    gl_bPlayerWeaponJump        [iClient]    = false;
    gl_vPlayerWeaponJumpVelocity[iClient][0] = 0.0;
    gl_vPlayerWeaponJumpVelocity[iClient][1] = 0.0;
    gl_vPlayerWeaponJumpVelocity[iClient][2] = 0.0;
}

/* ------------------------------------------------------------------------- */
/* Weapon                                                                    */
/* ------------------------------------------------------------------------- */

public void OnWeaponFirePost(Event hEvent, const char[] szName, bool bDontBroadcast)
{
    // Check if the plugin is enabled
    if (gl_bCvarPluginEnable)
    {
        // Get the player
        int iPlayer = GetClientOfUserId(hEvent.GetInt("userid"));
        
        // Check if the player is valid
        if (1 <= iPlayer <= MaxClients)
        {
            // Get the player active weapon
            int iWeapon = GetEntPropEnt(iPlayer, Prop_Send, "m_hActiveWeapon");
            
            // Check the current number of ammo in the loader
            if (GetEntProp(iWeapon, Prop_Send, "m_iClip1") > 0)
            {
                char szWeaponName[32];
                int  arrWeaponProperty[C_WEAPON_PROPERTY_MAXIMUM];
                
                // Get the weapon name
                hEvent.GetString("weapon", szWeaponName, sizeof(szWeaponName));
                
                // Check if the weapon name is present in the weapon properties stringmap
                if (gl_hMapWeaponProperties.GetArray(szWeaponName, arrWeaponProperty, C_WEAPON_PROPERTY_MAXIMUM))
                {
                    // Convert the weapon properties
                    float flKnockback = view_as<float>(arrWeaponProperty[C_WEAPON_PROPERTY_KNOCKBACK]);
                    float flVelocity  = view_as<float>(arrWeaponProperty[C_WEAPON_PROPERTY_VELOCITY]);
                    bool  bGround     = view_as<bool> (arrWeaponProperty[C_WEAPON_PROPERTY_GROUND]);
                    
                    // Check if the player can weapon jump on ground
                    if (!(GetEntityFlags(iPlayer) & FL_ONGROUND) || bGround)
                    {
                        float vPlayerVelocity[3];
                        float vPlayerEyeAngles[3];
                        float vPlayerForward[3];
                        
                        // Get the player velocity
                        GetEntPropVector(iPlayer, Prop_Data, "m_vecVelocity", vPlayerVelocity);
                        
                        // Get the player forward direction
                        GetClientEyeAngles(iPlayer, vPlayerEyeAngles);
                        GetAngleVectors(vPlayerEyeAngles, vPlayerForward, NULL_VECTOR, NULL_VECTOR);
                        
                        // Compute the player weapon jump velocity
                        gl_vPlayerWeaponJumpVelocity[iPlayer][0] = vPlayerVelocity[0] * flVelocity - vPlayerForward[0] * flKnockback;
                        gl_vPlayerWeaponJumpVelocity[iPlayer][1] = vPlayerVelocity[1] * flVelocity - vPlayerForward[1] * flKnockback;
                        gl_vPlayerWeaponJumpVelocity[iPlayer][2] = vPlayerVelocity[2] * flVelocity - vPlayerForward[2] * flKnockback;
                        
                        // Set the player weapon jump
                        gl_bPlayerWeaponJump[iPlayer] = true;
                    }
                }
            }
        }
    }
}

/* ------------------------------------------------------------------------- */
/* Player                                                                    */
/* ------------------------------------------------------------------------- */

public void OnPlayerPostThinkPost(int iPlayer)
{
    // Check if the player must weapon jump
    if (gl_bPlayerWeaponJump[iPlayer])
    {
        // Check if the player is still alive
        if (IsPlayerAlive(iPlayer))
        {
            // Knockback the player
            TeleportEntity(iPlayer, NULL_VECTOR, NULL_VECTOR, gl_vPlayerWeaponJumpVelocity[iPlayer]);
        }
        
        // Reset the player weapon jump
        gl_bPlayerWeaponJump[iPlayer] = false;
    }
}

/* ========================================================================= */
