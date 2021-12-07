#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#include <tf2items>
#define PLUGIN_VERSION "1.0.2"

new bool:g_Gimmie[MAXPLAYERS+1] = { false, ...};
new Handle:nextItem[MAXPLAYERS+1];
new Handle:hDebug;

public Plugin:myinfo =
{
    name = "[TF2Items] Advanced Give Item",
    author = "DarthNinja",
    description = "Change item stats via command.  A live version of [TF2Items] Manager.",
    version = PLUGIN_VERSION,
    url = "DarthNinja.com"
};


public OnPluginStart ()
{
	CreateConVar ("sm_giveitem_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	hDebug = CreateConVar("sm_giveitem_textspew", "1", "Enable/Disable debugging text", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegAdminCmd ("sm_gi", GiveItem, ADMFLAG_ROOT);
	RegAdminCmd ("sm_giveitem", GiveItem, ADMFLAG_ROOT);
	LoadTranslations("common.phrases");
}


//sm_giveitem <client>	<int:item index>	<int:slot>	<int:level>		<int:quality>	<intbool:Preserve>	<int:ishat>	<str:classname> <str:attribs>
//				 client		itemIndex			weaponslot			itemlevel		quality		Preserve	ishat			classname			-----
//sm_giveitem 	@me 		123					 1					50				 9				 0 		1				tf_weapon_something			"5;34" "51;21" "77;4.0" "99;1"
public Action:GiveItem (client, args)
{
	if (args < 9)
	{
		ReplyToCommand(client, "Usage: sm_gi <client> <item index> <slot> <level> <quality> <preserve attribs 1/0> <hat 1/0> <tf_weapon_classname> <\"attribute1\" \"attribute2\" etc>  !!ALL VALUES ARE REQUIRED!!");
		return Plugin_Handled;
	}
	
	//Poot strings hea
	decl String:buffer1[64];
	decl String:buffer2[64];
	decl String:buffer3[64];
	decl String:buffer4[64];
	decl String:buffer5[64];
	decl String:buffer6[64];
	decl String:buffer7[128];
	decl String:strhat[64];
	decl String:strclassname[128];
	decl String:explodeStr[16][64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	//Get target
	GetCmdArg(1, buffer1, sizeof(buffer1));
	
		//Process
	if ((target_count = ProcessTargetString(
			buffer1,
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
	
	//Create dat item!
	new Handle:newItem = TF2Items_CreateItem(OVERRIDE_ALL);
	//And flags
	new Flags = 0;
	
	//--- Set Index - Gotta have this
	GetCmdArg(2, buffer2, sizeof(buffer2));
	new itemIndex = StringToInt(buffer2);
	TF2Items_SetItemIndex(newItem, itemIndex);
	//PrintToChatAll("Index %i", itemIndex);
	//---
	
	//--- Set Level
	GetCmdArg(4, buffer4, sizeof(buffer4));
	new level = StringToInt(buffer4);
	// Level -1 = ignore
	if (level < 101 && level > -1)
	{
		TF2Items_SetLevel(newItem, level);
		//PrintToChatAll("Level %i", level);
		Flags |= OVERRIDE_ITEM_LEVEL;
	}
	//---
	
	//--- Set Quality
	GetCmdArg(5, buffer5, sizeof(buffer5));
	new quality = StringToInt(buffer5);
	// Quality -1 = ignore
	if (quality < 10 && quality > -1)
	{
		TF2Items_SetQuality(newItem, quality);
		//PrintToChatAll("Quality %i", quality);
		Flags |= OVERRIDE_ITEM_QUALITY;
	}
	//---
	
	//--- Preserve Attribs
	GetCmdArg(6, buffer6, sizeof(buffer6));
	new Preserve = StringToInt(buffer6);
	if (Preserve == 1)
	{
		Flags |= PRESERVE_ATTRIBUTES;
		//PrintToChatAll("PRESERVE_ATTRIBUTES = true");
	}
	
	//get attrib count
	new NumAttribs = args - 8;
	for (new i = 0; i < NumAttribs; i ++)
	{
		//Get each attrib arg
		GetCmdArg(i+9, buffer7, sizeof(buffer7));
		ExplodeString(buffer7, ";", explodeStr, 2, 64);
		
		//PrintToChatAll("ATTRIBUTE %i from arg %i = %s", i, i+9, buffer7);
		//split
		new iAttributeIndex = StringToInt(explodeStr[0]);
		new Float:fAttributeValue = StringToFloat(explodeStr[1]);
		//apply
		TF2Items_SetAttribute(newItem, i, iAttributeIndex, fAttributeValue);
	}
	
	//Set nummber of attributes
	if (NumAttribs != 0)
	{
		TF2Items_SetNumAttributes(newItem, NumAttribs);
		//PrintToChatAll("NumAttribs = %i", NumAttribs);
		Flags |= OVERRIDE_ATTRIBUTES;
	}
	//Set flags
	TF2Items_SetFlags(newItem, Flags);
	
	//set classname
	GetCmdArg(8, strclassname, sizeof(strclassname));
	new thisShouldFail = StringToInt(strclassname); //This should fail and return 0 - if they enter a 0 then ohshiiii.
	if (thisShouldFail == 0)
	{
		TF2Items_SetClassname(newItem, strclassname);
		//PrintToChatAll("classname = %s", strclassname);
	}
	
	//check for hats, ties and coats
	GetCmdArg(7, strhat, sizeof(strhat));
	new derphat = StringToInt(strhat);
	if (derphat != 1) //Not a hat, apply now
	{
		//get slot
		GetCmdArg(3, buffer3, sizeof(buffer3));
		new slot = StringToInt(buffer3);
		slot--
		// ^ 0 -> 1 for primary
		
		if (GetConVarBool(hDebug))
		{
			if (client != 0)
			{
				PrintToChat(client, "--------\n Giving item with index %i to %s in Slot %i \n Level: %i  - Quality: %i - Preserve Attributes: %i \n Total Attributes: %i \n --------", itemIndex, target_name, slot+1, level, quality, Preserve, NumAttribs);
			}
			ReplyToCommand(client, "--------\n Giving item with index %i to %s in Slot %i \n Level: %i  - Quality: %i - Preserve Attributes: %i \n Total Attributes: %i \n --------", itemIndex, target_name, slot+1, level, quality, Preserve, NumAttribs);
			for (new i = 0; i < NumAttribs; i ++)
			{
				GetCmdArg(i+9, buffer7, sizeof(buffer7));
				ExplodeString(buffer7, ";", explodeStr, 2, 64);
				if (client != 0)
				{
					PrintToChat(client, "Attribute ID Number: %i from cmd arg %i = \"%s\"", i, i+9, buffer7);
				}
				ReplyToCommand(client, "Attribute ID Number: %i from cmd arg %i = \"%s\"", i, i+9, buffer7);
			}
			if (client != 0)
			{
				PrintToChat(client, "--------");
			}
			ReplyToCommand(client, "--------");
		}
		
		for (new i = 0; i < target_count; i ++)
		{
			TF2_RemoveWeaponSlot(target_list[i], slot);
			new entity = TF2Items_GiveNamedItem(target_list[i], newItem);
			//CloseHandle(newItem);
			
			if (IsValidEntity(entity))
			{
				//PrintToChatAll("Ent is valid");
				EquipPlayerWeapon(target_list[i], entity);
			}
		}
	}
	
	
	else if (derphat == 1) //Cache to apply later
	{
		for (new i = 0; i < target_count; i ++)
		{
			if (GetConVarBool(hDebug))
			{
				if	(client != 0)
				{
					PrintToChat(client, "--------\n Giving item with index %i to %s \n Level: %i  - Quality: %i - Preserve Attributes: %i \n Total Attributes: %i \n --------", itemIndex, target_name, level, quality, Preserve, NumAttribs);
				}
				ReplyToCommand(client, "--------\n Giving item with index %i to %s \n Level: %i  - Quality: %i - Preserve Attributes: %i \n Total Attributes: %i \n --------", itemIndex, target_name, level, quality, Preserve, NumAttribs);
				for (new ii = 0; ii < NumAttribs; ii ++)
				{
					GetCmdArg(ii+9, buffer7, sizeof(buffer7));
					ExplodeString(buffer7, ";", explodeStr, 2, 64);
					if	(client != 0)
					{
						PrintToChat(client, "Attribute ID Number: %i from cmd arg %i = \"%s\"", ii, ii+9, buffer7);
					}
					ReplyToCommand(client, "Attribute ID Number: %i from cmd arg %i = \"%s\"", ii, ii+9, buffer7);
				}
				ReplyToCommand(client, "--------");
				if	(client != 0)
				{
					PrintToChat(client, "--------");
				}
			}
			ReplyToCommand(target_list[i], "[GIA] Your loadout has been regenerated to equip item changes");
			if	(client != 0)
			{
				PrintToChat(target_list[i], "[GIA] Your loadout has been regenerated to equip item changes");
			}
			
			g_Gimmie[target_list[i]] = true;
			
			nextItem[target_list[i]] = CloneHandle(newItem);			
			//---- MUST use CloneHandle, "nextItem[target_list[i]] = newItem;" does not work.
			TF2_RegeneratePlayer(target_list[i]);
			//Force regen right away since we can only store 1 item at a time...
			
			//PrintToChatAll("hat data stored");
		}
	}
	
	CloseHandle(newItem);
	return Plugin_Handled;
	
}

public Action:TF2Items_OnGiveNamedItem(client, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{	
	if (nextItem[client] != INVALID_HANDLE)
	{
		new cacheditemindex = TF2Items_GetItemIndex(nextItem[client]);
		//PrintToChatAll("does %i = %i ?",cacheditemindex,iItemDefinitionIndex);
	
		//If the client is valid, has an item queued, and the item they are getting matches the input index
		// -> Swap it out for the tf2items item.
		if (IsValidClient(client) && g_Gimmie[client] && iItemDefinitionIndex == cacheditemindex) //Player has item waiting
		{
			//PrintToChatAll("OnGive checks passed...");
			//PrintToChatAll("Item Applied?");
			hItemOverride = nextItem[client];
			nextItem[client] = INVALID_HANDLE;
			g_Gimmie[client] = false;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
/*
stock TF2_RemoveWeaponSlot(client, slot)
{
	new weaponIndex;
	while ((weaponIndex = GetPlayerWeaponSlot(client, slot)) != -1)
	{
		RemovePlayerItem(client, weaponIndex);
		RemoveEdict(weaponIndex);
	}
}
*/

/* IsValidClient()
 *
 * Checks if a client is valid.
 * -------------------------------------------------------------------------- */
bool:IsValidClient(iClient)
{
	if (iClient < 1 || iClient > MaxClients)
		return false;
	if (!IsClientConnected(iClient))
		return false;
	return IsClientInGame(iClient);
}
