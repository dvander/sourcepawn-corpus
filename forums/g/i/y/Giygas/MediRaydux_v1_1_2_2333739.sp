/*
 * MediRay
 *
 * Allows players to equip a MediRay that heals teammates near them @ 10hp/s
 * 
 * When equipped ubers last 6s compared to 9s regular uber
 * Version 0.9
 * - Initial release 
 *
 *  Version 0.91
 * - Added lots of convars
 *
 *  Version 1.01
 * - Fixed some junk code. Not much else happened, other than me being an idiot.
 *
 *  Version 1.1
 * - Changed the version cvar, to make it stand out from the original. 
 * - Updater added! Automatic plugin updates!
 *
 *  Version 1.1.1
 * - Changed the cvar names, to make it stand out from the original. 
 * - Unfucked some stuff.
 *
 *  Version 1.1.2
 * - Changed the cvar names in the checks, I derped in 1.1.1 and missed some stuff. "Unfucked some stuff." will now be a running joke with me, because I mess everything up and should feel bad.
 * - Thank you, RavensBro, for providing the updated, fixed model for the Mediray-dar. I'll be using this, until it breaks from an update, and from then, the cycle continues.
 * - Unfucked some stuff.
 */
#define PLUGIN_VERSION "1.1.2"
 
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <clientprefs>
#include <tf2>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "https://goldclaimers.net/mediraydux/updateme.txt"

#define MODEL_MEDIRAY					"models/mediray_v3/mediray.mdl"

// ---- Engine flags ---------------------------------------------------------------
#define EF_BONEMERGE            (1 << 0)
#define EF_BRIGHTLIGHT          (1 << 1)
#define EF_DIMLIGHT             (1 << 2)
#define EF_NOINTERP             (1 << 3)
#define EF_NOSHADOW             (1 << 4)
#define EF_NODRAW               (1 << 5)
#define EF_NORECEIVESHADOW      (1 << 6)
#define EF_BONEMERGE_FASTCULL   (1 << 7)
#define EF_ITEM_BLINK           (1 << 8)
#define EF_PARENT_ANIMATES      (1 << 9)

#define RED_TEAM				2
#define BLUE_TEAM				3

new m_clrRender;
new m_nPlayerCond;
new usingMediRayDar[MAXPLAYERS];
new bool:enabled = true;
new bool:lateLoaded = false;

new mediRayModelIndex;
new curMsg;

//cvars
new Handle:c_Enabled	= INVALID_HANDLE;
new Handle:c_Distance	= INVALID_HANDLE;
new Handle:c_HealRate	= INVALID_HANDLE;
new Handle:c_UberTime	= INVALID_HANDLE;
new Handle:c_HealSelf	= INVALID_HANDLE;

new Float:distance;
new healRate;
new Float:uberDrain;
new bool:healSelf;

// --- SDK variables ---------------------------------------------------------------
new bool:g_bSdkStarted = false;
new Handle:g_hSdkEquipWearable;

//Cookies!
new Handle:pMediray;

public Plugin:myinfo = 
{
	name = "[TF2] MediRay [Redux]",
	author = "fox (Plugin modified and updated by Giygas)",
	description = "Lets medics equip the Mediray-Dar",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
}

new const TFClass_MaxHealth[TFClassType][1] = 
{
  {50}, {125}, {125}, {200}, {175}, 
  {150}, {300}, {175}, {125}, {125}
};

