#include <sdktools>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.08"

public Plugin myinfo = 
{
	name = "[TF2] Taunt Menu", 
	author = "FlaminSarge, Nighty, xCoderx, Crow, PC Gamer", 
	description = "Displays a taunt menu.", 
	version = PLUGIN_VERSION, 
	url = "http://forums.alliedmods.net/showthread.php?t=242866"
};

Handle hPlayTaunt;

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile("tf2.tauntem");
	
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
}

public void OnMapStart()
{
	PrecacheModel("models/player/items/taunts/chicken_bucket/chicken_bucket.mdl", true);
	PrecacheModel("models/workshop/player/items/taunts/pyro_poolparty/pyro_poolparty.mdl", true);
	PrecacheModel("models/workshop/player/items/pyro/taunt_the_grilled_gunman/taunt_the_grilled_gunman.mdl", true);
	PrecacheModel("models/workshop/player/items/pyro/taunt_the_skating_scorcher/taunt_the_skating_scorcher.mdl", true);	
	PrecacheModel("models/workshop/player/items/spy/taunt_spy_boxtrot/taunt_spy_boxtrot.mdl", true);
	PrecacheModel("models/workshop/player/items/sniper/killer_solo/killer_solo.mdl", true);
	PrecacheModel("models/workshop/player/items/sniper/taunt_most_wanted/taunt_most_wanted.mdl", true);
	PrecacheModel("models/workshop/player/items/engineer/taunt_bumpkins_banjo/taunt_bumpkins_banjo.mdl", true);
	PrecacheModel("models/workshop/player/items/engineer/taunt_jackhammer_rodeo/taunt_jackhammer_rodeo.mdl", true);
	PrecacheModel("models/workshop/player/items/heavy/taunt_soviet_strongarm/taunt_soviet_strongarm.mdl", true);
	PrecacheModel("models/workshop/player/items/scout/taunt_runners_rythm/taunt_runners_rythm.mdl", true);
	PrecacheModel("models/workshop/player/items/scout/taunt_the_bunnyhopper/taunt_the_bunnyhopper.mdl", true);
	PrecacheModel("models/workshop/player/items/scout/taunt_the_trackmans_touchdown/taunt_the_trackmans_touchdown.mdl", true);
	PrecacheModel("models/workshop/player/items/medic/taunt_surgeons_squeezebox/taunt_surgeons_squeezebox.mdl", true);
	PrecacheModel("models/workshop/player/items/spy/taunt_luxury_lounge/taunt_luxury_lounge.mdl", true);	
}

public Action Cmd_TauntMenu(int client, int args)
{
	ShowMenu(client);
	
	return Plugin_Handled;
}

