//Includes
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <emitsoundany>

Handle hHudTextA;


#define MAX_STEAMAUTH_LENGTH 21 
#define MAX_COMMUNITYID_LENGTH 18 
#pragma tabsize 0
//Definitions 
#define PLUGIN_VERSION 	"1.1"

new token[64];
bool ffa_on = false;


ConVar g_mvip;
ConVar g_vip;
ConVar g_player;


public Plugin:myinfo =
{
	name = "Shop",
	author = "DeadSwim",
	description = "Simple SHOP",
	version = PLUGIN_VERSION,
	url = "nourl"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_shop", displaymenu); 
	RegConsoleCmd("sm_addtoken", Command_Donate);
 
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd); 
	HookEvent("player_team", EventPlayerTeam);
	
    hHudTextA = CreateHudSynchronizer();

	g_mvip = CreateConVar("mvip_get_tokens", "8", "MVIP get tokens");
	g_vip = CreateConVar("vip_get_tokens", "6", "VIP get tokens");
	g_player = CreateConVar("player_get_tokens", "5", "Player get tokens");
}

public Action displaymenu(int client, int args)
{
	if(IsPlayerAlive(client))
	{
	shop_menu(client);
	return Plugin_Handled;
	}else{
	PrintToChat(client, " \x01[\x04Shop\x01]  \x04Must be alive and in game!");
	}

	return Plugin_Handled;
}

//songs
public OnConfigsExecuted()
{
    AddFileToDownloadsTable("sound/Shop/321go.mp3");
    PrecacheSoundAny("Shop/321go.mp3");
	PrecacheSound("Shop/321go.mp3", true);
}
public OnMapStart() {
    AddFileToDownloadsTable("sound/Shop/321go.mp3");
    PrecacheSoundAny("Shop/321go.mp3");
	
	CreateTimer(1.0, hud_ref, _, TIMER_REPEAT);
}
//end round

