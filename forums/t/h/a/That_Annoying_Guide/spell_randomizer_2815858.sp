#pragma semicolon 1;

#include <sourcemod>
#include <tf2_stocks>
//#include <tf2items>

new Handle:g_time = INVALID_HANDLE;
new Handle:g_block = INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "Spell Randomizer",
	author = "svaugrasn edited by TAG",
	description = "",
	version = "1.2.0",
	url = "none"
};

public OnPluginStart()
{
	g_time = CreateConVar("sm_spell_time", "20.0", "");
	g_block = CreateConVar("sm_spell_no_skeletons", "0", "");

	CreateTimer(10.0, Spells, 0);
}

public Action:Spells(Handle:timer, any:hoge)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEdict(i) && IsClientConnected(i) && IsPlayerAlive(i))
		{
			new rint = GetRandomUInt(0,10);

			if(!(GetConVarInt(g_block))){
				rint = GetRandomUInt(0,11);
			}

			new ent = -1;

			// http://forums.alliedmods.net/showthread.php?p=2054523
			while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
			{
				if(ent)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == i)
					{
						SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", rint);
						if (rint == 0 || rint == 1 || rint == 4 || rint == 6)
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", 2);
						else
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", 1);

						SetHudTextParams(-1.0, 0.65, 6.0, 0, 255, 0, 255);

						if (rint == 0)
							ShowHudText(i, -1, "Picked up the spell: Fire Ball");
						else if (rint == 1)
							ShowHudText(i, -1, "Picked up the spell: Bats");
						else if (rint == 2)
							ShowHudText(i, -1, "Picked up the spell: Heal Allies");
						else if (rint == 3)
							ShowHudText(i, -1, "Picked up the spell: Explosive Pumpkins");
						else if (rint == 4)
							ShowHudText(i, -1, "Picked up the spell: Super Jump");
						else if (rint == 5)
							ShowHudText(i, -1, "Picked up the spell: Invisibility");
						else if (rint == 6)
							ShowHudText(i, -1, "Picked up the spell: Teleport");
						else if (rint == 7)
							ShowHudText(i, -1, "Picked up the spell: Magnetic Bolt");
						else if (rint == 8)
							ShowHudText(i, -1, "Picked up the spell: Shrink");
						else if (rint == 9)
							ShowHudText(i, -1, "Picked up the spell: Fire Storm");
						else if (rint == 10)
							ShowHudText(i, -1, "Picked up the spell: Summon MONOCULUS!");
						else if (rint == 11)
							ShowHudText(i, -1, "Picked up the spell: Summon Skeletons");
					}
				}
			}
		}
	}
	CreateTimer(GetConVarFloat(g_time), Spells, 0);		// Loop
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}