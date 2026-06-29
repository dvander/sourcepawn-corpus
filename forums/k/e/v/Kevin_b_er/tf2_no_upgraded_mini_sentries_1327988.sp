#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PL_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[TF2] No upgraded mini sentry guns",
	author = "Kevin_b_er",
	description = "Prevents the construction of upgraded mini sentry guns",
	version = PL_VERSION,
	url = "www.brothersofchaos.com"
}

public OnPluginStart()
{
	CreateConVar("sm_noupgradedmini_version", PL_VERSION, "Prevents the construction of upgraded mini sentry guns.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	HookEvent("player_builtobject", Event_Player_BuiltObject, EventHookMode_Pre);
}

public Action:Event_Player_BuiltObject(Handle:event, const String:name[], bool:dontBroadcast)
{
new client = GetClientOfUserId(GetEventInt(event, "userid"));
new bool:bad_build;

if (!client)
    return Plugin_Continue;

bad_build = false;
new index = GetEventInt(event, "index");

decl String:classname[32];
GetEdictClassname(index, classname, sizeof(classname));

if( strcmp("obj_sentrygun", classname ) == 0 )
    {
    new highest_lvl = GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel");
    if(  ( GetEntProp(index, Prop_Send, "m_bMiniBuilding") == 1 )
      && ( highest_lvl != 1 ) )
        {
        bad_build = true;
        
        // Kill the building
        SetVariantInt(9999);
        AcceptEntityInput(index, "RemoveHealth");
        
        // Warn user and log
        PrintToChat(client, "Server message: Mini sentries may only be deployed at level 1");
        LogMessage("%L tried to build a mini sentry gun at level %d", client, highest_lvl);
        }
    }
if( bad_build )
	{
	return Plugin_Handled;
	}
else
	{
	return Plugin_Continue;
	}
}