/* Just a Simple Plugin That'll 
*  Let you Adjust how much health you gain for knifing someone.
*/
#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.0"


new Handle:g_hEnable;
new Handle:g_hAnnouce;
new Handle:kniferhealth = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[CSS] Knifer Health",
	author = "adzty",
	description = "When you knife someone you gain health.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart()
{
	//CVARs
	CreateConVar("css_kniferhealth_version", PLUGIN_VERSION, "Current Version of Knifer Health", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY);
	g_hEnable = CreateConVar("css_kniferhealth_enable", "1", "Turns the plugin on/off", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hAnnouce = CreateConVar("css_kniferhealth_message", "1", "Enable the messages that displays to clients on knife deaths?", FCVAR_PLUGIN);
	kniferhealth = CreateConVar("css_kniferhealth", "25", "How much health do you gain by knifing someone?", FCVAR_PLUGIN);
	RegConsoleCmd("kh", Command_OnOff, "Is KniferHealth On/Off?");
	
	//Hooked Events
	HookEvent("player_death", Event_player_knifed);
	//The Config File
	AutoExecConfig(true, "css_kniferhealth");
}

public Action:Event_player_knifed(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Enables The Plugin.
	if (GetConVarInt(g_hEnable) > 0)
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		//checks to see whether its an actual client.
		//if (client > 0 && client < 20)
		for(client = 0; client <= MaxClients; client++)
		{
			decl String:weaponName[32];
			decl String:killerName[32];
			decl String:victimName[32];
			//decl String:target[32], String:health[10];
			GetEventString(event,"weapon",weaponName,32);
			
			//if the weapon used in death was a knife it continues
			
			if(StrEqual(weaponName, "knife"))
			{
				new userid = GetEventInt(event, "userid");
				new userid2 = GetEventInt(event, "attacker");
				new victim = GetClientOfUserId(userid);
				new killer = GetClientOfUserId(userid2);
				//continues
				if(victim != 0 && killer != 0)
				{
					new victimTeam = GetClientTeam(victim);
					new killerTeam = GetClientTeam(killer);
					
					// if the players' teams are not the same, health gets given for a knife kill.
					if(killerTeam != victimTeam)
					{
						GetClientName(victim, victimName, 32);
						GetClientName(killer, killerName, 32);
						
						//Hints Messages to attacker and victim
						if (GetConVarInt(g_hAnnouce) > 0)
						{
							PrintHintText(victim, "You were knifed by %s", killerName);
							PrintHintText(killer, "You knifed %s for %i hp.", victimName, kniferhealth);
						}
						//new m_Offset = FindSendPropOffs("CTFPlayer", "m_iHealth"); //Offset
						
						//adds health to the knifer according to the convar's integer.
						new kHealth = GetClientHealth(killer);
						SetEntityHealth(killer, kHealth + GetConVarInt(kniferhealth));
					}
				}
			}
		}
	}
}

public Action:Command_OnOff(client, args)
{
	if (GetConVarInt(g_hEnable) == 1)
	{
		//\x04 is the color green(I think)
		PrintToChat(client, "\x01CSS Knifer Health is \x04On!");
	}
	else if (GetConVarInt(g_hEnable) == 0)
	{
		PrintToChat(client, "\x01CSS Knifer Health is \x04Off!");
	}
	return Plugin_Handled;
}
