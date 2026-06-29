#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION 		"1.4"
/*======================================================================================
	Change Log:
1.4 (08-May-2022)
	- Fix hold shove when heal by teammate .	
1.3 (11-Fer-2022)
	- Fix hold some situation.
1.2 (04-Fer-2022)
	- Add pass the key Tab Ctrl shift.

1.1 (03-Fer-2022)
	- Optimus and changed some old unused code, Thank Silvers for advised.

1.0 (02-Fer-2022)
	- Initial release.

======================================================================================*/
public Plugin myinfo =
{
	name = "Last key process holder",
	author = "Hoangzp",
	description = "Help to hold the key when act the process bar",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336193"
}
int holderkey[MAXPLAYERS + 1];

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!IsFakeClient(client))
	{
		if(IsClientIncapacitated(client)){
			holderkey[client] = 0;
			return Plugin_Continue;
		}
		if(buttons & (131072+IN_RELOAD)){
			holderkey[client] = 0;
			return Plugin_Continue;
		}		
		if(holderkey[client] != 0 && (buttons & 65536 || buttons & 4 || buttons & 131072) //buttons == 0 || 
		&& GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration")  > 0.0 )
		{
				if(holderkey[client] && buttons == 0 && GetEntPropEnt(client, Prop_Send, "m_reviveOwner") == GetEntPropEnt(client, Prop_Send, "m_reviveTarget")){
					buttons += holderkey[client];
					return Plugin_Changed;
				}
				else if(holderkey[client] && buttons == 0){
				buttons += holderkey[client];
				return Plugin_Changed;
			}
		}			
		else if(holderkey[client] != 0 && buttons != 0 && GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") > 0.0  && (!(buttons & 65536) && !(buttons & 4) && !(buttons & 131072))
		){
			holderkey[client] = 0;
		}
		if(GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") > 0.0 && GetEntPropEnt(client, Prop_Send, "m_reviveOwner") != GetEntPropEnt(client, Prop_Send, "m_reviveTarget"))
		{
			if((buttons & IN_USE || (holderkey[client] == IN_USE))){
				if(!(buttons & IN_USE)){
				buttons += IN_USE;
				}
				holderkey[client] = IN_USE;
				return Plugin_Changed;
			}
		}
		else if(GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") > 0.0 && GetEntPropEnt(client, Prop_Send, "m_reviveOwner") == GetEntPropEnt(client, Prop_Send, "m_reviveTarget")){
				if((buttons & IN_USE || (holderkey[client] == IN_USE))){
				if(!(buttons & IN_USE)){
				buttons += IN_USE;
				}
				holderkey[client] = IN_USE;
				return Plugin_Changed;
			}
		}
		if(GetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration") > 0.0){
			if((buttons & IN_ATTACK2 || (holderkey[client] == IN_ATTACK2)) && GetEntPropEnt(client, Prop_Send, "m_useActionOwner") != GetEntPropEnt(client, Prop_Send, "m_useActionTarget")){
				if(!(buttons & IN_ATTACK2)){
				//PrintToChatAll("%N-%i-%i-%i-%i", client, GetEntPropEnt(client, Prop_Send, "m_useActionOwner"),
				//GetEntPropEnt(client, Prop_Send, "m_useActionTarget"),GetEntPropEnt(client, Prop_Send, "m_reviveOwner"), GetEntPropEnt(client, Prop_Send, "m_reviveTarget"));
				if(GetEntPropEnt(client, Prop_Send, "m_useActionTarget") != client){	 //fix bug shove when teammate heal
				buttons += IN_ATTACK2; 
				}
				}
				holderkey[client] = IN_ATTACK2;
			}
			else if((buttons & IN_ATTACK2 ||(holderkey[client] == IN_ATTACK2)) && GetEntPropEnt(client, Prop_Send, "m_useActionTarget") > MaxClients){
				if(!(buttons & IN_ATTACK2)){
				buttons += IN_ATTACK2;
				}
				holderkey[client] = IN_ATTACK2;
								
			}				
			else if((buttons & IN_USE ||(holderkey[client] == IN_USE))){
				if(!(buttons & IN_USE)){
				buttons += IN_USE;
				}
				holderkey[client] = IN_USE;
			}				
			else if((buttons & IN_ATTACK ||(holderkey[client] == IN_ATTACK)) && GetEntPropEnt(client, Prop_Send, "m_useActionOwner") == GetEntPropEnt(client, Prop_Send, "m_useActionTarget")){ // && GetEntPropEnt(client, Prop_Send, "m_useActionTarget") == client && 
				if(!(buttons & IN_ATTACK)){
				buttons += IN_ATTACK;
				}
				holderkey[client] = IN_ATTACK;
			}
			else if((buttons & IN_ATTACK ||(holderkey[client] == IN_ATTACK)) && GetEntPropEnt(client, Prop_Send, "m_useActionTarget") > MaxClients){
				if(!(buttons & IN_ATTACK)){
				buttons += IN_ATTACK;
				}
				holderkey[client] = IN_ATTACK;
								
			}	
		}
	}
	return Plugin_Continue;
}

public bool IsClientIncapacitated(int client)
{
	if(client > 0 && client <= MaxClients)
	{
		if(GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0 || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0)
		{
			return true;
		}
	}
	return false;
}
