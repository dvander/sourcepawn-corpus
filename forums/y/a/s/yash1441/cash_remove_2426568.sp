#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Remove Suicide Cash Messages (CS:GO)", 
	author = "sneaK/blackhawk74/Simon", 
	version = "1.1",
	description = "Disables suicide cash messages in chat.",
	url = "yash1441@yahoo.com"
};

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("TextMsg"), MsgHook_AdjustMoney, true);
}

public Action:MsgHook_AdjustMoney(UserMsg:msg_id, Handle:msg, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:buffer[64];
	PbReadString(msg, "params", buffer, sizeof(buffer), 0);
	
	if (StrEqual(buffer, "#Player_Cash_Award_ExplainSuicide_YouGotCash"))
	{
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_ExplainSuicide_Spectators	"))
	{
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_ExplainSuicide_EnemyGotCash"))
	{
		return Plugin_Handled;
	}
	if (StrEqual(buffer, "#Player_Cash_Award_ExplainSuicide_TeammateGotCash"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}