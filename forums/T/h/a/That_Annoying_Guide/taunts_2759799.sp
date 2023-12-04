#pragma semicolon 1

#include <sdktools>
#include <tf2items>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1"

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
	
	RegConsoleCmd("sm_taunt", Cmd_TauntMenu, "Taunt Menu");
	RegConsoleCmd("sm_taunts", Cmd_TauntMenu, "Taunt Menu");
	CloseHandle(conf);
	LoadTranslations("common.phrases");
	CreateConVar("tf_tauntem_version", PLUGIN_VERSION, "[TF2] Taunt 'em Version", FCVAR_NOTIFY);
}

public Action:Cmd_TauntMenu(client, args)
{
	if (CheckCommandAccess(client, "sm_taunt", false))
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
			AddMenuItem(menu, "1197", "The Scooty Scoot [Scout]", 0);
			AddMenuItem(menu, "1117", "Battin' a Thousand [Scout]", 0);
			AddMenuItem(menu, "1119", "Deep Fried Desire [Scout]", 0);
			AddMenuItem(menu, "1168", "Carlton [Scout]", 0);
			AddMenuItem(menu, "30572", "The Boston Breakdance [Scout]", 0);
			AddMenuItem(menu, "30917", "The Trackman's Touchdown [Scout]", 0);
			AddMenuItem(menu, "30920", "The Bunnyhopper [Scout]", 0);
			AddMenuItem(menu, "30921", "Runner's Rhythm [Scout]", 0);
			AddMenuItem(menu, "31156", "The Boston Boarder [Scout]", 0);
			AddMenuItem(menu, "31161", "Spin-to-Win [Scout]", 0);
			AddMenuItem(menu, "31233", "The Homerunners Hobby [Scout]", 0);
		}
		case TFClass_Sniper:
		{
			AddMenuItem(menu, "1116", "I See You [Sniper]", 0);
			AddMenuItem(menu, "30609", "The Killer Solo [Sniper]", 0);
			AddMenuItem(menu, "30614", "Most Wanted [Sniper]", 0);
			AddMenuItem(menu, "30839", "Didgeridrongo [Sniper]", 0);
			AddMenuItem(menu, "31237", "Shooter's Stakeout [Sniper]", 0);
		}
		case TFClass_Soldier:
		{
			AddMenuItem(menu, "1196", "Panzer Pants [Soldier]", 0);
			AddMenuItem(menu, "1113", "Fresh Brewed Victory [Soldier]", 0);
			AddMenuItem(menu, "30673", "Soldier's Requiem [Soldier]", 0);
			AddMenuItem(menu, "30761", "The Fubar Fanfare [Soldier]", 0);
			AddMenuItem(menu, "31155", "Rocket Jockey [Soldier]", 0);
			AddMenuItem(menu, "31202", "The Profane Puppeteer [Soldier]", 0);
		}
		case TFClass_DemoMan:
		{
			AddMenuItem(menu, "1114", "Spent Well Spirits [Demoman]", 0);
			AddMenuItem(menu, "1120", "Oblooterated [Demoman]", 0);
			AddMenuItem(menu, "30671", "Bad Pipes [Demoman]", 0);
			AddMenuItem(menu, "30840", "Scotsmann's Stagger [Demoman]", 0);
			AddMenuItem(menu, "31153", "The Pooped Deck [Demoman]", 0);
			AddMenuItem(menu, "31201", "The Drunken Sailor [Demoman]", 0);
		}
		case TFClass_Medic:
		{
			AddMenuItem(menu, "477", "Meet the Medic [Medic]", 0);
			AddMenuItem(menu, "1109", "Results Are In [Medic]", 0);
			AddMenuItem(menu, "30918", "Surgeon's Squeezebox [Medic]", 0);
			AddMenuItem(menu, "31154", "Time Out Therapy [Medic]", 0);
			AddMenuItem(menu, "31203", "The Mannbulance! [Medic]", 0);
			AddMenuItem(menu, "31236", "Doctor's Defibrillators [Medic]", 0);
		}
		case TFClass_Heavy:
		{
			AddMenuItem(menu, "30843", "Russian Arms Race [Heavy]", 0);
			AddMenuItem(menu, "30844", "Soviet Strongarm [Heavy]", 0);
			AddMenuItem(menu, "1174", "Table Tantrum [Heavy]", 0);
			AddMenuItem(menu, "1175", "Boiling Point [Heavy]", 0);
			AddMenuItem(menu, "30616", "Proletariat Posedown [Heavy]", 0);
			AddMenuItem(menu, "31207", "Bare Knuckle Beatdown [Heavy]", 0);
		}
		case TFClass_Pyro:
		{
			AddMenuItem(menu, "30876", "Headcase [Pyro]", 0);
			AddMenuItem(menu, "1112", "Party Trick [Pyro]", 0);
			AddMenuItem(menu, "30570", "Pool Party [Pyro]", 0);
			AddMenuItem(menu, "30763", "The Balloonibouncer [Pyro]", 0);
			AddMenuItem(menu, "30919", "The Skating Scorcher [Pyro]", 0);
			AddMenuItem(menu, "31157", "Scorcher's Solo [Pyro]", 0);
			AddMenuItem(menu, "31239", "The Hot Wheeler [Pyro]", 0);
		}
		case TFClass_Spy:
		{
			AddMenuItem(menu, "1108", "Buy A Life [Spy]", 0);
			AddMenuItem(menu, "30615", "Box Trot [Spy]", 0);
			AddMenuItem(menu, "30762", "Disco Fever [Spy]", 0);
			AddMenuItem(menu, "30922", "Luxury Lounge [Spy]", 0);
		}
		case TFClass_Engineer:
		{
			AddMenuItem(menu, "30842", "Dueling Banjo [Engineer]", 0);
			AddMenuItem(menu, "30845", "Jumping Jack [Engineer]", 0);
			AddMenuItem(menu, "1115", "Rancho Relaxo [Engineer]", 0);
			AddMenuItem(menu, "30618", "Bucking Bronco [Engineer]", 0);
			AddMenuItem(menu, "31160", "Texas Truckin [Engineer]", 0);
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
	AddMenuItem(menu, "31162", "Fist Bump [Any]");
	
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