#include <sdktools>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "[Timer] NoJail",
	author = "Smesh; Credit: Zipcore",
	description = "[Timer] Block/Disable maps logic timers.",
	version = "1.0",
	url = "forums.alliedmods.net/showthread.php?p=2074699"
};

new String:EntityList[][] = {"logic_auto", "logic_timer", "team_round_timer", "logic_relay", "*jail", "jail*", "*jail*", "jail", "*JAIL", "JAIL*", "*JAIL*", "JAIL", "*Jail", "Jail*", "*Jail*", "Jail"};

public OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iEnt;
	for(new i = 0; i < sizeof(EntityList); i++)
	{
		while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
		{
			AcceptEntityInput(iEnt, "Disable");
			AcceptEntityInput(iEnt, "Kill");
		}
	}
}
