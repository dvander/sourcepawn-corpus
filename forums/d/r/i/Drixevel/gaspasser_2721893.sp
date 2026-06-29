#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "[TF2] Gas to Piss", 
	author = "Drixevel", 
	description = "Turns gas into piss.", 
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

public void TF2_OnConditionAdded(int client, TFCond condition)
{	
	if (condition == TFCond_Gas)
	{
		TF2_RemoveCondition(client, TFCond_Gas);
		TF2_AddCondition(client, TFCond_Jarated);
	}
}