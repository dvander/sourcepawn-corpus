#include <sourcemod>
#include <sdktools>

 public Plugin:myinfo =
{
	name = "godmod for everyone",
	author = "Peace",
	description = "Simple god mode anyone can use",
	version = "1.0.0.0",
	url = "http://steamcommunity.com/id/colorfulpeace"
}
 
 public OnPluginStart()
{
RegConsoleCmd("sm_god", Command_god, "[SM] Usage: sm_god");
}

public Action:Command_god(client, args)
{
        new gValue = GetEntProp(client, Prop_Data, "m_takedamage", 1);

        if(gValue) 
        {
                SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
                PrintToChat(client,"god mode enabled")
        }else{     
                SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
                PrintToChat(client,"god mode disabled")
        }
        return Plugin_Handled;
}  