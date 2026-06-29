#include <sourcemod>
#include <morecolors>
//#include <cstrike>

new bonushealthON[MAXPLAYERS+1]; //1 = ON | 2 = OFF
new bonusarmorON[MAXPLAYERS+1]; //1 = ON | 2 = OFF
new regenerationON[MAXPLAYERS+1]; //1 = ON | 2 = OFF
new gravityON[MAXPLAYERS+1]; //1 = ON | 2 = OFF
new maxHP[MAXPLAYERS+1];

new String:plugintag[100];
new String:titlename[100];

new Handle:menu_title;
new Handle:plugin_tag;
new Handle:health_add;
new Handle:set_armor;
new Handle:regen_time;
new Handle:regen_value;
new Handle:gravity_value;
new Handle:TIMER_REGEN = INVALID_HANDLE;

public Plugin:myinfo =  
{  
	name = "VIP menu for CS:S",  
	author = "Arkarr",  
	description = "VIP menu for donator",  
	version = "1.0",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{
	RegAdminCmd("sm_vip", Vip_Menu, ADMFLAG_CUSTOM3);
	
	//General config
	plugin_tag = CreateConVar("sm_VIP_plugin_tag", "{red}[[HvG] VIP]", "What should the plugin tag ?");
	menu_title = CreateConVar("sm_VIP_menu_title", "[HvG] VIP", "What should the name of the menu ?");
	
	//Health config
	health_add = CreateConVar("sm_VIP_bonus_health", "30", "How much bonus health should a player have ? NOTE: Bonues health are added when player spawn.");
	
	//Armor config
	set_armor = CreateConVar("sm_VIP_set_armor", "100", "How much armor should a player have ? NOTE: Armor are set when player spawn.");
	
	//Health Regen config
	regen_time = CreateConVar("sm_VIP_regen_time", "10", "After how much time (in seconds) a player regenerate.");
	regen_value = CreateConVar("sm_VIP_regen_value", "5", "How much HP should a player regenerate");
	
	//Gravity Config
	gravity_value = CreateConVar("sm_VIP_gravity_value", "0.4", "Set gravity value. 0.1 = extrem low | 2.0 = extrem high");
	
	AutoExecConfig(true,"CSS_VIP_menu");
	
	GetConVarString(plugin_tag, plugintag, sizeof(plugintag));
	GetConVarString(menu_title, titlename, sizeof(titlename));
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre)
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	maxHP[client] = GetClientHealth(client);
	
	if(bonushealthON[client] == 1)
	{
		AddHealth(client);
	}
	
	if(bonusarmorON[client] == 1)
	{
		AddArmor(client);
	}
	
}

public MenuHandler1(Handle:menu, MenuAction:action, client, param2)  
{  
    new String:info[32];  
    GetMenuItem(menu, param2, info, sizeof(info));  
    
    if (action == MenuAction_Select)  
    {
        param2++; 
        if(param2 == 1) 
        {
			if(bonushealthON[client] == 1)
			{
				bonushealthON[client] = 0;
				CPrintToChat(client, "%s {default}Your {green}bonus health{default} is now {red}OFF{default} !", plugintag);
			}
			else
			{
				bonushealthON[client] = 1;
				CPrintToChat(client, "%s {default}Your {green}bonus health{default} is now {green}ON{default} !", plugintag);
			}
        }  
        else if(param2 == 2) 
        {
			if(bonusarmorON[client] == 1)
			{
				bonusarmorON[client] = 0;
				CPrintToChat(client, "%s {default}Your {green}armor bonus{default} is now {red}OFF{default} !", plugintag);
			}
			else
			{
				bonusarmorON[client] = 1;
				CPrintToChat(client, "%s {default}Your {green}armor bonus{default} is now {green}ON{default} !", plugintag);
			}
        }  
        else if(param2 == 3) 
        {
			if(regenerationON[client] == 1)
			{
				regenerationON[client] = 0;
				CPrintToChat(client, "%s {default}Your {green}regenration health{default} is now {red}OFF{default} !", plugintag);
				
				if(TIMER_REGEN != INVALID_HANDLE) 
				{ 
					KillTimer(TIMER_REGEN); 
					TIMER_REGEN = INVALID_HANDLE; 
				}
			}
			else
			{
				regenerationON[client] = 1;
				CPrintToChat(client, "%s {default}Your {green}regenration health{default} is now {green}ON{default} !", plugintag);
				
				TIMER_REGEN = CreateTimer(GetConVarFloat(regen_time), Regen_Timer, GetClientSerial(client), TIMER_REPEAT);
			}
        }  
        else if(param2 == 4) 
        {
			if(IsValidClient(client))
			{
				if(gravityON[client] == 1)
				{
					gravityON[client] = 0;
					CPrintToChat(client, "%s {default}Your {green}gravity{default} is now {red}OFF{default} !", plugintag);
					SetEntityGravity(client, 1.0);
				}
				else
				{
					gravityON[client] = 1;
					CPrintToChat(client, "%s {default}Your {green}armor bonus{default} is now {green}ON{default} !", plugintag);
					SetEntityGravity(client, GetConVarFloat(gravity_value));
				}
			}
        } 
    } 
    
    else if (action == MenuAction_End)  
    {  
        CloseHandle(menu);  
    } 
}

public Action:Vip_Menu(client, args)  
{
	new Handle:menu = CreateMenu(MenuHandler1); 
	SetMenuTitle(menu, titlename); 
	AddMenuItem(menu, "option1", "Health Bonus"); 
	AddMenuItem(menu, "option2", "More armor"); 
	AddMenuItem(menu, "option3", "HP regeneration"); 
	AddMenuItem(menu, "option4", "Low Gravity"); 
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

stock AddHealth(client)
{
	if(IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_iHealth", GetClientHealth(client) + GetConVarInt(health_add));
	}
}

stock AddArmor(client)
{
	if(IsValidClient(client))
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", GetConVarInt(set_armor));
	}
}

public Action:Regen_Timer(Handle:timer, any:user)  
{
	new client = GetClientFromSerial(user);
	
	if(IsValidClient(client))
	{
		if(bonushealthON[client] == 1)
		{
			if(maxHP[client] + GetConVarInt(health_add) > GetClientHealth(client) + GetConVarInt(regen_value))
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetClientHealth(client) + GetConVarInt(regen_value));
			}
		}
		else
		{
			if(maxHP[client] > GetClientHealth(client) + GetConVarInt(regen_value))
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetClientHealth(client) + GetConVarInt(regen_value));
			}
		}
		
	}
}

//Check if client is valid :
stock bool:IsValidClient(iClient, bool:bReplay = true) {
    if(iClient <= 0 || iClient > MaxClients)
        return false;
    if(!IsClientInGame(iClient))
        return false;
    if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
        return false;
    return true;
}
