#include <sourcemod>

#define PLUGIN_VERSION		"1.5.0"

public Plugin:myinfo = 
{
	name = "[TF2] Fake Item Messages",
	author = "DarthNinja",
	description = "Prints fake item found messages",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	RegAdminCmd("sm_fakeitem", PrintFakeItem, ADMFLAG_SLAY, "Prints a fake item message to chat");
	RegAdminCmd("sm_fakeitem2", PrintFakeItem2, ADMFLAG_SLAY, "Prints a fake item message to chat");
	CreateConVar("sm_fakeitem_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("common.phrases");
}

public Action:PrintFakeItem(client, args)
{
	if (args < 2 || args > 4)
	{
		ReplyToCommand(client, "Usage: sm_fakeitem <client> <item index> [quality] [method]");
		return Plugin_Handled;
	}
	
	decl String:player[64];
	GetCmdArg(1, player, sizeof(player));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:Item[64];
	GetCmdArg(2, Item, sizeof(Item));
	
	new iItem = StringToInt(Item);
	new iQuality = 6; //Yellow 'Unique' items
	new iMethod = 0; //found
	
	if (args > 2)
	{
		decl String:Quality[64];
		GetCmdArg(3, Quality, sizeof(Quality));
		
		if (StrEqual(Quality, "Normal", false))
			iQuality = 0;
		else if (StrEqual(Quality, "Genuine", false))
			iQuality = 1;
		else if (StrEqual(Quality, "olive", false))
			iQuality = 2;
		else if (StrEqual(Quality, "Vintage", false))
			iQuality = 3;
		else if (StrEqual(Quality, "orange", false))
			iQuality = 4;
		else if (StrEqual(Quality, "Unusual", false))
			iQuality = 5;
		else if (StrEqual(Quality, "Unique", false))
			iQuality = 6;
		else if (StrEqual(Quality, "Community", false))
			iQuality = 7;
		else if (StrEqual(Quality, "Valve", false))
			iQuality = 8;
		else if (StrEqual(Quality, "Selfmade", false))
			iQuality = 9;
		else if (StrEqual(Quality, "Customized", false) || StrEqual(Quality, "Custom", false))
			iQuality = 10;
		else if (StrEqual(Quality, "Strange", false) || StrEqual(Quality, "Strange", false))
			iQuality = 11;
		else if (StrEqual(Quality, "Haunted", false) || StrEqual(Quality, "Haunted", false))
			iQuality = 13;
		else
		{
			iQuality = StringToInt(Quality);
			if (iQuality > 14 || iQuality < 0 || StrEqual(Quality, "help", false) || StrEqual(Quality, "list", false))
			{
				ReplyToCommand(client, "\nInvalid or unknown quality given.\nPlease use one of the following, or their int values (0-14):\n  - Normal\n  - Genuine\n  - olive\n  - Vintage\n  - orange\n  - Unusual\n  - Unique\n  - Community\n  - Valve\n  - Selfmade\n  - Cusomized\n  - Strange - Haunted");
				return Plugin_Handled;
			}
		}	
	}
	
	if (args == 4)
	{
		decl String:Method[64];
		GetCmdArg(4, Method, sizeof(Method));
		
		if (StrEqual(Method, "Found", false) || StrEqual(Method, "Drop", false))
			iMethod = 0;
		else if (StrEqual(Method, "Craft", false) || StrEqual(Method, "Crafted", false))
			iMethod = 1;
		else if (StrEqual(Method, "Trade", false) || StrEqual(Method, "Traded", false))
			iMethod = 2;
		else if (StrEqual(Method, "Buy", false) || StrEqual(Method, "bought", false) || StrEqual(Method, "store", false))
			iMethod = 3;
		else if (StrEqual(Method, "Unbox", false) || StrEqual(Method, "Unboxed", false) || StrEqual(Method, "Uncrate", false) || StrEqual(Method, "crate", false))
			iMethod = 4;
		else if (StrEqual(Method, "Gift", false))
			iMethod = 5;
		//6 is not used
		//7 is not used
		else if (StrEqual(Method, "Earned", false))
			iMethod = 8;
		else if (StrEqual(Method, "Refund", false) || StrEqual(Method, "Refunded", false))
			iMethod = 9;
		else if (StrEqual(Method, "Wrapped", false) || StrEqual(Method, "Wrap", false))
			iMethod = 10;
		//11 = prints "(null)"
		//12 = unused
		//Loops back to 0
		else
		{
			iMethod = StringToInt(Method);
			if (iMethod > 10 || iMethod < 0 || StrEqual(Method, "help", false) || StrEqual(Method, "list", false))
			{
				ReplyToCommand(client, "\nInvalid or unknown method given.\nPlease use one of the following, or their int values:\n  - Found\n  - Craft\n  - Trade\n  - Buy\n  - Unbox\n  - Gift\n  - Earned\n  - Refund\n  - Wrapped");
				return Plugin_Handled;
			}
		}	
	}
	
	for (new i=0; i<target_count; i++)
	{
		new Handle:hEvent = CreateEvent("item_found");
		if (hEvent == INVALID_HANDLE)
			return Plugin_Handled;
	 
		SetEventInt(hEvent, "player", target_list[i]);
		SetEventInt(hEvent, "quality", iQuality);
		SetEventInt(hEvent, "method", iMethod);
		SetEventInt(hEvent, "itemdef", iItem);
		SetEventBool(hEvent, "isfake", true);
		
		FireEvent(hEvent);
	}	
	return Plugin_Handled;
}

public Action:PrintFakeItem2(client, args)
{
	if (args != 3)
	{
		ReplyToCommand(client, "Usage: sm_fakeitem2 <client> <item method> <\"item name\">");
		return Plugin_Handled;
	}
	
	decl String:player[64];
	GetCmdArg(1, player, sizeof(player));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	decl String:sItemMethod[64];
	GetCmdArg(2, sItemMethod, sizeof(sItemMethod));
		
	if (StrEqual(sItemMethod, "Found", false) || StrEqual(sItemMethod, "Drop", false))
		Format(sItemMethod, sizeof(sItemMethod), "has found:");
	else if (StrEqual(sItemMethod, "Craft", false) || StrEqual(sItemMethod, "Crafted", false))
		Format(sItemMethod, sizeof(sItemMethod), "has crafted:");
	else if (StrEqual(sItemMethod, "Trade", false) || StrEqual(sItemMethod, "Traded", false))
		Format(sItemMethod, sizeof(sItemMethod), "has traded for:");
	else if (StrEqual(sItemMethod, "Buy", false) || StrEqual(sItemMethod, "bought", false) || StrEqual(sItemMethod, "store", false))
		Format(sItemMethod, sizeof(sItemMethod), "has purchased:");
	else if (StrEqual(sItemMethod, "Unbox", false) || StrEqual(sItemMethod, "Unboxed", false) || StrEqual(sItemMethod, "Uncrate", false) || StrEqual(sItemMethod, "crate", false))
		Format(sItemMethod, sizeof(sItemMethod), "has unboxed:");
	else if (StrEqual(sItemMethod, "Gift", false))
		Format(sItemMethod, sizeof(sItemMethod), "has received a gift:");
	else if (StrEqual(sItemMethod, "Earned", false))
		Format(sItemMethod, sizeof(sItemMethod), "has earned:");
	else if (StrEqual(sItemMethod, "Refund", false) || StrEqual(sItemMethod, "Refunded", false))
		Format(sItemMethod, sizeof(sItemMethod), "has been refunded:");
	else if (StrEqual(sItemMethod, "Wrapped", false) || StrEqual(sItemMethod, "Wrap", false))
		Format(sItemMethod, sizeof(sItemMethod), "has wrapped a gift:");
	//if none of this shit is found, we'll just use whatever the user typed.
	
	decl String:sItemName[64];
	GetCmdArg(3, sItemName, sizeof(sItemName));
	
	decl String:sMessage[256];
	
	for (new i=0; i<target_count; i++)
	{
		Format(sMessage, sizeof(sMessage), "\x03%N\x01 %s \x06%s", target_list[i], sItemMethod, sItemName);
		new Handle:buffer = StartMessageAll("SayText2");
		if (buffer != INVALID_HANDLE) 
		{
			BfWriteByte(buffer, target_list[i]);
			BfWriteByte(buffer, true);
			BfWriteString(buffer, sMessage);
			EndMessage();
		}
	}
	return Plugin_Handled;
}
