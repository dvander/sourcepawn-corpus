#include <sourcemod>
#include <sdktools>

ConVar tf_bot_quota;
ConVar tf_mvm_disconnect_on_victory;
ConVar tf_mvm_victory_reset_time;

Handle g_hSDKGetMyNextBotPointer;
Handle g_hCrashTimer;

public Plugin myinfo = 
{
	name = "Bot crash fix",
	author = "Benoist3012",
	description = "",
	version = "0.1",
	url = "",
};

public void OnPluginStart()
{
	HookEvent("teamplay_game_over", Event_GameOver);
	HookEvent("teamplay_round_start", Event_StartMission);
	HookEvent("mvm_mission_complete", Event_MissionOver);
	
	tf_bot_quota = FindConVar("tf_bot_quota");
	tf_mvm_disconnect_on_victory = FindConVar("tf_mvm_disconnect_on_victory");
	tf_mvm_victory_reset_time = FindConVar("tf_mvm_victory_reset_time");
	
	HookUserMessage(GetUserMessageId("VotePass"), Hook_VotePass, false);
	
	Handle hGameData = LoadGameConfigFile("bot_crash_fix");
	if (hGameData == null)
		SetFailState("Couldn't find bot_crash_fix.txt gamedata!");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CBaseEntity::MyNextBotPointer");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKGetMyNextBotPointer = EndPrepSDKCall();
	if (g_hSDKGetMyNextBotPointer == null)
		SetFailState("Failed to create call: CBaseEntity::MyNextBotPointer!");
	delete hGameData;
}

public Action Event_GameOver(Event event, const char[] eventName, bool bDontBroadcast)
{
	Avoid_Crash();
}

public Action Event_StartMission(Event event, const char[] eventName, bool bDontBroadcast)
{
	g_hCrashTimer = null;
}

public Action Event_MissionOver(Event event, const char[] eventName, bool bDontBroadcast)
{
	if (!tf_mvm_disconnect_on_victory.BoolValue) // Map will change
		g_hCrashTimer = CreateTimer(tf_mvm_victory_reset_time.FloatValue-0.1, Timer_AvoidCrash);
}

public Action Hook_VotePass(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	msg.ReadByte();
	char sMessage[125];
	
	DataPack pack = new DataPack();
	
	msg.ReadString(sMessage, sizeof(sMessage));
	pack.WriteString(sMessage);
	msg.ReadString(sMessage, sizeof(sMessage));
	pack.WriteString(sMessage);
	
	RequestFrame(Frame_PrintPassMessage, pack);
}

public Action Timer_AvoidCrash(Handle timer)
{
	if (timer != g_hCrashTimer)
		return Plugin_Continue;
	Avoid_Crash();
}

void Frame_PrintPassMessage(DataPack pack)
{
	char sMessage[125];
	pack.Reset();
	pack.ReadString(sMessage, sizeof(sMessage));
	if (strcmp(sMessage, "#TF_vote_passed_changelevel") == 0)
		Avoid_Crash();
	pack.ReadString(sMessage, sizeof(sMessage));
	
	delete pack;
}

void Avoid_Crash()
{
	PrintToServer("Cleaning bots");
	
	for (int i = 1; i <= 2048; i++)
	{
		if (IsValidEntity(i))
		{
			if (SDKCall(g_hSDKGetMyNextBotPointer, i) != Address_Null)//If the entity is a bot
			{
				if ( 1 <= i <= MaxClients) //Client
					KickClient(i);
				else // Regular entity, send kill input
					AcceptEntityInput(i, "Kill");
			}
		}
	}
	
	tf_bot_quota.IntValue = 0;//Make sure client bots don't come back
}