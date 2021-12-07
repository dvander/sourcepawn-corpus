#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "TF2 Godmode for Non-Admins",
	author = "ratty, Seb",
	description = "TF2 Godmode for Non-Admins",
	version = PLUGIN_VERSION,
	url = "3-pg.com"
}

public OnPluginStart()
{

	RegConsoleCmd("sm_god", Command_godmode, "[SM] Usage: sm_god");
	RegConsoleCmd("sm_buddha", Command_buddha, "[SM] Usage: sm_buddha");
	RegConsoleCmd("sm_mortal", Command_mortal, "[SM] Usage: sm_mortal");
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
	
   
public Action:Command_buddha(client, args)
	
        {
        SetEntProp(client, Prop_Data, "m_takedamage", 1, 1)
        PrintToChat(client,"\x01\x04Buddha Mode on")
        return Plugin_Handled;
	}  

public Action:Command_mortal(client, args)
	{
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
	PrintToChat(client,"\x01\x04Buddha Mode Disabled")
	return Plugin_Handled;
	}
	
