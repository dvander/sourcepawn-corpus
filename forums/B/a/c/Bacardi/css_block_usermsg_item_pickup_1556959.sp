#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[CS:S] Block usermessages item_pickup",
	author = "Bacardi",
	description = "Block all usermessages item_pickup to not show items from his screen when buy, kevlars, nightvision",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{

    CreateConVar("block_usermsgs_item_pickup_version", PLUGIN_VERSION, "Block usermessages item_pickup version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookUserMessage(GetUserMessageId("ItemPickup"), TextMsg, true);
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{

	return Plugin_Handled;
}