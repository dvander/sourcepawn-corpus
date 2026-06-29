// SPDX-License-Identifier: GPL-3.0-only
/**
 * =============================================================================
 * Copyright https://steamcommunity.com/id/dr_lex/
 *
 * =============================================================================
 *
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

#define PROP0 0
#define PROP1 1
#define PROP2 2
#define PROP3 3
#define PROP4 4

char sg_slot0[MAXPLAYERS+1][64];
int ig_prop[10][MAXPLAYERS+1];

char sg_slot0m[MAXPLAYERS+1][64];
int ig_prop_m[10][MAXPLAYERS+1];

int ig_entity[MAXPLAYERS+1];
int ig_time[MAXPLAYERS+1];
int BackpackOwner[4096];

bool ig_third_person[MAXPLAYERS+1];

#define DEBUG 0
#if DEBUG
native int HxAmmoGrenadeLauncher(int client, int iAmmo);
#define OFFSET 6260
#endif

native bool L4D_IsFirstMapInScenario();

public Plugin myinfo =
{
	name = "[L4D2] Backpack (!bk)",
	author = "dr lex",
	description = "",
	version = "1.6.3",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_bk", CMD_backpack, "", 0);
	LoadTranslations("bk.phrases");
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("map_transition", Event_MapTransition);

	CreateTimer(3.0, HxTimerInfinite, _, TIMER_REPEAT);
}

/**
 * Удаляем энтити рюкзака
 * @param client     Номер игрока от 0 до 32
 * @return           void
 */
stock void Hx_kill_ent_visual_backpack(int &client)
{
	int iEnt = ig_entity[client];
	if (iEnt > 0)
	{
		if (IsValidEntity(iEnt))
		{
			AcceptEntityInput(iEnt, "Kill");
		}
	}
	ig_entity[client] = 0;
}

/**
 * Очистка сохраненного в течении карты рюкзака
 * 
 * @param client     Номер игрока от 0 до 32
 * @return           void
 */
stock void HxCleaning(int &client)
{
	sg_slot0[client][0] = '\0';
	ig_prop[PROP0][client] = 0;
	ig_prop[PROP1][client] = 0;
	ig_prop[PROP2][client] = 0;
	ig_prop[PROP3][client] = 0;
	ig_prop[PROP4][client] = 0;

	Hx_kill_ent_visual_backpack(client);
}

/**
 * Очистка сохраненного в конце карты рюкзака
 * 
 * @param client     Номер игрока от 0 до 32
 * @return           void
 */
stock void HxCleaningMaps(int &client)
{
	sg_slot0m[client][0] = '\0';
	ig_prop_m[PROP0][client] = 0;
	ig_prop_m[PROP1][client] = 0;
	ig_prop_m[PROP2][client] = 0;
	ig_prop_m[PROP3][client] = 0;
	ig_prop_m[PROP4][client] = 0;

	Hx_kill_ent_visual_backpack(client);
}

/**
 * Копирование слота рюкзака сохраненного на прошлой карте в временный слот текущего рюкзака
 * 
 * @param client     Номер игрока от 0 до 32
 * @return           void
 */
stock void Hx_copy_temp_slot0(int &client)
{
	if (sg_slot0m[client][0])
	{
		Format(sg_slot0[client], 39, "%s", sg_slot0m[client]);
		ig_prop[PROP0][client] = ig_prop_m[PROP0][client];
		ig_prop[PROP1][client] = ig_prop_m[PROP1][client];
		ig_prop[PROP2][client] = ig_prop_m[PROP2][client];
		ig_prop[PROP3][client] = ig_prop_m[PROP3][client];
		ig_prop[PROP4][client] = ig_prop_m[PROP4][client];

		Hx_add_visual_backpack(client);
	}
}

/**
 * Спавним содержимое рюкзака рядом с игроком
 * 
 * @param client     Номер игрока от 0 до 32
 * @return           1 взял из слота. 0 ничего нет в слоте
 */
stock int HxSpawnSlot0(int client)
{
	float fxyz[3];
	if (sg_slot0[client][0])
	{
		int iEnt = CreateEntityByName(sg_slot0[client]);
		if (iEnt > 0)
		{
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fxyz);
			fxyz[2] += 50;
			
			DispatchSpawn(iEnt);
			
			SetEntProp(iEnt, Prop_Send, "m_iClip1", ig_prop[PROP0][client]);
			SetEntProp(iEnt, Prop_Send, "m_upgradeBitVec", ig_prop[PROP1][client]); /*	лазер, осколочные, зажигательные	*/
			SetEntProp(iEnt, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_prop[PROP2][client]);
			SetEntProp(iEnt, Prop_Send, "m_iExtraPrimaryAmmo", ig_prop[PROP3][client]);
			SetEntProp(iEnt, Prop_Send, "m_nSkin", ig_prop[PROP4][client]);

			TeleportEntity(iEnt, fxyz, NULL_VECTOR, NULL_VECTOR);			
			HxCleaning(client);
			return 1;
		}
	}
	return 0;
}

