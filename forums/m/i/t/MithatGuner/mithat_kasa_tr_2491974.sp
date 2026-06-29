/*
THANKS FOR DOWNLOADING PLUGIN :)
PLUGINLER.COM - MITHAT GUNER
TR - VERSIYON
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

new Handle:GirisUcreti;
new Handle:CikacakMinTL;
new Handle:CikacakMaxTL;
//new Bakiye = -1;
Handle Tag = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "KASA | Mithat Guner",
	author = PLUGIN_AUTHOR,
	description = "KASA | Mithat Guner",
	version = PLUGIN_VERSION,
	url = "pluginler.com"
};

public void OnPluginStart()
{
	Tag = CreateConVar("mithat_tag", "Only Fun", "Eklenti Reklam Tagi | Mithat Guner", FCVAR_PLUGIN);
	RegConsoleCmd("sm_kasa", KASADD, "Kasa Ac | Mithat Guner");
	GirisUcreti = CreateConVar("mithat_giris_ucreti", "5000", "Kasadan Giris Ucreti");
	CikacakMinTL = CreateConVar("mithat_min_odul", "1000", "Kasadan Cikan Min Kredi");
	CikacakMaxTL = CreateConVar("mithat_max_odul", "30000", "Kasadan Cikan Max Kredi");
	//Bakiye = FindSendPropOffs("CCSPlayer", "m_iAccount");
	//	if(Bakiye == -1) SetFailState("Deger Bulunamadi 'm_iAccount'");
	AutoExecConfig(true, "mithat_kasa");
}

public Action KASADD(client, args)
{
	char Tagg[180];
	GetConVarString(Tag, Tagg, sizeof(Tagg));
	new UCRET = GetConVarInt(GirisUcreti);
	if (Store_GetClientCredits(client) >= UCRET)	
		{
			Store_SetClientCredits(client, Store_GetClientCredits(client) - UCRET);
			//SetEntData(client, Bakiye, Client_GetMoney(client) - UCRET);
			CreateTimer(0.1, GAMMAaciliyor, client, TIMER_REPEAT);
		}
		else CPrintToChat(client, "{darkred}[ %s ]{lime} Kasa açabilmek için %i Paraya ihtiyacýn var.", Tagg, UCRET);
}


public Action GAMMAaciliyor(Handle timer, any client)
{
	char Tagg[180];
	GetConVarString(Tag, Tagg, sizeof(Tagg));
	static int SAYI = 0;
 	new MIN = GetConVarInt(CikacakMinTL);
 	new MAX = GetConVarInt(CikacakMaxTL);
	if (SAYI >= 100) 
	{
		SAYI = 0;
		int randomSAYI = GetRandomInt(MIN,MAX);	
		PrintCenterText(client, "<big><u><b><font color='#dd2f2f'><center>%s</center>\n</font><font color='#00CCFF'>|| <font color='#15fb00'>%i</font> Para ||</font></b></u></big>", Tagg, randomSAYI);
		CPrintToChat(client, "{darkred}[ %s ] {lime}Tebrikler! kasadan {purple}|| {darkred}%i {lime}Para {purple}|| {lime}kazandýn!", Tagg, randomSAYI);
		Store_SetClientCredits(client, Store_GetClientCredits(client) + randomSAYI);
		//SetEntData(client, Bakiye, Client_GetMoney(client) + randomSAYI);
		return Plugin_Stop;
	}
	
 	int randomSAYI = GetRandomInt(MIN,MAX);	
	PrintCenterText(client, "<big><u><b><font color='#00CCFF'>|| <font color='#15fb00'>%i</font> Para ||</font></b></u></big>", randomSAYI);
	SAYI++;			
	return Plugin_Continue;
}