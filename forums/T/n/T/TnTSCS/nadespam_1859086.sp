#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#define VERSION "1.0.1"

new Handle:HEGrenadeAmmo = INVALID_HANDLE;
new HEGrenadeAmmoAmount;
new Handle:SmokeGrenadeAmmo = INVALID_HANDLE;
new SmokeGrenadeAmmoAmount;
new Handle:FlashbangAmmo = INVALID_HANDLE;
new FlashbangAmmoAmount;

new HEGBuyCount[MAXPLAYERS+1];
new SGBuyCount[MAXPLAYERS+1];
new FBBuyCount[MAXPLAYERS+1];

new bool:enabled;

new Handle:cvarEnableNadeSpamPrevent;

public Plugin:myinfo = 
{
	name = "Grenade Spam Prevention",
	author = "FlyingMongoose | TnTSCS",
	description = "Prevents people from buying more than their first set of grenades",
	version = VERSION,
	url = "http://www.interwavestudios.com/"
}

public OnPluginStart()
{
	CreateConVar("nadespam_version",VERSION, _,FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnableNadeSpamPrevent = CreateConVar("sm_preventnadespam","1","Enables/Disables nade spam prevention",FCVAR_PLUGIN,true,0.0,true,1.0);
	enabled = GetConVarBool(cvarEnableNadeSpamPrevent);
	HookConVarChange(cvarEnableNadeSpamPrevent, EnabledChanged);
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	
	// ======================================================================
	if ((HEGrenadeAmmo = FindConVar("ammo_hegrenade_max")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_hegrenade_max");
	}
	HookConVarChange(HEGrenadeAmmo, HEGrenadeAmmoChanged);
	HEGrenadeAmmoAmount = GetConVarInt(HEGrenadeAmmo);
	
	if ((SmokeGrenadeAmmo = FindConVar("ammo_smokegrenade_max")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_smokegrenade_max");
	}
	HookConVarChange(SmokeGrenadeAmmo, SmokeGrenadeAmmoChanged);
	SmokeGrenadeAmmoAmount = GetConVarInt(SmokeGrenadeAmmo);
	
	if ((FlashbangAmmo = FindConVar("ammo_flashbang_max")) == INVALID_HANDLE)
	{
		SetFailState("Unable to locate CVar ammo_flashbang_max");
	}
	HookConVarChange(FlashbangAmmo, FlashbangAmmoChanged);
	FlashbangAmmoAmount = GetConVarInt(FlashbangAmmo);	
	// ======================================================================
}

/**
 * Called when a player attempts to purchase an item.
 * Return Plugin_Continue to allow the purchase or return a
 * higher action to deny.
 *
 * @param client		Client index
 * @param weapon	User input for weapon name (shortname like hegrenade, knife, or awp)
 */
public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (!enabled)
	{
		return Plugin_Continue;
	}
	
	/* Check if client is buying nade type and if it's allowed or not
	* Purchase allowed with Plugin_Continue
	* Purchase prohibited with Plugin_Handled
	*/
	if (StrEqual(weapon, "hegrenade", false))
	{
		if (HEGBuyCount[client] >= HEGrenadeAmmoAmount)
		{
			PrintToChat(client, "You are only allowed %i HE grenade per round", HEGrenadeAmmoAmount);
			return Plugin_Handled;
		}
		
		HEGBuyCount[client]++;
		return Plugin_Continue;
	}
	else if (StrEqual(weapon, "flashbang", false))
	{
		if (FBBuyCount[client] >= FlashbangAmmoAmount)
		{
			PrintToChat(client, "You are only allowed %i FlashBangs per round", FlashbangAmmoAmount);
			return Plugin_Handled;
		}
		
		FBBuyCount[client]++;
		return Plugin_Continue;
	}
	else if (StrEqual(weapon, "smokegrenade", false))
	{
		if (SGBuyCount[client] >= SmokeGrenadeAmmoAmount)
		{
			PrintToChat(client, "You are only allowed %i Smoke Grenade per round", SmokeGrenadeAmmoAmount);
			return Plugin_Handled;
		}
		
		SGBuyCount[client]++;
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

/**
 * Client has spawned.
 * 
 * @param event				The event handle.
 * @param name				The name of the event.
 * @param dontBroadcast 		Don't tell clients the event has fired.
 */
public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client <= 0 || client > MaxClients)
	{
		return;
	}
	
	HEGBuyCount[client] = 0;
	FBBuyCount[client] = 0;
	SGBuyCount[client] = 0;
}

public EnabledChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	enabled = GetConVarBool(cvar);
	LogMessage("ENABLED value changed from %s to %s", oldValue, newValue);
}

public HEGrenadeAmmoChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	HEGrenadeAmmoAmount = GetConVarInt(cvar);
}

public FlashbangAmmoChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	FlashbangAmmoAmount = GetConVarInt(cvar);
}

public SmokeGrenadeAmmoChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	SmokeGrenadeAmmoAmount = GetConVarInt(cvar);
}