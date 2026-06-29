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
	
	RegAdminCmd("sm_taunt", Cmd_TauntMenu, ADMFLAG_CUSTOM6, "Taunt Menu");
	RegAdminCmd("sm_taunts", Cmd_TauntMenu, ADMFLAG_CUSTOM6, "Taunt Menu");
	CloseHandle(conf);
	LoadTranslations("common.phrases");
	CreateConVar("tf_tauntem_version", PLUGIN_VERSION, "[TF2] Taunt 'em Version", FCVAR_NOTIFY|FCVAR_PLUGIN);
}

public Action:Cmd_TauntMenu(client, args)
{
	if (CheckCommandAccess(client, "sm_taunt", ADMFLAG_CUSTOM6, false))
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
			AddMenuItem(menu, "1197", "The Scooty Scoot [Scout]");
			AddMenuItem(menu, "1117", "Battin' a Thousand [Scout]");
			AddMenuItem(menu, "1119", "Deep Fried Desire [Scout]");
			AddMenuItem(menu, "1168", "Carlton [Scout]");
			AddMenuItem(menu, "30572", "The Boston Breakdance [Scout]");
			AddMenuItem(menu, "30917", "The Trackman's Touchdown [Scout]");
			AddMenuItem(menu, "30920", "The Bunnyhopper [Scout]");
			AddMenuItem(menu, "30921", "Runner's Rhythm [Scout]");
		}
		case TFClass_Soldier:
		{
			AddMenuItem(menu, "1196", "Panzer Pants [Soldier]");
			AddMenuItem(menu, "1113", "Fresh Brewed Victory [Soldier]");
			AddMenuItem(menu, "30673", "Soldier's Requiem [Soldier]");
			AddMenuItem(menu, "30761", "The Fubar Fanfare [Soldier]");
		}
		case TFClass_Pyro:
		{
			AddMenuItem(menu, "30876", "Headcase [Pyro]");
			AddMenuItem(menu, "1112", "Party Trick [Pyro]");
			AddMenuItem(menu, "30570", "Pool Party [Pyro]");
			AddMenuItem(menu, "30763", "The Balloonibouncer [Pyro]");
			AddMenuItem(menu, "30919", "The Skating Scorcher [Pyro]");
		}
		case TFClass_DemoMan:
		{
			AddMenuItem(menu, "1114", "Spent Well Spirits [Demoman]");
			AddMenuItem(menu, "1120", "Oblooterated [Demoman]");
			AddMenuItem(menu, "30671", "Bad Pipes [Demoman]");
			AddMenuItem(menu, "30840", "Scotsmann's Stagger [Demoman]");
		}
		case TFClass_Heavy:
		{
			AddMenuItem(menu, "30843", "Russian Arms Race [Heavy]");
			AddMenuItem(menu, "30844", "Soviet Strongarm [Heavy]");
			AddMenuItem(menu, "1174", "Table Tantrum [Heavy]");
			AddMenuItem(menu, "1175", "Boiling Point [Heavy]");
			AddMenuItem(menu, "30616", "Proletariat Posedown [Heavy]");
		}
		case TFClass_Engineer:
		{
			AddMenuItem(menu, "30842", "Dueling Banjo [Engineer]");
			AddMenuItem(menu, "30845", "Jumping Jack [Engineer]");
			AddMenuItem(menu, "1115", "Rancho Relaxo [Engineer]");
			AddMenuItem(menu, "30618", "Bucking Bronco [Engineer]");
		}
		case TFClass_Medic:
		{
			AddMenuItem(menu, "477", "Meet the Medic [Medic]");
			AddMenuItem(menu, "1109", "Results Are In [Medic]");
			AddMenuItem(menu, "30918", "Surgeon's Squeezebox [Medic]");
		}
		case TFClass_Sniper:
		{
			AddMenuItem(menu, "1116", "I See You [Sniper]");
			AddMenuItem(menu, "30609", "The Killer Solo [Sniper]");
			AddMenuItem(menu, "30614", "Most Wanted [Sniper]");
			AddMenuItem(menu, "30839", "Didgeridrongo [Sniper]");
		}
		case TFClass_Spy:
		{
			AddMenuItem(menu, "1108", "Buy A Life [Spy]");
			AddMenuItem(menu, "30615", "Box Trot [Spy]");
			AddMenuItem(menu, "30762", "Disco Fever [Spy]");
			AddMenuItem(menu, "30922", "Luxury Lounge [Spy]");
		}
	}
	AddMenuItem(menu, "167", "High Five! [Any]");
	AddMenuItem(menu, "438", "Director's Vision [Any]");
	AddMenuItem(menu, "463", "Schadenfreude [Any]");
	AddMenuItem(menu, "1015", "Shred Alert [Any]");
	AddMenuItem(menu, "1106", "Square Dance [Any]");
	AddMenuItem(menu, "1107", "Flippin' Awesome [Any]");
	AddMenuItem(menu, "1110", "Rock, Paper, Scissors [Any]");
	AddMenuItem(menu, "1111", "Skullcracker [Any]");
	AddMenuItem(menu, "1118", "Conga [Any]");
	AddMenuItem(menu, "1157", "Kazotsky Kick [Any]");
	AddMenuItem(menu, "1162", "Mannrobics [Any]");
	AddMenuItem(menu, "1172", "Victory Lap [Any]");
	AddMenuItem(menu, "1182", "Yeti Punch [Any]");
	AddMenuItem(menu, "1183", "Yeti Smash [Any]");	
	AddMenuItem(menu, "30621", "Burtchester [Any]");
	AddMenuItem(menu, "30672", "Zoomin' Broom [Any]");
	AddMenuItem(menu, "30816", "Second Rate Sourcery [Any]");
	
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