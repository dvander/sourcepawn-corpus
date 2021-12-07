#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

// ==========================================================================================================
// PLUGIN DESCRIPTION
//
// "Trigger"
// A means of easily triggering any Input on any entity. Based on work on "Trigger Mapentity"
// by HSFighter but improved so as to not require a class name, trigger ALL matching entities,
// and accept wildcards, enabling it to effectively mimic the "ent_fire" cheat command without
// using cheats. I have since expanded this plugin to allow for the triggering of entities
// not normally reachable by "ent_fire", such as unnamed entities.
//
// USAGE:
// Although I have only personally used this plugin with TF2, this plugin should be mod-agnostic.
// Simply load the plugin to enable the commands, unload to disable.
// Due to the potential danger of these commands, all commands by default require the ROOT
// admin flag to execute.
// You may change this below by altering the TRIGGER_PERMISSION #define entry.
// "sm_trigger" and "sm_findentities" can be used from the server console (though @aim cannot
// be used). "sm_aimentity" cannot as live presence is required.
//
// CONSOLE VARIABLES (CVARS):
// sm_trigger_version - Version of this plugin for update tracking.
//
// COMMANDS:
// sm_trigger <entity> [input] [value]
// This is the main command and works just like the "ent_fire" command, down to the use of wildcards,
// a numeric entry (#<entity), or the "@aim" keyword (in-game only) to trigger any solid entity in
// the crosshairs.
// 
// sm_findentity <entity>
// This is a debugging command primarily intended for use with map makers and map testers.
// It uses the ability to locate entries contained in this plugin to identify any entities that
// match your input.
//
// sm_aimentity
// This allows you to point your in-game crosshairs at any solid entity and learn more about it,
// enabling you to Trigger it if you wish. Note that untouchable entities like triggers and nonsolid
// func_brushes will not be seen by this command. However, it WILL see entities that are
// SELECTIVELY solid (like func_respawnroomvisualizer and func_clip_vphysics).
//
// DISCLAIMER
// You assume all responsibility for any unwanted effects created by the use of this plugin.
// This plugin does not perform any automated effects. Use at your own risk.
//
// LICENSE
// Trigger is released under the terms of the GNU General Public License (GPL), Version 3.
// The full text can be located at http://gplv3.fsf.org/
// All terms and conditions of the license apply.
//
// SIGNED
// WhosAsking?, GmodTech group (http://gmodtech.net)
// ==========================================================================================================

// ==========================================================================================================
// PLUGIN HISTORY
//
// 0.1 - 2012/04/17 - Initial release. Can only trigger the FIRST instance of a given entity.
// 0.2 - 2013/08/21 - Can now trigger and find ALL instances of a given name.
// 1.0 - 2013/08/22 - MILESTONE RELEASE. Now accepts wildcards. Should be functionally equal to "ent_fire"
// 1.1 - 2013/09/12 - Can now target entities by number or by aim using the "@aim" keyword.
//                    Made "sm_findentity" available in-game.
//                    Added "sm_aimentity" to identify aimed entities.
//                    Added several entity classes to list of defaults and altered the list structure
//                    for better organization.					
// ==========================================================================================================

// ==========================================================================================================
// DEFINED CONSTANTS
// ==========================================================================================================
#define PLUGIN_NAME			"Trigger"					// Plugin name.
#define PLUGIN_VERSION		"1.1"						// Plugin version.
#define ARG_SIZE			64							// Maximum length of arguments.
#define TRIGGER_PERMISSION	ADMFLAG_ROOT				// Permission needed to use trigger command

#define TRIGGER_INVALID		-1							// Return value for when an invalid entity was triggered.
#define TRIGGER_NODEFAULT	-2							// Return value for when a trigger found no default action.
#define TRIGGER_NOCLASS		-3							// Return value for when a trigger entity's class couldn't be found.

// ==========================================================================================================
// PLUGIN DEFINITION
// ==========================================================================================================
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "WhosAsking?",
	description = "Easily trigger any map entity without having to enable cheating",
	version = PLUGIN_VERSION,
	url = "http://www.gmodtech.net"
}

// ==========================================================================================================
// LOCAL VARIABLES
// ==========================================================================================================
new MaxEntities;										// Placeholder for maximum possible entities.
new MaxDefault = 0;										// Placeholder for the endpoint of the defaults array.

