#pragma semicolon 1
#pragma newdecls required
#include <sourcemod> 
#include <sdktools>

#define PLUGIN_VERSION "1.0" 
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

#define MODEL_BASEBALLBAT_W "models/weapons/melee/w_bat.mdl"
#define MODEL_BASEBALLBAT_V "models/weapons/melee/v_bat.mdl"
#define MODEL_CRICKETBAT_W "models/weapons/melee/w_cricket_bat.mdl"
#define MODEL_CRICKETBAT_V "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_CROWBAR_W "models/weapons/melee/w_crowbar.mdl"
#define MODEL_CROWBAR_V "models/weapons/melee/v_crowbar.mdl"
#define MODEL_ELECTRICGUITAR_W "models/weapons/melee/w_electric_guitar.mdl"
#define MODEL_ELECTRICGUITAR_V "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_FIREAXE_W "models/weapons/melee/w_fireaxe.mdl"
#define MODEL_FIREAXE_V "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_FRYINGPAN_W "models/weapons/melee/w_frying_pan.mdl"
#define MODEL_FRYINGPAN_V "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_GOLFCLUB_W "models/weapons/melee/w_golfclub.mdl"
#define MODEL_GOLFCLUB_V "models/weapons/melee/v_golfclub.mdl"
#define MODEL_KATANA_W "models/weapons/melee/w_katana.mdl"
#define MODEL_KATANA_V "models/weapons/melee/v_katana.mdl"
#define MODEL_KNIFE_W "models/w_models/weapons/w_knife_t.mdl"
#define MODEL_KNIFE_V "models/v_models/v_knife_t.mdl"
#define MODEL_MACHETE_W "models/weapons/melee/w_machete.mdl"
#define MODEL_MACHETE_V "models/weapons/melee/v_machete.mdl"
#define MODEL_TONFA_W "models/weapons/melee/w_tonfa.mdl"
#define MODEL_TONFA_V "models/weapons/melee/v_tonfa.mdl"
#define MODEL_RIOTSHIELD_W "models/weapons/melee/w_riotshield.mdl"
#define MODEL_RIOTSHIELD_V "models/weapons/melee/v_riotshield.mdl"
#define MODEL_SHOVEL_W "models/weapons/melee/w_shovel.mdl"
#define MODEL_SHOVEL_v "models/weapons/melee/v_shovel.mdl" 
#define MODEL_PITCHFORK_W "models/weapons/melee/w_pitchfork.mdl"
#define MODEL_PITCHFORK_V "models/weapons/melee/v_pitchfork.mdl"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public Plugin myinfo =  
{ 
	name = "[L4D2]MeleeWeponsMenu", 
	author = "dani1341", 
	description = "Allows Clients To Get Melee Weapons From The Melee Weapon Menu", 
	version = PLUGIN_VERSION, 
	url = "" 
}

ConVar cvar_plugin_on, cvar_maxweaponstotal, cvar_maxweaponsclient, cvar_meleeannounce;
int iCvarMaxWeaponsTotal = 0, iCvarMaxWeaponsClient = 0, iCvarAnnounce = 0, numweaponstotal = 0, numweaponsclient[MAXPLAYERS + 1] = {0, ...};
bool bCvarPlugonOn = false, bHooked = false;

