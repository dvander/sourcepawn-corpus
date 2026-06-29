#pragma semicolon 1;

#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>

new Handle:g_time = INVALID_HANDLE;
new Handle:g_amount = INVALID_HANDLE;
new Handle:g_medieval = INVALID_HANDLE;
new Handle:g_block = INVALID_HANDLE;


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
	g_amount = CreateConVar("sm_spell_amounts", "5", "");
	g_medieval = CreateConVar("sm_spell_medieval", "1", "");
	g_block = CreateConVar("sm_spell_block", "1", "");


	CreateTimer(10.0, Spells, 0);

	if(GetConVarInt(g_medieval)){
		HookEvent ("player_spawn", Event_playerspawn);
		HookEvent("teamplay_round_start", Event_teamplay_round_start);
	}

}

public OnMapStart(){
	if(GetConVarInt(g_medieval)){
		new search = -1;
		while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
			AcceptEntityInput(search, "Disable");
	}
}

public Action:Spells(Handle:timer, any:hoge)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEdict(i) && IsClientConnected(i) && IsPlayerAlive(i))
		{
			new rint = GetRandomInt(0,8);

			if(!(GetConVarInt(g_block))){		// 9-11 is too strong, and cause a lag.
				rint = GetRandomInt(0,11);
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
						SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));

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
							ShowHudText(i, -1, "Picked up the spell: Summon MONOCULUS!");
						else if (rint == 10)
							ShowHudText(i, -1, "Picked up the spell: Fire Storm");
						else if (rint == 11)
							ShowHudText(i, -1, "Picked up the spell: Summon Skeletons");
					}
				}
			}
		}
	}
	CreateTimer(GetConVarFloat(g_time), Spells, 0);		// Loop
}

public Action:Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new search = -1;
	while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
		AcceptEntityInput(search, "Disable");
}

public Event_playerspawn(Handle:eventi, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt (eventi, "userid");
	new client = GetClientOfUserId (userid);

	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 2);

	if (TF2_GetPlayerClass(client) == TFClass_Scout)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat", 939, 100, 5, "2 ; 0.001 ; 49 ; 1"));
	else if (TF2_GetPlayerClass(client) == TFClass_Soldier)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat", 939, 100, 5, "2 ; 0.001"));
	else if (TF2_GetPlayerClass(client) == TFClass_Pyro)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat", 939, 100, 5, "2 ; 0.001"));
	else if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat", 939, 100, 5, "2 ; 0.001"));
	else if (TF2_GetPlayerClass(client) == TFClass_Heavy)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat", 939, 100, 5, "2 ; 0.001"));
	else if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		PrintToChat(client, "\x05This class is not allowed.");
		TF2_SetPlayerClass(client, TFClassType:TFClass_Pyro);
		TF2_RespawnPlayer(client);
	}
	else if (TF2_GetPlayerClass(client) == TFClass_Medic)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat", 939, 100, 5, "2 ; 0.001"));
	else if (TF2_GetPlayerClass(client) == TFClass_Sniper)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", SpawnWeapon(client, "tf_weapon_bat", 939, 100, 5, "2 ; 0.001"));
	else if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		PrintToChat(client, "\x05This class is not allowed.");
		TF2_SetPlayerClass(client, TFClassType:TFClass_Pyro);
		TF2_RespawnPlayer(client);
	}
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon == INVALID_HANDLE)
		return -1;
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0;  i < count;  i+= 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}