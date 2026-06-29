#pragma semicolon 1
 
#define DEBUG
 
#define PLUGIN_AUTHOR "weird fox / Wyatt"
#define PLUGIN_VERSION "BETAv1"
#define PLUGIN_NAME "[TF2] Hungergames BETA"
 
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <sdkhooks>
#include <sdktools_entinput>



new Handle:RespawnTimeBlue = INVALID_HANDLE;
new Handle:RespawnTimeRed = INVALID_HANDLE;
new Handle:RespawnTimeEnabled = INVALID_HANDLE;
new Handle:ShowRespawnMessage = INVALID_HANDLE;
new bool:SuddenDeathMode; //Are we in SuddenDeathMode boolean?
new TF2GameRulesEntity; //The entity that controls spawn wave times
new Handle:g_hArenaAutoDisable;

const TeamBlu = 3;
const TeamRed = 2;

#define STATE_DISABLED		2
#define STATE_NOT_IN_ROUND	1

#define LoopAlivePlayers(%1) for (int %1 = 1; %1 <= MaxClients; ++%1) if (IsClientInGame(%1) && IsPlayerAlive(%1) && !IsFakeClient(%1))
#define TEAM_BLU 3
#define TEAM_RED 2

#define TEAM_INVALID	-1
#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATOR	1
#define TEAM_RED		2
#define TEAM_BLUE		3

#define MAX_SPAWN_POINTS	128
#define MAX_FILTERS			8

#define SND_SUCCESS		"buttons/blip1.wav"
#define SND_FAIL		"buttons/button8.wav"

#define PARTICLE_BLUE	"teleporter_arms_circle_blue"
#define PARTICLE_RED	"teleporter_arms_circle_red"

new g_PluginState;						// Holds the flags for the global plugin state.

new Float:Angles[MAX_SPAWN_POINTS][3];
new Float:Position[MAX_SPAWN_POINTS][3];
new TeamNum[MAX_SPAWN_POINTS];
new Entities[MAX_SPAWN_POINTS] = {-1, ...};
new NumPoints;
new String:FilePath[192];
//new Filters[MAX_FILTERS] = {-1, ...};
//new numFilters;
new Doors[32] = {-1, ...};
new numDoors;

new Handle:cv_PluginEnabled = INVALID_HANDLE;	// Enables or disables the plugin.
new Handle:cv_SpawnRadius = INVALID_HANDLE;		// Radius around spawn point in which to destroy objects/kill clients.
new Handle:cv_Particles = INVALID_HANDLE;		// Enables or disables spawn point markers.
new Handle:cv_Respawn = INVALID_HANDLE;			// If 0, respawn rooms will be disabled.
new Handle:cv_RespawnVis = INVALID_HANDLE;		// If 0, respawn room visualisers will be disabled.

new Handle:DoorTimer = INVALID_HANDLE;
 
public Plugin myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = "",
    version = PLUGIN_VERSION,
    url = ""
};
 
 stock ChangeClientTeam_Safe(client, team)
{
    new EntProp = GetEntProp(client, Prop_Send, "m_lifeState");
    SetEntProp(client, Prop_Send, "m_lifeState", 2);
    ChangeClientTeam(client, team);
    SetEntProp(client, Prop_Send, "m_lifeState", EntProp);
}  
 
