/*
 * ============================================================================
 *
 *  Rotoblin
 *
 *  File:			rotoblin.healthcontrol.sp
 *  Type:			Module
 *  Description:	Removes/replaces health items depending on settings
 *
 *  Copyright (C) 2010  Mr. Zero <mrzerodk@gmail.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

// --------------------
//       Public
// --------------------
#define PILLS_DEBUG 0	//set this to 1 to be able to easily find pill spawns, and edit pilllocations.inc

// This used to pertain solely to replacing kits, but it now pertains to health kits and pills
enum HEALTH_STYLE
{
	REPLACE_NO_KITS = 0, // Don't replace any medkits with pills
	REPLACE_ALL_KITS = 1, // Replace all medkits with pills
	REPLACE_ALL_BUT_FINALE_KITS = 2, // Replace all medkits besides finale medkits
	SAFEROOM_AND_FINALE_PILLS_ONLY = 3, // Replace the saferoom and finale kits with pills and remove all other pills/kits
	REMOVE_ALL_BUT_FOUR = 4 // Remove all pills except 4
}

// --------------------
//       Private
// --------------------

static	const	String:	CONVERT_PILLS_CVAR[]			= "director_convert_pills";
static	const	String:	CONVERT_PILLS_VS_CVAR[]			= "director_vs_convert_pills"; // setting this var to 0 will convert no pills to health kits

static	const	String:	FIRST_AID_KIT_CLASSNAME[]		= "weapon_first_aid_kit_spawn";
static	const	String:	PAIN_PILLS_CLASSNAME[]			= "weapon_pain_pills_spawn";
static	const	String:	MODEL_PAIN_PILLS[]				= "w_models/weapons/w_eq_painpills.mdl";

static	bool: 	g_bPainPillDensityReset = false;

static	const	Float:	REPLACE_DELAY					= 0.1; 			// Short delay on OnEntityCreated before replacing

static	const	Float:	KIT_FINALE_AREA					= 400.0;

static			bool:	g_bIsFinale						= false;
static			Float:	g_vFinaleOrigin[3]				= {0.0};

static 	  HEALTH_STYLE: g_iHealthStyle					= REPLACE_ALL_KITS; // How we replace kits
static			Handle:	g_hHealthStyle_Cvar				= INVALID_HANDLE;

static 					g_iSurvivorLimit 				= 4;			//ammount of finale pills or pills on the map depending on survivor count

static	const 	String: PIPEBOMB_NAME[] 				= "weapon_pipe_bomb_spawn";		//if health style 4, these are converted to pills

static					g_iDebugChannel					= 0;
static	const	String:	DEBUG_CHANNEL_NAME[]			= "HealthControl";

#if PILLS_DEBUG
static					g_iDebugPillArrayIndex 			= 0;
#endif

// **********************************************
//                   Forwards
// **********************************************

/**
 * Plugin is starting.
 *
 * @noreturn
 */
public _HealthControl_OnPluginStart()
{
	HookPublicEvent(EVENT_ONPLUGINENABLE, _HC_OnPluginEnable);
	HookPublicEvent(EVENT_ONPLUGINDISABLE, _HC_OnPluginDisable);

	decl String:buffer[10];
	IntToString(int:g_iHealthStyle, buffer, sizeof(buffer)); // Get default value for replacement style
	g_hHealthStyle_Cvar = CreateConVarEx("health_style", 
		buffer, 
		"How medkits and pills will be configured. 0 - Don't replace any medkits, 1 - Replace all medkits with pills, 2 - Replace all but finale medkits with pills, 3 - Replace safe room and finale kits with pills; remove all other health sources, 4 - Remove all but 4 pills from the map", 
		FCVAR_NOTIFY | FCVAR_PLUGIN);

	if (g_hHealthStyle_Cvar == INVALID_HANDLE) 
	{
		ThrowError("Unable to create health style cvar!");
	}
	
	AddConVarToReport(g_hHealthStyle_Cvar); // Add to report status module
	UpdateHealthStyle();
	
	RegConsoleCmd("sm_pills", _HC_CommandPrintPills); // Print the ammount of pills remaining on the map (1-4);
	#if PILLS_DEBUG
	RegConsoleCmd("sm_pill", Pill); /// Print the aimed pill's location; debug
	RegConsoleCmd("sm_pill1", Pill1); /// Print the aimed pill's location; debug
	RegConsoleCmd("sm_pill2", Pill2); /// Print the aimed pill's location; debug
	RegConsoleCmd("sm_pill3", Pill3); /// Print the aimed pill's location; debug
	RegConsoleCmd("sm_pill4", Pill4); /// Print the aimed pill's location; debug
	RegConsoleCmd("sm_reset", Reset); /// Print the aimed pill's location; debug
	#endif

	g_iDebugChannel = DebugAddChannel(DEBUG_CHANNEL_NAME);
	DebugPrintToAllEx("Module is now setup");
}

