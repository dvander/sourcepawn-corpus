#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.1.0"

new Handle:v_TextEnabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Set Ammo",
	author = "DarthNinja",
	description = "Set weapons' ammo",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_setammo_version", PLUGIN_VERSION, "Set Ammo Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	RegAdminCmd("sm_setammo", CommandSetAmmo, ADMFLAG_ROOT, "sm_setammo <Player> <Slot> <Offhand Ammo>");
	RegAdminCmd("sm_setclip", CommandSetClip, ADMFLAG_ROOT, "sm_setclip <Player> <Slot> <Ammo>");
	v_TextEnabled = CreateConVar("sm_setammo_showtext", "1", "Enable/Disable Text <1/0>", 0, true, 0.0, true, 1.0);
	//HookEvent("post_inventory_application", ReapplyAmmo);
}


public Action:CommandSetAmmo(client, args)
{
	if (args != 3)
	{
		ReplyToCommand(client, "Usage: sm_setammo <Player> <Slot> <Ammo>");
		return Plugin_Handled;
	}
	
	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));
	
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	//Get weapon slot
	GetCmdArg(2, buffer, sizeof(buffer));
	new Slot = StringToInt(buffer);
	Slot--
	
	//Get ammo
	GetCmdArg(3, buffer, sizeof(buffer));
	new Ammo = StringToInt(buffer);
	
	if (GetConVarBool(v_TextEnabled))
	{
		ShowActivity2(client, "\x04[\x03SetAmmo\x04] "," \x01gave \x05%s \x04%i\x01 offhand ammo for the weapon in slot \x04%i\x01!", target_name, Ammo, Slot+1);
	}
	for (new i = 0; i < target_count; i ++)
	{	
		SetAmmo(target_list[i], Slot, Ammo, client)
	}
	
	return Plugin_Handled;
}


public Action:CommandSetClip(client, args)
{
	if (args != 3)
	{
		ReplyToCommand(client, "Usage: sm_setclip <Player> <Slot> <Ammo>");
		return Plugin_Handled;
	}
	
	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));
	
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	//Get weapon slot
	GetCmdArg(2, buffer, sizeof(buffer));
	new Slot = StringToInt(buffer);
	Slot--
	
	//Get ammo
	GetCmdArg(3, buffer, sizeof(buffer));
	new Ammo = StringToInt(buffer);
	
	if (GetConVarBool(v_TextEnabled))
	{
		ShowActivity2(client, "\x04[\x03SetAmmo\x04] "," \x01gave \x05%s\x01 a clip size of \x04%i\x01 in weapon slot \x04%i\x01!", target_name, Ammo, Slot+1);
	}
	for (new i = 0; i < target_count; i ++)
	{	
		SetClip(target_list[i], Slot, Ammo, client)
	}
	
	return Plugin_Handled;
}

stock SetClip(client, wepslot, newAmmo, admin)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon))
	{
		ReplyToCommand(admin, "\x04[\x03SetAmmo\x04]:\x01 Invalid weapon slot")
	}
	if (IsValidEntity(weapon))
	{
		new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
		SetEntData(weapon, iAmmoTable, newAmmo, 4, true);
	}
}


stock SetAmmo(client, wepslot, newAmmo, admin)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon))
	{
		ReplyToCommand(admin, "\x04[\x03SetAmmo\x04]:\x01 Invalid weapon slot")
	}
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}