public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("teamplay_round_start", Event_RoundStart);
    HookEvent("teamplay_round_stalemate", EventSuddenDeath, EventHookMode_PostNoCopy); //Disable spawning during suddendeath. Could be fun if enabled with melee only.
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
    HookEvent("teamplay_game_over", EventSuddenDeath, EventHookMode_PostNoCopy); //Disable spawning
    HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Pre);
    HookEvent("arena_round_start", Event_ArenaRoundStart, EventHookMode_PostNoCopy);
    HookEvent("teamplay_round_win", Event_RoundWinEnd);
    HookEvent("teamplay_waiting_ends", Event_WaitingForPlayersEnd);
    HookEvent("teamplay_game_over", EventSuddenDeath, EventHookMode_PostNoCopy); //Disable spawning
    RegAdminCmd("sm_hgcap_enable", Command_EnableObjectives, ADMFLAG_BAN, "Enable Capping"); 
  	RegAdminCmd("sm_hgcap_disable", Command_DisableObjectives, ADMFLAG_BAN, "Disable Capping");
    ServerCommand("mp_respawnwavetime 650");
    ServerCommand("mp_disable_respawn_times 0");
    ServerCommand("mp_autoteambalance 0");
    ServerCommand("sv_alltalk 0");
    ServerCommand("sm_hgcap_disable");
    ServerCommand("tf_gravetalk 0");
    ServerCommand("mp_scrambleteams_auto 0");
    RegConsoleCmd("sm_drop", DropWeapon, "Spawns a dropped weapon at your feet. Usage: sm_drop [item index]");
    CreateConVar("sm_hg_force_end_round_version", PLUGIN_VERSION, "HG Version implemented", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    CreateConVar("sm_tf_hgcaptoggle", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
  	g_hArenaAutoDisable = CreateConVar("sm_hgcap_auto_arena", "1", "Sets whether or not Arena capture points are automatically disabled on round start");
	RegAdminCmd("sm_hgfer", ForceGameEnd, ADMFLAG_BAN, "sm_hgfer [team]");
	RegAdminCmd("sm_hgforceendround", ForceGameEnd, ADMFLAG_BAN, "sm_forceendround [team]");
	LoadTranslations("common.phrases");
    LogMessage("===== %s v%s =====", PLUGIN_NAME, PLUGIN_VERSION);
	
	CreateConVar("dmspawn_version", PLUGIN_VERSION, "Plugin version.", FCVAR_NOTIFY);
	
	cv_PluginEnabled  = CreateConVar("hgspawn_enabled",
												"1",
												"Enables or disables the HG spawns",
												FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_SpawnRadius  = CreateConVar("hgspawn_spawn_radius",
												"24",
												"Radius around spawn point in which to destroy objects/kill clients.",
												FCVAR_ARCHIVE,
												true,
												1.0,
												true,
												128.0);
	
	cv_Particles  = CreateConVar("hgspawn_spawn_markers",
												"1",
												"Enables or disables spawn point markers.",
												FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_Respawn = CreateConVar("hgspawn_respawn_enabled",
												"0",
												"If 0, respawn rooms will be disabled.",
												FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_RespawnVis = CreateConVar("hgspawn_respawn_visualizers_enabled",
												"0",
												"If 0, respawn room visualisers will be disabled.",
												FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	AutoExecConfig(true, "hgspawn", "sourcemod/hgspawns");
	
	RegAdminCmd("hgspawn_add",		Command_AddSpawn, ADMFLAG_CONFIG,		"Adds a spawn point at the player's current position.");
	RegAdminCmd("hgspawn_remove",	Command_RemoveSpawn, ADMFLAG_CONFIG,	"Removes spawn point of the specified number; 'all' removes all points, no argument removes closest point.");
	RegAdminCmd("hgspawn_save",		Command_SaveSpawns, ADMFLAG_CONFIG,		"Saves current spawn points to scripts/hgspawn.");
	RegAdminCmd("hgspawn_reload",	Command_LoadSpawns, ADMFLAG_CONFIG,		"Reloads map's spawn points from file.");
	RegAdminCmd("hgspawn_dump",		Command_DumpAll, ADMFLAG_CONFIG,		"hgspawn_dump [min] [max]: Dumps info about spawns numbered between min and max.");
	RespawnTimeEnabled = CreateConVar("sm_hgrespawn_time_enabled", "1", "Enable or disable the plugin 1=On, 0=Off", FCVAR_NOTIFY);
	RespawnTimeBlue = CreateConVar("sm_hgrespawn_time_blue", "650", "Respawn time for Blue team", FCVAR_NOTIFY);
	RespawnTimeRed = CreateConVar("sm_hgrespawn_time_red", "650", "Respawn time for Red team", FCVAR_NOTIFY);
	ShowRespawnMessage = CreateConVar("sm_show_respawn_message", "0", "Enable or disable respawn message", FCVAR_NOTIFY);
	CreateConVar("sm_respawn_time_version", PLUGIN_VERSION, "TF2 Fast Respawns Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookConVarChange(RespawnTimeBlue, RespawnConVarChanged);
	HookConVarChange(RespawnTimeRed, RespawnConVarChanged);
	HookConVarChange(RespawnTimeEnabled, EnableChanged);
	HookConVarChange(FindConVar("sv_tags"), TagsChanged);
	// Update the plugin state to reflect the cvar after autoexec.
	PluginEnabledStateChanged(GetConVarBool(cv_PluginEnabled));
	CheckParticles(GetConVarBool(cv_Particles));
	
	HookConVarChange(cv_PluginEnabled, CvarChange);
	HookConVarChange(cv_Particles, CvarChange);
	HookConVarChange(cv_Respawn, CvarChange);
	HookConVarChange(cv_RespawnVis, CvarChange);
	
	HookEventEx("teamplay_round_start",		Event_RoundStart,		EventHookMode_Post);
	HookEventEx("teamplay_round_win",		Event_RoundWin,			EventHookMode_Post);
	HookEventEx("teamplay_round_stalemate",	Event_RoundStalemate,	EventHookMode_Post);
	HookEventEx("player_spawn",				Event_Spawn,			EventHookMode_Post);
	
	AutoExecConfig(true, "tf2_respawn");
	
	// Spawn points are loaded on MapStart which is called immediately after this if the plugins is loaded on an active server.
}

stock TagsCheck(const String:tag[], bool:remove = false)
{
	new Handle:hTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hTags, tags, sizeof(tags));

	if (StrContains(tags, tag, false) == -1 && !remove)
	{
		decl String:newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		ReplaceString(newTags, sizeof(newTags), ",,", ",", false);
		SetConVarString(hTags, newTags);
		GetConVarString(hTags, tags, sizeof(tags));
	}
	else if (StrContains(tags, tag, false) > -1 && remove)
	{
		ReplaceString(tags, sizeof(tags), tag, "", false);
		ReplaceString(tags, sizeof(tags), ",,", ",", false);
		SetConVarString(hTags, tags);
	}
}

public function_DeleteEntities()

{ 
	function_deleteEntities("func_door",true);
	function_deleteEntities("func_door_rotating",true);
	function_deleteEntities("func_brush",false);
	function_deleteEntities("func_respawnroomvisualizer", false);
	function_deleteEntities("func_respawnroom", true);
	function_deleteEntities("func_regenerate", true);
	function_sendEntitiesInput("trigger_teleport","Enable");
}
 
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(NextFrame_CheckPlayerCount);
    int client = GetClientOfUserId(event .GetInt("userid"));
    if(IsClientInGame(client) && !IsFakeClient(client))
    {
        CPrintToChatAll("{red}[HG] A player has been brutally murdered!");
        ChangeClientTeam_Safe(client, TFTeam_Red);
    }
	new Float:RespawnTime = 0.0;
	
	if ((GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER) == TF_DEATHFLAG_DEADRINGER) // I never really was on your side!
		return Plugin_Continue;
	
	if (!SuddenDeathMode) //If we are enabled and SuddenDeathMode is not running then spawn players
	{
		new PlayerTeam = GetClientTeam(client);
		if (PlayerTeam == TeamBlu)
		{
			SetRespawnTime(); //Have to do this since valve likes to reset the TF_GameRules during rounds and map changes
			RespawnTime = GetConVarFloat(RespawnTimeBlue);
			if (RespawnTime > 0) // Use the timer if the Respawn time is greater 0
			{
				if (GetConVarBool(ShowRespawnMessage))
					PrintHintText(client, "Respawning in %.1f seconds", RespawnTime); //inform the player time to wait for respond
					
				CreateTimer(RespawnTime, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE); //Respawn the player at the specified time
			}
			else if (RespawnTime <= 0) // else respawn the player straight
				SpawnPlayer(client);
		}
		else if (PlayerTeam == TeamRed)
		{
			SetRespawnTime(); //Have to do this since valve likes to reset the TF_GameRules during rounds and map changes
			RespawnTime = GetConVarFloat(RespawnTimeRed);
			if (RespawnTime > 0) // Use the timer if the Respawn time is greater 0
			{
				if (GetConVarBool(ShowRespawnMessage))
					PrintHintText(client, "Respawning in %.1f seconds", RespawnTime); //inform the player time to wait for respond
					
				CreateTimer(RespawnTime, SpawnPlayerTimer, client, TIMER_FLAG_NO_MAPCHANGE); //Respawn the player at the specified time
			}
			else if (RespawnTime <= 0) // else respawn the player straight
				SpawnPlayer(client);
		}
	}
	return Plugin_Continue;
}

public Action SpawnPlayerTimer(Handle timer, any client)
{
    SpawnPlayer(client);
    return Plugin_Continue;
}

void NextFrame_CheckPlayerCount(any data)
{
    if (GetTeamAliveClientCount(TEAM_RED) == 1) 
    {
    	ServerCommand("sm_hgfer red");
    }
    else if (GetTeamClientCount(TEAM_BLU) == 1) 
    {
   		ServerCommand("sm_hgfer blue");
  	}
}


public SpawnPlayer(client)
{
	 //Respawn the player if he is in game and is dead.
     if(!SuddenDeathMode && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
     {
          new PlayerTeam = GetClientTeam(client);
          if(PlayerTeam == TeamRed || PlayerTeam == TeamBlu)
          {
               TF2_RespawnPlayer(client);
          }
     }
}

public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new intNewValue = StringToInt(newValue);
	new intOldValue = StringToInt(oldValue);

	if(intNewValue == 1 && intOldValue == 0) 
	{
		TagsCheck("respawntimes");
		SetRespawnTime();
	}
	else if(intNewValue == 0 && intOldValue == 1) 
	{
		TagsCheck("respawntimes", true);
	}
}

public TagsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(RespawnTimeEnabled))
		TagsCheck("respawntimes");
	else
		TagsCheck("respawntimes", true);
}

public RespawnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(RespawnTimeEnabled))
		SetRespawnTime();
}

