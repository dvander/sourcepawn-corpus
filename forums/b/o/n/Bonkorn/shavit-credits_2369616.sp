
#include <sourcemod>
#include <sdktools>
#include <shavit>
#include <store>

#pragma newdecls required 

public Plugin myinfo = 
{
	name = "[shavit] Credits on MapFinish",
	author = "wyd3x",
	description = "Gives Store credits when you finish a map",
	version = "1.0",
	url = "https://forums.alliedmods.net/member.php?u=197680"
};

Handle gH_Enabled;
Handle gH_Amout;
bool gB_StoreExists;
public void OnPluginStart()
{
	
	gH_Enabled = CreateConVar("sm_giver_enabled", "1", "Store money give for map finish is enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Amout = CreateConVar("sm_giver_amout", "10", "Amout to give on finish map", FCVAR_PLUGIN ,true, 1.0);
	
	AutoExecConfig(true, "shavit-credits");
	
	gB_StoreExists = LibraryExists("store-backend");
}

public void Shavit_OnFinish(int client, int style, float time, int jumps)
{
	if(gB_StoreExists)
		if(gH_Enabled)
		{
			int accountId = Store_GetClientAccountID(client);
			int credits = GetConVarInt(gH_Amout);
	
			Store_GiveCredits(accountId, credits);
			PrintToChat(client, "\x04[Store]\x01 You have earned %d credits for finishing this map.", credits);
		}
}
