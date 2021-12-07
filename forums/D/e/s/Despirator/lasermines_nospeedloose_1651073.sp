#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <lasermines>
#include <zr_lasermines>
#include <zriot_lasermines>

new g_Offset_m_flVelocityModifier = -1;

public OnClientPutInServer(client)
{
	decl String:netclass[64];
	GetEntityNetClass(client, netclass, sizeof(netclass));
	g_Offset_m_flVelocityModifier = FindSendPropInfo(netclass, "m_flVelocityModifier");
}

public OnPostHitByLasermine(victim, attacker, beam, lasermine, damage)
{
	ResetSpeed(victim);
}

public ZR_OnPostHitByLasermine(victim, attacker, beam, lasermine, damage)
{
	ResetSpeed(victim);
}

public ZRiot_OnPostHitByLasermine(victim, attacker, beam, lasermine, damage)
{
	ResetSpeed(victim);
}

ResetSpeed(client)
{
	SetEntDataFloat(client, g_Offset_m_flVelocityModifier, 1.0, true);
}