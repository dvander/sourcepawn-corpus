#define NONE        ""
#define CLASS_PISTOL    "weapon_pistol"
#define CLASS_MAGNUM    "weapon_pistol_magnum"
#define CLASS_MELEE     "weapon_melee"
#define CLASS_CHAINSAW  "weapon_chainsaw"
#define MODEL_CLAW      "models/v_models/weapons/v_claw_hunter.mdl"

#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool Started;
bool Failed;
bool Side_mode;

bool Has_melee[MAXPLAYERS+1];
char Melee_name[MAXPLAYERS+1][PLATFORM_MAX_PATH];
bool Has_chainsaw[MAXPLAYERS+1];
int Pistol_clip[MAXPLAYERS+1];
int Chainsaw_clip[MAXPLAYERS+1];
bool Backing[MAXPLAYERS+1];

bool BP_Has_melee[MAXPLAYERS+1];
char BP_Melee_name[MAXPLAYERS+1][PLATFORM_MAX_PATH];
bool BP_Has_chainsaw[MAXPLAYERS+1];
int BP_Pistol_clip[MAXPLAYERS+1];
int BP_Chainsaw_clip[MAXPLAYERS+1];

bool Zoom[MAXPLAYERS+1];
bool Use[MAXPLAYERS+1];

public int create_weapon(const char[] CLASSNAME, const char[] MELEENAME)
{
    if(strcmp(CLASSNAME, CLASS_MELEE) == 0)
    {
        int weapon = CreateEntityByName(CLASS_MELEE);
        DispatchKeyValue(weapon, "melee_script_name", MELEENAME);
        DispatchSpawn(weapon);
        return weapon;
    }
    else
    {
        int weapon = CreateEntityByName(CLASSNAME);
        DispatchSpawn(weapon);
        return weapon;
    }
}

public bool is_end_map()
{
	if(FindEntityByClassname(-1, "info_changelevel") == -1 && FindEntityByClassname(-1, "trigger_changelevel") == -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}

public bool is_start_or_end_map()
{
	int count = 0;
	int i = -1;
	while((i = FindEntityByClassname(i, "info_landmark")) != -1) 
	{
		count++;
	}
	if(count == 1)
	{
		return true;
	}
	else 
	{
		return false;
	}
}

public bool is_start_map()
{
	if(is_start_or_end_map() && !is_end_map())
	{
		return true;
	}
	else
	{
		return false;
	}
}

public void on_gamemode(const char[] output, int caller, int activator, float delay)
{
    if(strcmp(output, "OnSurvival") == 0)
    {
        Side_mode = true;
    }
    else if(strcmp(output, "OnVersus") == 0)
    {
        Side_mode = true;
    }
    else if(strcmp(output, "OnScavenge") == 0)
    {
        Side_mode = true;
    }
    else if(strcmp(output, "OnCoop") == 0)
    {
        Side_mode = false;
    }
}

public bool is_side_mode()
{
    int entity = CreateEntityByName("info_gamemode");
	if(IsValidEntity(entity))
	{
        DispatchSpawn(entity);
        HookSingleEntityOutput(entity, "OnCoop", on_gamemode, true);
        HookSingleEntityOutput(entity, "OnSurvival", on_gamemode, true);
        HookSingleEntityOutput(entity, "OnVersus", on_gamemode, true);
        HookSingleEntityOutput(entity, "OnScavenge", on_gamemode, true);
        ActivateEntity(entity);
        AcceptEntityInput(entity, "PostSpawnActivate");
        if(IsValidEntity(entity))
        {
            RemoveEdict(entity);
        }
	}
    if(Side_mode == true)
    {
        return true;
    }
    else
    {
        return false;
    }
}

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}

public bool IsPlayerAlright(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") == 0;
}

public bool IsValidSurvivor(int client)
{
	if(client >= 1 && client <= MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) == 2)
			{
				return true;
			}
		}
	}
	return false;
}

public bool IsValidSpectator(int client)
{
	if(client >= 1 && client <= MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(!IsFakeClient(client) && GetClientTeam(client) == 1)
			{
				return true;
			}
		}
	}
	return false;
}

public int get_idled_of_bot(int bot)
{
	char name[PLATFORM_MAX_PATH];
	if(GetEntityNetClass(bot, name, PLATFORM_MAX_PATH) == false)
	{
		return 0;
	}
	if(FindSendPropInfo(name, "m_humanSpectatorUserID") <= 0)
	{
		return 0;
	}
	int human = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
    if(IsValidSpectator(human))
    {
        return human;
    }
	return 0;
}

