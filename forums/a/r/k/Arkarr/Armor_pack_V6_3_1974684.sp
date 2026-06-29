#include <sourcemod>  
#include <sdkhooks>
#include <morecolors>

new effect[MAXPLAYERS + 1] = -1;
new armor[MAXPLAYERS + 1];
new Handle:hHudText;
new kills[MAXPLAYERS + 1];
new killsneeded[MAXPLAYERS + 1];
new totalkills[MAXPLAYERS + 1];
new buyed[MAXPLAYERS + 1];
new Float:pourcent;
new Float:DamageResistance;

new Handle:g_armor1;
new Handle:g_armor2;
new Handle:g_armor3;
new Handle:g_armor4;

new Handle:g_armorHP1;
new Handle:g_armorHP2;
new Handle:g_armorHP3;
new Handle:g_armorHP4;

new Handle:g_name_armor1;
new Handle:g_name_armor2;
new Handle:g_name_armor3;
new Handle:g_name_armor4;

new Handle:g_DamageResistance_armor1;
new Handle:g_DamageResistance_armor2;
new Handle:g_DamageResistance_armor3;
new Handle:g_DamageResistance_armor4;

new Handle:g_killbeforearmor;

new String:armor1[512];
new String:armor2[512];
new String:armor3[512];
new String:armor4[512];

new String:name_armor1[512];
new String:name_armor2[512];
new String:name_armor3[512];
new String:name_armor4[512];

new String:playername[512];
new String:plugintag[40] = "{strange}[Armor]{default} ";

new g_GameEngine = SOURCE_SDK_UNKNOWN;

public Plugin:myinfo =  
{  
    name = "Armor pack",  
    author = "Arkarr",  
    description = "Active a armor for players, armor can be buy with kills - MY FIRST PLUGIN",  
    version = "5.0",  
    url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{ 
    RegConsoleCmd("sm_armor", Armor_Menu, "Armor menu");
    RegAdminCmd("sm_addkills", Armor_AddKills, ADMFLAG_CHEATS);
    
    g_GameEngine = GuessSDKVersion();
    
    hHudText = CreateHudSynchronizer();
    
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre)
    
    g_armor1 = CreateConVar("sm_price_armor1", "5", "What should the price of the 1 armor be ?");
    g_armor2 = CreateConVar("sm_price_armor2", "15", "What should the price of the 2 armor be ?");
    g_armor3 = CreateConVar("sm_price_armor3", "25", "What should the price of the 3 armor be ?");
    g_armor4 = CreateConVar("sm_price_armor4", "35", "What should the price of the 4 armor be ?");
    
    g_armorHP1 = CreateConVar("sm_hp_armor1", "20", "How much HP should have armor 1 ?");
    g_armorHP2 = CreateConVar("sm_hp_armor2", "50", "How much HP should have armor 2 ?");
    g_armorHP3 = CreateConVar("sm_hp_armor3", "100", "How much HP should have armor 3 ?");
    g_armorHP4 = CreateConVar("sm_hp_armor4", "200", "How much HP should have armor 4 ?");
	
    g_name_armor1 = CreateConVar("sm_name_armor1", "Basic Armor", "What should be the name of armor 1 ?");
    g_name_armor2 = CreateConVar("sm_name_armor2", "Elite Armor", "What should be the name of armor 2 ?");
    g_name_armor3 = CreateConVar("sm_name_armor3", "Veteran Armor", "What should be the name of armor 3 ?");
    g_name_armor4 = CreateConVar("sm_name_armor4", "Suprem Armor", "What should be the name of armor 4 ?");
	
    g_killbeforearmor = CreateConVar("sm_kills_before_first_armor", "30", "How much kill(s) should do the player before buying is first armor ?");
	
    g_DamageResistance_armor1 = CreateConVar("sm_armor1_damage_resis", "30", "Amount of damage armor 1 will absorb");
    g_DamageResistance_armor2 = CreateConVar("sm_armor2_damage_resis", "40", "Amount of damage armor 2 will absorb");
    g_DamageResistance_armor3 = CreateConVar("sm_armor3_damage_resis", "50", "Amount of damage armor 3 will absorb");
    g_DamageResistance_armor4 = CreateConVar("sm_armor4_damage_resis", "70", "Amount of damage armor 4 will absorb");
    
    AutoExecConfig(true, "armorpackV6");
    
    //Chaosxk idea, Thank you ! https://forums.alliedmods.net/showpost.php?p=1975232&postcount=9
    for(new i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i)) {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            killsneeded[i] = GetConVarInt(g_killbeforearmor);
        }
    }
    
}

//Thanks to bl4nk for is help : https://forums.alliedmods.net/showpost.php?p=1975240&postcount=10
public OnClientPutInServer(client)
{
    kills[client] = 0;
    armor[client] = 0;
    
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}


