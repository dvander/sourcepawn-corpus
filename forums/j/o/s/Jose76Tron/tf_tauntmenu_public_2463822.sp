#pragma semicolon 1

#include <sdktools>
#include <tf2items>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.07"

public Plugin:myinfo = 
{
	name = "[TF2] Taunt Menu", 
	author = "FlaminSarge, Nighty, xCoderx, Crow", 
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
	CreateConVar("tf_tauntem_version", PLUGIN_VERSION, "[TF2] Taunt 'em Version", FCVAR_NOTIFY | FCVAR_NONE);
	
	PrecacheModel("models/player/items/taunts/chicken_bucket/chicken_bucket.mdl", true);
	PrecacheModel("models/workshop/player/items/taunts/pyro_poolparty/pyro_poolparty.mdl", true);
	PrecacheModel("models/workshop/player/items/spy/taunt_spy_boxtrot/taunt_spy_boxtrot.mdl", true);
	PrecacheModel("models/workshop/player/items/sniper/killer_solo/killer_solo.mdl", true);
	PrecacheModel("models/workshop/player/items/sniper/taunt_most_wanted/taunt_most_wanted.mdl", true);
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
	
	switch (class)
	{
		case TFClass_Scout:
		{
			AddMenuItem(menu, "1117", "(Scout) Battin' a Thousand Taunt");
			AddMenuItem(menu, "1119", "(Scout) Deep Fried Desire Taunt");
			AddMenuItem(menu, "30572", "(Scout) Boston Breakdance");
			AddMenuItem(menu, "1168", "(Scout) The Carlton");
		}
		case TFClass_Sniper:
		{
			AddMenuItem(menu, "1116", "(Sniper) I See You Taunt");
			AddMenuItem(menu, "30609", "(Sniper) Killer Solo");
			AddMenuItem(menu, "30614", "(Sniper) Most Wanted");
		}
		case TFClass_Soldier:
		{
			AddMenuItem(menu, "30673", "(Soldier) Requiem Taunt");
			AddMenuItem(menu, "1113", "(Soldier) Fresh Brewed Victory Taunt");
			AddMenuItem(menu, "30761", "(Soldier) The Fubar Fanfare");
		}
		case TFClass_DemoMan:
		{
			AddMenuItem(menu, "30671", "(Demo) Bad Pipes");
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
			AddMenuItem(menu, "30763", "(Pyro) Balloonibouncer");
		}
		case TFClass_Spy:
		{
			AddMenuItem(menu, "1108", "(Spy) Buy A Life Taunt");
			AddMenuItem(menu, "30615", "(Spy) The Boxtrot");
			AddMenuItem(menu, "30762", "(Spy) Disco Fever");
		}
		case TFClass_Engineer:
		{
			AddMenuItem(menu, "30618", "(Engi) Bucking Bronco");
			AddMenuItem(menu, "1115", "(Engi) Rancho Relaxo Taunt");
		}
		case TFClass_Heavy:
		{
			AddMenuItem(menu, "30616", "(Heavy) The Proletariat Showoff");
		}
	}
	
	AddMenuItem(menu, "1162", "(Any) Mannrobics Dance");
	AddMenuItem(menu, "30672", "(Any) Zoomin Broom");
	AddMenuItem(menu, "30621", "(Any) Burstchester");
	AddMenuItem(menu, "1157", "(Any) Kazotsky Kick");
	AddMenuItem(menu, "167", "(Any) High Five Taunt");
	AddMenuItem(menu, "438", "(Any) Replay Taunt");
	AddMenuItem(menu, "463", "(Any) Laugh Taunt");
	AddMenuItem(menu, "1015", "(Any) Shred Alert Taunt");
	AddMenuItem(menu, "1106", "(Any) Square Dance Taunt");
	AddMenuItem(menu, "1107", "(Any) Flippin' Awesome Taunt");
	AddMenuItem(menu, "1110", "(Any) RPS Taunt");
	AddMenuItem(menu, "1111", "(Any) Skullcracker Taunt");
	AddMenuItem(menu, "1118", "(Any) Conga Taunt");
	AddMenuItem(menu, "1172", "(Any) The Victory Lap");
	AddMenuItem(menu, "30816", "(Any) Second Rate Sorcery");
	
	DisplayMenu(menu, client, 20);
}

public Tauntme_MenuSelected(Handle:menu, MenuAction:action, iClient, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	if (action == MenuAction_Select)
	{
		decl String:info[12];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		ExecuteTaunt(iClient, StringToInt(info));
	}
}

ExecuteTaunt(client, itemdef)
{
	static Handle:hItem;
	hItem = TF2Items_CreateItem(OVERRIDE_ALL | PRESERVE_ATTRIBUTES | FORCE_GENERATION);
	
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