/**
 * Plugin is now enabled.
 *
 * @noreturn
 */
public _HC_OnPluginEnable()
{
	if (g_iHealthStyle == REPLACE_NO_KITS) // If we do not want to replace any medkits
	{
		ResetConVar(FindConVar(CONVERT_PILLS_CVAR)); // Reset medkit conversion of pain pills cvar
		ResetConVar(FindConVar(CONVERT_PILLS_VS_CVAR));
	}
	else
	{
		SetConVarFloat(FindConVar(CONVERT_PILLS_CVAR), 0.0); // Otherwise set it 0 to disable director from spawning medkits
		SetConVarFloat(FindConVar(CONVERT_PILLS_VS_CVAR), 0.0);
	}

	HookEvent("round_start", _HC_RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", _HC_PlayerLeftSafeRoom_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", _HC_RoundEnd_Event, EventHookMode_PostNoCopy);
	HookPublicEvent(EVENT_ONMAPEND, _HC_OnMapEnd);

	UpdateHealthStyle();
	HookConVarChange(g_hHealthStyle_Cvar, _HC_HealthStyle_CvarChange);
	DebugPrintToAllEx("Module is now loaded");
}

/**
 * Plugin is now disabled.
 *
 * @noreturn
 */
public _HC_OnPluginDisable()
{
	ResetConVar(FindConVar(CONVERT_PILLS_CVAR));
	ResetConVar(FindConVar(CONVERT_PILLS_VS_CVAR));

	UnhookEvent("round_start", _HC_RoundStart_Event, EventHookMode_PostNoCopy);
	UnhookEvent("player_left_start_area", _HC_PlayerLeftSafeRoom_Event, EventHookMode_PostNoCopy);
	UnhookEvent("round_end", _HC_RoundEnd_Event, EventHookMode_PostNoCopy);
	UnhookPublicEvent(EVENT_ONMAPEND, _HC_OnMapEnd);
	UnhookPublicEvent(EVENT_ONENTITYCREATED, _HC_OnEntityCreated);
	UnhookConVarChange(g_hHealthStyle_Cvar, _HC_HealthStyle_CvarChange);

	DebugPrintToAllEx("Module is now unloaded");
}

/**
 * Map is ending.
 *
 * @noreturn
 */
public _HC_OnMapEnd()
{
	UnhookPublicEvent(EVENT_ONENTITYCREATED, _HC_OnEntityCreated);

	DebugPrintToAllEx("Map is ending, unhook OnEntityCreated");
}

public Action:_HC_CommandPrintPills(client, args)
{
	new entity = -1;
	new Float:entityPosPrint[3];
	new pillCount = 0;
	while ((entity = FindEntityByClassnameEx(entity, PAIN_PILLS_CLASSNAME)) != -1)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPosPrint);
		pillCount++;
		DebugPrintToAllEx("{ %f , %f , %f }", entityPosPrint[0], entityPosPrint[1], entityPosPrint[2]);
	}
	if ( client == 0)
	{
		PrintToServer("%i pills remaining.", pillCount);
	}
	else PrintToChat(client, "%i pills remaining.", pillCount);
	
	return Plugin_Handled;
}

#if PILLS_DEBUG
public Action:Pill(client, args)
{
    new entity = -1;
	
	if (client == 0)
    {
		return Plugin_Handled;
    }
    	
	entity = GetClientAimedLocationData(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	
	if (entity == 0)
	{
		PrintToChatAll("[PillDebug] Nothing selected");
		return Plugin_Handled;
	}
	
	new String:param[128];
	GetEdictClassname( entity, param, 128 );
	
	if (strcmp(param, PAIN_PILLS_CLASSNAME) != 0 || entity <= MaxClients)
	{
		PrintToChatAll("[PillDebug] %i is a non-valid pill entity", entity);
		return Plugin_Handled;
	}
	
	new Float:pillPosPrint[3];
    
    if (entity > MaxClients)
    {        
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pillPosPrint);
		PrintToChatAll("{ %f , %f , %f }", pillPosPrint[0], pillPosPrint[1], pillPosPrint[2]);
		PrintToChatAll("setpos %f %f %f", pillPosPrint[0], pillPosPrint[1], pillPosPrint[2]);
    }
    return Plugin_Handled;
}

