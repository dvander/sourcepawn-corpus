#include <sourcemod>
#include <sdktools>

new g_iAccount = -1;
new g_oldmoney;
new g_newmoney;

new Handle:Switch;
new Handle:MoneyToGive;
new Handle:VisibleChat;
new Handle:EndRound;

public Plugin:myinfo = 
{
	name = "RoundMoney",
	author = "Pigophone",
	description = "Gives Money Every Round",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	HookEvent("round_end", GiveMoneyFuncEnd, EventHookMode_Post);
	HookEvent("round_start", GiveMoneyFunc, EventHookMode_Post);
	Switch = CreateConVar("sm_roundmoney_enabled","1","Enable or disable the RoundMoney", _, true, 0.0, true, 1.0);
	MoneyToGive = CreateConVar("sm_roundmoney_amount","16000","Amount of Money To Give Each Round", _, true, 0.0, true, 16000.0);
	VisibleChat = CreateConVar("sm_roundmoney_chat","1","Roundmoney prints '[SM] Gave x amount of money to everyone'", _, true, 0.0, true, 1.0);
	EndRound = CreateConVar("sm_roundmoney_endround","0","Give RoundMoney at end of Round?", _, true, 0.0, true, 1.0);
}

public GiveMoneyFunc(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Switch)){
		if(GetConVarInt(VisibleChat))
		{
			PrintToChatAll("\x04[SM] Gave Everyone $%d", GetConVarInt(MoneyToGive));
		}
		if(GetConVarInt(EndRound)==0){
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i)) {
					SetMoney( i, GetConVarInt(MoneyToGive));
				}
			}
		}
	}
}

public GiveMoneyFuncEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Switch)){
		if(GetConVarInt(EndRound)){
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i)) {
					SetMoney( i, GetConVarInt(MoneyToGive));
				}
			}
		}
	}
}
		

public SetMoney(client, amount)
{
	if (g_iAccount != -1)
	{
		g_oldmoney = GetMoney(client);
		g_newmoney = g_oldmoney + amount;
		if(g_newmoney > 16000){
			g_newmoney = 16000;
		}
		SetEntData(client, g_iAccount, g_newmoney);
	}	
}

public GetMoney(client)
{
	if (g_iAccount != -1)
		return GetEntData(client, g_iAccount);

	return 0;
}