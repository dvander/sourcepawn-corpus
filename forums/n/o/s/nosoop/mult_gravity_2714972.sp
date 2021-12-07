/**
 * mult_gravity
 * 
 * Sets a gravity multiplier on the given player.
 */
#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required

#include <sdkhooks>
#include <tf2attributes>

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_GroundEntChangedPost, OnGroundEntChangedPost);
}

public void OnGroundEntChangedPost(int client) {
	SetEntityGravity(client, TF2Attrib_HookValueFloat(1.0, "mult_gravity", client));
}
