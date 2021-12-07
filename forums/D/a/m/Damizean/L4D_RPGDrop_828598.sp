/* ========================================================
 * L4D RPG Drop
 * ========================================================
 *
 * Created by Damizean
 * --------------------------------------------------------
 *
 * This plugin allows the special infected to drop an item
 * based upon a ratio system. Quite easy to configure and use.
 */

// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1                 // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
#define RPGDROP_HUNTER_OFFSET      0
#define RPGDROP_SMOKER_OFFSET      6
#define RPGDROP_BOOMER_OFFSET      12
#define RPGDROP_TANK_OFFSET        18

#define RPGDROP_WEAPON             0
#define RPGDROP_FIRST_AID_KIT      1
#define RPGDROP_PAIN_PILLS         2
#define RPGDROP_MOLOTOV            3
#define RPGDROP_PIPE_BOMB          4
#define RPGDROP_NOTHING            5

// *********************************************************************************
// VARS
// *********************************************************************************
// Declarate the convar handlers for operating with them and hook to their callbacks.
new Handle:RPGDrop_Variables[24];
new Float:RPGDrop_Rates[24];

new Handle:RPGDrop_EnableCvar;
new RPGDrop_Enabled;
new RPGDrop_PreviousState;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
    name        = "L4D RPG Drop",
    author      = "Damizean",
    description = "Plugin for simulating a RPG drop system for special infected.",
    version     = "1.0.3",
    url         = "elgigantedeyeso@gmail.com"
};


// *********************************************************************************
// METHODS
// *********************************************************************************

// =====[ GAME EVENTS ]===================================================

