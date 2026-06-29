#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

new bool:IsRoundEnd = false;

new Float:g_fBreakDistance = 150.00;
new Handle:v_BreakDistance = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Spawn Stickybomb Removal",
	author = "DarthNinja",
	description = "Prevents players from sticky-camping spawn doors",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("spawn_sticky_removal", PLUGIN_VERSION, "Plugin Version", FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("teamplay_round_active", OnRoundStart);

	v_BreakDistance = CreateConVar("sticky_break_distance", "150.0", "Stickies closer then this to a spawn door will be removed.", 0, true, 0.0);
	HookConVarChange(v_BreakDistance, OnConVarChanged);
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_fBreakDistance = StringToFloat(newVal);
}

public OnMapStart()
{
	CreateTimer(1.0, ScanStickyLocations, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action:ScanStickyLocations(Handle:timer)
{
	if (IsRoundEnd)
		return Plugin_Continue;	// End of round, woo!

	new iSticky = -1;
	while ((iSticky = FindEntityByClassname(iSticky, "tf_projectile_pipe_remote")) != -1) //Called for every sticky bomb on the server
	{
		new Float:stickyloc[3];
		GetEntPropVector(iSticky, Prop_Send, "m_vecOrigin", stickyloc);

		new iSpawn = -1;
		while ((iSpawn = FindEntityByClassname(iSpawn, "func_respawnroomvisualizer")) != -1)
		{
			//Location check
			new Float:spawnloc[3];
			GetEntPropVector(iSpawn, Prop_Send, "m_vecOrigin", spawnloc);

			//PrintToChatAll("Sticky: %i (%f,%f,%f) is\x07ff00ff %f\x01 from Spawn: %i (%f,%f,%f)\n", iSticky, stickyloc[0], stickyloc[1], stickyloc[2], GetVectorDistance(stickyloc, spawnloc), iSpawn, spawnloc[0], spawnloc[1], spawnloc[2]);
			if (GetVectorDistance(stickyloc, spawnloc) < g_fBreakDistance)
			{
				//Sticky is too close to a door
				// Make sure the player isnt stickycamping their own spawn
				if (GetEntProp(iSticky, Prop_Send, "m_iTeamNum") == GetEntProp(iSpawn, Prop_Send, "m_iTeamNum"))
				{
					//PrintToChatAll("iSticky %i is too close but is also on the same team! (Distance: %f)", iSticky, GetVectorDistance(stickyloc, spawnloc));
					continue;	// Player is stickying their own spawn, so we can leave it alone
				}
				// not on the same team, so lets kill it
				AcceptEntityInput(iSticky, "Kill");	// Replace with dealdamage at some point
				//PrintToChatAll("iSticky %i was too close and has been removed (Distance: %f)", iSticky, GetVectorDistance(stickyloc, spawnloc));
				new owner = GetEntPropEnt(iSticky, Prop_Send, "m_hThrower");
				if (owner > 0 && owner <= MaxClients)
					PrintHintText(owner, "Please do not sticky camp spawnrooms!");
				break;	// Sticky is gone, break out of any more checks on it
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsRoundEnd = false;
}
public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	IsRoundEnd = true;
}
