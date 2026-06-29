#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.0"

new g_iOffsetCloak;

public Plugin:myinfo = 
{
	name = "TF2 Bot Hack",
	author = "EfeDursun125",
	description = "Bots now using mini hacks.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				
				if(GetAmmo(client) != -1)
				{
					SetEntData(client, GetAmmo(client) +4, 50);
					SetEntData(client, GetAmmo(client) +8, 50);
				}
				
				if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
				{
					TF2_AddCondition(client, TFCond_StealthedUserBuffFade, -1.0)
				}
				else
				{
					TF2_RemoveCondition(client, TFCond_StealthedUserBuffFade);
				}
				
				if(class != TFClass_Medic)
				{
					SetVariantInt(1);
					AcceptEntityInput(client, "SetForcedTauntCam");
				}
				
				if(class == TFClass_Sniper)
				{
					if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
					{
		 				SetEntProp(client, Prop_Send, "m_iHideHUD", 5);
						new weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
						SetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage", 150.0); 
					}
					else 	
					{
						SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
					}
				}
				
				if(class == TFClass_Spy)
				{
					if(GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab"))
					{
						buttons |= IN_ATTACK;
					}

					if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						g_iOffsetCloak = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
						SetEntDataFloat(client, g_iOffsetCloak, 100.0);
					}
					
					if(TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
					{
						g_iOffsetCloak = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
						SetEntDataFloat(client, g_iOffsetCloak, 100.0);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock GetAmmo(client)
{
	return FindSendPropInfo("CTFPlayer", "m_iAmmo");
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  