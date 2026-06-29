#pragma semicolon 1;

#include <sourcemod>
#include <tf2_stocks>

new Handle:g_time = INVALID_HANDLE;
new Handle:g_amount = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Spell MvM",
	author = "svaugrasn",
	description = "",
	version = "1.0.0",
	url = "none"
};

public OnPluginStart()
{
	g_time = CreateConVar("sm_spellmvm_time", "20.0", "");
	g_amount = CreateConVar("sm_spellmvm_amount", "5", "");

	CreateTimer(10.0, Spells, 0);

	HookEvent("player_spawn", Event_playerspawn);

}

public OnMapStart()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));

	if(strncmp(mapname, "mvm_", 4, false) == 0)
	{
		LogMessage("MvM map detected.");

		PrecacheModel("models/bots/skeleton_sniper/skeleton_sniper.mdl", true);
		PrecacheModel("models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl", true);

	}
 	 else
	{
		LogMessage("Current map is not a mvm map. Unloading spell mvm plugin.");
		ServerCommand("sm plugins unload spell_mvm");
	}

}

public Action:Spells(Handle:timer, any:hoge)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEdict(i) && IsClientConnected(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			new rint = GetRandomInt(0,22);
			new ent = -1;
			
			// http://forums.alliedmods.net/showthread.php?p=2054523
			while ((ent = FindEntityByClassname(ent, "tf_weapon_spellbook")) != -1)
			{
				if(ent)
				{
					if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == i)
					{
						SetHudTextParams(-1.0, 0.65, 6.0, 0, 255, 0, 255);

						// Probability adjustment

						if (rint == 0){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Fire Ball");
						}else if (rint == 1){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Fire Ball");
						}else if (rint == 2){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Fire Ball");
						}else if (rint == 3){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Fire Ball");
						}else if (rint == 4){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 0);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Fire Ball");
						}else if (rint == 5){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 1);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Ball O' Bats");
						}else if (rint == 6){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 1);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Ball O' Bats");
						}else if (rint == 7){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 1);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Ball O' Bats");
						}else if (rint == 8){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 1);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Ball O' Bats");
						}else if (rint == 9){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 2);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Healing Aura");
						}else if (rint == 10){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 2);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Healing Aura");
						}else if (rint == 11){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 3);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Pumpkin MIRV");
						}else if (rint == 12){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 3);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Pumpkin MIRV");
						}else if (rint == 13){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 3);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Pumpkin MIRV");

						//  Rare Magic Spells  //

						}else if (rint == 14){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 7);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Tesla Bolt");
						}else if (rint == 15){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 7);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Tesla Bolt");
						}else if (rint == 16){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 7);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Tesla Bolt");
						}else if (rint == 17){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 7);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Tesla Bolt");
						}else if (rint == 18){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 8);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Minify");
						}else if (rint == 19){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 9);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", 3);
							ShowHudText(i, -1, "Picked up the spell: Summon MONOCULUS");
						}else if (rint == 20){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 10);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Meteor Shower");
						}else if (rint == 21){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 10);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", GetConVarInt(g_amount));
							ShowHudText(i, -1, "Picked up the spell: Meteor Shower");
						}else if (rint == 22){
							SetEntProp(ent, Prop_Send, "m_iSelectedSpellIndex", 11);
							SetEntProp(ent, Prop_Send, "m_iSpellCharges", 3);
							ShowHudText(i, -1, "Picked up the spell: Summon Skeletons");
						}
					}
				}
			}
		}
	}
	CreateTimer(GetConVarFloat(g_time), Spells, 0);		// Loop
}

public Event_playerspawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt (event, "userid");
	new client = GetClientOfUserId (userid);

	if(IsFakeClient(client)){
		decl String:m_ModelName[128];
		GetEntPropString(client, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
		if(StrContains(m_ModelName, "boss") != -1){
			CreateTimer(1.0, Changebossmodel, client);
		}else{
			CreateTimer(1.0, Changemodel, client);
		}

	}

}


public Action:Changemodel(Handle:timer, any:client){
	SetVariantString("models/bots/skeleton_sniper/skeleton_sniper.mdl");
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

public Action:Changebossmodel(Handle:timer, any:client){
	SetVariantString("models/bots/skeleton_sniper_boss/skeleton_sniper_boss.mdl");
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}