public void data_trans(int client, int prev)
{
    Has_melee[client] = Has_melee[prev];
    strcopy(Melee_name[client], PLATFORM_MAX_PATH, Melee_name[prev]);
    Has_chainsaw[client] = Has_chainsaw[prev];
    Pistol_clip[client] = Pistol_clip[prev];
    Chainsaw_clip[client] = Chainsaw_clip[prev];
    Backing[client] = Backing[prev];
}

public void wait_to_back()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        Backing[client] = true;
    }   
}

public void save_weapon()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        BP_Has_melee[client] = Has_melee[client];
        strcopy(BP_Melee_name[client], PLATFORM_MAX_PATH, Melee_name[client]);
        BP_Has_chainsaw[client] = Has_chainsaw[client];
        BP_Pistol_clip[client] = Pistol_clip[client];
        BP_Chainsaw_clip[client] = Chainsaw_clip[client];
    }
}

public void restore_weapon()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        Has_melee[client] = BP_Has_melee[client];
        strcopy(Melee_name[client], PLATFORM_MAX_PATH, BP_Melee_name[client]);
        Has_chainsaw[client] = BP_Has_chainsaw[client];
        Pistol_clip[client] = BP_Pistol_clip[client];
        Chainsaw_clip[client] = BP_Chainsaw_clip[client];
    }    
}

public bool is_melee(int weapon)
{
    if(IsValidEntity(weapon))
    {
        char class_name[PLATFORM_MAX_PATH];
        GetEntityClassname(weapon, class_name, PLATFORM_MAX_PATH);
        if(strcmp(class_name, CLASS_MELEE) == 0)
        {
            return true;
        }
    }
    return false;
}

public bool is_chainsaw(int weapon)
{
    if(IsValidEntity(weapon))
    {
        char class_name[PLATFORM_MAX_PATH];
        GetEntityClassname(weapon, class_name, PLATFORM_MAX_PATH);
        if(strcmp(class_name, CLASS_CHAINSAW) == 0)
        {
            return true;
        }
    }
    return false;
}

public bool is_pistol_single(int weapon)
{
    if(IsValidEntity(weapon))
    {
        char class_name[PLATFORM_MAX_PATH];
        GetEntityClassname(weapon, class_name, PLATFORM_MAX_PATH);
        if(strcmp(class_name, CLASS_PISTOL) == 0)
        {
            if(GetEntProp(weapon, Prop_Send, "m_hasDualWeapons") == 0)
            {
                return true;
            }
        }
    }
    return false;
}

public bool is_pistol_other(int weapon)
{
    if(IsValidEntity(weapon))
    {
        char class_name[PLATFORM_MAX_PATH];
        GetEntityClassname(weapon, class_name, PLATFORM_MAX_PATH);
        if(strcmp(class_name, CLASS_PISTOL) == 0)
        {
            if(GetEntProp(weapon, Prop_Send, "m_hasDualWeapons") != 0)
            {
                return true;
            }
        }
        else if(strcmp(class_name, CLASS_MAGNUM) == 0)
        {
            return true;
        }
    }
    return false;
}

public bool is_claw(int weapon)
{
    char model[PLATFORM_MAX_PATH];
    GetEntPropString(weapon, Prop_Data, "m_ModelName", model, PLATFORM_MAX_PATH);
    if(strcmp(MODEL_CLAW, model) == 0)
    {
        return true;
    }
    else
    {
        return false;
    }
}

public int get_clip(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_iClip1");
}

public void set_clip(int weapon, int clip)
{
    SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
}

public int get_active_weapon(int client)
{
    return GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
}

public void give_pistol(int client)
{
    int weapon = create_weapon(CLASS_PISTOL, NONE);
    if(is_pistol_single(weapon))
    {
        EquipPlayerWeapon(client, weapon);
        set_clip(weapon, Pistol_clip[client]);
    }    
}

public void give_melee(int client)
{
    int weapon = create_weapon(CLASS_MELEE, Melee_name[client]);
    if(is_melee(weapon))
    {
        EquipPlayerWeapon(client, weapon);
    }
}

public void give_chainsaw(int client)
{
    int weapon = create_weapon(CLASS_CHAINSAW, NONE);
    if(is_chainsaw(weapon))
    {
        EquipPlayerWeapon(client, weapon);
        set_clip(weapon, Chainsaw_clip[client]);
    }
}

