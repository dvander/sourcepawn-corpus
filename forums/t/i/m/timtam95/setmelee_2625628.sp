#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin:myinfo =
{

    name = "Force melee on specific player(s)",
    author = "timtam95",
    description = "Force melee on specific player(s)",
    version = "1.0.0.0",
    url = "http://www.sourcemod.net/"

};


public void OnPluginStart()
{
  LoadTranslations("common.phrases.txt");
  RegAdminCmd("sm_melee", Command_SetMelee, ADMFLAG_GENERIC, "Sets or removes melee only on target(s), Usage: sm_melee \"target\" \"1|0\"");
}


public Action:Command_SetMelee(client, args)
{
	new String:strBuffer[MAX_NAME_LENGTH], String:strEnabled[MAX_NAME_LENGTH], String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(2, strEnabled, sizeof(strEnabled));

        if ((args != 2) || (!StrEqual(strEnabled, "0") && !StrEqual(strEnabled, "1")))
	{
		ReplyToCommand(client, "[SM] Usage: sm_melee \"target\" \"1|0\"");
		return Plugin_Handled;
	}


	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	if ((target_count = ProcessTargetString(strBuffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}


	for(new i = 0; i < target_count; i++)
	{
                if (!IsValidClient(target_list[i])) continue;

                GetClientName(target_list[i], strBuffer, sizeof(strBuffer));

                if (StrEqual(strEnabled, "1"))
                {
                  new client_weapon = GetPlayerWeaponSlot(target_list[i], 2);

                  if (client_weapon != -1)
                  {
                     ClientCommand(target_list[i], "slot3");
                     SetEntPropEnt(target_list[i], Prop_Send, "m_hActiveWeapon", client_weapon);  
                  }

                  PrintToChatAll("Melee only enabled for %s", strBuffer);
                  SDKHook(target_list[i], SDKHook_WeaponCanSwitchTo, BlockWeaponSwitch);
                } else
                {

                  PrintToChatAll("Melee only disabled for %s", strBuffer);
                  SDKUnhook(target_list[i], SDKHook_WeaponCanSwitchTo, BlockWeaponSwitch);
                }

	}
	return Plugin_Handled;


}

public Action:BlockWeaponSwitch(client, weapon)
{
  return Plugin_Handled;
}


stock bool:IsValidClient(iClient)
{

    return (0 < iClient && iClient <= MaxClients
        && IsClientInGame(iClient)
        && !IsClientReplay(iClient)
        && !IsClientSourceTV(iClient)
        && !GetEntProp(iClient, Prop_Send, "m_bIsCoaching")
        && IsPlayerAlive(iClient)
    );

}