public Action:Reset(client, args)
{
	g_iDebugPillArrayIndex = 0;
	PrintToChatAll("[PillDebug] g_iDebugPillArrayIndex = %i", g_iDebugPillArrayIndex);
	return Plugin_Handled;
}

public Action:Pill1(client, args)
{
    new entity = -1;
	
	if (client == 0)
    {
		return Plugin_Handled;
    }
    	
	entity = GetClientAimedLocationData(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	
	if (entity == 0)
	{
		return Plugin_Handled;
	}
	
	new String:param[128];
	GetEdictClassname( entity, param, 128 );
	
	if (strcmp(param, PAIN_PILLS_CLASSNAME) != 0 || entity <= MaxClients)
	{
		return Plugin_Handled;
	}
	
	new Float:pillPosPrint[3];
    
    if (entity > MaxClients)
    {        
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pillPosPrint);
		PrintToChatAll("fFirstPills[%i] = { %f , %f , %f };", g_iDebugPillArrayIndex, pillPosPrint[0], pillPosPrint[1], pillPosPrint[2]);
		g_iDebugPillArrayIndex++;
    }
    return Plugin_Handled;
}

public Action:Pill2(client, args)
{
    new entity = -1;
	
	if (client == 0)
    {
		return Plugin_Handled;
    }
    	
	entity = GetClientAimedLocationData(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	
	if (entity == 0)
	{
		return Plugin_Handled;
	}
	
	new String:param[128];
	GetEdictClassname( entity, param, 128 );
	

	if (strcmp(param, PAIN_PILLS_CLASSNAME) != 0 || entity <= MaxClients)
	{
		return Plugin_Handled;
	}
	
	new Float:pillPosPrint[3];
    
    if (entity > MaxClients)
    {        
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pillPosPrint);
		PrintToChatAll("fSecondPills[%i] = { %f , %f , %f };", g_iDebugPillArrayIndex, pillPosPrint[0], pillPosPrint[1], pillPosPrint[2]);
		g_iDebugPillArrayIndex++;
    }
    return Plugin_Handled;
}

public Action:Pill3(client, args)
{
    new entity = -1;
	
	if (client == 0)
    {
		return Plugin_Handled;
    }
    	
	entity = GetClientAimedLocationData(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	
	if (entity == 0)
	{
		return Plugin_Handled;
	}
	
	new String:param[128];
	GetEdictClassname( entity, param, 128 );

	if (strcmp(param, PAIN_PILLS_CLASSNAME) != 0 || entity <= MaxClients)
	{
		return Plugin_Handled;
	}
	
	new Float:pillPosPrint[3];
    
    if (entity > MaxClients)
    {        
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pillPosPrint);
		PrintToChatAll("fThirdPills[%i] = { %f , %f , %f };", g_iDebugPillArrayIndex, pillPosPrint[0], pillPosPrint[1], pillPosPrint[2]);
		g_iDebugPillArrayIndex++;
    }
    return Plugin_Handled;
}

public Action:Pill4(client, args)
{
    new entity = -1;
	
	if (client == 0)
    {
		return Plugin_Handled;
    }
    	
	entity = GetClientAimedLocationData(client, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR);
	
	if (entity == 0)
	{
		return Plugin_Handled;
	}
	
	new String:param[128];
	GetEdictClassname( entity, param, 128 );

	if (strcmp(param, PAIN_PILLS_CLASSNAME) != 0 || entity <= MaxClients)
	{
		return Plugin_Handled;
	}
	
	new Float:pillPosPrint[3];
    
    if (entity > MaxClients)
    {        
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pillPosPrint);
		PrintToChatAll("fFourthPills[%i] = { %f , %f , %f };", g_iDebugPillArrayIndex, pillPosPrint[0], pillPosPrint[1], pillPosPrint[2]);
		g_iDebugPillArrayIndex++;
    }
    return Plugin_Handled;
}