public SetRespawnTime()
{
	if (TF2GameRulesEntity != -1)
	{
		new Float:RespawnTimeRedValue = GetConVarFloat(RespawnTimeRed);
		if (RespawnTimeRedValue >= 6.0) //Added this check for servers setting spawn time to 6 seconds. The -6.0 below would cause instant spawn.
			SetVariantFloat(RespawnTimeRedValue - 6.0); //I subtract 6 to help with getting an exact spawn time since valve adds on time to the spawn wave
		else
			SetVariantFloat(RespawnTimeRedValue);
			
		AcceptEntityInput(TF2GameRulesEntity, "SetRedTeamRespawnWaveTime", -1, -1, 0);
		
		new Float:RespawnTimeBlueValue = GetConVarFloat(RespawnTimeBlue);
		if (RespawnTimeBlueValue >= 6.0)
			SetVariantFloat(RespawnTimeBlueValue - 6.0); //I subtract 6 to help with getting an exact spawn time since valve adds on time to the spawn wave
		else
			SetVariantFloat(RespawnTimeBlueValue);
			
		AcceptEntityInput(TF2GameRulesEntity, "SetBlueTeamRespawnWaveTime", -1, -1, 0);
	}
}

public Action:EventSuddenDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Don't respawn players during sudden death mode
	SuddenDeathMode = true;
	return Plugin_Continue;
}

public bool:IsArenaMap()
{
	new iEnt = FindEntityByClassname(-1, "tf_logic_arena");
	
	if (iEnt == -1)
		return false;
	else
		return true;
}

int GetTeamAliveClientCount(int iTeam) {
    int iCount;
   
    LoopAlivePlayers(i) {
        if (GetClientTeam(i) == iTeam)
            iCount++;
    }
   
    return iCount;
}

public Event_RoundWinEnd(Handle event, const String:name[], bool dontBroadcast)
{
	ServerCommand("mp_friendlyfire 0");
	for (new i = 1; i <= MaxClients; i++)
    {
        if((1 <= i <= MaxClients) && IsPlayerAlive(i) && !IsFakeClient(i))
        {
           	ChangeClientTeam_Safe(i, TFTeam_Red);
    		TF2_SetPlayerClass(i, TFClass_Sniper, true, true);
        }
    }
    //Don't respawn players during sudden death mode
	SuddenDeathMode = true;
	return Plugin_Continue;
}  

public Event_ArenaRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(g_hArenaAutoDisable)
  {
    ToggleObjectiveState(false);    
  }
  //Time to respawn players again, wahoo!
  SuddenDeathMode = false;
  return Plugin_Continue;
}

ToggleObjectiveState(bool:newState)
{
  /* Things to enable or disable */
  new String:targets[5][25] = {"team_control_point_master","team_control_point","trigger_capture_area","item_teamflag","func_capturezone"};
  new String:input[7] = "Disable";
  if(newState) input = "Enable";

  /* Loop through things that should be enabled/disabled, and push it as an input */
  new ent = 0;
  for (new i = 0; i < 5; i++)
  {
    ent = MaxClients+1;
    while((ent = FindEntityByClassname(ent, targets[i]))!=-1)
    {
      AcceptEntityInput(ent, input);
    }
  }
  LogMessage("[SM] Objective State Now: %sd", input);
}

public Action Command_DisableObjectives(client,args)
{
  ToggleObjectiveState(false);
  return Plugin_Handled;
}

public Action Command_EnableObjectives(client,args)
{
  ToggleObjectiveState(true);
  return Plugin_Handled;
}

public OnMapStart()
{
	KillSpawnRooms();
	HookEvent("post_inventory_application", OnPostInventoryApplicationTwice, EventHookMode_Pre);
    PrecacheModel("models/weapons/c_models/c_directhit/c_directhit.mdl", true);
    PrecacheModel("models/workshop.weapons/c_models.c_invasion_pistol/c_invasion_pistol.mdl", true);
    PrecacheModel("models/weapons/c_models/c_eviction_notice/c_eviction_notice.mdl", true);
    // Need to add more precaches here
    PrecacheSound(SND_SUCCESS, true);
	PrecacheSound(SND_FAIL, true);
	
	decl String:MapName[128];
	GetCurrentMap(MapName, sizeof(MapName));
	Format(FilePath, sizeof(FilePath), "scripts/hgspawn/%s_spawns.txt", MapName);
	
	LogMessage("File path for map: %s", FilePath);
	
	// Get the info and stick it into our global variables.
	RetrieveSpawnInfo(FilePath);
	
	// Find any filters.
	/*new i = -1;
	while ( (i = FindEntityByClassname(i, "filter_activator_tfteam")) != -1 )
	{
		if ( numFilters >= MAX_FILTERS )
		{
			LogMessage("Map has more than the maximum number of team filters!");
			break;
		}
		
		Filters[numFilters] = i;
		numFilters++;
		
		LogMessage("Team filter found at index %d.", i);
	}*/
	
	if ( NumPoints < 1 ) return;
	
	// Kill all entities that shouldn't exist.
	KillEntities();
	
	numDoors = 0;
	new i = -1;
	while ( (i = FindEntityByClassname(i, "func_door")) != -1 )
	{
		LogMessage("Func_door recorded at index %d", i);
		Doors[numDoors] = EntIndexToEntRef(i);
		numDoors++;
	}
	
		//Find the TF_GameRules Entity
	TF2GameRulesEntity = FindEntityByClassname(-1, "tf_gamerules");
	
	if (TF2GameRulesEntity == -1)
	{
		LogToGame("Could not find TF_GameRules to set respawn wave time");
	}
	
	// Disable the plugin during Arena Mode
	if (IsArenaMap())
		SetConVarInt(RespawnTimeEnabled, 0);
		
	SuddenDeathMode = false;
}

