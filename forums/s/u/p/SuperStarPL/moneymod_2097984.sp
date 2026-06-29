#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "MoneyMod",
	author = "SuperStarPL",
	description = "Plays the sounds when money is picked up.",
	version = "1.0",
	url = "http://marcinbebenek.capriolo.pl/",
};

public OnPluginStart()
{
	Plugin_Actions();

	PrintToServer("[MoneyMod] Plugin loaded.");
//	PrintToServer("[MoneyMod]");
	
	HookEvent("mvm_pickup_currency", event_mvm_pickup_currency, EventHookMode_PostNoCopy)
//	decl String:config[PLATFORM_MAX_PATH], String:i_str[4];
//	BuildPath(Path_SM, config, PLATFORM_MAX_PATH, "configs/moneymod.cfg");	 //config unfinished (idk how-to)
//	KvGetString(Kv, "file", fileString, 64);
}

public OnMapStart()
{
    Plugin_Actions();
}

public Action:Plugin_Actions()
{
	AddFileToDownloadsTable("sound/moneymod/moneymoneymoney.mp3");  
//	AddFileToDownloadsTable("sound/moneymod/");  
//	AddFileToDownloadsTable("sound/moneymod/");  
//	AddFileToDownloadsTable("sound/moneymod/");  
//	AddFileToDownloadsTable("sound/moneymod/");  
//	AddFileToDownloadsTable("sound/moneymod/");  
//	AddFileToDownloadsTable("sound/moneymod/");  
//	AddFileToDownloadsTable("sound/moneymod/");  
//	AddFileToDownloadsTable("sound/moneymod/");  

	PrecacheSound("moneymod/moneymoneymoney.mp3");
//	PrecacheSound("moneymod/");
//	PrecacheSound("moneymod/");
//	PrecacheSound("moneymod/");
//	PrecacheSound("moneymod/");
//	PrecacheSound("moneymod/");
//	PrecacheSound("moneymod/");
//	PrecacheSound("moneymod/");
//	PrecacheSound("moneymod/");
}  

public event_mvm_pickup_currency(Handle:event, const String:name[], bool:dontBroadcast)
{
	new nmin = 1; //define first number of sound (DO NOT CHANGE!)
	new nmax = 1; //max num of sounds (cases below)
	
	new snd_money = GetRandomInt(nmin, nmax); //choose random sound
	switch (snd_money)
	{
		case 1:
			{
				EmitSoundToAll("moneymod/moneymoneymoney.mp3"); // 1st sound file
			}
/*		case 2:
			{
				EmitSoundToAll("moneymod/");
			}
		case 3:
			{
				EmitSoundToAll("moneymod/");
			}
		case 4:
			{
				EmitSoundToAll("moneymod/");
			}
		case 5:
			{
				EmitSoundToAll("moneymod/");
			}
		case 6:
			{
				EmitSoundToAll("moneymod/");
			}
		case 7:
			{
				EmitSoundToAll("moneymod/");
			}
		case 8:
			{
				EmitSoundToAll("moneymod/");
			}
		case 9:
			{
				EmitSoundToAll("moneymod/");
			}
*/
	}
	
//	EmitSoundToAll("moneymod/moneymoneymoney.mp3"); //old version, with one sound
}