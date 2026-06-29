/*
 * woodencrates.sp
 * Copyright (c) 2022 Ed <ed@groovyexpress.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sourcemod>
#include <sdktools>

#define ITEMSLIMIT 4
#define WEAPONSLIMIT 2

bool isL4D2;

public Plugin myinfo =
{
	name = "[L4D1/L4D2] Wooden Crates",
	author = "EDSHOT",
	description = "What could be inside...",
	version = "0.1"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_Left4Dead && GetEngineVersion() != Engine_Left4Dead2)
	{
		SetFailState("This plugin is only supported by the Left 4 Dead series.");
	}

	if (GetEngineVersion() == Engine_Left4Dead2) isL4D2 = true;
	else isL4D2 = false;

	HookEntityOutput("prop_physics", "OnBreak", dropItems);
}

public void OnPluginEnd()
{
	UnhookEntityOutput("prop_physics", "OnBreak", dropItems);
}

public void OnMapStart()
{
	HookEntityOutput("prop_physics", "OnBreak", dropItems);
}

public void OnMapEnd()
{
	UnhookEntityOutput("prop_physics", "OnBreak", dropItems);
}

public void dropItems(const char[] output, int caller, int activator, float delay)
{
	char modelName[32];
	GetEntPropString(caller, Prop_Data, "m_ModelName", modelName, sizeof(modelName));

	if (!IsValidEntity(caller)) return;

	if (StrEqual(modelName, "models/props_junk/wood_crate001", false) || StrEqual(modelName, "models/props_junk/wood_crate001_damagedmax", false))
	{
		char item[ITEMSLIMIT+1][32];
		int item_entity;
		float box_pos[3];

		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", box_pos);

		if (isL4D2)
		{
			for (int tmp = 1; tmp <= ITEMSLIMIT; tmp++)
			{
				switch (GetRandomInt(0, 10))
				{
					case 0: item[tmp] = "weapon_adrenaline";
					case 1: item[tmp] = "weapon_defibrillator";
					case 2: item[tmp] = "weapon_first_aid_kit";
					case 3: item[tmp] = "weapon_molotov";
					case 4: item[tmp] = "weapon_pain_pills";
					case 5: item[tmp] = "weapon_pipe_bomb";
					case 6: item[tmp] = "weapon_pistol";
					case 7: item[tmp] = "weapon_pistol_magnum";
					case 8: item[tmp] = "weapon_upgradepack_explosive";
					case 9: item[tmp] = "weapon_upgradepack_incendiary";
					case 10: item[tmp] = "weapon_vomitjar";
				}
			}
		}
		else
		{
			for (int tmp = 1; tmp <= ITEMSLIMIT; tmp++)
			{
				switch (GetRandomInt(0, 4))
				{
					case 0: item[tmp] = "weapon_first_aid_kit";
					case 1: item[tmp] = "weapon_molotov";
					case 2: item[tmp] = "weapon_pain_pills";
					case 3: item[tmp] = "weapon_pipe_bomb";
					case 4: item[tmp] = "weapon_pistol";
				}
			}
		}

		for (int tmp = 1; tmp <= ITEMSLIMIT; tmp++)
		{
			item_entity = CreateEntityByName(item[tmp]);
			if (IsValidEntity(item_entity))
			{
				DispatchSpawn(item_entity);
				TeleportEntity(item_entity, box_pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}

	if (StrEqual(modelName, "models/props_junk/wood_crate002", false))
	{
		char weapon[WEAPONSLIMIT+1][32];
		int weapon_entity;
		float box_pos[3];

		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", box_pos);

		if (isL4D2)
		{
			for (int tmp = 1; tmp <= WEAPONSLIMIT; tmp++)
			{
				switch (GetRandomInt(0, 30))
				{
					case 0: weapon[tmp] = "weapon_autoshotgun";
					case 1: weapon[tmp] = "weapon_chainsaw";
					case 2: weapon[tmp] = "weapon_grenade_launcher";
					case 3: weapon[tmp] = "weapon_hunting_rifle";
					case 4: weapon[tmp] = "weapon_pumpshotgun";
					case 5: weapon[tmp] = "weapon_rifle";
					case 6: weapon[tmp] = "weapon_rifle_ak47";
					case 7: weapon[tmp] = "weapon_rifle_desert";
					case 8: weapon[tmp] = "weapon_rifle_m60";
					case 9: weapon[tmp] = "weapon_rifle_sg552";
					case 10: weapon[tmp] = "weapon_shotgun_chrome";
					case 11: weapon[tmp] = "weapon_shotgun_spas";
					case 12: weapon[tmp] = "weapon_smg";
					case 13: weapon[tmp] = "weapon_smg_mp5";
					case 14: weapon[tmp] = "weapon_smg_silenced";
					case 15: weapon[tmp] = "weapon_sniper_awp";
					case 16: weapon[tmp] = "weapon_sniper_military";
					case 17: weapon[tmp] = "weapon_sniper_scout";
				}
			}
		}
		else
		{
			for (int tmp = 1; tmp <= WEAPONSLIMIT; tmp++)
			{
				switch (GetRandomInt(0, 4))
				{
					case 0: weapon[tmp] = "weapon_autoshotgun";
					case 1: weapon[tmp] = "weapon_hunting_rifle";
					case 2: weapon[tmp] = "weapon_pumpshotgun";
					case 3: weapon[tmp] = "weapon_rifle";
					case 4: weapon[tmp] = "weapon_smg";
				}
			}
		}

		for (int tmp = 1; tmp <= WEAPONSLIMIT; tmp++)
		{
			weapon_entity = CreateEntityByName(weapon[tmp]);
			if (IsValidEntity(weapon_entity))
			{
				DispatchSpawn(weapon_entity);
				TeleportEntity(weapon_entity, box_pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}
