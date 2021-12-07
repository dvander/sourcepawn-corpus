#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <tf2items_giveweapon>

new String:plugintag[80] = "{green}[StickLimit]{default} ";
new String:amout[30];
new String:attribut[10005];
new String:TargetClient[900];
new Float:MaxSticky;

new weaponindex[MAXPLAYERS+1];
new Handle:g_sticky_limit;
new Handle:g_sticky_limit_admin;
//new Handle:newitem[MAXPLAYERS+1] = INVALID_HANDLE;

//Creat a new weapon with this index. Well, I take this number because i'm pretty sure, no one who didn't read this will take this item index.
new customweaponID = 35237092768972386798270953277956130591758105;


public Plugin:myinfo =  
{  
	name = "Sticky Limitor (All-Class Edition)",  
	author = "Arkarr & Oshizu",  
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

/*
Don't want ot comment this block :|
*/
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	if(client > 0 && IsClientInGame(client) && GetConVarInt(g_sticky_limit) > -1)
	{		
		if(CheckCommandAccess(client, "sm_stickylimit_admin", ADMFLAG_CHEATS))
		{
			MaxSticky = GetConVarFloat(g_sticky_limit_admin);
		}
		else
		{
			MaxSticky = GetConVarFloat(g_sticky_limit);
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
			// Get the client using the 1 argument :
			
			// 1) Get the client:
			GetCmdArg(1, TargetClient, sizeof(TargetClient));
			// 2) Put the client into a a variable :
			new selectedClient = FindTarget(client, TargetClient);
			
			//Check if the selected client is valid or not :
			if(selectedClient > 0 && IsClientInGame(selectedClient))
			{
				//Get the value of max stick using 2 argument :
				
				GetCmdArg(2, amout, sizeof(amout));
				
				//Get the second arguemnt as a String :
				Format(attribut, sizeof(attribut), "88 : %s", amout);
				
				/* ---> DON'T WORK, WHY ?!
				new secondary = GetPlayerWeaponSlot(client, 1);
				new Quality = GetEntProp(secondary, Prop_Send, "m_iEntityQuality");
				new Level = GetEntProp(secondary, Prop_Send, "m_iEntityLevel");
				new ItemIndex = GetEntProp(secondary, Prop_Send, "m_iItemDefinitionIndex");
					
				newitem[client] = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES);
    
				TF2Items_SetClassname(newitem[client], "tf_weapon_pipebomblauncher");
					
				TF2Items_SetItemIndex(newitem[client], ItemIndex);
					
				TF2Items_SetQuality(newitem[client], Quality);
					
				TF2Items_SetLevel(newitem[client], Level);
					
				TF2Items_SetAttribute(newitem[client], 0, 88, MaxSticky);
				TF2Items_SetNumAttributes(newitem[client], 1);
                
				TF2Items_GiveNamedItem(client, newitem[client]);
				*/
				new weapon = GetPlayerWeaponSlot(selectedClient, 1);
				SetEntPropEnt(selectedClient, Prop_Send, "m_hActiveWeapon", weapon);
					
				new activeweapon = GetEntPropEnt(selectedClient, Prop_Send, "m_hActiveWeapon");
				weaponindex[selectedClient] = GetEntProp(activeweapon, Prop_Send, "m_iItemDefinitionIndex");
				
				TF2Items_CreateWeapon(customweaponID, "tf_weapon_pipebomblauncher", weaponindex[selectedClient], 1, 9, 100, amout);
				
				TF2Items_GiveWeapon(selectedClient, customweaponID);
					
				customweaponID++;
			}
			else
			{
				PrintToChat(client, "%sThe selected player is invalid ! Possible reason : Disconnected or spectating", plugintag);
			}
			//Nothing is done return continue :
			return Plugin_Continue;
		}
		//Explain how command work :
		else
		{
			ReplyToCommand(client, "Usage : sm_stickylimit [PLAYER] [NUMBER] | Exemple : sm_stickylimit @me 30");
			//Nothing is done return continue :
			return Plugin_Continue;
		}
	}
	else
	{	
		//Nothing is done return continue :
		return Plugin_Continue;
	}
}

public Action:Sticky_Settings_admin(client, args)  
{
	CPrintToChat(client, "%sIf you see this, you have acces to admin sticky limit.", plugintag);
}
	