public OnPluginStart()
{
	CreateConVar("sm_mediray_version", PLUGIN_VERSION, "[TF2] MediRay [Redux]", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	c_Enabled	= CreateConVar("sm_mediraydux_enable",		"1",	"<0/1> Enable or disable MediRay completely.");
	c_Distance	= CreateConVar("sm_mediraydux_distance",	"200",	"<1-500> How far away can others be from the medic to be healed?");
	c_HealRate	= CreateConVar("sm_mediraydux_healrate",	"10",	"<1-100> Heal rate per second, HP/s");
	c_UberTime	= CreateConVar("sm_mediraydux_ubertime",	"5.0",	"<0.1-8.0> Time it should consume Ubers in seconds");
	c_HealSelf	= CreateConVar("sm_mediraydux_healself",	"1",	"<0/1> Should MediRay heal the player using it as well?");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_changeclass", Event_PlayerChangeClass);
	
	m_clrRender = FindSendPropInfo("CTFPlayer", "m_clrRender");
	m_nPlayerCond = FindSendPropInfo("CTFPlayer","m_nPlayerCond");
	
	// Startup extended stocks
	TF2_SdkStartup();
	
	RegConsoleCmd("mediray",               Cmd_MediRay, "Enables/Disables Mediray");
	
	/******************
	 * Cookies!       *
	 ******************/
	//creds and dice are only used for the transition phase, meaning they are read only
	pMediray 	= RegClientCookie("mediray",		"Mediray Enabled", 	CookieAccess_Protected);

	//Updater stuff
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

// if the plugin was loaded late we have a bunch of initialization that needs to be done
public APLRes:AskPluginLoad2(Handle:hPlugin, bool:isAfterMapLoaded, String:error[], err_max)
{	
	lateLoaded = isAfterMapLoaded;
}

public OnConfigsExecuted()
{	
	//Delete any MediRay remnants
	deleteMediRayEntities();
	
	HookConVarChange(c_Enabled, ConVarChange_Enabled);
	HookConVarChange(c_Distance, ConVarChange_Distance);
	HookConVarChange(c_HealRate,ConVarChange_HealRate);
	HookConVarChange(c_UberTime,ConVarChange_UberTime);
	HookConVarChange(c_HealSelf,ConVarChange_HealSelf);
	
	///////////////////////////
	//Setup gloabl variables //
	///////////////////////////
	enabled = GetConVarBool(c_Enabled);
	healSelf = GetConVarBool(c_HealSelf);
	distance = float(GetConVarInt(c_Distance));
	healRate = RoundFloat(float(GetConVarInt(c_HealRate)) / 10.0);
	new Float:percentDifference = 1.0 - (0.125 * GetConVarFloat(c_UberTime));
	uberDrain = percentDifference / (10.0 * GetConVarFloat(c_UberTime));
	
	/******************
	 * On late load   *
	 ******************/
	if (lateLoaded)
	{
		for(new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i))
			{
				new String:temp[128];
				GetClientCookie(i, pMediray, temp, sizeof(temp));
				
				usingMediRayDar[i] = StringToInt(temp);
				
				if(IsPlayerAlive(i) && TF2_GetPlayerClass(i) == TFClass_Medic)
					CreateTimer(0.0, equipMediray_Timer, i);
			}
		}
		
		lateLoaded = false;
	}
}

public ConVarChange_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(c_Enabled) != 0 && GetConVarInt(c_Enabled) != 1)
	{
		LogMessage("sm_mediray_enable must be 0 or 1!");
		enabled = true;
		SetConVarBool(c_Enabled, true);
		return;
	}
	
	if(GetConVarBool(c_Enabled))
	{
		enabled = true;
	}else
	{
		PrintToChatAll("[SM] Mediray DISABLED!");
		enabled = false;
		deleteMediRayEntities();
		
	}
}

public ConVarChange_HealSelf(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(c_HealSelf) != 0 && GetConVarInt(c_HealSelf) != 1)
	{
		LogMessage("sm_mediraydux_healself must be 0 or 1!");
		
		//revert to default
		healSelf = true;
		SetConVarBool(c_HealSelf, true);
		return;
	}
	
	if(GetConVarBool(c_Enabled))
	{
		healSelf = true;
	}else
	{
		healSelf = false;
		
	}
}

public ConVarChange_Distance(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(c_Distance) < 1  || GetConVarInt(c_Distance) > 500)
	{
		LogMessage("sm_mediraydux_distance must between 0 and 500!");
		
		//revert to default
		SetConVarInt(c_Distance, 200);
		return;
	}
	
	distance = float(GetConVarInt(c_Distance));
}


