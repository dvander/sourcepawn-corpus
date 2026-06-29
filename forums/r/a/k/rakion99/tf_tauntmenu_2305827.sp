#pragma semicolon 1

#include <sdktools>
#include <tf2items>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.02mod"

public Plugin:myinfo =
{
	name = "[TF2] Taunt Menu",
	author = "FlaminSarge, Nighty, xCoderx, Edited by Crow",
	description = "Displays a taunt menu.",
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
	
	RegConsoleCmd("sm_taunt", Cmd_TauntMenu, "Taunt Menu");
	RegConsoleCmd("sm_taunts", Cmd_TauntMenu, "Taunt Menu");
	
	CloseHandle(conf);
	LoadTranslations("common.phrases");
	CreateConVar("tf_tauntem_version", PLUGIN_VERSION, "[TF2] Taunt 'em Version", FCVAR_NOTIFY|FCVAR_PLUGIN);
}

public Action:Cmd_TauntMenu(client, args)
{

	ShowMenu(client);
	
	return Plugin_Handled;
}

public Action:ShowMenu(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new Handle:menu = CreateMenu(Tauntme_MenuSelected);
	SetMenuTitle(menu, "Taunts:");
	
	switch(class)
	{
		case TFClass_Scout:
		{
			AddMenuItem(menu, "1117", "(Scout) Battin' a Thousand Taunt");
			AddMenuItem(menu, "1119", "(Scout) Deep Fried Desire Taunt");
            AddMenuItem(menu, "30572", "(Scout) Boston Breakdance");
		}
		case TFClass_Sniper:
		{
			AddMenuItem(menu, "1116", "(Sniper) I See You Taunt");
            AddMenuItem(menu, "30609", "(Sniper) Killer Solo");
            AddMenuItem(menu, "30614", "(Sniper) Most Wanted");
		}
		case TFClass_Soldier:
		{
			AddMenuItem(menu, "1113", "(Soldier) Fresh Brewed Victory Taunt");
		}
		case TFClass_DemoMan:
		{
			AddMenuItem(menu, "1114", "(Demo) Spent Well Spirits Taunt");
			AddMenuItem(menu, "1120", "(Demo) Oblooterated Taunt");
		}
		case TFClass_Medic:
		{
			AddMenuItem(menu, "477", "(Medic) Meet the Medic Heroic Taunt");
			AddMenuItem(menu, "1109", "(Medic) Results Are In Taunt");
		}
		
		case TFClass_Pyro:
		{
			AddMenuItem(menu, "1112", "(Pyro) Party Trick Taunt");
            AddMenuItem(menu, "30570", "(Pyro) Pool Party Taunt");
		}
		case TFClass_Spy:
		{
			AddMenuItem(menu, "1108", "(Spy) Buy A Life Taunt");
		}
		case TFClass_Engineer:
		{
			AddMenuItem(menu, "1115", "(Engi) Rancho Relaxo Taunt");
		}
	}
	
	AddMenuItem(menu, "167", "(Any) High Five Taunt");
	AddMenuItem(menu, "438", "(Any) Replay Taunt");
	AddMenuItem(menu, "463", "(Any) Laugh Taunt");
	AddMenuItem(menu, "1015", "(Any) Shred Alert Taunt");
	AddMenuItem(menu, "1106", "(Any) Square Dance Taunt");
	AddMenuItem(menu, "1107", "(Any) Flippin' Awesome Taunt");
	AddMenuItem(menu, "1110", "(Any) RPS Taunt");
	AddMenuItem(menu, "1111", "(Any) Skullcracker Taunt");
	AddMenuItem(menu, "1118", "(Any) Conga Taunt");
	
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
		ExecuteTaunt(iClient, StringToInt(info));
	}
}

ExecuteTaunt(client, itemdef)
{
	static Handle:hItem;
	hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
	
	TF2Items_SetClassname(hItem, "tf_wearable_vm");
	TF2Items_SetQuality(hItem, 6);
	TF2Items_SetLevel(hItem, 1);
	TF2Items_SetNumAttributes(hItem, 0);
	TF2Items_SetItemIndex(hItem, itemdef);
	
	new ent = TF2Items_GiveNamedItem(client, hItem);
	new Address:pEconItemView = GetEntityAddress(ent) + Address:FindSendPropInfo("CTFWearable", "m_Item");
	
	SDKCall(hPlayTaunt, client, pEconItemView) ? 1 : 0;
	AcceptEntityInput(ent, "Kill");
}