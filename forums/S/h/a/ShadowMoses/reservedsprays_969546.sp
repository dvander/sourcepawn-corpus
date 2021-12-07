/* reservedsprays.sp
 * ============================================================================
 *  Reserved Sprays Change Log
 * ============================================================================
 *  1.0.0
 *  - Initial release.
 * ============================================================================
 */
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Reserved Sprays",
	author = "ShadowMoses",
	description = "Removes player spray unless they have reserved slot access.",
	version = VERSION,
	url = "http://www.thinking-man.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_reservedsprays_version", VERSION, "Reserved sprays version.",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddTempEntHook("Player Decal",PlayerSpray);
}

public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay)
{
	new client = TE_ReadNum("m_nPlayer");
	if(client && IsClientInGame(client))
	{		
		if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
			return Plugin_Continue;
		else
		{
			PrintToChat(client, "\x04[Reserved Sprays]\x03Sorry, sprays can only be used by donating members.");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}