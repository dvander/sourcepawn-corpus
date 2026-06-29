
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
#define C_PLUGIN_VERSION                "1.1.0"

/* ------------------------------------------------------------------------- */

/* No grenade type (Assault rifle, knife..)                                  */
#define C_GRENADE_TYPE_NONE             (-1)
/* High explosive grenade type                                               */
#define C_GRENADE_TYPE_HE               (0)
/* Flashbang grenade type                                                    */
#define C_GRENADE_TYPE_FLASHBANG        (1)
/* Smoke grenade type                                                        */
#define C_GRENADE_TYPE_SMOKE            (2)
/* Decoy grenade type                                                        */
#define C_GRENADE_TYPE_DECOY            (3)
/* Tactical awareness grenade type                                           */
#define C_GRENADE_TYPE_TA               (4)
/* Incendiary grenade type                                                   */
#define C_GRENADE_TYPE_INCENDIARY       (5)
/* Maximum grenade type                                                      */
#define C_GRENADE_TYPE_MAXIMUM          (6)

/* Normal grenade mode                                                       */
#define C_GRENADE_MODE_NORMAL           (0)
/* Impact grenade mode                                                       */
#define C_GRENADE_MODE_IMPACT           (1)
/* Proximity grenade mode                                                    */
#define C_GRENADE_MODE_PROXIMITY        (2)
/* Tripwire grenade mode                                                     */
#define C_GRENADE_MODE_TRIPWIRE         (3)
/* Maximum grenade mode                                                      */
#define C_GRENADE_MODE_MAXIMUM          (4)

/* Wait idle proximity state                                                 */
#define C_PROXIMITY_STATE_WAIT_IDLE     (0)
/* Powerup proximity state                                                   */
#define C_PROXIMITY_STATE_POWERUP       (1)
/* Detect proximity state                                                    */
#define C_PROXIMITY_STATE_DETECT        (2)
/* Maximum proximity state                                                   */
#define C_PROXIMITY_STATE_MAXIMUM       (3)

/* Powerup tripwire state                                                    */
#define C_TRIPWIRE_STATE_POWERUP        (0)
/* Detect tripwire state                                                     */
#define C_TRIPWIRE_STATE_DETECT         (1)
/* Maximum tripwire state                                                    */
#define C_TRIPWIRE_STATE_MAXIMUM        (2)

/* ========================================================================= */
/* GLOBAL CONSTANTS                                                          */
/* ========================================================================= */

/* Plugin information                                                        */
public Plugin myinfo =
{
    name        = "Grenade Modes",
    author      = "Nyuu",
    description = "Provide new modes for the grenades",
    version     = C_PLUGIN_VERSION,
    url         = "https://forums.alliedmods.net/showthread.php?t=309154"
}

/* ------------------------------------------------------------------------- */

/* Grenade type names (Translation)                                          */
char gl_szGrenadeTypeNameTr[C_GRENADE_TYPE_MAXIMUM][] =
{
    "TExplosive", // HE
    "TFlashbang", // FLASHBANG
    "TSmoke",     // SMOKE
    "TDecoy",     // DECOY
    "TTactical",  // TA
    "TIncendiary" // INCENDIARY + MOLOTOV
};

/* Grenade mode names (Translation)                                          */
char gl_szGrenadeModeNameTr[C_GRENADE_MODE_MAXIMUM][] =
{
    "TNormal",    // NORMAL
    "TImpact",    // IMPACT
    "TProximity", // PROXIMITY
    "TTripwire"   // TRIPWIRE
};

/* Grenade mode limits                                                       */
int gl_iGrenadeModeLimits[C_GRENADE_TYPE_MAXIMUM] = 
{
    C_GRENADE_MODE_MAXIMUM, // HE
    C_GRENADE_MODE_MAXIMUM, // FLASHBANG
    C_GRENADE_MODE_MAXIMUM, // SMOKE
    C_GRENADE_MODE_IMPACT,  // DECOY
    C_GRENADE_MODE_IMPACT,  // TA
    C_GRENADE_MODE_IMPACT   // INCENDIARY + MOLOTOV
};

/* ========================================================================= */
/* GLOBAL VARIABLES                                                          */
/* ========================================================================= */

/* Plugin late loading                                                       */
bool      gl_bPluginLateLoading;

/* Players in game                                                           */
bool      gl_bPlayerInGame     [MAXPLAYERS + 1];
/* Players current grenade type                                              */
int       gl_iPlayerGrenadeType[MAXPLAYERS + 1];
/* Players mode for each grenade type                                        */
int       gl_iPlayerGrenadeMode[MAXPLAYERS + 1][C_GRENADE_TYPE_MAXIMUM];

/* Beacon sprite                                                             */
int       gl_nSpriteBeacon;
/* Beam sprite                                                               */
int       gl_nSpriteBeam;
/* Halo sprite                                                               */
int       gl_nSpriteHalo;

/* Grenade weapon name stringmap                                             */
StringMap gl_hGrenadeWeaponName;
/* Grenade projectile name stringmap                                         */
StringMap gl_hGrenadeProjectileName;

/* ------------------------------------------------------------------------- */

/* Plugin enable cvar                                                        */
ConVar    gl_hCvarPluginEnable;
/* Color of the self effects cvar                                            */
ConVar    gl_hCvarEffectsSelfColor;
/* Color of the teammate effects cvar                                        */
ConVar    gl_hCvarEffectsTeammateColor;
/* Color of the enemy effects cvar                                           */
ConVar    gl_hCvarEffectsEnemyColor;
/* Powerup time for the proximity mode cvar                                  */
ConVar    gl_hCvarProximityPowerupTime;
/* Powerup time for the tripwire mode cvar                                   */
ConVar    gl_hCvarTripwirePowerupTime;

