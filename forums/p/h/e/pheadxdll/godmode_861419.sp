#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "godmode",
	author = "linux_lover",
	description = "simple godmode plugin",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
        RegConsoleCmd("godmode", Command_godmode);
}

public Action:Command_godmode(client, args)
{
        new gValue = GetEntProp(client, Prop_Data, "m_takedamage", 1);

        if(gValue) // mortal
        {
                SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
                PrintToChat(client,"\x01\x04God mode on")
        }else{     // godmode
                SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
                PrintToChat(client,"\x01\x04God mode off")
        }
        return Plugin_Handled;
}