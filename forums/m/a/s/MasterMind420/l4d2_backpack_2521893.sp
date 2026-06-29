/*CHANGELOG
v0.8
Items automatically refill empty slots.
Limit backpack contents added. (Optional)
Pickup items while incap added. (Optional)
Display a backpack on players backs added. (Optional)
Configure players starting backpack contents added. (Optional)

v0.9
Removed some useless code snippets.
Added DeathDrop option - players drop or don't drop items on death.
Updated IsSurvivorThirdPerson bool, thanks Lux.

v1.0
Major rewrite fixed many bugs and did many optimizations.
Recreated the admin backpack menu to work much better.
Item switching can now be done pressing number keys(NGBUCKWANGS).
Added ability to drop items holding your RELOAD button(NGBUCKWANGS).
Added single tap and double tap option for item switching.
Added ThirdpersonShoulder Detect Plugin support.

v1.1
Fixed -
	Quantities not subtracting from player passing pills
	Item pickup not always working and needing to be pressed several times
Feature -
	Added incap pickup option again
	Modified item limit to use slot limit instead
	Added ability to pass multiple pills/adrenaline

v1.2
Fixed -
	Fixed broken qty hints system
	Fixed after throwing grenade switching to another
Feature -
        Made items more visible when swapping/dropping them

v1.3
Fixed -
	Fixed broken grenade replenish after dropping one
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

//INT
int HintIndex[2048+1], HintEntity[2048+1], Backpack[MAXPLAYERS+1][9], 
Storage[MAXPLAYERS+1][9], ItemUsed[MAXPLAYERS+1][9], LastSlot[MAXPLAYERS+1], LastWeapon[MAXPLAYERS+1];

//BOOL
bool InUse[MAXPLAYERS+1], bInShove[MAXPLAYERS+1], bMissionLost[MAXPLAYERS+1], bIsIdlePlayer[MAXPLAYERS+1], 
bRoundStart[MAXPLAYERS+1], bBlockWeaponSwitch[MAXPLAYERS+1], bChangeIntercept[MAXPLAYERS+1], bDropWeapon[MAXPLAYERS+1];

//FLOAT
float LastDrop[MAXPLAYERS+1];

//CHAR
char gClassname[512], MedsMunch[MAXPLAYERS+1][32];
static const char SOUND_NOPICKUP[] = "ui/beep_error01.wav", Slot2Class[3][32] = {"molotov", "pipe_bomb", "vomitjar"},
Slot1Class[3][32] = {"pistol", "pistol_magnum", "melee"}, Slot4Class[2][32] = {"pain_pills", "adrenaline"},
Slot3Class[4][32] = {"first_aid_kit", "defibrillator", "upgradepack_incendiary", "upgradepack_explosive"},
Slot0Class[5][32] = {"rifle", "smg", "shotgun", "sniper", "grenade_launcher"};

//CONVAR
ConVar SwitchMode, DeathDrop, IncapPickup, ShowQuantity, slot2_max, slot3_max, slot4_max,
start_molotovs, start_pipebombs, start_vomitjars, start_kits, start_defibs, start_incendiary, start_explosive, start_pills, start_adrenalines;

public Plugin myinfo =
{
	name = "Oshroth's Backpack",
	author = "MasterMind420, Lux, NGBUCKWANGS, Oshroth",
	description = "Players get a backpack to carry extra items",
	version = "1.3",
	url = ""
};

public void OnPluginStart()
{
	SwitchMode = CreateConVar("bp_switch_mode", "1", "[1 = SingleTap][2 = DoubleTap] Select item switch mode");
	DeathDrop = CreateConVar("bp_death_drop", "1", "[1 = Enable][0 = Disable] Drop backpack contents when players die");
	IncapPickup = CreateConVar("bp_incap_pickup", "1", "[1 = Enable][0 = Disable] Allow picking up items while incap");
	ShowQuantity = CreateConVar("bp_show_quantity", "4", "[0 = Disable][1 = Chat Text][2 = Hint Text][3 = Center Text][4 = Instructor Hint] Show item quantity");

	slot2_max = CreateConVar("l4d_slot2_max", "3", "Max Grenade Slot", _, true, 0.0);
	slot3_max = CreateConVar("l4d_slot3_max", "2", "Max Health Slot", _, true, 0.0);
	slot4_max = CreateConVar("l4d_slot4_max", "4", "Max Pills Slot", _, true, 0.0);

	start_molotovs = CreateConVar("l4d_backpack_start_mols", "0", "Starting Molotovs", _, true, 0.0);
	start_pipebombs = CreateConVar("l4d_backpack_start_pipes", "0", "Starting Pipe Bombs", _, true, 0.0);
	start_vomitjars = CreateConVar("l4d_backpack_start_biles", "0", "Starting Bile Jars", _, true, 0.0);
	start_kits = CreateConVar("l4d_backpack_start_kits", "0", "Starting Medkits", _, true, 0.0);
	start_defibs = CreateConVar("l4d_backpack_start_defibs", "0", "Starting Defibs", _, true, 0.0);
	start_incendiary = CreateConVar("l4d_backpack_start_firepacks", "0", "Starting Fire Ammo Packs", _, true, 0.0);
	start_explosive = CreateConVar("l4d_backpack_start_explodepacks", "0", "Starting Explode Ammo Packs", _, true, 0.0);
	start_pills = CreateConVar("l4d_backpack_start_pills", "0", "Starting Pills", _, true, 0.0);
	start_adrenalines = CreateConVar("l4d_backpack_start_adrens", "0", "Starting Adrenalines", _, true, 0.0);

	AutoExecConfig(true, "l4d2_backpack");

	HookEvent("round_start", eEvents);											//Used to save players backpacks
	HookEvent("player_spawn", eEvents);											//Used to fix slot items
	HookEvent("player_first_spawn", eEvents);									//Used to give starting backpack contents

	HookEvent("player_disconnect", eEvents, EventHookMode_Pre);					//Used to reset players on disconnect
	HookEvent("mission_lost", eEvents, EventHookMode_Pre);						//Used to reset players backpacks
	HookEvent("finale_win", eEvents, EventHookMode_Pre);						//Used to reset players backpacks

	HookEvent("player_death", eEvents);											//Used to catch dropping items on death
	HookEvent("player_bot_replace", eEvents);									//Used to transfer backpack contents to bots
	//HookEvent("bot_player_replace", eEvents);									//Used to restore previous player backpack

	HookEvent("weapon_given", eGiveWeapon, EventHookMode_Pre);					//Used to fix pills passing quantity
	HookEvent("revive_success", eReviveSuccessPre, EventHookMode_Pre);			//Used to fix Incap MedsMunch quantity
	HookEvent("revive_success", eReviveSuccess, EventHookMode_Post);			//Used to fix Incap MedsMunch quantity

	HookEvent("heal_success", eItemUsed); 										//Used to catch when someone uses kit
	HookEvent("defibrillator_used", eItemUsed); 								//Used to catch when someone uses defib
	HookEvent("upgrade_pack_used", eItemUsed); 									//Used to catch when someone uses ammo pack
	HookEvent("pills_used", eItemUsed); 										//Used to catch when someone uses pills
	HookEvent("adrenaline_used", eItemUsed); 									//Used to catch when someone uses adrenaline

	AddCommandListener(ChangeIntercept, "sm_map");
	AddCommandListener(ChangeIntercept, "changelevel");
	//AddCommandListener(ChangeIntercept, "skipouttro");
	//AddCommandListener(ChangeIntercept, "outtro_stats_done");

	for(int i = 1; i <= 2048; i++)
	{
		if(IsValidClient(i) && GetClientTeam(i) == 2)
		{
			QuantityFix(i);
			OnClientPutInServer(i);
		}

		if(IsValidEntity(i))
		{
			GetEntityClassname(i, gClassname, sizeof(gClassname));

			if(gClassname[0] != 'w' || StrContains(gClassname, "weapon_", false) != 0)
				continue;

			OnEntityCreated(i, gClassname);
		}
	}
}


public void OnPluginEnd()
{
	
}

public void OnAllPluginsLoaded()
{

}

public void OnMapStart()
{
	PrecacheSound(SOUND_NOPICKUP, true);
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		CreateHintEntity(client);

		SDKHook(client, SDKHook_WeaponEquipPost, WeaponEquipPost);
		SDKHook(client, SDKHook_WeaponSwitchPost, WeaponSwitchPost);
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	}
}

public Action ChangeIntercept(int client, const char[] cmd, int argc)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			bChangeIntercept[i] = true;
	}
}

public Action WeaponEquipPost(int client, int weapon)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsValidEntity(weapon))
	{
		char ClsName[32] = "GetAnyClassname(weapon)";
		ShowQuantities(client, ClsName);
	}

	return Plugin_Continue;
}

public Action WeaponSwitchPost(int client, int weapon)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsValidEntity(weapon))
	{
		if(bBlockWeaponSwitch[client])
		{
			bBlockWeaponSwitch[client] = false;
			return Plugin_Continue;
		}

		char ClsName[32] = "GetAnyClassname(weapon)";
		ShowQuantities(client, ClsName);
	}

	return Plugin_Continue;
}

public void OnPostThinkPost(int client)
{
	if(IsValidClient(client))
	{
//SET LASTSLOT AND LASTWEAPON
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if(IsValidEntity(weapon))
		{
			char sClsname[32];
			GetEntityClassname(weapon, sClsname, sizeof(sClsname));

			if(sClsname[0] != 'w' || StrContains(sClsname, "weapon_", false) != 0)
				return;

			int slot = DetectSlot(sClsname);

			LastSlot[client] = slot;
			LastWeapon[client] = weapon;
		}

//ENFORCE BACKPACK QUANTITIES
		if(Backpack[client][0] > GetConVarInt(slot2_max))
			Backpack[client][0] = GetConVarInt(slot2_max);
		else if(Backpack[client][0] < 0)
			Backpack[client][0] = 0;

		if(Backpack[client][1] > GetConVarInt(slot2_max))
			Backpack[client][1] = GetConVarInt(slot2_max);
		else if(Backpack[client][1] < 0)
			Backpack[client][1] = 0;

		if(Backpack[client][2] > GetConVarInt(slot2_max))
			Backpack[client][2] = GetConVarInt(slot2_max);
		else if(Backpack[client][2] < 0)
			Backpack[client][2] = 0;

		if(Backpack[client][3] > GetConVarInt(slot3_max))
			Backpack[client][3] = GetConVarInt(slot3_max);
		else if(Backpack[client][3] < 0)
			Backpack[client][3] = 0;

		if(Backpack[client][4] > GetConVarInt(slot3_max))
			Backpack[client][4] = GetConVarInt(slot3_max);
		else if(Backpack[client][4] < 0)
			Backpack[client][4] = 0;

		if(Backpack[client][5] > GetConVarInt(slot3_max))
			Backpack[client][5] = GetConVarInt(slot3_max);
		else if(Backpack[client][5] < 0)
			Backpack[client][5] = 0;

		if(Backpack[client][6] > GetConVarInt(slot3_max))
			Backpack[client][6] = GetConVarInt(slot3_max);
		else if(Backpack[client][6] < 0)
			Backpack[client][6] = 0;

		if(Backpack[client][7] > GetConVarInt(slot4_max))
			Backpack[client][7] = GetConVarInt(slot4_max);
		else if(Backpack[client][7] < 0)
			Backpack[client][7] = 0;

		if(Backpack[client][8] > GetConVarInt(slot4_max))
			Backpack[client][8] = GetConVarInt(slot4_max);
		else if(Backpack[client][8] < 0)
			Backpack[client][8] = 0;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "molotov_projectile") || StrEqual(classname, "pipe_bomb_projectile") || StrEqual(classname, "vomitjar_projectile"))
		SDKHook(entity, SDKHook_SpawnPost, BombSpawnPost);

	if(classname[0] != 'w' || StrContains(classname, "weapon_", false) != 0)
		return;

	if(DetectClassname(classname))
	{
		//SDKHook(entity, SDKHook_Use, OnPlayerUse);
		SDKHook(entity, SDKHook_SpawnPost, ItemSpawnPost);
	}
}

public Action OnEntityOutPut(const char[] output, int caller, int activator, float delay)
{
	//PrintToServer("%s, %d, %d, %0.2f", output, caller, activator, delay);
	PrintToChatAll("%s, %d, %d, %0.2f", output, caller, activator, delay);
}

public void ItemSpawnPost(int entity)
{
	if (IsValidEntity(entity))
	{
/*
		char sBuffer[32];
		FormatEx(sBuffer, sizeof(sBuffer), "OnUser1 activator:OnPlayerUse");
		SetVariantString(sBuffer);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");

		HookSingleEntityOutput(entity, "OnPlayerUse", OnEntityOutPut, false);
*/
		SDKUnhook(entity, SDKHook_SpawnPost, ItemSpawnPost);
		SDKHook(entity, SDKHook_Use, OnPlayerUse);
	}
}

