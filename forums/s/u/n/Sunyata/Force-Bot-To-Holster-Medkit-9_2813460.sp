#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
    name = "L4D1 Bot Holster Medkit",
    author = "Sunyata/VS",
    description = "allow medkit plugin used to cause bot to hold medkit at 50HP, this plugin stops that",
    version = "9.0",
    url = ""
}

new Handle:AddBackTempHP[MAXPLAYERS + 1];

// VS NOTES - THIS SCRIPT WILL STOP A BOT FROM HOLDING THEIR MEDKIT AND WILL ENSURE THEY HOLSTER IT.
// Bot will hold medkit to try and heal itself at 50hp when not under threat; it does this because the !AMH plugin is set to 30hp, but the bot can't use the kit until their hp is at 30

//Version: 9-fixed memory timer error log message

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
            SetConVarInt(FindConVar("mkp_minhealth"), 25); // AMH healing start point for bot
            //PrintToChatAll("* DEBUG TEST - BOT HEALTH IS BETWEEN 1 AND 25");
            return Plugin_Handled;
        }
        else
        {
            SetEntProp(Botvictim, Prop_Send, "m_iHealth", 100);
            // SetEntPropFloat(Botvictim, Prop_Send, "m_healthBuffer", 0.0);
            if (AddBackTempHP[Botvictim] != INVALID_HANDLE)
            {
                KillTimer(AddBackTempHP[Botvictim]);
            }
            AddBackTempHP[Botvictim] = CreateTimer(7.0, ResetBotHealth, Botvictim);
            //PrintToChatAll("* Force bot not to heal with medkit.");
            //PrintToChatAll("* DEBUG TEST - BOT HEALTH IS BETWEEN 25 AND 100");
            SetConVarInt(FindConVar("mkp_minhealth"), 30);
        }
    }
    return Plugin_Handled;
}

public Action:ResetBotHealth(Handle:timer, any:i)
{
    //PrintToChatAll("* Medkit holstered - re-adjusted Bot HP.");
    SetEntProp(i, Prop_Send, "m_iHealth", 60);
    SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);

    if (AddBackTempHP[i] != INVALID_HANDLE)
    {
        KillTimer(AddBackTempHP[i]);
        AddBackTempHP[i] = INVALID_HANDLE;
    }
    return Plugin_Handled;
}
