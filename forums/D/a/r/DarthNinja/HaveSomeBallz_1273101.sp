#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
    name = "[TF2] Have Some Ballz",
    author = "DarthNinja",
    description = "You're gonna love my ballz!",
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
		LogMessage("Ballsballsballsballsballsballsballsballsballsballs.");
	}
	else
	{
		SetFailState("Team Fortress 2 Only.");
	}
	//Don't need no cvars hea!
	CreateConVar("sm_bawlz_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	RegAdminCmd("sm_giveballs", Cmd_Bawlz, ADMFLAG_BAN);
	
	LoadTranslations("common.phrases");
}

public Action:Cmd_Bawlz(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "Usage: sm_giveballs <target> <number>");
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
	new String:ballz[64];
	GetCmdArg(2,ballz,sizeof(ballz));
	
	for (new i = 0; i < target_count; i ++)
	{
		new TFClassType:playerClass = TF2_GetPlayerClass(target_list[i]);
		if(playerClass == TFClass_Scout)
		{
			SetGrenadeAmmo(target_list[i], StringToInt(ballz));
			ShowActivity2(client, "[SM] ","Gave %N some ballz!", target_list[i]);
			PrintToChat(target_list[i], "An admin gave you some ballz!");
			LogAction(client, target_list[i], "[BALLS] %L gave %L %i balls!", client, target_list[i], StringToInt(ballz));
		}
	}
	
	return Plugin_Handled;
}

stock SetGrenadeAmmo(client, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, 2);
	if (IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 44)
		{    
			new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
		}
	}
}