public ConVarChange_HealRate(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(c_HealRate) < 1  || GetConVarInt(c_HealRate) > 100)
	{
		LogMessage("sm_mediraydux_healrate must between 1 and 100!");
		
		//revert to default
		SetConVarInt(c_HealRate, 10);
		return;
	}
	
	healRate = RoundFloat(float(GetConVarInt(c_HealRate)) / 10.0);
}

public ConVarChange_UberTime(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarFloat(c_UberTime) < 0.1  || GetConVarFloat(c_UberTime) > 8.0)
	{
		LogMessage("sm_mediraydux_ubertime must between 0.1 and 8!");
		
		//revert to default
		SetConVarFloat(c_UberTime, 5.0);
	}
	
	//Constant Drain = (1 / RegularTotalUberTime)
	//Constant Drain = (1 / 8) 
	//Constant Drain = 0.125;
	
	//how much of a percentage is left after the reduced uber time
	new Float:percentDifference = 1.0 - (0.125 * GetConVarFloat(c_UberTime));
	
	uberDrain = percentDifference / (10.0 * GetConVarFloat(c_UberTime));
	//LogMessage("%f",uberDrain);
}

public OnPluginEnd()
{
	//Delete any MediRay remnants
	deleteMediRayEntities();
}

public OnMapStart()
{
	//MediRay-DAR
	AddFileToDownloadsTable("models/mediray_v3/mediray.dx80.vtx");
	AddFileToDownloadsTable("models/mediray_v3/mediray_dar.dx90.vtx");
	AddFileToDownloadsTable("models/mediray_v3/mediray_dar.mdl");
	AddFileToDownloadsTable("models/mediray_v3/mediray.sw.vtx");
	AddFileToDownloadsTable("models/mediray_v3/mediray.vvd");
	
	AddFileToDownloadsTable("materials/models/mediray_v3/invulnfx_blue.vmt");
	AddFileToDownloadsTable("materials/models/mediray_v3/invulnfx_red.vmt");
	AddFileToDownloadsTable("materials/models/mediray_v3/medidish_blue.vmt");
	AddFileToDownloadsTable("materials/models/mediray_v3/medidish_blue.vtf");
	AddFileToDownloadsTable("materials/models/mediray_v3/medidish_meter_blue.vmt");
	AddFileToDownloadsTable("materials/models/mediray_v3/medidish_meter_red.vmt");
	AddFileToDownloadsTable("materials/models/mediray_v3/medidish_red.vmt");
	AddFileToDownloadsTable("materials/models/mediray_v3/medidish_red.vtf");
	
	mediRayModelIndex = PrecacheModel(MODEL_MEDIRAY, true);
	
	CreateTimer(120.0,  	Timer_ShowInfo, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Cmd_MediRay(client, iArgs)
{
	// Not allowed if not ingame.
	if (client == 0) { ReplyToCommand(client, "[TF2] Command is in-game only."); return Plugin_Handled; }
	
	
	// Check if the user doesn't have permission. If not, ignore command.
	if (usingMediRayDar[client])
	{
		usingMediRayDar[client] = false;
		PrintCenterText(client, "MediRay has been removed");
		
		if(AreClientCookiesCached(client))
			SetClientCookie(client, pMediray, "0");
			
	}else{
		usingMediRayDar[client] = true;
		PrintCenterText(client, "MediRay will be equipped on spawn");
		
		if(AreClientCookiesCached(client))
			SetClientCookie(client, pMediray, "1");
	}

	return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!enabled)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(usingMediRayDar[client])
	{
		if(TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			//PrintToChatAll("Event_PlayerSpawn!");
			CreateTimer(0.0, equipMediray_Timer, client);
		}
	}
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!enabled)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;

	new TFClassType:class = TFClassType:GetEventInt(event, "class");
	new TFClassType:oldclass = TF2_GetPlayerClass(client);
	
	//player is the same class  :P
	if (class == oldclass)
		return;
	
	if(usingMediRayDar[client])
	{
		if(class == TFClass_Medic)
		{
			//PrintToChatAll("Player changed to Medic!");
			CreateTimer(1.0, equipMediray_Timer, client);
		}else{
			deleteOwnedMediRayEntities(client);
		}
	}
	
	return;
}

