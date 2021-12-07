#include <sourcemod>
#include <sdktools>

#define MAX_PLAYERS 32
#define PL_VERSION "1.0.7"

// Orginial credit goes to Dean Poot for his save teleport locations plugin
// URL: http://forums.alliedmods.net/showthread.php?p=508657

// Definitions
new g_teleportsLeft[MAX_PLAYERS]; // Client teleports left array
new Handle:g_hNumOfTeleports; // Handle for number of allowed teleports
new Handle:g_hPluginAnnounce; // Handle for plugin announcement
new Handle:ClientDelayTimers[MAX_PLAYERS]; // Timers for teleport delays on clients

public Plugin:myinfo = 
{
	name = "L4D2 Unstick",
	author = "HowIChrgeLazer (rewrited by V10)",
	description = "Allows players to get themselves unstuck from charger glitches and level clips",
	version = PL_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=110041"
}

public OnPluginStart()
{	
  // Cvar for plugin version
  CreateConVar("l4d2unstick_version", PL_VERSION, "L4D2 Unstuck", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  
  // Cvar for number of teleports a client can have
  g_hNumOfTeleports = CreateConVar("l4d2unstick_teleports", "2", "Amount of times the client can use !stuck per map", FCVAR_PLUGIN)
  g_hPluginAnnounce = CreateConVar("l4d2unstick_announce", "1", "Announces at each map start that the !stuck command is available", FCVAR_PLUGIN)
  
  // Say command hooks
  RegConsoleCmd("stuck", Command_Stuck);
  RegAdminCmd("sm_unstick", Cmd_Unstick, ADMFLAG_GENERIC);
}

public OnMapStart()
{
  if(GetConVarInt(g_hPluginAnnounce) == 1)
  {
    CreateTimer(240.0, StuckPluginAnnounce,_,TIMER_REPEAT + TIMER_FLAG_NO_MAPCHANGE);
  }  
}

public OnClientPutInServer(client)
{
  //Initalize location and teleport amount values for client
  g_teleportsLeft[client] = GetConVarInt(g_hNumOfTeleports); // Number of teleports for client
  // Lets check if we're allowing annoucements
}

public OnClientDisconnect(client)
{
  if (ClientDelayTimers[client] != INVALID_HANDLE)
  {
    KillTimer(ClientDelayTimers[client]);
    ClientDelayTimers[client] = INVALID_HANDLE;
  }
}

public Action:Command_Stuck(client,args)
{
  if(client != 0)
  {
    // We're checking for client to say !stuck here, also check if client is hanging from a ledge
    new CheckLedge = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
    if(g_teleportsLeft[client] > 0 && CheckLedge == 0)
    {
      PrintToChat (client, "[SM] Unsticking in 3 seconds...");
      ClientDelayTimers[client] = CreateTimer(3.0, DelayTeleport, client);
    }
    else if(g_teleportsLeft[client] == 0 && CheckLedge != 1)
    {
      // Client has 0 teleports left
      //
      PrintToChat (client, "[SM] You are out of teleports this round!");
    }
    else if(CheckLedge == 1)
    {
      // Client is hanging from a ledge
      PrintToChat (client, "[SM] You cannot use !stuck right now!");
    }
  }	
}

public Action:DelayTeleport(Handle:timer, any:client)
{
  Teleport_User(client);
  
  // Notify the client that they have been unstuck and take away a teleport use
  //
  g_teleportsLeft[client] = g_teleportsLeft[client] - 1;
  if(g_teleportsLeft[client] > 1 || g_teleportsLeft[client] == 0)
  {
    PrintToChat (client, "[SM] You have been unstuck! You have \"%i\" attempts left this map.", g_teleportsLeft[client]);
  }
  else
  {
    PrintToChat (client, "[SM] You have been unstuck! You have \"%i\" attempt left this map.", g_teleportsLeft[client]);
  }
  ClientDelayTimers[client] = INVALID_HANDLE;  
}
	
Teleport_User(client)
{
  // Client has teleports left. Get client's orgin and teleport him/her away while in noclip.
  //
  new Float:Origin[3];
  GetClientAbsOrigin(client, Origin);
  Origin[0] = Origin[0] + 4;
  Origin[1] = Origin[1] + 4;
  Origin[2] = Origin[2] + 4;
  SetEntityMoveType(client, MOVETYPE_NOCLIP);
  TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
  SetEntityMoveType(client, MOVETYPE_WALK);  
}

public Action:StuckPluginAnnounce(Handle:timer)
{
  // Announcement message
  PrintToChatAll ("[SM] Survivors: If you become glitched and unable to move, type !stuck during the round to free yourself.");
}

public Action:Cmd_Unstick(client, args)
{	
  // This is the function that allows admins to unstick players
  
  if (args < 1)
  {
    PrintToConsole(client, "Usage: sm_unstick <name>");
    return Plugin_Continue;
	}
  
  new String:arg1[32]
 
  /* Get the first argument */
  GetCmdArg(1, arg1, sizeof(arg1));
  
  /* Try and find a matching player */
  new target = FindTarget(client, arg1);
  if (target == -1)
  {
    /* FindTarget() automatically replies with the 
    * failure reason.
    */
    return Plugin_Continue;
  }
  
  // teleport him/her 
  Teleport_User(target);
  
  ReplyToCommand(client, "[SM] You unstuck %N", target);
  
  return Plugin_Continue;
}