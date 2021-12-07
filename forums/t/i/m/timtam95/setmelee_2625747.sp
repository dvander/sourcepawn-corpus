#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

new Handle:g_MeleeArray;

public Plugin:myinfo =
{

    name = "Force melee on specific player(s)",
    author = "timtam95",
    description = "Force melee on specific player(s)",
    version = "1.0.0.2",
    url = "http://www.sourcemod.net/"

};


public void OnPluginStart()
{
         LoadTranslations("common.phrases.txt");
         RegAdminCmd("sm_melee", Command_SetMelee, ADMFLAG_GENERIC, "Sets or removes melee only on target(s), Usage: sm_melee \"target\" \"1|0\"");
         HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

         g_MeleeArray = CreateArray();

}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

         new client = GetClientOfUserId(GetEventInt(event, "userid"));

         if (FindValueInArray(g_MeleeArray, client) != -1)  
         {  
           TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
           new client_weapon = GetPlayerWeaponSlot(client, 2);

           ClientCommand(client, "slot3");
           if (client_weapon != -1)
             SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", client_weapon);  
         }

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

                  TF2_AddCondition(target_list[i], TFCond_RestrictToMelee, TFCondDuration_Infinite);          

                  PrintToChatAll("Melee only enabled for %s", strBuffer);

                  if (FindValueInArray(g_MeleeArray, target_list[i]) == -1)
                    PushArrayCell(g_MeleeArray, target_list[i]);
                }
                else
                {

                  PrintToChatAll("Melee only disabled for %s", strBuffer);
                  TF2_RemoveCondition(target_list[i], TFCond_RestrictToMelee);

                  if (FindValueInArray(g_MeleeArray, target_list[i]) != -1)
                    RemoveFromArray(g_MeleeArray, FindValueInArray(g_MeleeArray, target_list[i]));

                }
        }

	return Plugin_Handled;

}

public OnClientDisconnect(client)
{
         if (FindValueInArray(g_MeleeArray, client) != -1)
           RemoveFromArray(g_MeleeArray, FindValueInArray(g_MeleeArray, client));

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