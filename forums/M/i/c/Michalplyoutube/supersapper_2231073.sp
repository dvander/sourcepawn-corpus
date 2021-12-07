#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

public Plugin:myinfo = {
    name = "Super sapper",
    author = "Michalpl",
    description = "Upgrades sapper effects for mvm",
    version = "0.9",
    url = ""
};

public TF2_OnConditionAdded(client, TFCond:condition) //sapper stuff
{
	
	if(condition==TFCond_Sapped)
	{
		GetClientUserId( client );
		
		CreateTimer(0.1, Timer_Sapper_hurt, client, TIMER_REPEAT)
//		TF2_MakeBleed(client, client, 50.0);
		new String:strName[MAX_NAME_LENGTH];
		GetClientName(client, strName, sizeof(strName));
		if (StrEqual(strName, "Sentry Buster"))
		{
			SetEntityHealth(client, 60);
//			PrintToChatAll("Added DMG");
		}
	}
}
public Action:Timer_Sapper_hurt(Handle:timer, any:client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_Sapped))
	{
		if(bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == true)
		{
			new weaponP = GetPlayerWeaponSlot(client, 0);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponP);  
		}
		return Plugin_Stop;
	}
	if(TF2_IsPlayerInCondition(client, TFCond_Sapped))
	{
		if(bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == true)
		{
			TF2_AddCondition( client, TFCond_RestrictToMelee, 2.0 );
			new weaponM = GetPlayerWeaponSlot(client, 2);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponM);  
		}
//		new TFClassType:iClass = TF2_GetPlayerClass(client);
//		new attacker = iClass == TFClass_Spy && GetClientTeam(client) == _:TFTeam_Red;
		new curhp = GetClientHealth(client);
		if(curhp > 4)
		{
			SetEntityHealth(client, curhp-3);
		}
		if(curhp > 0 && bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == false)
			TF2_AddCondition( client, TFCond_NoHealingDamageBuff, 1.25 );
		if(curhp < 4 && bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == false)
			TF2_MakeBleed(client, client, 2.0);
//			ForcePlayerSuicide(client);
		if(curhp < 5 && bool:GetEntProp(client, Prop_Send, "m_bIsMiniBoss") == true)
			TF2_MakeBleed(client, client, 2.0);
	}
	return Plugin_Continue;
}