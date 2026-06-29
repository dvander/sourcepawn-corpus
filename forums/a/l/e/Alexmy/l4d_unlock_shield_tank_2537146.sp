#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

#define       DAMAGE_ON   2
#define       DAMAGE_OFF  0
Handle        sm_shield_tank_rock = null, sm_shield_melee = null;
bool          advertising_tank_rock,      advertising_melee;
char          class[100],                 weapon[64];

public Plugin myinfo = 
{
	name = "[L4D] Unlock Shield Tank",
	author = "AlexMy",
	description = "Танк использует защиту от урона, при использование какого либо оружия",
	version = "1.5",
	url = ""
};

public void OnPluginStart()
{
	sm_shield_tank_rock = CreateConVar("sm_shield_tank_rock","1", "Защита при броске камня. 0:Выкл. 1:Вкл.", FCVAR_NOTIFY);
	sm_shield_melee     = CreateConVar("sm_shield_melee",    "1", "Защита в ближнем бою     0:Выкл. 1:Вкл.", FCVAR_NOTIFY);
	
	HookEvent("ability_use",                Event_ability_use);
	HookEvent("player_incapacitated_start", Event_player_incapacitated);
	
	HookEvent("tank_spawn",                 Event_ResetBool);
	HookEvent("tank_killed",                Event_ResetBool);
}

public void Event_ability_use(Event event, const char [] name, bool dontBroadcast)
{
	if(!GetConVarInt(sm_shield_tank_rock))return;
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		{
			if(client)
			{
				GetClientModel(client, class, sizeof(class));
				if (StrContains(class, "hulk", false) != -1)
				{
					GetEventString(event, "weapon", weapon, sizeof(weapon));
					if(!StrEqual(weapon, "tank_rock"))
					{
						CreateTimer(4.0, Timer_takedamage, client, SetEntProp(client, Prop_Data, "m_takedamage", DAMAGE_OFF, 1));
						{
							if(advertising_tank_rock)return;
							{
								PrintToChatAll("\x05Танк \x03включил защиту при броске камня\x01!!!");
								advertising_tank_rock = true;
							}
						}
					}
				}
			}
		}
	}
}
public void Event_player_incapacitated(Event event, const char [] name, bool dontBroadcast)
{
	if(!GetConVarInt(sm_shield_melee))return;
	{
		int client = GetClientOfUserId(event.GetInt("attacker"));
		{
			if(client)
			{
				GetClientModel(client, class, sizeof(class));
				if (StrContains(class, "hulk", false) != -1)
				{
					GetEventString(event, "weapon", weapon, sizeof(weapon));
					if(!StrEqual(weapon, "melee") || !StrEqual(weapon, "tank_claw"))
					{
						CreateTimer(4.0, Timer_takedamage, client,  SetEntProp(client, Prop_Data, "m_takedamage", DAMAGE_OFF, 1));
						{
							if(advertising_melee)return;
							{
								PrintToChatAll("\x05Танк \x03включил защиту в ближнем бою\x01!!!");
								advertising_melee = true;
							}
						}
					}
				}
			}
		}
	}
}
public void Event_ResetBool(Event event, const char[] name, bool dontBroadcast)
{
	advertising_melee = false; advertising_tank_rock = false;
}
public Action Timer_takedamage(Handle timer, any client)
{
	if(client <= 0 || client > GetMaxClients() || !IsValidEntity(client) || !IsClientInGame(client))return;
	{
		SetEntProp(client, Prop_Data, "m_takedamage", DAMAGE_ON, 1);
	}
	return;
}