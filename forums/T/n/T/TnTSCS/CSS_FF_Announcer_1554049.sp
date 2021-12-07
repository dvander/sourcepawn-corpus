/*
 * Friendly Fire Announcer
 
 A CSS version of Frustian's L4D FF Announce Plugin - reworked just a bit
 
	* CHANGE LOG 
	
	Version 1.0.0
		* Initial Release
		
	Version 1.0.1
		* Fixed Native "KillTimer" reported: Invalid timer handle
 */

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION	"1.0.1"

new Handle:ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;
new bool:TimerExists[MAXPLAYERS+1] = false;
new bool:AdminOnT = false;
new bool:AdminOnCT = false;
new bool:NotifyAdmin = true;

new String:weapon_name[64];

public Plugin: myinfo =
{
	name = "CSS Friendly Fire Announcer",
	author = "TnTSCS aka ClarkKent",
	description = "Announces to admins when friendly fire incidents occur",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	// Create My ConVars
	CreateConVar("sm_cssffannouncer_version", PLUGIN_VERSION, "CSS Friendly Fire Announcer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	new Handle:hRandom;// KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_cssffannouncer_notify", "1", "Set to 1 to always notify admins on all FF incidents that occur on the opposite team they're on, or set to 0 to only notify admins of all FF incidents that occur on the opposite team if there is no admin on that team.", _, true, 0.0, true, 1.0)), OnNotifyChanged);
	NotifyAdmin = GetConVarBool(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles.
	
	// Hook the player_hurt event
	HookEvent("player_hurt", Event_PlayerHurt);
}

public OnNotifyChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	NotifyAdmin = GetConVarBool(cvar);
}

public Event_PlayerHurt(Handle: event, const String: name[], bool: dontBroadcast)
{
	// Get victim and attacker Client IDs
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// If self inflicted damage, absense of attacker/victim, attacker isn't a player or is a bot, stop processing
	if(victim == attacker || !victim || !attacker || attacker > MaxClients || attacker < 1 || IsFakeClient(attacker) || IsFakeClient(victim))
		return;
	
	// Get victim and attacker teams
	new victim_team = GetClientTeam(victim);
	new attacker_team = GetClientTeam(attacker);
	
	// If victim is not on the same team as the attacker, or the attacker is not on a team, stop processing
	if(victim_team != attacker_team || attacker_team <= 1)
		return;
	
	// Get the damage amount, armor amount, and weapon name from this event
	new damage_health = GetEventInt(event, "dmg_health");
	new damage_armor = GetEventInt(event, "dmg_armor");
	GetEventString(event, "weapon", weapon_name, sizeof(weapon_name));
	
	// Print damage information to all admins' consoles
	NotifyAdminConsole(attacker, victim, damage_armor, damage_health, weapon_name);
	
	// As long as there isn't already a timer for the attacker, continue processing by gonig to NoTimer
	if(!TimerExists[attacker])
		NoTimer(attacker);
}

public NoTimer(client)
{
	if(TimerExists[client])
		return;
	
	// If sm_cssffannouncer_notify is set to 1, notify all admins who are on the opposite team of the attacker who is committing Friendly Fire
	if(NotifyAdmin)
	{
		ClientTimer[client] = CreateTimer(1.0, NotifyAdminChat, client);// Create timer
		TimerExists[client] = true;// Set timer for attacker to TRUE
		return;
	}
	
	// Find out if there are admins on either team
	AdminCheck();
	
	//If attacker is a Terrorst and there are no admins on Terrorist team
	if(GetClientTeam(client) == 2 && !AdminOnT)
	{
		ClientTimer[client] = CreateTimer(1.0, NotifyAdminChat, client);
		TimerExists[client] = true;
	}
	else if(GetClientTeam(client) == 3 && !AdminOnCT)// else if attacker is on CT and there are no admins on CT team
	{
		ClientTimer[client] = CreateTimer(1.0, NotifyAdminChat, client);
		TimerExists[client] = true;
	}
}

public NotifyAdminConsole(any:attacker, any:victim, any:armordmg, any:healthdmg, const String:weapon[])
{
	// Get the names of the attacker and victim
	decl String:attacker_name[64];
	decl String:victim_name[64];
	GetClientName(attacker, attacker_name, sizeof(attacker_name));
	GetClientName(victim, victim_name, sizeof(victim_name));
	
	// Run through each player and determine if they are an admin
	for (new i = 1; i <= MaxClients; i++)
	{
		// If admin has GENERIC flag (or overridden for "notify_ff"
		if(CheckCommandAccess(i, "notify_ff", ADMFLAG_GENERIC))
		{
			// Print Friendly Fire information to Admins' console (this prints for every incident of FF, regardless of what team the attacker or admin is on)
			PrintToConsole(i, "[%s] attacked [%s] - [damage: %i] - [armor: %i] - [weapon: %s]", attacker_name, victim_name, healthdmg, armordmg, weapon);
		}
	}
}

public Action:NotifyAdminChat(Handle:timer, any:attacker)
{
	if(IsClientInGame(attacker))
	{
		// Set timer for attacker to FALSE
		TimerExists[attacker] = false;

		// Run through each player and determine if they are an admin
		for (new i = 1; i <= MaxClients; i++)
		{
			// If admin has GENERIC flag (or overridden for "notify_ff"
			if(CheckCommandAccess(i, "notify_ff", ADMFLAG_GENERIC))
			{
				// Only notify admins on opposite team of attacker that a FF incident occurred
				if(GetClientTeam(i) != GetClientTeam(attacker))
				{
					// Get the name of the attacker
					decl String:attacker_name[64];
					GetClientName(attacker, attacker_name, sizeof(attacker_name));
					
					// Print Friendly Fire incident to admins on opposite team than attacker.  This message will only print if attacker team attacks 1 second after their last incident.
					PrintToChat(i, "\x05-ADMIN NOTIFY- \x04[\x03%s\x04] attacked a teammate, check your console for details", attacker_name);
				}
			}
		}
	}
}

public AdminCheck()
{
	// Set variables to false
	AdminOnT = false;
	AdminOnCT = false;
	
	// Run through each client and determine if they are an admin
	for (new i = 1; i <= MaxClients; i++)
	{
		// If admin has GENERIC flag (or overridden for "notify_ff"
		if(CheckCommandAccess(i, "notify_ff", ADMFLAG_GENERIC))
		{
			// If there's an admin on the Terrorst team, set AdminOnT to true
			if(GetClientTeam(i) == 2)
				AdminOnT = true;
			
			// If there's an admin on the CT team, set AdminOnCT to true
			if(GetClientTeam(i) == 3)
				AdminOnCT = true;
		}
	}
}