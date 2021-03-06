#include <sourcemod>
#include <tf2_stocks>
#include <clientprefs>
#include <morecolors>


#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define MASK_INDEX 31163

Handle g_hWearableEquip;
Handle g_hCookie;

int g_Mask[MAXPLAYERS+1] = {false,...};

public Plugin myinfo = 
{
	name = "[TF2] Covid-19",
	author = "Tair",
	description = "Gives TF2 players mask against Covid-19",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}


public void OnPluginStart() 
{
    
	RegConsoleCmd("sm_covid", Command_Mask);
	HookEvent("post_inventory_application", OnResupply);
	g_hCookie  = RegClientCookie("covid_mask", "", CookieAccess_Private);

	GameData hTF2 = new GameData("sm-tf2.games"); // sourcemod's tf2 gamdata

	if (!hTF2)
		SetFailState("This plugin is designed for a TF2 dedicated server only.");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(hTF2.GetOffset("RemoveWearable") - 1);    // EquipWearable offset is always behind RemoveWearable, subtract its value by 1
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();

	if (!g_hWearableEquip)
		SetFailState("Failed to create call: CBasePlayer::EquipWearable");

	delete hTF2; 
}


public Action OnResupply(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_Mask[client])
    	CreateMask(client);
}


public Action Command_Mask(int client, int args)
{
	if (!g_Mask[client])
	{
		g_Mask[client] = true;
		SetClientCookie(client, g_hCookie, "true");
		CPrintToChat(client,"{gold}★ Covid-19 {white}| Mask is now on! Touch resupply to receive!");
	}
	else
	{
		g_Mask[client] = false;
		SetClientCookie(client, g_hCookie, "false");
		CPrintToChat(client,"{gold}★ Covid-19 {white}| Mask is now off. Touch resupply to remove it!");
	}

	return Plugin_Handled;
}


public void OnClientDisconnect(int client)
{
	g_Mask[client] = false;
}


public void OnClientCookiesCached(int client) 
{
   char value[9];
   GetClientCookie(client, g_hCookie, value, sizeof(value));
   if (StrEqual(value, "true"))
      g_Mask[client] = true;
}


bool CreateMask(int client)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntProp(hat, Prop_Send, "m_iItemDefinitionIndex", MASK_INDEX);	 
	SetEntProp(hat, Prop_Send, "m_bInitialized", 1);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), 10);
	SetEntProp(hat, Prop_Send, "m_iEntityLevel", 1);
	
	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);
	return true;
} 