public void OnPluginStart() 
{
	RegConsoleCmd("sm_melee", MeleeMenu);
	RegConsoleCmd("sm_ml", MeleeMenu);
	CreateConVar("melee_version", PLUGIN_VERSION, "L4D 2 Melee Weapons Menu version", CVAR_FLAGS|FCVAR_DONTRECORD);
	cvar_plugin_on = CreateConVar("melee_on", "1", "Enable/Disable plugin", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvar_maxweaponstotal = CreateConVar("melee_max", "40", "How much times all players can get melee weapons per map", CVAR_FLAGS);
	cvar_maxweaponsclient = CreateConVar("melee_playermax", "10", "How much times one player can get melee weapons", CVAR_FLAGS);
	cvar_meleeannounce = CreateConVar("melee_announce", "3", "Should the plugin advertise itself? 1 chat box message, 2 hint text message, 3 both, 0 for none.",CVAR_FLAGS,true,0.0,true,3.0);
	cvar_plugin_on.AddChangeHook(ConVarPluginOnChanged);
	cvar_maxweaponstotal.AddChangeHook(ConVarsChanged);
	cvar_maxweaponsclient.AddChangeHook(ConVarsChanged);
	cvar_meleeannounce.AddChangeHook(ConVarsChanged);
	AutoExecConfig(true, "l4d2_melee"); 
} 

public void OnMapStart() 
{ 
	PrecacheModel(MODEL_BASEBALLBAT_W, true);
	PrecacheModel(MODEL_BASEBALLBAT_V, true);
	PrecacheModel(MODEL_CRICKETBAT_W, true);
	PrecacheModel(MODEL_CRICKETBAT_V, true);
	PrecacheModel(MODEL_CROWBAR_W, true);
	PrecacheModel(MODEL_CROWBAR_V, true);
	PrecacheModel(MODEL_ELECTRICGUITAR_W, true);
	PrecacheModel(MODEL_ELECTRICGUITAR_V, true);
	PrecacheModel(MODEL_FIREAXE_W, true);
	PrecacheModel(MODEL_FIREAXE_V, true);
	PrecacheModel(MODEL_FRYINGPAN_W, true);
	PrecacheModel(MODEL_FRYINGPAN_V, true);
	PrecacheModel(MODEL_GOLFCLUB_W, true);
	PrecacheModel(MODEL_GOLFCLUB_V, true);
	PrecacheModel(MODEL_KATANA_W, true);
	PrecacheModel(MODEL_KATANA_V, true);
	PrecacheModel(MODEL_GOLFCLUB_W, true);
	PrecacheModel(MODEL_GOLFCLUB_V, true);
	PrecacheModel(MODEL_KNIFE_W, true);
	PrecacheModel(MODEL_KNIFE_V, true);
	PrecacheModel(MODEL_MACHETE_W, true);
	PrecacheModel(MODEL_MACHETE_V, true);
	PrecacheModel(MODEL_TONFA_W, true);
	PrecacheModel(MODEL_TONFA_V, true);
	PrecacheModel(MODEL_RIOTSHIELD_W, true);
	PrecacheModel(MODEL_RIOTSHIELD_V, true);
	PrecacheModel(MODEL_SHOVEL_W, true);
	PrecacheModel(MODEL_SHOVEL_v, true);
	PrecacheModel(MODEL_PITCHFORK_W, true);
	PrecacheModel(MODEL_PITCHFORK_V, true);
	numweaponstotal = 0;
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    iCvarMaxWeaponsTotal = cvar_maxweaponstotal.IntValue;
    iCvarMaxWeaponsClient = cvar_maxweaponsclient.IntValue;
    iCvarAnnounce = cvar_meleeannounce.IntValue;
}

void IsAllowed()
{
	bCvarPlugonOn = cvar_plugin_on.BoolValue;
	if (bCvarPlugonOn && !bHooked)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("round_start", Event_RoundEnd);
		HookEvent("mission_lost", Event_RoundEnd);
		HookEvent("round_end", Event_RoundEnd);
		HookEvent("map_transition", Event_RoundEnd);
	}
	else if (!bCvarPlugonOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("round_start", Event_RoundEnd);
		UnhookEvent("mission_lost", Event_RoundEnd);
		UnhookEvent("round_end", Event_RoundEnd);
		UnhookEvent("map_transition", Event_RoundEnd);
	}
}

Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{ 
	numweaponstotal = 0; 
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			numweaponsclient[i] = 0;
		}
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	if (client > 0 && !IsFakeClient(client) && iCvarAnnounce > 0)
	{
		CreateTimer(30.0, AnnounceMelee, client);
	}
}

Action MeleeMenu(int client, int args) 
{ 
	if(client > 0 && IsClientInGame(client))
	{	
		if(GetClientTeam(client) != 2) 
		{ 
			PrintToChat(client, "Melee Weapons Menu is only available to survivors."); 
			return Plugin_Handled; 
		} 

		if(numweaponstotal >= iCvarMaxWeaponsTotal)  
		{ 
			PrintToChat(client, "Limit of %i total melee weapons for this map has been reached.", iCvarMaxWeaponsTotal);
			return Plugin_Handled; 
		} 

		if(numweaponsclient[client] >= iCvarMaxWeaponsClient)  
		{ 
			PrintToChat(client, "You have reached your limit of %i for this map.", iCvarMaxWeaponsClient); 
			return Plugin_Handled; 
		}

		if(!IsPlayerAlive(client))  
		{
			PrintToChat(client, "You will be alive to open this menu."); 
			return Plugin_Handled; 
		}

		Melee(client);
	}
	return Plugin_Handled; 
} 

Action Melee(int clientId)
{ 
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
	menu.AddItem("option13", "Pistol"); 
	menu.AddItem("option14", "Pitchfork");
	menu.AddItem("option15", "Shovel"); 
	menu.AddItem("option16", "Riot Shield"); 
	menu.ExitButton = true; 
	menu.Display(clientId, MENU_TIME_FOREVER);
	return Plugin_Handled; 
} 

Action AnnounceMelee(Handle timer, any client)
{
	switch(iCvarAnnounce)
	{
		case 1:
		{
			PrintToChatAll("[SM] If you want a melee weapon write !melee or /melee in chat");
		}
		case 2:
		{
			PrintHintTextToAll("If you want a melee weapon write !melee or /melee in chat");
		}
		case 3:
		{
			PrintToChatAll("[SM] If you want a melee weapon write !melee or /melee in chat");
			PrintHintTextToAll("If you want a melee weapon write !melee or /melee in chat");
		}
	}
	return Plugin_Stop;
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
				GivePlayerItem(client, "gmachete"); 
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
			case 12: //Pistol 
			{
				//Give the player a Pistol 
				GivePlayerItem(client, "weapon_pistol"); 
			}
			case 13: //Pitchfork 
			{ 
				//Give the player a Pitchfork 
				GivePlayerItem(client, "pitchfork"); 
			}
			case 14: //Shovel
			{ 
				//Give the player a Shovel 
				GivePlayerItem(client, "shovel"); 
			}
			case 15: //Riot Shield 
			{ 
				//Give the player a Riot Shield 
				GivePlayerItem(client, "weapon_riotshield"); 
			} 
		} 
		numweaponstotal++; 
		numweaponsclient[client]++; 
	}
	return 0;
}
