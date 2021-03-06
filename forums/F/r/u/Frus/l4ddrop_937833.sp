/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#define FL_PISTOL_PRIMARY (1<<6) //Is 1 when you have a primary weapon and dual pistols
#define FL_PISTOL (1<<7) //Is 1 when you have dual pistols
public Plugin:myinfo = 
{
	name = "DropWeapons",
	author = "Frustian",
	description = "Allows clients to drop the weapon they are holding",
	version = "0.0.1",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_drop", Command_Drop);
}
public Action:Command_Drop(client, args)
{
	new String:weapon[32];
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
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
				SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
				FakeClientCommand(client, "give pistol", sWeapon);
				SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
				new index = CreateEntityByName(sWeapon);
				new Float:cllocation[3];
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", cllocation);
				cllocation[2]+=20;
				TeleportEntity(index,cllocation, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(index);
				ActivateEntity(index);
			}
			else
				ReplyToCommand(client, "You can't drop your only pistol!");
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