// ------------------------------------------------------------------------
// OnPluginStart()
// ------------------------------------------------------------------------
public OnPluginStart()
{
    // Declarate the plugin convars.
    RPGDrop_Variables[00] = CreateConVar("l4d_rpg_hunter_weapon",       "1.00",  "RPG dropping - Rate for a Hunter to drop a weapon.",        FCVAR_PLUGIN);
    RPGDrop_Variables[01] = CreateConVar("l4d_rpg_hunter_aidkit",       "1.00",  "RPG dropping - Rate for a Hunter to drop First Aid Kit.",   FCVAR_PLUGIN);
    RPGDrop_Variables[02] = CreateConVar("l4d_rpg_hunter_pain_pills",   "4.00",  "RPG dropping - Rate for a Hunter to drop Pain Pills.",      FCVAR_PLUGIN);
    RPGDrop_Variables[03] = CreateConVar("l4d_rpg_hunter_molotov",      "9.00",  "RPG dropping - Rate for a Hunter to drop a Molotov.",       FCVAR_PLUGIN);
    RPGDrop_Variables[04] = CreateConVar("l4d_rpg_hunter_pipe_bomb",    "9.00",  "RPG dropping - Rate for a Hunter to drop a Pipe Bomb.",     FCVAR_PLUGIN);
    RPGDrop_Variables[05] = CreateConVar("l4d_rpg_hunter_nothing",     "76.67",  "RPG dropping - Rate for a Hunter to drop nothing.",         FCVAR_PLUGIN);
    
    RPGDrop_Variables[06] = CreateConVar("l4d_rpg_smoker_weapon",       "1.00",  "RPG dropping - Rate for a Smoker to drop a weapon.",        FCVAR_PLUGIN);
    RPGDrop_Variables[07] = CreateConVar("l4d_rpg_smoker_aidkit",       "1.00",  "RPG dropping - Rate for a Smoker to drop First Aid Kit.",   FCVAR_PLUGIN);
    RPGDrop_Variables[08] = CreateConVar("l4d_rpg_smoker_pain_pills",   "4.00",  "RPG dropping - Rate for a Smoker to drop Pain Pills.",      FCVAR_PLUGIN);
    RPGDrop_Variables[09] = CreateConVar("l4d_rpg_smoker_molotov",      "9.00",  "RPG dropping - Rate for a Smoker to drop a Molotov.",       FCVAR_PLUGIN);
    RPGDrop_Variables[10] = CreateConVar("l4d_rpg_smoker_pipe_bomb",    "9.00",  "RPG dropping - Rate for a Smoker to drop a Pipe Bomb.",     FCVAR_PLUGIN);
    RPGDrop_Variables[11] = CreateConVar("l4d_rpg_smoker_nothing",     "76.67",  "RPG dropping - Rate for a Smoker to drop nothing.",         FCVAR_PLUGIN);
    
    RPGDrop_Variables[12] = CreateConVar("l4d_rpg_boomer_weapon",       "1.00",  "RPG dropping - Rate for a Boomer to drop a weapon.",        FCVAR_PLUGIN);
    RPGDrop_Variables[13] = CreateConVar("l4d_rpg_boomer_aidkit",       "1.00",  "RPG dropping - Rate for a Boomer to drop First Aid Kit.",   FCVAR_PLUGIN);
    RPGDrop_Variables[14] = CreateConVar("l4d_rpg_boomer_pain_pills",   "4.00",  "RPG dropping - Rate for a Boomer to drop Pain Pills.",      FCVAR_PLUGIN);
    RPGDrop_Variables[15] = CreateConVar("l4d_rpg_boomer_molotov",     "18.00",  "RPG dropping - Rate for a Boomer to drop a Molotov.",       FCVAR_PLUGIN);
    RPGDrop_Variables[16] = CreateConVar("l4d_rpg_boomer_pipe_bomb",    "0.00",  "RPG dropping - Rate for a Boomer to drop a Pipe Bomb.",     FCVAR_PLUGIN);
    RPGDrop_Variables[17] = CreateConVar("l4d_rpg_boomer_nothing",     "76.67",  "RPG dropping - Rate for a Boomer to drop nothing.",         FCVAR_PLUGIN);
    
    RPGDrop_Variables[18] = CreateConVar("l4d_rpg_tank_weapon",         "3.00",  "RPG dropping - Rate for a Tank to drop a weapon.",          FCVAR_PLUGIN);
    RPGDrop_Variables[19] = CreateConVar("l4d_rpg_tank_aidkit",        "17.00",  "RPG dropping - Rate for a Tank to drop First Aid Kit.",     FCVAR_PLUGIN);
    RPGDrop_Variables[20] = CreateConVar("l4d_rpg_tank_pain_pills",    "28.00",  "RPG dropping - Rate for a Tank to drop Pain Pills.",        FCVAR_PLUGIN);
    RPGDrop_Variables[21] = CreateConVar("l4d_rpg_tank_molotov",       "23.50",  "RPG dropping - Rate for a Tank to drop a Molotov.",         FCVAR_PLUGIN);
    RPGDrop_Variables[22] = CreateConVar("l4d_rpg_tank_pipe_bomb",     "23.50",  "RPG dropping - Rate for a Tank to drop a Pipe Bomb.",       FCVAR_PLUGIN);
    RPGDrop_Variables[23] = CreateConVar("l4d_rpg_tank_nothing",        "0.00",  "RPG dropping - Rate for a Tank to drop nothing.",           FCVAR_PLUGIN);
    
    // Create enable var
    RPGDrop_EnableCvar = CreateConVar("l4d_rpg_enable",                    "0",  "RPG dropping - Enables or disables it",                     FCVAR_PLUGIN);
    HookConVarChange(RPGDrop_EnableCvar, RPGDrop_EnableManager);
    
    // Regenerate domains
    RPGDrop_Regenerate(RPGDROP_HUNTER_OFFSET);
    RPGDrop_Regenerate(RPGDROP_SMOKER_OFFSET);
    RPGDrop_Regenerate(RPGDROP_BOOMER_OFFSET);
    RPGDrop_Regenerate(RPGDROP_TANK_OFFSET);
    
    // Startup complete.
    RPGDrop_Enabled       = 0;
    RPGDrop_PreviousState = -1;
    
    // Autoexec config
    AutoExecConfig(true, "L4D_RPGDrop");
}

