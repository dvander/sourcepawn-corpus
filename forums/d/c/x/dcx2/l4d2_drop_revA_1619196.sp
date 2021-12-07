#define PLUGIN_VERSION "1.3.0revA"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "L4D2 Weapon Drop",
	author = "Machine (targeting added by dcx2)",
	description = "Allows players to drop the weapon they are holding, and admins with root to target players to drop any weapon",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");		// Needed for ProcessTargetString

	RegConsoleCmd("sm_drop", Command_Drop);
	RegConsoleCmd("sm_dropslot", Command_DropSlot, "sm_dropslot <slot> [<client>]; force <client> (optional, default self) to drop item in <slot>");
	CreateConVar("sm_drop_version", PLUGIN_VERSION, "L4D2 Weapon Drop Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

// returns target_count, modifies target_list
public GetTargets(client, const String:target[], target_list[], Filter)
{
	decl String:target_name[MAX_TARGET_LENGTH];
	new bool:tn_is_ml;
	 
	return ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				Filter,
				target_name,
				sizeof(target_name),
				tn_is_ml);
}

public Action:Command_Drop(client, args)
{
	if (client == 0 || !IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))	return Plugin_Handled;

	decl String:arg1[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS+1];
	new target_count;
	
	// Assume self
	target_count = 1;
	target_list[0] = client;

	// Is there a target argument?
	// Does the client have the root flag?
	// Is the target_count >= 0?
	if (args > 0 && GetAdminFlag(GetUserAdmin(client), Admin_Root) && GetCmdArg(1, arg1, sizeof(arg1)) && (target_count = GetTargets(client, arg1, target_list, COMMAND_FILTER_ALIVE)) <= 0)
	{
		return Plugin_Handled;	// Could not find target
	}

	decl String:weapon[32];
	new slot;
	for (new i = 0; i < target_count; i++)
	{
		GetClientWeapon(target_list[i], weapon, sizeof(weapon));
		
		slot = -1;

		if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
			slot = 0;
		else if (StrEqual(weapon, "weapon_pistol") || StrEqual(weapon, "weapon_pistol_magnum") || StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_melee"))
			slot = 1;
		else if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov") || StrEqual(weapon, "weapon_vomitjar"))
			slot = 2;
		else if (StrEqual(weapon, "weapon_first_aid_kit") || StrEqual(weapon, "weapon_defibrillator") || StrEqual(weapon, "weapon_upgradepack_explosive") || StrEqual(weapon, "weapon_upgradepack_incendiary"))
			slot = 3;
		else if (StrEqual(weapon, "weapon_pain_pills") || StrEqual(weapon, "weapon_adrenaline"))
			slot = 4;

		if (slot >= 0)
		{
			DropSlot(target_list[i], slot);
		}
		
	}

	return Plugin_Handled;
}

public Action:Command_DropSlot(client, args)
{
	if (client == 0 || !IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Handled;

	new String:arg1[3];
	new slotNum;
	if (args > 0 && GetCmdArg(1, arg1, sizeof(arg1)))
	{
		slotNum = StringToInt(arg1) - 1;	// client counts slots from 1, server counts from 0
		
		decl String:arg2[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS+1];
		new target_count;
		
		// Assume self
		target_count = 1;
		target_list[0] = client;

		// Is there a target argument?
		// Does the client have the root flag?
		// Is the target_count >= 0?
		if (args > 1 && GetAdminFlag(GetUserAdmin(client), Admin_Root) && GetCmdArg(2, arg2, sizeof(arg2)) && (target_count = GetTargets(client, arg2, target_list, COMMAND_FILTER_ALIVE)) <= 0)
		{
			return Plugin_Handled;	// Could not find target
		}

		for (new i = 0; i < target_count; i++)
		{
			DropSlot(target_list[i], slotNum);
		}
	}
	else
	{
		ReplyToCommand(client, "sm_dropslot requires at least one argument, 1=primary, 2=secondary, 3=grenade, 4=kit, 5=temp health");
		ReplyToCommand(client, "sm_dropslot <slot> [<client>]; force <client> (optional, default self, requires root flag) to drop item in <slot>");
		
	}

	return Plugin_Handled;
}

public DropSlot(client, slot)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		new weapon = GetPlayerWeaponSlot(client, slot);

		// DropWeapon uses a relatively high velocity...
		SDKHooks_DropWeapon(client, weapon);

		// ...and it also appears to ignore the velocity argument
		// So let's use a smaller, random one with TeleportEntity
		// this "random velocity" idea taken from Thraka's Infected Loot Drops
		decl Float:vel[3];
		vel[0] = GetRandomFloat(-80.0, 80.0);
		vel[1] = GetRandomFloat(-80.0, 80.0);
		vel[2] = GetRandomFloat(40.0, 80.0);
		TeleportEntity(weapon, NULL_VECTOR, NULL_VECTOR, vel);
	}
}