/* Plugin enable cvar value                                                  */
bool      gl_bCvarPluginEnable;
/* Color of the self effects cvar value                                      */
int       gl_iCvarEffectsSelfColor;
/* Color of the teammate effects cvar value                                  */
int       gl_iCvarEffectsTeammateColor;
/* Color of the enemy effects cvar value                                     */
int       gl_iCvarEffectsEnemyColor;
/* Powerup time for the proximity mode cvar value                            */
float     gl_flCvarProximityPowerupTime;
/* Powerup time for the tripwire mode cvar value                             */
float     gl_flCvarTripwirePowerupTime;

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
    
    // Load the translations
    LoadTranslations("grenade_modes.phrases");
    
    // Prepare the grenade weapon name stringmap
    gl_hGrenadeWeaponName = new StringMap();
    gl_hGrenadeWeaponName.SetValue("weapon_hegrenade",    C_GRENADE_TYPE_HE);
    gl_hGrenadeWeaponName.SetValue("weapon_flashbang",    C_GRENADE_TYPE_FLASHBANG);
    gl_hGrenadeWeaponName.SetValue("weapon_smokegrenade", C_GRENADE_TYPE_SMOKE);
    gl_hGrenadeWeaponName.SetValue("weapon_decoy",        C_GRENADE_TYPE_DECOY);
    gl_hGrenadeWeaponName.SetValue("weapon_tagrenade",    C_GRENADE_TYPE_TA);
    gl_hGrenadeWeaponName.SetValue("weapon_incgrenade",   C_GRENADE_TYPE_INCENDIARY);
    gl_hGrenadeWeaponName.SetValue("weapon_molotov",      C_GRENADE_TYPE_INCENDIARY);
    
    // Prepare the grenade projectile name stringmap
    gl_hGrenadeProjectileName = new StringMap();
    gl_hGrenadeProjectileName.SetValue("hegrenade_projectile",    C_GRENADE_TYPE_HE);
    gl_hGrenadeProjectileName.SetValue("flashbang_projectile",    C_GRENADE_TYPE_FLASHBANG);
    gl_hGrenadeProjectileName.SetValue("smokegrenade_projectile", C_GRENADE_TYPE_SMOKE);
    
    // Hook the player command +lookatweapon
    AddCommandListener(OnPlayerLookAtWeapon, "+lookatweapon");
    
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
/* Map                                                                       */
/* ------------------------------------------------------------------------- */

public void OnMapStart()
{
    // Precache the sprites
    gl_nSpriteBeacon = PrecacheModel("materials/sprites/physbeam.vmt");
    gl_nSpriteBeam   = PrecacheModel("materials/sprites/purplelaser1.vmt");
    gl_nSpriteHalo   = PrecacheModel("materials/sprites/purpleglow1.vmt");
    
    // Precache the sounds
    PrecacheSound("buttons/blip1.wav");
    PrecacheSound("buttons/blip2.wav");
}

/* ------------------------------------------------------------------------- */
/* Cvar                                                                      */
/* ------------------------------------------------------------------------- */