public OnClientDisconnect(client)
{
	new String:temp[32];
	Format(temp, sizeof(temp), "%i",usingMediRayDar[client]);
	if(AreClientCookiesCached(client))
		SetClientCookie(client, pMediray, temp);
	
	usingMediRayDar[client] = false;
}

 public OnClientPostAdminCheck(client)
{
	if (!IsClientInGame(client)) return;
	
	usingMediRayDar[client] = false;
	
	
	new String:temp[128];
	GetClientCookie(client, pMediray, temp, sizeof(temp));
	
	usingMediRayDar[client] = StringToInt(temp);
	
	if(IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
		CreateTimer(0.0, equipMediray_Timer, client);
}




public Action:Timer_ShowInfo(Handle:timer) 
{
	if(!enabled)
		return Plugin_Continue;
	
	if(curMsg == 0)
		PrintToChatAll("\x01\x04[Mediray] \x03Type:\x04 !mediray \x03to equip a mediray");
	
	if(curMsg == 1)
		PrintToChatAll("\x01\x04[Mediray] \x03Medirays heal nearby allies BUT consumes Ubers faster!");
	
	curMsg ++;
	if(curMsg > 2)
		curMsg = 0;
	
	return Plugin_Continue;
}

public Action:equipMediray(client)
{
	PrintHintText(client, "Mediray Equipped!");
	
	create_Self_MediRay(client);
}

public Action:create_Self_MediRay(client)
{
	// Create owner entity.
	new iEntity = TF2_SpawnWearable(client);
	if (iEntity != -1)
	{
		TF2_EquipWearable(client, iEntity);
		SetEntityModel(iEntity, MODEL_MEDIRAY);
		
		//The Datapack stores all the Spider's important values
		new Handle:dataPackHandle;
		CreateDataTimer(0.1, mediRay_Timer, dataPackHandle, TIMER_REPEAT |TIMER_FLAG_NO_MAPCHANGE);
		
		//Setup the datapack with appropriate information
		WritePackCell(dataPackHandle, iEntity); //entity
		WritePackCell(dataPackHandle, 1); //type of entity: 1 = werable(hat) | 2= attachable
		WritePackCell(dataPackHandle, client); //owner
	}
	else
	{
		LogError("Error while creating owner MediRay");
	}
	
}

public OnClientCookiesCached(client)
{	
	new String:temp[128];
	GetClientCookie(client, pMediray, temp, sizeof(temp));
	
	usingMediRayDar[client] = StringToInt(temp);
}

public Action:equipMediray_Timer(Handle:Timer, any:client)
{	
	if(!needsAttachment(client))
	{
		return Plugin_Stop;
	}
	
	deleteOwnedMediRayEntities(client);
	
	equipMediray(client);
	return Plugin_Stop;
}


public bool:needsAttachment(any:client)
{
	new ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "prop_physics")) != -1)
	{	
		new currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == mediRayModelIndex)
		{
			new parent = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
			if(parent == client)
				return false; 
		}
	}
	
	ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "tf_wearable_item")) != -1)
	{	
		new currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == mediRayModelIndex)
		{
			new parent = GetEntPropEnt(ent, Prop_Data, "m_pParent");
			if(parent == client)
				return false; 
		}
	}
	
	return true;
}