static GetClientAimedLocationData( client, Float:position[3], Float:angles[3], Float:normal[3] )
{
    new index = -1;

    decl Float:_origin[3], Float:_angles[3];
    GetClientEyePosition( client, _origin );
    GetClientEyeAngles( client, _angles );

    new Handle:trace = TR_TraceRayFilterEx( _origin, _angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayers );
    if ( !TR_DidHit( trace ) )
    { 
        ReplyToCommand( client, "[Left FORT Dead] Failed to pick the aimed location" );
        index = -1;
    }
    else
    {
        TR_GetEndPosition( position, trace );
        TR_GetPlaneNormal( trace, normal );
        angles[0] = _angles[0];
        angles[1] = _angles[1];
        angles[2] = _angles[2];

        index = TR_GetEntityIndex( trace );
    }
    CloseHandle( trace );
    
    return index;
}

public bool:TraceEntityFilterPlayers( entity, contentsMask, any:data )
{
    return entity > MaxClients && entity != data;
}

#endif

/**
 * Health style cvar changed.
 *
 * @param convar		Handle to the convar that was changed.
 * @param oldValue		String containing the value of the convar before it was changed.
 * @param newValue		String containing the new value of the convar.
 * @noreturn
 */
public _HC_HealthStyle_CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DebugPrintToAllEx("Health style cvar was changed, update style var. Old value %s, new value %s", oldValue, newValue);
	UpdateHealthStyle();
}

public _HC_PlayerLeftSafeRoom_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Then, if we're using the hardcore setting, remove all pills from the map excluding the finale sets
	if (g_iHealthStyle == SAFEROOM_AND_FINALE_PILLS_ONLY)
	{				
		// Finally: Now we either have 0 (standard) or 4 (finale) sets of pills remaining.
		// Give the survivors the pills that we've removed from the saferoom.
		GivePillsToSurvivors();
	}
	else if (g_iHealthStyle == REMOVE_ALL_BUT_FOUR)	//if finale or non indexed map, pills are given to the survivors
	{
		new map = GetCurrentMapNumber();
		if (map == 0 || map == 999)	//0 = non indexed map, 999 = finale map
		{
			GivePillsToSurvivors();
		}	
	}
}

/**
 * Called when round start event is fired.
 *
 * @param event			INVALID_HANDLE, post no copy data.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 */
public _HC_RoundStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iHealthStyle == REPLACE_NO_KITS)
	{
		DebugPrintToAllEx("Round start - Will not replace medkits");
		return; // Not replacing any medkits, return
	}
	DebugPrintToAllEx("Round start - Running health control");

	DetermineIfMapIsFinale();
	UpdateStartingHealthItems();
	
	// Hook on entity created for late spawned medkits
	HookPublicEvent(EVENT_ONENTITYCREATED, _HC_OnEntityCreated);
}

/**
 * Called when round end event is fired.
 *
 * @param event			INVALID_HANDLE, post no copy data.
 * @param name			String containing the name of the event.
 * @param dontBroadcast	True if event was not broadcast to clients, false otherwise.
 * @noreturn
 */
public _HC_RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	UnhookPublicEvent(EVENT_ONENTITYCREATED, _HC_OnEntityCreated);
	DebugPrintToAllEx("Round end");
}

/**
 * When an entity is created.
 *
 * @param entity		Entity index.
 * @param classname		Classname.
 * @noreturn
 */
public _HC_OnEntityCreated(entity, const String:classname[])
{
	// If we're running the mode where all extra pills and kits are removed, we need to jump in first
	if (g_iHealthStyle == SAFEROOM_AND_FINALE_PILLS_ONLY	&& 
		StrEqual(classname, PAIN_PILLS_CLASSNAME))
	{						
		new entRef = EntIndexToEntRef(entity);
		CreateTimer(REPLACE_DELAY, _HC_RemoveItem_Delayed_Timer, entRef);
	} 	
	else if (StrEqual(classname, FIRST_AID_KIT_CLASSNAME) && ShouldReplaceKitWithPills(entity)) 
	{		
		new entRef = EntIndexToEntRef(entity);
		CreateTimer(REPLACE_DELAY, _HC_ReplaceKit_Delayed_Timer, entRef); // Replace medkit
		DebugPrintToAllEx("Late spawned medkit, timer created. Entity %i", entity);
	}
	if (g_iHealthStyle == REMOVE_ALL_BUT_FOUR && StrEqual(classname, PIPEBOMB_NAME))
	{						
		new entRef = EntIndexToEntRef(entity);
		CreateTimer(REPLACE_DELAY, _HC_ReplacePipe_Delayed_Timer, entRef); // Replace pipe bomb
		DebugPrintToAllEx("Late spawned pipebomb, timer created. Entity %i", entity);
	}	
}