Action ShowMenu(int client)
{
	TFClassType class = TF2_GetPlayerClass(client);
	Menu menu = CreateMenu(Tauntme_MenuSelected);
	SetMenuTitle(menu, "Taunts:");
	
	switch (class)
	{
	case TFClass_Scout:
		{
			AddMenuItem(menu, "31233", "(Scout) The Homerunners Hobby");
			AddMenuItem(menu, "31161", "(Scout) Spin-To-Win");	
			AddMenuItem(menu, "31156", "(Scout) The Boston Boarder");			
			AddMenuItem(menu, "1197", "(Scout) The Scooty Scoot");
			AddMenuItem(menu, "1117", "(Scout) Battin' a Thousand");
			AddMenuItem(menu, "1119", "(Scout) Deep Fried Desire");
			AddMenuItem(menu, "30572", "(Scout) The Boston Breakdance");
			AddMenuItem(menu, "1168", "(Scout) The Carlton");
			AddMenuItem(menu, "30917", "(Scout) The Trackmans Touchdown");
			AddMenuItem(menu, "30920", "(Scout) The Bunnyhopper");
			AddMenuItem(menu, "30921", "(Scout) Runners Rhythm");
		}
	case TFClass_Sniper:
		{
			AddMenuItem(menu, "31237", "(Sniper) Shooters Stakeout");
			AddMenuItem(menu, "1116", "(Sniper) I See You");
			AddMenuItem(menu, "30609", "(Sniper) Killer Solo");
			AddMenuItem(menu, "30614", "(Sniper) Most Wanted");
			AddMenuItem(menu, "30839", "(Sniper) Didgeridrongo");			
		}
	case TFClass_Soldier:
		{
			AddMenuItem(menu, "31202", "(Soldier) The Profane Puppeteer");
			AddMenuItem(menu, "1196", "(Soldier) Panzer Pants");
			AddMenuItem(menu, "30673", "(Soldier) Soldiers Requiem");
			AddMenuItem(menu, "1113", "(Soldier) Fresh Brewed Victory");
			AddMenuItem(menu, "30761", "(Soldier) The Fubar Fanfare");
			AddMenuItem(menu, "31155", "(Soldier) Rocket Jockey");			
		}
	case TFClass_DemoMan:
		{
			AddMenuItem(menu, "31201", "(Demo) The Drunken Sailor");
			AddMenuItem(menu, "30671", "(Demo) True Scotsmans Call");
			AddMenuItem(menu, "1114", "(Demo) Spent Well Spirits");
			AddMenuItem(menu, "1120", "(Demo) Oblooterated");
			AddMenuItem(menu, "30840", "(Demo) Scotsmann's Stagger");
			AddMenuItem(menu, "31153", "(Demo) The Pooped Deck");			
		}
	case TFClass_Medic:
		{
			AddMenuItem(menu, "31236", "(Medic) Doctors Defibrillators");
			AddMenuItem(menu, "31203", "(Medic) The Mannbulance");
			AddMenuItem(menu, "477", "(Medic) Meet the Medic Heroic");
			AddMenuItem(menu, "1109", "(Medic) Results Are In");
			AddMenuItem(menu, "30918", "(Medic) Surgeons Squeezebox");
			AddMenuItem(menu, "31154", "(Medic) Time Out Therapy");				
		}
		
	case TFClass_Pyro:
		{
			AddMenuItem(menu, "31239", "(Pyro) The Hot Wheeler");
			AddMenuItem(menu, "31157", "(Pyro) Scorcher's Solo");
			AddMenuItem(menu, "30876", "(Pyro) The Headcase");
			AddMenuItem(menu, "1112", "(Pyro) Party Trick");
			AddMenuItem(menu, "30570", "(Pyro) Pool Party");
			AddMenuItem(menu, "30763", "(Pyro) The Balloonibouncer");
			AddMenuItem(menu, "30919", "(Pyro) The Skating Scorcher");
		}
	case TFClass_Spy:
		{
			AddMenuItem(menu, "1108", "(Spy) Buy A Life");
			AddMenuItem(menu, "30615", "(Spy) The Boxtrot");
			AddMenuItem(menu, "30762", "(Spy) Disco Fever");
			AddMenuItem(menu, "30922", "(Spy) Luxury Lounge");
		}
	case TFClass_Engineer:
		{
			AddMenuItem(menu, "31160", "(Engineer) Texas Truckin");
			AddMenuItem(menu, "30842", "(Engineer) The Dueling Banjo");
			AddMenuItem(menu, "30845", "(Engineer) The Jumping Jack");			
			AddMenuItem(menu, "30618", "(Engineer) Bucking Bronco");
			AddMenuItem(menu, "1115", "(Engineer) Rancho Relaxo");
		}
	case TFClass_Heavy:
		{
			AddMenuItem(menu, "31207", "(Heavy) Bare Knuckle Beatdown");
			AddMenuItem(menu, "30843", "(Heavy) The Russian Arms Race");
			AddMenuItem(menu, "30844", "(Heavy) The Soviet Strongarm");
			AddMenuItem(menu, "30616", "(Heavy) The Proletariat Showoff");
			AddMenuItem(menu, "1174", "(Heavy) The Table Tantrum");
			AddMenuItem(menu, "1175", "(Heavy) The Boiling Point");
		}
	}

	AddMenuItem(menu, "1182", "(Any) Yeti Punch");
	AddMenuItem(menu, "1183", "(Any) Yeti Smash");	
	AddMenuItem(menu, "1162", "(Any) Mannrobics");
	AddMenuItem(menu, "30672", "(Any) Zoomin Broom");
	AddMenuItem(menu, "30621", "(Any) Burstchester");
	AddMenuItem(menu, "1157", "(Any) Kazotsky Kick");
	AddMenuItem(menu, "167", "(Any) High Five");
	AddMenuItem(menu, "438", "(Any) Replay");
	AddMenuItem(menu, "463", "(Any) Laugh");
	AddMenuItem(menu, "1015", "(Any) Shred Alert Taunt");
	AddMenuItem(menu, "1106", "(Any) Square Dance");
	AddMenuItem(menu, "1107", "(Any) Flippin' Awesome");
	AddMenuItem(menu, "1110", "(Any) Rock Paper Scissors");
	AddMenuItem(menu, "1111", "(Any) Skullcracker");
	AddMenuItem(menu, "1118", "(Any) Conga");
	AddMenuItem(menu, "1172", "(Any) The Victory Lap");
	AddMenuItem(menu, "30816", "(Any) Second Rate Sorcery");
	AddMenuItem(menu, "31162", "(Any) The Fist Bump");	
	
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

int Tauntme_MenuSelected(Menu menu, MenuAction action, int iClient, int param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	if (action == MenuAction_Select)
	{
		char info[12];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		ExecuteTaunt(iClient, StringToInt(info));
	}
	return 1;
}

stock Action ExecuteTaunt(int client, int itemindex)
{
	int taunt = CreateEntityByName("tf_wearable_vm");
	
	if (!IsValidEntity(taunt))
	{
		return Plugin_Handled;
	}
	
	char entclass[64];
	GetEntityNetClass(taunt, entclass, sizeof(entclass));
	SetEntData(taunt, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(taunt, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(taunt, FindSendPropInfo(entclass, "m_iEntityLevel"), 1);
	SetEntData(taunt, FindSendPropInfo(entclass, "m_iEntityQuality"), 6);
	SetEntProp(taunt, Prop_Send, "m_bValidatedAttachedEntity", 1);  	

	Address pEconItemView = GetEntityAddress(taunt) + view_as<Address>(FindSendPropInfo("CTFWearable", "m_Item"));

	SDKCall(hPlayTaunt, client, pEconItemView) ? 1 : 0;
	AcceptEntityInput(taunt, "Kill");
	
	return Plugin_Handled;
} 