public Action Event_RoundEnd(Handle:event, const char[] sName, bool bDontBroadcast) 
{ 
	if(ffa_on)
    {
	FindConVar("mp_teammates_are_enemies").SetInt(0);
    ffa_on = false;
    }
}	
// Change team / restart tokens
public Action EventPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
				new client_id = GetEventInt(event, "userid");
				new client = GetClientOfUserId(client_id);
				
				new aktualni_tokeny = 0;
			    token[client]=aktualni_tokeny;
} 
// HUD with tokens
public Action hud_ref(Handle:timer, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsClientObserver(i))
        {
		    new ck = token[i]
            SetHudTextParams(-1.0, -0.01, 1.0, 255, 0, 0, 255, 0, 0.0, 0.25, 0.25);
            ShowSyncHudText(i, hHudTextA, "Tokens: %d | Use /shop", ck);
        }
    }
}
// Giving tokens
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int attacker = GetClientOfUserId(event.GetInt("attacker")); 

	if(mvip_player(attacker)){

	int mvip = GetConVarInt(g_mvip);

	new ck = token[attacker];
	new aktualni_tokeny = ck + mvip;
	token[attacker]=aktualni_tokeny;

	PrintToChat(attacker, " \x01[\x04Shop\x01] \x04You get \x01%i\x04 tokens for \x01/shop\x04 for \x01 kill\x04. (M-VIP Bonus)", mvip);
	}else if(vip_player(attacker)){

	int vip = GetConVarInt(g_vip);

	new ck = token[attacker];
	new new_tokens = ck + vip;
	token[attacker]=new_tokens;

	PrintToChat(attacker, " \x01[\x04Shop\x01] \x04You get \x01%i\x04 tokens for \x01/shop\x04 for \x01 kill\x04. (VIP Bonus)", vip);
	}else{

	int player = GetConVarInt(g_player);
	
	new ck = token[attacker];
	new new_tokens = ck + player;
	token[attacker]=new_tokens;
	PrintToChat(attacker, " \x01[\x04Shop\x01] \x04You get \x01%i\x04 tokens for \x01/shop\x04 for \x01 kill\x04.", player);
	}
}
// Add player tokens
public Action Command_Donate(client, args)
{
 if(player_admin(client))
 {
    if (args < 1)
    {
        ReplyToCommand(client, " \x01[\x04Shop\x01]  \x04/addtokens <Name> <Value> <Reason>");
        return Plugin_Handled;
    }

    decl String:sArg[64];
    GetCmdArg(1, sArg, sizeof(sArg));
    
    new Player = -1;
    
    for(new i = 1; i <= MaxClients ; i++)
    {
        if(!IsClientConnected(i)) continue;

        decl String:sName[32];
        GetClientName(i, sName, sizeof(sName));

        if(StrContains(sName, sArg, false) != -1) Player = i;
		

    }
    
    if(Player == -1)
    {
        PrintToChat(client, "[Shop] Wrong name: \x04%s\x01", sArg);
        return Plugin_Handled;
    }
			char pocet[64];
			GetCmdArg(2, pocet, sizeof(pocet));
			int d1 = StringToInt(pocet);
			
			char duvod[64];
			GetCmdArg(3, duvod, sizeof(duvod));
			

			
			new ck = token[Player];
			new aktualni_tokeny = ck + d1;
			token[Player]=aktualni_tokeny;
			
			PrintToChatAll(" \x01[\x04Shop\x01] \x04Admin \x01%N \x04add tokens to player \x01%N \x01(%d)\x04!", client, Player, d1);
			
    return Plugin_Handled;
 }else{
 PrintToChat(client, " \x01[\x04Shop\x01]  \x04You don't have permission for this command!");
 }
 return Plugin_Handled;
}  
// Shop menu
shop_menu(client)
{
	new Handle:menu = CreateMenu(shops, MenuAction_Select | MenuAction_End);
	new ck = token[client];
	SetMenuTitle(menu, "Shop\nTokens: %d", ck);

	AddMenuItem(menu, "gravity", "Gravity [20 T]");
	AddMenuItem(menu, "wh", "WH grenade [55 T]");
	AddMenuItem(menu, "granade", "Flash, Smoke, He [25 T]");
	AddMenuItem(menu, "hp", "More HP [100 T]");
	if(vip_player(client))
	{
	AddMenuItem(menu, "terminator", "TERMINATOR [300 T] [VIP]");
	AddMenuItem(menu, "heal", "Heal [VIP] [60 T]");
	AddMenuItem(menu, "speed", "Speed [VIP] [120 T]");
	AddMenuItem(menu, "glock8", "Glock with 8 Ammo [VIP] [80 T]");
	}else{
	AddMenuItem(menu, "terminator", "TERMINATOR [300 T] [VIP]", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "heal", "Heal [VIP] [60 T]", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "speed", "Speed [VIP] [120 T]", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "glock8", "Glock with 8 Ammo [VIP] [80 T]", ITEMDRAW_DISABLED);
	}
	if(mvip_player(client))
	{
	AddMenuItem(menu, "glock30", "Glock with 30 Ammo [M-VIP] [100 T]");
	AddMenuItem(menu, "ffa", "Turn ON FFA [M-VIP] [200 T]");
	}else{
	AddMenuItem(menu, "glock30", "Glock with 30 Ammo [M-VIP] [100 T]", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "ffa", "Turn ON FFA [M-VIP] [200 T]", ITEMDRAW_DISABLED);
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public shops(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{

			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			if (StrEqual(item, "gravity"))
			{
			    new ck = token[param1];
				if (ck>=20)
				{
				
				new aktualni_tokeny = ck - 20;
			    token[param1]=aktualni_tokeny;
				
				ServerCommand("sm_gravity \"%N\" 0.5", param1);
				
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01gravity\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
			}
			else if (StrEqual(item, "wh"))
			{
				new ck = token[param1];
				if (ck>=55)
				{
				new aktualni_tokeny = ck - 55;
			    token[param1]=aktualni_tokeny;
				
				GivePlayerItem(param1,"weapon_tagrenade");
				
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01WH grenade\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
			}
			else if (StrEqual(item, "granade"))
			{
				new ck = token[param1];
				if (ck>=25)
				{
				new aktualni_tokeny = ck - 25;
			    token[param1]=aktualni_tokeny;
				
				GivePlayerItem(param1, "weapon_flashbang");
				GivePlayerItem(param1, "weapon_smokegrenade");
				GivePlayerItem(param1, "weapon_hegrenade");
				
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01Flash, Smoke, He\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
			}
			else if (StrEqual(item, "hp"))
			{
				new ck = token[param1];
				if (ck>=100)
				{
				new aktualni_tokeny = ck - 100;
			    token[param1]=aktualni_tokeny;

				new health = GetClientHealth(param1);
				new nowhealth = health + 50;
				SetEntityHealth(param1, nowhealth);

				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01More HP\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
			}
			else if (StrEqual(item, "terminator"))
			{
				if(vip_player(param1))
				{
				new ck = token[param1];
				if (ck>=300)
				{
				new aktualni_tokeny = ck - 300;
			    token[param1]=aktualni_tokeny;

				new nowhealth = 650;
				SetEntityHealth(param1, nowhealth);
				ServerCommand("sm_gravity \"%N\" 0.5", param1);
				
				new Float:speed = GetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue");
				new Float:nowspeed = speed + 0.5;		
				SetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue", nowspeed);
				
				GivePlayerItem(param1,"weapon_tagrenade");
				GivePlayerItem(param1, "weapon_flashbang");
				GivePlayerItem(param1, "weapon_smokegrenade");
				GivePlayerItem(param1, "weapon_hegrenade");
				
				FindConVar("mp_teammates_are_enemies").SetInt(1);
				
				EmitSoundToAllAny("Shop/321go.mp3", _, _, _, _, 0.25);

				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01TERMINATOR\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
				}
			}
			else if (StrEqual(item, "heal"))
			{
				if(vip_player(param1))
				{
				new ck = token[param1];
				if (ck>=60)
				{
				new aktualni_tokeny = ck - 60;
			    token[param1]=aktualni_tokeny;

				new nowhealth = 100;
				SetEntityHealth(param1, nowhealth);

				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01Heal\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
				}
			}
			else if (StrEqual(item, "speed"))
			{
				if(vip_player(param1))
				{
				new ck = token[param1];
				if (ck>=120)
				{
				new aktualni_tokeny = ck - 120;
			    token[param1]=aktualni_tokeny;

				new Float:speed = GetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue");
				new Float:nowspeed = speed + 0.5;		
				SetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue", nowspeed);

				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01Big Speed\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
				}
			}
			else if (StrEqual(item, "glock8"))
			{
				if(vip_player(param1))
				{
				new ck = token[param1];
				if (ck>=80)
				{
				new aktualni_tokeny = ck - 80;
			    token[param1]=aktualni_tokeny;

				new Pistol_Eagle1;
				Pistol_Eagle1 = GivePlayerItem(param1, "weapon_glock");
				SetEntProp(Pistol_Eagle1, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
				SetEntProp(Pistol_Eagle1, Prop_Send, "m_iClip1", 8);

				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01Glock with 8 Ammo\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
				}
			}
			else if (StrEqual(item, "glock30"))
			{
				if(mvip_player(param1))
				{
				new ck = token[param1];
				if (ck>=100)
				{
				new aktualni_tokeny = ck - 100;
			    token[param1]=aktualni_tokeny;

				new Pistol_Eagle2;
				Pistol_Eagle2 = GivePlayerItem(param1, "weapon_glock");
				SetEntProp(Pistol_Eagle2, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
				SetEntProp(Pistol_Eagle2, Prop_Send, "m_iClip1", 30);

				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01Glock with 30 Ammo\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
				}
			}
			else if (StrEqual(item, "ffa"))
			{
				if(mvip_player(param1))
				{
				new ck = token[param1];
				if (ck>=200)
				{
				new aktualni_tokeny = ck - 200;
			    token[param1]=aktualni_tokeny;

				FindConVar("mp_teammates_are_enemies").SetInt(1);

				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Item \x01Turn ON FFA\x04, was bought!");  
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04Your current number of tokens is \x01%d\x04.", aktualni_tokeny);

                ffa_on = true;
				}else{
				new aktualni_tokeny = token[param1];
				PrintToChat(param1, " \x01[\x04Shop\x01] \x04You don't have enough Tokens, your current number \x01%d\x04.", aktualni_tokeny);  
				}
				}
			}
		}

		case MenuAction_End:
		{
			CloseHandle(menu);

		}

	}
}

// Bool check permission
bool:vip_player(client)
{
	return CheckCommandAccess(client, "", ADMFLAG_CUSTOM6, true);
}
bool:player_admin(client)
{
	return CheckCommandAccess(client, "", ADMFLAG_ROOT, true);
}
bool:mvip_player(client)
{
	return CheckCommandAccess(client, "", ADMFLAG_CUSTOM5, true);
}