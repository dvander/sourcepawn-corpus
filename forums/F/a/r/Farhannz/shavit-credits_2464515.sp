#include <sourcemod>
#include <sdktools>
#include <store>
#include <shavit>

#define PLUGIN_VERSION "1.1"
public Plugin myinfo = 
{
	name = "[shavit] Credits | Zephyrus Store",
	author = "Farhannz",
	description = "Gives Zephyrus Store Credits when map finish, break records",
	version = "1.1",
	url = ""
};

Handle gH_Enabled;
Handle gH_Amount_normal;
Handle gH_Amount_wr;
public void OnPluginStart()
{
	CreateConVar("shavit_creds_version", PLUGIN_VERSION, "Zephyrus-Store : Shavit Credits Map Finish", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	gH_Enabled = CreateConVar("credits_enable", "1", "Store money give for map finish is enabled?", 0, true, 0.0, true, 1.0);
	gH_Amount_normal = CreateConVar("credits_amount_normal", "100", "Amount of credits are given on map finish.", 0, true, 0.0, true, 1.0);
	gH_Amount_wr = CreateConVar("credits_amount_wr", "125", "Amount of credits are given on breaking world records.", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "shavit-credits-farhannz");
	
}

public void Shavit_OnFinish(int client, BhopStyle style, float time, int jumps)
{
	if(gH_Enabled)
	{
		int fcredits = GetConVarInt(gH_Amount_normal);
	
		Store_SetClientCredits(client, Store_GetClientCredits(client) + fcredits);
		PrintToChat(client, "\x04[Store]\x01 You have earned %d credits for finishing this map.", fcredits);
	}
	else
	{
		PrintToChat(client, "Disabled")
	}
}
public void Shavit_OnWorldRecord(int client, BhopStyle style, float time, int jumps)
{
	if(gH_Enabled)
	{
		int fcredits = GetConVarInt(gH_Amount_wr);
	
		Store_SetClientCredits(client, Store_GetClientCredits(client) + fcredits);
		PrintToChat(client, "\x04[Store]\x01 You have earned %d credits for break the world records.", fcredits);
	}
	else
	{
		PrintToChat(client, "Disabled")
	}
}