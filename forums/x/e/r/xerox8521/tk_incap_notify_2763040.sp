#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

#define TEAM_SURVIVORS  2


public Plugin myinfo =
{
	name = "[L4D / L4D2] Teamkill / Incap Notification",
	author = "XeroX",
	description = "Allows the injection of Adrenaline on Teammates",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2763040&postcount=2"
}

public void OnPluginStart()
{
    CreateConVar("tk_incap_notification_version", PLUGIN_VERSION, "Version of the Plugin", FCVAR_NOTIFY);

    HookEvent("player_incapacitated", Event_PlayerIncapacitated);
    HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if(!victim)
        return;

    if(GetClientTeam(victim) != TEAM_SURVIVORS)
        return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));

    if(attacker > 0 && attacker < MaxClients)
    {
        if(IsClientInGame(attacker))
        {
            PrintToChatAll("\x05%N \x01killed \x05%N", attacker, victim);
        }
    }
    else
    {
        int attackerid = event.GetInt("attackerentid");
        if(attackerid > 0 && IsValidEntity(attackerid))
        {
            if(!HasEntProp(attackerid, Prop_Send, "m_rage"))
            {
                PrintToChatAll("\x05Infected \x01killed \x05%N", victim);
            }
            else if(HasEntProp(attackerid, Prop_Send, "m_rage"))
            {
                PrintToChatAll("\x05Witch \x01killed \x05%N", victim);
            }
            else
            {
                char szClassName[32];
                GetEntityClassname(attackerid, szClassName, sizeof(szClassName));
                PrintToChatAll("\x05%s \x01killed \x05%N", szClassName, victim);
            }
        }
        else
        {
            PrintToChatAll("\x05%N \x01died", victim);
        }
    }
}


public void Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if(!victim)
        return;
    
    if(GetClientTeam(victim) != TEAM_SURVIVORS)
        return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if(attacker > 0 && attacker < MaxClients)
    {
        if(IsClientInGame(attacker))
        {
            PrintToChatAll("\x05%N \x01incapacitated \x05%N", attacker, victim);
        }
    }
    else
    {
        int attackerid = event.GetInt("attackerentid");
        if(attackerid > 0 && IsValidEntity(attackerid))
        {
            if(!HasEntProp(attackerid, Prop_Send, "m_rage"))
            {
                PrintToChatAll("\x05Infected \x01incapacitated \x05%N", victim);
            }
            else if(HasEntProp(attackerid, Prop_Send, "m_rage"))
            {
                PrintToChatAll("\x05Witch \x01incapacitated \x05%N", victim);
            }
            else
            {
                char szClassName[32];
                GetEntityClassname(attackerid, szClassName, sizeof(szClassName));
                PrintToChatAll("\x05%s \x01incapacitated \x05%N", szClassName, victim);
            }
        }
    }
}
