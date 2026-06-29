#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks> // http://forums.alliedmods.net/showthread.php?t=106748
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "2.0.0"

new Handle:h_Enabled;
new Handle:h_AdminI;

new bool:b_sdkhookloaded = false;

public Plugin:myinfo =
{
	name = "[TF2] Caution: Fire Spreads!",
	author = "EHG (Modded by Calystos)",
	description = "Fire spreads from player to player on touch",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=144298"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SDKHook"); // This needs to be marked optional for a number of reasons
	return APLRes_Success;
}

public OnPluginStart()
{
	new String:game[10];
	GetGameFolderName(game, sizeof(game));
	if(!StrEqual(game, "tf"))
	{
		SetFailState("This plugin only works for Team Fortress 2");
	}

	CreateConVar("tf2_fire_spreads_version", PLUGIN_VERSION, "Caution: Fire Spreads! Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	h_Enabled = CreateConVar("tf2_fire_spreads", "1", "Enable/Disable fire spreading", FCVAR_PLUGIN);
	h_AdminI = CreateConVar("tf2_fire_spreads_admin_immunity", "0", "Enable/Disable admin immunity", FCVAR_PLUGIN);
}

public OnAllPluginsLoaded()
{
	b_sdkhookloaded = GetExtensionFileStatus("sdkhooks.ext") == 1;
	if (b_sdkhookloaded)
		HookAllClients();
}

HookAllClients()
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_Touch, SpreadFire);
		}
}

public OnClientPutInServer(client)
{
	// No point hooking if the systems not enabled
	if (b_sdkhookloaded)
	{
		SDKHook(client, SDKHook_Touch, SpreadFire);
	}
}

public SpreadFire(client, target)
{
	// Check to make sure the plugin is enabled and has enough clients playing
	if (GetConVarInt(h_Enabled) == 1 && client <= MaxClients && client >= 1 && target <= MaxClients && target >= 1)
	{
		// Check if user is an Admin, and if Admin Immunity is set, if so don't pass on fire to them
		if (GetConVarInt(h_AdminI) == 1 && GetUserAdmin(target) != INVALID_ADMIN_ID)
		{
			// Target is an Admin, Admin Immunity is enabled so ignore the target
			return;
		}

		// Check if the client player is on fire, if so set the target/touched player on fire too!
		if (TF2_IsPlayerInCondition(client, TFCond_OnFire))
		{
			// Set target/touched player on fire
			TF2_IgnitePlayer(target, client);
		}
	}
}