public MenuHandler1(Handle:menu, MenuAction:action, client, param2)  
{  
    new String:info[32];  
    GetMenuItem(menu, param2, info, sizeof(info));  
    
    if (action == MenuAction_Select)  
    {
        param2++; 
        if(param2 == 1) 
        {  
            effect[client] = 1;  
            Action_Effect(client);  
        }  
        else if(param2 == 2) 
        {  
            effect[client] = 2;  
            Action_Effect(client);  
        }  
        else if(param2 == 3) 
        {  
            effect[client] = 3;  
            Action_Effect(client);  
        }  
        else if(param2 == 4) 
        {  
            effect[client] = 4;  
            Action_Effect(client);  
        } 
    } 
    
    else if (action == MenuAction_End)  
    {  
        CloseHandle(menu);  
    } 
} 


public Action:Armor_Menu(client, args)  
{
    if(IsValidClient(client))
	{
		if(GetClientTeam(client) != 1 || GetClientTeam(client) != 0)
		{
	
			name_armor1[100] = GetConVarString(g_name_armor1, name_armor1, sizeof(name_armor1));
			name_armor2[100] = GetConVarString(g_name_armor2, name_armor2, sizeof(name_armor2));
			name_armor3[100] = GetConVarString(g_name_armor3, name_armor3, sizeof(name_armor3));
			name_armor4[100] = GetConVarString(g_name_armor4, name_armor4, sizeof(name_armor4));
			
			Format(armor1, sizeof(armor1), "%s (%i HP)", name_armor1, GetConVarInt(g_armorHP1) );
			Format(armor2, sizeof(armor2), "%s (%i HP)", name_armor2, GetConVarInt(g_armorHP2) );
			Format(armor3, sizeof(armor3), "%s (%i HP)", name_armor3, GetConVarInt(g_armorHP3) );
			Format(armor4, sizeof(armor4), "%s (%i HP)", name_armor4, GetConVarInt(g_armorHP4) );
			
			new Handle:menu = CreateMenu(MenuHandler1); 
			SetMenuTitle(menu, "Select your armor health :"); 
			AddMenuItem(menu, "armor1", armor1); 
			AddMenuItem(menu, "armor2", armor2); 
			AddMenuItem(menu, "armor3", armor3); 
			AddMenuItem(menu, "armor4", armor4); 
			SetMenuExitButton(menu, true); 
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
			
			PrintToChat(client, "-------------------------");
			PrintToChat(client, "%s (%i kills)", name_armor1, GetConVarInt(g_armor1) );
			PrintToChat(client, "%s (%i kills)", name_armor2, GetConVarInt(g_armor2) );
			PrintToChat(client, "%s (%i kills)", name_armor3, GetConVarInt(g_armor3) );
			PrintToChat(client, "%s (%i kills)", name_armor4, GetConVarInt(g_armor4) );
			PrintToChat(client, "You have %i kills", kills[client]);
			PrintToChat(client, "-------------------------");
		}
	}

    return Plugin_Handled;
} 


Action_Effect(client)  
{         
    if(effect[client] == 1) 
    {	
		totalkills[client] = GetConVarInt(g_armor1) - kills[client];
		if(kills[client] >= GetConVarInt(g_armor1) )
		{
			armor[client] = GetConVarInt(g_armorHP1);
			buyed[client] = 1;
			kills[client] -= GetConVarInt(g_armor1);
			DamageResistance = GetConVarFloat(g_DamageResistance_armor1);
		}
		else
		{
			CPrintToChat(client, "%sYou need to do %i kills befor buying a armor !", plugintag, totalkills[client]);
			buyed[client] = 0;
		}
    } 
        
    if(effect[client] == 2) 
    {	
		totalkills[client] = GetConVarInt(g_armor2) - kills[client];
		if(kills[client] >= GetConVarInt(g_armor2) )
		{
			armor[client] = GetConVarInt(g_armorHP2);
			buyed[client] = 1;
			kills[client] -= GetConVarInt(g_armor2);
			DamageResistance = GetConVarFloat(g_DamageResistance_armor2);
		}
		else
		{
			CPrintToChat(client, "%sYou need to do %i kills befor buying a armor !", plugintag, totalkills[client]);
			buyed[client] = 0;
		}
    } 
        
    if(effect[client] == 3) 
    {	
		totalkills[client] = GetConVarInt(g_armor3) - kills[client];
		if(kills[client] >= GetConVarInt(g_armor3) )
		{
			armor[client] = GetConVarInt(g_armorHP3);
			buyed[client] = 1;
			kills[client] -= GetConVarInt(g_armor3);
			DamageResistance = GetConVarFloat(g_DamageResistance_armor3);
		}
		else
		{
			CPrintToChat(client, "%sYou need to do %i kills befor buying a armor !", plugintag, totalkills[client]);
			buyed[client] = 0;
		}
    } 
    
    if(effect[client] == 4) 
    {	
		totalkills[client] = GetConVarInt(g_armor4) - kills[client];
		if(kills[client] >= GetConVarInt(g_armor4) )
		{
			armor[client] = GetConVarInt(g_armorHP4);
			buyed[client] = 1;
			kills[client]-= GetConVarInt(g_armor4);
			DamageResistance = GetConVarFloat(g_DamageResistance_armor4);
		}
		else
		{
			CPrintToChat(client, "%sYou need to do %i kills befor buying a armor !", plugintag, totalkills[client]);
			buyed[client] = 0;
		}
    }
    
    //Thanks to abrandnewday : https://forums.alliedmods.net/showpost.php?p=1975482&postcount=18
    new sdkversion = GuessSDKVersion();
    if (sdkversion >= SOURCE_SDK_LEFT4DEAD2 && buyed[client] == 1)
    {
        PrintHintText(client, "HP of armor : %i", armor[client]);
    }
    else if(buyed[client] == 1)
    {
        SetHudTextParams(-0.75, 0.90, 45.0, 40, 151, 249, 255);
        ShowSyncHudText(client, hHudText, "HP of armor : %i", armor[client]);
    }

}


