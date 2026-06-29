#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.6"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar cvar_melee_on, cvar_maxweaponstotal, cvar_maxweaponsclient;
bool bHooked = false;
int iMaxWeaponsTotal = 0, iMaxWeaponsClient = 0, numweaponstotal = 0, numweaponsclient[MAXPLAYERS + 1] = {0, ...};

public Plugin myinfo = 
{
    name = "[L4D2] Melee Wepons Menu",
    author = "dani1341(Edit. by BloodyBlade)",
    description = "Allows Clients To Get Melee Weapons From The Melee Weapon Menu",
    version = PLUGIN_VERSION,
    url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if(engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead2\" game.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
    //melee weapons menu cvar
    RegConsoleCmd("sm_melee", MeleeMenu);
    //plugin version
    CreateConVar("l4d2_melee_version", PLUGIN_VERSION, "[L4D2] Melee Wepons Menu plugin version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
    cvar_melee_on = CreateConVar("l4d2_melee_on", "1", "Enable/Disable plugin", CVAR_FLAGS);
    cvar_maxweaponstotal = CreateConVar("l4d2_melee_max", "32", "How much times all players can get melee weapons per map", CVAR_FLAGS);
    cvar_maxweaponsclient = CreateConVar("l4d2_melee_playermax", "3", "How much times one player can get melee weapons", CVAR_FLAGS);

    AutoExecConfig(true, "l4d2_melee");

    cvar_melee_on.AddChangeHook(OnPluginEnableChanged);
    cvar_maxweaponstotal.AddChangeHook(OnConVarsChanged);
    cvar_maxweaponsclient.AddChangeHook(OnConVarsChanged);
}

public void OnMapStart()
{
    Reset();
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void OnPluginEnableChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	iMaxWeaponsTotal = cvar_maxweaponstotal.IntValue;
	iMaxWeaponsClient = cvar_maxweaponsclient.IntValue;
}

void IsAllowed()
{
	bool bPluginOn = cvar_melee_on.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		HookEvent("mission_lost", Event_RoundEnd);
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("map_transition", Event_RoundEnd);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("mission_lost", Event_RoundEnd);
		UnhookEvent("round_end", Event_RoundEnd);
		UnhookEvent("map_transition", Event_RoundEnd);
	}
}

Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    Reset();
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    if(bHooked && client > 0 && !IsFakeClient(client))
    {
        numweaponsclient[client] = 0;
    }
}

public void OnClientDisconnect(int client)
{
    if(client > 0 && !IsFakeClient(client))
    {
        numweaponsclient[client] = 0;
        numweaponstotal--;
    }
}

Action MeleeMenu(int client, int args)
{
	if(!bHooked || !client || !IsClientInGame(client))
		return Plugin_Handled;

	if(GetClientTeam(client) != 2)
	{
		PrintToChat(client, "Melee Weapons Menu is only available to survivors.");
		return Plugin_Handled;
	}

	if(numweaponstotal >= iMaxWeaponsTotal) 
	{
		PrintToChat(client, "Limit of %i total melee weapons for this map has been reached.", GetConVarInt(cvar_maxweaponstotal));
		return Plugin_Handled;
	}

	if(numweaponsclient[client] >= iMaxWeaponsClient) 
	{
		PrintToChat(client, "You have reached your limit of %i for this map.", GetConVarInt(cvar_maxweaponsclient));
		return Plugin_Handled;
	}

	Menu menu = new Menu(MeleeMenuHandler);
	menu.SetTitle("Melee Weapons Menu");
	menu.AddItem("option1", "Baseball Bat");
	menu.AddItem("option2", "Crowbar");
	menu.AddItem("option3", "Cricket Bat");
	menu.AddItem("option4", "Electric Guitar");
	menu.AddItem("option5", "Fire Axe");
	menu.AddItem("option6", "Frying Pan");
	menu.AddItem("option7", "Golf Club");
	menu.AddItem("option8", "Katana");
	menu.AddItem("option9", "Knife");
	menu.AddItem("option10", "Machete");
	menu.AddItem("option11", "Magnum");
	menu.AddItem("option12", "Night Stick");
	menu.AddItem("option13", "Pitchfork");
	menu.AddItem("option14", "Shovel");
	menu.AddItem("option15", "Pistol");
	menu.AddItem("option16", "Riot Shield");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

int MeleeMenuHandler(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0: //Baseball Bat
			{
				//Give the player a Baseball Bat
				GivePlayerItem(client, "baseball_bat");
			}
			case 1: //Crowbar
			{
				//Give the player a Crowbar
				GivePlayerItem(client, "crowbar");
			}
			case 2: //Cricket Bat
			{
				//Give the player a Cricket Bat
				GivePlayerItem(client, "cricket_bat");
			}
			case 3: //Electric Guitar
			{
				//Give the player a Electric Guitar
				GivePlayerItem(client, "electric_guitar");
			}
			case 4: //Fire Axe
			{
				//Give the player a Fire Axe
				GivePlayerItem(client, "fireaxe");
			}
			case 5: //Frying Pan
			{
				//Give the player a Frying Pan
				GivePlayerItem(client, "frying_pan");
			}
			case 6: //Golf Club
			{
				//Give the player a Golf Club
				GivePlayerItem(client, "golfclub");
			}
			case 7: //Katana
			{
				//Give the player a Katana
				GivePlayerItem(client, "katana");
			}
			case 8: //Knife
			{
				//Give the player a Knife
				GivePlayerItem(client, "knife");
			}
			case 9: //Machete
			{
				//Give the player a Machete
				GivePlayerItem(client, "machete");
			}
			case 10: //Magnum
			{
				//Give the player a Magnum
				GivePlayerItem(client, "weapon_pistol_magnum");
			}
			case 11: //Night Stick
			{
				//Give the player a Night Stick
				GivePlayerItem(client, "tonfa");
			}
			case 12: //Pitchfork
			{
				//Give the player a Pistol
				GivePlayerItem(client, "pitchfork");
			}
			case 13: //Shovel
			{
				//Give the player a Riot Shield
				GivePlayerItem(client, "shovel");
			}
			case 14: //Pistol
			{
				//Give the player a Pistol
				GivePlayerItem(client, "weapon_pistol");
			}
			case 15: //Riot Shield
			{
				//Give the player a Riot Shield
				GivePlayerItem(client, "riotshield");
			}
		}
		numweaponstotal++;
		numweaponsclient[client]++;
	}
	return 0;
}

void Reset()
{
    numweaponstotal = 0;
    for(int i = 1; i <= MAXPLAYERS; i++)
    {
        numweaponsclient[i] = 0;
    }
}
