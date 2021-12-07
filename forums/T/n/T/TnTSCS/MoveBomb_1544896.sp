/* 
* 	DESCRIPTION:
* 		This plugin will move the planted bomb to your players feet (or the feet of the player
* 		you're spectating), or, if you're in free camera mode, it will put the bomb at eye level
* 
* 		This plugin is designed to be for fun.  For when chicken CTs don't try to defuse, admins
* 		can "move" the bomb so that it will explode near the fleeing CT.
* 
* 		It is defaulted to allow admins with CHEAT flag persmission to use this command.  You can
* 		customize access to this command using the admin_overrides.cfg and adding whatever flag 
* 		you want to the "allow_movebomb", example:
* 		"allow_movebomb"	"o"
* 		That would set the permission for this command to be CUSTOM1 flag
* 
* 
*	CREDITS:
* 		* xaider for code samples from Advanced Commands
* 
* 		* Bacardi for previous plugin help with the NoBombDamage
* 			- OnEntityCreated and OnEntityDestroyed
* 
*	Changelog
*		Version 1.0
*			*	Initial public release
* 
* 		Version 1.1
* 			*	Changed from RegConsoleCmd to RegAdminCmd for sm_movebomb
* 
* 		Version 1.2
* 			*	Removed unneeded SDKHooks and OnConfigsExecuted per Bacardi's suggestions
* 				-	Thanks for advising me of the error of my ways (one I should have known of)
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new planted_c4 = -1;

public Plugin:myinfo = 
{
	name = "Move Bomb",
	author = "TnTSCS aka ClarkKent",
	description = "Will move the bomb after it has been planted",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_movebomb_buildversion",SOURCEMOD_VERSION, "This version of SourceMod that 'Move Bomb' was built on ", FCVAR_PLUGIN);
	CreateConVar("sm_movebomb_version", PLUGIN_VERSION, "Move Bomb Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// I chose sm_movebomb because RedSword's plugin 'Bomb Commands' uses sm_getbomb
	// He should implement this into his plugin :)
	RegAdminCmd("sm_movebomb", MoveBomb, ADMFLAG_CHEATS, "Moves the planted bomb");
	
	// Hook the events for switching the bomb as planted or not
	HookEvent("bomb_planted", IsBombPlanted);
	HookEvent("round_start", IsBombPlanted);
}

public IsBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(StrEqual(name, "bomb_planted")) // Check if event was "bomb_planted"
	{
		// Find entity and return it by index. If it's not found, then it returns as -1
		planted_c4 = FindEntityByClassname(planted_c4, "planted_c4");
	}
	else
	{
		planted_c4 = -1;
	} 
}


public Action:MoveBomb(client, args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] You cannot use sm_movebomb from console");
		return Plugin_Handled;
	}
	
	if(planted_c4 == -1)
	{
		ReplyToCommand(client, "\x04[\x03SM\x04] Bomb has not been planted yet.");
		return Plugin_Handled;
	}

	// Code sampled from xaider's Advanced Commands plugin - Thank you!!
	new Float:origin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
	
	TeleportEntity(planted_c4, origin, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}