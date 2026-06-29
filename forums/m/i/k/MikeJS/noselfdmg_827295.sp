#pragma semicolon 1
#include <sourcemod>
#include <tf2damage>
public Action:TF2_PlayerHurt(client, attacker, damage, health) {
	if(client==attacker)
		return Plugin_Handled;
	return Plugin_Continue;
}