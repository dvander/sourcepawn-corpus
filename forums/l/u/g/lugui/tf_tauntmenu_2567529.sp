#pragma semicolon 1

#include <sdktools>
#include <tf2items>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Taunt Menu",
	author = "FlaminSarge, Nighty, xCoderx",
	description = "Displays a nifty taunt menu.",
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
	
	RegAdminCmd("sm_taunt", Cmd_TauntMenu, ADMFLAG_GENERIC, "Taunt Menu");
	RegAdminCmd("sm_taunts", Cmd_TauntMenu, ADMFLAG_GENERIC, "Taunt Menu");
	CloseHandle(conf);
	LoadTranslations("common.phrases");
	CreateConVar("tf_tauntem_version", PLUGIN_VERSION, "[TF2] Taunt 'em Version", FCVAR_NOTIFY|FCVAR_PLUGIN);
}

public Action:Cmd_TauntMenu(client, args)
{
	if (CheckCommandAccess(client, "sm_taunt", ADMFLAG_GENERIC, false))
	{
		ShowMenu(client);
		return Plugin_Handled;
	}
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
			AddMenuItem(menu, "1117", "Battin' a Thousand");
			AddMenuItem(menu, "1119", "Deep Fried Desire");
			AddMenuItem(menu, "1168", "Carlton");
			AddMenuItem(menu, "30572", "The Boston Breakdance");
			AddMenuItem(menu, "30917", "The Trackman's Touchdown");
			AddMenuItem(menu, "30920", "The Bunnyhopper");
			AddMenuItem(menu, "30921", "Runner's Rhythm");
		}
		case TFClass_Soldier:
		{
			AddMenuItem(menu, "1113", "Fresh Brewed Victory");
			AddMenuItem(menu, "30673", "Soldier's Requiem");
			AddMenuItem(menu, "30761", "The Fubar Fanfare");
		}
		case TFClass_Pyro:
		{
			AddMenuItem(menu, "30876", "Headcase");
			AddMenuItem(menu, "1112", "Party Trick");
			AddMenuItem(menu, "30570", "Pool Party");
			AddMenuItem(menu, "30763", "The Balloonibouncer");
			AddMenuItem(menu, "30919", "The Skating Scorcher");
		}
		case TFClass_DemoMan:
		{
			AddMenuItem(menu, "1114", "Spent Well Spirits");
			AddMenuItem(menu, "1120", "Oblooterated");
			AddMenuItem(menu, "30671", "Bad Pipes");
			AddMenuItem(menu, "30840", "Scotsmann's Stagger");
			AddMenuItem(menu, "30840", "Scotsmann's Stagger");
		}
		case TFClass_Heavy:
		{
			AddMenuItem(menu, "30843", "Russian Arms Race");
			AddMenuItem(menu, "30844", "Soviet Strongarm");
			AddMenuItem(menu, "1174", "Table Tantrum");
			AddMenuItem(menu, "1175", "Boiling Point");
			AddMenuItem(menu, "30616", "Proletariat Posedown");
		}
		case TFClass_Engineer:
		{
			AddMenuItem(menu, "30842", "Dueling Banjo");
			AddMenuItem(menu, "30845", "Jumping Jack");
			AddMenuItem(menu, "1115", "Rancho Relaxo");
			AddMenuItem(menu, "30618", "Bucking Bronco");
		}
		case TFClass_Medic:
		{
			AddMenuItem(menu, "477", "Meet the Medic");
			AddMenuItem(menu, "1109", "Results Are In");
		}
		case TFClass_Sniper:
		{
			AddMenuItem(menu, "1116", "I See You");
			AddMenuItem(menu, "30609", "The Killer Solo");
			AddMenuItem(menu, "30614", "Most Wanted");
			AddMenuItem(menu, "30839", "Didgeridrongo");
		}
		case TFClass_Spy:
		{
			AddMenuItem(menu, "1108", "Buy A Life");
			AddMenuItem(menu, "30615", "Box Trot");
			AddMenuItem(menu, "30762", "Disco Fever");
			AddMenuItem(menu, "30922", "Luxury Lounge");
		}
	}
	AddMenuItem(menu, "1182", "Yeti Punch");
	AddMenuItem(menu, "1183", "Yeti Smash");
	AddMenuItem(menu, "167", "High Five!");
	AddMenuItem(menu, "438", "Director's Vision");
	AddMenuItem(menu, "463", "Schadenfreude");
	AddMenuItem(menu, "1015", "Shred Alert");
	AddMenuItem(menu, "1106", "Square Dance");
	AddMenuItem(menu, "1107", "Flippin' Awesome");
	AddMenuItem(menu, "1110", "Rock, Paper, Scissors");
	AddMenuItem(menu, "1111", "Skullcracker");
	AddMenuItem(menu, "1118", "Conga");
	AddMenuItem(menu, "1157", "Kazotsky Kick");
	AddMenuItem(menu, "1162", "Mannrobics");
	AddMenuItem(menu, "1172", "Victory Lap");
	AddMenuItem(menu, "30621", "Burtchester");
	AddMenuItem(menu, "30672", "Zoomin' Broom");
	AddMenuItem(menu, "30816", "Second Rate Sourcery");
	
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