public Action:_HC_RemoveItem_Delayed_Timer(Handle:timer, any:entRef)
{
	new entity = EntRefToEntIndex(entRef);		
	SafelyRemoveEdict(entity);
	DebugPrintToAllEx("Removed item");
}

/**
 * Called when the replace pipe bomb timer interval has elapsed.
 * 
 * @param timer				Handle to the timer object.
 * @param pipeBombEntRef	Entity reference to the medkit to be removed
 * @noreturn
 */
public Action:_HC_ReplacePipe_Delayed_Timer(Handle:timer, any:pipeBombEntRef)
{
	new entity = EntRefToEntIndex(pipeBombEntRef);
	
	if (entity < 0 || entity > MAX_ENTITIES || !IsValidEntity(entity)) 
	{
		DebugPrintToAllEx("ERROR: When replacing pipe bomb, entity (index: %i) invalidated!", entity);
		return;
	}

	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);
	if (!StrEqual(classname, PIPEBOMB_NAME)) 
	{
		DebugPrintToAllEx("ERROR: was trying to replace pipe bomb, but ent %i 's classname is now %s", entity, classname);
		return;
	}

	ReplacePipeBombWithPills(entity);
}

/**
 * Called when the replace kit timer interval has elapsed.
 * 
 * @param timer			Handle to the timer object.
 * @param medkitEntRef	Entity reference to the medkit to be removed
 * @noreturn
 */
public Action:_HC_ReplaceKit_Delayed_Timer(Handle:timer, any:medkitEntRef)
{
	new entity = EntRefToEntIndex(medkitEntRef);
	
	if (entity < 0 || entity > MAX_ENTITIES || !IsValidEntity(entity)) 
	{
		DebugPrintToAllEx("ERROR: When replacing medkit or pills, entity (index: %i) invalidated!", entity);
		return;
	}

	// check just in case, by some miracle (or our own incompetence), the kit has swapped to some other entity type
	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);
	if (!StrEqual(classname, FIRST_AID_KIT_CLASSNAME)) 
	{
		DebugPrintToAllEx("ERROR: was trying to replace medkit, but ent %i 's classname is now %s", entity, classname);
		return;
	}

	ReplaceKitWithPills(entity);
}

// **********************************************
//                 Public API
// **********************************************

/**
 * Return current health style.
 *
 * @return				Health style.
 */
stock HEALTH_STYLE:GetHealthStyle()
{
	return g_iHealthStyle;
}

// **********************************************
//                 Private API
// **********************************************

/**
 * Updates the global health style variable with the cvar.
 *
 * @noreturn
 */
static UpdateHealthStyle()
{
	g_iHealthStyle = HEALTH_STYLE:GetConVarInt(g_hHealthStyle_Cvar);
	DebugPrintToAllEx("Updated global style variable; %i", int:g_iHealthStyle);
	//added to reset pain pill density once upon changing from health style 4 to something else	
	if (g_iHealthStyle == REMOVE_ALL_BUT_FOUR)
	{
		g_bPainPillDensityReset = false;
		SetConVarFloat(FindConVar("director_pain_pill_density"), 1000.0);
		SetConVarFloat(FindConVar("director_pipe_bomb_density"), 1000.0);
	}
	if (g_iHealthStyle != REMOVE_ALL_BUT_FOUR && g_bPainPillDensityReset == false)
	{
		g_bPainPillDensityReset = true;
		SetConVarFloat(FindConVar("director_pain_pill_density"), 1.0);
		SetConVarFloat(FindConVar("director_pipe_bomb_density"), 1.0);
	}
	
}

/**
 * Replaces or removes items present at the start of the round.  Logic run is based on the chosen health style.
 * 
 * @noreturn
 */
