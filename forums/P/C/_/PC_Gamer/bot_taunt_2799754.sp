/*
All class taunt numbers:
"31288", "(Any) The Scaredy-Cat"
"1182", "(Any) Yeti Punch"
"1183", "(Any) Yeti Smash"	
"1162", "(Any) Mannrobics"
"30672", "(Any) Zoomin Broom"
"30621", "(Any) Burstchester"
"1157", "(Any) Kazotsky Kick"
"167", "(Any) High Five"
"438", "(Any) Replay"
"463", "(Any) Laugh"
"1015", "(Any) Shred Alert Taunt"
"1106", "(Any) Square Dance"
"1107", "(Any) Flippin' Awesome"
"1110", "(Any) Rock Paper Scissors"
"1111", "(Any) Skullcracker"
"1118", "(Any) Conga"
"1172", "(Any) The Victory Lap"
"30816", "(Any) Second Rate Sorcery"
"31162", "(Any) The Fist Bump"	
*/

#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Bot Taunt",
	author = "PC Gamer, using code by FlaminSarge",
	description = "Bots randomly taunt",
	version = "1.0",
	url = "http://forums.alliedmods.net"
};

Handle hPlayBotTaunt;
ConVar g_hTauntChance;

public void OnPluginStart()
{
	g_hTauntChance = CreateConVar("sm_bot_taunt_chance", "5", "Percentage chance a bot will taunt 0-100", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	Handle conf2 = LoadGameConfigFile("tf2.tauntem");
	
	if (conf2 == INVALID_HANDLE)
	{
		SetFailState("Unable to load gamedata/tf2.tauntem.txt. Good luck figuring that out.");
		return;
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf2, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPlayBotTaunt = EndPrepSDKCall();
	
	if (hPlayBotTaunt == INVALID_HANDLE)
	{
		SetFailState("Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Wait patiently for a fix.");
		CloseHandle(conf2);
		return;
	}
	
	HookEvent("player_death", Event_Death, EventHookMode_Post);	
}

public void Event_Death(Handle event, const char[] name, bool dontBroadcast) 
{
	int killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (killer > 0 && IsFakeClient(killer) && IsPlayerAlive(killer))
	{
		int rnd1 = GetRandomUInt(1,100);		
		if (rnd1 < g_hTauntChance.IntValue)
		{
			int rnd2 = GetRandomUInt(1,10);
			switch (rnd2)
			{
			case 1:
				{
					MakeTaunt(killer, 31288); //Scaredy-Cat
				}
			case 2:
				{
					MakeTaunt(killer, 1182); //Yeti Punch
				}
			case 3:
				{
					MakeTaunt(killer, 1183); //Yeti Smash
				}
			case 4:
				{
					MakeTaunt(killer, 1162); //Mannrobics
				}
			case 5:
				{
					MakeTaunt(killer, 30621); //Burstchester
				}
			case 6:
				{
					MakeTaunt(killer, 1157); //Kazotsky Kick
				}
			case 7:
				{
					MakeTaunt(killer, 1015); //Shred Alert
				}
			case 8,9,10,11:
				{
					MakeTaunt(killer, 463); //Laugh
				}
			case 12:
				{
					MakeTaunt(killer, 30816); //Second Rate Sorcery
				}
			case 13:
				{
					MakeTaunt(killer, 1118); //Conga
				}				
			}
		}
	}
}

stock Action MakeTaunt(int client, int itemindex, int particle=0)
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

	SDKCall(hPlayBotTaunt, client, pEconItemView) ? 1 : 0;

	AcceptEntityInput(taunt, "Kill");
	
	return Plugin_Handled;
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}