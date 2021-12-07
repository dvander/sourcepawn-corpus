#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
	
public Plugin:myinfo = {
	name = "Change Player Score",
	author = "Ben6006",
	description = "Change Player Score",
	version = "1.0",
	url = "http://"
};
new Handle:hIncrementFragCount;
new Handle:hResetFragCount;
new Handle:hIncrementDeathCount;
new Handle:hResetDeathCount;
new Handle:hGameConf;
public OnPluginStart()
{
	RegConsoleCmd("add_score", add_5_score);
	RegConsoleCmd("add_death", add_5_death);
	
	RegConsoleCmd("reset_score", reset_score);
	RegConsoleCmd("reset_death", reset_death);
	
	RegConsoleCmd("set_score", set_score_to_4321);
	RegConsoleCmd("set_death", set_death_to_4321);
	
	hGameConf = LoadGameConfigFile("weaponmodel");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IncrementFragCount");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hIncrementFragCount = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "ResetFragCount");
	hResetFragCount = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "IncrementDeathCount");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hIncrementDeathCount = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "ResetDeathCount");
	hResetDeathCount = EndPrepSDKCall();

}
stock AddScore(client,value)
{
	SDKCall(hIncrementFragCount,client,value);
}
stock AddDeath(client,value)
{
	SDKCall(hIncrementDeathCount,client,value);
}
stock ResetScore(client)
{
	SDKCall(hResetFragCount,client);
}
stock ResetDeath(client)
{
	SDKCall(hResetDeathCount,client);
}
stock SetScore(client, value)
{
	ResetScore(client);
	AddScore(client,value);
}
stock SetDeath(client, value)
{
	ResetDeath(client);
	AddDeath(client,value);
}
public Action:add_5_score(client,args)
{
	if(client)
	{
		AddScore(client,5);
	}
	return Plugin_Handled;
}
public Action:add_5_death(client,args)
{
	if(client)
	{
		AddDeath(client,5);
	}
	return Plugin_Handled;
}
public Action:reset_score(client,args)
{
	if(client)
	{
		ResetScore(client);
	}
	return Plugin_Handled;
}
public Action:reset_death(client,args)
{
	if(client)
	{
		ResetDeath(client);
	}
	return Plugin_Handled;
}
public Action:set_score_to_4321(client,args)
{
	if(client)
	{
		SetScore(client,4321);
	}
	return Plugin_Handled;
}
public Action:set_death_to_4321(client,args)
{
	if(client)
	{
		SetDeath(client,4321);
	}
	return Plugin_Handled;
}