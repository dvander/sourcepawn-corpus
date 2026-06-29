#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo =
{
	name = "Give C4",
	author = "Boncey",
	description = "Gives C4 to player with !c4 and my first plugin!",
	version = "1.0",
	url = "http://www.thewarpdimension.com"
};

new Handle:g_pointsCvar

public OnPluginStart()
{
	//Register the console & chat command
	RegConsoleCmd("sm_c4", Command_GiveC4);
	
	// Create the minimum point CVAR
	g_pointsCvar = CreateConVar("sm_c4_points", 
								"250", 
								"How many points to buy C4?",
								FCVAR_NOTIFY,
								true,
								Float:1,
								false);
}

public Action:Command_GiveC4(client, args)
{
// Check if player is a T, if not display a message.

	if (GetClientTeam(client) == 2){
	// Check if the T has enough points to buy a C4, if not display message.
	
		if (CS_GetClientContributionScore(client) >= GetConVarInt(g_pointsCvar)){
		// Give them a C4 and take away the points.
		
			GivePlayerItem(client, "weapon_c4");
													// Takeaway score from CVar value.
			CS_SetClientContributionScore(client, CS_GetClientContributionScore(client) - GetConVarInt(g_pointsCvar));
			
		} else { 
			PrintHintText(client, "You require %i more points to buy a bomb.", GetConVarInt(g_pointsCvar) - CS_GetClientContributionScore(client)); 
			}
			
	} else { 
		PrintHintText(client, "You are not a terrorist."); 
		}
		
	return Plugin_Handled;
}