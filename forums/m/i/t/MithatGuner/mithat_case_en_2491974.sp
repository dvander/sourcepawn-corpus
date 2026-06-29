/*
THANKS FOR DOWNLOADING PLUGIN :)
PLUGINLER.COM - MITHAT GUNER
EN - VERSION
*/

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "KUTU | Mithat Guner"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <cstrike>
#include <multicolors>
#include <sdktools>
#include <store>

new Handle:JoinCost;
new Handle:MinPrice;
new Handle:MaxPrice;
//new Bakiye = -1;
Handle Tag = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "Case | Mithat Guner",
	author = PLUGIN_AUTHOR,
	description = "Case | Mithat Guner",
	version = PLUGIN_VERSION,
	url = "pluginler.com"
};

public void OnPluginStart()
{
	Tag = CreateConVar("mithat_tag", "Pluginler.com", "Eklenti Reklam Tagi | Mithat Guner", FCVAR_PLUGIN);
	RegConsoleCmd("sm_case", CaseDD, "Case Ac | Mithat Guner");
	JoinCost = CreateConVar("mithat_open_cost", "5000", "Casedan Giris JoiningCosti");
	MinPrice = CreateConVar("mithat_min_price", "1000", "Casedan Cikan Min Kredi");
	MaxPrice = CreateConVar("mithat_max_price", "30000", "Casedan Cikan Max Kredi");
	//Bakiye = FindSendPropOffs("CCSPlayer", "m_iAccount");
	//	if(Bakiye == -1) SetFailState("Deger Bulunamadi 'm_iAccount'");
	AutoExecConfig(true, "mithat_case");
}

public Action CaseDD(client, args)
{
	char Tagg[180];
	GetConVarString(Tag, Tagg, sizeof(Tagg));
	new JoiningCost = GetConVarInt(JoinCost);
	if (Store_GetClientCredits(client) >= JoiningCost)	
		{
			Store_SetClientCredits(client, Store_GetClientCredits(client) - JoiningCost);
			//SetEntData(client, Bakiye, Client_GetMoney(client) - JoiningCost);
			CreateTimer(0.1, OpeningCase, client, TIMER_REPEAT);
		}
		else CPrintToChat(client, "{darkred}[ %s ]{lime} U need %i credits to open case.", Tagg, JoiningCost);
}


public Action OpeningCase(Handle timer, any client)
{
	char Tagg[180];
	GetConVarString(Tag, Tagg, sizeof(Tagg));
	static int Number = 0;
 	new MIN = GetConVarInt(MinPrice);
 	new MAX = GetConVarInt(MaxPrice);
	if (Number >= 100) 
	{
		Number = 0;
		int randomNumber = GetRandomInt(MIN,MAX);	
		PrintCenterText(client, "<big><u><b><font color='#dd2f2f'><center>%s</center>\n</font><font color='#00CCFF'>|| <font color='#15fb00'>%i</font> Credits ||</font></b></u></big>", Tagg, randomNumber);
		CPrintToChat(client, "{darkred}[ %s ] {lime}U Win {purple}|| {darkred}%i {lime}Credits From Case{purple}|| {lime}kazandın!", Tagg, randomNumber);
		Store_SetClientCredits(client, Store_GetClientCredits(client) + randomNumber);
		//SetEntData(client, Bakiye, Client_GetMoney(client) + randomNumber);
		return Plugin_Stop;
	}
	
 	int randomNumber = GetRandomInt(MIN,MAX);	
	PrintCenterText(client, "<big><u><b><font color='#00CCFF'>|| <font color='#15fb00'>%i</font> Credits ||</font></b></u></big>", randomNumber);
	Number++;			
	return Plugin_Continue;
}