stock void SetPlayerReserveAmmo(int client, int weapon, int ammo)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype >= 0)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
		ChangeEdictState(client, FindDataMapInfo(client, "m_iAmmo"));
	}
}

/**
 * Игрок берет сохраненный предмет из рюкзака
 * 
 * @param client     Номер игрока от 0 до 32
 * @return           1 взял из слота. 0 ничего нет в слоте
 */
stock int HxGiveSlot0(int client)
{
	if (sg_slot0[client][0])
	{
		int weapon = GivePlayerItem(client, sg_slot0[client]);
		if (weapon != -1)
		{
			SetEntProp(weapon, Prop_Send, "m_iClip1", ig_prop[PROP0][client]);
			SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", ig_prop[PROP1][client]);
			SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ig_prop[PROP2][client]);
			SetPlayerReserveAmmo(client, weapon, ig_prop[PROP3][client]);
			SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", ig_prop[PROP3][client]);
			SetEntProp(weapon, Prop_Send, "m_nSkin", ig_prop[PROP4][client]);
			
		#if DEBUG
			if (StrEqual(sg_slot0[client], "weapon_grenade_launcher"))
			{
				HxAmmoGrenadeLauncher(client, ig_prop[PROP0][client]);
				SetEntData(client, OFFSET + 68, 0);
			}
		#endif
		}

		HxCleaning(client);
		return 1;
	}
	return 0;
}

/**
 * Перекладываем оружие 0 слота в рюкзак
 * 
 * @param client     Номер игрока от 0 до 32
 * @return           void
 */
stock void HxSaveSlot0(int client, int iSlot0)
{
	if (iSlot0 > 0)
	{
		GetEdictClassname(iSlot0, sg_slot0[client], 39);
		ig_prop[PROP0][client] = GetEntProp(iSlot0, Prop_Send, "m_iClip1");
		ig_prop[PROP1][client] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec");
		ig_prop[PROP2][client] = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
		ig_prop[PROP3][client] = GetPlayerReserveAmmo(client, iSlot0);
		ig_prop[PROP4][client] = GetEntProp(iSlot0, Prop_Send, "m_nSkin");

		RemovePlayerItem(client, iSlot0);
		AcceptEntityInput(iSlot0, "Kill");

		Hx_add_visual_backpack(client);
	}
}

stock int GetPlayerReserveAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype >= 0)
	{
		return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
	}
	return 0;
}

stock int HxValidClient(int &client)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) == 2)
			{
				if (IsPlayerAlive(client))
				{
					return 1;
				}
			}
		}
	}
	return 0;
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}
	return false;
}

stock Action TimerClientPost(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) != 3)
		{
			Hx_copy_temp_slot0(client);
		}
	}
	return Plugin_Stop;
}

stock Action TimerClientInfo(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			PrintToChat(client, "\x04[\x03!bk\x04] \x05%t", "You can put additional weapons in your backpack");
		}
	}
	return Plugin_Stop;
}