public Action:deleteOwnedMediRayEntities(any:client)
{
	//delete any attached medirays that the player owns
	new ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "prop_physics")) != -1)
	{	
		new currIndex = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		
		if(currIndex == mediRayModelIndex)
		{
			new parent = GetEntPropEnt(ent, Prop_Data, "m_pParent");
			if(parent == client)
				killEntityIn(ent, 0.1); 
		}
	}
	
	ent = -1;
	
	while ((ent = FindEntityByClassname(ent, "tf_wearable_item")) != -1)
	{	
		new currIndex = GetEntProp(ent, Prop_Data, "m_nModelIndex");
		
		if(currIndex == mediRayModelIndex)
		{
			new parent = GetEntPropEnt(ent, Prop_Data, "m_pParent");
			if(parent == client)
				killEntityIn(ent, 0.1); 
		}
	}
}

public Action:mediRay_Timer(Handle:timer, Handle:dataPackHandle)
{
	if(!enabled)
		return Plugin_Stop;
	
	ResetPack(dataPackHandle);
	new mediRay = ReadPackCell(dataPackHandle);
	new typeOfEntity = ReadPackCell(dataPackHandle);
	new savedOwner = ReadPackCell(dataPackHandle);
	
	////////////////////////////////////////
	//Determine if the timer should stop  //
	////////////////////////////////////////
	if(savedOwner >= 1 && savedOwner <= MaxClients)
	{
		if(IsClientInGame(savedOwner))
		{
			if(TF2_GetPlayerClass(savedOwner) != TFClass_Medic)
			{
				//PrintToChatAll("Stopped Timer: Owner is not Medic!");
				deleteOwnedMediRayEntities(savedOwner);
				return Plugin_Stop;
			}
		}
	}
	
	if(!IsValidEntity(mediRay))
	{
		//PrintToChatAll("Removing Invalid: %i|%i",mediRay,typeOfEntity);
		
		//Try to spawn again?
		if(typeOfEntity == 1)
		{
			if(savedOwner >= 1 && savedOwner <= MaxClients)
			{
				if(IsClientInGame(savedOwner))
				{
					if(IsPlayerAlive(savedOwner) && usingMediRayDar[savedOwner])
					{
						//PrintToChatAll("Recreated Wearable!");
						create_Self_MediRay(savedOwner);
					}
				}
			}
		}
		
		return Plugin_Stop;
	}
	
	new currIndex = GetEntProp(mediRay, Prop_Data, "m_nModelIndex");
	if(currIndex != mediRayModelIndex)
	{
		//PrintToChatAll("Removing not Same Model: %i|%i",mediRay,typeOfEntity);
		return Plugin_Stop;
	}
	
	new owner = GetEntPropEnt(mediRay, Prop_Data, "m_hOwnerEntity");
	if(owner < 1 || owner > MaxClients)
	{
		//PrintToChatAll("Removing Owner is not HERE: %i|%i",mediRay,typeOfEntity);
		//Attachable_UnhookEntity(mediRay);
		killEntityIn( mediRay, 0.0);
		return Plugin_Stop;
	}
	
	if(!IsClientInGame(owner))
	{
		//PrintToChatAll("Client Not in game: %i|%i",mediRay,typeOfEntity);
		//Attachable_UnhookEntity(mediRay);
		killEntityIn( mediRay, 0.0);
		return Plugin_Stop;
	}
	
	if(!IsPlayerAlive(owner) || !usingMediRayDar[owner])
	{
		//PrintToChatAll("Removing Owner is dead or Not Using: %i|%i",mediRay,typeOfEntity);
		//Attachable_UnhookEntity(mediRay);
		killEntityIn( mediRay, 0.0);
		return Plugin_Stop;
	}
	
	/////////////////////
	//Update the alpha //
	/////////////////////
	new playerAlpha = GetEntData(owner, m_clrRender + 3, 1);
	new objectAlpha = GetEntData(mediRay, m_clrRender + 3, 1);
	
	if(playerAlpha != objectAlpha)
	{
		SetEntityRenderMode(mediRay, RENDER_TRANSCOLOR);
		SetEntityRenderColor(mediRay, 255, 255, 255, playerAlpha);
	}
	
	////////////////////
	//Determine Skin  //
	////////////////////
	new cond = GetEntData(owner, m_nPlayerCond);
	new skin = GetEntProp(mediRay, Prop_Data, "m_nSkin");
	
	if(GetClientTeam(owner) == RED_TEAM)
	{
		if(cond & 32)
		{
			if(skin != 2)
			{
				DispatchKeyValue(mediRay, "skin", "2"); 
			}
		}else{
			if(skin != 0)
			{
				DispatchKeyValue(mediRay, "skin", "0"); 
			}
		}
	}
	
	if(GetClientTeam(owner) == BLUE_TEAM)
	{
		if(cond & 32)
		{
			if(skin != 3)
			{
				DispatchKeyValue(mediRay, "skin", "3"); 
			}
		}else{
			if(skin != 1)
			{
				DispatchKeyValue(mediRay, "skin", "1"); 
			}
		}
	}
	
	//////////////////////////
	//Is this a self entity //
	//////////////////////////
	if(typeOfEntity == 1)
		return Plugin_Continue;
	
	/////////////////////////
	//Consume ubers faster //
	/////////////////////////
	if(cond & 32 )
	{
		new weapon = GetPlayerWeaponSlot(owner, 1);
		if (IsValidEntity(weapon))
		{
			new Float:currentCharge;
			
			new String:classname[64];
			GetEdictClassname(weapon, classname, 64);
			
			//is the player holding the medigun?
			if(StrEqual(classname, "tf_weapon_medigun"))
			{
				currentCharge = GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel");
				//PrintToChatAll("%f", currentCharge);
				
				currentCharge -= uberDrain;
				
				if(currentCharge > uberDrain)
					SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", currentCharge);
			}
		}
	}
	
	///////////////////////
	//Heal others nearby //
	///////////////////////
	new Float:ownerPos[3];
	GetClientAbsOrigin(owner, ownerPos);
	
	new Float:otherPlayerPos[3];
	new Float:playerDistance;
	
	for (new i = 1; i <= MaxClients ; i++)
	{
		if(i == owner && !healSelf)
			continue;
		
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		if(GetClientTeam(i) != GetClientTeam(owner))
			continue;
        
		GetClientAbsOrigin(i, otherPlayerPos);
		playerDistance = GetVectorDistance(ownerPos, otherPlayerPos);
		
		if(playerDistance < distance)
		{
			//TF2_AddCondition(i,TFCond_Buffed,0.3);
			addHealth(i, healRate);
		}
	}
	
	return Plugin_Continue;
}

