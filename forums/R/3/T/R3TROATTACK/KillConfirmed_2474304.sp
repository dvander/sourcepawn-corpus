#pragma semicolon 1

#define PLUGIN_AUTHOR "R3TROATTACK"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_cMaxScore;
ConVar g_cPointGain;
ConVar g_cCoinLife;
ConVar g_cPointLoss;

float g_fRestartDelay = 5.0;

int g_iLastPickup = -1;
bool g_bAllowEnd = false;

public Plugin myinfo = 
{
	name = "Kill Confirmed",
	author = PLUGIN_AUTHOR,
	description = "A gamemode based off cod",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/R3TROATTACK/"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only.");	
	}
	
	g_cMaxScore = CreateConVar("kc_maxscore", "30", "Score required to win", FCVAR_NONE, true, 0.0);
	g_cPointGain = CreateConVar("kc_collectpointgain", "1", "Points gained for collected a coin of the opposing team", FCVAR_NONE, true, 0.0);
	g_cPointLoss = CreateConVar("kc_collectpointloss", "0", "How many points does the other team lose when their coin is collected", FCVAR_NONE, true, 0.0);
	g_cCoinLife = CreateConVar("kc_coinlife", "10", "How long till coins despawn", FCVAR_NONE, true, 0.0);
	
	AutoExecConfig(true, "KillConfirmed");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookUserMessage(GetUserMessageId("TextMsg"), MsgHook_TextMsg, true);
	AddNormalSoundHook(StopCoinPickupSound);
}

public Action MsgHook_TextMsg(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char buffer[64];
	PbReadString(msg, "params", buffer, sizeof(buffer), 0);
	if(StrEqual(buffer, "#SFUIHUD_InfoPanel_Coop_CollectCoin", false))
		return Plugin_Handled;
	return Plugin_Continue;
}

public Action StopCoinPickupSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(StrContains(sample, "coin_pickup_", false) == -1)
		return Plugin_Continue;
		
	clients[0] = g_iLastPickup;
	numClients = 1;
	return Plugin_Changed;
}

public void OnConfigsExecuted()
{
	SetConVarInt(FindConVar("mp_maxrounds"), g_cMaxScore.IntValue);
	g_fRestartDelay = GetConVarFloat(FindConVar("mp_round_restart_delay"));
}

public void OnMapStart()
{
	PrecacheModel("models/coop/challenge_coin.mdl", true);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bAllowEnd = false;
	SetTeamScore(CS_TEAM_CT, 0);
	SetTeamScore(CS_TEAM_T, 0);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	float vec[3];
	GetClientAbsOrigin(victim, vec);
	CreateCoopCoin(victim, vec);
}

public void CreateCoopCoin(int client, float vec[3])
{
	if(GetClientTeam(client) < 2)
		return;
		
	int ent = CreateEntityByName("item_coop_coin");
	if(ent != -1)
	{
		DispatchKeyValue(ent, "model", "models/coop/challenge_coin.mdl");
		DispatchKeyValue(ent, "scale", "0.5");
		char sTarget[128];
		Format(sTarget, 128, "Team%i", GetClientTeam(client));
		DispatchKeyValue(ent, "targetname", sTarget);
		DispatchSpawn(ent);
		ActivateEntity(ent);
		
		char sOutput[128];
		Format(sOutput, sizeof(sOutput), "OnUser1 !self:kill::%i:1", g_cCoinLife.IntValue);
		SetVariantString(sOutput);
		AcceptEntityInput(ent, "AddOutput", ent, ent, 0);
		AcceptEntityInput(ent, "FireUser1", ent, ent, 0);
		
		switch(GetClientTeam(client))
		{
			case 2:
				SetEntityRenderColor(ent, 255, 0, 0, 255);
			case 3:
				SetEntityRenderColor(ent, 0, 255, 0, 255);
			default:
				SetEntityRenderColor(ent, 0, 0, 0, 255);
		}
		
		vec[2] -= 20.0;
		
		TeleportEntity(ent, vec, NULL_VECTOR, NULL_VECTOR);
		SDKHook(ent, SDKHook_StartTouch, Hook_StartTouch);
	}
}

public Action Hook_StartTouch(int ent, int toucher)
{
	if(IsValidClient(toucher))
	{	
		g_iLastPickup = toucher;
		char sName[128];
		GetEntPropString(ent, Prop_Data, "m_iName", sName, 128);
		ReplaceString(sName, 128, "Team", "", false);
		
		int team = StringToInt(sName);
		
		if(team != GetClientTeam(toucher))
			SetTeamScore(GetClientTeam(toucher), GetTeamScore(GetClientTeam(toucher)) + g_cPointGain.IntValue);
		else if(team == GetClientTeam(toucher))
			SetTeamScore(team, GetTeamScore(team) - g_cPointLoss.IntValue);
		
		CheckForWinner();
	}
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(!g_bAllowEnd)
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public void CheckForWinner()
{
	int CTScore = GetTeamScore(CS_TEAM_CT), TScore = GetTeamScore(CS_TEAM_T);
	
	int max = g_cMaxScore.IntValue;
	
	if(TScore >= max && CTScore >= max)
	{
		g_bAllowEnd = true;
		CS_TerminateRound(g_fRestartDelay, CSRoundEnd_Draw);
	}
	else if(CTScore >= max)
	{
		g_bAllowEnd = true;
		CS_TerminateRound(g_fRestartDelay, CSRoundEnd_CTWin);
	}
	else if(TScore >= max)
	{
		g_bAllowEnd = true;
		CS_TerminateRound(g_fRestartDelay, CSRoundEnd_TerroristWin);
	}
}

stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients)
		return false;
		
	if(!IsClientInGame(client) || !IsClientConnected(client))
		return false;
		
	return true;
}