public void OnClientPutInServer(int client)
{		/* При заходе игрока чистим рюкзак */
	HxCleaning(client);
	if (!IsFakeClient(client))
	{
		CreateTimer(1.0, TimerClientPost, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(15.0, TimerClientInfo, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnMapStart()
{
	char mode[32];
	ConVar g_Mode = FindConVar("mp_gamemode");
	GetConVarString(g_Mode, mode, sizeof(mode));
	if (strcmp(mode, "coop") == 0)
	{
		if (L4D_IsFirstMapInScenario())
		{
			int i = 1;
			while (i <= MaxClients)
			{
				HxCleaning(i);
				HxCleaningMaps(i);
				i += 1;
			}
		}
	}
	else
	{
		int i = 1;
		while (i <= MaxClients)
		{
			HxCleaning(i);
			HxCleaningMaps(i);
			i += 1;
		}
	}

	PrecacheModel("models/props_collectables/backpack.mdl", true);
}

stock Action HxTimerRS(Handle timer)
{
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) != 3)
			{
				Hx_copy_temp_slot0(i);
			}
		}
		i += 1;
	}
	return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int i = 1;
	while (i <= MaxClients)
	{		/* В начале раунда чистим всем рюкзак */
		HxCleaning(i);
		i += 1;
	}
	CreateTimer(1.2, HxTimerRS, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) == 2)
			{
				HxSpawnSlot0(client);
			}
		}
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client)
	{
		if (!IsFakeClient(client))
		{
			int iTeam = event.GetInt("team");
			switch (iTeam)
			{
				case 1:
				{
					if (event.GetInt("oldteam") == 2)
					{	/*	Игрок уходит в афк	*/
						Hx_kill_ent_visual_backpack(client);
					}
				}
				case 2: CreateTimer(1.0, HxTimerTeam2, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

stock Action HxTimerTeam2(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if (IsPlayerAlive(client))
			{
				Hx_add_visual_backpack(client);
			}
			else
			{
				CreateTimer(1.0, HxTimerTeam2, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Stop;
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{ /* делаем копию  */
	int i = 1;
	while (i <= MaxClients)
	{
		HxCleaningMaps(i);
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				if (sg_slot0[i][0])
				{
					Format(sg_slot0m[i], 39, "%s", sg_slot0[i]);
					ig_prop_m[PROP0][i] = ig_prop[PROP0][i];
					ig_prop_m[PROP1][i] = ig_prop[PROP1][i];
					ig_prop_m[PROP2][i] = ig_prop[PROP2][i];
					ig_prop_m[PROP3][i] = ig_prop[PROP3][i];
					ig_prop_m[PROP4][i] = ig_prop[PROP4][i];
				}
			}
		}

		HxCleaning(i);
		i += 1;
	}
}

public Action CMD_backpack(int client, int args)
{
	if (client)
	{
		if (HxValidClient(client))
		{
			if (!IsPlayerIncapped(client))
			{
				if (ig_time[client] < GetTime())
				{
					ig_time[client] = GetTime() + 3;
					int iSlot0 = GetPlayerWeaponSlot(client, 0);
					if (iSlot0 > 0)		/* У игрока есть оружие в 0 слоте */
					{
						if (HxSpawnSlot0(client))
						{
							PrintToChat(client, "\x04[\x03!bk\x04] \x05%t.", "An item taken from backpack");
						}
						else
						{
							HxSaveSlot0(client, iSlot0);
							PrintToChat(client, "\x04[\x03!bk\x04] \x05%t.", "An item was put in backpack");
						}
					}
					else	/* У игрока нет оружия в 0 слоте */
					{
						if (HxGiveSlot0(client))
						{
							PrintToChat(client, "\x04[\x03!bk\x04] \x05%t.", "An item taken from backpack");
						}
						else
						{
							PrintToChat(client, "\x04[\x03!bk\x04] \x05%t.", "No weapons");
							PrintToChat(client, "\x04[\x03!bk\x04] \x05%t.", "The backpack is empty");
						}
					}
				}
				else
				{
					PrintToChat(client, "\x04[\x03!bk\x04] \x05%t.", "Too often");
				}
			}
		}
	}
	return Plugin_Handled;
}

stock void Hx_add_visual_backpack(int &client)
{
	Hx_kill_ent_visual_backpack(client);

	if (sg_slot0[client][0])
	{
		int entity = CreateEntityByName("prop_dynamic_ornament");
		if (entity > 0)
		{
			DispatchKeyValue(entity, "model", "models/props_collectables/backpack.mdl");	// текстура

			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);	// c*a+dest*(1-a)
			SetEntityRenderColor(entity, 0, 0, 0, 255);

			DispatchSpawn(entity); // спавнит энтити
			ActivateEntity(entity); // Activates an entity (CBaseAnimating::Activate)

			AcceptEntityInput(entity, "TurnOn");	// показывает предмет
			SetEntPropFloat(entity, Prop_Send,"m_flModelScale", 0.67);	// размер модели 0.67

			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client); // прикреплен к данному игроку

			SetVariantString("medkit");
			AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset"); // сохраняет свою позицию без телепортирования

			float Pos[3];
			Pos[0] = 4.0;
			Pos[1] = 2.0;
			Pos[2] = 3.3;

			float Ang[3];
			Ang[0] = 175.0;
			Ang[1] = 85.0;
			Ang[2] = -75.0;

			TeleportEntity(entity, Pos, Ang, NULL_VECTOR); // расположение на обьекте
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", 0);	// 
			BackpackOwner[entity] = GetClientUserId(client);

			SDKHook(entity, SDKHook_SetTransmit, SetTransmit);
			ig_entity[client] = entity;
		}
	}
}

stock Action SetTransmit(int entity, int client)
{
	if (IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	if (!IsPlayerAlive(client))
	{
		if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
		{
			if(GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") == GetClientOfUserId(BackpackOwner[entity]))
			{
				return Plugin_Handled;
			}
		}
	}

	int iEntOwner = GetClientOfUserId(BackpackOwner[entity]);
	if (iEntOwner < 1 || !IsClientInGame(iEntOwner))
	{
		return Plugin_Continue;
	}

	if (GetClientTeam(iEntOwner) == 2)
	{
		if (iEntOwner != client)
		{
			return Plugin_Continue;
		}
		if (!ig_third_person[client])
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

static bool IsSurvivorThirdPerson(int iClient)
{
	if (GetEntPropEnt(iClient, Prop_Send, "m_hViewEntity") > 0)
	{
		return true;
	}
	if (GetEntPropFloat(iClient, Prop_Send, "m_TimeForceExternalView") > GetGameTime())
	{
		return true;
	}
	if (GetEntProp(iClient, Prop_Send, "m_iObserverMode") == 1)
	{
		return true;
	}
	if (GetEntPropEnt(iClient, Prop_Send, "m_pummelAttacker") > 0)
	{
		return true;
	}
	if (GetEntPropEnt(iClient, Prop_Send, "m_carryAttacker") > 0)
	{
		return true;
	}
	if (GetEntPropEnt(iClient, Prop_Send, "m_pounceAttacker") > 0)
	{
		return true;
	}
	if (GetEntPropEnt(iClient, Prop_Send, "m_jockeyAttacker") > 0)
	{
		return true;
	}
	if (GetEntProp(iClient, Prop_Send, "m_isHangingFromLedge") > 0)
	{
		return true;
	}
	if (GetEntPropEnt(iClient, Prop_Send, "m_reviveTarget") > 0)
	{
		return true;
	}
	if (GetEntPropFloat(iClient, Prop_Send, "m_staggerTimer", 1) > -1.0)
	{
		return true;
	}

	switch(GetEntProp(iClient, Prop_Send, "m_iCurrentUseAction"))
	{
		case 1:
		{
			static int iTarget;
			iTarget = GetEntPropEnt(iClient, Prop_Send, "m_useActionTarget");
			if (iTarget == GetEntPropEnt(iClient, Prop_Send, "m_useActionOwner"))
			{
				return true;
			}
			else if (iTarget != iClient)
			{
				return true;
			}
		}
		case 4, 6, 7, 8, 9, 10:
		{
			return true;
		}
	}

	static char sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	switch(sModel[29])
	{
		case 'b'://nick
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 626, 625, 624, 623, 622, 621, 661, 662, 664, 665, 666, 667, 668, 670, 671, 672, 673, 674, 620, 680, 616:
				{
					return true;
				}
			}
		}
		case 'd'://rochelle
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 674, 678, 679, 630, 631, 632, 633, 634, 668, 677, 681, 680, 676, 675, 673, 672, 671, 670, 687, 629, 625, 616:
				{
					return true;
				}
			}
		}
		case 'c'://coach
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 656, 622, 623, 624, 625, 626, 663, 662, 661, 660, 659, 658, 657, 654, 653, 652, 651, 621, 620, 669, 615:
				{
					return true;
				}
			}
		}
		case 'h'://ellis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 625, 675, 626, 627, 628, 629, 630, 631, 678, 677, 676, 575, 674, 673, 672, 671, 670, 669, 668, 667, 666, 665, 684, 621:
				{
					return true;
				}
			}
		}
		case 'v'://bill
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 528, 759, 763, 764, 529, 530, 531, 532, 533, 534, 753, 676, 675, 761, 758, 757, 756, 755, 754, 527, 772, 762, 522:
				{
					return true;
				}
			}
		}
		case 'n'://zoey
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 537, 819, 823, 824, 538, 539, 540, 541, 542, 543, 813, 828, 825, 822, 821, 820, 818, 817, 816, 815, 814, 536, 809, 572:
				{
					return true;
				}
			}
		}
		case 'e'://francis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 532, 533, 534, 535, 536, 537, 769, 768, 767, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 531, 530, 775, 525:
				{
					return true;
				}
			}
		}
		case 'a'://louis
		{
			switch(GetEntProp(iClient, Prop_Send, "m_nSequence"))
			{
				case 529, 530, 531, 532, 533, 534, 766, 765, 764, 763, 762, 761, 760, 759, 758, 757, 756, 755, 754, 753, 527, 772, 528, 522:
				{
					return true;
				}
			}
		}
	}
	return false;
}

stock Action HxTimerInfinite(Handle timer)
{
	int i = 1;
	while (i <= MaxClients)
	{
		ig_third_person[i] = false;
		if (IsClientInGame(i))
		{
			ig_third_person[i] = IsSurvivorThirdPerson(i);
		}
		i += 1;
	}
	return Plugin_Continue;
}