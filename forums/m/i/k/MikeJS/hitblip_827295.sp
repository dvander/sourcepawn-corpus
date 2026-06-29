#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2damage>
public OnMapStart() {
	PrecacheSound("buttons/button17.wav");
}
public Action:TF2_PlayerHurt(client, attacker, damage, health) {
	if(attacker>0 && client!=attacker) {
		new pitch = 150-damage;
		if(pitch<45)
			pitch = 45;
		EmitSoundToClient(attacker, "buttons/button17.wav", _, _, _, _, 1.0, pitch);
	}
	return Plugin_Continue;
}