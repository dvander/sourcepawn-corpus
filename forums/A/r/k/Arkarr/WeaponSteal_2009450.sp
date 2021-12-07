#include <sourcemod>
#include <sdkhooks>
#include <kvizzle>
#include <tf2items_giveweapon>

new Handle:ArrayWeapons = INVALID_HANDLE;
new bool:PluginEnabled;

public Plugin:myinfo =  
{  
    name = "Weapon Stealer",  
    author = "Arkarr",  
    description = "Allow to steal weapons from other players.",  
    version = "3.0",  
    url = "http://www.sourcemod.net/"  
}; 

public OnPluginStart()  
{ 	
	ArrayWeapons = CreateArray(255);
	
	PluginEnabled = StoreWeapons();
	
	if(!PluginEnabled)
	{
		PrintToServer("[Weapon Steal] ERROR: Can't read data from 'items_game.txt'. Can't load the plugin correctly.");
	}
}

public OnEntityCreated(entity, const String:classname[])
{
    if(StrContains(classname, "tf_ammo_pack", true) != -1)
    {
        SDKHook(entity, SDKHook_Touch, PickedLarge);
    }
}

public PickedLarge(entity, client)
{
	if(IsValidClient(client) && PluginEnabled)
	{
		decl String:m_ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
		new index = FindStringInArray(ArrayWeapons, m_ModelName);
		if(index != -1)
		{
			decl String:StringIndex[10];
			GetArrayString(ArrayWeapons, index-1, StringIndex, sizeof(StringIndex));
			new wep_index = StringToInt(StringIndex);
			TF2Items_GiveWeapon(client, wep_index);
		}
	}
}

stock bool:StoreWeapons()
{
	decl String:path[PLATFORM_MAX_PATH] = "./scripts/items/items_game.txt";
	decl String:itemIndex[40];
	decl String:modelPath[255];
	decl String:itemClass[50];
	new Handle:kv = KvizCreateFromFile("items_game", path);

	if(!FileExists(path))
	{
		return false;
	}
	
	for(new i = 1; KvizExists(kv, "items:nth-child(%i)", i); i++)
	{
		KvizGetStringExact(kv, itemClass, sizeof(itemClass), "items:nth-child(%i).item_class", i);
		
		if(StrContains(itemClass, "tf_weapon", true) != -1)
		{
			KvizGetStringExact(kv, itemIndex, sizeof(itemIndex), "items:nth-child(%i):key", i);
			KvizGetStringExact(kv, modelPath, sizeof(modelPath), "items:nth-child(%i).model_player", i);
			PushArrayString(ArrayWeapons, itemIndex);
			PushArrayString(ArrayWeapons, modelPath);
		}
	}
	
	return true;
}

stock bool:IsValidClient(iClient, bool:bReplay = true) {
    if(iClient <= 0 || iClient > MaxClients)
        return false;
    if(!IsClientInGame(iClient))
        return false;
    if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
        return false;
    return true;
}
