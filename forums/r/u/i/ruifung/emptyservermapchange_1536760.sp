/*
* Empty Server Map Change [ESMC]
*
* ESMC is a (TF2) SourceMod plugin that allows an empty server to change map
* after n minutes. This makes sure a server doesn't gets stuck on a not popular
* map, so nobody will join the server anymore.
*
* ConVars (will be created if no configuration file exists):
* sm_esmc_minutesmapchange <minutes>
* sm_esmc_defaultmapname <mapname>
* sm_esmc_mapchangemode [default|nextmap]
*
* Admin Commands:
* sm_esmc_info (requires privilege of ADMFLAG_CHANGEMAP)
* 
* This plugin is written by Marco 'MacNetron' de Reus for the playstuff.net
* community.
* It is compiled with the SourcePawn Compiler 1.3.6.
*
* www.macnetron.nl / www.playstuff.net
*
*/

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0.RC2"

// Define Plugin information.
public Plugin:myinfo =
{
  name        = "Empty Server Map Change",
  author      = "Marco 'MacNetron' de Reus",
  description = "An empty server will do a map change after n minutes",
  version     = PLUGIN_VERSION,
  url         = "www.macnetron.nl | www.playstuff.net"
}

// Handle with the timer
new Handle:mapChangeTimer;

// Defining the ConVars
new Handle:sm_esmc_minutesmapchange = INVALID_HANDLE;
new Handle:sm_esmc_defaultmapname   = INVALID_HANDLE;
new Handle:sm_esmc_mapchangemode    = INVALID_HANDLE;

// Defining Variables
new String:mapChangeMode[30];

/*
* Overriden from the Sourcemod API: Called when the plugin is fully initialized
* and all known external references are resolved.
*/
public OnPluginStart()
{
  // Define default ConVars
  sm_esmc_minutesmapchange = CreateConVar("sm_esmc_minutesmapchange", "30",
  "Number of minutes after which an empty server will do a map change.");
  sm_esmc_defaultmapname   = CreateConVar("sm_esmc_defaultmapname", "pl_hoodoo_final",
  "Name of the map which will be loaded on a triggered map change.");
  sm_esmc_mapchangemode    = CreateConVar("sm_esmc_mapchangemode", "default",
  "Sets the map changing mode. Possible values: [default|nextmap|off]. 'default' will use the sm_esmc_defaultmapname convar. 'nextmap' will use the current next map. 'off' means the plugin is turned off.");
  
  // Load config file. Param true means it will create a new config file, with
  // above defaults, if no such file exists.
  AutoExecConfig(true, "emptyservermapchange");
  
  // Register an Admin Command to show some info about the settings of ESMC
  RegAdminCmd("sm_esmc_info", Command_ShowInfo, ADMFLAG_CHANGEMAP, "sm_esmc_info");
}


/*
* An Admin Command which will show the values of the ESMC ConVars.
*/
public Action:Command_ShowInfo(client, args)
{
  // Get the ConVars.
  new String:minutesMapChange[30];
  GetConVarString(sm_esmc_minutesmapchange, minutesMapChange, sizeof(minutesMapChange));
  new String:defaultMapName[30];
  GetConVarString(sm_esmc_defaultmapname, defaultMapName, sizeof(defaultMapName));
  GetConVarString(sm_esmc_mapchangemode, mapChangeMode, sizeof(mapChangeMode));
  
  // Print the ConVars to the client who wants the info.
  ReplyToCommand(client, "[ESMC] EmptyServerMapChange version: %s", PLUGIN_VERSION);
  ReplyToCommand(client, "[ESMC] sm_esmc_minutesmapchange    : %s", minutesMapChange);
  ReplyToCommand(client, "[ESMC] sm_esmc_defaultmapname      : %s", defaultMapName);
  ReplyToCommand(client, "[ESMC] sm_esmc_mapchangemode       : %s", mapChangeMode);
  ReplyToCommand(client, "[ESMC] isSourceTvEnabled?          : %b", IsSourceTvEnabled());
  
  // Signal that this Action is done
  return Plugin_Handled;
}


/*
* Overriden from the Sourcemod API: Called when the map has loaded, servercfgfile
* (server.cfg) has been executed, and all plugin configs are done executing.
*/
public OnConfigsExecuted()
{
  // Check if we need to create a timer.
    CreateMapChangeTimer();
}


/*
* Overriden from the Sourcemod API: Called once a client successfully connects.
* @param Client index.
*/
public OnClientConnected(client)
{
  // Check if the Timer is still a valid timer.
  if (mapChangeTimer != INVALID_HANDLE)
  {
    // Stop countdown! Kill the timer! We have a customer!
    PrintToServer("[ESMC] %s", "Kill timer, we have a customer");
    KillTimer(mapChangeTimer);
    mapChangeTimer = INVALID_HANDLE;
  }
}


/*
* Overriden from the Sourcemod API: Called when a client is disconnected from the server.
* @param Client index.
*/
public OnClientDisconnect_Post(client)
{
  // Check if we need to create a timer.
    CreateMapChangeTimer();
}


/*
* DoMapChange will do the actual map change when the Timer hits its trigger.
* @param Handle No idea why it needs a param timer when we use the global defined timer...
*/
public Action:DoMapChange(Handle:timer)
{
  // Check if the Timer is still a valid timer.
  if (mapChangeTimer != INVALID_HANDLE)
  {
    // Kill the timer and set it to invalid.
    KillTimer(mapChangeTimer);
    mapChangeTimer = INVALID_HANDLE;
    
    // Call GetMapChangeName() to get the name of the map we need to change to.
    new String:mapName[30];
    GetMapChangeName(mapName, sizeof(mapName));
    
    PrintToServer("[ESMC] Map change triggered, changing map to %s", mapName);
    
    // Change map with ForceChangeLevel.
    ForceChangeLevel(mapName, "Empty Server Map Change: timer triggered map change");
  }
}


