#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0"

public Plugin myinfo =
{
	name = "[TF2] Taunt 'em",
	author = "FlaminSarge, edited by PC Gamer",
	description = "Force special taunts on players",
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
	
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_tauntem", Command_Tauntem, ADMFLAG_SLAY);
}

Action Command_Tauntem(int client, int args)
{
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	
	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));
	int tauntindex = StringToInt(arg2);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		MakeTaunt(target_list[i], tauntindex);
	}
	return Plugin_Handled;
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

	SDKCall(hPlayTaunt, client, pEconItemView) ? 1 : 0;

	AcceptEntityInput(taunt, "Kill");
	
	return Plugin_Handled;
}
