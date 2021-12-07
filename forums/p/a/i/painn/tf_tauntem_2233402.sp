#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2items>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0.3"

public Plugin:myinfo =
{
	name = "[TF2] Taunt 'em",
	author = "FlaminSarge edited by Xven",
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
	RegConsoleCmd("sm_taunt", Cmd_Taunt, "Taunt menu");
	RegConsoleCmd("sm_taunts", Cmd_Taunt, "Taunt menu");
	RegConsoleCmd("sm_tauntme", Cmd_Tauntme, "sm_tauntme");
	RegAdminCmd("sm_tauntem", Cmd_Tauntem, ADMFLAG_CHEATS);
	RegConsoleCmd("sm_tauntem_list", Cmd_Tauntem_List);
}
public Action:Cmd_Tauntme(client, args)
{
	decl String:arg1[32];
	new itemdef;
	if (hPlayTaunt == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] Couldn't find call CTFPlayer::PlayTauntSceneFromItem... what are you even doing here?");
		return Plugin_Handled;
	}
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_tauntem <tauntid>");
		return Plugin_Handled;
	}	
	GetCmdArg(1, arg1, sizeof(arg1));
	itemdef = StringToInt(arg1);
	new ent = MakeCEIVEnt(client, itemdef);
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
	successcount += SDKCall(hPlayTaunt, client, pEconItemView) ? 1 : 0;
	AcceptEntityInput(ent, "Kill");
	if (successcount == 1)
		ReplyToCommand(client, "[SM] Taunt used Successfully");
	else
		ReplyToCommand(client, "[SM] Taunt failed (available Tauntid? wrong class? alive?)");
	return Plugin_Handled;
}
public Action:Cmd_Taunt(client, args)
{
	Tauntme_Menu(client);
	
	return Plugin_Handled;
}
public Action:Tauntme_Menu(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new Handle:menu = CreateMenu(Tauntme_MenuSelected);
	SetMenuTitle(menu, "Taunts:");
	switch(class)
	{
		case TFClass_Scout:
		{
			AddMenuItem(menu, "1117", "(Scout)Battin' a Thousand Taunt");
			AddMenuItem(menu, "1119", "(Scout)Deep Fried Desire Taunt");
		}
		case TFClass_Sniper:
		{
			AddMenuItem(menu, "1116", "(Sniper)I See You Taunt");
		}
		case TFClass_Soldier:
		{
			AddMenuItem(menu, "1113", "(Soldier)Fresh Brewed Victory Taunt");
		}
		case TFClass_DemoMan:
		{
			AddMenuItem(menu, "1114", "(Demo)Spent Well Spirits Taunt");
			AddMenuItem(menu, "1120", "(Demo)Oblooterated Taunt");
		}
		case TFClass_Medic:
		{
			AddMenuItem(menu, "477", "(Medic)Meet the Medic Heroic Taunt");
			AddMenuItem(menu, "1109", "(Medic)Results Are In Taunt");
		}
//		case TFClass_Heavy:
//		{
//			ლ(ಠ_ಠლ) Y U NO HAVE HEAVY?
//		}
		case TFClass_Pyro:
		{
			AddMenuItem(menu, "30570", "(Pyro)Taunt Pool");
			AddMenuItem(menu, "1112", "(Pyro)Party Trick Taunt");
		}
		case TFClass_Spy:
		{
			AddMenuItem(menu, "1108", "(Spy)Buy A Life Taunt");
		}
		case TFClass_Engineer:
		{
			AddMenuItem(menu, "1115", "(Engi)Rancho Relaxo Taunt");
		}
	}
	AddMenuItem(menu, "167", "(Any)High Five Taunt");
	AddMenuItem(menu, "438", "(Any)Replay Taunt");
	AddMenuItem(menu, "463", "(Any)Laugh Taunt");
	AddMenuItem(menu, "1015", "(Any)Shred Alert Taunt");
	AddMenuItem(menu, "1106", "(Any)Square Dance Taunt");
	AddMenuItem(menu, "1107", "(Any)Flippin' Awesome Taunt");
	AddMenuItem(menu, "1110", "(Any)RPS Taunt");
	AddMenuItem(menu, "1111", "(Any)Skullcracker Taunt");
	AddMenuItem(menu, "1118", "(Any)Conga Taunt");
	
	DisplayMenu(menu, client, 20);
}
public Tauntme_MenuSelected(Handle:menu, MenuAction:action, iClient, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}

	if(action == MenuAction_Select)
	{
		decl String:info[12];
		GetMenuItem(menu, param2, info, sizeof(info));
		new iClientID = GetClientUserId(iClient);
		ServerCommand("sm_tauntem #%i %s", iClientID, info);
	}
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
	PrintToConsole(client, "-1015: Shred Alert Taunt");
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
//	if (tn_is_ml)
//		ReplyToCommand(client, "[SM] Succeeded at forcing %d of %d targets (%t) to use taunt %d", successcount, target_count, target_name, itemdef);
//	else
//		ReplyToCommand(client, "[SM] Succeeded at forcing %d of %d targets (%s) to use taunt %d", successcount, target_count, target_name, itemdef);
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