/*
* CreateMapChangeTimer will, if the server is empty, create a timer based on the
* value defined by ConVar 'sm_esmc_minutesmapchange'.
*/
CreateMapChangeTimer()
{
  // Get the mapChangeMode out of the ConVar.
  GetConVarString(sm_esmc_mapchangemode, mapChangeMode, sizeof(mapChangeMode));
  
  if (StrEqual(mapChangeMode, "off")) {
    PrintToServer("[ESMC] %s", "sm_esmc_mapchangemode is off, so don't check if a timer needs to be created");
    return;
  }
  
  // Check if the server is empty. The parameter false means that also clients
  // connecting but not yet on the server are taken into account.
  new bool:bTvEnabled = IsSourceTvEnabled();
  if ( ( GetClientCount(false) == 0 && !bTvEnabled ) ||
  ( GetClientCount(false) == 1 && bTvEnabled ) ) {
    PrintToServer("[ESMC] %s", "No clients ingame and no clients connecting");
    
    // Get the minutesMapChange out of the ConVar and convert to seconds
    // for the timer.
    new minutesMapChange = GetConVarInt(sm_esmc_minutesmapchange);
    new Float:secondsMapChange = minutesMapChange * 60.0;
    
    // Get the mapChangeMode out of the ConVar for logging purposes.
    GetConVarString(sm_esmc_mapchangemode, mapChangeMode, sizeof(mapChangeMode));
    
    // Call GetMapChangeName() to get the name of the map. Check if the 
    new String:cmapName[30];
    GetCurrentMap(cmapName, sizeof(cmapName))
    new String:mapName[30];
    GetMapChangeName(mapName, sizeof(mapName));
    if (StrEqual(cmapName, mapName))
   {
    PrintToServer("[ESMC] Current map matches next map, no change needed");
   }
    else
   {
    // Create the timer and define the function to call when
    // the timer hits its trigger.
    mapChangeTimer = CreateTimer(secondsMapChange, DoMapChange);
    PrintToServer("[ESMC] Timer created, map change after %d minutes, based on mode %s, going to %s", minutesMapChange, mapChangeMode, mapName);
   }
  }
}


/**
* GetMapChangeName will return a name of a map, based on the mode defined
* by ConVar 'sm_esmc_mapchangemode'.
* @param mapName String in which the name of the map will be returned.
* @param maxlen Should be sizeof(mapName).
* @return String with the map name.
*/
GetMapChangeName(String:mapName[], maxlen)
{
  // Get the mapChangeMode out of the ConVar.
  GetConVarString(sm_esmc_mapchangemode, mapChangeMode, sizeof(mapChangeMode));
  
  //new String:mapName[30];
  
  // Now determine the name of the map, based on the mapChangeMode
  if (StrEqual(mapChangeMode, "default"))
  {
    // 'default' means we take the name out of the ConVar.
    GetConVarString(sm_esmc_defaultmapname, mapName, maxlen);
  }
  else if (StrEqual(mapChangeMode, "nextmap"))
  {
    // 'nextmap' means we just take the nextmap of the server.
    GetNextMap(mapName, maxlen);
  }
  else if (StrEqual(mapChangeMode, "off"))
  {
    // 'off' so return nothing.
  }
  else
  {
    // Fall through for idiots who can't type. Go to default mode.
    GetConVarString(sm_esmc_defaultmapname, mapName, maxlen);
  }
}

/**
* Determines if SourceTV is enabled.
* It first checks to see if 'tv_enable' is set. Note that this convar used to always return a '0', but currently
* is behaving correctly.
* The fallback method is checking on all Clients if the ClientName is equal to the ConVar 'tv_name'.
* @return bool telling if SourceTV is enabled.
*/
bool:IsSourceTvEnabled()
{
  new bool:bTvEnabled = false;
  new iClientCount = GetClientCount(false);
  //PrintToServer("[ESMC][DEBUG] GetClientCount:%d",iClientCount);
  
  // Only run when there are clients (SourceTV is a client too!).
  if (iClientCount != 0) {
    // Get the value from 'tv_enable'.
    new Handle:hConVar = FindConVar("tv_enable");
    new bool:bTvEnable;
    if (hConVar != INVALID_HANDLE) {
      bTvEnable = GetConVarBool(hConVar);
      //PrintToServer("[ESMC][DEBUG] tv_enable:%b",bTvEnable);
    }
    
    if (bTvEnable) {
      bTvEnabled = true;
    } else {
      
      // Fallback 'old' method, iterate through clients.
      // Get the value from 'tv_name'.
      hConVar = FindConVar("tv_name");
      new String:sTvName[32];
      if (hConVar != INVALID_HANDLE) {
        GetConVarString(hConVar, sTvName, sizeof(sTvName));
        //PrintToServer("[ESMC][DEBUG] tv_name:%s",sTvName);
      }
      
      // for all Clients...
      for (new i=1; i <= iClientCount; i++) {
        new String:sClientName[32];
        if (IsClientInGame(i)) {
          GetClientName(i, sClientName, sizeof(sClientName));
          // ... search for SourceTV.
          if (StrEqual(sTvName, sClientName)) {
            // Found it! Stop searching.
            bTvEnabled = true;
            break;
          }
        }
      }
    }
  }
  //PrintToServer("[ESMC][DEBUG] bTvEnabled:%b",bTvEnabled);
  return bTvEnabled;
}