public void BombSpawnPost(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	//bool bIsLive = GetEntProp(entity, Prop_Data, "m_bIsLive");
	//float fDamage = GetEntPropFloat(entity, Prop_Data, "m_flDamage");
	//int iDmgRadius = GetEntProp(entity, Prop_Data, "m_DmgRadius");
	//float fDetonateTime = GetEntPropFloat(entity, Prop_Data, "m_flDetonateTime");

	//PrintToChatAll("bIsLive %i fDamage %f fDetonateTime %f", bIsLive, fDamage, fDetonateTime);

	if(IsValidClient(client))
	{
		if(StrContains(GetAnyClassname(entity), "molotov") > -1)
		{
			ItemUsed[client][0] = 1;
			Backpack[client][0] -= 1;
		}
		else if(StrContains(GetAnyClassname(entity), "pipe_bomb") > -1)
		{
			ItemUsed[client][1] = 1;
			Backpack[client][1] -= 1;
		}
		else if(StrContains(GetAnyClassname(entity), "vomitjar") > -1)
		{
			ItemUsed[client][2] = 1;
			Backpack[client][2] -= 1;
		}

		CreateTimer(1.1, GiveGrenade, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		ShowQuantities(client, GetAnyClassname(entity));
	}
}

public Action GiveGrenade(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (IsValidClient(client))
		RequestFrame(NextFrame, client);
}

public Action OnPlayerUse(int entity, int activator, int caller, UseType type, float value)
{
	if(IsValidClient(activator) && IsValidEntity(entity))
	{
		//AcceptEntityInput(entity, "Use", activator, entity)
		//PrintToChat(activator, "AcceptEntityInput Use");

		int client = activator;

		char sClsName[32];
		GetEntityClassname(entity, sClsName, sizeof(sClsName));
		//PrintToChat(client, "OnPlayerUse %s", sClsName);

		if(StrContains(sClsName, "spawn") > -1)
		{
			if(GetEntProp(entity, Prop_Data, "m_spawnflags") < 8 && GetEntProp(entity, Prop_Data, "m_itemCount") < 1)
			{
				AcceptEntityInput(entity, "Kill", entity, entity);
				return Plugin_Handled;
			}
		}

		int iSlot = DetectSlot(sClsName);

		int slot = GetPlayerWeaponSlot(client, iSlot);

		char SlotName[32];

		if(slot > -1)
			GetEntityClassname(slot, SlotName, sizeof(SlotName));

		switch(iSlot)
		{
			case 2:
			{
				if(StrContains(sClsName, "molotov") > -1)
				{
					if((Backpack[client][0] + Backpack[client][1] + Backpack[client][2]) >= GetConVarInt(slot2_max))
					{
						if(StrContains(SlotName, "molotov") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//else if(StrContains(SlotName, "pipe_bomb") > -1)
						//	Backpack[client][1] -=1;
						//else if(StrContains(SlotName, "vomitjar") > -1)
						//	Backpack[client][2] -=1;

						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 2);

					Backpack[client][0] +=1;
				}
				else if(StrContains(sClsName, "pipe_bomb") > -1)
				{
					if((Backpack[client][0] + Backpack[client][1] + Backpack[client][2]) >= GetConVarInt(slot2_max))
					{
						if(StrContains(SlotName, "pipe_bomb") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//else if(StrContains(SlotName, "molotov") > -1)
						//	Backpack[client][0] -=1;
						//else if(StrContains(SlotName, "vomitjar") > -1)
						//	Backpack[client][2] -=1;
						
						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 2);

					Backpack[client][1] +=1;
				}
				else if(StrContains(sClsName, "vomitjar") > -1)
				{
					if((Backpack[client][0] + Backpack[client][1] + Backpack[client][2]) >= GetConVarInt(slot2_max))
					{
						if(StrContains(SlotName, "vomitjar") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//else if(StrContains(SlotName, "molotov") > -1)
						//	Backpack[client][0] -=1;
						//else if(StrContains(SlotName, "pipe_bomb") > -1)
						//	Backpack[client][1] -=1;
						
						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 2);

					Backpack[client][2] +=1;
				}
			}
			case 3:
			{
				if(StrContains(sClsName, "first_aid_kit") > -1)
				{
					if((Backpack[client][3] + Backpack[client][4] + Backpack[client][5] + Backpack[client][6]) >= GetConVarInt(slot3_max))
					{
						if(StrContains(SlotName, "first_aid_kit") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//else if(StrContains(SlotName, "defibrillator") > -1)
						//	Backpack[client][4] -=1;
						//else if(StrContains(SlotName, "upgradepack_incendiary") > -1)
						//	Backpack[client][5] -=1;
						//else if(StrContains(SlotName, "upgradepack_explosive") > -1)
						//	Backpack[client][6] -=1;
						
						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 3);

					Backpack[client][3] +=1;
				}
				else if(StrContains(sClsName, "defibrillator") > -1)
				{
					if((Backpack[client][3] + Backpack[client][4] + Backpack[client][5] + Backpack[client][6]) >= GetConVarInt(slot3_max))
					{
						if(StrContains(SlotName, "defibrillator") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//else if(StrContains(SlotName, "upgradepack_incendiary") > -1)
						//	Backpack[client][5] -=1;
						//else if(StrContains(SlotName, "upgradepack_explosive") > -1)
						//	Backpack[client][6] -=1;
						//else if(StrContains(SlotName, "first_aid_kit") > -1)
						//	Backpack[client][3] -=1;
						
						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 3);

					Backpack[client][4] +=1;
				}
				else if(StrContains(sClsName, "upgradepack_incendiary") > -1)
				{
					if((Backpack[client][3] + Backpack[client][4] + Backpack[client][5] + Backpack[client][6]) >= GetConVarInt(slot3_max))
					{
						if(StrContains(SlotName, "upgradepack_incendiary") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//else if(StrContains(SlotName, "upgradepack_explosive") > -1)
						//	Backpack[client][6] -=1;
						//else if(StrContains(SlotName, "first_aid_kit") > -1)
						//	Backpack[client][3] -=1;
						//else if(StrContains(SlotName, "defibrillator") > -1)
						//	Backpack[client][4] -=1;
						
						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 3);

					Backpack[client][5] +=1;
				}
				else if(StrContains(sClsName, "upgradepack_explosive") > -1)
				{
					if((Backpack[client][3] + Backpack[client][4] + Backpack[client][5] + Backpack[client][6]) >= GetConVarInt(slot3_max))
					{
						if(StrContains(SlotName, "upgradepack_explosive") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//if(StrContains(SlotName, "first_aid_kit") > -1)
						//	Backpack[client][3] -=1;
						//else if(StrContains(SlotName, "defibrillator") > -1)
						//	Backpack[client][4] -=1;
						//if(StrContains(SlotName, "upgradepack_incendiary") > -1)
						//	Backpack[client][5] -=1;
						
						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 3);

					Backpack[client][6] +=1;
				}
			}
			case 4:
			{
				if(StrContains(sClsName, "pain_pills") > -1)
				{
					if((Backpack[client][7] + Backpack[client][8]) >= GetConVarInt(slot4_max))
					{
						if(StrContains(SlotName, "pain_pills") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//else if(StrContains(SlotName, "adrenaline") > -1)
						//	Backpack[client][8] -=1;
						
						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 4);

					Backpack[client][7] +=1;
				}
				else if(StrContains(sClsName, "adrenaline") > -1)
				{
					if((Backpack[client][7] + Backpack[client][8]) >= GetConVarInt(slot4_max))
					{
						if(StrContains(SlotName, "adrenaline") > -1)
						{
							EmitSoundToClient(client, SOUND_NOPICKUP, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
							return Plugin_Handled;
						}
						//else if(StrContains(SlotName, "pain_pills") > -1)
						//	Backpack[client][7] -=1;
						
						DropWeapon(client, slot, SlotName);
					}
					else
						RemoveWeapon(client, 4);

					Backpack[client][8] +=1;
				}
			}
		}

		ShowQuantities(client, sClsName);
		SDKUnhook(entity, SDKHook_Use, OnPlayerUse);
		AcceptEntityInput(entity, "Use", client, entity);
/*
		if (AcceptEntityInput(entity, "Use", client, entity))
			PrintToChat(client, "AcceptEntityInput Use = True");
		else
			PrintToChat(client, "AcceptEntityInput Use = False");
*/
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		char ClsName[32];

//===== MULTIPLE PILLS PASS =====//
		if(!bInShove[client] && buttons & 2048)
		{
			bInShove[client] = true;

			int iWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

			if(iWeapon > -1)
			{
				GetEntityClassname(iWeapon, ClsName, sizeof(ClsName));

				if(StrContains(ClsName, "adrenaline") > -1 || StrContains(ClsName, "pills") > -1)
				{
					int target = GetClientAimTarget(client);

					if(target > 0 && target <= MaxClients && GetClientTeam(target) == 2)
					{
						int slot = GetPlayerWeaponSlot(target, 4);

						if(StrContains(ClsName, "pills") > -1)
						{
							if(Backpack[target][7] < GetConVarInt(slot4_max))
							{
								if(slot > -1)
									AcceptEntityInput(slot, "Kill", slot, slot);
							}
						}
						else if(StrContains(ClsName, "adrenaline") > -1)
						{
							if(Backpack[target][8] < GetConVarInt(slot4_max))
							{
								if(slot > -1)
									AcceptEntityInput(slot, "Kill", slot, slot);
							}
						}
					}
				}
			}
		}
		else if(bInShove[client] && !(buttons & 2048))
			bInShove[client] = false;

//===== INCAP PICKUP =====//
		if(!InUse[client] && buttons & IN_USE == IN_USE)
		{
			InUse[client] = true;

			if(GetConVarInt(IncapPickup) == 1 && IsIncapped(client))
			{
				int entity = -1;
				while ((entity = FindEntityByClassname(entity, "weapon_*")) != -1)
				{
					if(IsValidEntity(entity) && IsTargetInSightRange(client, entity, 30.0, 80.0))
					{
						GetEntityClassname(entity, ClsName, sizeof(ClsName));

						if(StrContains(ClsName, "molotov") > -1 || StrContains(ClsName, "pipe_bomb") > -1 ||
							StrContains(ClsName, "vomitjar") > -1 || StrContains(ClsName, "first_aid_kit") > -1 ||
							StrContains(ClsName, "defibrillator") > -1 || StrContains(ClsName, "upgradepack_incendiary") > -1 ||
							StrContains(ClsName, "upgradepack_explosive") > -1 || StrContains(ClsName, "pain_pills") > -1 ||
							StrContains(ClsName, "adrenaline") > -1)
						{
							ShowQuantities(client, ClsName);
							SDKUnhook(entity, SDKHook_Use, OnPlayerUse);
							AcceptEntityInput(entity, "Use", client, entity);
						}
					}
				}
			}
		}
		else if(InUse[client] && !(buttons & IN_USE))
			InUse[client] = false;

//===== QUICKSWITCH =====//
		if(IsValidEntity(weapon))
			GetEntityClassname(weapon, ClsName, sizeof(ClsName));

		int slot = DetectSlot(ClsName);

		if(slot > 1 && slot < 5)
		{
/*
			if(IsIncapped(client))
			{
				if(GetPlayerWeaponSlot(client, 2) > -1)
				{
					ChangeWeapon(client, 2);
					bBlockWeaponSwitch[client] = true;
				}
				if(GetPlayerWeaponSlot(client, 3) > -1)
				{
					ChangeWeapon(client, 3);
					bBlockWeaponSwitch[client] = true;
				}
				if(GetPlayerWeaponSlot(client, 4) > -1)
				{
					ChangeWeapon(client, 4);
					bBlockWeaponSwitch[client] = true;
				}

				return Plugin_Continue;
			}
*/
			if(GetConVarInt(SwitchMode) == 1) //SingleTap
			{
				if(LastSlot[client] != slot)
				{
					LastSlot[client] = slot;
					return Plugin_Continue;
				}
			}
			else if(GetConVarInt(SwitchMode) == 2) //DoubleTap
			{
				if(LastWeapon[client] != weapon)
				{
					LastWeapon[client] = weapon;
					return Plugin_Continue;
				}
			}

			ChangeWeapon(client, slot);
			bBlockWeaponSwitch[client] = true;

			return Plugin_Continue;
		}

//===== QUICKDROP =====//
		float engineTime = GetEngineTime();

		if((buttons == 8192) && engineTime > LastDrop[client])
		{
			if(bDropWeapon[client])
			{
				bDropWeapon[client] = false;
				LastDrop[client] = engineTime + 0.75;

				int aWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

				if(IsValidEntity(aWeapon))
				{
					GetEntityClassname(aWeapon, ClsName, sizeof(ClsName));
					slot = DetectSlot(ClsName);

					if(slot == 0 || slot == 1)
						return Plugin_Continue;

					if(slot > 1 && slot < 5)
					{
						if(LastSlot[client] == slot)
						{
							DropWeapon(client, aWeapon, ClsName);
							RequestFrame(NextFrame, client);
						}
					}
				}
			}
		}
		else if(buttons != 8192)
		{
			bDropWeapon[client] = true;
			LastDrop[client] = engineTime + 0.75;
		}
//===== QUICKDROP =====//
	}

	return Plugin_Continue;
}

public void eItemUsed(Event event, const char[] name, bool dontBroadcast)
{
	int client;

	if(StrEqual(name, "heal_success"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client) && !IsFakeClient(client))
		{
			ItemUsed[client][3] = 1;
			Backpack[client][3] -= 1;

			RequestFrame(NextFrame, client);

			char ClsName[32] = "weapon_first_aid_kit";
			ShowQuantities(client, ClsName);
		}
	}
	else if(StrEqual(name, "defibrillator_used"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client) && !IsFakeClient(client))
		{
			ItemUsed[client][4] = 1;
			Backpack[client][4] -= 1;

			RequestFrame(NextFrame, client);

			char ClsName[32] = "weapon_defibrillator";
			ShowQuantities(client, ClsName);
		}
	}
	else if(StrEqual(name, "upgrade_pack_used"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client) && !IsFakeClient(client))
		{
			char sClsName[32];
			GetEntityClassname(event.GetInt("upgradeid"), sClsName, sizeof(sClsName));

			if(StrEqual(sClsName, "upgrade_ammo_incendiary"))
			{
				ItemUsed[client][5] = 1;
				Backpack[client][5] -= 1;

				RequestFrame(NextFrame, client);
			}	
			else if(StrEqual(sClsName, "upgrade_ammo_explosive"))
			{
				ItemUsed[client][6] = 1;
				Backpack[client][6] -= 1;

				RequestFrame(NextFrame, client);
			}

			ShowQuantities(client, sClsName);
		}
	}
	else if(StrEqual(name, "pills_used"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client) && !IsFakeClient(client))
		{
			ItemUsed[client][7] = 1;
			Backpack[client][7] -= 1;
			RequestFrame(NextFrame, client);

			char ClsName[32] = "weapon_pain_pills";
			ShowQuantities(client, ClsName);
		}
	}
	else if(StrEqual(name, "adrenaline_used"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client) && !IsFakeClient(client))
		{
			ItemUsed[client][8] = 1;
			Backpack[client][8] -= 1;
			RequestFrame(NextFrame, client);

			char ClsName[32] = "weapon_adrenaline";
			ShowQuantities(client, ClsName);
		}
	}
}

void ChangeWeapon(int client, int slot = -1)
{
	char ClsName[32];
	Format(ClsName, sizeof(ClsName), GetAnyClassname(client, slot));

	switch(slot)
	{
		case 0:
		{
			
		}
		case 1:
		{
			
		}
        case 2:
		{
			if(StrContains(ClsName, "molotov") > -1)
			{
				if(Backpack[client][0] > 0 && Backpack[client][1] < 1 && Backpack[client][2] < 1)
					return;

				if(Backpack[client][1] > 0)
					GiveWeapon(client, "weapon_pipe_bomb", 2);
				else if(Backpack[client][2] > 0)
					GiveWeapon(client, "weapon_vomitjar", 2);
				else
					GiveWeapon(client, "weapon_molotov", 2);
			}
			else if (StrContains(ClsName, "pipe_bomb") > -1)
			{
				if(Backpack[client][1] > 0 && Backpack[client][2] < 1 && Backpack[client][0] < 1)
					return;

				if(Backpack[client][2] > 0)
					GiveWeapon(client, "weapon_vomitjar", 2);
				else if(Backpack[client][0] > 0)
					GiveWeapon(client, "weapon_molotov", 2);
				else
					GiveWeapon(client, "weapon_pipe_bomb", 2);
			}
			else if (StrContains(ClsName, "vomitjar") > -1)
			{
				if(Backpack[client][2] > 0 && Backpack[client][0] < 1 && Backpack[client][1] < 1)
					return;

				if(Backpack[client][0] > 0)
					GiveWeapon(client, "weapon_molotov", 2);
				else if(Backpack[client][1] > 0)
					GiveWeapon(client, "weapon_pipe_bomb", 2);
				else
					GiveWeapon(client, "weapon_vomitjar", 2);
			}
		}
        case 3:
		{
			if (StrContains(ClsName, "first_aid_kit") > -1)
			{
				if(Backpack[client][3] > 0 && Backpack[client][4] < 1 && Backpack[client][5] < 1 && Backpack[client][6] < 1)
					return;

				if(Backpack[client][4] > 0)
					GiveWeapon(client, "weapon_defibrillator", 3);
				else if(Backpack[client][5] > 0)
					GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
				else if(Backpack[client][6] > 0)
					GiveWeapon(client, "weapon_upgradepack_explosive", 3);
				else
					GiveWeapon(client, "weapon_first_aid_kit", 3);
			}
			else if (StrContains(ClsName, "defibrillator") > -1)
			{
				if(Backpack[client][4] > 0 && Backpack[client][5] < 1 && Backpack[client][6] < 1 && Backpack[client][3] < 1)
					return;

				if(Backpack[client][5] > 0)
					GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
				else if(Backpack[client][6] > 0)
					GiveWeapon(client, "weapon_upgradepack_explosive", 3);
				else if(Backpack[client][3] > 0)
					GiveWeapon(client, "weapon_first_aid_kit", 3);
				else
					GiveWeapon(client, "weapon_defibrillator", 3);
			}
			else if (StrContains(ClsName, "upgradepack_incendiary") > -1)
			{
				if(Backpack[client][5] > 0 && Backpack[client][6] < 1 && Backpack[client][3] < 1 && Backpack[client][4] < 1)
					return;

				if(Backpack[client][6] > 0)
					GiveWeapon(client, "weapon_upgradepack_explosive", 3);
				else if(Backpack[client][3] > 0)
					GiveWeapon(client, "weapon_first_aid_kit", 3);
				else if(Backpack[client][4] > 0)
					GiveWeapon(client, "weapon_defibrillator", 3);
				else
					GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
			}
			else if (StrContains(ClsName, "upgradepack_explosive") > -1)
			{
				if(Backpack[client][6] > 0 && Backpack[client][3] < 1 && Backpack[client][4] < 1 && Backpack[client][5] < 1)
					return;

				if(Backpack[client][3] > 0)
					GiveWeapon(client, "weapon_first_aid_kit", 3);
				else if(Backpack[client][4] > 0)
					GiveWeapon(client, "weapon_defibrillator", 3);
				else if(Backpack[client][5] > 0)
					GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
				else
					GiveWeapon(client, "weapon_upgradepack_explosive", 3);
			}
        }
        case 4:
		{
			if (StrContains(ClsName, "pain_pills") > -1)
			{
				if(Backpack[client][7] > 0 && Backpack[client][8] < 1)
					return;

				if(Backpack[client][8] > 0)
					GiveWeapon(client, "weapon_adrenaline", 4);
				else
					GiveWeapon(client, "weapon_pain_pills", 4);
			}
			else if (StrContains(ClsName, "adrenaline") > -1)
			{
				if(Backpack[client][8] > 0 && Backpack[client][7] < 1)
					return;

				if(Backpack[client][7] > 0)
					GiveWeapon(client, "weapon_pain_pills", 4);
				else
					GiveWeapon(client, "weapon_adrenaline", 4);
			}
        }
    }
}

bool DetectClassname(const char[] clsname)
{
	if(clsname[0] != 'w' || StrContains(clsname, "weapon_", false) != 0)
		return false;

	for (int i = 0; i < sizeof(Slot2Class); i++)
	{
		if (StrContains(clsname, Slot2Class[i]) > -1)
			return true;
	}

	for (int i = 0; i < sizeof(Slot3Class); i++)
	{
		if (StrContains(clsname, Slot3Class[i]) > -1)
			return true;
	}

	for (int i = 0; i < sizeof(Slot4Class); i++)
	{
		if (StrContains(clsname, Slot4Class[i]) > -1)
			return true;
	}

	return false;
}

int DetectSlot(const char[] clsname)
{
	if(clsname[0] != 'w' || StrContains(clsname, "weapon_", false) != 0)
		return -1;

	for (int i = 0; i < sizeof(Slot0Class); i++)
	{
		if (StrContains(clsname, Slot0Class[i]) > -1)
			return 0;
	}

	for (int i = 0; i < sizeof(Slot1Class); i++)
	{
		if (StrContains(clsname, Slot1Class[i]) > -1)
			return 1;
	}

	for (int i = 0; i < sizeof(Slot2Class); i++)
	{
		if (StrContains(clsname, Slot2Class[i]) > -1)
			return 2;
	}

	for (int i = 0; i < sizeof(Slot3Class); i++)
	{
		if (StrContains(clsname, Slot3Class[i]) > -1)
			return 3;
	}

	for (int i = 0; i < sizeof(Slot4Class); i++)
	{
		if (StrContains(clsname, Slot4Class[i]) > -1)
			return 4;
	}

	return -1;
}

void GiveWeapon(int client, char[] sClsName, int slot = -1)
{
	if(IsValidClient(client))
	{
		if(StrContains(sClsName, "molotov") > -1)
		{
			if(Backpack[client][0] <= 0)
				return;
		}
		else if(StrContains(sClsName, "pipe_bomb") > -1)
		{
			if(Backpack[client][1] <= 0)
				return;
		}
		else if(StrContains(sClsName, "vomitjar") > -1)
		{
			if(Backpack[client][2] <= 0)
				return;
		}
		else if(StrContains(sClsName, "first_aid_kit") > -1)
		{
			if(Backpack[client][3] <= 0)
				return;
		}
		else if(StrContains(sClsName, "defibrillator") > -1)
		{
			if(Backpack[client][4] <= 0)
				return;
		}
		else if(StrContains(sClsName, "upgradepack_incendiary") > -1)
		{
			if(Backpack[client][5] <= 0)
				return;
		}
		else if(StrContains(sClsName, "upgradepack_explosive") > -1)
		{
			if(Backpack[client][6] <= 0)
				return;
		}
		else if(StrContains(sClsName, "pain_pills") > -1)
		{
			if(Backpack[client][7] <= 0)
				return;
		}
		else if(StrContains(sClsName, "adrenaline") > -1)
		{
			if(Backpack[client][8] <= 0)
				return;
		}

		int entity = CreateEntityByName(sClsName);

		if(IsValidEntity(entity))
		{
			if(!DispatchSpawn(entity))
			{
				AcceptEntityInput(entity, "Kill");
				return;
			}

			ActivateEntity(entity);
			RemoveWeapon(client, slot);

			SDKUnhook(entity, SDKHook_Use, OnPlayerUse);
			AcceptEntityInput(entity, "use", client);
			//SDKHook(entity, SDKHook_Use, OnPlayerUse);
		}
	}
}

void RemoveWeapon(int client, int slot)
{
	int entity = GetPlayerWeaponSlot(client, slot);

	if(IsValidEntity(entity))
	{
		RemovePlayerItem(client, entity);
		AcceptEntityInput(entity, "kill");
	}
}

void DropWeapon(int client, int weapon, char[] sClassname)
{
	int entity = CreateEntityByName(sClassname);

	if (!IsValidEntity(entity) || !DispatchSpawn(entity))
		return;

	if (IsValidEntity(weapon))
	{
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "kill");
	}

	AcceptEntityInput(entity, "DisableDamageForces");
	ActivateEntity(entity);

	SDKUnhook(entity, SDKHook_Use, OnPlayerUse);

//THROW ITEM AT AIM
	float Pos[3], vecAngles[3], vecVelocity[3];

	GetClientEyePosition(client, Pos);
	GetClientEyeAngles(client, vecAngles);
	GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);

	vecVelocity[0] *= 300.0;
	vecVelocity[1] *= 300.0;
	vecVelocity[2] *= 300.0;

	TeleportEntity(entity, Pos, NULL_VECTOR, vecVelocity);
//THROW ITEM AT AIM

	SDKHook(entity, SDKHook_Use, OnPlayerUse);

	if(StrContains(sClassname, "molotov") > -1)
	{
		Backpack[client][0] -= 1;
		ItemUsed[client][0] = 1;
	}
	else if(StrContains(sClassname, "pipe_bomb") > -1)
	{
		Backpack[client][1] -= 1;
		ItemUsed[client][1] = 1;
	}
	else if(StrContains(sClassname, "vomitjar") > -1)
	{
		Backpack[client][2] -= 1;
		ItemUsed[client][2] = 1;
	}
	else if(StrContains(sClassname, "first_aid_kit") > -1)
	{
		Backpack[client][3] -= 1;
		ItemUsed[client][3] = 1;
	}
	else if(StrContains(sClassname, "defibrillator") > -1)
	{
		Backpack[client][4] -= 1;
		ItemUsed[client][4] = 1;
	}
	else if(StrContains(sClassname, "upgradepack_incendiary") > -1)
	{
		Backpack[client][5] -= 1;
		ItemUsed[client][5] = 1;
	}
	else if(StrContains(sClassname, "upgradepack_explosive") > -1)
	{
		Backpack[client][6] -= 1;
		ItemUsed[client][6] = 1;
	}
	else if(StrContains(sClassname, "pain_pills") > -1)
	{
		Backpack[client][7] -= 1;
		ItemUsed[client][7] = 1;
	}
	else if(StrContains(sClassname, "adrenaline") > -1)
	{
		Backpack[client][8] -= 1;
		ItemUsed[client][8] = 1;
	}
}

void QuantityFix(int client)
{
	char ClsName[32];
	Format(ClsName, sizeof(ClsName), GetAnyClassname(client, 2));

	if(StrEqual(ClsName, "weapon_molotov"))
		Backpack[client][0] = 1;
	else if(StrEqual(ClsName, "weapon_pipe_bomb"))
		Backpack[client][1] = 1;
	else if(StrEqual(ClsName, "weapon_vomitjar"))
		Backpack[client][2] = 1;

	Format(ClsName, sizeof(ClsName), GetAnyClassname(client, 3));

	if(StrEqual(ClsName, "weapon_first_aid_kit"))
		Backpack[client][3] = 1;
	else if(StrEqual(ClsName, "weapon_defibrillator"))
		Backpack[client][4] = 1;
	else if(StrEqual(ClsName, "weapon_upgradepack_incendiary"))
		Backpack[client][5] = 1;
	else if(StrEqual(ClsName, "weapon_upgradepack_explosive"))
		Backpack[client][6] = 1;

	Format(ClsName, sizeof(ClsName), GetAnyClassname(client, 4));

	if(StrEqual(ClsName, "weapon_pain_pills"))
		Backpack[client][7] = 1;
	else if(StrEqual(ClsName, "weapon_adrenaline"))
		Backpack[client][8] = 1;
}

public void eEvents(Event event, const char[] name, bool dontBroadcast)
{
	int client;

	if(StrEqual(name, "round_start"))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
				bRoundStart[i] = true;
		}

		SaveBackpack(_, true);
	}
	else if(StrEqual(name, "player_first_spawn"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
		{
			StartBackpack(client);
			SaveBackpack(client);
			CreateHintEntity(client);
		}
	}
	else if(StrEqual(name, "player_spawn"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client) && GetClientTeam(client) == 2)
		{
			int userid = GetClientUserId(client);

			if(bMissionLost[client])
			{
				bMissionLost[client] = false;
				LoadBackpack(client);

				CreateTimer(0.3, FixBackpack, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if(bRoundStart[client] || bChangeIntercept[client])
			{
				bRoundStart[client] = false;
				bChangeIntercept[client] = false;

				if(Backpack[client][3] < 1) //GIVE HEALTHPACK AT ROUNDSTART IF HAVE NONE
					Backpack[client][3] = 1;

				CreateTimer(0.3, FixBackpack, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
			else if(bIsIdlePlayer[client])
			{
				bIsIdlePlayer[client] = false;
				CreateTimer(0.3, FixBackpack, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else if(StrEqual(name, "player_bot_replace"))
	{
		int bot = GetClientOfUserId(event.GetInt("bot"));
		int player = GetClientOfUserId(event.GetInt("player"));

		Storage[player][0] = Backpack[player][0];
		Storage[player][1] = Backpack[player][1];
		Storage[player][2] = Backpack[player][2];
		Storage[player][3] = Backpack[player][3];
		Storage[player][4] = Backpack[player][4];
		Storage[player][5] = Backpack[player][5];
		Storage[player][6] = Backpack[player][6];
		Storage[player][7] = Backpack[player][7];
		Storage[player][8] = Backpack[player][8];

		Backpack[bot][0] = Backpack[player][0];
		Backpack[bot][1] = Backpack[player][1];
		Backpack[bot][2] = Backpack[player][2];
		Backpack[bot][3] = Backpack[player][3];
		Backpack[bot][4] = Backpack[player][4];
		Backpack[bot][5] = Backpack[player][5];
		Backpack[bot][6] = Backpack[player][6];
		Backpack[bot][7] = Backpack[player][7];
		Backpack[bot][8] = Backpack[player][8];

		bIsIdlePlayer[player] = true;
	}
	else if(StrEqual(name, "bot_player_replace"))
	{
		//int bot = GetClientOfUserId(event.GetInt("bot"));
		int player = GetClientOfUserId(event.GetInt("player"));
/*
		Backpack[player][0] = Backpack[bot][0];
		Backpack[player][1] = Backpack[bot][1];
		Backpack[player][2] = Backpack[bot][2];
		Backpack[player][3] = Backpack[bot][3];
		Backpack[player][4] = Backpack[bot][4];
		Backpack[player][5] = Backpack[bot][5];
		Backpack[player][6] = Backpack[bot][6];
		Backpack[player][7] = Backpack[bot][7];
		Backpack[player][8] = Backpack[bot][8];
*/
		if(IsValidClient(player))
		{
			int userid = GetClientUserId(player);
			CreateTimer(0.3, FixBackpack, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if(StrEqual(name, "player_death"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client) && GetClientTeam(client) == 2)
		{
			if(GetConVarInt(DeathDrop) == 1)
			{
				float victim[3];
				victim[0] = GetEventFloat(event, "victim_x");
				victim[1] = GetEventFloat(event, "victim_y");
				victim[2] = GetEventFloat(event, "victim_z");

				SpawnItem(victim, "weapon_molotov", Backpack[client][0]);
				SpawnItem(victim, "weapon_pipe_bomb", Backpack[client][1]);
				SpawnItem(victim, "weapon_vomitjar", Backpack[client][2]);
				SpawnItem(victim, "weapon_first_aid_kit", Backpack[client][3]);
				SpawnItem(victim, "weapon_defibrillator", Backpack[client][4]);
				SpawnItem(victim, "weapon_upgradepack_incendiary", Backpack[client][5]);
				SpawnItem(victim, "weapon_upgradepack_explosive", Backpack[client][6]);
				SpawnItem(victim, "weapon_pain_pills", Backpack[client][7]);
				SpawnItem(victim, "weapon_adrenaline", Backpack[client][8]);
			}

			ResetBackpack(client);
		}
	}
	else if(StrEqual(name, "player_disconnect"))
	{
		client = GetClientOfUserId(event.GetInt("userid"));

		if(IsValidClient(client))
			ResetBackpack(client); //POSSIBLY ALLOW BOTS TO KEEP PLAYERS BACKPACKS?
	}
	else if(StrEqual(name, "mission_lost"))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
				bMissionLost[i] = true;
		}
	}
	else if(StrEqual(name, "finale_win"))
	{
		ResetBackpack(0);
	}
}

public void NextFrame(any client)
{
	RequestFrame(GiveItem, client);
}

public void GiveItem(any client)
{
	if(IsValidClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if(ItemUsed[client][0] == 1)
		{
			ItemUsed[client][0] = 0;

			if(Backpack[client][0] > 0)
			{
				GiveWeapon(client, "weapon_molotov", 2);
				//ClientCommand(client, "slot3");
			}
			else if(Backpack[client][1] > 0)
			{
				GiveWeapon(client, "weapon_pipe_bomb", 2);
				//ClientCommand(client, "slot3");
			}
			else if(Backpack[client][2] > 0)
			{
				GiveWeapon(client, "weapon_vomitjar", 2);
				//ClientCommand(client, "slot3");
			}
		}
		else if(ItemUsed[client][1] == 1)
		{
			ItemUsed[client][1] = 0;

			if(Backpack[client][1] > 0)
			{
				GiveWeapon(client, "weapon_pipe_bomb", 2);
				//ClientCommand(client, "slot3");
			}
			else if(Backpack[client][2] > 0)
			{
				GiveWeapon(client, "weapon_vomitjar", 2);
				//ClientCommand(client, "slot3");
			}
			else if(Backpack[client][0] > 0)
			{
				GiveWeapon(client, "weapon_molotov", 2);
				//ClientCommand(client, "slot3");
			}
		}
		else if(ItemUsed[client][2] == 1)
		{
			ItemUsed[client][2] = 0;

			if(Backpack[client][2] > 0)
			{
				GiveWeapon(client, "weapon_vomitjar", 2);
				//ClientCommand(client, "slot3");
			}
			else if(Backpack[client][0] > 0)
			{
				GiveWeapon(client, "weapon_molotov", 2);
				//ClientCommand(client, "slot3");
			}
			else if(Backpack[client][1] > 0)
			{
				GiveWeapon(client, "weapon_pipe_bomb", 2);
				//ClientCommand(client, "slot3");
			}
		}
		else if(ItemUsed[client][3] == 1)
		{
			ItemUsed[client][3] = 0;

			if(Backpack[client][3] > 0)
			{
				GiveWeapon(client, "weapon_first_aid_kit", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][4] > 0)
			{
				GiveWeapon(client, "weapon_defibrillator", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][5] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][6] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_explosive", 3);
				//ClientCommand(client, "slot4");
			}
		}
		else if(ItemUsed[client][4] == 1)
		{
			ItemUsed[client][4] = 0;

			if(Backpack[client][4] > 0)
			{
				GiveWeapon(client, "weapon_defibrillator", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][5] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][6] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_explosive", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][3] > 0)
			{
				GiveWeapon(client, "weapon_first_aid_kit", 3);
				//ClientCommand(client, "slot4");
			}
		}
		else if(ItemUsed[client][5] == 1)
		{
			ItemUsed[client][5] = 0;

			if(Backpack[client][5] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][6] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_explosive", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][3] > 0)
			{
				GiveWeapon(client, "weapon_first_aid_kit", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][4] > 0)
			{
				GiveWeapon(client, "weapon_defibrillator", 3);
				//ClientCommand(client, "slot4");
			}
		}
		else if(ItemUsed[client][6] == 1)
		{
			ItemUsed[client][6] = 0;

			if(Backpack[client][6] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_explosive", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][3] > 0)
			{
				GiveWeapon(client, "weapon_first_aid_kit", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][4] > 0)
			{
				GiveWeapon(client, "weapon_defibrillator", 3);
				//ClientCommand(client, "slot4");
			}
			else if(Backpack[client][5] > 0)
			{
				GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
				//ClientCommand(client, "slot4");
			}
		}
		else if(ItemUsed[client][7] == 1)
		{
			ItemUsed[client][7] = 0;

			if(Backpack[client][7] > 0)
			{
				GiveWeapon(client, "weapon_pain_pills", 4);
				//ClientCommand(client, "slot5");
			}
			else if(Backpack[client][8] > 0)
			{
				GiveWeapon(client, "weapon_adrenaline", 4);
				//ClientCommand(client, "slot5");
			}
		}
		else if(ItemUsed[client][8] == 1)
		{
			ItemUsed[client][8] = 0;

			if(Backpack[client][8] > 0)
			{
				GiveWeapon(client, "weapon_adrenaline", 4);
				//ClientCommand(client, "slot5");
			}
			else if(Backpack[client][7] > 0)
			{
				GiveWeapon(client, "weapon_pain_pills", 4);
				//ClientCommand(client, "slot5");
			}
		}
	}
}

public Action FixBackpack(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(IsValidClient(client) && GetClientTeam(client) == 2)
	{
		if(Backpack[client][0] > 0)
			GiveWeapon(client, "weapon_molotov", 2);
		else if(Backpack[client][1] > 0)
			GiveWeapon(client, "weapon_pipe_bomb", 2);
		else if(Backpack[client][2] > 0)
			GiveWeapon(client, "weapon_vomitjar", 2);

		if(Backpack[client][3] > 0)
			GiveWeapon(client, "weapon_first_aid_kit", 3);
		else if(Backpack[client][4] > 0)
			GiveWeapon(client, "weapon_defibrillator", 3);
		else if(Backpack[client][5] > 0)
			GiveWeapon(client, "weapon_upgradepack_incendiary", 3);
		else if(Backpack[client][6] > 0)
			GiveWeapon(client, "weapon_upgradepack_explosive", 3);

		if(Backpack[client][7] > 0)
			GiveWeapon(client, "weapon_pain_pills", 4);
		else if(Backpack[client][8] > 0)
			GiveWeapon(client, "weapon_adrenaline", 4);
	}

	return Plugin_Continue;
}

//MEDSMUNCH FIX
public void eReviveSuccessPre(Event event, const char[] name, bool dontBroadcast)
{
	int recipient = GetClientOfUserId(event.GetInt("subject"));

	if(IsValidClient(recipient) && GetClientTeam(recipient) == 2)
	{
		int slot = GetPlayerWeaponSlot(recipient, 4);

		if(slot > -1)
			GetEntityClassname(slot, MedsMunch[recipient], sizeof(MedsMunch[]));
	}
}
	
public void eReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int recipient = GetClientOfUserId(event.GetInt("subject"));

	if(IsValidClient(recipient) && GetClientTeam(recipient) == 2)
		CreateTimer(0.5, GivePills, event.GetInt("subject"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action GivePills(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(IsValidClient(client) && GetClientTeam(client) == 2)
	{
		int slot = GetPlayerWeaponSlot(client, 4);

		if(slot == -1)
		{
			if(StrContains(MedsMunch[client], "pain_pills") > -1)
			{
				Backpack[client][7] -= 1;

				if(Backpack[client][7] > 0)
					GiveWeapon(client, "weapon_pain_pills", 4);
				else if(Backpack[client][8] > 0)
					GiveWeapon(client, "weapon_adrenaline", 4);
			}
			else if(StrContains(MedsMunch[client], "adrenaline") > -1)
			{
				Backpack[client][8] -= 1;

				if(Backpack[client][8] > 0)
					GiveWeapon(client, "weapon_adrenaline", 4);
				else if(Backpack[client][7] > 0)
					GiveWeapon(client, "weapon_pain_pills", 4);
			}

			MedsMunch[client][0] = '\0';
		}
	}

	return Plugin_Continue;
}
//MEDSMUNCH FIX

//PILLS PASS QUANTITIES FIX
public void eGiveWeapon(Event event, const char[] name, bool dontBroadcast)
{
	int giver = GetClientOfUserId(event.GetInt("giver"));
	int receiver = GetClientOfUserId(event.GetInt("userid"));

	char item[32];
	GetEventString(event, "weapon", item, sizeof(item));

	if(StrEqual(item, "15")) //PILLS ID
	{
		ItemUsed[giver][7] = 1;
		Backpack[giver][7] -= 1;
		Backpack[receiver][7] += 1;
	}
	else if(StrEqual(item, "23")) //ADRENALINE ID
	{
		ItemUsed[giver][8] = 1;
		Backpack[giver][8] -= 1;
		Backpack[receiver][8] += 1;
	}
	else
		return;

	RequestFrame(NextFrame, giver);
}
//PILLS PASS QUANTITIES FIX

void ResetBackpack(int client = 0)
{
	/*0 = ALL CLIENTS*/

	if(client != 0)
	{
		Backpack[client][0] = 0;
		Backpack[client][1] = 0;
		Backpack[client][2] = 0;
		Backpack[client][3] = 0;
		Backpack[client][4] = 0;
		Backpack[client][5] = 0;
		Backpack[client][6] = 0;
		Backpack[client][7] = 0;
		Backpack[client][8] = 0;

		ItemUsed[client][0] = 0;
		ItemUsed[client][1] = 0;
		ItemUsed[client][2] = 0;
		ItemUsed[client][3] = 0;
		ItemUsed[client][4] = 0;
		ItemUsed[client][5] = 0;
		ItemUsed[client][6] = 0;
		ItemUsed[client][7] = 0;
		ItemUsed[client][8] = 0;
	}
	else
	{
		for(int i = 0; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				Backpack[i][0] = 0;
				Backpack[i][1] = 0;
				Backpack[i][2] = 0;
				Backpack[i][3] = 0;
				Backpack[i][4] = 0;
				Backpack[i][5] = 0;
				Backpack[i][6] = 0;
				Backpack[i][7] = 0;
				Backpack[i][8] = 0;

				ItemUsed[i][0] = 0;
				ItemUsed[i][1] = 0;
				ItemUsed[i][2] = 0;
				ItemUsed[i][3] = 0;
				ItemUsed[i][4] = 0;
				ItemUsed[i][5] = 0;
				ItemUsed[i][6] = 0;
				ItemUsed[i][7] = 0;
				ItemUsed[i][8] = 0;
			}
		}
	}
}

stock void StartBackpack(int client)
{
	int slot;

	slot = GetPlayerWeaponSlot(client, 2);

	if(slot > -1)
		RemoveWeapon(client, 2);

	slot = GetPlayerWeaponSlot(client, 3);

	if(slot > -1)
		RemoveWeapon(client, 3);

	slot = GetPlayerWeaponSlot(client, 4);

	if(slot > -1)
		RemoveWeapon(client, 4);

	Backpack[client][0] = GetConVarInt(start_molotovs);
	Backpack[client][1] = GetConVarInt(start_pipebombs);
	Backpack[client][2] = GetConVarInt(start_vomitjars);
	Backpack[client][3] = GetConVarInt(start_kits);
	Backpack[client][4] = GetConVarInt(start_defibs);
	Backpack[client][5] = GetConVarInt(start_incendiary);
	Backpack[client][6] = GetConVarInt(start_explosive);
	Backpack[client][7] = GetConVarInt(start_pills);
	Backpack[client][8] = GetConVarInt(start_adrenalines);

	int userid = GetClientUserId(client);
	CreateTimer(1.0, FixBackpack, userid, TIMER_FLAG_NO_MAPCHANGE);
}

stock void SaveBackpack(int client = -1, bool all = false)
{
	if(all)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			Storage[i][0] = Backpack[i][0];
			Storage[i][1] = Backpack[i][1];
			Storage[i][2] = Backpack[i][2];
			Storage[i][3] = Backpack[i][3];
			Storage[i][4] = Backpack[i][4];
			Storage[i][5] = Backpack[i][5];
			Storage[i][6] = Backpack[i][6];
			Storage[i][7] = Backpack[i][7];
			Storage[i][8] = Backpack[i][8];
		}
	}
	else
	{
		Storage[client][0] = Backpack[client][0];
		Storage[client][1] = Backpack[client][1];
		Storage[client][2] = Backpack[client][2];
		Storage[client][3] = Backpack[client][3];
		Storage[client][4] = Backpack[client][4];
		Storage[client][5] = Backpack[client][5];
		Storage[client][6] = Backpack[client][6];
		Storage[client][7] = Backpack[client][7];
		Storage[client][8] = Backpack[client][8];
	}
}

stock void LoadBackpack(int client = -1, bool all = false)
{
	if(all)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			Backpack[i][0] = Storage[i][0];
			Backpack[i][1] = Storage[i][1];
			Backpack[i][2] = Storage[i][2];
			Backpack[i][3] = Storage[i][3];
			Backpack[i][4] = Storage[i][4];
			Backpack[i][5] = Storage[i][5];
			Backpack[i][6] = Storage[i][6];
			Backpack[i][7] = Storage[i][7];
			Backpack[i][8] = Storage[i][8];
		}
	}
	else
	{
		Backpack[client][0] = Storage[client][0];
		Backpack[client][1] = Storage[client][1];
		Backpack[client][2] = Storage[client][2];
		Backpack[client][3] = Storage[client][3];
		Backpack[client][4] = Storage[client][4];
		Backpack[client][5] = Storage[client][5];
		Backpack[client][6] = Storage[client][6];
		Backpack[client][7] = Storage[client][7];
		Backpack[client][8] = Storage[client][8];
	}
}

public void SpawnItem(const float origin[3], const char[] item, const int amount)
{
	int entity = -1;

	for(int i = 1; i <= amount; i++)
	{
		entity = CreateEntityByName(item);

		if(!IsValidEntity(entity) || !DispatchSpawn(entity))
			continue;

		ActivateEntity(entity);
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
	}
}

/////====================[ QUANTITY HINT ]====================/////
stock void DestroyHintEntity(int client)
{
	if(IsValidEntRef(HintIndex[client]))
	{
		AcceptEntityInput(HintIndex[client], "Kill");
		HintIndex[client] = -1;
	}
}

stock void CreateHintEntity(int client)
{
	if(IsValidEntRef(HintIndex[client]))
	{
		AcceptEntityInput(HintIndex[client], "Kill");
		HintIndex[client] = -1;
	}

	HintEntity[client] = CreateEntityByName("env_instructor_hint");

	if(HintEntity[client] < 0)
		return;

	DispatchSpawn(HintEntity[client]);

	HintIndex[client] = EntIndexToEntRef(HintEntity[client]);
}

stock void DisplayInstructorHint(int target, int iTimeout, float fHeight, float fRange, bool bFollow, bool bShowOffScreen, int flag, char[] sIconOnScreen, char[] sIconOffScreen, char[] sCmd, bool bShowTextAlways, int iColor[3], char sWeapon[32])
{
	if(!IsValidEntity(target))
		return;

	if(!IsValidEntity(HintEntity[target]))
		return;

	char sBuffer[32];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			if(i == target)
			{
				// Target
				FormatEx(sBuffer, sizeof(sBuffer), "quantity_%d", target);
				DispatchKeyValue(target, "targetname", sBuffer);
				DispatchKeyValue(HintEntity[target], "hint_target", sBuffer);

				// Fix for showing all clients
				//DispatchKeyValue(HintEntity[target], "hint_name", sBuffer);
				DispatchKeyValue(HintEntity[target], "hint_replace_key", sBuffer);

				// Other Options
				DispatchKeyValue(HintEntity[target], "hint_timeout", "2");
				DispatchKeyValue(HintEntity[target], "hint_instance_type", "2");
				DispatchKeyValue(HintEntity[target], "hint_display_limit", "0");
				DispatchKeyValue(HintEntity[target], "hint_suppress_rest", "1");
				DispatchKeyValue(HintEntity[target], "hint_auto_start", "false");
				DispatchKeyValue(HintEntity[target], "hint_local_player_only", "false"); //true
				DispatchKeyValue(HintEntity[target], "hint_allow_nodraw_target", "true");

				//FormatEx(sBuffer, sizeof(sBuffer), "%i", flag);
				//DispatchKeyValue(HintEntity[target], "hint_flags", sBuffer);		//EFFECTS THE ICON
				//DispatchKeyValue(HintEntity[target], "hint_pulseoption", "1"); 	//EFFECTS THE TEXT //Left To Right
				//DispatchKeyValue(HintEntity[target], "hint_alphaoption", "1"); 	//EFFECTS THE TEXT //Flash
				//DispatchKeyValue(HintEntity[target], "hint_shakeoption", "1"); 	//EFFECTS THE TEXT //Shake

				char Message[48];

				int aWeapon = GetEntPropEnt(i, Prop_Data, "m_hActiveWeapon");

				if(aWeapon > -1)
				{
					GetEntityClassname(aWeapon, sWeapon, sizeof(sWeapon));

					if(StrContains(sWeapon, "molotov") > -1)
					{
						if(Backpack[target][0] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][0]);
						else
							return;
					}
					else if(StrContains(sWeapon, "pipe_bomb") > -1)
					{
						if(Backpack[target][1] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][1]);
						else
							return;
					}
					else if(StrContains(sWeapon, "vomitjar") > -1)
					{
						if(Backpack[target][2] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][2]);
						else
							return;
					}
					else if(StrContains(sWeapon, "first_aid_kit") > -1)
					{
						if(Backpack[target][3] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][3]);
						else
							return;
					}
					else if(StrContains(sWeapon, "defibrillator") > -1)
					{
						if(Backpack[target][4] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][4]);
						else
							return;
					}
					else if(StrContains(sWeapon, "upgradepack_incendiary") > -1)
					{
						if(Backpack[target][5] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][5]);
						else
							return;
					}
					else if(StrContains(sWeapon, "upgradepack_explosive") > -1)
					{
						if(Backpack[target][6] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][6]);
						else
							return;
					}
					else if(StrContains(sWeapon, "pain_pills") > -1)
					{
						if(Backpack[target][7] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][7]);
						else
							return;
					}
					else if(StrContains(sWeapon, "adrenaline") > -1)
					{
						if(Backpack[target][8] > 1)
							Format(Message, sizeof(Message), "Qty( %d )", Backpack[target][8]);
						else
							return;
					}
					else
						return;

					DispatchKeyValue(HintEntity[target], "hint_caption", Message);
					DispatchKeyValue(HintEntity[target], "hint_activator_caption", Message);
					DispatchKeyValue(HintEntity[target], "hint_color", "100 100 255");

					AcceptEntityInput(HintEntity[target], "ShowHint", i);
				}
			}
		}
	}
}

