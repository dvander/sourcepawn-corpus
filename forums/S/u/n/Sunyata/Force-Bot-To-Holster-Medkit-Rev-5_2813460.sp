#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "L4D1 Bot Holster Medkit",
    author = "Sunyata",
    description = "anti-medit plugin will cause bot to hold medkit when HO is >50, this plugin stops that by using a 'dirty fix' to reholster thier kit",
    version = "5.0",
    url = "https://forums.alliedmods.net/showpost.php?p=2813460&postcount=25"
}

new Handle:AddBackTempHP[MAXPLAYERS + 1];

public OnPluginStart()
{
    HookEvent("heal_begin", StopBotUseMedkit, EventHookMode_Post);
}

public Action:StopBotUseMedkit(Handle:event, const String:name[], bool:dontBroadcast)
{
    new Botvictim = GetClientOfUserId(GetEventInt(event, "userid")); 

    if (IsFakeClient(Botvictim))
    {
        new health = GetEntProp(Botvictim, Prop_Send, "m_iHealth", 0);
		if (health <= 25)	
        {
			SetConVarInt(FindConVar("mkp_minhealth"), 25); //this CVRA value is taken from the anti-medkit plugin, but its value can be overidden here.		
			//PrintToChatAll("* DEBUG TEST - BOT USE MEDKIT BETWEEN 0 AND 25");
			Plugin_Handled;
        }
        else
        {	
		    SetEntProp(Botvictim, Prop_Send, "m_iHealth", 100);
            //SetEntPropFloat(Botvictim, Prop_Send, "m_healthBuffer", 0.0); //best to avoid using this as it can force FULL-HP to exceed 100HP/
            AddBackTempHP[Botvictim] = CreateTimer(7.0, ResetBotHealth, Botvictim);
            PrintToChatAll("* Force bot not to heal with medkit.");
			//PrintToChatAll("* DEBUG TEST - BOT REHOLSTER KIT IS SET BETWEEN 25 AND 100");
			SetConVarInt(FindConVar("mkp_minhealth"), 30);
        }
    }
}

public Action:ResetBotHealth(Handle:timer, any: i)
{
    PrintToChatAll("* Medkit holstered - re-adjusted Bot HP.");
    GetEntProp(i, Prop_Send, "m_iHealth", 0); 

    SetEntProp(i, Prop_Send, "m_iHealth", 60); //this value can be adjusted by a coder-admin to suit each game server requirements
    SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0); //best to avoid using this as it can force FULL-HP green zone HP bar to exceed 100HP when timer is called
    KillTimer(AddBackTempHP[i]);
}
