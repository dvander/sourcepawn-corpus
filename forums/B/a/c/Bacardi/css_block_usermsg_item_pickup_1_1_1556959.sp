#define PLUGIN_VERSION "1.1"
new bool:bypass = false;


public Plugin:myinfo =
{
	name = "[CS:S] Block usermessages item_pickup",
	author = "Bacardi",
	description = "Block all usermessages item_pickup to not show items players screen when buy, kevlars, nightvision",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
    CreateConVar("block_usermsgs_item_pickup_version", PLUGIN_VERSION, "Block usermessages item_pickup version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("item_pickup", event_pickup, EventHookMode_Post);

	HookUserMessage(GetUserMessageId("ItemPickup"), TextMsg, true);
}

public event_pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
/*
	"userid"		"short"
	"item"		"string"	// either a weapon such as 'tmp' or 'hegrenade', or an item such as 'nvgs'
*/

	decl String:item[60], bool:nvgs;
	item[0] = '\0';
	nvgs = false;

	GetEventString(event, "item", item, sizeof(item));

	if(StrContains(item, "vest", false) != -1 || (nvgs = StrEqual(item, "nvgs", false)))
	{
		decl client;
		client = GetClientOfUserId(GetEventInt(event, "userid"));
		//PrintToServer("%N %s", client, item);

		if(nvgs)
		{
			Format(item, sizeof(item), "item_nvgs");
		}
		else
		{
			Format(item, sizeof(item), "%s", StrEqual(item, "vest", false) ? "item_kevlar":"item_assaultsuit");
		}

		// start message
		new Handle:hBf = StartMessageOne("ItemPickup", client);
    
		if(hBf != INVALID_HANDLE)
		{
			//PrintToServer("%N %s", client, item);

			bypass = true;
			BfWriteString(hBf, item);
			EndMessage();
		}
	}
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if(bypass)
	{
		//PrintToServer("print")
		bypass = false;
		return Plugin_Continue;
	}

	//PrintToServer("block")
	return Plugin_Handled;
}