// ------------------------------------------------------------------------
// OnConfigsExecuted()
// ------------------------------------------------------------------------
public OnConfigsExecuted()
{
    // If the configuration changed to something else than the default
    if (RPGDrop_PreviousState != -1) SetConVarInt(RPGDrop_EnableCvar, RPGDrop_PreviousState);
    
    // Enable or disable.
    if (GetConVarInt(RPGDrop_EnableCvar)==0) RPGDrop_Disable();
    else                                     RPGDrop_Enable();
}

// ------------------------------------------------------------------------
// OnMapEnd()
// ------------------------------------------------------------------------
public OnMapEnd()
{
    // Disable drop on map end and retrieve the enabled value for next map.
    RPGDrop_Disable();
    RPGDrop_PreviousState = GetConVarInt(RPGDrop_EnableCvar);
}

// =====[ DROP METHODS ]==================================================

// ------------------------------------------------------------------------
// RPGDrop_EnableManager()
// ------------------------------------------------------------------------
public RPGDrop_EnableManager(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
    // Change the enabled flag to the one the convar holds.
    if (GetConVarInt(RPGDrop_EnableCvar)==0) RPGDrop_Disable();
    else                                     RPGDrop_Enable();
}

// ------------------------------------------------------------------------
// RPGDrop_Enable()
// ------------------------------------------------------------------------
RPGDrop_Enable()
{
    if (RPGDrop_Enabled == 1) return;
    
    // Hook all the cvars to the CVar manager
    for (new i=0; i<sizeof(RPGDrop_Variables); i++) HookConVarChange(RPGDrop_Variables[i], RPGDrop_CVarManager);
    
    // Hook player death event
    HookEvent("player_death", RPGDrop_DeathManager);
    
    // Regenerate player domains
    RPGDrop_Regenerate(RPGDROP_HUNTER_OFFSET);
    RPGDrop_Regenerate(RPGDROP_SMOKER_OFFSET);
    RPGDrop_Regenerate(RPGDROP_BOOMER_OFFSET);
    RPGDrop_Regenerate(RPGDROP_TANK_OFFSET);
    
    // Done
    RPGDrop_Enabled = 1;
    return;
}

// ------------------------------------------------------------------------
// RPGDrop_Disable()
// ------------------------------------------------------------------------
RPGDrop_Disable()
{
    if (RPGDrop_Enabled == 0) return;
    
    // Unhook all the cvars to the CVar manager
    for (new i=0; i<sizeof(RPGDrop_Variables); i++) UnhookConVarChange(RPGDrop_Variables[i], RPGDrop_CVarManager);
    
    // Unhook player death event
    UnhookEvent("player_death", RPGDrop_DeathManager);

    // Done
    RPGDrop_Enabled = 0;
    return;
}

