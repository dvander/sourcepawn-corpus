/*	corrected line 142 -  BOT 
	bumped version to 1.2
 */
#include <sourcemod>
#include <sdktools_functions>
#include <gungame>

#pragma semicolon 1

#define BUYLEVEL_VERSION          "1.2"

#define MAX_FUNDS                 16000
#define DEFAULT_KILL_VALUE        300
#define DEFAULT_TEAMKILL_PENALTY  2700


/*******************************\
            Globals   
\*******************************/
new PlayerFunds[MAXPLAYERS+1];
new accountOffset = -1;
new bool:gameOver = false;


/*******************************\
         Convar Handles   
\*******************************/
new Handle:kill_value = INVALID_HANDLE;
new Handle:level_cost = INVALID_HANDLE;
new Handle:restricted_weapons = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "SM GunGame Buylevel",
	author = "{cDS} Artsemis",
	description = "Buylevel for GunGame:SM",
	version = BUYLEVEL_VERSION,
	url = "http://www.cyberdeathsquad.com/"
};

public OnPluginStart()
{
  // Set up the convars
  CreateConVar("sm_gg_buylevel_version", BUYLEVEL_VERSION, "Buylevel Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  
  kill_value            = CreateConVar("sm_buylevel_kill_value", "1600", "Amount of money to award for a kill");
  level_cost            = CreateConVar("sm_buylevel_level_cost", "8000", "Amount of money required to buy a level");
  restricted_weapons    = CreateConVar("sm_buylevel_restricted_weapons", "hegrenade,knife", "Comma-delimited list of weapon short names that cannot be skipped (see http://wiki.alliedmods.net/CS_Weapons_Information for weapon names).");
  
  // Autogenerate a config file in the gungame config directory if it doesn't exist
  AutoExecConfig(true, "buylevel", "gungame");
  
  // Hook commands and events
  RegConsoleCmd("sm_buylevel", Command_Buylevel);
  HookEvent("player_spawn", Event_PlayerSpawn);
  
  // Get the m_iAccount offset so we can access the in-game display
  accountOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
  
  // If accountOffset is -1, we weren't able to locate the offset needed to adjust funds
  if (accountOffset == -1)
  {
    ThrowError("[SM] Buylevel was unable to locate the correct account offset.");
  }
}


/*******************************\
             Commands   
\*******************************/

/**
 * Called when a player uses sm_buylevel in console or one of the following chat commands:
 * [Announced]: !sm_buylevel, !buylevel    [Silent]: /sm_buylevel, /buylevel
 *  - If the player has enough funds and is on a level that is allowed to be bought off of,
 *    this command will award the player with the level and deduct funds from their account.
 */
public Action:Command_Buylevel(client, args)
{  
  // Make sure the admin console (client=0) isn't the one initiating the command. We'll go ahead
  // and check that it's not outside the valid range of client indexes as a sanity check too.
  if(client < 1 || client > MAXPLAYERS)
  {
    ReplyToCommand(client, "\x04[Buylevel] This command is for players only.");
    return Plugin_Handled;
  }
  
  // Don't allow a player to buy a level during the warmup round
  if(GG_IsWarmupInProgress())
  {
    ReplyToCommand(client, "\x04[Buylevel] You cannot buy a level during the warmup round.");
    return Plugin_Handled;
  }
  
  // Don't allow a player to buy a level after the game is over
  if(gameOver)
  {
    ReplyToCommand(client, "\x04[Buylevel] You cannot buy a level after the game is over.");
    return Plugin_Handled;
  }
  
  // Make sure the client is allowed to buy off their current level    
  new String:currentWeapon[64];
  new String:restricted_weapons_list[255];
  
  GG_GetLevelWeaponName(GG_GetClientLevel(client), currentWeapon, sizeof(currentWeapon));
  GetConVarString(restricted_weapons, restricted_weapons_list, sizeof(restricted_weapons_list));
  
  if(StrContains(restricted_weapons_list, currentWeapon, false) != -1){
    ReplyToCommand(client, "\x04[Buylevel] You cannot buy off of the %s level.", currentWeapon);
    return Plugin_Handled;
  }
  
  /*if((clientLevel + GetConVarInt(2)) > maxLevel)
  {
    ReplyToCommand(client, "\x04[Buylevel] You cannot buy off of this level.");
    return Plugin_Handled;
  }
  */
  
  // Check if the client has enough funds
  if(PlayerFunds[client] < GetConVarInt(level_cost))
  {
    ReplyToCommand(client, "\x04[Buylevel] You need $%d to buy a level.", GetConVarInt(level_cost));
    return Plugin_Handled;
  }
  
  // Deduct the funds, update the display, and level the player up
  PlayerFunds[client] -= GetConVarInt(level_cost);
  setFundsDisplay(client, PlayerFunds[client]);
  GG_AddALevel(client);
  
  return Plugin_Handled;
}


/*******************************\
             Callbacks   
\*******************************/

/**
 * Called when a player dies
 *  - Awards the killer with appropriate funds as long as it wasn't a teamkill
 */
public Action:GG_OnClientDeath(killer, victim, WeaponId, bool:TeamKilled)
{
  // If this was a teamkill, we need to refund the built-in funds penalty
  if(TeamKilled)
  {
    setFundsDisplay(killer, PlayerFunds[killer] + DEFAULT_TEAMKILL_PENALTY);
    return Plugin_Continue;
  }
  
  // If this kill was during the warmup round, we don't want to award the funds but
  // we still want to deduct the built-in kill funds from the display
  if(GG_IsWarmupInProgress()){
    setFundsDisplay(killer, PlayerFunds[killer] - DEFAULT_KILL_VALUE);
    return Plugin_Continue;
  }
  
  // Calculate the player's new total funds
  new adjustedFunds = PlayerFunds[killer] + GetConVarInt(kill_value);
  
  if(adjustedFunds > MAX_FUNDS)
    adjustedFunds = MAX_FUNDS;
    
  // Store the new funds total and update the display
  PlayerFunds[killer] = adjustedFunds;
  setFundsDisplay(killer, adjustedFunds - DEFAULT_KILL_VALUE);

  return Plugin_Continue;
}

/**
 * Called when a new map starts
 *  - Empties the funds associated with all player slots
 */
public OnMapStart()
{
  gameOver = false;
  emptyAllAccounts();
}

/**
 * Called when a player joins the server
 *  - Empties the funds associated with the player slot
 */
public OnClientPutInServer(client)
{
  emptyAccount(client);
}

/**
 * Called when a player spawns
 *  - Syncronizes the player's in-game funds display with thier actual money
 *    so that money awarded at the start of a round to a team is removed
 */
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new userId = GetEventInt(event, "userid");
  new client = GetClientOfUserId(userId);
  
  setFundsDisplay(client, PlayerFunds[client]);
}