static UpdateStartingHealthItems()
{	
	DebugPrintToAllEx("Updating starting health items.");
	new entity = -1;
	
	// First, replace all starting medkits for pills.  This applies for all replacement strategies.
	while ((entity = FindEntityByClassnameEx(entity, FIRST_AID_KIT_CLASSNAME)) != -1)
	{
		if (ShouldReplaceKitWithPills(entity))
		{
			ReplaceKitWithPills(entity);
		}
	}
	
	entity = -1;
	
	// Then, if we're using the hardcore setting, remove all pills from the map excluding the finale sets
	if (g_iHealthStyle == SAFEROOM_AND_FINALE_PILLS_ONLY)
	{		
		if (g_bIsFinale)
		{
			if (g_iHealthStyle == SAFEROOM_AND_FINALE_PILLS_ONLY)
			{
				// We want to remove all the pills excluding the finale pills
				g_iSurvivorLimit = GetConVarInt(FindConVar("survivor_limit"));	//keep only x ammount of finale pills (1v1, 2v2, 3v3 support)
				decl finale_pills[4];
				if (TryGetFinalePillEntities(finale_pills))
				{
					RemoveAllPillsExcluding(finale_pills);
				}
			}
		}		
		else
		{
			RemoveAllPills();
		}
	}
	if (g_iHealthStyle == REMOVE_ALL_BUT_FOUR)
	{
		//turn all pipe bombs into pills
		while ((entity = FindEntityByClassnameEx(entity, PIPEBOMB_NAME)) != -1)
		{
			ReplacePipeBombWithPills(entity);
		}				
		DebugPrintToAllEx("delayed replacement");
		CreateTimer(0.2, _HC_RemoveAllButFour_Delayed_Timer, _, TIMER_FLAG_NO_MAPCHANGE); // Replace pipe bomb
	}
	DebugPrintToAllEx("Finished removing pills.");
}

/**
 * Called when the remove all but four interval has elapsed.
 * 
 * @param timer			Handle to the timer object.
 * @noreturn
 */
public Action:_HC_RemoveAllButFour_Delayed_Timer(Handle:timer)
{
	RemoveAllButFourPills();
}

/**
 * Removes all sets of pills from the map
 *
 * @noreturn
 */
static RemoveAllPills()
{
	DebugPrintToAllEx("Removing all pills");
	new removedCount = 0;
	new entity = -1;
	while ((entity = FindEntityByClassnameEx(entity, PAIN_PILLS_CLASSNAME)) != -1)
	{		
		if (SafelyRemoveEdict(entity))
		{			
			removedCount++;
			DebugPrintToAllEx("Removed pills (ent: %i)", entity);
		}
		else
		{
			DebugPrintToAllEx("Failed to remove pills (ent: %i)", entity);
		}
	}
	
	DebugPrintToAllEx("Removed %i sets of pills", removedCount);
}

/**
 * Removes all sets of pills, excluding 4 (partially randomized) from the map
 *
 * @noreturn
 */
static RemoveAllButFourPills()
{
	DebugPrintToAllEx("Running RemoveAllButFourPills");
	new map = GetCurrentMapNumber();
	DebugPrintToAllEx("Map number: %i", map);
	g_iSurvivorLimit = GetConVarInt(FindConVar("survivor_limit"));	
	SetConVarFloat(FindConVar("director_pain_pill_density"), 1000.0);
	SetConVarFloat(FindConVar("director_pipe_bomb_density"), 1000.0);
	
	#if !PILLS_DEBUG
	if (map == 0) //0 = non indexed map, 999 = finale map
	{
		RemoveAllPills();
		return;
	}
	#endif


	new totalCount = 0;
	new removedCount = 0;
	new entity = -1;
	while ((entity = FindEntityByClassnameEx(entity, PAIN_PILLS_CLASSNAME)) != -1)
	{
		if (!IsValidEntity(entity))
		{
			DebugPrintToAllEx("Invalid entity.  Skipping.  Entity: %i", entity);
			continue;
		}
		totalCount++;
	}
	
	new entityPills[4] = { -1, -1, -1, -1};
	GetPillEntities(map, entityPills);
	DebugPrintToAllEx("Valid pain pill entities are: %i %i %i %i", entityPills[0], entityPills[1], entityPills[2], entityPills[3]);

	entity = -1;
	
	decl finale_pills[4];
	if(g_bIsFinale)
	{
		if (TryGetFinalePillEntities(finale_pills))
		{
			DebugPrintToAllEx("Valid finale pills entities are: %i %i %i %i", finale_pills[0], finale_pills[1], finale_pills[2], finale_pills[3]);
		}
	}
	
	
	#if !PILLS_DEBUG
	while ((entity = FindEntityByClassnameEx(entity, PAIN_PILLS_CLASSNAME)) != -1)
	{
		if(g_bIsFinale)
		{
			if (entity == finale_pills[0] || entity == finale_pills[1] || entity == finale_pills[2] || entity == finale_pills[3])
			{
				DebugPrintToAllEx("Found finale pills entity %i", entity);
				continue;
			}
		}
		if (!IsValidEntity(entity))
		{
			DebugPrintToAllEx("Invalid entity.  Skipping.  Entity: %i", entity);
			continue;
		}
		if (entity == entityPills[0] || entity == entityPills[1] || entity == entityPills[2] || entity == entityPills[3])
		{
			if (entity == entityPills[0])
			{
				DebugPrintToAllEx("Found first pills entity %i", entity);
			}
			if (entity == entityPills[1])
			{
				if (g_iSurvivorLimit < 2)
				{	
					if (SafelyRemoveEdict(entity))
					{
						removedCount++;
						DebugPrintToAllEx("Found and removed second pills entity %i", entity);
					}
				}
				else DebugPrintToAllEx("Found second pills entity %i", entity);
			}
			if (entity == entityPills[2])
			{
				if (g_iSurvivorLimit < 3)
				{	
					if (SafelyRemoveEdict(entity))
					{
						removedCount++;
						DebugPrintToAllEx("Found and removed third pills entity %i", entity);
					}
				}
				else DebugPrintToAllEx("Found third pills entity %i", entity);
			}
			if (entity == entityPills[3])
			{
				if (g_iSurvivorLimit < 4)
				{	
					if (SafelyRemoveEdict(entity))
					{
						removedCount++;
						DebugPrintToAllEx("Found and removed fourth pills entity %i", entity);
					}
				}
				else DebugPrintToAllEx("Found fourth pills entity %i", entity);
			}
		}
		else
		{
			if (SafelyRemoveEdict(entity))
			{
				removedCount++;
				DebugPrintToAllEx("Removed pills entity %i", entity);
			}			
		}
	}
	#endif
	DebugPrintToAllEx("Removed %i of %i pills", removedCount, totalCount);
}