// ------------------------------------------------------------------------
// RPGDrop_CVarManager()
// ------------------------------------------------------------------------
public RPGDrop_CVarManager(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{   
    // Determine wich CVar has changed and it's domain.
    for (new i=0; i<sizeof(RPGDrop_Variables); i++) {
        if (RPGDrop_Variables[i] == hVariable) {
            // Determine domain and regenerate probabilities
            RPGDrop_Regenerate((i / 6)*6);
        }
    }
}

// ------------------------------------------------------------------------
// RPGDrop_Regenerate()
// ------------------------------------------------------------------------
RPGDrop_Regenerate(Domain)
{    
    // Determine the maximum probability
    new Float:Maximum = 0.0;
    for (new i=0; i<6; i++) Maximum += GetConVarFloat(RPGDrop_Variables[Domain+i]);
    
    // Prevent a division by zero
    if (Maximum != 0.0) Maximum = 1.0 / Maximum;
    else                Maximum = 0.0;
    
    // Regenerate the buffers
    RPGDrop_Rates[Domain] = GetConVarFloat(RPGDrop_Variables[Domain])*Maximum;
    for (new i=1; i<6; i++) RPGDrop_Rates[Domain+i] = RPGDrop_Rates[Domain+i-1]+(GetConVarFloat(RPGDrop_Variables[Domain+i])*Maximum);
    
    // Done
}

// ------------------------------------------------------------------------
// RPGDrop_DeathManager()
// ------------------------------------------------------------------------
public Action:RPGDrop_DeathManager(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
    decl String:strBuffer[48];
    new ClientId    = 0;
    new ClientType  = -1;
    new Float:RandomNumber = 1.0;
    new Reward;
    
    // Determine client ID. If there's no client, it means either 
    // it's a common infected, or a witch :3
    ClientId = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if (ClientId == 0) return Plugin_Continue;
    
    // Determine if it's an infected.
    GetEventString(hEvent, "victimname", strBuffer, sizeof(strBuffer));
   
    if (StrEqual("Hunter", strBuffer))      { ClientType = RPGDROP_HUNTER_OFFSET; }
    else if (StrEqual(strBuffer, "Smoker")) { ClientType = RPGDROP_SMOKER_OFFSET; } 
    else if (StrEqual(strBuffer, "Boomer")) { ClientType = RPGDROP_BOOMER_OFFSET; }
    else if (StrEqual(strBuffer, "Tank"))   { ClientType = RPGDROP_TANK_OFFSET;   }

    // If no infected type was found, leave.
    if (ClientType == -1) return Plugin_Continue;
    
    // Now we know wich type of thing it is, determine a random number and see
    // if there's a reward for him.
    SetRandomSeed(GetSysTickCount());
    RandomNumber = GetRandomFloat();
    
    // Determine reward
    if      (RandomNumber >= 0                           && RandomNumber < RPGDrop_Rates[ClientType])   Reward = 0;
    else if (RandomNumber >= RPGDrop_Rates[ClientType]   && RandomNumber < RPGDrop_Rates[ClientType+1]) Reward = 1;
    else if (RandomNumber >= RPGDrop_Rates[ClientType+1] && RandomNumber < RPGDrop_Rates[ClientType+2]) Reward = 2;
    else if (RandomNumber >= RPGDrop_Rates[ClientType+2] && RandomNumber < RPGDrop_Rates[ClientType+3]) Reward = 3;
    else if (RandomNumber >= RPGDrop_Rates[ClientType+3] && RandomNumber < RPGDrop_Rates[ClientType+4]) Reward = 4;
    else if (RandomNumber >= RPGDrop_Rates[ClientType+4])                                               Reward = 5;
    
    // Give the reward.
    switch(Reward) 
    {
        case 0: { 
            switch(GetRandomInt(0, 2))
            {
                case 0: {
                    RPGDrop_ExecuteCommand(ClientId, "give", "autoshotgun");
                }
                case 1: {
                    RPGDrop_ExecuteCommand(ClientId, "give", "rifle");
                }
                case 2: {
                    RPGDrop_ExecuteCommand(ClientId, "give", "hunting_rifle");
                }
            }
            
        }
        case 1: { 
            RPGDrop_ExecuteCommand(ClientId, "give", "first_aid_kit");
        }
        case 2: {
            RPGDrop_ExecuteCommand(ClientId, "give", "pain_pills");
        }
        case 3: {
            RPGDrop_ExecuteCommand(ClientId, "give", "molotov");
        }
        case 4: {
            RPGDrop_ExecuteCommand(ClientId, "give", "pipe_bomb");
        }
    }
    
    // Done
    return Plugin_Continue;
    
}

// ------------------------------------------------------------------------
// RPGDrop_ExecuteCommand()
// ------------------------------------------------------------------------
RPGDrop_ExecuteCommand(Client, String:strCommand[], String:strParam1[])
{
    new Flags = GetCommandFlags(strCommand);
    SetCommandFlags(strCommand, Flags & ~FCVAR_CHEAT);
    FakeClientCommand(Client, "%s %s", strCommand, strParam1);
    SetCommandFlags(strCommand, Flags);
}