void ShowQuantities(int client, char ClsName[32])
{
	if(GetConVarInt(ShowQuantity) == 4)
		DisplayInstructorHint(client, 1, 0.0, 0.0, true, false, 0, "", "", "", true, {25, 25, 255}, ClsName);
	else
	{
		char Message[48];

		int aWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

		if (aWeapon > -1)
		{
			char sWeapon[32];
			GetEntityClassname(aWeapon, sWeapon, sizeof(sWeapon));

			if (StrContains(sWeapon, "molotov") > -1)
			{
				if (Backpack[client][0] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][0]);
				else
					return;
			}
			else if (StrContains(sWeapon, "pipe_bomb") > -1)
			{
				if (Backpack[client][1] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][1]);
				else
					return;
			}
			else if (StrContains(sWeapon, "vomitjar") > -1)
			{
				if (Backpack[client][2] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][2]);
				else
					return;
			}
			else if (StrContains(sWeapon, "first_aid_kit") > -1)
			{
				if (Backpack[client][3] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][3]);
				else
					return;
			}
			else if (StrContains(sWeapon, "defibrillator") > -1)
			{
				if (Backpack[client][4] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][4]);
				else
					return;
			}
			else if (StrContains(sWeapon, "upgradepack_incendiary") > -1)
			{
				if (Backpack[client][5] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][5]);
				else
					return;
			}
			else if (StrContains(sWeapon, "upgradepack_explosive") > -1)
			{
				if (Backpack[client][6] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][6]);
				else
					return;
			}
			else if (StrContains(sWeapon, "pain_pills") > -1)
			{
				if (Backpack[client][7] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][7]);
				else
					return;
			}
			else if (StrContains(sWeapon, "adrenaline") > -1)
			{
				if (Backpack[client][8] > 1)
					Format(Message, sizeof(Message), "Qty( %d )", Backpack[client][8]);
				else
					return;
			}
			else
				return;

			if(GetConVarInt(ShowQuantity) == 1)
				PrintToChat(client, "%s", Message);
			else if(GetConVarInt(ShowQuantity) == 2)
				PrintHintText(client, "%s", Message);
			else if(GetConVarInt(ShowQuantity) == 3)
				PrintCenterText(client, "%s", Message);
		}
	}
}