public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{     
	if(IsValidClient(victim) && IsValidClient(attacker))
	{
		if(victim == attacker)
		{
			return Plugin_Continue;
		}
		else{
		
		new Float:maxdammage; //backup of max dammage
		new Float:intdamage;
		
		if(armor[victim] >= 1){ 
			
			//Get the dammage :
            intdamage = damage;
            maxdammage = damage;			
			
			//Get the % of absorbation
            pourcent = DamageResistance / 100;
			
			//Dammage to substitue of armor :
            intdamage *= pourcent;
			
			//Rest of dammage for player :
            maxdammage -= intdamage;
			
			//NOW substitue the dammage to armor :
            armor[victim] -= RoundToCeil(intdamage);
			
			//AND to player :
            SetEntProp(victim, Prop_Send, "m_iHealth", GetClientHealth(victim) - RoundToCeil(maxdammage));			
			
            if(armor[victim] <= -1){
			
				armor[victim] = 0; 
				
				//Thanks to abrandnewday : https://forums.alliedmods.net/showpost.php?p=1975482&postcount=18
				new sdkversion = GuessSDKVersion();
				if (sdkversion >= SOURCE_SDK_LEFT4DEAD2)
				{
					PrintHintText(victim, "Your armor is now DESTROYED !");
				}
				else
				{
					ClearSyncHud(victim, hHudText);
					PrintHintText(victim, "Your armor is now DESTROYED !");
				}
				
			}
			
			else{
				//Thanks to abrandnewday : https://forums.alliedmods.net/showpost.php?p=1975482&postcount=18
				new sdkversion = GuessSDKVersion();
				if (sdkversion >= SOURCE_SDK_LEFT4DEAD2)
				{
					PrintHintText(victim, "HP of armor : %i", armor[victim]);
				}
				else
				{
					ClearSyncHud(victim, hHudText);
					SetHudTextParams(-0.75, 0.90, 45.0, 40, 151, 249, 255); 
					ShowSyncHudText(victim, hHudText, "HP of armor : %i", armor[victim]);
				}
				
			} 
			
            if(armor[victim] >= 1){
				PrintHintText(attacker, "This player use armor, HP of armor : %d", armor[victim]);
			}
			else{
				GetClientName(victim, playername, 512);
				PrintHintText(attacker, "You destroyed the armor of %s !", playername);
			}
			
            new health = GetEntProp(victim, Prop_Send, "m_iHealth", GetClientHealth(victim));
			
            if(health <= 0)
			{
				// Allow damage
				return Plugin_Continue;
			}
			// Block damage 
            return Plugin_Handled;
		}
		
		}
	}
    
	// Allow damage 
	return Plugin_Continue; 
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
    if(killer != victim){
        kills[killer]++;
	}
    
    return Plugin_Continue
}

public Action:Armor_AddKills(client, args)
{
	new String:arg1[32], String:arg2[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new target = FindTarget(client, arg1);
	
	if(IsValidClient(client) && IsValidClient(target))
	{
		
		
		//Thanks to abrandnewday : https://forums.alliedmods.net/showpost.php?p=1975482&postcount=18
		new sdkversion = GuessSDKVersion();
		if (sdkversion >= SOURCE_SDK_LEFT4DEAD2)
		{
			//Nothing to do.
		}
		else
		{
			ClearSyncHud(client, hHudText);
		}
		
		kills[client] = StringToInt(arg2);
		PrintHintText(client, "A admin added you %i kills ! You can use again !armor !", StringToInt(arg2) ,StringToInt(arg1));
		
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

//Stocks here <------------------------------------------------------------------------------

//Stock one, thank to Chaosxk https://forums.alliedmods.net/showpost.php?p=1975847&postcount=25
stock bool:IsValidClient(iClient, bool:bReplay = true) {
    if(iClient <= 0 || iClient > MaxClients)
        return false;
    if(!IsClientInGame(iClient))
        return false;
    if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
        return false;
    return true;
}

