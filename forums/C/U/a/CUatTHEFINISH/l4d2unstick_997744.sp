#include <sourcemod>
#include <sdktools>

#define MAX_PLAYERS 19
#define PL_VERSION "1.0.6"

// Orginial credit goes to Dean Poot for his save teleport locations plugin
// URL: http://forums.alliedmods.net/showthread.php?p=508657

// Definitions
new Float:g_Location[MAX_PLAYERS][3]; // Client location array
new g_teleportsLeft[MAX_PLAYERS]; // Client teleports left array
new Handle:g_hNumOfTeleports; // Handle for number of allowed teleports
new Handle:g_hPluginAnnounce; // Handle for plugin announcement
new Handle:ClientDelayTimers[MAX_PLAYERS][2]; // Timers for teleport delays on clients

public Plugin:myinfo = 
{
	name = "L4D2 Unstick",
	author = "HowIChrgeLazer",
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
  RegConsoleCmd("say", Command_Say);
  RegConsoleCmd("say_team", Command_Say);
  RegAdminCmd("sm_unstick", Cmd_Unstick, ADMFLAG_GENERIC);
}

public OnClientPutInServer(client)
{
  // Initalize location and teleport amount values for client
  g_Location[client][0] = 0.0; // X
  g_Location[client][1] = 0.0; // Y
  g_Location[client][2] = 0.0; // Z
  g_teleportsLeft[client] = GetConVarInt(g_hNumOfTeleports); // Number of teleports for client
  // Lets check if we're allowing annoucements
  if(GetConVarInt(g_hPluginAnnounce) == 1)
  {
    ClientDelayTimers[client][1] = CreateTimer(50.0, StuckPluginAnnounce, client);
  }  
}

public OnClientDisconnect(client)
{
  if (ClientDelayTimers[client][0] != INVALID_HANDLE)
  {
    KillTimer(ClientDelayTimers[client][0]);
    ClientDelayTimers[client][0] = INVALID_HANDLE;
  }
  if (ClientDelayTimers[client][1] != INVALID_HANDLE)
  {
    KillTimer(ClientDelayTimers[client][1]);
    ClientDelayTimers[client][1] = INVALID_HANDLE;
  }
}

public Action:Command_Say(client,args)
{
  if(client != 0)
  {
    decl String:szText[192];
    GetCmdArgString(szText, sizeof(szText));
    szText[strlen(szText)-1] = '\0';
    
    new String:szParts[3][16];
    ExplodeString(szText[1], " ", szParts, 3, 16);
    
    // We're checking for client to say !stuck here, also check if client is hanging from a ledge
    new CheckLedge = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
    if((strcmp(szParts[0],"!stuck",false) == 0) && g_teleportsLeft[client] > 0 && CheckLedge == 0)
    {
      PrintToChat (client, "[SM] Unsticking in 3 seconds...");
      ClientDelayTimers[client][0] = CreateTimer(3.0, DelayTeleport, client);
    }
    else if((strcmp(szParts[0],"!stuck",false) == 0) && g_teleportsLeft[client] == 0 && CheckLedge != 1)
    {
      // Client has 0 teleports left
      //
      PrintToChat (client, "[SM] You are out of teleports this round!");
    }
    else if((strcmp(szParts[0],"!stuck",false) == 0) && CheckLedge == 1)
    {
      // Client is hanging from a ledge
      PrintToChat (client, "[SM] You cannot use !stuck right now!");
    }
    else
    {
    }
  }	
}

public Action:DelayTeleport(Handle:timer, any:client)
{
  Teleport_User(client);
}
	
public Action:Teleport_User(client)
{
  // Client has teleports left. Get client's orgin and teleport him/her away while in noclip.
  //
  GetClientAbsOrigin(client, g_Location[client]);
  g_Location[client][0] = g_Location[client][0] + 4;
  g_Location[client][1] = g_Location[client][1] + 4;
  g_Location[client][2] = g_Location[client][2] + 4;
  SetEntityMoveType(client, MOVETYPE_NOCLIP);
  TeleportEntity(client, g_Location[client], NULL_VECTOR, NULL_VECTOR);
  SetEntityMoveType(client, MOVETYPE_WALK);
  
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
  ClientDelayTimers[client][0] = INVALID_HANDLE;
}

public Action:StuckPluginAnnounce(Handle:timer, any:client)
{
  // Announcement message
  PrintToChat (client, "[SM] Survivors: If you become glitched and unable to move, type !stuck during the round to free yourself.");
  ClientDelayTimers[client][1] = INVALID_HANDLE;
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
  // Get client's orgin and teleport him/her away while in noclip.
  //
  GetClientAbsOrigin(target, g_Location[target]);
  g_Location[target][0] = g_Location[target][0] + 4;
  g_Location[target][1] = g_Location[target][1] + 4;
  g_Location[target][2] = g_Location[target][2] + 4;
  SetEntityMoveType(target, MOVETYPE_NOCLIP);
  TeleportEntity(target, g_Location[target], NULL_VECTOR, NULL_VECTOR);
  SetEntityMoveType(target, MOVETYPE_WALK);
  
  new String:name[MAX_NAME_LENGTH];
  
  GetClientName(target, name, sizeof(name));
  ReplyToCommand(client, "[SM] You unstuck %s", name);
  
  return Plugin_Continue;
}