#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
new attempt[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "l4d2_ty_giver",
	author = "TY",
	description = "l4d2_ty_giver",
	version = "1.0.3",
	url = "www.russerver.com"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("map_transition", Event_maptransition);
}

public Action:Event_maptransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientInGame(i)) {
			if (GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
				if (GetPlayerWeaponSlot(i, 0) > -1) {
					RemovePlayerItem(i, GetPlayerWeaponSlot(i, 0));
				}
			}
		}
	}
}

public Action:attempt_give_weapons(Handle:timer, any:client)
{
	if (!client)
		return Plugin_Stop;

	if (!IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) != 2) {
		if (attempt[client]++ < 60)
			CreateTimer(0.5, attempt_give_weapons, client);
		return Plugin_Stop;
	}

	attempt[client] = 0;
	give_weapons(client);
	return Plugin_Stop;
}

public Precached_weapons()
{
	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl"))
		PrecacheModel("models/v_models/v_snip_awp.mdl");

	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl"))
		PrecacheModel("models/v_models/v_snip_scout.mdl");

	if (!IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl"))
		PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");

	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl"))
		PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");

	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl"))
		PrecacheModel("models/w_models/weapons/w_m60.mdl");

	if (!IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl"))
		PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");

	if (!IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl"))
		PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");

	if (!IsModelPrecached("models/v_models/v_rif_sg552.mdl"))
		PrecacheModel("models/v_models/v_rif_sg552.mdl");

	if (!IsModelPrecached("models/v_models/v_smg_mp5.mdl"))
		PrecacheModel("models/v_models/v_smg_mp5.mdl");

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2) {
			attempt[i] = 0;
			CreateTimer(1.1, attempt_give_weapons, i);
		}
	}
}

public Action:Timer_RoundStart(Handle:timer, any:client)
{
	Precached_weapons();
	return Plugin_Stop;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Timer_RoundStart);
	return Plugin_Continue;
}

stock create_weapons(client, String:command[], String:arguments[] = "")
{
	if (client) {
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	}
}

public give_weapons(client)
{
	if (!client || !IsClientConnected(client))
		return;

	if (!IsClientInGame(client))
		return;

	if (GetClientTeam(client) != 2)
		return;

	if (!IsPlayerAlive(client))
		return;

	if (GetPlayerWeaponSlot(client, 0) > -1) {
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, 0));
	}

	new random = GetRandomInt(1, 17);
	switch (random)
	{
		case 1: create_weapons(client, "give", "sniper_awp");
		case 2: create_weapons(client, "give", "sniper_scout");
		case 3: create_weapons(client, "give", "rifle_ak47");
		case 4: create_weapons(client, "give", "rifle_m60");
		case 5: create_weapons(client, "give", "shotgun_spas");
		case 6: create_weapons(client, "give", "grenade_launcher");
		case 7: create_weapons(client, "give", "sniper_military");
		case 8: create_weapons(client, "give", "smg");
		case 9: create_weapons(client, "give", "smg_silenced");
		case 10: create_weapons(client, "give", "pumpshotgun");
		case 11: create_weapons(client, "give", "shotgun_chrome");
		case 12: create_weapons(client, "give", "autoshotgun");
		case 13: create_weapons(client, "give", "hunting_rifle");
		case 14: create_weapons(client, "give", "rifle");
		case 15: create_weapons(client, "give", "rifle_desert");
		case 16: create_weapons(client, "give", "smg_mp5");
		case 17: create_weapons(client, "give", "rifle_sg552");
	}
}

public Action:attempt_give_weapons1(Handle:timer, any:client)
{
	if (client) {
		give_weapons(client);
	}
	return Plugin_Stop;
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client)) {
		CreateTimer(2.0, attempt_give_weapons1, client);
		return;
	}

	attempt[client] = 0;
	CreateTimer(2.0, attempt_give_weapons, client);
}
