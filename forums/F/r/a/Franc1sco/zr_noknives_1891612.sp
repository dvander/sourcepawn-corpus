#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>
#include <cssthrowingknives>
#pragma semicolon 1


public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	SetClientThrowingKnives(client, 0);
}