new String:DefaultClasses[][ARG_SIZE] =					// A list of entity classes for which defaults are available. 
{														// followed by their default actions.
	"env_beam",						"Toggle",
	"env_blood",					"EmitBlood",
	"env_bubbles",					"Toggle",
	"env_dustpuff",					"SpawnDust",
	"env_embers",					"Use",
	"env_fire",						"StartFire",
	"env_laser",					"Toggle",
	"env_message",					"ShowMessage",
	"env_physexplosion",			"Explode",
	"env_physimpact",				"Impact",
	"env_shooter",					"Shoot",
	"env_smokestack",				"Toggle",
	"env_soundscape",				"ToggleEnabled",
	"env_spark",					"ToggleSpark",
	"env_splash",					"Splash",
	"env_sprite",					"ToggleSprite",
	"env_steam",					"ToggleSprite",
	"func_areaportal",				"Toggle",
	"func_breakable",				"Break",
	"func_brush",					"Toggle",
	"func_button",					"Press",
	"func_door",					"Toggle",
	"func_door_rotating",			"Toggle",
	"func_occluder",				"Toggle",
	"func_physbox", 				"Break",
	"func_physbox_multiplayer",		"Break",
	"func_platrot",					"Toggle",
	"func_rot_button",				"Press",
	"game_end",						"EndGame",
	"game_score",					"ApplyScore",
	"game_text",					"Display",
	"game_zone_player",				"CountPlayersInZone",
	"gibshooter",					"Shoot",
	"light",						"Toggle",
	"light_directional",			"Toggle",
	"light_dynamic",				"Toggle",
	"logic_branch",					"Test",
	"logic_branch_listener",		"Test",
	"logic_case",					"PickRandom",
	"logic_compare",				"Compare",
	"logic_multicompare",			"CompareValues",
	"logic_navigation",				"Toggle",
	"logic_timer",					"Toggle",
	"logic_relay",					"Trigger",
	"move_rope",					"Break",
	"path_track",					"TogglePath",
	"phys_ballsocket",				"Break",
	"phys_constraint",				"Break",
	"phys_convert",					"ConvertTarget",
	"phys_hinge",					"Break",
	"phys_lengthconstraint",		"Break",
	"phys_pulleyconstraint",		"Break",
	"phys_ragdollconstraint",		"Break",
	"phys_slideconstraint",			"Break",
	"point_anglesensor",			"Toggle",
	"point_angularvelocitysensor",	"Test",
	"point_hurt",					"Hurt",
	"point_proximity_sensor",		"Toggle",
	"point_teleport",				"Teleport",
	"point_template",				"ForceSpawn",
	"prop_door_rotating",			"Toggle",
	"trigger_changelevel",			"ChangLevel",
	"trigger_gravity",				"Toggle",
	"trigger_hurt",					"Toggle",
	"trigger_look",					"Toggle",
	"trigger_multiple",				"Toggle",
	"trigger_once",					"Toggle",
	"trigger_playermovement",		"Toggle",
	"trigger_proximity",			"Toggle",
	"trigger_push",					"Toggle",
	"trigger_remove",				"Toggle",
	"trigger_soundscape",			"Toggle",
	"trigger_teleport",				"Toggle",
	"trigger_wind",					"Toggle",
	// DO NOT REMOVE THIS! AND KEEP IT LAST!
	// This blank string is used to detect the end of the list and get a count.
	""
};

