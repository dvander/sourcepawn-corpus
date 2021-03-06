/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#define FL_PISTOL_PRIMARY (1<<6) //Is 1 when you have a primary weapon and dual pistols
#define FL_PISTOL (1<<7) //Is 1 when you have dual pistols
public Plugin:myinfo = 
{
	name = "L4D Drop Weapon",
	author = "Frustian",
	description = "Allows players to drop the weapon they are holding, or another weapon they have",
	version = "1.1",
	url = ""
}
new Handle:g_hSpecify;
public OnPluginStart()
{
	CreateConVar("l4d_drop_version", "1.1", "Drop Weapon Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hSpecify = CreateConVar("l4d_drop_specify", "1", "Allow people to drop weapons they have, but are not using",FCVAR_PLUGIN|FCVAR_SPONLY);
	RegConsoleCmd("sm_drop", Command_Drop);
}
public Action:Command_Drop(client, args)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return Plugin_Handled;
	new String:weapon[32];
	if (args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_drop [weapon]");
		return Plugin_Handled;
	}
	if (args == 1)
	{
		if (GetConVarInt(g_hSpecify))
		{
			GetCmdArg(1, weapon, 32);
			if ((StrContains(weapon, "pump") != -1 || StrContains(weapon, "auto") != -1 || StrContains(weapon, "shot") != -1 || StrContains(weapon, "rifle") != -1 || StrContains(weapon, "smg") != -1 || StrContains(weapon, "uzi") != -1 || StrContains(weapon, "m16") != -1 || StrContains(weapon, "hunt") != -1) && GetPlayerWeaponSlot(client, 0) != -1)
				DropSlot(client, 0);
			else if ((StrContains(weapon, "pistol") != -1) && GetPlayerWeaponSlot(client, 1) != -1)
				DropSlot(client, 1);
			else if ((StrContains(weapon, "pipe") != -1 || StrContains(weapon, "mol") != -1) && GetPlayerWeaponSlot(client, 2) != -1)
				DropSlot(client, 2);
			else if ((StrContains(weapon, "kit") != -1 || StrContains(weapon, "pack") != -1 || StrContains(weapon, "med") != -1) && GetPlayerWeaponSlot(client, 3) != -1)
				DropSlot(client, 3);
			else if ((StrContains(weapon, "pill") != -1) && GetPlayerWeaponSlot(client, 4) != -1)
				DropSlot(client, 4);
			else
				ReplyToCommand(client, "[SM] You do not have a %s!", weapon);
		}
		else
			ReplyToCommand(client, "[SM] This server's settings do not allow you to drop a specific weapon.  Use sm_drop(/drop in chat) without a weapon name after it to drop the weapon you are holding.");
		return Plugin_Handled;
	}
	GetClientWeapon(client, weapon, 32);
	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle"))
		DropSlot(client, 0);
	else if (StrEqual(weapon, "weapon_pistol"))
		DropSlot(client, 1);
	else if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov"))
		DropSlot(client, 2);
	else if (StrEqual(weapon, "weapon_first_aid_kit"))
		DropSlot(client, 3);
	else if (StrEqual(weapon, "weapon_pain_pills"))
		DropSlot(client, 4);
	return Plugin_Handled;
}
public DropSlot(client, slot)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		new String:sWeapon[32];
		new ammo;
		new clip;
		new ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), sWeapon, 32);
		if (slot == 0)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1")
			if (StrEqual(sWeapon, "weapon_pumpshotgun") || StrEqual(sWeapon, "weapon_autoshotgun"))
			{
				ammo = GetEntData(client, ammoOffset+(6*4));
				SetEntData(client, ammoOffset+(6*4), 0);
			}
			else if (StrEqual(sWeapon, "weapon_smg"))
			{
				ammo = GetEntData(client, ammoOffset+(5*4));
				SetEntData(client, ammoOffset+(5*4), 0);
			}
			else if (StrEqual(sWeapon, "weapon_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(3*4));
				SetEntData(client, ammoOffset+(3*4), 0);
			}
			else if (StrEqual(sWeapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(2*4));
				SetEntData(client, ammoOffset+(2*4), 0);
			}
		}
		if (slot == 1)
		{
			if ((GetEntProp(client, Prop_Send, "m_iAddonBits") & (FL_PISTOL|FL_PISTOL_PRIMARY)) > 0)
			{
				clip = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1")
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
				SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
				FakeClientCommand(client, "give pistol", sWeapon);
				SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
				if (clip < 15)
					SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1", 0);
				else
					SetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1", clip-15);
				new index = CreateEntityByName(sWeapon);
				new Float:cllocation[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", cllocation);
				cllocation[2]+=20;
				TeleportEntity(index,cllocation, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(index);
				ActivateEntity(index);
			}
			else
				ReplyToCommand(client, "[SM] You can't drop your only pistol!");
			return;
		}
		new index = CreateEntityByName(sWeapon);
		new Float:cllocation[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", cllocation);
		cllocation[2]+=20;
		TeleportEntity(index,cllocation, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(index);
		ActivateEntity(index);
		RemovePlayerItem(client, GetPlayerWeaponSlot(client, slot));
		if (slot == 0)
		{
			SetEntProp(index, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
			SetEntProp(index, Prop_Send, "m_iClip1", clip);
		}
		
	}
}