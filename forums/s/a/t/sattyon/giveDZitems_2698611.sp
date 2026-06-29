#include <sourcemod>
#include <sdktools>
#include <cstrike>
new String:tagre[32] = "weapon_tagrenade";
new String:mine[32]= "weapon_bumpmine";
new String:charge[32]= "weapon_breachcharge";
new String:shield[32]= "weapon_shield";
public Plugin myinfo =
{
	name = "give DangerZoneItems+",
	author = "sattyon",
	description = "simple plugin, give equipments",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	PrintToServer("#############")
	PrintToServer("#####sattyon#####")
	PrintToServer("#############")
	RegConsoleCmd("say"     , Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public void OnMapStart()
{
}

public Action:Command_Say(client, args)
{
	new String:text[64];
	GetCmdArg(1, text, sizeof(text));//発言内容を取得
	if((StrEqual(text, "!ta", true)))
	{
		Tagre(client);
	}
	if((StrEqual(text, "!mine", true)))
	{
		Mine(client);
	}
	if((StrEqual(text, "!charge", true)))
	{
		Charge(client);
	}
	if((StrEqual(text, "!shield", true)))
	{
		Shield(client);
	}
}

public Tagre(client)
{
	GivePlayerItem(client, tagre);
}

public Mine(client)
{
	GivePlayerItem(client, mine);
}

public Charge(client)
{
	GivePlayerItem(client, charge);
}

public Shield(client)
{
	GivePlayerItem(client, shield);
}