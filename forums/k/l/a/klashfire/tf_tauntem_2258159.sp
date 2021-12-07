#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2items>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "[TF2] Taunt 'em",
	author = "FlaminSarge",
	description = "Force special taunts on players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=242866"
};

new Handle:hPlayTaunt;
public OnPluginStart()
{
	new Handle:conf = LoadGameConfigFile("tf2.tauntem");
	if (conf == INVALID_HANDLE)
	{
		SetFailState("Unable to load gamedata/tf2.tauntem.txt. Good luck figuring that out.");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPlayTaunt = EndPrepSDKCall();
	if (hPlayTaunt == INVALID_HANDLE)
	{
		SetFailState("Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Wait patiently for a fix.");
		CloseHandle(conf);
		return;
	}
	CloseHandle(conf);
	CreateConVar("tf_tauntem_version", PLUGIN_VERSION, "[TF2] Taunt 'em Version", FCVAR_NOTIFY|FCVAR_PLUGIN);
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_tauntem", Cmd_Tauntem, ADMFLAG_CHEATS);
	RegConsoleCmd("sm_tauntem_list", Cmd_Tauntem_List);
}
public Action:Cmd_Tauntem_List(client, args)
{
	if (!CheckCommandAccess(client, "sm_tauntem", ADMFLAG_CHEATS))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	PrintToConsole(client, "- 167: High Five Taunt");
	PrintToConsole(client, "- 438: Replay Taunt");
	PrintToConsole(client, "- 463: Laugh Taunt");
	PrintToConsole(client, "- 477: Meet the Medic Heroic Taunt");
	PrintToConsole(client, "-1106: Square Dance Taunt");
	PrintToConsole(client, "-1107: Flippin' Awesome Taunt");
	PrintToConsole(client, "-1108: Buy A Life Taunt");
	PrintToConsole(client, "-1109: Results Are In Taunt");
	PrintToConsole(client, "-1110: RPS Taunt");
	PrintToConsole(client, "-1111: Skullcracker Taunt");
	PrintToConsole(client, "-1112: Party Trick Taunt");
	PrintToConsole(client, "-1113: Fresh Brewed Victory Taunt");
	PrintToConsole(client, "-1114: Spent Well Spirits Taunt");
	PrintToConsole(client, "-1115: Rancho Relaxo Taunt");
	PrintToConsole(client, "-1116: I See You Taunt");
	PrintToConsole(client, "-1117: Battin' a Thousand Taunt");
	PrintToConsole(client, "-1118: Conga Taunt");
	PrintToConsole(client, "-1119: Deep Fried Desire Taunt");
	PrintToConsole(client, "-1120: Oblooterated Taunt");
	PrintToConsole(client, "-30570: Pool Party Taunt");
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
	{
		ReplyToCommand(client, "[SM] %t", "See console for output");
	}
	return Plugin_Handled;
}
public Action:Cmd_Tauntem(client, args)
{
	decl String:arg1[32];
	new itemdef;
	if (hPlayTaunt == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] Couldn't find call CTFPlayer::PlayTauntSceneFromItem... what are you even doing here?");
		return Plugin_Handled;
	}
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_tauntem <target> <tauntid>");
		return Plugin_Handled;
	}
	//if (args > 0)
	//{
	//	if (args > 1)
	//	{	
	GetCmdArg(2, arg1, sizeof(arg1));
	itemdef = StringToInt(arg1);
	//	}
	GetCmdArg(1, arg1, sizeof(arg1));
	//}
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(StrEqual(arg1, "@me") ? COMMAND_FILTER_NO_IMMUNITY : 0),	/* alive, and allow people to target themselves regardless */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new dummytarget = target_list[0];
	new ent = MakeCEIVEnt(dummytarget, itemdef);
	if (!IsValidEntity(ent))
	{
		ReplyToCommand(client, "[SM] Couldn't create entity for taunt");
		return Plugin_Handled;
	}
	new Address:pEconItemView = GetEntityAddress(ent) + Address:FindSendPropInfo("CTFWearable", "m_Item");
	if (pEconItemView <= Address_MinimumValid)
	{
		ReplyToCommand(client, "[SM] Couldn't find CEconItemView for taunt");
		return Plugin_Handled;
	}
	new successcount = 0;
	for (new i = 0; i < target_count; i++)
	{
		successcount += SDKCall(hPlayTaunt, target_list[i], pEconItemView) ? 1 : 0;
	}
	AcceptEntityInput(ent, "Kill");
	if (tn_is_ml)
		ReplyToCommand(client, "", successcount, target_count, target_name, itemdef);
	else
		ReplyToCommand(client, "", successcount, target_count, target_name, itemdef);
	return Plugin_Handled;
}
stock MakeCEIVEnt(client, itemdef)
{
	static Handle:hItem;
	if (hItem == INVALID_HANDLE)
	{
		hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
		TF2Items_SetClassname(hItem, "tf_wearable_vm");
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetLevel(hItem, 1);
		TF2Items_SetNumAttributes(hItem, 0);
	}
	TF2Items_SetItemIndex(hItem, itemdef);
	return TF2Items_GiveNamedItem(client, hItem);
}