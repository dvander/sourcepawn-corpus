//修正玩家在遊戲中切換模組之後角色語音錯亂，配合會在遊戲轉換角色模組的插件，依照目前模組判定是一二代倖存者則給予相對應的角色語音
//譬如!csm插件L https://forums.alliedmods.net/showthread.php?p=969651，選擇模組導致自己角色講不出話
//譬如Survivor Bot Holdout插件: https://forums.alliedmods.net/showthread.php?t=188966，在一代地圖上使用二代NPC，二代的NPC語音卻是一代的角色語音
//建議等真的發生角色說不出話再來安裝此插件

#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sourcemod>  
#include <sdktools>

public Plugin myinfo = 
{
	name = "Voice based on model",
	author = "TBK Duy, Harry",
	description = "Survivors will vocalize based on their model",
	version = "1.2",
	url = "https://steamcommunity.com/profiles/76561198026784913/"
}

bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if(bLate)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i)) OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
}

void BillVoice(int client)  
{
	SetVariantString("who:NamVet:0");
	DispatchKeyValue(client, "targetname", "NamVet");
	AcceptEntityInput(client, "AddContext");
}

void ZoeyVoice(int client)  
{
	SetVariantString("who:TeenGirl:0");
	DispatchKeyValue(client, "targetname", "TeenGirl");
	AcceptEntityInput(client, "AddContext");
}

void LouisVoice(int client)  
{
	SetVariantString("who:Manager:0");
	DispatchKeyValue(client, "targetname", "Manager");
	AcceptEntityInput(client, "AddContext");
}

void FrancisVoice(int client)  
{
	SetVariantString("who:Biker:0");
	DispatchKeyValue(client, "targetname", "Biker");
	AcceptEntityInput(client, "AddContext");
}

void NickVoice(int client)  
{
	SetVariantString("who:Gambler:0");
	DispatchKeyValue(client, "targetname", "Gambler");
	AcceptEntityInput(client, "AddContext");
}

void RochelleVoice(int client)  
{
	SetVariantString("who:Producer:0");
	DispatchKeyValue(client, "targetname", "Producer");
	AcceptEntityInput(client, "AddContext");
}

void CoachVoice(int client)  
{
	SetVariantString("who:Coach:0");
	DispatchKeyValue(client, "targetname", "Coach");
	AcceptEntityInput(client, "AddContext");
}

void EllisVoice(int client)  
{
	SetVariantString("who:Mechanic:0");
	DispatchKeyValue(client, "targetname", "Mechanic");
	AcceptEntityInput(client, "AddContext");
}

void Hook_OnPostThinkPost(int iClient)
{
	if(!IsPlayerAlive(iClient)) 
		return;

	if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 4)
	{
		VoiceModel(iClient);
	}
}	
	
void VoiceModel(int iClient)
{
	static char sModel[31];
	GetEntPropString(iClient, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	switch(sModel[29])
	{
		case 'c'://coach
		{
			CoachVoice(iClient);
		}
		case 'b'://nick
		{
			NickVoice(iClient);
		}
		case 'd'://rochelle
		{
			RochelleVoice(iClient);
		}
		case 'h'://ellis
		{
			EllisVoice(iClient);
		}
		case 'v'://bill
		{
			BillVoice(iClient);
		}
		case 'n'://zoey
		{
			ZoeyVoice(iClient);
		}
		case 'e'://francis
		{
			FrancisVoice(iClient);
		}
		case 'a'://louis
		{
			LouisVoice(iClient);
		}
	}
}