public void get_sub_type(int client)
{
    int slot2 = GetPlayerWeaponSlot(client, 1);
    if(is_pistol_other(slot2))
    {
        Has_melee[client] = false;
        strcopy(Melee_name[client], PLATFORM_MAX_PATH, NONE);
        Has_chainsaw[client] = false;
        Chainsaw_clip[client] = 0;
        Backing[client] = false;
    }
    else if(is_pistol_single(slot2))
    {
        Pistol_clip[client] = get_clip(slot2);
    }
    else if(is_melee(slot2))
    {
        if(is_claw(slot2))
        {
            RemovePlayerItem(client, slot2);
            if(GetPlayerWeaponSlot(client, 1) == -1)
            {
                give_pistol(client);
            }
            Has_melee[client] = false;
            strcopy(Melee_name[client], PLATFORM_MAX_PATH, NONE);
            Has_chainsaw[client] = false;
            Chainsaw_clip[client] = 0;
            Backing[client] = false;
        }
        else
        {
            Has_melee[client] = true;
            char melee[PLATFORM_MAX_PATH];
            GetEntPropString(slot2, Prop_Data, "m_strMapSetScriptName", melee, PLATFORM_MAX_PATH);
            strcopy(Melee_name[client], PLATFORM_MAX_PATH, melee);
            Has_chainsaw[client] = false;
            Chainsaw_clip[client] = 0;
            Backing[client] = false;
        }
    }
    else if(is_chainsaw(slot2))
    {
        Has_chainsaw[client] = true;
        Chainsaw_clip[client] = get_clip(slot2);
        Has_melee[client] = false;
        strcopy(Melee_name[client], PLATFORM_MAX_PATH, NONE);
        Backing[client] = false;
    }
}

public void selecting(int client)
{
    int weapon = get_active_weapon(client);
    if(is_melee(weapon) || is_chainsaw(weapon))
    {
        change_pistol(client);
    }
    else if(is_pistol_single(weapon))
    {
        change_melee(client);
    }
}

public void change_pistol(int client)
{
    if(Has_melee[client] == true || Has_chainsaw[client] == true)
    {
        int slot2 = GetPlayerWeaponSlot(client, 1);
        if(is_melee(slot2) || is_chainsaw(slot2))
        {
            RemovePlayerItem(client, slot2);
            if(GetPlayerWeaponSlot(client, 1) == -1)
            {
                give_pistol(client);
            }
        }
    }
}

public void change_melee(int client)
{
    if(Has_melee[client] == true || Has_chainsaw[client] == true)
    {
        int slot2 = GetPlayerWeaponSlot(client, 1);
        if(is_pistol_single(slot2))
        {
            RemovePlayerItem(client, slot2);
            if(GetPlayerWeaponSlot(client, 1) == -1)
            {
                if(Has_melee[client] == true)
                {
                    give_melee(client);
                }
                else if(Has_chainsaw[client] == true)
                {
                    give_chainsaw(client);
                }
            }
        }
    }
}

public void reset_player(int client)
{
    Use[client] = false;
    Zoom[client] = false;
}

public void init_player(int client)
{
    Has_melee[client] = false;
    strcopy(Melee_name[client], PLATFORM_MAX_PATH, NONE);
    Has_chainsaw[client] = false;
    Pistol_clip[client] = 0;
    Chainsaw_clip[client] = 0;
    Backing[client] = false;
}

public void init_player_backup(int client)
{
    BP_Has_melee[client] = false;
    strcopy(BP_Melee_name[client], PLATFORM_MAX_PATH, NONE);
    BP_Has_chainsaw[client] = false;
    BP_Pistol_clip[client] = 0;
    BP_Chainsaw_clip[client] = 0;   
}

public void init_all()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        reset_player(client);
        init_player(client);
        init_player_backup(client);
    }
}

public void round_check(int client)
{
    if(Started == false)
    {
        if(IsValidSurvivor(client))
        {
            if(IsPlayerAlive(client))
            {
                if(is_side_mode())
                {
                    init_all();
                }
                else if(is_start_map())
                {
                    init_all();
                }
                else if(Failed == true)
                {
                    restore_weapon();
                }
                Started = true;
                Failed = false;
                Side_mode = false;
            }
        }
    }
}

public Action on_drop(int client, int weapon)
{
    if(IsValidSurvivor(client))
    {
        if(IsPlayerAlive(client) && IsPlayerAlright(client))
        {
            if(is_melee(weapon))
            {
                Has_melee[client] = false;
                strcopy(Melee_name[client], PLATFORM_MAX_PATH, NONE);
            }
            else if(is_chainsaw(weapon))
            {
                Has_chainsaw[client] = false;
                Chainsaw_clip[client] = 0;
            }
        }
    }
    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponDrop, on_drop);
}

public bool button_pressed_zoom(int client, int buttons)
{
    if(buttons & IN_ZOOM)
    {
        if(Zoom[client] == false)
        {
            Zoom[client] = true;
            return true;
        }
        else
        {
            return false;
        }
    }
    else
    {
        Zoom[client] = false;
        return false;
    }
}

