#pragma semicolon 1

#include <sourcemod>
#include <dukehacks>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name        = "Admin FF Only",
	author      = "Antithasys",
	description = "Allows admins to kill everyone",
	version     = PLUGIN_VERSION,
	url         = "http://projects.mygsn.net"
};

/**
 * Globals
 */

new bool:g_bPlayerIsAdmin[MAXPLAYERS + 1];

new Handle:aff_adminflag = INVALID_HANDLE;
new String:g_sAdminFlag[5];

/**
 * Plugin Forwards
 */
public OnPluginStart()
{

	/**
	Create console variables
	*/
	CreateConVar("aff_version", PLUGIN_VERSION, "Admin FF Only", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	aff_adminflag = CreateConVar("aff_adminflag", "a", "Admin flag to use for friendly fire.  Must be a in char format.");
	
	/**
	Add dukehacks forward
	*/
	dhAddClientHook(CHK_TakeDamage, Hacks_TakeDamageHook);
	
}

public OnConfigsExecuted()
{
	GetConVarString(aff_adminflag, g_sAdminFlag, sizeof(g_sAdminFlag));
}


/**
 * Client Forwards
 */
public OnClientPostAdminCheck(client)
{

	if(!client || IsFakeClient(client))
		return;
	
	/**
	Get the client and flags
	*/
	decl String:sFlags[15];
	GetNativeString(2, sFlags, sizeof(sFlags));
	new ibFlags = ReadFlagString(sFlags);
	
	/**
	Check the flags
	*/
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags || GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		g_bPlayerIsAdmin[client] = true;
	}
	else
	{
		g_bPlayerIsAdmin[client] = false;
	}
}

public OnClientDisconnect(client)
{

	/**
	Cleanup client
	*/
	g_bPlayerIsAdmin[client] = false;
}

public Action:Hacks_TakeDamageHook(client, attacker, inflictor, Float:damage, &Float:multiplier, damagetype)
{

	/**
	Check for a valid client and attacker
	*/
	if (client > 0 && client <= MaxClients && attacker > 0 && attacker <= MaxClients)
	{
		
		/**
		Make sure they aren't hurting themselves
		*/
		if (client == attacker)
		{
			
			/**
			They are, bug out
			*/
			return Plugin_Continue;
		}
		
		/**
		Get the teams
		*/
		new iTeamClient = GetClientTeam(client);
		new iTeamAttacker = GetClientTeam(attacker);
		
		/**
		Make sure they are on the same team
		*/
		if (iTeamClient != iTeamAttacker)
		{
			
			/**
			They aren't, bug out
			*/
			return Plugin_Continue;
		}
		else
		{
			
			/**
			Since they are on the same team, check if attacker is admin
			*/
			if (!g_bPlayerIsAdmin[attacker])
			{
				
				/**
				The attacker is NOT an admin, null the damage
				*/
				multiplier *= 0.0;
				return Plugin_Changed;
			}
		}
	}
	
	/**
	We are done, bug out
	*/
	return Plugin_Continue;
}