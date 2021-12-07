/**
* CS:GO Admin ESP by Root
*
* Description:
*   Plugin show positions of all players through walls to admin when he/she is observing, dead or spectate.
*
* Version 2.1
* Changelog & more info at http://goo.gl/4nKhJ
*/

// ====[ INCLUDES ]=======================================================================
#undef REQUIRE_EXTENSIONS
#include <cstrike> // included for constatnts
#include <sdkhooks> // optional transmit hook for skins
#undef REQUIRE_PLUGIN
#tryinclude <CustomPlayerSkins> // for colored glow

// ====[ CONSTANTS ]======================================================================
#define PLUGIN_NAME    "CS:GO Admin ESP"
#define PLUGIN_VERSION "2.1"

// ====[ VARIABLES ]======================================================================
new	Handle:AdminESP,
#if defined _CustomPlayerSkins_included
	Handle:AdminESP_Mode,
	Handle:AdminESP_Dead,
	Handle:AdminESP_TColor,
	Handle:AdminESP_CTColor,
#endif
	Handle:mp_teammates_are_enemies,
	bool:IsUsingESP[MAXPLAYERS + 1];

// ====[ PLUGIN ]=========================================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "ESP/WH for Admins",
	version     = PLUGIN_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=211117"
}


/* OnPluginStart()
 *
 * When the plugin starts up.
 * --------------------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Magical cvar to enable glows on everyone
	mp_teammates_are_enemies = FindConVar("sv_competitive_official_5v5");

	// Log error and disable plugin if mod is not supported
	if (mp_teammates_are_enemies == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Could not find \"mp_teammates_are_enemies\" console variable! Disabling plugin...");
	}

	// Create plugin console variables on success
	CreateConVar("sm_csgo_adminesp_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AdminESP         = CreateConVar("sm_csgo_adminesp",         "1",             "Whether or not automatically enable ESP/WH when Admin with cheat flag (\"n\" by default) is observing",  FCVAR_PLUGIN, true, 0.0, true, 1.0);
#if defined _CustomPlayerSkins_included
	AdminESP_Mode    = CreateConVar("sm_csgo_adminesp_mode",    "0",             "Determines a glow mode for Admin ESP:\n0 = Red glow (old)\n1 = Colored glow (might be cpu intensive!)",  FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AdminESP_Dead    = CreateConVar("sm_csgo_adminesp_dead",    "1",             "Sets when automatically enable colored glow:\n0 = Enable ESP on spawning\n1 = Enable in observing mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	AdminESP_TColor  = CreateConVar("sm_csgo_adminesp_tcolor",  "192 160 96 64", "Determines R G B A glow colors for Terrorists team\nSet to \"0 0 0 0\" to disable",                      FCVAR_PLUGIN);
	AdminESP_CTColor = CreateConVar("sm_csgo_adminesp_ctcolor", "96 128 192 64", "Determines R G B A glow colors for Counter-Terrorists team\nFormat should be \"R G B A\" (with spaces)", FCVAR_PLUGIN);
#endif
	// Command to toggle Admin ESP
	RegConsoleCmd("sm_esp", Command_ToggleESP, "Toggles glow on all players for users with \"csgo_admin_esp_cmd\" override access");

	// Hook main ConVar change
	HookConVarChange(AdminESP, OnConVarChange);

	// Manually trigger OnConVarChange to hook needed events
	OnConVarChange(AdminESP, "0", "1");

	// Auto generate plugin config
	AutoExecConfig(true, "csgo_admin_esp");
}

/* OnConVarChange()
 *
 * Called when a convar's value is changed.
 * --------------------------------------------------------------------------------------- */
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Since old/newValue's is strings, convert them to integers
	switch (StringToInt(newValue))
	{
		// Unhook plugin events on its disabling
		case false:
		{
			UnhookEvent("player_spawn", OnPlayerEvents, EventHookMode_Post);
			UnhookEvent("player_death", OnPlayerEvents, EventHookMode_Post);
			UnhookEvent("player_team",  OnPlayerEvents, EventHookMode_Post);
		}
		case true:
		{
			HookEvent("player_spawn", OnPlayerEvents, EventHookMode_Post);
			HookEvent("player_death", OnPlayerEvents, EventHookMode_Post);
			HookEvent("player_team",  OnPlayerEvents, EventHookMode_Post);
		}
	}
}

/* OnPlayerEvents()
 *
 * Called when player spawns, dies or changes team.
 * --------------------------------------------------------------------------------------- */
public OnPlayerEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Retrieve client ID from event
	new clientID = GetEventInt(event, "userid");
	new client   = GetClientOfUserId(clientID);

	if (IsValidClient(client))
	{
		// Called when the player spawns
		if (name[7] == 's')
		{
#if defined _CustomPlayerSkins_included
			if (GetConVarBool(AdminESP_Mode))
			{
				// Attach custom player model and enable glow after 0.1 delay on respawning
				CreateTimer(0.1, Timer_SetupGlow, clientID, TIMER_FLAG_NO_MAPCHANGE);

				// Skip disabling glow if alive ESP is set
				if (!GetConVarBool(AdminESP_Dead))
				{
					return;
				}
			}
#endif
			if (IsUsingESP[client])
			{
				// Otherwise disable ESP
				ToggleAdminESP(client, false);
			}
		}
		else if (CheckCommandAccess(client, "csgo_admin_esp", ADMFLAG_CHEATS))
		{
			// Check access and enable ESP when admin dies or changes the team
			ToggleAdminESP(client, true);
		}
	}
}

/* Command_ToggleESP()
 *
 * Command to enable/disable ESP for single Admin.
 * --------------------------------------------------------------------------------------- */
public Action:Command_ToggleESP(client, args)
{
	// At first check whether or not client can access to ESP/WH
	if (GetConVarBool(AdminESP) && CheckCommandAccess(client, "csgo_admin_esp_cmd", ADMFLAG_CHEATS))
	{
		// Toggle ESP correctly
		IsUsingESP[client] = !IsUsingESP[client];
		ToggleAdminESP(client, IsUsingESP[client]);
	}

	// Supress 'Unknown command' in client console
	return Plugin_Handled;
}
#if defined _CustomPlayerSkins_included
/* Timer_SetupGlow()
 *
 * Sets player skin and enables glow.
 * --------------------------------------------------------------------------------------- */
public Action:Timer_SetupGlow(Handle:timer, any:client)
{
	// Validate client on delayed callback
	if ((client = GetClientOfUserId(client)))
	{
		decl String:model[PLATFORM_MAX_PATH];

		// Retrieve current player model
		GetClientModel(client, model, sizeof(model));

		// Remove old custom skin and create a new one with same model as player
		CPS_RemoveSkin(client); // Does not make the model invisible. (useful for glows) (c) CustomPlayerSkins.inc file
		CPS_SetSkin(client, model, CPS_RENDER);

		// Retrieve skin entity from core plugin
		new skin = CPS_GetSkin(client);

		// Validate skin entity by SDKHookEx native return
		if (SDKHookEx(skin, SDKHook_SetTransmit, OnSetTransmit))
		{
			// Declare convar strings to properly colorize players
			decl String:color[16], String:pieces[4][sizeof(color)];

			// Get values from plugin convars
			switch (GetClientTeam(client))
			{
				case CS_TEAM_T:  GetConVarString(AdminESP_TColor,  color, sizeof(color));
				case CS_TEAM_CT: GetConVarString(AdminESP_CTColor, color, sizeof(color));
			}

			// Get rid of spaces to get all the RGBA values
			if (ExplodeString(color, " ", pieces, sizeof(pieces), sizeof(pieces[])) == 4)
			{
				// Enable glow on prop_physics_override entity, aka custom player skin
				SetupGlow(skin, StringToInt(pieces[0]), StringToInt(pieces[1]), StringToInt(pieces[2]), StringToInt(pieces[3]));
			}
		}
	}
}

/* OnSetTransmit()
 *
 * Transmit hook for custom player skins.
 * --------------------------------------------------------------------------------------- */
public Action:OnSetTransmit(entity, client)
{
	// Dont show custom player skins if player is not observing/using ESP
	return !IsUsingESP[client] ? Plugin_Handled : Plugin_Continue;
}

/* SetupGlow()
 *
 * Sets glow for player assigned skins depends on their team and a color settings.
 * --------------------------------------------------------------------------------------- */
SetupGlow(entity, r, g, b, a)
{
	static offset;

	// Get sendprop offset for prop_dynamic_override
	if (!offset && (offset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1)
	{
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return;
	}

	// Enable glow for custom skin
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);

	// So now setup given glow colors for the skin
	SetEntData(entity, offset, r, _, true);    // Red
	SetEntData(entity, offset + 1, g, _, true) // Green
	SetEntData(entity, offset + 2, b, _, true) // Blue
	SetEntData(entity, offset + 3, a, _, true) // Alpha
}
#endif
/* ToggleAdminESP()
 *
 * Enables or disables ESP for Admin.
 * --------------------------------------------------------------------------------------- */
ToggleAdminESP(client, bool:value)
{
	// Assign global boolean same as value
	IsUsingESP[client] = value;

	// Check for ESP mode (if available)
#if defined _CustomPlayerSkins_included
	if (!GetConVarBool(AdminESP_Mode))
#endif
		// Toggle old (red) glow for all players
		SendConVarValue(client, mp_teammates_are_enemies, value ? "1" : "0");
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * --------------------------------------------------------------------------------------- */
bool:IsValidClient(client)
{
	// Bots should be ignored (because their glow skin won't be removed after controlling)
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;
}