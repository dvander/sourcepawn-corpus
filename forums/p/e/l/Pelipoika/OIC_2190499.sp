#pragma semicolon 1

#include <sourcemod>

#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <tf2items>
#include <tf2items_giveweapon>
#include <tf2>
#include <tf2_stocks>

new bool:OneInTheChamber;
new lives[MAXPLAYERS+1];

//One in the chamber
//Everyone is a sniper with The hunstman and a melee weapon
//Each player is given The Huntsman - and only The Huntsman - with one arrow. Use it wisely. Every shot kills.
//If you miss, you're limited to your melee. Every time you kill a player, you get an arrow. 
//Each player is given three lives. Players will have glow when only two players are left fighting, preventing player camping.

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	OneInTheChamber = true;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if(GetClientTeam(i) < 2)
			return;
		lives[i] = 3;
		TF2_SetPlayerClass(i, TFClass_Sniper, true, true);
		TF2_RespawnPlayer(i);
	}
	
	CPrintToChatAll("{unique}<-< {lime}One In the Quiver! {unique}>->");
	
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "func_respawnroomvisualizer")) != -1)
		AcceptEntityInput(ent, "Disable");
		
/*	new ammo = -1;
	while ((ammo = FindEntityByClassname(ammo, "item_ammopack_*")) != -1)
	{
		if (IsValidEntity(ammo))
		{
			AcceptEntityInput(ammo, "Kill");
		}
	}
	
	new supply = -1;
	while ((supply = FindEntityByClassname(supply, "func_regenerate")) != -1)
	{
		if (IsValidEntity(supply))
		{
			AcceptEntityInput(supply, "Kill");
		}
	}*/
}

public OnClientAuthorized(client)
{
	lives[client] = 3;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(OneInTheChamber)
	{
		if(IsValidClient(client) && GetClientTeam(client) != _:TFTeam_Spectator && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
		{
			if(GetClientTeam(client) < 2)
				return; // Spawning into spectate or Unassigned
		
			if(TF2_GetPlayerClass(client) != TFClass_Sniper)
			{
				TF2_SetPlayerClass(client, TFClass_Sniper);
				TF2_RespawnPlayer(client);
			}

			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Secondary);
			GiveBow(client);
			CreateTimer(0.5, Timer_SetAmmo, client);
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0, 1);
		}
			
		if(lives[client] <= 0)
			TF2_AddCondition(client, TFCond_HalloweenGhostMode, -1.0);
		else
			TF2_RemoveCondition(client, TFCond_HalloweenGhostMode);
	}
}

public Action:Timer_SetAmmo(Handle:timer, any:client)
{
	if(IsValidClient(client))
	{
		new weapon = GetPlayerWeaponSlot(client, 0);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		SetAmmo(client, 0, 0);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new deathflags = GetEventInt(event, "death_flags");
	
	if(OneInTheChamber && IsValidClient(victim) && IsValidClient(killer))
	{
		if (deathflags != TF_DEATHFLAG_DEADRINGER && victim != killer)
		{
			SetAmmo(killer, 0, GetAmmo(killer, 0) + 1);
			CPrintToChatEx(killer, victim, "{lime}+1 {unique}Arrow{default} for killing {teamcolor}%N", victim);
			
			lives[victim] -= 1;
			if(lives[victim] <= 0)
			{
				CPrintToChat(victim, "{red}You have no more lives remaining.");
				TF2_AddCondition(victim, TFCond_HalloweenGhostMode, -1.0);
			}
			else
			{
				CPrintToChat(victim, "You have {red}%i{default} more lives remaining", lives[victim]);
			}
			
			new REDTeam = 0;
			new BLUTeam = 0;
			
			for(new i=1; i<=GetMaxClients(); i++)
			{
				if(!IsClientInGame(i)) continue;
				if(GetClientTeam(i) != _:TFTeam_Spectator && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Red)
				{
					REDTeam++;
				}
				else if(GetClientTeam(i) != _:TFTeam_Spectator && IsPlayerAlive(i) && GetClientTeam(i) == _:TFTeam_Blue)
				{
					BLUTeam++;
				}
			}

			if(REDTeam <= 2 || BLUTeam <= 2)
			{
				if(REDTeam != 0)
				{
					PrintCenterTextAll("The RED TEAM is victorious!");
					ServerCommand("mp_restartgame 1");
				}
				else
				{
					PrintCenterTextAll("The BLUE TEAM is victorious!");
					ServerCommand("mp_restartgame 1");
				}
			
				for(new i=1; i<=GetMaxClients(); i++)
				{
					if(!IsClientInGame(i)) continue;
					if(!IsPlayerAlive(i)) continue;
					
					SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1, 1);
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable + iOffset, ammo, 4, true);
	}
}

stock GetAmmo(client, slot)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1) * 4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		return GetEntData(client, iAmmoTable + iOffset, 4);
	}
	
	return -1;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock GiveBow(client)
{
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_compound_bow");
		TF2Items_SetItemIndex(hWeapon, 56);
		TF2Items_SetLevel(hWeapon, 1);
		TF2Items_SetQuality(hWeapon, 5);
		new String:weaponAttribs[256];
		Format(weaponAttribs, sizeof(weaponAttribs), "2 ; 100.0 ; 258 ; 1.0");
		new String:weaponAttribsArray[32][32];
		new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
		if (attribCount > 0) 
		{
			TF2Items_SetNumAttributes(hWeapon, attribCount/2);
			new i2 = 0;
			for (new i = 0; i < attribCount; i+=2) 
			{
				TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
				i2++;
			}
		} 
		else 
		{
			TF2Items_SetNumAttributes(hWeapon, 0);
		}
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);

		CloseHandle(hWeapon);
		
		SetAmmo(client, 0, 0);
	}	
}