/**
 * Removes all sets of pills from the map, excluding the 4 sets contained in the supplied array
 *
 * @param pills the pills to exclude from removal
 * @noreturn
 */
static RemoveAllPillsExcluding(pills[4])
{	
	DebugPrintToAllEx("Removing all pills excluding finale pills.");
		
	new removedCount = 0;
	new entity = -1;
	while ((entity = FindEntityByClassnameEx(entity, PAIN_PILLS_CLASSNAME)) != -1)
	{		
		if (!IsValidEntity(entity))
		{
			DebugPrintToAllEx("Invalid entity.  Skipping.  Entity: %i", entity);
			continue;
		}
			
		new bool:shouldRemove = true;
		DebugPrintToAllEx("Testing ent %i (pills) to see whether we should remove it.", entity);
				
		for(new j = 0; j < g_iSurvivorLimit; j++)
		{			
			if (entity == pills[j])
			{
				DebugPrintToAllEx("Pills (ent: %i) won't be removed.", entity);
				shouldRemove = false;							
			}				
		}		

		if (shouldRemove)
		{			
			if (SafelyRemoveEdict(entity))
			{
				removedCount++;
				DebugPrintToAllEx("Removed (non-finale) pills (ent: %i)", entity);
			}
			else
			{
				DebugPrintToAllEx("Failed to remove (non-finale) pills (ent: %i)", entity);
			}
		}
	}

	DebugPrintToAllEx("Removed %i sets of pills", removedCount);
}

/**
 * Dishes out pills to the survivors
 * 
 * @noreturn
 */
static GivePillsToSurvivors()
{
	DebugPrintToAllEx("Giving pills to survivors.");
	new String:cmdGive[] = "give";
	new originalCmdFlags = GetCommandFlags(cmdGive);
	
	// Basically, make the command a non-cheat, execute it and then reset its flags.
	SetCommandFlags(cmdGive, originalCmdFlags & ~FCVAR_CHEAT);
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
		{			
			FakeClientCommand(i, "give pain_pills");
		}				
	}
	
	SetCommandFlags(cmdGive, originalCmdFlags);
}

/**
 * Determines whether the map is the finale and sets the global flag to identify it
 * 
 * @noreturn
 */
static DetermineIfMapIsFinale()
{	
	if (GetFinaleOrigin(g_vFinaleOrigin))
	{
		g_bIsFinale = true;
		DebugPrintToAllEx("Map is finale. Finale origin %f %f %f", g_vFinaleOrigin[0], g_vFinaleOrigin[1], g_vFinaleOrigin[2]);
	}
	else
	{
		g_bIsFinale = false;
		DebugPrintToAllEx("Map is not the finale");
	}
}

/**
 * Predicate used to determine whether we should replace kits with pills
 * @param entity 	medkit entity to be considered for replacement
 * @return			whether the kit should be replaced with pills
 */
