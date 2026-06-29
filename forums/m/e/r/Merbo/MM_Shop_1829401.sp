#pragma semicolon 1 
#include <sourcemod>
#include <tf2_stocks>
#define REQUIRE_EXTENSIONS
#include <tf2items>

//#define DEBUG

//Some methods are taken from tf2items_manager.sp
//This is an attempt to get a tf2items system to work with SQL, so people may purchase access to a tf2items item through SQL (using even a credits system from ranking)

/* Todo with this plugin:
* 
* - Get modified items working always, not just in certain situations.
* 
* - Introduce the credits system.
*   1 kill = +10 credits
*   1 bot kill = +1 credit
*   1 domination = +30 credits
*   1 MvM credit = 1 credit
*   1 death = -2 credits
*   1 suicide = -10 credits
*   
*   Credits cannot go negative, obviously (virtual monetary value, debt is rediculous in a game)
*   1 scrap = 111 credits (1/9th * 1000)
*   1 refined metal = 1000 credits (base value)
*   1 key = 2555 credits (if 1 key = 2.55ref)
*   1 buds = 69000 credits (if 1 buds = 27 keys)
* 
* - Possibly create a trade bot to allow for the tf2 items credits values, this will make my life easier if people choose to "cash in" items for credits
* 
*/
new String:error[255];
new Handle:db = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "MerbosMagic Shop Plugin",
	author = "Merbo",
	description = "!Shop - allows showing of the shop, and buying of items",
	version = "1.2",
	url = "http://merbosmagic.co.cc"
}

public OnPluginStart()
{
	RegConsoleCmd("shop", showShop, "Shows the MerbosMagic Custom Weapons Shop to the caller");
	HookEvent("mvm_pickup_currency", Event_MvM_grabCash);
	HookEvent("player_death", Event_playerDeath);
	db = SQL_Connect("tf2-shop", false, error, sizeof(error));
}

public Action:showShop(client, args)
{
	if (client)
	{
		ShowMOTDPanel(client, "MerbosMagic Custom Items Shop", "http://merbosmagic.co.cc/TF2/Shop.aspx", MOTDPANEL_TYPE_URL);
	} 
	return Plugin_Handled;
}

public Event_playerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new String:VictimName[63];
	new String:KillerName[63];
	
	new String:query[127];
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	GetClientAuthString(victim, VictimName, sizeof(VictimName));
	GetClientAuthString(killer, KillerName, sizeof(KillerName));
	
	if (victim != killer)
	{
		if (GetEventInt(event, "death_flags") & TF_DEATHFLAG_KILLERDOMINATION)
		{
			Format(query, sizeof(query), "UPDATE users SET credits = credits + 30 WHERE steamid='%s'", KillerName);
			SQL_Query(db, query);
		}
		Format(query, sizeof(query), "UPDATE users SET credits = credits + 10 WHERE steamid='%s'", KillerName);
		SQL_Query(db, query);
		Format(query, sizeof(query), "UPDATE users SET credits = credits - 2 WHERE steamid='%s'", VictimName);
		SQL_Query(db, query);
	}
	else
	{
		Format(query, sizeof(query), "UPDATE users SET credits = credits - 10 WHERE steamid='%s'", VictimName);
		SQL_Query(db, query);
	}
}

public Event_MvM_grabCash(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:clientSteamID[63];
	new String:query[127];
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new cashAmount = GetEventInt(event, "currency");
	
	GetClientAuthString(client, clientSteamID, sizeof(clientSteamID));
	
	Format(query, sizeof(query), "UPDATE users SET credits = credits + %d WHERE steamid='%s'", cashAmount, clientSteamID);
}