// ==========================================================================================================
// PLUGIN INITIALIZATIONS
// ==========================================================================================================
// ------------------------------------------------------------------
// OnPluginStart()
// General plugin initialization.
// ------------------------------------------------------------------
public OnPluginStart()
{
	// Just to make sure all the non-networked entities are picked up.
	MaxEntities = GetMaxEntities() * 2;
	
	// Report version
	CreateConVar("sm_trigger_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Create admin commands
	RegAdminCmd("sm_trigger", Command_Trigger, TRIGGER_PERMISSION);
	RegAdminCmd("sm_findentity", Command_Find, TRIGGER_PERMISSION);
	RegAdminCmd("sm_aimentity", Command_Aim, TRIGGER_PERMISSION);
	
	// Count off default actions until we hit the end.
	while (DefaultClasses[MaxDefault][0])
		 MaxDefault += 2;
}

// ==========================================================================================================
// LOCAL FUNCTIONS
// ==========================================================================================================
// ------------------------------------------------------------------
// FindEntityWildcard(Name, Start)
// This will locate the first entity (optionally past a certain point)
// matching a name. The * wildcard is supported here.
//
// Name     - Name (or wildcard) of the entity to match.
// Start    - Do not search entities up to this one.
//            This is best for repeat searching.
//            Defaults to -1, which means search from the beginning.
// RETURNS  - The first entity to match the name or wildcard if found,
//            INVALID_ENT_REFERENCE if none is found.
// ------------------------------------------------------------------
FindEntityWildcard(const String:Name[], const Start = -1)
{
	// To hold the name taken from the entity being checked.
	decl String:TempName[ARG_SIZE];
	
	// First, find the "*" wildcard. If it's present, we truncate the search limit.
	new StringLimit = StrContains(Name, "*");
	
	// If no match is found, reset to the entire length, to include the terminating NULL.
	// There's a sanity check, in case the entity name is malformed.
	if (StringLimit < 0)
		StringLimit = (strlen(Name) < ARG_SIZE) ? strlen(Name) + 1 : ARG_SIZE;
	
	// Go through the entries from the start until the limit is reached.
	for (new i = Start + 1; i < MaxEntities ; i++)
	{
		// If the entity is invalid, skip to the next entity.
		if (!IsValidEntity(i))
			continue;
		
		// Get the entity's name to compare.
		GetEntPropString(i, Prop_Data, "m_iName", TempName, ARG_SIZE);
		
		// We use strncmp since it allows to limit the length of the search,
		// in case the "*" is present.
		if (strncmp(Name, TempName, StringLimit, false) == 0)
			// We have a match. Stop processing and return the match.
			return i;
	}
	
	// No match. Return the invalid reference.
	return INVALID_ENT_REFERENCE;
}

// ------------------------------------------------------------------
// TriggerEntity(Entity, Input, Value)
// This will perform the actual triggering of the entity
//
// Client    - Client calling for the trigger.
// Entity    - Entity to be triggered.
// Input     - The input to trigger. If blank, a default is attempted.
//             Will store found input for return if successful.
// Value     - Override value to send to input if any.
// ClassName - Will hold the class detected if any for default action.
// RETURNS   - 0 if successful, a negative error condition otherwise.
// ------------------------------------------------------------------
TriggerEntity(const Client, const Entity, String:Input[], const String:Value[], String:ClassName[])
{
	// If no input was stated, we attempt a default based on the class name.
	if (!Input[0])
	{
		// First, test if the Entity is valid.
		if (!IsValidEntity(Entity))
			return TRIGGER_INVALID;
		
		// Now retrieve the entity's class name.
		GetEntPropString(Entity, Prop_Data, "m_iClassname", ClassName, ARG_SIZE);
		
		// If we have a class name, cycle through class names with known defaults until we find a match.
		if (ClassName[0])
		{
			new Index;
			
			for (Index = 0; Index < MaxDefault; Index+= 2)
				// If we have a match, break the loop.
				if (StrEqual(ClassName, DefaultClasses[Index]))
					break;
					
			// We'll know we have a match if Index isn't at the max.
			// We'll set Input to this.
			if (Index < MaxDefault)
				strcopy(Input, ARG_SIZE, DefaultClasses[Index + 1]);
			// No match found.
			else
				return TRIGGER_NODEFAULT;
		}
		// We couldn't find a class name for some reason.
		else
			return TRIGGER_NOCLASS;
	}

	// If Value is non-blank, set the Variant.
	if (Value[0])
		SetVariantString(Value);

	// If we have an input, fire the input.
	// We assume the Client to be the Activator.
	if (Input[0])
	{
		AcceptEntityInput(Entity, Input, Client);
	}
	
	return 0;
}

// ==========================================================================================================
// PLUGIN HOOKS AND COMMANDS
// ==========================================================================================================
// ------------------------------------------------------------------
// Command_Trigger(Client, ArgCount)
// This command handler finds all instances of the given
// entity and fires the desired input. If a "#<number>" is given,
// then that numbered entity is triggered. If "@aim" is given,
// then the entity in the player's crosshairs is targeted.
//
// Client   - Client who called the command, 0 if server console.
// ArgCount - Number of arguments passed with the command.
// RETURNS  - Plugin_Handled
// ------------------------------------------------------------------
public Action:Command_Trigger(Client, ArgCount)
{
	// String variables to hold the parameters.
	decl String:Input[ARG_SIZE] = "";
	decl String:Value[ARG_SIZE] = "";
	decl String:Name[ARG_SIZE] = "";
	decl String:ClassName[ARG_SIZE] = "";
	
	// Base case: no entity name given.
	// Display command format and exit.
	GetCmdArg(0, Name, ARG_SIZE);
	if (ArgCount < 1)
	{
		ReplyToCommand(Client, "\x03[Trigger]\x01 FORMAT: %s <entity> [input] [value]", Name);
		return Plugin_Handled;
	}
	
	// Get the target entity name.
	GetCmdArg(1, Name, ARG_SIZE);
	
	// Check for server console using @aim.
	if (StrEqual(Name, "@aim", false) && Client < 1)
	{
		ReplyToCommand(Client, "[Trigger] @aim target is for players only.");
		return Plugin_Handled;
	}

	// Extract an input name if there is one and hold it for later.
	if (ArgCount > 1)
		GetCmdArg(2, Input, ARG_SIZE);

	// Extract an input value if there is one and hold it for later.
	if (ArgCount > 2)
		GetCmdArg(3, Value, ARG_SIZE);

	// Test for a "#" prefix, indicating an entity number target,
	// and the "@aim" string, indicating an aim target.
	// Both indicate a single-entity target.
	if ((Name[0] == '#') || (StrEqual(Name, "@aim", false)))
	{
		// If the name's a number, extract the number from the rest of the string
		// Otherwise, it's "@aim", use the target aiming function.
		new Entity = (Name[0] == '#')  ? StringToInt(Name[1])
									   : GetClientAimTarget(Client, false);
		
		// Check for an invalid aim target first.
		if (Entity == -1)
		{
			ReplyToCommand(Client, "\x03[Trigger]\x01 No solid entity to trigger.");
			return Plugin_Handled;
		}
		
		// Check for any other invalid entity number.
		if (Entity < 1 || Entity >= MaxEntities)
		{
			ReplyToCommand(Client, "\x03[Trigger]\x01 Invalid entity #%d.", Entity);
			return Plugin_Handled;
		}
		
		// Now process the trigger and its return.
		switch(TriggerEntity(Client, Entity, Input, Value, ClassName))
		{
			// Case TRIGGER_INVALID means the input given was invalid 
			// entity class lacks a default action.
			case TRIGGER_INVALID:
			{
				ReplyToCommand(Client, "\x03[Trigger]\x01 Entity #%d does not exist.", Entity);
			}
			// Case TRIGGER_NODEFAULT means no input was given and the
			// entity class lacks a default action.
			case TRIGGER_NODEFAULT:
			{
				ReplyToCommand(Client, "\x03[Trigger]\x01 Cannot find default action for entity #%d (class '%s').", Entity, ClassName);
			}
			// Case TRIGGER_NOCLASS means no input was given and the
			// entity's class could not be determined.
			case TRIGGER_NOCLASS:
			{
				ReplyToCommand(Client, "\x03[Trigger]\x01 Cannot find class name for entity #%d.", Entity);
			}
			// Default means the trigger was done. Report to user.
			default:
			{
				ReplyToCommand(Client, "\x03[Trigger]\x01 Triggered input '%s' of entity #%d.", Input, Entity);
			}
		}
		// We're done.
		return Plugin_Handled;
	}
	
	// Default case: we'll perform a name match.
	new Entity = FindEntityWildcard(Name);

	// Couldn't find one.
	// Report error and exit.
	if (!IsValidEntity(Entity))
	{
		ReplyToCommand(Client, "\x03[Trigger]\x01 Entity '%s' not found.", Name);
		return Plugin_Handled;
	}
	
	// Temporary placeholder for Inputs if original was blank.
	decl String:TempInput[ARG_SIZE];
	
	// Found one match. Loop through ALL of them.
	while (IsValidEntity(Entity))
	{
		// Reset the input string in case it was originally blank.
		strcopy(TempInput, ARG_SIZE, Input);

		// Now process the trigger and its return.
		switch(TriggerEntity(Client, Entity, TempInput, Value, ClassName))
		{
			// Case TRIGGER_NODEFAULT means no input was given and the
			// entity class lacks a default action.
			case TRIGGER_NODEFAULT:
			{
				ReplyToCommand(Client, "\x03[Trigger]\x01 Cannot find default action for entity '%s' (class '%s').", Name, ClassName);
			}
			// Case TRIGGER_NOCLASS means no input was given and the
			// entity's class could not be determined.
			case TRIGGER_NOCLASS:
			{
				ReplyToCommand(Client, "\x03[Trigger]\x01 Cannot find class name for entity '%s'.", Name);
			}
			// Default means the trigger was done. Report to user.
			default:
			{
				ReplyToCommand(Client, "\x03[Trigger]\x01 Triggered input '%s' of '%s'.", TempInput, Name);
			}
		}
		
		// Now, go find the next one.
		Entity = FindEntityWildcard(Name, Entity);
	}
	
	// We're done.
	return Plugin_Handled;
}

// ------------------------------------------------------------------
// Command_Trigger(Client, ArgCount)
// This is a debug commaned meant for map making and map testing.
// It will return all instances of a given entity name.
//
// Client   - Client who called the command, 0 if server console.
// ArgCount - Number of arguments passed with the command.
// RETURNS  - Plugin_Handled
// ------------------------------------------------------------------
public Action:Command_Find(Client, ArgCount)
{
	decl String:Arg[ARG_SIZE];
	decl String:Name[ARG_SIZE];
	decl String:ClassName[ARG_SIZE];
	
	// Default for when no paramater is given.
	GetCmdArg(0, Arg, ARG_SIZE);
	if (ArgCount < 1)
	{
		ReplyToCommand(Client, "\x03[Trigger]\x01 FORMAT: %s <entity>", Arg);
		return Plugin_Handled;
	}
	
	// Get the entity's name and begin searching.
	GetCmdArg(1, Arg, ARG_SIZE);
	ReplyToCommand(Client, "\x03[Trigger] --- Search for entities named '%s':\x01", Arg);
	new Entity = FindEntityWildcard(Arg);
	
	// Continue for all matches.
	while (IsValidEntity(Entity))
	{
		// Get the entity's name, in case of a wildcard use.
		GetEntPropString(Entity, Prop_Data, "m_iName", Name, ARG_SIZE);
		// Get the entity's class name.
		GetEntPropString(Entity, Prop_Data, "m_iClassname", ClassName, ARG_SIZE);

		// Report the finding.
		ReplyToCommand(Client, "Entity #%d '%s' found, classname '%s'.", Entity, Name, ClassName);
		
		// Now, go find the next one.
		Entity = FindEntityWildcard(Arg, Entity);
	}

	// End the command output.
	ReplyToCommand(Client, "\x03--- Search Complete.\x01");
	
	return Plugin_Handled;
}

// ------------------------------------------------------------------
// Command_Aim(Client, ArgCount)
// This is a debug commaned meant for map making and map testing.
// This is an in-game command only available to clients.
// It will return any entity being aimed at by the player.
//
// Client   - Client who called the command, 0 if server console.
// ArgCount - Number of arguments passed with the command.
// RETURNS  - Plugin_Handled
// ------------------------------------------------------------------
public Action:Command_Aim(Client, ArgCount)
{
	// This command is only available to players.
	if (Client < 1)
	{
		ReplyToCommand(Client, "[Trigger] Command is for players only.");
		return Plugin_Handled;
	}
	
	// Variables to store the aim target.
	new Target;
	
	// Get the aim target.
	Target = GetClientAimTarget(Client, false);
	
	switch (Target)
	{
		// A return of -2 means the game doesn't implement
		// this feature.
		case -2:
		{
			ReplyToCommand(Client, "\x03[Trigger]\x01 Aiming is not implemented in this game.");
		}
		// A return of -1 means no entity was targeted.
		case -1:
		{
			ReplyToCommand(Client, "\x03[Trigger]\x01 No solid entity targeted.");
		}
		// The default case is we found a target.
		default:
		{
			// Temporary string to hold extracted names.
			decl String:Temp[ARG_SIZE];
			
			ReplyToCommand(Client, "\x03[Trigger]\x01 Aiming at entity #%d", Target);
			// Get the entity's name (if any).
			GetEntPropString(Target, Prop_Data, "m_iName", Temp, ARG_SIZE);
			// Is the name non-blank?
			if (Temp[0])
				ReplyToCommand(Client, "Entity named '%s'", Temp);
			else
				ReplyToCommand(Client, "Entity unnamed.");
			// Now report the entity's class name.
			GetEntPropString(Target, Prop_Data, "m_iClassname", Temp, ARG_SIZE);
			ReplyToCommand(Client, "Entity of class '%s'", Temp);
		}
	}
	return Plugin_Handled;
}

