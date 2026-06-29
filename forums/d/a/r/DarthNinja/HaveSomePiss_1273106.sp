#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
    name = "[TF2] Have Some Piss",
    author = "DarthNinja",
    description = "You're gonna love my.... Piss?",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
};

 
public OnPluginStart()
{
	/* Check Game */
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if(StrEqual(game, "tf"))
	{
		LogMessage("God save the piss!");
	}
	else
	{
		SetFailState("Team Fortress 2 Only.");
	}
	//Don't need no cvars hea!
	CreateConVar("sm_piss_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	RegAdminCmd("sm_givepiss", Cmd_Piss, ADMFLAG_BAN);
	
	LoadTranslations("common.phrases");
}

public Action:Cmd_Piss(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_givepiss <target> <number>");
		return Plugin_Handled;
	}
	
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	
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
	new String:piss[64];
	GetCmdArg(2,piss,sizeof(piss));
	
	for (new i = 0; i < target_count; i ++)
	{
		new TFClassType:playerClass = TF2_GetPlayerClass(target_list[i]);
		if(playerClass == TFClass_Sniper)
		{
			SetJarAmmo(target_list[i], StringToInt(piss));
			ShowActivity2(client, "[SM] ","Gave %N some piss!", target_list[i]);
			PrintToChat(target_list[i], "An admin gave you some piss!");
			LogAction(client, target_list[i], "[PISS] %L gave %L %i piss!", client, target_list[i], StringToInt(piss));
		}
	}
	
	return Plugin_Handled;
}
stock SetJarAmmo(client, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 58)
		{    
			new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
		}
	}
}