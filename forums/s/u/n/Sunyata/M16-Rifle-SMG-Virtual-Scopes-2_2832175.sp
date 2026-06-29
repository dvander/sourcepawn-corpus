#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.0"
#define UPGRADE_SCOPE 0x02000000

static const char SOUND_MODECHANGE[] = "^ui/menu_focus.wav"; // quieter zoom sound

bool g_Proto;

ConVar g_ConVarSurvivorUpgrades;

Handle sdkAddUpgrade = INVALID_HANDLE;
Handle sdkRemoveUpgrade = INVALID_HANDLE;

ArrayList g_ByteSaved_Sound;

Address g_Address_Sound;

public Plugin myinfo =
{
    name = "[L4D1] Scope Upgrade for M16 rifle & SMG",
    description = "Adds scope upgrade for M16 rifle & SMG",
    author = "Sunyata",
    version = PLUGIN_VERSION,
    url = ""
};



public void OnPluginStart()
{
    // Load SDK calls
    ReloadSDK();

    if (!g_ConVarSurvivorUpgrades)
    {
        g_ConVarSurvivorUpgrades = FindConVar("survivor_upgrades");
    }
    
    // Hook necessary events
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
    HookEvent("map_transition", Event_RoundEnd, EventHookMode_Pre);
     
    g_Proto = CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
	HookUserMessage(GetUserMessageId("SayText"), UserMsg_SayText, true);
    
    // Apply patch
    PatchAddress(true);
}

//sunyata note - need to suppress l4d_upgrade messages on next map 
public Action UserMsg_SayText(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int iSender = g_Proto ? PbReadInt(msg, "ent_idx") : BfReadByte(msg);
	if( iSender )
	{
		return Plugin_Continue;
	}
	
	g_Proto ? PbReadBool(msg, "chat") : view_as<bool>(BfReadByte(msg));
	
	char message[64];
	
	if( g_Proto )
	{
		PbReadString(msg, "msg_name", message, sizeof message);
	}
	else {
		BfReadString(msg, message, sizeof message);
	}
	
	if( StrContains(message, "_expire") != -1 ) 
	{
		return Plugin_Handled;
	}
	else if( strncmp(message, "L4D_Upgrade", 11) == 0 ) 
	{ //&& (StrContains(message, "description") != -1 || StrContains(message, "alert") != -1) ) {
		return Plugin_Handled;
	}
	else if( strcmp(message, "L4D_NOTIFY_VOMIT_ON") == 0 ) 
	{
		return Plugin_Handled;
	}
	else if( strcmp(message, "Cstrike_TitlesTXT_Game_connected") == 0 ) 
	{
		return Plugin_Handled;
	}	
	return Plugin_Continue;
}

//Sunyata - handle signatures for gamedata txt file - renamed for this plugin
void ReloadSDK()
{
    Handle hGameData = LoadGameConfigFile("l4d_scope_upgrade");
    if(hGameData == null) SetFailState("Could not find gamedata file at addons/sourcemod/gamedata/l4d_scope_upgrade.txt");
    
    StartPrepSDKCall(SDKCall_Player);
    if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "AddUpgrade") == false)
    {
        LogError("Failed to find signature: AddUpgrade");
    }
    else {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
        sdkAddUpgrade = EndPrepSDKCall();
        if(sdkAddUpgrade == null) LogError("Failed to create SDKCall: AddUpgrade");
    }
    
    StartPrepSDKCall(SDKCall_Player);
    if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "RemoveUpgrade") == false)
    {
        LogError("Failed to find signature: RemoveUpgrade");
    }
    else {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);
        sdkRemoveUpgrade = EndPrepSDKCall();
        if(sdkRemoveUpgrade == null) LogError("Failed to create SDKCall: RemoveUpgrade");
    }
    
    // Nop patch
    int iOffset = GameConfGetOffset(hGameData, "AddUpgrade_Offset");
    if(iOffset == -1) SetFailState("Failed to load \"AddUpgrade_Offset\" offset.");
    
    int iByteMatch = GameConfGetOffset(hGameData, "AddUpgrade_Byte");
    if(iByteMatch == -1) SetFailState("Failed to load \"AddUpgrade_Byte\" byte.");

    int iByteCount = GameConfGetOffset(hGameData, "AddUpgrade_Count");
    if(iByteCount == -1) SetFailState("Failed to load \"AddUpgrade_Count\" count.");

    g_Address_Sound = GameConfGetAddress(hGameData, "AddUpgrade");
    if(!g_Address_Sound) SetFailState("Failed to load \"AddUpgrade\" address.");

    g_Address_Sound += view_as<Address>(iOffset);
    g_ByteSaved_Sound = new ArrayList();

    for(int i = 0; i < iByteCount; i++)
    {
        g_ByteSaved_Sound.Push(LoadFromAddress(g_Address_Sound + view_as<Address>(i), NumberType_Int8));
    }

    if(g_ByteSaved_Sound.Get(0) != iByteMatch) SetFailState("Failed to load, byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, g_ByteSaved_Sound.Get(0), iByteMatch);
    
    delete hGameData;
}

