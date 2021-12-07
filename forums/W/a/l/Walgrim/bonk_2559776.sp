#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin myinfo =
{
	name = "[TF2] Bonk",
	author = "Walgrim",
	description = "Bonk is back on Sandman.",
	version = "1.0",
	url = "http://steamcommunity.com/id/walgrim/"
};

public OnClientPutInServer(client) {
  if (IsClientInGame(client)) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
  }
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom) {
  new wepindex = (IsValidEntity(weapon) && weapon > MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
  if (wepindex == 44) {
		decl Float:fClientLocation[3], Float:fClientEyePosition[3];
		GetClientAbsOrigin(attacker, fClientEyePosition);
		GetClientAbsOrigin(client, fClientLocation);

		decl Float:fDistance[3];
		MakeVectorFromPoints(fClientLocation, fClientEyePosition, fDistance);
		float dist = GetVectorLength(fDistance);
		//PrintToChat(attacker, "\x04Distance: %2.f", dist); //See the distances between the ball and the client.
		if (dist >= 128.0 && dist <= 256.0) {
			TF2_StunPlayer(client, 1.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		else if (dist >= 256.0 && dist < 512.0) {
			TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		else if (dist >= 512.0 && dist < 768.0) {
			TF2_StunPlayer(client, 3.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		else if (dist >= 768.0 && dist < 1024.0) {
			TF2_StunPlayer(client, 4.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		else if (dist >= 1024.0 && dist < 1280.0) {
			TF2_StunPlayer(client, 5.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		else if (dist >= 1280.0 && dist < 1536.0) {
			TF2_StunPlayer(client, 6.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		else if (dist >= 1536.0 && dist < 1792.0) {
			TF2_StunPlayer(client, 7.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker);
		}
		else if (dist >= 1792.0) {
			TF2_StunPlayer(client, 7.0, 0.0, TF_STUNFLAGS_BIGBONK, attacker);
		}
  }
  return Plugin_Changed;
}