// ------------------------------------------------------------------------
// TF2_SpawnWearable
// ------------------------------------------------------------------------
stock TF2_SpawnWearable(iOwner, iDef=52, iLevel=100, iQuality=0)
{
    new iTeam = GetClientTeam(iOwner);
    new iItem = CreateEntityByName("tf_wearable_item");
    
    if (IsValidEdict(iItem))
    {
        //SetEntProp(iItem, Prop_Send, "m_bInitialized", 1);    // Disabling this avoids the crashes related to spies
        // disguising as someone with hat in Windows.
        
        // Using reference data from Batter's Helmet. Thanks to MrSaturn.
        SetEntProp(iItem, Prop_Send, "m_fEffects",             EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_NOSHADOW|EF_PARENT_ANIMATES);
        SetEntProp(iItem, Prop_Send, "m_iTeamNum",             iTeam);
        SetEntProp(iItem, Prop_Send, "m_nSkin",                (iTeam-2));
        SetEntProp(iItem, Prop_Send, "m_CollisionGroup",       11);
        SetEntProp(iItem, Prop_Send, "m_iItemDefinitionIndex", iDef);
        SetEntProp(iItem, Prop_Send, "m_iEntityLevel",         iLevel);
        SetEntProp(iItem, Prop_Send, "m_iEntityQuality",       iQuality);
        
        // Spawn.
        DispatchSpawn(iItem);
    }
    
    return iItem;
}