static bool:ShouldReplaceKitWithPills(entity)
{
	if (g_bIsFinale && 
		g_iHealthStyle == REPLACE_ALL_BUT_FINALE_KITS && 
		EntityIsInsideFinaleArea(entity))
	{
		// Finale medkit and we're not replacing them; can't touch this!
		return false;					
	}			
	
	return true;
}

/**
 * Replaces medkit with pills unless the health style precludes it
 * @param entity the medkit entity to be considered for replacement
 * @noreturn				
 */
static ReplaceKitWithPills(entity)
{	
	new result = ReplaceEntity(entity, PAIN_PILLS_CLASSNAME, MODEL_PAIN_PILLS, 1);
	if (!result)
	{
		ThrowError("Failed to replace medkit with pills! Entity %i", entity);
	}
	DebugPrintToAllEx("Medkit (entity %i) replaced with pills (entity %i)", entity, result);	
}

/**
 * Replaces pipe bomb with pills unless the health style precludes it
 * @param entity the medkit entity to be considered for replacement
 * @noreturn				
 */
static ReplacePipeBombWithPills(entity)
{	
	new result = ReplaceEntity(entity, PAIN_PILLS_CLASSNAME, MODEL_PAIN_PILLS, 1);
	if (!result)
	{
		ThrowError("Failed to replace pipe bomb with pills! Entity %i", entity);
	}
	DebugPrintToAllEx("Pipe Bomb (entity %i) replaced with pills (entity %i)", entity, result);	
}

/**
 * Determines whether an entity is within a given radius of the finale trigger
  *
 * @param entity the entity
 * @return whether the entity is inside the finale radius.
 */
static bool:EntityIsInsideFinaleArea(entity)
{	
	decl Float:origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	if (GetVectorDistance(g_vFinaleOrigin, origin) <= KIT_FINALE_AREA) 
	{
		DebugPrintToAllEx("Entity (entity %i) is within finale area", entity);
		return true; 
	}
	
	return false;	
}

/**
 * Attempts to find the 4 sets of pills closest to the finale trigger.  
 *
 * Note: We can't just check for the pills being inside a radius around the finale trigger
 * like for the medkits as, unlike medkits, extra pills can be spawned within the finale radius.
 *
 * @param outFinalePills the array into which, if found, the finale pill entities will be placed.  If the pills could not be found, the array members will be set to -1
 * @return whether the pills were found or not.  Check the return value before doing anything with the results.
 */
static bool:TryGetFinalePillEntities(outFinalePills[4])
{	
	if (!g_bIsFinale)	
	{
		return false;			
	}
	
	// run through all the pill spawns and find the 4 pill spawns that are closest to the survivors	
	new Float:closestDistances[4] = { 9999999999.0, 9999999999.0, 9999999999.0, 9999999999.0 };	
	outFinalePills[0] = -1;
	outFinalePills[1] = -1;
	outFinalePills[2] = -1;
	outFinalePills[3] = -1;
	
	new entity = -1;	
	decl Float:entityPos[3];
	
	while ((entity = FindEntityByClassnameEx(entity, PAIN_PILLS_CLASSNAME)) != -1)
	{		
		if (!IsValidEntity(entity))
			continue;
			
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityPos);
		
		new Float:distance = GetVectorDistance(entityPos, g_vFinaleOrigin);
		
		// basically, what we want to do is move left, shifting the elements we encounter
		// until we encounter one that is smaller than our inserted distance, then insert the new element		
		if (closestDistances[3] > distance)
		{
			new i = 3;
			while (i > 0 && closestDistances[i] > distance)
			{	
				closestDistances[i] = closestDistances[i - 1];
				outFinalePills[i] = outFinalePills[i - 1];				
				
				i--;
			}	
			
			// we have the index and the rest of the array has been bumped down by now; insert our new data
			closestDistances[i] = distance;	
			outFinalePills[i] = entity;
		}		
	}	
	
	DebugPrintToAllEx("Distances of pills from finale (we're keeping these ones):");
	for(new j = 0; j < 4; j++)
	{
		DebugPrintToAllEx("ent id: %i, distance: %f", outFinalePills[j], closestDistances[j] );
	}
	
	return true;
}

/**
 * Wrapper for printing a debug message without having to define channel index
 * everytime.
 *
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
static DebugPrintToAllEx(const String:format[], any:...)
{
	decl String:buffer[DEBUG_MESSAGE_LENGTH];
	VFormat(buffer, sizeof(buffer), format, 2);
	DebugPrintToAll(g_iDebugChannel, buffer);
}