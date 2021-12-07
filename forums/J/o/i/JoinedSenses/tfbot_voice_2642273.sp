#include <sourcemod>
#include <tf2_stocks>

#pragma newdecls required
#pragma semicolon 1

#define FRAME_LIMIT 120

int g_iFrame;

public Plugin myinfo = {
	name = "TFBot Voice",
	author = "EfeDursun125",
	description = "TFBots now uses voice commands.",
	version = "1.0",
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

public void OnGameFrame() {
	if (g_iFrame < FRAME_LIMIT) {
		++g_iFrame;
		return;
	}

	g_iFrame = 0;

	int health;
	int maxhealth;

	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || !IsFakeClient(i) || !IsPlayerAlive(i)) {
			continue;
		}

		health = GetEntProp(i, Prop_Send, "m_iHealth");
		maxhealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");

		if (health <= (maxhealth / 2)) {
			int slot = GetActiveSlot(i);

			switch (TF2_GetPlayerClass(i)) {
				case TFClass_Scout: {
					switch (slot) {
						case 0: FakeClientCommand(i, "voicemenu 0 0");
						case 1: FakeClientCommand(i, "voicemenu 2 0");
					}
				}
				case TFClass_Sniper: {
					switch (slot) {
						case 0: FakeClientCommand(i, "voicemenu 0 0");
						case 1: FakeClientCommand(i, "voicemenu 2 0");
						case 2: FakeClientCommand(i, "voicemenu 1 1");
					}
				}
				case TFClass_Soldier: {
					switch (slot) {
						case 0: FakeClientCommand(i, "voicemenu 0 0");
						case 1: FakeClientCommand(i, "voicemenu 2 0");
						case 2: FakeClientCommand(i, "voicemenu 0 0");
					}
				}
				case TFClass_DemoMan: {
					switch (slot) {
						case 0: FakeClientCommand(i, "voicemenu 0 0");
						case 1: FakeClientCommand(i, "voicemenu 1 1");
						case 2: FakeClientCommand(i, "voicemenu 0 0");
					}
				}
				case TFClass_Medic: {
					switch (slot) {
						case 0: FakeClientCommand(i, "voicemenu 2 0");
						case 1: FakeClientCommand(i, "voicemenu 0 0");
						case 2: FakeClientCommand(i, "voicemenu 1 7");
					}
					if (health < 50) {
						SetEntProp(i, Prop_Data, "m_nButtons", GetClientButtons(i)|IN_ATTACK2);
					}
				}
				case TFClass_Heavy: {
					switch (slot) {
						case 0: FakeClientCommand(i, "voicemenu 0 0");
						case 1: FakeClientCommand(i, "voicemenu 1 4");
						case 2: FakeClientCommand(i, "voicemenu 0 0");
					}
				}
				case TFClass_Pyro: {
					switch (slot) {
						case 0: FakeClientCommand(i, "voicemenu 0 0");
						case 1: FakeClientCommand(i, "voicemenu 2 0");
					}
				}
				case TFClass_Spy: {
					FakeClientCommand(i, "voicemenu 0 0");
				}
				case TFClass_Engineer: {
					switch (slot) {
						case 0: FakeClientCommand(i, "voicemenu 2 0");
						case 1: FakeClientCommand(i, "voicemenu 0 %i", GetRandomInt(2, 5));
						case 2: FakeClientCommand(i, "voicemenu 0 0");
					}
				}
			}
		}
	}
}

int GetActiveSlot(int client) {
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	for (int i = 0; i < 3; i++) {
		if (GetPlayerWeaponSlot(client, i) == weapon) {
			return i;
		}
	}

	return 0;
}