void PatchAddress(int patch)
{
    static bool patched;
    
    if(!patched && patch)
    {
        patched = true;
        int len = g_ByteSaved_Sound.Length;
        for(int i = 0; i < len; i++)
        {
            StoreToAddress(g_Address_Sound + view_as<Address>(i), 0x90, NumberType_Int8); // NOP
        }
    }
    else if(patched && !patch)
    {
        patched = false;
        int len = g_ByteSaved_Sound.Length;
        for(int i = 0; i < len; i++)
        {
            StoreToAddress(g_Address_Sound + view_as<Address>(i), g_ByteSaved_Sound.Get(i), NumberType_Int8);
        }
    }
}

public void OnPluginEnd()
{
    PatchAddress(false);
}

public void OnConfigsExecuted()
{
    if(g_ConVarSurvivorUpgrades != null)
    {
        while(g_ConVarSurvivorUpgrades.IntValue != 1)
        {
            g_ConVarSurvivorUpgrades.SetInt(1, true, false);
        }
    }
    
    // Ensure patch is applied after configs are executed
    PatchAddress(true);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(client && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        DisableScope(client);
    }
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(client && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        CreateTimer(0.3, Timer_ApplyScope, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && GetClientTeam(i) == 2)
        {
            DisableScope(i);
        }
    }
}

public Action Timer_ApplyScope(Handle timer, int userId)
{
    int client = GetClientOfUserId(userId);
    
    if(client && IsClientInGame(client))
    {
        ApplyScope(client);
    }
    return Plugin_Continue;
}

void DisableScope(int client)
{
    if(IsClientInGame(client))
    {
        SetEntProp(client, Prop_Send, "m_upgradeBitVec", 0, 4);
    }
}

void ApplyScope(int client)
{
    if(IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        int currentBits = GetEntProp(client, Prop_Send, "m_upgradeBitVec");
        int newBits = currentBits | UPGRADE_SCOPE;
        SetEntProp(client, Prop_Send, "m_upgradeBitVec", newBits, 4);
    }
}

//Sunyata - ostensible nooping of weapons other than m16 and smg
public Action OnPlayerRunCmd(int client, int& buttons, int& impuls, float vel[3], float angles[3], int& weapon)
{
    if((buttons & IN_ZOOM))
    {        
        int activeWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
        if(!IsValidEntity(activeWeapon) || IsFakeClient(client)) return Plugin_Handled;
        
        char classname[256];
        GetEntityClassname(activeWeapon, classname, sizeof(classname));
        
        // Nooping zoom for these weapons
        if (StrContains(classname, "weapon_autoshotgun", false) != -1 ||
            StrContains(classname, "weapon_pistol", false) != -1 ||
            StrContains(classname, "weapon_pumpshotgun", false) != -1)
        {
            buttons &= ~IN_ZOOM;
            return Plugin_Changed;
        }
        
        // Play sound for valid zoom weapons
        if (StrContains(classname, "weapon_rifle", false) != -1 ||
            StrContains(classname, "weapon_smg", false) != -1)
        {
			EmitSoundToClient(client, SOUND_MODECHANGE, _, SNDCHAN_ITEM, SNDLEVEL_NORMAL);
			//EmitSoundToClient(client, SOUND_MODECHANGE, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE);
        }
    }
    return Plugin_Continue;
}
