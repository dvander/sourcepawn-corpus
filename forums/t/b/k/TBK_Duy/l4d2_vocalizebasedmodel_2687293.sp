#include <sdkhooks>
#include <sourcemod>  
#include <sdktools>

public Plugin myinfo = 
{
	name = "Voice based on model",
	author = "TBK Duy",
	description = "Survivors will vocalize based on their model",
	version = "1.0",
	url = "None"
}

public Action BillVoice(int client)  
{
	SetVariantString("who:NamVet:0");
	DispatchKeyValue(client, "targetname", "NamVet");
	AcceptEntityInput(client, "AddContext");
}

public Action ZoeyVoice(int client)  
{
	SetVariantString("who:TeenGirl:0");
	DispatchKeyValue(client, "targetname", "TeenGirl");
	AcceptEntityInput(client, "AddContext");
}

public Action LouisVoice(int client)  
{
	SetVariantString("who:Manager:0");
	DispatchKeyValue(client, "targetname", "Manager");
	AcceptEntityInput(client, "AddContext");
}

public Action FrancisVoice(int client)  
{
	SetVariantString("who:Biker:0");
	DispatchKeyValue(client, "targetname", "Biker");
	AcceptEntityInput(client, "AddContext");
}

public Action NickVoice(int client)  
{
	SetVariantString("who:Gambler:0");
	DispatchKeyValue(client, "targetname", "Gambler");
	AcceptEntityInput(client, "AddContext");
}

public Action RochelleVoice(int client)  
{
	SetVariantString("who:Producer:0");
	DispatchKeyValue(client, "targetname", "Producer");
	AcceptEntityInput(client, "AddContext");
}

public Action CoachVoice(int client)  
{
	SetVariantString("who:Coach:0");
	DispatchKeyValue(client, "targetname", "Coach");
	AcceptEntityInput(client, "AddContext");
}

public Action EllisVoice(int client)  
{
	SetVariantString("who:Mechanic:0");
	DispatchKeyValue(client, "targetname", "Mechanic");
	AcceptEntityInput(client, "AddContext");
}

public void OnClientPutInServer(int iClient)
{
	SDKUnhook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
	SDKHook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
}

public void OnMapStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i) )
		{
			if(IsClientInGame(i))
			{
				SDKUnhook(i, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
				SDKHook(i, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
			}
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_PostThinkPost, Hook_OnPostThinkPost);
}

public void Hook_OnPostThinkPost(int iClient)
{
	if(!IsPlayerAlive(iClient) || GetClientTeam(iClient) != 2) 
		return;
	VoiceModel(iClient);
}	
	
static int VoiceModel(int iClient)
{
	char sModel[31];
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