/////====================[ STOCKS ]====================/////
stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsIncapped(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0);
}

stock bool IsOnGround(int client)
{
	if(GetEntityFlags(client) & FL_ONGROUND)
		return true;
	return false;
}

stock bool IsAdmin(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}

static bool IsValidEntRef(int iEntRef)
{
    static int iEntity;
    iEntity = EntRefToEntIndex(iEntRef);
    return (iEntRef && iEntity != INVALID_ENT_REFERENCE && IsValidEntity(iEntity));
}

stock void GetEntityAbsOrigin(int entity, float vec[3])
{
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);
}

stock bool IsTargetInSightRange(int client, int target, float angle = 90.0, float distance = 0.0, bool heightcheck = true, bool negativeangle = false)
{
	if(angle > 360.0 || angle < 0.0)
		return false;
		//ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);

	if(!IsValidClient(client) || !IsPlayerAlive(client) || !IsIncapped(client))
		return false;
		//ThrowError("Client Is Not Valid.");

	float resultangle;
	float resultdistance;

	float clientpos[3];
	float targetpos[3];
	float anglevector[3];
	float targetvector[3];

	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;

	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);

	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetEntityAbsOrigin(target, targetpos);

	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);

	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);

	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));

	if(resultangle <= angle/2)
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);

			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

stock char GetAnyClassname(int entity, int slot = -1)
{
	char sClsName[32];
	
	if(IsValidClient(entity))
	{
		int weapon;

		if(slot > -1 && slot < 5)
			weapon = GetPlayerWeaponSlot(entity, slot);
		else if(slot == 5)
			weapon = GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");
	
		if(weapon > -1)
			GetEntityClassname(weapon, sClsName, sizeof(sClsName));
	}
	else if(IsValidEntity(entity))
		GetEntityClassname(entity, sClsName, sizeof(sClsName));

	return sClsName;
}