public bool button_pressed_use(int client, int buttons)
{
    if(buttons & IN_USE)
    {
        if(Use[client] == false)
        {
            Use[client] = true;
            return true;
        }
        else
        {
            return false;
        }
    }
    else
    {
        Use[client] = false;
        return false;
    }
}

public void next_frame(any client)
{
    if(Started == true)
    {
        if(IsValidSurvivor(client))
        {
            if(!IsFakeClient(client) && IsPlayerAlive(client) && IsPlayerAlright(client))
            {
                int slot2 = GetPlayerWeaponSlot(client, 1);
                if(is_melee(slot2))
                {
                    if(is_claw(slot2))
                    {
                        RemovePlayerItem(client, slot2);
                        if(GetPlayerWeaponSlot(client, 1) == -1)
                        {
                            give_pistol(client);
                        }
                        Has_melee[client] = false;
                        strcopy(Melee_name[client], PLATFORM_MAX_PATH, NONE);
                        Has_chainsaw[client] = false;
                        Chainsaw_clip[client] = 0;
                    }
                }
                char name[PLATFORM_MAX_PATH];
                GetClientWeapon(client, name, PLATFORM_MAX_PATH);
                if(strcmp(name, CLASS_MELEE) == 0 || strcmp(name, CLASS_CHAINSAW) == 0)
                {
                    change_pistol(client);
                }
            }
        }
    }  
}

public void survivor_check(int client, int buttons, int weapon)
{
    if(Started == true)
    {
        if(IsValidSurvivor(client))
        {
            if(!IsFakeClient(client))
            {
                if(IsPlayerAlive(client))
                {
                    get_sub_type(client);
                    if(IsPlayerAlright(client))
                    {
                        if(Backing[client] == true)
                        {
                            change_melee(client);
                            Backing[client] = false;
                        }
                        else if(weapon != 0)
                        {
                            change_melee(client);
                        }
                        else if(button_pressed_use(client, buttons))
                        {
                            int slot2 = GetPlayerWeaponSlot(client, 1);
                            if(is_pistol_single(slot2))
                            {
                                change_melee(client);
                                RequestFrame(next_frame, client);
                            }
                        }
                        else if(button_pressed_zoom(client, buttons))
                        {
                            selecting(client);
                        }
                    }
                }
            }
            else
            {
                if(IsPlayerAlive(client))
                {
                    get_sub_type(client);
                    if(IsPlayerAlright(client) || IsPlayerFalling(client))
                    {
                        change_melee(client);
                        Backing[client] = false;
                    }
                }
                int human = get_idled_of_bot(client);
                if(human != 0)
                {
                    data_trans(human, client);
                }         
            }
        }
    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
    round_check(client);
    survivor_check(client, buttons, weapon);
    return Plugin_Continue;
}

public void Event_round(Event event, const char[] name, bool dontBroadcast)
{
    wait_to_back();
	Started = false;
}

public void Event_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsValidSurvivor(client))
    {
        reset_player(client);
    }
}

public void Event_player_bot(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "player"));
    int bot = GetClientOfUserId(GetEventInt(event, "bot"));
    if(IsValidSurvivor(bot))
    {
        data_trans(bot, player);
    }
}

public void Event_bot_player(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(GetEventInt(event, "player"));
    int bot = GetClientOfUserId(GetEventInt(event, "bot"));
    if(IsValidSurvivor(player))
    {
        data_trans(player, bot);
    }
}

public void Event_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsValidSurvivor(client))
    {
        if(!IsFakeClient(client))
        {
            Backing[client] = true;
        }
    }
}

public void Event_ledge(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsValidSurvivor(client))
    {
        if(!IsFakeClient(client) && IsPlayerAlive(client) && IsPlayerFalling(client))
        {
            change_melee(client);
        }
    }
}

public void Event_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsValidSurvivor(client))
    {
        if(!IsFakeClient(client))
        {
            Backing[client] = true;
        }
    }
}

public void Event_maptrans(Event event, const char[] name, bool dontBroadcast)
{
    save_weapon();
}

public void Event_failed(Event event, const char[] name, bool dontBroadcast)
{
    Failed = true;
}

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_spawn);
    HookEvent("player_bot_replace", Event_player_bot);
    HookEvent("bot_player_replace", Event_bot_player);
    HookEvent("player_ledge_grab", Event_ledge);
    HookEvent("player_incapacitated", Event_incapacitated);
    HookEvent("player_death", Event_death);
    HookEvent("round_start", Event_round);
    HookEvent("map_transition", Event_maptrans);
    HookEvent("mission_lost", Event_failed);
}