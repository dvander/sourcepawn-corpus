#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zombie_outline>

public Plugin:myinfo =
{
	name = "Zombie Outline",
	author = "Vlladz",
	description = "CS:S Zombie Mod",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	ZO_CreateAllKeyMenus();
	ZO_PrepConfig();
	ZO_PrepConVars();
	ZO_HookGameEvents();
	ZO_CreatePostAdminCommands();
	ZO_CreatePlayerCommands();
}

public ZO_CreateAllKeyMenus()
{
	h_kGame = ZO_CreateGameKeyMenu();
	h_kLevels = ZO_CreateLevelsKeyMenu();
	h_kZombies = ZO_CreateZombiesKeyMenu();
	h_kDays = ZO_CreateDaysKeyMenu();
	h_kPlayers = ZO_CreatePlayersKeyMenu();
	h_kBots = ZO_CreateBotsKeyMenu();
	h_kDaysComp = ZO_CreateDaysCompKeyMenu();
}

public ZO_PrepConfig()
{
	ZO_ExpandAllVariables();
	ZO_RegisterMenu();
}

public ZO_PrepConVars()
{
	HookConVarChange(h_BotJoinAfterPlayer, OnMainConVarChange);
	HookConVarChange(h_BotDeferToHuman, OnMainConVarChange);
	HookConVarChange(h_BotChatter, OnMainConVarChange);
	HookConVarChange(h_HudHintSound, OnMainConVarChange);
}

public ZO_HookGameEvents()
{
	HookEvent("round_start", Event_RoundStartEx, EventHookMode_Post);
	HookEvent("round_freeze_end", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("item_pickup", Event_ItemPickup, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

public OnMapStart()
{
	ZO_PrecacheModels();
	ZO_PrecacheSounds();
	ZO_AddResourcesToDownloadsTable();

	ExtendMapTimeLimit(0);
	CreateTimer(30.0, RevealSelf);
}

public Action:RevealSelf(Handle:timer)
{
	new String:cmd[32];
	KvJumpToKey(h_kGame, "Settings");
	KvGetString(h_kGame, "zomenu", cmd, sizeof(cmd));
	KvRewind(h_kGame);

	PrintToChatAll("\x04[Zombie Outline] \x01This server is running \x04Zombie Outline\x01! Type \x04!%s \x01to open the menu!", cmd);
}

public OnMainConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarInt(h_BotJoinAfterPlayer, 0);
	SetConVarInt(h_BotDeferToHuman, 1);
	SetConVarString(h_BotChatter, "off");
	SetConVarInt(h_HudHintSound, 0);
}

public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client))
	{
		ZO_AddZombieBot(client);
		ZO_CreateClientWorkspace(client);
	}

	zhp[client] = 0;
	fLoc[client][0] = 0.0;
	fLoc[client][1] = 0.0;
	fLoc[client][2] = 0.0;
	fPos[client][0] = 0.0;
	fPos[client][1] = 0.0;
	fPos[client][2] = 0.0;
}