stock KillSpawnRooms()
{
    new i = -1;
    new entity = 0;

    for (new n = 0; n <= 16; n++)
    {
        entity = FindEntityByClassname(i, "func_respawnroom");
        if (IsValidEntity(entity))
        {
            AcceptEntityInput(entity, "Kill");
            i = entity;
        }
        else
        {
       		break;
      	}     
    }
}

public OnConfigsExecuted()
{
	if (GetConVarBool(RespawnTimeEnabled))
		TagsCheck("respawntimes");
	else
		TagsCheck("respawntimes", true);
}

public Event_WaitingForPlayersEnd(Handle event, const String:name[], bool dontBroadcast)
{
	ServerCommand("mp_friendlyfire 0");
	ServerCommand("sm_respawn_time_red 650");
	ServerCommand("sm_cvar sm_respawn_time_red 650");
	CreateTimer(5.0, SetupTime);
	for (new i = 1; i <= MaxClients; i++)
    {
        if((1 <= i <= MaxClients) && IsPlayerAlive(i) && !IsFakeClient(i))
        {
           	ChangeClientTeam_Safe(i, TFTeam_Red);
    		TF2_SetPlayerClass(i, TFClass_Sniper, true, true);
        }
    }
}

public Action SetupTime(Handle timer)
{
	CPrintToChatAll("{red}[HG] Setting up server....");
	ServerCommand("sm_hgfer red");
}


public OnMapEnd()
{
	// Clear out all spawn point info.
	ClearAllIndices();
	
	FilePath[0] = '\0';
	
	for ( new i = 0; i < 32; i++ )
	{
		Doors[i] = -1;
	}
	
	numDoors = 0;
	
	if ( DoorTimer != INVALID_HANDLE )
	{
		KillTimer(DoorTimer);
		DoorTimer = INVALID_HANDLE;
	}
}

public OnPluginEnd()
{
	// Clean up entities just in case we get reloaded.
	ClearAllIndices();
}

/*	Checks which ConVar has changed and does the relevant things.	*/
public CvarChange( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	if		( convar == cv_PluginEnabled )	PluginEnabledStateChanged(GetConVarBool(cv_PluginEnabled));
	else if ( convar == cv_Particles )		CheckParticles(GetConVarBool(cv_Particles));
	else if ( convar == cv_Respawn )		RespawnRooms(GetConVarBool(cv_Respawn));
	else if ( convar == cv_RespawnVis )		TeamVis(GetConVarBool(cv_RespawnVis));
}

/*	Sets the enabled/disabled state of the plugin and restarts the map.
	Passing true enables, false disables.	*/
stock PluginEnabledStateChanged(bool:b_state)
{
	if ( b_state )
	{
		g_PluginState &= ~STATE_DISABLED;	// Clear the disabled flag.
	}
	else
	{
		g_PluginState |= STATE_DISABLED;	// Set the disabled flag.
	}
	
	// Update the state of entities which depend on the state of the plugin.
	KillEntities();
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )	// If now disabled, kill all spawn points.
	{
		ClearAllIndices();
	}
	else	// If enabled, reload spawn points.
	{
		RetrieveSpawnInfo(FilePath);
	}
}

stock CheckParticles(enable)
{
	for ( new i = 0; i < NumPoints; i++ )
	{
		if ( g_PluginState & STATE_DISABLED != STATE_DISABLED && enable )	// Create particle effects if the plugin is not disabled.
		{
			new ent = EntRefToEntIndex(Entities[i]);
			
			if ( IsValidEntity(ent) )	// Stored entity ref is valid.
			{
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Start");
			}
			else	// Entity is invalid, create a new one.
			{
				if ( TeamNum[i] == TEAM_RED )
				{
					ent = CreateParticle(PARTICLE_RED, Position[i]);
				}
				else if ( TeamNum[i] == TEAM_BLUE )
				{
					ent = CreateParticle(PARTICLE_BLUE, Position[i]);
				}
				
				ActivateEntity(ent);
				AcceptEntityInput(ent, "Start");
				
				Entities[i] = EntIndexToEntRef(ent);
			}
		}
		else	// Destroy particle effects
		{
			if ( Entities[i] == -1 ) continue;	// Entity is invalid, leave it.
			
			// Entity is valid, kill it
			new ent = EntRefToEntIndex(Entities[i]);
			
			if ( IsValidEntity(ent) )
			{
				AcceptEntityInput(ent, "Stop");
				AcceptEntityInput(ent, "Kill");
			}
			
			Entities[i] = -1;
		}
	}
}
 
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	AddCommandListener(BlockedCommands, "jointeam");
	AddCommandListener(BlockedCommands, "join_class");
	AddCommandListener(BlockedCommands, "changeclass");
	RequestFrame(NextFrame_CheckPlayerCount);
	function_DeleteEntities();
	ServerCommand("sm_hgcap_disable");
	ServerCommand("sm_givew @all 423");
	CreateTimer(30.0, FF);
    CPrintToChatAll("{red}[HG] 30 Seconds grace period has started!");
    for (new i = 1; i <= MaxClients; i++)
    {
        if((1 <= i <= MaxClients) && IsPlayerAlive(i) && !IsFakeClient(i))
        {
        	TF2_RespawnPlayer(i);
            TF2_RegeneratePlayer(i);
            ChangeClientTeam_Safe(i, TFTeam_Red);
            TF2_SetPlayerClass(i, TFClass_Sniper, true, true);
            TF2_RemoveWeaponSlot(i, TFWeaponSlot_Primary);
			TF2_RemoveWeaponSlot(i, TFWeaponSlot_Secondary);
        }
        else if((1 <= i <= MaxClients) && IsPlayerAlive(i) && IsFakeClient(i))
        {
		   	SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
		   	SetEntProp(i, Prop_Data, "m_takedamage", 1, 1);
	    }
    }
    
    g_PluginState &= ~STATE_NOT_IN_ROUND;
	
	numDoors = 0;
	new i = -1;
	while ( (i = FindEntityByClassname(i, "func_door")) != -1 )
	{
		LogMessage("Func_door recorded at index %d", i);
		Doors[numDoors] = EntIndexToEntRef(i);
		numDoors++;
	}
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED ) return;
	
	if ( NumPoints < 1 ) return;
	
	KillEntities();
	CheckParticles(GetConVarBool(cv_Particles));
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_PluginState |= STATE_NOT_IN_ROUND;
	ServerCommand("mp_friendlyfire 0");
}