/**
 * Called when we have a GunGame winner
 *  - Disables buying of levels until the next game starts
 */
public GG_OnWarmupEnd()
{
  PrintToChatAll("\x04Buylevel is currently running!");
  PrintToChatAll("\x04Type !buylevel in chat when you have $%d to buy a level.", GetConVarInt(level_cost));
}

/**
 * Called when we have a GunGame winner
 *  - Disables buying of levels until the next game starts
 */
public GG_OnWinner(client, const String:Weapon[])
{
  gameOver = true;
}


/*******************************\
             Helpers   
\*******************************/

/**
 * Empties the funds associated with a player slot
 * @param client      Player index to empty funds for
 */
emptyAccount(client)
{
  PlayerFunds[client] = 0;
  SetEntData(client, accountOffset, 0);
}

/**
 * Empties the funds associated with all player slots
 */
emptyAllAccounts()
{
  for( new i = 1; i <= MaxClients; i++ ) {
    new tempClient = GetClientOfUserId(i);
    emptyAccount(tempClient);
  }
}

/**
 * Updates the in-game funds display.
 * @param client      The player who's funds we want to update
 * @param amount      The value to set the funds to
 */
setFundsDisplay(client, amount)
{
  new String:name[MAX_NAME_LENGTH];
  GetClientName(client, name, sizeof(name));
  SetEntData(client, accountOffset, amount);
}