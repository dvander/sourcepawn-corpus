#pragma semicolon 1;

#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>

new Handle:g_time = INVALID_HANDLE;
new Handle:g_amount = INVALID_HANDLE;
new Handle:g_amount_strong = INVALID_HANDLE;

			// http://forums.alliedmods.net/showthread.php?p=2054523
public Plugin:myinfo =
{
	name = "Spell Randomizer",
	author = "svaugrasn",
	description = "",
	version = "1.2.0",
	url = "none"
};

public OnPluginStart()
{
	g_time = CreateConVar("sm_spell_time", "20.0", "");
	g_amount = CreateConVar("sm_spell_amounts", "10", "");
	g_amount_strong = CreateConVar("sm_spell_amounts_strong", "3", "");
	CreateTimer(10.0, Spells, 0);
}

public OnMapStart(){
}

public Action:Spells(Handle:timer, any:hoge)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEdict(i) && IsClientConnected(i) && IsPlayerAlive(i))
		{
			new rint = GetRandomInt(0,11);
			
			if (rint == 3) // If pumpkins are rolled, turn it into skeles. Pumpkins are called edict crash on server
			{
				rint = 11;
			}
			if (rint == 7) // If Magnet is rolled, change to monoc. It's fucking up the bots in spawn screen
			{
				rint = 9;
			}
			if (rint == 6) // Teleport is being used as exploit. Remove it. 
			{
				rint = 10;
			}
			
			new ent = -1;
			while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
			{
				if(ent)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == i)
					{
						SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", rint);
						if ((rint == 11) || (rint == 10) || (rint == 9) || (rint == 8) || (rint == 7))
						{
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount_strong));
						}
						else
						{
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
						}
						SetHudTextParams(-1.0, 0.65, 6.0, 0, 255, 0, 255);

						if (rint == 0) //Yes
							ShowHudText(i, -1, "Fireball x10");
						else if (rint == 1) //Yes
							ShowHudText(i, -1, "Bats x10");
						else if (rint == 2)
							ShowHudText(i, -1, "Heal x10");
						else if (rint == 3)
							ShowHudText(i, -1, "Pumpkin x10");
						else if (rint == 4)
							ShowHudText(i, -1, "Jump x10");
						else if (rint == 5)
							ShowHudText(i, -1, "Cloak x10");
						else if (rint == 6)
							ShowHudText(i, -1, "Teleport x10");
						else if (rint == 7) //Yes
							ShowHudText(i, -1, "Magnet x3");
						else if (rint == 8) //Yes
							ShowHudText(i, -1, "Tiny x3");
						else if (rint == 9) //Yes
							ShowHudText(i, -1, "Eyeball x3");
						else if (rint == 10) //Yes
							ShowHudText(i, -1, "Storm x3");
						else if (rint == 11)
							ShowHudText(i, -1, "Skeletons x3");
					}
				}
			}
		}
	}
	CreateTimer(GetConVarFloat(g_time), Spells, 0);		// Loop
}