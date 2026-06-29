#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "2.0"

static char Items[][][] = 
{
	{"!ta", "weapon_tagrenade", "1"},
	{"!mine", "weapon_bumpmine", "1"},
	{"!charge", "weapon_breachcharge", "1"},
	{"!shield;!riot", "weapon_shield", "1"},
	{"!para;!parachute", "parachute", "0"},
	{"!exojump;!exo;jump", "exojump", "0"}
};

stock void GiveSomething(int client = -1, char[] something, bool equip = false) 
{
	if(client == -1)
		return;
	
	if(strlen(something) < 1)
		return;
	
	int item = GivePlayerItem(client, something);
	
	if(item == -1) 
		return;
	
	if(equip)
	{
		//EquipPlayerWeapon(client, item);
		FakeClientCommand(client, "use %s", something);
	}
}

public Plugin myinfo =
{
	name = "give DangerZoneItems+",
	author = "sattyon, KGB1st",
	description = "simple plugin, give equipments",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2698611&postcount=1"
};

public void OnPluginStart()
{
	RegConsoleCmd("say", Processing_Say);
	RegConsoleCmd("say_team", Processing_Say);
}

public Action Processing_Say(int client, any args)
{
	char text[32];
	GetCmdArg(1, text, sizeof(text));
	
	if(strlen(text) < 3)
		return;
	
	for(int i = 0; i < sizeof(Items); ++i) 
	{
		char Buf[3][32]; ExplodeString(Items[i][0], ";", Buf, sizeof(Buf), sizeof(Buf[]));
		// 
		// ReplyToCommand(client, "[SM] input text => %s, Buf => %s, Items[i][1] => %s", text, Buf[0], Items[i][1]);
		// 
		// [SM] input text => !ta, Buf => !ta, Items[i][1] => weapon_tagrenade
		// [SM] input text => !ta, Buf => !mine, Items[i][1] => weapon_bumpmine
		// [SM] input text => !ta, Buf => !charge, Items[i][1] => weapon_breachcharge
		// [SM] input text => !ta, Buf => !shield, Items[i][1] => weapon_shield
		// [SM] input text => !ta, Buf => !para, Items[i][1] => parachute
		// [SM] input text => !ta, Buf => !exojump, Items[i][1] => exojump
		// 
		for(int j = 0; j < sizeof(Buf); ++j)
		{
			if(StrEqual(text, Buf[j], true))
			{
				// ReplyToCommand(client, "[SM] input text => %s, Buf => %s, Items[i][1] => %s", text, Buf[0], Items[i][1]);
				GiveSomething(client, Items[i][1], view_as<bool>(StringToInt(Items[i][2])));
				break;
			}
		}
	}
	
	
}

public void OnMapStart()
{
	//PrintToServer("[SM] sizeofs: %d, %d", sizeof(Items), sizeof(Items[]));
}
