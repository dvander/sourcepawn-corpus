#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <tf2items_giveweapon>
#include <tf2attributes>

new String:plugintag[80] = "{green}[StickLimit]{default} ";

new Handle:g_sticky_limit;
new Handle:g_sticky_limit_admin;


public Plugin:myinfo =  
{  
	name = "Sticky Limitor",  
	author = "Arkarr",  
	description = "Allow admins to choose how much sticky bomb can put a player.",  
	version = "1.0",  
	url = "http://www.sourcemod.net/"  
}; 


public OnPluginStart()  
{
	RegAdminCmd("sm_stickylimit", Sticky_Settings, ADMFLAG_CHEATS, "Allow to change your sticky bomb limit !");
	RegAdminCmd("sm_stickylimit_admin", Sticky_Settings_admin, ADMFLAG_CHEATS, "Allow to change your sticky bomb limit for admins !");
	
	g_sticky_limit = CreateConVar("sm_set_sticky_limit", "20", "Default value when player spawn, set to -1 to disable.");
	g_sticky_limit_admin = CreateConVar("sm_set_sticky_limit_admin", "50", "Default value when admin spawn, set to -1 to disable.");
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(client > 0 && IsClientInGame(client))
	{		
		new TFClassType:class = TF2_GetPlayerClass(client);
		
		if(class == TFClass_DemoMan)
		{
			new Float:MaxSticky;
				
			if(CheckCommandAccess(client, "sm_stickylimit_admin", ADMFLAG_CHEATS))
			{
				if(GetConVarInt(g_sticky_limit_admin) > -1)
				{
					MaxSticky = GetConVarFloat(g_sticky_limit_admin);
				}
				else
				{
					return Plugin_Continue;
				}
			}
			else
			{
				if(GetConVarInt(g_sticky_limit) > -1)
				{
					MaxSticky = GetConVarFloat(g_sticky_limit);
				}
				else
				{
					return Plugin_Continue;
				}
			}
				
			switch(iItemDefinitionIndex)
			{
				case 20, 207, 661, 797, 806, 886, 895, 904, 913, 962, 971:
				{
					MaxSticky -= 8;
				}
				case 130 :
				{
					MaxSticky -= 14;
				}
				case 265 :
				{
					MaxSticky -= 2;
				}
			}
				
			hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES|PRESERVE_ATTRIBUTES);
    
			TF2Items_SetClassname(hItem, classname);
			TF2Items_SetAttribute(hItem, 0, 88, MaxSticky);
			TF2Items_SetNumAttributes(hItem, 1);
               
			TF2Items_GiveNamedItem(client, hItem);

			return Plugin_Changed;
		}
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action:Sticky_Settings(client, args)  
{
	if(client > 0 && IsClientInGame(client))
	{	
		if(args == 2)
		{
			decl String:amount[100];
			decl String:Target[100];
			
			GetCmdArg(1, Target, sizeof(Target));
			
			GetCmdArg(2, amount, sizeof(amount));
			
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
		 
			if ((target_count = ProcessTargetString(
					Target,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_NO_BOTS,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
		 
			for (new i = 0; i < target_count; i++)
			{	
				new sticklaucher = GetPlayerWeaponSlot(target_list[i], 1);
				TF2Attrib_RemoveByName(sticklaucher, "max pipebombs increased")
				
				new Float:MaxSticky = StringToFloat(amount);
				new iItemDefinitionIndex = GetEntProp(sticklaucher, Prop_Send, "m_iItemDefinitionIndex");
				
				switch(iItemDefinitionIndex)
				{
					case 20, 207, 661, 797, 806, 886, 895, 904, 913, 962, 971:
					{
						MaxSticky -= 8.0;
					}
					case 130 :
					{
						MaxSticky -= 14.0;
					}
					case 265 :
					{
						MaxSticky -= 2.0;
					}
				}
				
				TF2Attrib_SetByName(sticklaucher, "max pipebombs increased", MaxSticky);
			}
		 
			if (tn_is_ml)
			{
				CPrintToChat(client, "%sMax sticky limit set to %s for %t", plugintag, amount, target_name);
			}
			else
			{
				CPrintToChat(client, "%sMax sticky limit set to %s for %s", plugintag, amount, target_name);
			}
			
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "Usage : sm_stickylimit [PLAYER] [NUMBER] | Exemple : sm_stickylimit @me 30");
			return Plugin_Continue;
		}
	}
	else
	{	
		return Plugin_Continue;
	}
}

public Action:Sticky_Settings_admin(client, args)  
{
	CPrintToChat(client, "%sIf you see this, you have acces to admin sticky limit.", plugintag);
}
	