void CvarInitialize()
{
    // Create the version cvar
    CreateConVar("sm_grenade_modes_version", C_PLUGIN_VERSION, "Display the plugin version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY);
    
    // Create the custom cvars
    gl_hCvarPluginEnable         = CreateConVar("sm_grenade_modes_enable",                 "1",        "Enable the plugin",                     _, true, 0.0, true, 1.0);
    gl_hCvarEffectsSelfColor     = CreateConVar("sm_grenade_modes_self_color",             "0x0000FF", "Set the color of the self effects",     _, true, 0.0);
    gl_hCvarEffectsTeammateColor = CreateConVar("sm_grenade_modes_teammate_color",         "0x0000FF", "Set the color of the teammate effects", _, true, 0.0);
    gl_hCvarEffectsEnemyColor    = CreateConVar("sm_grenade_modes_enemy_color",            "0xFF0000", "Set the color of the enemy effects",    _, true, 0.0);
    gl_hCvarProximityPowerupTime = CreateConVar("sm_grenade_modes_proximity_powerup_time", "2.0",      "Set the proximity powerup time",        _, true, 0.0);
    gl_hCvarTripwirePowerupTime  = CreateConVar("sm_grenade_modes_tripwire_powerup_time",  "2.0",      "Set the tripwire powerup time",         _, true, 0.0);
    
    // Cache the custom cvars values
    gl_bCvarPluginEnable          = gl_hCvarPluginEnable.BoolValue;
    gl_iCvarEffectsSelfColor      = gl_hCvarEffectsSelfColor.IntValue;
    gl_iCvarEffectsTeammateColor  = gl_hCvarEffectsTeammateColor.IntValue;
    gl_iCvarEffectsEnemyColor     = gl_hCvarEffectsEnemyColor.IntValue;
    gl_flCvarProximityPowerupTime = gl_hCvarProximityPowerupTime.FloatValue;
    gl_flCvarTripwirePowerupTime  = gl_hCvarTripwirePowerupTime.FloatValue;
    
    // Hook the custom cvars change
    gl_hCvarPluginEnable.AddChangeHook(OnCvarChanged);
    gl_hCvarEffectsSelfColor.AddChangeHook(OnCvarChanged);
    gl_hCvarEffectsTeammateColor.AddChangeHook(OnCvarChanged);
    gl_hCvarEffectsEnemyColor.AddChangeHook(OnCvarChanged);
    gl_hCvarProximityPowerupTime.AddChangeHook(OnCvarChanged);
    gl_hCvarTripwirePowerupTime.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
    // Cache the custom cvars values
    if      (gl_hCvarPluginEnable         == hCvar) gl_bCvarPluginEnable          = gl_hCvarPluginEnable.BoolValue;
    else if (gl_hCvarEffectsSelfColor     == hCvar) gl_iCvarEffectsSelfColor      = gl_hCvarEffectsSelfColor.IntValue;
    else if (gl_hCvarEffectsTeammateColor == hCvar) gl_iCvarEffectsTeammateColor  = gl_hCvarEffectsTeammateColor.IntValue;
    else if (gl_hCvarEffectsEnemyColor    == hCvar) gl_iCvarEffectsEnemyColor     = gl_hCvarEffectsEnemyColor.IntValue;
    else if (gl_hCvarProximityPowerupTime == hCvar) gl_flCvarProximityPowerupTime = gl_hCvarProximityPowerupTime.FloatValue;
    else if (gl_hCvarTripwirePowerupTime  == hCvar) gl_flCvarTripwirePowerupTime  = gl_hCvarTripwirePowerupTime.FloatValue;
}

/* ------------------------------------------------------------------------- */
/* Client                                                                    */
/* ------------------------------------------------------------------------- */

public void OnClientConnected(int iClient)
{
    // Initialize the client data
    gl_bPlayerInGame     [iClient] = false;
    gl_iPlayerGrenadeType[iClient] = C_GRENADE_TYPE_NONE;
    
    gl_iPlayerGrenadeMode[iClient][C_GRENADE_TYPE_HE]         = C_GRENADE_MODE_NORMAL;
    gl_iPlayerGrenadeMode[iClient][C_GRENADE_TYPE_FLASHBANG]  = C_GRENADE_MODE_NORMAL;
    gl_iPlayerGrenadeMode[iClient][C_GRENADE_TYPE_SMOKE]      = C_GRENADE_MODE_NORMAL;
    gl_iPlayerGrenadeMode[iClient][C_GRENADE_TYPE_DECOY]      = C_GRENADE_MODE_NORMAL;
    gl_iPlayerGrenadeMode[iClient][C_GRENADE_TYPE_TA]         = C_GRENADE_MODE_NORMAL;
    gl_iPlayerGrenadeMode[iClient][C_GRENADE_TYPE_INCENDIARY] = C_GRENADE_MODE_NORMAL;
}

public void OnClientPutInServer(int iClient)
{
    // Set the client as in game
    gl_bPlayerInGame[iClient] = true;
    
    // Hook the client weapon switch function
    SDKHook(iClient, SDKHook_WeaponSwitch, OnPlayerWeaponSwitch);
}

public void OnClientDisconnect(int iClient)
{
    // Clear the client data
    gl_bPlayerInGame     [iClient] = false;
    gl_iPlayerGrenadeType[iClient] = C_GRENADE_TYPE_NONE;
}

/* ------------------------------------------------------------------------- */
/* Player                                                                    */
/* ------------------------------------------------------------------------- */

public Action OnPlayerWeaponSwitch(int iPlayer, int iWeapon)
{
    static char szClassname[32];
    static int  iGrenadeType;
    
    // Get the weapon classname
    GetEdictClassname(iWeapon, szClassname, sizeof(szClassname));
    
    // Check if the weapon is a grenade
    if (gl_hGrenadeWeaponName.GetValue(szClassname, iGrenadeType))
    {
        gl_iPlayerGrenadeType[iPlayer] = iGrenadeType;
    }
    else
    {
        gl_iPlayerGrenadeType[iPlayer] = C_GRENADE_TYPE_NONE;
    }
    
    return Plugin_Continue;
}

public Action OnPlayerLookAtWeapon(int iPlayer, const char[] szCommand, int iArgc)
{
    // Check if the plugin is enabled
    if (gl_bCvarPluginEnable)
    {
        // Check if the player is alive
        if (gl_bPlayerInGame[iPlayer] && IsPlayerAlive(iPlayer))
        {
            // Cache the grenade type
            int iGrenadeType = gl_iPlayerGrenadeType[iPlayer];
            
            // Check if the current player weapon is a grenade
            if (iGrenadeType != C_GRENADE_TYPE_NONE)
            {
                /* Cache the grenade mode */
                int iGrenadeMode = gl_iPlayerGrenadeMode[iPlayer][iGrenadeType];
                
                // Go to the next grenade mode
                iGrenadeMode = (iGrenadeMode + 1) % gl_iGrenadeModeLimits[iGrenadeType];
                
                // Set the grenade mode
                gl_iPlayerGrenadeMode[iPlayer][iGrenadeType] = iGrenadeMode;
                
                // Display the grenade mode
                PrintHintText(iPlayer, "<b> %t <font color='#CE7FFF'>%t</font></b>\n\
                                        <b> >> %t : <font color='#4FE44A'>%t</font></b>",
                                        "TGrenade", gl_szGrenadeTypeNameTr[iGrenadeType], 
                                        "TMode",    gl_szGrenadeModeNameTr[iGrenadeMode]);
            }
        }
    }
    
    return Plugin_Continue;
}

/* ------------------------------------------------------------------------- */
/* Entity                                                                    */
/* ------------------------------------------------------------------------- */

public void OnEntityCreated(int iEntity, const char[] szClassname)
{
    static int iGrenadeType;
    
    // Check if the plugin is enabled
    if (gl_bCvarPluginEnable)
    {
        // Check if the entity created is a grenade projectile
        if (gl_hGrenadeProjectileName.GetValue(szClassname, iGrenadeType))
        {
            // Hook the grenade spawn function
            SDKHook(iEntity, SDKHook_SpawnPost, OnGrenadeSpawnPost);
        }
    }
}

/* ------------------------------------------------------------------------- */
/* Grenade                                                                   */
/* ------------------------------------------------------------------------- */

public void OnGrenadeSpawnPost(int iGrenade)
{
    char szClassname[32];
    int  iGrenadeType;
    
    // Get the grenade classname
    GetEdictClassname(iGrenade, szClassname, sizeof(szClassname));
    
    // Get the grenade type
    if (gl_hGrenadeProjectileName.GetValue(szClassname, iGrenadeType))
    {
        // Get the grenade owner
        int iOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
        
        // Check if the owner is connected
        if (1 <= iOwner <= MaxClients)
        {
            // Switch on the player grenade mode
            switch (gl_iPlayerGrenadeMode[iOwner][iGrenadeType])
            {
                case C_GRENADE_MODE_NORMAL:
                {
                    // Nothing to do
                }
                case C_GRENADE_MODE_IMPACT:
                {
                    // Set the grenade as infinite
                    CreateTimer(0.1, OnGrenadeTimerSetInfinite, EntIndexToEntRef(iGrenade), TIMER_FLAG_NO_MAPCHANGE);
                    
                    // Hook the grenade touch function
                    SDKHook(iGrenade, SDKHook_TouchPost, OnGrenadeImpactTouchPost);
                }
                case C_GRENADE_MODE_PROXIMITY:
                {
                    DataPack hPack;
                    
                    // Set the grenade as infinite
                    CreateTimer(0.1, OnGrenadeTimerSetInfinite, EntIndexToEntRef(iGrenade), TIMER_FLAG_NO_MAPCHANGE);
                    
                    // Set the grenade think function
                    CreateDataTimer(0.1, OnGrenadeProximityTimerThink, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                    
                    // Prepare the datapack
                    // -------------------------
                    // int iGrenadeReference
                    // int iGrenadeState
                    // int iGrenadeCounter
                    hPack.WriteCell(EntIndexToEntRef(iGrenade));
                    hPack.WriteCell(C_PROXIMITY_STATE_WAIT_IDLE);
                    hPack.WriteCell(0);
                }
                case C_GRENADE_MODE_TRIPWIRE:
                {
                    // Set the grenade as infinite
                    CreateTimer(0.1, OnGrenadeTimerSetInfinite, EntIndexToEntRef(iGrenade), TIMER_FLAG_NO_MAPCHANGE);
                    
                    // Hook the grenade touch function
                    SDKHook(iGrenade, SDKHook_TouchPost, OnGrenadeTripwireTouchPost);
                }
            }
        }
    }
}

// @TODO: It shouldn't work with an enemy smokegrenade.
public Action OnGrenadeTakeDamage(int iGrenade, int &iAttacker, int &iInflictor, float &flDamage, int &iDamagetype)
{
    // Check if the attacker is a player
    if (1 <= iAttacker <= MaxClients)
    {
        // Get the grenade owner
        int iOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
        
        // Check if the owner is still connected and in the same team than the attacker
        if ((1 <= iOwner <= MaxClients) && (GetClientTeam(iAttacker) == GetClientTeam(iOwner)))
        {
            // Don't do damage
            return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Common                                                         */
/* ------------------------------------------------------------------------- */

static void GrenadeSetBreakable(int iGrenade)
{
    // Set the grenade as breakable
    SetEntProp(iGrenade, Prop_Data, "m_takedamage", 2);
    SetEntProp(iGrenade, Prop_Data, "m_iHealth", 1);
}

static void GrenadeDetonate(int iGrenade)
{
    char szClassname[32];
    
    // Get the grenade classname
    GetEdictClassname(iGrenade, szClassname, sizeof(szClassname));
    
    // Check if the grenade is a smoke
    if (StrEqual(szClassname, "smokegrenade_projectile"))
    {
        float vGrenadeVelocity[3] = {0.0, 0.0, 0.0};
        
        // Stop the grenade velocity
        TeleportEntity(iGrenade, NULL_VECTOR, NULL_VECTOR, vGrenadeVelocity);
        
        // Explode in the next tick
        SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", 1);
    }
    else
    {
        // Set the grenade as breakable
        GrenadeSetBreakable(iGrenade);
        
        // Inflict damage
        SDKHooks_TakeDamage(iGrenade, iGrenade, iGrenade, 10.0);
    }
}

public Action OnGrenadeTimerSetInfinite(Handle hTimer, int iReference)
{
    // Get the grenade index
    int iGrenade = EntRefToEntIndex(iReference);
    
    // Check if the grenade is still valid
    if (iGrenade != INVALID_ENT_REFERENCE)
    {
        // Set the grenade as infinite
        SetEntProp(iGrenade, Prop_Data, "m_nNextThinkTick", -1);
    }
    
    return Plugin_Continue;
}

public Action OnGrenadeTimerDetonate(Handle hTimer, int iReference)
{
    // Get the grenade index
    int iGrenade = EntRefToEntIndex(iReference);
    
    // Check if the grenade is still valid
    if (iGrenade != INVALID_ENT_REFERENCE)
    {
        // Detonate the grenade
        GrenadeDetonate(iGrenade);
    }
    
    return Plugin_Continue;
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Impact                                                         */
/* ------------------------------------------------------------------------- */

public void OnGrenadeImpactTouchPost(int iGrenade, int iOther)
{
    // Check if the grenade touches the world
    if (!iOther)
    {
        // Detonate the grenade
        GrenadeDetonate(iGrenade);
    }
    else
    {
        // Check if the grenade touches a solid entity
        if (GetEntProp(iOther, Prop_Send, "m_nSolidType", 1) && !(GetEntProp(iOther, Prop_Send, "m_usSolidFlags", 2) & 0x0004))
        {
            // Get the grenade owner
            int iOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
            
            // Check if it's not the owner
            if (iOwner != iOther)
            {
                // Detonate the grenade
                GrenadeDetonate(iGrenade);
            }
        }
    }
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Proximity                                                      */
/* ------------------------------------------------------------------------- */

stock Action GrenadeProximityThinkWaitIdle(int  iGrenade, 
                                           int  iGrenadeReference, 
                                           int &rGrenadeState, 
                                           int &rGrenadeCounter)
{
    static float vGrenadeVelocity[3];
    
    // Get the grenade velocity
    GetEntPropVector(iGrenade, Prop_Data, "m_vecVelocity", vGrenadeVelocity);
    
    // Check if the grenade is stationary
    if (GetVectorLength(vGrenadeVelocity) <= 0.0)
    {
        float vGrenadeOrigin[3];
        
        // Get the grenade origin
        GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", vGrenadeOrigin);
        
        // Set the grenade as breakable
        GrenadeSetBreakable(iGrenade);
        
        // Hook the grenade takedamage function
        SDKHook(iGrenade, SDKHook_OnTakeDamage, OnGrenadeTakeDamage);
        
        // Set the grenade next state
        rGrenadeState   = C_PROXIMITY_STATE_POWERUP;
        rGrenadeCounter = RoundFloat(gl_flCvarProximityPowerupTime * 10.0);
    }
    
    return Plugin_Continue;
}

stock Action GrenadeProximityThinkPowerUp(int  iGrenade, 
                                          int  iGrenadeReference, 
                                          int &rGrenadeState, 
                                          int &rGrenadeCounter)
{
    // Check if the grenade is ready
    if (rGrenadeCounter <= 0)
    {
        // Play a sound
        EmitSoundToAll("buttons/blip2.wav", iGrenade, _, SNDLEVEL_CONVO);
        
        // Set the grenade next state
        rGrenadeState   = C_PROXIMITY_STATE_DETECT;
        rGrenadeCounter = 0;
    }
    else if ((rGrenadeCounter % 2) == 0)
    {
        // Determine the pitch
        int iPitch = 200 - rGrenadeCounter * 4;
        
        if (iPitch <= 100)
        {
            iPitch = 100;
        }
        
        // Play a sound
        EmitSoundToAll("buttons/blip1.wav", iGrenade, _, SNDLEVEL_CONVO, _, _, iPitch);
    }
    
    return Plugin_Continue;
}

stock Action GrenadeProximityThinkDetect(int  iGrenade, 
                                         int  iGrenadeReference, 
                                         int &rGrenadeState, 
                                         int &rGrenadeCounter)
{
    static int iOwner;
    
    // Get the grenade owner
    iOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
    
    // Check if the owner is still connected
    if (1 <= iOwner <= MaxClients)
    {
        static int   iOwnerTeam;
        static float vGrenadeOrigin[3];
        static float vPlayerOrigin[3];
        static int   iPlayer;
        static bool  bDetonate;
        
        // Get the owner team
        iOwnerTeam = GetClientTeam(iOwner);
        
        // Get the grenade origin
        GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", vGrenadeOrigin);
        
        // Initialize the context
        iPlayer   = -1;
        bDetonate = false;
        
        // Check if there's a valid player near the grenade
        while (((iPlayer = FindEntityByClassname(iPlayer, "player")) != -1) && !bDetonate)
        {
            if ((1 <= iPlayer <= MaxClients) && (IsPlayerAlive(iPlayer)) && (GetClientTeam(iPlayer) != iOwnerTeam))
            {
                GetEntPropVector(iPlayer, Prop_Send, "m_vecOrigin", vPlayerOrigin);
                
                if (GetVectorDistance(vGrenadeOrigin, vPlayerOrigin) <= 100.0)
                {
                    bDetonate = true;
                }
            }
        }
        
        // Check if the grenade must detonate
        if (bDetonate)
        {
            CreateTimer(0.1, OnGrenadeTimerDetonate, iGrenadeReference, TIMER_FLAG_NO_MAPCHANGE);
            return Plugin_Stop;
        }
        
        // Warn the players
        if (rGrenadeCounter <= 0)
        {
            static int iPlayers[MAXPLAYERS + 1];
            static int iNbPlayers;
            static int iNumPlayer;
            static int iColor;
            
            // Just above the ground..
            vGrenadeOrigin[2] += 2;
            
            // Get all the players in range
            iNbPlayers = GetClientsInRange(vGrenadeOrigin, RangeType_Audibility, iPlayers, MaxClients);
            
            // Send the beacon effect to all the close players
            for (iNumPlayer = 0 ; iNumPlayer < iNbPlayers ; iNumPlayer++)
            {
                iPlayer = iPlayers[iNumPlayer];
                
                // Determine the color of the beacon
                if (iPlayer == iOwner)
                {
                    iColor = gl_iCvarEffectsSelfColor;
                }
                else if (GetClientTeam(iPlayer) == iOwnerTeam)
                {
                    iColor = gl_iCvarEffectsTeammateColor;
                }
                else
                {
                    iColor = gl_iCvarEffectsEnemyColor;
                }
                
                // Prepare the beacon effect
                TE_Start      ("BeamRingPoint");
                TE_WriteVector("m_vecCenter",     vGrenadeOrigin);
                TE_WriteFloat ("m_flStartRadius", 0.0);
                TE_WriteFloat ("m_flEndRadius",   200.0);
                TE_WriteNum   ("m_nModelIndex",   gl_nSpriteBeacon);
                TE_WriteNum   ("m_nHaloIndex",    gl_nSpriteHalo);
                TE_WriteNum   ("m_nStartFrame",   0);
                TE_WriteNum   ("m_nFrameRate",    0);
                TE_WriteFloat ("m_fLife",         0.5);
                TE_WriteFloat ("m_fWidth",        4.0);
                TE_WriteFloat ("m_fEndWidth",     4.0);
                TE_WriteNum   ("r",               (iColor >> 16) & 0xFF);
                TE_WriteNum   ("g",               (iColor >>  8) & 0xFF);
                TE_WriteNum   ("b",               (iColor      ) & 0xFF);
                TE_WriteNum   ("a",               255);
                TE_WriteNum   ("m_nFadeLength",   0);
                
                // Send the beacon effect to the player
                TE_SendToClient(iPlayer);
            }
            
            rGrenadeCounter = 10; // 1.0 sec
        }
    }
    else
    {
        // Detonate the grenade
        CreateTimer(GetRandomFloat(0.5, 2.0), OnGrenadeTimerDetonate, iGrenadeReference, TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public Action OnGrenadeProximityTimerThink(Handle hTimer, DataPack hPack)
{
    static int    iGrenadeReference;
    static int    iGrenade;
    static int    iGrenadeState;
    static int    iGrenadeCounter;
    static Action iTimerAction;
    
    // Read the datapack
    ResetPack(hPack);
    iGrenadeReference = hPack.ReadCell();
    iGrenade          = EntRefToEntIndex(iGrenadeReference);
    iGrenadeState     = hPack.ReadCell();
    iGrenadeCounter   = hPack.ReadCell();
    
    // By default, exit the timer
    iTimerAction = Plugin_Stop;
    
    // Check if the grenade is still valid
    if (iGrenade != INVALID_ENT_REFERENCE)
    {
        // Decrement the grenade counter
        if (iGrenadeCounter > 0)
        {
            iGrenadeCounter--;
        }
        
        // Execute the grenade think function
        switch (iGrenadeState)
        {
            case C_PROXIMITY_STATE_WAIT_IDLE:
            {
                iTimerAction = GrenadeProximityThinkWaitIdle(iGrenade, iGrenadeReference, iGrenadeState, iGrenadeCounter);
            }
            case C_PROXIMITY_STATE_POWERUP:
            {
                iTimerAction = GrenadeProximityThinkPowerUp(iGrenade, iGrenadeReference, iGrenadeState, iGrenadeCounter);
            }
            case C_PROXIMITY_STATE_DETECT:
            {
                iTimerAction = GrenadeProximityThinkDetect(iGrenade, iGrenadeReference, iGrenadeState, iGrenadeCounter);
            }
        }
        
        // Write the datapack
        if (iTimerAction == Plugin_Continue)
        {
            ResetPack(hPack, true);
            hPack.WriteCell(iGrenadeReference);
            hPack.WriteCell(iGrenadeState);
            hPack.WriteCell(iGrenadeCounter);
        }
    }
    
    return iTimerAction;
}

/* ------------------------------------------------------------------------- */
/* Grenade :: Tripwire                                                       */
/* ------------------------------------------------------------------------- */

public bool OnGrenadeTripwireTraceFilterNoPlayer(int iEntity, int iContentsMask, any iData)
{
    return (iEntity == view_as<int>(iData) || 1 <= iEntity <= MaxClients) ? false : true;
}

stock void GrenadeTripwireTrackWall(int iGrenade)
{
    float vTracker[6][3] = {{ 0.0,  0.0,  5.0},
                            { 0.0,  5.0,  0.0},
                            { 5.0,  0.0,  0.0},
                            { 0.0,  0.0, -5.0},
                            { 0.0, -5.0,  0.0},
                            {-5.0,  0.0,  0.0}};
    
    Handle hTrace;
    float  vGrenadeOrigin[3];
    float  vEndPoint[3];
    float  vNormal[3];
    
    int    iIndex;
    float  flFraction;
    float  flBestFraction;
    
    // Get the grenade origin
    GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", vGrenadeOrigin);
    
    // Search the best fraction
    flBestFraction = 1.0;
    
    for (iIndex = 0 ; iIndex < 6 ; iIndex++)
    {
        vEndPoint[0] = vTracker[iIndex][0] + vGrenadeOrigin[0];
        vEndPoint[1] = vTracker[iIndex][1] + vGrenadeOrigin[1];
        vEndPoint[2] = vTracker[iIndex][2] + vGrenadeOrigin[2];
        
        hTrace     = TR_TraceRayFilterEx(vGrenadeOrigin, vEndPoint, MASK_SOLID, RayType_EndPoint, OnGrenadeTripwireTraceFilterNoPlayer, iGrenade);
        flFraction = TR_GetFraction(hTrace);
        
        if (flBestFraction > flFraction)
        {
            flBestFraction = flFraction;
            TR_GetPlaneNormal(hTrace, vNormal);
        }
        
        CloseHandle(hTrace);
    }
    
    // Check if the fraction is good
    if (flBestFraction < 1.0)
    {
        DataPack hPack;
        
        // Set the grenade think function
        CreateDataTimer(0.1, OnGrenadeTripwireTimerThink, hPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        
        // Prepare the datapack
        // -------------------------
        // int   iGrenadeReference
        // float vGrenadeNormal[3]
        // int   iGrenadeState
        // int   iGrenadeCounter
        hPack.WriteCell(EntIndexToEntRef(iGrenade));
        hPack.WriteFloat(vNormal[0]);
        hPack.WriteFloat(vNormal[1]);
        hPack.WriteFloat(vNormal[2]);
        hPack.WriteCell(C_TRIPWIRE_STATE_POWERUP);
        hPack.WriteCell(RoundFloat(gl_flCvarTripwirePowerupTime * 10.0));
        
        // Unhook the grenade touch function
        SDKUnhook(iGrenade, SDKHook_TouchPost, OnGrenadeTripwireTouchPost);
        
        // Block the grenade
        SetEntityMoveType(iGrenade, MOVETYPE_NONE);
        
        // Set the grenade breakable
        GrenadeSetBreakable(iGrenade);
        
        // Hook the grenade takedamage function
        SDKHook(iGrenade, SDKHook_OnTakeDamage, OnGrenadeTakeDamage);
    }
}

public void OnGrenadeTripwireTouchPost(int iGrenade, int iOther)
{
    // Check if the grenade touches the world
    if (!iOther)
    {
        // Search a wall near the grenade
        GrenadeTripwireTrackWall(iGrenade);
    }
    // Check if the grenade touches a solid entity (But not a player)
    else if ((iOther > MaxClients) && (GetEntProp(iOther, Prop_Send, "m_nSolidType", 1) && !(GetEntProp(iOther, Prop_Send, "m_usSolidFlags", 2) & 0x0004)))
    {
        // Search a wall near the grenade
        GrenadeTripwireTrackWall(iGrenade);
    }
}

stock Action GrenadeTripwireThinkPowerUp(int    iGrenade, 
                                         int    iGrenadeReference, 
                                         float  vGrenadeNormal[3],
                                         int   &rGrenadeState, 
                                         int   &rGrenadeCounter)
{
    // Check if the grenade is ready
    if (rGrenadeCounter <= 0)
    {
        // Play a sound
        EmitSoundToAll("buttons/blip2.wav", iGrenade, _, SNDLEVEL_CONVO);
        
        // Set the grenade next state
        rGrenadeState   = C_TRIPWIRE_STATE_DETECT;
        rGrenadeCounter = 0;
    }
    else if ((rGrenadeCounter % 2) == 0)
    {
        // Determine the pitch
        int iPitch = 200 - rGrenadeCounter * 4;
        
        if (iPitch <= 100)
        {
            iPitch = 100;
        }
        
        // Play a sound
        EmitSoundToAll("buttons/blip1.wav", iGrenade, _, SNDLEVEL_CONVO, _, _, iPitch);
    }
    
    return Plugin_Continue;
}

public bool OnGrenadeTripwireTraceFilter(int iEntity, int iContentsMask, any iData)
{
    return (iEntity == view_as<int>(iData)) ? false : true;
}

stock Action GrenadeTripwireThinkDetect(int    iGrenade, 
                                        int    iGrenadeReference, 
                                        float  vGrenadeNormal[3],
                                        int   &rGrenadeState, 
                                        int   &rGrenadeCounter)
{
    static int iOwner;
    
    // Get the grenade owner
    iOwner = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
    
    // Check if the owner is still connected
    if (1 <= iOwner <= MaxClients)
    {
        static int    iOwnerTeam;
        static float  vGrenadeOrigin[3];
        static float  vGrenadeEndPoint[3];
        static Handle hTrace;
        static int    iEntityHit;
        static bool   bDetonate;
        
        // Get the owner team
        iOwnerTeam = GetClientTeam(iOwner);
        
        // Get the grenade origin
        GetEntPropVector(iGrenade, Prop_Send, "m_vecOrigin", vGrenadeOrigin);
        
        // Initialize the context
        bDetonate = false;
        
        // Check if there's a valid player in the grenade tripwire
        vGrenadeEndPoint[0] = vGrenadeNormal[0] * 8192.0 + vGrenadeOrigin[0];
        vGrenadeEndPoint[1] = vGrenadeNormal[1] * 8192.0 + vGrenadeOrigin[1];
        vGrenadeEndPoint[2] = vGrenadeNormal[2] * 8192.0 + vGrenadeOrigin[2];
        
        hTrace = TR_TraceRayFilterEx(vGrenadeOrigin, vGrenadeEndPoint, MASK_SOLID, RayType_EndPoint, OnGrenadeTripwireTraceFilter, iGrenade);
        
        if (TR_GetFraction(hTrace) < 1.0)
        {
            TR_GetEndPosition(vGrenadeEndPoint, hTrace);
            iEntityHit = TR_GetEntityIndex(hTrace);
            
            if ((1 <= iEntityHit <= MaxClients) && (IsPlayerAlive(iEntityHit)) && (GetClientTeam(iEntityHit) != iOwnerTeam))
            {
                bDetonate = true;
            }
        }
        
        CloseHandle(hTrace);
        
        // Check if the grenade must detonate
        if (bDetonate)
        {
            CreateTimer(0.1, OnGrenadeTimerDetonate, iGrenadeReference, TIMER_FLAG_NO_MAPCHANGE);
            return Plugin_Stop;
        }
        
        // Warn the players
        if (rGrenadeCounter <= 0)
        {
            static int iPlayers[MAXPLAYERS + 1];
            static int iNbPlayers;
            static int iNumPlayer;
            static int iPlayer;
            static int iColor;
            
            // Get all the players in range
            iNbPlayers = GetClientsInRange(vGrenadeOrigin, RangeType_Audibility, iPlayers, MaxClients);
            
            // Send the beam effect to all the close players
            for (iNumPlayer = 0 ; iNumPlayer < iNbPlayers ; iNumPlayer++)
            {
                iPlayer = iPlayers[iNumPlayer];
                
                // Determine the color of the beam
                if (iPlayer == iOwner)
                {
                    iColor = gl_iCvarEffectsSelfColor;
                }
                else if (GetClientTeam(iPlayer) == iOwnerTeam)
                {
                    iColor = gl_iCvarEffectsTeammateColor;
                }
                else
                {
                    iColor = gl_iCvarEffectsEnemyColor;
                }
                
                // Create the beam effect
                TE_Start      ("BeamEntPoint");
                TE_WriteNum   ("m_nStartEntity", iGrenade);
                TE_WriteVector("m_vecEndPoint",  vGrenadeEndPoint);
                TE_WriteNum   ("m_nModelIndex",  gl_nSpriteBeam);
                TE_WriteNum   ("m_nHaloIndex",   gl_nSpriteHalo);
                TE_WriteNum   ("m_nStartFrame",  0);
                TE_WriteNum   ("m_nFrameRate",   0);
                TE_WriteFloat ("m_fLife",        0.1);
                TE_WriteFloat ("m_fWidth",       8.0);
                TE_WriteFloat ("m_fEndWidth",    8.0);
                TE_WriteNum   ("r",              (iColor >> 16) & 0xFF);
                TE_WriteNum   ("g",              (iColor >>  8) & 0xFF);
                TE_WriteNum   ("b",              (iColor      ) & 0xFF);
                TE_WriteNum   ("a",              255);
                TE_WriteNum   ("m_nFlags",       FBEAM_STARTENTITY);
                TE_WriteNum   ("m_nFadeLength",  0);
                
                // Send the beam effect to the player
                TE_SendToClient(iPlayer);
            }
            
            rGrenadeCounter = 1; // 0.1 sec
        }
    }
    else
    {
        // Detonate the grenade
        CreateTimer(GetRandomFloat(0.5, 2.0), OnGrenadeTimerDetonate, iGrenadeReference, TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

public Action OnGrenadeTripwireTimerThink(Handle hTimer, DataPack hPack)
{
    static int    iGrenadeReference;
    static int    iGrenade;
    static float  vGrenadeNormal[3];
    static int    iGrenadeState;
    static int    iGrenadeCounter;
    static Action iTimerAction;
    
    // Read the datapack
    ResetPack(hPack);
    iGrenadeReference = hPack.ReadCell();
    iGrenade          = EntRefToEntIndex(iGrenadeReference);
    vGrenadeNormal[0] = hPack.ReadFloat();
    vGrenadeNormal[1] = hPack.ReadFloat();
    vGrenadeNormal[2] = hPack.ReadFloat();
    iGrenadeState     = hPack.ReadCell();
    iGrenadeCounter   = hPack.ReadCell();

    // By default, exit the timer
    iTimerAction = Plugin_Stop;
    
    // Check if the grenade is still valid
    if (iGrenade != INVALID_ENT_REFERENCE)
    {
        // Decrement the grenade counter
        if (iGrenadeCounter > 0)
        {
            iGrenadeCounter--;
        }
        
        // Execute the grenade think function
        switch (iGrenadeState)
        {
            case C_TRIPWIRE_STATE_POWERUP:
            {
                iTimerAction = GrenadeTripwireThinkPowerUp(iGrenade, iGrenadeReference, vGrenadeNormal, iGrenadeState, iGrenadeCounter);
            }
            case C_TRIPWIRE_STATE_DETECT:
            {
                iTimerAction = GrenadeTripwireThinkDetect(iGrenade, iGrenadeReference, vGrenadeNormal, iGrenadeState, iGrenadeCounter);
            }
        }
        
        // Write the datapack
        if (iTimerAction == Plugin_Continue)
        {
            ResetPack(hPack, true);
            hPack.WriteCell(EntIndexToEntRef(iGrenade));
            hPack.WriteFloat(vGrenadeNormal[0]);
            hPack.WriteFloat(vGrenadeNormal[1]);
            hPack.WriteFloat(vGrenadeNormal[2]);
            hPack.WriteCell(iGrenadeState);
            hPack.WriteCell(iGrenadeCounter);
        }
    }
    
    return iTimerAction;
}

/* ========================================================================= */
