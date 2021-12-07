#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Handle:g_hGiveAmmo;

public OnPluginStart()
{
	new Handle:hGameConf = LoadGameConfigFile("giveammo");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Can't find giveammo.txt gamedata.");
	
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GiveAmmo"))
		SetFailState("Can't find CBaseCombatCharacter::GiveAmmo(int, int, bool) offset.");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hGiveAmmo = EndPrepSDKCall();
	
	CloseHandle(hGameConf);
	
	RegConsoleCmd("sm_giveammo", Cmd_GiveAmmo);
}

public Action:Cmd_GiveAmmo(client, args)
{
	if(!client)
		return Plugin_Handled;
	
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(iWeapon < 1)
	{
		ReplyToCommand(client, "No active weapon.");
		return Plugin_Handled;
	}
	
	new ammoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	
	if(ammoType < 0)
	{
		ReplyToCommand(client, "This weapon has no ammo.");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "Ammotype: %d", ammoType);
	
	/**
	 * GiveAmmo gives ammo of a certain type to a player - duh.
	 *
	 * @param client		The client index.
	 * @param ammo			Amount of bullets to give. Is capped at weapon's limit.
	 * @param ammotype		Type of ammo to give to player.
	 * @param suppressSound Don't play the ammo pickup sound.
	 * 
	 * @return Amount of bullets actually given.
	 */
	new ret = SDKCall(g_hGiveAmmo, client, 30, ammoType, true);
	
	ReplyToCommand(client, "Gave you 30 ammo in your current weapon. (%d)", ret);
	return Plugin_Handled;
}