// ------------------------------------------------------------------------
// TF2_SdkStartup
// ------------------------------------------------------------------------
stock TF2_SdkStartup()
{
    
    new Handle:hGameConf = LoadGameConfigFile("TF2_EquipmentManager");
    if (hGameConf != INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"EquipWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkEquipWearable = EndPrepSDKCall();
        
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"RemoveWearable");
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        g_hSdkEquipWearable = EndPrepSDKCall();		
        
        CloseHandle(hGameConf);
        g_bSdkStarted = true;
    } else {
        SetFailState("Couldn't load SDK functions (TF2_EquipmentManager).");
    }
}

// ------------------------------------------------------------------------
// TF2_EquipWearable
// ------------------------------------------------------------------------
stock TF2_EquipWearable(iOwner, iItem)
{
    if (g_bSdkStarted == false) TF2_SdkStartup();
    
    if (TF2_IsEntityWearable(iItem)) SDKCall(g_hSdkEquipWearable, iOwner, iItem);
    else                             LogMessage("Error: Item %i isn't a valid wearable.", iItem);
}

// ------------------------------------------------------------------------
// TF2_IsEntityWearable
// ------------------------------------------------------------------------
stock bool:TF2_IsEntityWearable(iEntity)
{
    if ((iEntity > 0) && IsValidEdict(iEntity))
    {
        new String:strClassname[32]; GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
        return StrEqual(strClassname, "tf_wearable_item", false);
    }
    
    return false;
}

public Action:addHealth(client, amountOfHelath)
{
	//Adds health to a client but will not allow it to go over maxhealth
	if(IsClientConnected(client) || IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			new TFClassType:class = TF2_GetPlayerClass(client);
			new healthAdjustment;
			healthAdjustment = findHealthAdjustment(client);
			
			if ((GetClientHealth(client)+ amountOfHelath) > TFClass_MaxHealth[class][0] + healthAdjustment){
				//SetEntityHealth(i,TFClass_MaxHealth[class][0] + healthAdjustment);
			}else{
				SetEntityHealth(client,GetClientHealth(client) + amountOfHelath);
			}
		}
	}
}

public findHealthAdjustment(client)
{
	new healthAdjustment;
	
	//find health adjustments this is for special weapons that either
	//increase or decrease the players health when a certain
	//weapon is equipped
	//
	//"item_slot"	"melee" = 1
	new iWeapon ;
	
	for (new islot = 0; islot < 11; islot++) 
	{
		iWeapon = GetPlayerWeaponSlot(client, islot);
		if (IsValidEntity(iWeapon))
		{
			//PrintToChatAll("m_iItemDefinitionIndex: %i", GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"));
			
			if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 132)
				healthAdjustment -= 25;
			
			if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 44)
				healthAdjustment -= 15;
		}
	}
	
	new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	if(decapitations > 4)
	{
		decapitations = 4;
	}
	healthAdjustment += (15*decapitations);
	
	return healthAdjustment;
}

public killEntityIn(entity, Float:seconds)
{
	if(IsValidEdict(entity))
	{
		// send "kill" event to the event queue
		new String:addoutput[64];
		Format(addoutput, sizeof(addoutput), "OnUser1 !self:kill::%f:1",seconds);
		SetVariantString(addoutput);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

public Action:deleteMediRayEntities()
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_physics")) != -1)
	{	
		new currIndex = GetEntProp(entity, Prop_Data, "m_nModelIndex");
		
		if(currIndex == mediRayModelIndex)
		{
			killEntityIn(entity, 1.0);
		}
	}
	
	entity = -1;
	
	while ((entity = FindEntityByClassname(entity, "tf_wearable_item")) != -1)
	{	
		new currIndex = GetEntProp(entity, Prop_Data, "m_nModelIndex");
		
		if(currIndex == mediRayModelIndex)
		{
			killEntityIn(entity, 0.1); 
		}
	}
}
