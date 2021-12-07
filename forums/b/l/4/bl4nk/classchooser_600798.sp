#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "1.0.2"

#define cDefault    0x01
#define cLightGreen 0x03
#define cGreen      0x04
#define cDarkGreen  0x05

new bool:isHooked = false;

new Handle:cvarEnable;
new Handle:cvarClass;
new Handle:cvarEngy;
new Handle:cvarMelee;

public Plugin:myinfo =
{
	name = "ClassChooser",
	author = "bl4nk",
	description = "Choose a class to spawn everyone as",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_classchooser_version", PLUGIN_VERSION, "ClassChooser Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarEnable = CreateConVar("sm_classchooser_enable", "0", "Enables/Disables the ClassChooser plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarClass = CreateConVar("sm_classchooser_class", "scout", "Class for people to spawn as", FCVAR_PLUGIN);
	cvarEngy = CreateConVar("sm_classchooser_engineer_tools", "0", "Enables/Disables building tools as the engineer class", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarMelee = CreateConVar("sm_classchooser_melee", "1", "Enables/Disables melee only mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
	if (GetConVarInt(cvarEnable))
	{
		isHooked = true;
		HookEvent("player_spawn", event_PlayerSpawn);
		HookEvent("teamplay_round_active", event_RoundStart);
		HookEvent("teamplay_round_win", event_RoundEnd);

		LogMessage("[ClassChooser] - Loaded");
	}

	HookConVarChange(cvarEnable, CvarChange);
	HookConVarChange(cvarMelee, CvarChange);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarEnable)
	{
		if (!GetConVarInt(cvarEnable))
		{
			if (isHooked)
			{
				isHooked = false;
				UnhookEvent("player_spawn", event_PlayerSpawn);
				UnhookEvent("teamplay_round_active", event_RoundStart);
				UnhookEvent("teamplay_round_win", event_RoundEnd);

				ChangeResupplyState(1);

				if (GetConVarInt(cvarMelee))
					PrintToChatAll("%c[SM] %cMelee only mode %cdisabled%c!", cGreen, cDefault, cLightGreen, cDefault);
			}
		}
		else if (!isHooked)
		{
			isHooked = true;
			HookEvent("player_spawn", event_PlayerSpawn);
			HookEvent("teamplay_round_active", event_RoundStart);
			HookEvent("teamplay_round_win", event_RoundEnd);

			if (GetConVarInt(cvarMelee))
			{
				MeleeStrip();
				ChangeResupplyState(0);
				PrintToChatAll("%c[SM] %cMelee only mode %cenabled%c!", cGreen, cDefault, cLightGreen, cDefault);
			}
		}
	}
	else if (convar == cvarMelee)
	{
		if (GetConVarInt(cvarEnable))
		{
			if (GetConVarInt(cvarMelee))
			{
				MeleeStrip();
				ChangeResupplyState(0);
				PrintToChatAll("%c[SM] %cMelee only mode %cenabled%c!", cGreen, cDefault, cLightGreen, cDefault);
			}
			else
			{
				ChangeResupplyState(1);
				PrintToChatAll("%c[SM] %cMelee only mode %cdisabled%c!", cGreen, cDefault, cLightGreen, cDefault);
			}
		}
	}
}

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	decl String:cvarString[32];
	GetConVarString(cvarClass, cvarString, sizeof(cvarString));

	new TFClassType:class = TF2_GetClass(cvarString);

	switch (class)
	{
		case TFClass_Unknown:
		{
			if (strcmp(cvarString, "random") == 0)
			{
				new TFClassType:random = TFClassType:GetRandomInt(1, 9);
				TF2_SetPlayerClass(client, random, false);

				if (random == TFClass_Engineer && !GetConVarInt(cvarEngy) && !GetConVarInt(cvarMelee))
					CreateTimer(0.1, timer_EngyRemove, client);
			}
		}
		case TFClass_Engineer:
		{
			TF2_SetPlayerClass(client, class, false);

			if (!GetConVarInt(cvarEngy) && !GetConVarInt(cvarMelee))
				CreateTimer(0.1, timer_EngyRemove, client);
		}
		default:
			TF2_SetPlayerClass(client, class, false);
	}

	if (GetConVarInt(cvarMelee))
		CreateTimer(0.1, timer_Melee, client);
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	if (GetConVarInt(cvarMelee))
		ChangeResupplyState(0);

public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
	ChangeResupplyState(1);

public Action:timer_EngyRemove(Handle:timer, any:client)
{
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 4);
}

public Action:timer_Melee(Handle:timer, any:client)
	RemoveWeaponsToMelee(client);

stock RemoveWeaponsToMelee(client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		for (new i = 0; i <= 5; i++)
		{
			if (i == 2)
				continue;

			TF2_RemoveWeaponSlot(client, i);
		}
	}
}

stock MeleeStrip()
{
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
			RemoveWeaponsToMelee(i);
}

stock ChangeResupplyState(mode)
{
	new maxents = GetMaxEntities();
	new maxplayers = GetMaxClients();
	for (new i = maxplayers + 1; i <= maxents; i++)
	{
		if (!IsValidEntity(i))
			return;

		decl String:classname[32];
		GetEdictClassname(i, classname, sizeof(classname));

		if (strcmp(classname, "func_regenerate") == 0)
		{
			switch (mode)
			{
				case 0:
				{
					AcceptEntityInput(i, "Disable");
					continue;
				}
				case 1:
				{
					AcceptEntityInput(i, "Enable");
					continue;
				}
				case 2:
				{
					AcceptEntityInput(i, "Toggle");
					continue;
				}
			}

			LogError("Invalid state used for ChangeResupplyState()");
			break;
		}
	}
}