public Event_RoundStalemate(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_PluginState |= STATE_NOT_IN_ROUND;
	ServerCommand("mp_friendlyfire 0");
}
 
public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    CPrintToChatAll("{red}A player has abandoned the match!");
}

/*	Called when a player spawns.	*/
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED ) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	
	// Choose a random spawn index to teleport the client to.
	if ( NumPoints > 0 && client > 0 && client <= MaxClients && IsClientInGame(client) )
	{
		// Build a list of points on the same team as the client.
		new Spawns[NumPoints];
		new validSpawns = 0;
		
		for ( new j = 0; j < NumPoints; j++ )
		{
			if ( TeamNum[j] == team )
			{
				Spawns[validSpawns] = j;
				validSpawns++;
			}
		}
		
		new i;
		if ( validSpawns < 1 ) i = GetRandomInt(0, NumPoints-1);	// If there are spawns on the client's team, spawn anywhere.
		else i = Spawns[GetRandomInt(0, validSpawns-1)];			// Else choose a random team spawn.
		
		// Firstly, check to see if there is any client or building within the specified radius of the spawn point.
		// NOTE: The following is hacky because the radius ignores walls/objects/etc.
		new Float:SpawnRadius = GetConVarFloat(cv_SpawnRadius);
		
		for ( new ClientSearch = 1; ClientSearch <= MaxClients; ClientSearch++ )
		{
			if ( IsClientInGame(ClientSearch) )
			{
				new Float:ClOrigin[3];
				GetClientAbsOrigin(ClientSearch, ClOrigin);
				
				// If the client is near enough:
				if ( GetVectorDistance(ClOrigin, Position[i]) <= SpawnRadius && GetClientTeam(ClientSearch) != GetClientTeam(client) && GetClientTeam(ClientSearch) > TEAM_SPECTATOR ) ForcePlayerSuicide(ClientSearch);
			}
		}
		
		new BuildingSearch = -1;
		while ( (BuildingSearch = FindEntityByClassname(BuildingSearch, "obj_sentrygun")) != -1 )
		{
			new Float:EntOrigin[3], BuildingTeam;
			GetEntPropVector(BuildingSearch, Prop_Send, "m_vecOrigin", EntOrigin);
			BuildingTeam = GetEntProp(BuildingSearch, Prop_Send, "m_iTeamNum");
			
			// If the building is near enough:
			if ( GetVectorDistance(EntOrigin, Position[i]) <= SpawnRadius && BuildingTeam != GetClientTeam(client) )
			{
				SetVariantInt( GetEntProp(BuildingSearch, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(BuildingSearch, "RemoveHealth");
				AcceptEntityInput(BuildingSearch, "Kill");
			}
		}
		
		BuildingSearch = -1;
		while ( (BuildingSearch = FindEntityByClassname(BuildingSearch, "obj_dispenser")) != -1 )
		{
			new Float:EntOrigin[3], BuildingTeam;
			GetEntPropVector(BuildingSearch, Prop_Send, "m_vecOrigin", EntOrigin);
			BuildingTeam = GetEntProp(BuildingSearch, Prop_Send, "m_iTeamNum");
			
			// If the building is near enough:
			if ( GetVectorDistance(EntOrigin, Position[i]) <= SpawnRadius && BuildingTeam != GetClientTeam(client) )
			{
				SetVariantInt( GetEntProp(BuildingSearch, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(BuildingSearch, "RemoveHealth");
				AcceptEntityInput(BuildingSearch, "Kill");
			}
		}
		
		BuildingSearch = -1;
		while ( (BuildingSearch = FindEntityByClassname(BuildingSearch, "obj_teleporter")) != -1 )
		{
			new Float:EntOrigin[3], BuildingTeam;
			GetEntPropVector(BuildingSearch, Prop_Send, "m_vecOrigin", EntOrigin);
			BuildingTeam = GetEntProp(BuildingSearch, Prop_Send, "m_iTeamNum");
			
			// If the building is near enough:
			if ( GetVectorDistance(EntOrigin, Position[i]) <= SpawnRadius && BuildingTeam != GetClientTeam(client) )
			{
				// Set up a trace to see if anything is in the way.
				SetVariantInt( GetEntProp(BuildingSearch, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(BuildingSearch, "RemoveHealth");
				AcceptEntityInput(BuildingSearch, "Kill");
			}
		}
		
		TeleportEntity(client, Position[i], Angles[i], NULL_VECTOR);
	}
}

public Action FF(Handle timer)
{
	ServerCommand("mp_friendlyfire 1");
	CPrintToChatAll("{red}[HG] Grace period is over!");
}

public void function_sendEntitiesInput(const char[] entityname, const char[] input){

	int x = -1;
	int EntIndex;
	bool HasFound = true;

	while(HasFound) {

		EntIndex = FindEntityByClassname (x, entityname); //finds doors

		if(EntIndex==-1) {//breaks the loop if no matching entity has been found

			HasFound=false;

		}else{

			if (IsValidEntity(EntIndex)) {

				AcceptEntityInput(EntIndex, input); //Deletes the door it.
				x = EntIndex;
			}
		}
	}
}

public void function_deleteEntities(const char[] entityname, bool isDoor){

	if(isDoor){
		function_sendEntitiesInput(entityname, "Open");
	}
	function_sendEntitiesInput(entityname,"Kill");

}

ClearAllIndices()
{
	NumPoints = 0;
	
	for ( new i = 0; i < MAX_SPAWN_POINTS; i++ )
	{
		Angles[i][0] = 0.0;
		Angles[i][1] = 0.0;
		Angles[i][2] = 0.0;
		
		Position[i][0] = 0.0;
		Position[i][1] = 0.0;
		Position[i][2] = 0.0;
		
		TeamNum[i] = 0;
		
		new ent = EntRefToEntIndex(Entities[i]);
		if ( IsValidEntity(ent) )
		{
			AcceptEntityInput(ent, "Stop");
			AcceptEntityInput(ent, "Kill");
		}
		
		Entities[i] = -1;
	}
}

/*	Parses the spawn info file and puts the values into the global variables.
	Returns true on success, false on failure.	*/
RetrieveSpawnInfo(String:s_FilePath[])
{	
	new Handle:kv = CreateKeyValues("spawns");
	
	if ( kv == INVALID_HANDLE )
	{
		LogMessage("Could not create keyvalues tree to import spawn point information.");
		return 1;
	}
	
	if ( !FileToKeyValues(kv, s_FilePath) )
	{
		LogMessage("No spawns file %s found.", s_FilePath);
		return 2;
	}
	
	LogMessage("Spawn point file %s loaded successfully.", s_FilePath);
	
	ClearAllIndices();
	
	if ( !KvGotoFirstSubKey(kv) )	// If there are no sub-keys:
		{
			LogMessage("No first key found.");
		}
	else	// If there are sub-keys:
	{
		new Float:vAngles[3];
		new Float:vPosition[3];
		new Team;
		new SwitchNum = TEAM_RED;
		
		do
		{
			KvGetVector(kv, "angles", vAngles);
			Team = KvGetNum(kv, "TeamNum", SwitchNum);
			KvGetVector(kv, "position", vPosition);
			
			if ( (Team == TEAM_RED || Team == TEAM_BLUE) && NumPoints < MAX_SPAWN_POINTS )	// If the spawn formatting is valid:
			{
				// Put the data into the global variables.
				TeamNum[NumPoints] = Team;
				Angles[NumPoints] = vAngles;
				Position[NumPoints] = vPosition;
				
				LogMessage("Spawn point %d: team %d, pos %f %f %f, ang %f %f %f", NumPoints, TeamNum[NumPoints],
							Position[NumPoints][0], Position[NumPoints][1], Position[NumPoints][2],
							Angles[NumPoints][0], Angles[NumPoints][1], Angles[NumPoints][2]);
				
				NumPoints++;
			}
			
			vAngles[0] = 0.0;
			vAngles[1] = 0.0;
			vAngles[2] = 0.0;
			vPosition[0] = 0.0;
			vPosition[1] = 0.0;
			vPosition[2] = 0.0;
			Team = 0;
			
			if ( SwitchNum == TEAM_RED ) SwitchNum = TEAM_BLUE;
			else SwitchNum = TEAM_RED;
			
		} while ( KvGotoNextKey(kv) );	// Increment NumPoints while the next key exists.
	}
	
	// Now all data is held in the global arrays.
	CloseHandle(kv);
	kv = INVALID_HANDLE;
	
	CheckParticles(GetConVarBool(cv_Particles));
	
	LogMessage("Number of spawns in file: %d", NumPoints);
	LogMessage("All spawns are loaded.");
	
	return 0;
}

stock KillEntities()
{
	RespawnRooms(GetConVarBool(cv_Respawn));
	TeamVis(GetConVarBool(cv_RespawnVis));
}

stock Resupply(bool:enable)
{
	new i = -1;
	
	while ( (i = FindEntityByClassname(i, "func_regenerate")) != -1 )
	{
		if ( g_PluginState & STATE_DISABLED == STATE_DISABLED || enable )
		{
			AcceptEntityInput(i, "Enable");
			LogMessage("Resupply locker at index %d enabled.", i);
		}
		else
		{
			AcceptEntityInput(i, "Disable");
			LogMessage("Resupply locker at index %d disabled.", i);
		}
	}
}

stock RespawnRooms(bool:enable)
{
	new i = -1;
	
	while ( (i = FindEntityByClassname(i, "func_respawnroom")) != -1 )
	{
		if ( g_PluginState & STATE_DISABLED == STATE_DISABLED || enable )
		{
			AcceptEntityInput(i, "Enable");
			LogMessage("func_respawnroom at index %d enabled.", i);
		}
		else
		{
			AcceptEntityInput(i, "Disable");
			LogMessage("func_respawnroom at index %d disabled.", i);
		}
	}
}

stock TeamVis(bool:enable)
{
	new i = -1;
	
	while ( (i = FindEntityByClassname(i, "func_respawnroomvisualizer")) != -1 )
	{
		if ( enable )
		{
			AcceptEntityInput(i, "Enable");
			LogMessage("func_respawnroomvisualizer at index %d enabled.", i);
		}
		else
		{
			AcceptEntityInput(i, "Disable");
			LogMessage("func_respawnroomvisualizer at index %d disabled.", i);
		}
	}
}

/*	Adds a spawn at the position of the specified client and for the specified team.	*/
stock AddSpawn(client, team)
{
	if ( NumPoints >= MAX_SPAWN_POINTS ) return 0;
	
	// Add a new spawn in the next index.
	new Float:pos[3], Float:ang[3];
	GetClientAbsOrigin(client, pos);
	GetClientAbsAngles(client, ang);
	
	// Ignore pitch and roll
	ang[0] = 0.0;
	ang[2] = 0.0;
	
	TeamNum[NumPoints] = team;
	Position[NumPoints] = pos;
	Angles[NumPoints] = ang;
	
	NumPoints++;
	
	CheckParticles(GetConVarBool(cv_Particles));
	
	return NumPoints;
}

/*	Removes the spawn at the specified array index.	*/
stock RemoveSpawn(client, index)
{
	if ( index == -1 )	// If index == -1, remove all.
	{
		ClearAllIndices();
		
		ShowActivity(client, "All spawn points removed.");
		
		return 0;
	}
	
	if ( NumPoints < 1 ) return 1;
	
	// Find the closest spawn to us.
	new spawn = -1;
	new Float:dist = 99999.0;
	
	new Float:ClientPos[3];
	GetClientAbsOrigin(client, ClientPos);
	
	for ( new i = 0; i < NumPoints; i++ )
	{
		new Float:tdist = GetVectorDistance(Position[i], ClientPos);
		
		if ( tdist < dist && tdist <= 64.0 )
		{
			spawn = i;
			dist = tdist;
		}
	}
	
	if ( index >= 0 ) spawn = index;
	if ( spawn < 0 ) return 2;
	
	// Kill any particles before we remove array entries.
	new ent = EntRefToEntIndex(Entities[spawn]);
	if ( IsValidEntity(ent) )
	{
		AcceptEntityInput(ent, "Stop");
		AcceptEntityInput(ent, "Kill");
	}
	
	// Shift all the information down in the arrays.
	for ( new shift = (spawn + 1); shift < NumPoints; shift++ )
	{
		// Each time, shift will point to the information in the next index on.
		// Move this information to the index (shift - 1).
		Angles[shift-1][0] = Angles[shift][0];
		Angles[shift-1][1] = Angles[shift][1];
		Angles[shift-1][2] = Angles[shift][2];
		
		Position[shift-1][0] = Position[shift-1][0];
		Position[shift-1][1] = Position[shift-1][1];
		Position[shift-1][2] = Position[shift-1][2];
		
		TeamNum[shift-1] = TeamNum[shift];
		Entities[shift-1] = Entities[shift];
	}
	
	// We're at the last index which is now redundant.
	// Remove all the information at this index.
	Angles[NumPoints-1][0] = 0.0;
	Angles[NumPoints-1][1] = 0.0;
	Angles[NumPoints-1][2] = 0.0;
	
	Position[NumPoints-1][0] = 0.0;
	Position[NumPoints-1][1] = 0.0;
	Position[NumPoints-1][2] = 0.0;
	
	TeamNum[NumPoints-1] = 0;
	Entities[NumPoints-1] = -1;
	
	NumPoints--;	// Decrement NumPoints now we've lost a spawn.
	
	ShowActivity(client, "Spawn point %d removed. Spawns have been renumbered.", spawn+1);
	
	return 0;
}

stock bool:SaveSpawns(String:path[])
{
	new Handle:kv = CreateKeyValues("spawns");
		
	if ( kv != INVALID_HANDLE )
	{		
		// Add to the keyvalues tree.
		for ( new i = 0; i < NumPoints; i++ )
		{
			decl String:Buffer[64];
			IntToString(i, Buffer, sizeof(Buffer));
			KvJumpToKey(kv, Buffer, true);			// This will create the new section named as whatever number i currently is.
			
			new Float:KvVector[3];
			KvVector[0] = Angles[i][0];
			KvVector[1] = Angles[i][1];
			KvVector[2] = Angles[i][2];
			KvSetVector(kv, "angles", KvVector);	// This will create a new vector with this value.
			
			new KvTeamNum = TeamNum[i];
			KvSetNum(kv, "TeamNum", KvTeamNum);		// And so on.
			
			KvVector[0] = Position[i][0];
			KvVector[1] = Position[i][1];
			KvVector[2] = Position[i][2];
			KvSetVector(kv, "position", KvVector);
			
			// That's all for this section, return back.
			KvGoBack(kv);
		}
		
		LogMessage("File path to write to: %s", path);
		
		KeyValuesToFile(kv, path);
		CloseHandle(kv);
		
		LogMessage("File written, handle closed.");
		return true;
	}
	else
	{
		LogMessage("Keyvalues unable to be created.");
		return false;
	}
}

stock CreateParticle(String:name[], Float:pos[3])
{
	new entity = CreateEntityByName("info_particle_system");
	
	DispatchKeyValue(entity, "angles", "0 0 0");
	DispatchKeyValue(entity, "start_active", "0");
	DispatchKeyValue(entity, "effect_name", name);
	DispatchKeyValue(entity, "flag_as_weather", "0");
	
	DispatchSpawn(entity);
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
	
	return entity;
}

public Action Command_AddSpawn(client, args)
{
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return Plugin_Handled;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "HG plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( GetClientTeam(client) < TEAM_RED )
	{
		ShowActivity(client, "Cannot create spawn points as a spectator.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( !IsPlayerAlive(client) )
	{
		ShowActivity(client, "Cannot create spawn points while dead.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	new String:Buffer[8], rVal;
	GetCmdArg(1, Buffer, sizeof(Buffer));
	
	if ( StrEqual(Buffer, "red", false) )
	{
		rVal = AddSpawn(client, TEAM_RED);
	}
	else
	{
		rVal = AddSpawn(client, TEAM_BLUE);
	}
	
	if ( rVal < 1 )
	{
		ShowActivity(client, "Maximum number of spawn points reached.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( StrEqual(Buffer, "red", false) ) ShowActivity(client, "Spawn point %d created for team Red.", rVal);
	else ShowActivity(client, "Spawn point %d created for team Blue.", rVal);
	
	EmitSoundToClient(client, SND_SUCCESS);
	
	return Plugin_Handled;
}

public Action:Command_RemoveSpawn(client, args)
{
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return Plugin_Handled;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "HG plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( GetClientTeam(client) < TEAM_RED )
	{
		ShowActivity(client, "Cannot remove spawn points as a spectator.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( !IsPlayerAlive(client) )
	{
		ShowActivity(client, "Cannot remove spawn points while dead.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	new rVal;
	
	if ( GetCmdArgs() > 0 )	// A spawn to remove is specified.
	{
		new String:ArgBuffer[16];
		GetCmdArg(1, ArgBuffer, sizeof(ArgBuffer));
		
		// If the command argument is "all", get rid of everything.
		if ( StrEqual(ArgBuffer, "all", false) ) rVal = RemoveSpawn(client, -1);	// Remove all.
		else
		{
			new index = StringToInt(ArgBuffer);
			index--;							// Decrement to get array index instead of spawn ID.
			
			if ( index < 0 || index >= NumPoints )
			{
				ShowActivity(client, "Spawn %d is invalid", index+1);
				EmitSoundToClient(client, SND_FAIL);
				return Plugin_Handled;
			}
			
			rVal = RemoveSpawn(client, index);	// Remove specific.
		}
	}
	else rVal = RemoveSpawn(client, -2);		// Remove closest.
	
	switch (rVal)
	{
		case 1:
		{
			ShowActivity(client, "No spawn points to remove.");
			EmitSoundToClient(client, SND_FAIL);
		}
		
		case 2:
		{
			ShowActivity(client, "No spawn points near enough to remove.");
			EmitSoundToClient(client, SND_FAIL);
		}
		
		default:
		{
			//ShowActivity(client, "Spawn point removed");
			EmitSoundToClient(client, SND_SUCCESS);
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_DumpAll(client, args)
{
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "Deathmatch Spawn plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	new minIndex = 0;
	new maxIndex = NumPoints-1;
	
	if ( GetCmdArgs() >= 1 )
	{
		decl String:min[8];
		GetCmdArg(1, min, sizeof(min));
		minIndex = StringToInt(min)-1;	// Decrement to get an array index.
	}
	
	if ( GetCmdArgs() >= 2 )
	{
		decl String:max[8];
		GetCmdArg(2, max, sizeof(max));
		maxIndex = StringToInt(max)-1;	// Decrement to get an array index.
	}
	
	if ( minIndex < 0 ) minIndex = 0;
	if ( maxIndex >= MAX_SPAWN_POINTS ) maxIndex = MAX_SPAWN_POINTS-1;
	if ( maxIndex < minIndex ) maxIndex = minIndex;
	
	PrintToConsole(client, "===== Active points: %d. Max points: %d =====", NumPoints, MAX_SPAWN_POINTS);
	PrintToConsole(client, "Team 2 is Red, 3 is Blue.\n");
	
	for ( new i = minIndex; i <= maxIndex; i++ )
	{
		PrintToConsole(client, "Spawn point %d (index %d):", i+1, i);
		
		PrintToConsole(client, "Position %f %f %f, Angles %f %f %f", Position[i][0], Position[i][1], Position[i][2], Angles[i][0], Angles[i][1], Angles[i][2]);
		PrintToConsole(client, "Team ID: %d\n", TeamNum[i]);
	}
	
	PrintToConsole(client, "===== Dump finished. =====");
	
	return Plugin_Handled;
}

public Action:Command_SaveSpawns(client, args)
{
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return Plugin_Handled;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "Deathmatch Spawn plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	if ( SaveSpawns(FilePath) )
	{
		ShowActivity(client, "Spawn file %s successfully written.", FilePath);
		EmitSoundToClient(client, SND_SUCCESS);
	}
	else
	{
		ShowActivity(client, "Spawn file %s was not able to be written.", FilePath);
		EmitSoundToClient(client, SND_FAIL);
	}
	
	return Plugin_Handled;
}

public Action:Command_LoadSpawns(client, args)
{
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return Plugin_Handled;
	
	if ( g_PluginState & STATE_DISABLED == STATE_DISABLED )
	{
		ShowActivity(client, "Deathmatch Spawn plugin is disabled.");
		EmitSoundToClient(client, SND_FAIL);
		return Plugin_Handled;
	}
	
	switch(RetrieveSpawnInfo(FilePath))
	{
		case 1:
		{
			ShowActivity(client, "Error loading spawn file.");
			EmitSoundToClient(client, SND_FAIL);
		}
		
		case 2:
		{
			ShowActivity(client, "No spawn file exists for this map.");
			EmitSoundToClient(client, SND_FAIL);
		}
		
		default:
		{
			ShowActivity(client, "Spawns from %s loaded successfully.", FilePath);
			EmitSoundToClient(client, SND_SUCCESS);
		}
	}
	
	return Plugin_Handled;
}

public OnPostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public OnPostInventoryApplicationTwice(Event event, const char[] name, bool dontBroadcast)
{
	return Plugin_Handled;
}

public Action DropWeapon(iClient, nArgs)
{
    char index[10];
    GetCmdArg(1, index, 10);
    int Entity = CreateEntityByName("tf_dropped_weapon");
    SetEntProp(Entity, Prop_Send, "m_iItemDefinitionIndex", StringToInt(index));
    //SetEntProp(Entity, Prop_Send, "m_nModelIndex", 662); Don't think this is needed.
    SetEntProp(Entity, Prop_Send, "m_iEntityLevel", 5);
    SetEntProp(Entity, Prop_Send, "m_iEntityQuality", 6);
    SetEntProp(Entity, Prop_Send, "m_bInitialized", 1);
    float coordinates[3];
    GetClientAbsOrigin(iClient, coordinates);
    GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", coordinates);
    TeleportEntity(Entity, coordinates, NULL_VECTOR, NULL_VECTOR);
    SetEntityModel(Entity, "models/weapons/c_models/c_eviction_notice/c_eviction_notice.mdl");
    DispatchSpawn(Entity);
    PrintToChatAll("Command ran %.2f %.2f %.2f", coordinates[0], coordinates[1], coordinates[2]);
}  

public Action BlockedCommands(client, const String:command[], argc)
{
	return Plugin_Handled;
}

public void OnClientPutInServer(client)
{
	ChangeClientTeam_Safe(client, TFTeam_Red);
    TF2_SetPlayerClass(client, TFClass_Sniper, true, true);
    TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
    ServerCommand("sm_hgcap_disable");
}

public Action:ForceGameEnd(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "sm_hgfer / sm_hgforceendround [Winning Team: Red/Blue/None]");
		return Plugin_Handled;
	}
	
	new iEnt = -1;
	iEnt = FindEntityByClassname(iEnt, "game_round_win");
	
	if (iEnt < 1)
	{
		iEnt = CreateEntityByName("game_round_win");
		if (IsValidEntity(iEnt))
			DispatchSpawn(iEnt);
		else
		{
			ReplyToCommand(client, "Unable to find or create a game_round_win entity!");
			return Plugin_Handled;
		}
	}
	
	new iWinningTeam = 0;
	if (client) 
		iWinningTeam = GetClientTeam(client);
	
	if (args == 1)
	{
		decl String:buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
	
		if (StrEqual(buffer, "blue", false))
			iWinningTeam = 3;
		else if (StrEqual(buffer, "red", false))
			iWinningTeam = 2;
		else if (StrEqual(buffer, "none", false))
			iWinningTeam = 0;
	}
	
	if (iWinningTeam == 1)
		iWinningTeam --;
		
	SetVariantInt(iWinningTeam);
	AcceptEntityInput(iEnt, "SetTeam");
	AcceptEntityInput(iEnt, "RoundWin");
	
	return Plugin_Handled;
}
