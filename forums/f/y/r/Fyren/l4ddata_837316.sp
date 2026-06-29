#include <sourcemod>

#pragma semicolon 1

public Plugin:myinfo =
{
	name = "L4D data",
	author = "Fyren",
	description = "",
	version = "",
	url = ""
};

new Float:pos[15][3];

public eventAbility(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:playerName[MAX_NAME_LENGTH];
	GetClientName(user, playerName, sizeof(playerName));

	GetClientAbsOrigin(user, pos[user]);

	decl String:ability[256];
	GetEventString(event, "ability", ability, sizeof(ability));
	//new context = GetEventInt(event, "context");

	//PrintToChatAll("%s -> %s: %s (%d)", name, playerName, ability, context);
}

public eventPounced(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hunter = GetClientOfUserId(GetEventInt(event, "userid"));
	new Float:hunterPos[3];

	GetClientAbsOrigin(hunter, hunterPos);
	new calc = RoundToNearest(GetVectorDistance(pos[hunter], hunterPos));

	new survivor = GetClientOfUserId(GetEventInt(event, "victim"));
	new distance = GetEventInt(event, "distance");

	new Float:posH[3];
	posH = pos[hunter];
	posH[2] = 0.0;
	new Float:hunterPosH[3];
	hunterPosH = hunterPos;
	hunterPosH[2] = 0.0;
	new calcH = RoundToNearest(GetVectorDistance(posH, hunterPosH));

	new bool:has_upgrade = GetEventBool(event, "has_upgrade");

	PrintToChatAll("%s -> %N pounced %N: evdist=%d / dist=%d / hdist=%d (%s)", name, hunter, survivor, distance, calc, calcH, has_upgrade ? "true" : "false");
	PrintToChatAll("%d damage?", ((calc - 300) > 0) ? RoundToNearest((calc - 300.0) / 28.0) : 0);
}

public OnPluginStart()
{
	HookEvent("lunge_pounce", eventPounced);
	HookEvent("ability_use", eventAbility);
}