public Action:TF2Items_OnGiveNamedItem(iClient, String:strClassName[], iItemDefinitionIndex, &Handle:hItemOverride)
{
	
	if (hItemOverride != INVALID_HANDLE)
		return Plugin_Continue; // Plugin_Changed from elsehwere
	
	// Find item.
	new Handle:hItem = INVALID_HANDLE;
	hItem = FindItem(iClient, iItemDefinitionIndex, strClassName);
	if (hItem != INVALID_HANDLE)
	{
		hItemOverride = hItem;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

Handle:FindItem(iClient, iItemDefinitionIndex, String:classname[])
{
	new String:steamid[64];
	new String:cmd[256];
	new String:items[2048];
	new String:itemToFind[8];
	new String:tmp[8];
	new Handle:query;
	new Handle:hOutput = INVALID_HANDLE;
	
	#if defined DEBUG
	PrintToConsole(iClient, "iItemDefinitionIndex = %d", iItemDefinitionIndex);
	PrintToConsole(iClient, "steamid = %s", steamid);
	#endif
	
	GetClientAuthString(iClient, steamid, sizeof(steamid));
	
	Format(cmd, sizeof(cmd), "SELECT items FROM users WHERE steamid='%s'", steamid);
	query = SQL_Query(db, cmd);
	if (SQL_GetRowCount(query) > 0)
	{
		SQL_FetchRow(query);
		if (SQL_GetFieldCount(query) > 0)
		{
			SQL_FetchString(query, 0, items, sizeof(items));
			#if defined DEBUG
			PrintToConsole(iClient, "items = %s", items);
			#endif
		}
	}
	else
	return hOutput;
	CloseHandle(query);
	
	Format(cmd, sizeof(cmd), "SELECT modid FROM items WHERE itemid=%d", iItemDefinitionIndex);
	query = SQL_Query(db, cmd);
	if (SQL_GetRowCount(query) > 0)
	{
		SQL_FetchRow(query);
		if (SQL_GetFieldCount(query) > 0)
		{
			SQL_FetchString(query, 0, tmp, sizeof(tmp));
			#if defined DEBUG
			PrintToConsole(iClient, "tmp = %s", tmp);
			#endif
		}
	}
	else
	return hOutput;
	CloseHandle(query);
	
	Format(itemToFind, sizeof(itemToFind), "; %s ", tmp);
	#if defined DEBUG
	PrintToConsole(iClient, "itemToFind = %s", itemToFind);
	#endif
	
	if (StrContains(items, itemToFind) != -1)
	{
		#if defined DEBUG
		PrintToConsole(iClient, "StrContains(items, itemToFind) = %d", StrContains(items, itemToFind));
		#endif
		new itemLevel;
		new itemQuality;
		new itemNumAttributes;
		new preserve_attributes;
		new String:itemAttributeFull[16];
		//new itemAttributeID;
		//new Float:itemAttributeValue;
		
		Format(cmd, sizeof(cmd), "SELECT preserve_attributes,level,quality,num_tf2_attributes FROM items WHERE itemid=%d", iItemDefinitionIndex);
		query = SQL_Query(db, cmd);
		if (SQL_GetRowCount(query) > 0)
		{
			SQL_FetchRow(query);
			if (SQL_GetFieldCount(query) == 4)
			{
				preserve_attributes = SQL_FetchInt(query, 0);
				itemLevel = SQL_FetchInt(query, 1);
				itemQuality = SQL_FetchInt(query, 2);
				itemNumAttributes = SQL_FetchInt(query, 3);
				#if defined DEBUG
				PrintToConsole(iClient, "preserve_attributes = %d", preserve_attributes);
				PrintToConsole(iClient, "itemLevel = %d", itemLevel);
				PrintToConsole(iClient, "itemQuality = %d", itemQuality);
				PrintToConsole(iClient, "itemNumAttributes = %d", itemNumAttributes);
				#endif
			}
		}
		else
			return hOutput;
		
		if (preserve_attributes == 0)
			hOutput = TF2Items_CreateItem(OVERRIDE_ALL);
		else
		hOutput = TF2Items_CreateItem(OVERRIDE_ALL | PRESERVE_ATTRIBUTES);
		
		TF2Items_SetLevel(hOutput, itemLevel);
		TF2Items_SetQuality(hOutput, itemQuality);
		TF2Items_SetClassname(hOutput, classname);
		TF2Items_SetItemIndex(hOutput, iItemDefinitionIndex);
		
		if (preserve_attributes == 0)
			TF2Items_SetFlags(hOutput, OVERRIDE_ALL);
		else
		TF2Items_SetFlags(hOutput, OVERRIDE_ALL | PRESERVE_ATTRIBUTES);
		
		
		for (new i = 0; i < itemNumAttributes; i++)
		{
			new String:Split[2][8];
			
			Format(cmd, sizeof(cmd), "SELECT attribute_tf2_%d FROM items WHERE itemid=%d", i + 1, iItemDefinitionIndex);
			query = SQL_Query(db, cmd);
			if (SQL_GetRowCount(query) == 1)
			{
				SQL_FetchRow(query);
				if (SQL_GetFieldCount(query) == 1)
				{
					SQL_FetchString(query, 0, itemAttributeFull, sizeof(itemAttributeFull));
					#if defined DEBUG
					PrintToConsole(iClient, "itemAttributeFull = %s", itemAttributeFull);
					#endif
				}
			}
			CloseHandle(query);
			
			ReplaceString(itemAttributeFull, sizeof(itemAttributeFull), " ", "");
			
			ExplodeString(itemAttributeFull, ";", Split, 2, 8);
			
			#if defined DEBUG
			PrintToConsole(iClient, "TF2Items_SetAttribute(hOutput, %d, %d, %f)", i, StringToInt(Split[0]), StringToFloat(Split[1]));
			#endif
			TF2Items_SetAttribute(hOutput, i, StringToInt(Split[0]), StringToFloat(Split[1]));
		}
	}
	CloseHandle(db);
	return hOutput;
}
/* IsValidClient()
*
* Checks if a client is valid.
* --------------------------------------------------------------------------
bool:IsValidClient(iClient)
{
if (iClient < 1 || iClient > MaxClients)
	return false;
if (!IsClientConnected(iClient))
	return false;
return IsClientInGame(iClient);
*/