public Action:Event_RoundStartEx(Handle:event, const String:name[], bool:dontBroadcast)
{
	ZO_StartDay();
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ZO_InitiateDayTimers();
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && IsFakeClient(i))
			ZO_PrepareClient(i);
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winner = GetEventInt(event, "winner");
	ZO_EndDay(winner);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);

	if (!IsFakeClient(client) && team == 2)
	{
		ChangeClientTeam(client, 1);
		PrintToChat(client, "\x04[Zombie Outline] \x01This server is running \x04Zombie Outline\x01! You cannot join Terrorists!");
		return Plugin_Continue;
	}

	if (!IsFakeClient(client) && team == 3)
	{
		new String:auth[32];
		GetClientAuthString(client, auth, sizeof(auth));
		if (KvJumpToKey(h_kPlayers, auth))
		{
			KvRewind(h_kPlayers);
			ZO_PrepareClient(client);
			GetClientAbsOrigin(client, fPos[client]);
			return Plugin_Continue;
		}
		else
		{
			PrintToChat(client, "\x04[Zombie Outline] \x01You do not have a workspace! Create one if you want to play!");
			ChangeClientTeam(client, 1);
			return Plugin_Continue;
		}
	}

	if (IsFakeClient(client) && team == 2)
	{
		ZO_SetBotZombie(client);
		ZO_PrepareClient(client);
	}

	if (IsFakeClient(client) && team == 3)
		ZO_PrepareClient(client);

	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	new clientTeam = GetClientTeam(client);
	new attackerTeam = GetClientTeam(attacker);

	if (clientTeam == 2 && attackerTeam == 3)
	{
		new String:sCurrentZombie[32];
		Format(sCurrentZombie, sizeof(sCurrentZombie), ZO_GetBotZombie(client));

		new IsMotherZombie = ZO_IsMotherZombie(client);
		new zombieExp = ZO_GetZombieExp(client);

		zombieExp = zombieExp * expboost;

		new bool:headshot = GetEventBool(event, "headshot");
		new String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		
		if (headshot)
			zombieExp = zombieExp + exphead;

		if (StrContains(sWeapon, "hegrenade", false) != -1)
			zombieExp = zombieExp + exphe;

		if (StrContains(sWeapon, "knife", false) != -1)
			zombieExp = zombieExp + expknife;

		ZO_AddClientExp(attacker, zombieExp);

		if (IsMotherZombie == 1)
			ZO_MotherZombieKill(attacker, sCurrentZombie);
	}

	if (clientTeam == 2)
		ZO_ZombieDeath(client);
	if (clientTeam == 3)
	{
		decl String:model[256];
		GetClientModel(client, model, sizeof(model));
		if (StrEqual(model, "models/player/slow/hl2/combine_soldier/slow.mdl", false))
			ZO_CombineSoldierDied(client);
		else if (StrContains(model, "combine_soldier", false) != -1)
			ZO_CombineSoldierDied(client);

		ZO_RespawnClient(client, humanresptime);
	}

	KvRewind(h_kDays);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:sDay[4];
	IntToString(iDay, sDay, sizeof(sDay));

	KvJumpToKey(h_kDays, sDay);
	new String:sDayType[32];
	KvGetString(h_kDays, "daytype", sDayType, sizeof(sDayType));
	KvRewind(h_kDays);

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);
	new String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (team == 3 && StrContains(weapon, "knife", false) != -1)
	{
		new iEStats = ZO_GetStats(client, "estats");
		new iChance = iEStats * eperstat;

		new f = GetRandomInt(1, 100);
		if (f <= iChance)
		{
			new dmgHealth = GetEventInt(event, "dmg_health");
			new dmgArmor = GetEventInt(event, "dmg_armor");

			new pHealth = GetClientHealth(client);
			new pArmor = GetClientArmor(client);

			new health = pHealth + dmgHealth;
			new armor = pArmor + dmgArmor;

			SetEntProp(client, Prop_Send, "m_iHealth", health, 1);
			SetEntProp(client, Prop_Data, "m_iHealth", health, 1);
			SetEntProp(client, Prop_Send, "m_ArmorValue", armor, 1);
		}
		else
		{
			if (StrEqual(sDayType, "epidemic", false))
			{
				if (h_tEpidemic[client] != INVALID_HANDLE)
				{
					KillTimer(h_tEpidemic[client]);
					h_tEpidemic[client] = INVALID_HANDLE;
				}

				EpidemicDamage[client] = 8;
				h_tEpidemic[client] = CreateTimer(0.3, ZO_EpidemicDamage, client, TIMER_REPEAT);
			}
			else
			{
				decl String:model[256];
				GetClientModel(client, model, sizeof(model));
				if (StrEqual(model, "models/player/slow/hl2/combine_soldier/slow.mdl", false))
					ZO_CombineSoldierHurt(client);
				else if (StrContains(model, "combine_soldier", false) != -1)
					ZO_CombineSoldierHurt(client);
			}
		}
	}

	else if (team == 2)
	{
		new hitgroup = GetEventInt(event, "hitgroup");
		if (hitgroup == 1)
		{
			new String:sCurrentZombie[32];
			Format(sCurrentZombie, sizeof(sCurrentZombie), ZO_GetBotZombie(client));

			decl String:model2[256];
			decl String:health[64];
			KvJumpToKey(h_kZombies, sCurrentZombie);
			KvGetString(h_kZombies, "model2", model2, sizeof(model2));
			KvGetString(h_kZombies, "health", health, sizeof(health));
			KvRewind(h_kZombies);

			new zhealth = StringToInt(health);
			new phealth = GetClientHealth(client);

			new Float:x = float(phealth) / float(zhealth);
			x = x * 100;

			if (x <= 40.00)
			{
				new f = GetRandomInt(1, 100);
				if (f <= 67)
				{
					if (!StrEqual(model2, "0", false))
					{
						decl String:model[256];
						GetClientModel(client, model, sizeof(model));

						if (!StrEqual(model, model2, false))
							SetEntityModel(client, model2);
					}
				}
			}
		}

		new clientf = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (zhp[clientf] == 1)
		{
			new iZHP = GetClientHealth(client);
			if (iZHP > 0)
			{
				new String:sCurrentZombie[32];
				Format(sCurrentZombie, sizeof(sCurrentZombie), ZO_GetBotZombie(client));
				PrintCenterText(clientf, "%s: %dhp", sCurrentZombie, iZHP);
			}
		}
	}
}

public Action:ZO_EpidemicDamage(Handle:timer, any:client)
{
	if (IsPlayerAlive(client))
	{
		new health = GetClientHealth(client);
		health = health - 3;
		SetEntProp(client, Prop_Send, "m_iHealth", health, 1);
		SetEntProp(client, Prop_Data, "m_iHealth", health, 1);

		EpidemicDamage[client]--;
		if (EpidemicDamage[client] == 0)
		{
			KillTimer(h_tEpidemic[client]);
			h_tEpidemic[client] = INVALID_HANDLE;
		}

		decl String:model[256];
		GetClientModel(client, model, sizeof(model));
		if (StrEqual(model, "models/player/slow/hl2/combine_soldier/slow.mdl", false))
			ZO_CombineSoldierHurt(client);
		else if (StrContains(model, "combine_soldier", false) != -1)
			ZO_CombineSoldierHurt(client);
	}
	else
	{
		KillTimer(h_tEpidemic[client]);
		h_tEpidemic[client] = INVALID_HANDLE;
	}
}

public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetClientTeam(client);

	if (team == 2)
		ZO_RemoveZombieItems(client);
}