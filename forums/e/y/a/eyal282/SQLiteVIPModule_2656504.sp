#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new const String:PLUGIN_VERSION[] = "1.0";

public Plugin:myinfo = 
{
	name = "SQLite VIP Module",
	author = "Eyal282",
	description = "An example module plugin for SQLite VIP API",
	version = PLUGIN_VERSION,
	url = ""
}

new Handle:hTimer_Rewards[MAXPLAYERS+1];
/**

*	@note			This forward is called when SQLite VIP API has connected to it's database.

*/
forward SQLiteVIPAPI_OnDatabaseConnected();

/**

* @param client		Client index that was authenticated.
* @param VIPLevel	VIP Level of the client, or 0 if the player is not VIP.
 
* @note				This forward is called for non-vip players as well as VIPs.
* @note				With the proper cvars, this isn't guaranteed to be called once, given the VIP Level of the VIP has decreased due to expiration of a better level / all of the levels.
* @noreturn		
*/

forward SQLiteVIPAPI_OnClientAuthorized(client, &VIPLevel);

/**

* @param client			Client index that changed his preference.
* @param FeatureSerial	Feature serial whose setting was changed.
* @param SettingValue	The new setting of the feature the client has set.
 
* @note					This forward is called whenever a client changes his feature preference.
* @note					This can be easily spammed by a client, and therefore should be noted.
* @noreturn		
*/

forward SQLiteVIPAPI_OnClientFeatureChanged(client, FeatureSerial, SettingValue);
/**

* @return			true if SQLite VIP API has connected to the database already, false otherwise.

*/

native SQLiteVIPAPI_IsDatabaseConnected();
/**

* @param client		Client index to check.
 
* @note				This forward is called for non-vip players as well as VIPs.
* @note				With the proper cvars, this isn't guaranteed to be called once, given the VIP Level of the VIP has decreased due to expiration of a better level / all of the levels.

* @return			VIP Level of the client, or 0 if the client is not a VIP. returns -1 if client was yet to be authenticated. If an error is thrown, returns -2 instead.

* @error			Client index is not in-game.
*/

native SQLiteVIPAPI_GetClientVIPLevel(client);

/**
* @param FeatureName	The name of the feature to be displayed in !settings.
* @param VIPLevelList	An arrayList containing each setting's VIP Level requirement
* @param NameList		An arrayList containing each setting's Name
* @param AlreadyExisted	Optional param to determine if the feature's name has already existed and therefore no feature was added. 

* @note					Only higher settings should be allowed to have higher VIP Levels than their lower ones.
* @note					You can execute this on "OnAllPluginsLoaded" even if the database is broken it'll still cache it.

* @return				Feature serial ID on success, 
* @error				List of setting variations exceed 25 ( it's too much anyways  )
*/

native bool:SQLiteVIPAPI_AddFeature(const String:FeatureName[64], Handle:VIPLevelList, Handle:NameList, &bool:AlreadyExisted=false);

/**

* @param client			Client index to check.
* @param FeatureSerial	Feature serial whose setting to find.

* @note 				Reduces to highest allowed value for the client if he lost a VIP status.
* @note					Returns -1 if the feature is entirely out of the client's league VIP wise. If an error is thrown, returns -2 instead.

* @return				Client's VIP setting for the feature given by the serial.

* @error				Client index is not in-game.

*/

native SQLiteVIPAPI_GetClientVIPFeature(client, FeatureSerial);

new HPFeatureSerial = -1;
new ArmorFeatureSerial = -1;
new HelmetFeatureSerial = -1;

public OnMapStart()
{
	for(new i=1;i <= MAXPLAYERS;i++)
		hTimer_Rewards[i] = INVALID_HANDLE;
}
public OnPluginStart()
{
	if(SQLiteVIPAPI_IsDatabaseConnected())
		SQLiteVIPAPI_OnDatabaseConnected();
		
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public OnClientDisconnect(client)
{
	if(hTimer_Rewards[client] != INVALID_HANDLE)
	{
		CloseHandle(hTimer_Rewards[client]);
		hTimer_Rewards[client] = INVALID_HANDLE;
	}
}

public SQLiteVIPAPI_OnDatabaseConnected()
{
	new String:Name[64];
	
	new Handle:Array_VIPLevelList = CreateArray(1);
	new Handle:Array_NameList = CreateArray(64);
	
	for(new i=0;i <= 10;i++)
	{
		PushArrayCell(Array_VIPLevelList, RoundToFloor(float(i)/ 2.0));
		IntToString(i*2, Name, sizeof(Name));
		
		PushArrayString(Array_NameList, Name);
	}
	
	HPFeatureSerial = SQLiteVIPAPI_AddFeature("Health", Array_VIPLevelList, Array_NameList);
	ArmorFeatureSerial = SQLiteVIPAPI_AddFeature("Armor", Array_VIPLevelList, Array_NameList);
	
	ClearArray(Array_NameList);
	ClearArray(Array_VIPLevelList);	
	
	PushArrayCell(Array_VIPLevelList, 2);
	PushArrayString(Array_NameList, "Disabled");
	
	PushArrayCell(Array_VIPLevelList, 2);
	PushArrayString(Array_NameList, "Enabled");
	
	HelmetFeatureSerial = SQLiteVIPAPI_AddFeature("Helmet", Array_VIPLevelList, Array_NameList);
	
	CloseHandle(Array_NameList);
	CloseHandle(Array_VIPLevelList);
}

public Event_PlayerSpawn(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(HPFeatureSerial == -1 || ArmorFeatureSerial == -1 || HelmetFeatureSerial == -1)
	{
		if(SQLiteVIPAPI_IsDatabaseConnected())
			SQLiteVIPAPI_OnDatabaseConnected();
			
		return;
	}
	
	new UserId = GetEventInt(hEvent, "userid");
	
	new client = GetClientOfUserId(UserId);
	
	if(hTimer_Rewards[client] != INVALID_HANDLE)
	{
		CloseHandle(hTimer_Rewards[client]);
		hTimer_Rewards[client] = INVALID_HANDLE;
	}
	
	hTimer_Rewards[client] = CreateTimer(1.0, Timer_Rewards, UserId);
}

public Action:Timer_Rewards(Handle:hTimer, UserId)
{
	new client = GetClientOfUserId(UserId)
	
	if(client == 0)
		return;
	
	new HPSetting = SQLiteVIPAPI_GetClientVIPFeature(client, HPFeatureSerial);
	new ArmorSetting = SQLiteVIPAPI_GetClientVIPFeature(client, ArmorFeatureSerial);
	new HelmetSetting = SQLiteVIPAPI_GetClientVIPFeature(client, HelmetFeatureSerial);
	
	SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + HPSetting*2);
	SetEntProp(client, Prop_Send, "m_ArmorValue", GetEntProp(client, Prop_Send, "m_ArmorValue") + ArmorSetting*2);
	
	if(HelmetSetting != 0)
		SetEntProp(client, Prop_Send, "m_bHasHelmet", true);
	
	hTimer_Rewards[client] = INVALID_HANDLE;
} 