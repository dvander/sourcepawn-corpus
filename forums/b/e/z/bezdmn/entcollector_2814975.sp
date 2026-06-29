#pragma semicolon 1

#include <dhooks>
#include <entcollector>

#pragma newdecls required

//#define DEBUG
#define PLUGIN_VERSION "1.1.3"

public Plugin myinfo = 
{
    name = "Entity Collector",
    author = "bezdmn",
    description = "Clean up orphaned entities such as projectiles after their owner dies",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=344992"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] err, int err_max) 
{
    if (Engine_SDK2013 != GetEngineVersion())
    {
        strcopy(err, err_max, "This plugin is made for Source engine version SDK2013");
        return APLRes_Failure;
    }

    // bind natives
    CreateNative("RemoveClientEntities", Native_RemoveClientEntities);
    return APLRes_Success;
}

#define GAMEDATA        "entcollector.plugin"
#define ITEMLIST        "configs/entcollector_items.cfg"

#define MK_PROJECTILE   "CTFWeaponBaseGun::FireProjectile"
#define SWAP_ITEM       "CTFPlayer::GiveNamedItem"

#define MAXENTS         50
#define ITEM_SLOTS      3

#if !defined DEBUG
    #define PRINT(%1)   0
#else
    #define PRINT(%1)   PrintToChatAll(%1)
#endif

ConVar  g_cvTrackedEnts,
        g_cvAutoRemove,
        g_cvDisplayTE;

Handle  g_hEntHook,
        g_hItemHooksKv;

int     g_iSlotHooked       [MAXPLAYERS][ITEM_SLOTS],
        g_iEntStore         [MAXPLAYERS][MAXENTS],
        g_iEntStorePtr      [MAXPLAYERS],
        g_iTrackedEnts;

bool    g_bEntStoreLoops    [MAXPLAYERS],
        g_bAutoRemove;

char    g_strDisplayTE      [64];

any Native_RemoveClientEntities(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    PRINT("Calling native RemoveClientEntitites for %i", client);
    return Clean_Ents_All(client);
}

public void OnPluginStart()
{
    // convars
    CreateConVar("sm_entc_version", PLUGIN_VERSION, "Entity Collector version", FCVAR_NONE);
    g_cvTrackedEnts = CreateConVar("entc_tracked_ents", "30", "Number of tracked entities per \
                                    player.", FCVAR_NONE, true, 5.0, true, MAXENTS * 1.0);
    g_cvAutoRemove  = CreateConVar("entc_autoremove", "1", "Remove entities automatically. \
                                    Call RemoveClientEntities to remove them manually.", FCVAR_NONE);
    g_cvDisplayTE   = CreateConVar("entc_display_te", "", "Show a brief visual effect in place \
                                    of a removed entity. Empty value means disabled.", FCVAR_NONE);
    Set_GVars();
    
    // hook cvar changes
    g_cvTrackedEnts.AddChangeHook(Change_GVar);
    g_cvAutoRemove.AddChangeHook(Change_GVar);
    g_cvDisplayTE.AddChangeHook(Change_GVar);

    // load gamedata and itemlist
    Handle hGameData = LoadGameConfigFile(GAMEDATA);
    if (!hGameData)
        SetFailState("Couldn't load \"gamedata/%s.txt\"", GAMEDATA);

    char path[256];
    BuildPath(Path_SM, path, sizeof(path), ITEMLIST);

    g_hItemHooksKv = new KeyValues("HookableItems");
    if (!FileToKeyValues(g_hItemHooksKv, path))
        SetFailState("Couldn't load \"%s", ITEMLIST);
    else
        PrintToServer("Loaded %s KeyValues", ITEMLIST);

    // virtual hook for CTFWeaponBaseGun::FireProjectile
    int offset = GameConfGetOffset(hGameData, MK_PROJECTILE);
    if (offset < 0)
        SetFailState("Failed to get offset. Game might not be supported.");

    g_hEntHook = DHookCreate(offset, HookType_Entity, ReturnType_CBaseEntity, 
                             ThisPointer_Ignore, Store_Ent); 
    if (!g_hEntHook)
        SetFailState("DHookCreate for %s failed", MK_PROJECTILE);

    DHookAddParam(g_hEntHook, HookParamType_CBaseEntity);

    PrintToServer("%s dhook success", MK_PROJECTILE);

    // detour GiveNamedItem to re-apply hooks on loadout changes/initial spawns/item pickups 
    Handle hook = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_CBaseEntity,
                                    ThisPointer_CBaseEntity);
    if (!hook)
        SetFailState("Detour setup for %s failed", SWAP_ITEM);

    if (DHookSetFromConf(hook, hGameData, SDKConf_Signature, SWAP_ITEM))
    {
        DHookAddParam(hook, HookParamType_CharPtr);
        DHookAddParam(hook, HookParamType_Int);
        DHookAddParam(hook, HookParamType_ObjectPtr);

        if (!DHookEnableDetour(hook, true, Hook_Weapon))
            SetFailState("Failed to detour %s", SWAP_ITEM);
    }
    else
    {
        SetFailState("Failed to load signature for %s", SWAP_ITEM);
    }

    PrintToServer("%s detour success", SWAP_ITEM);

    delete hook;
    delete hGameData;

    // entities get cleaned up when player dies
    HookEvent("player_death", Clean_Ents, EventHookMode_Post);

#if defined DEBUG
    DHookAddEntityListener(ListenType_Created, Print_All_Ents);
#endif
}

void Set_GVars()
{
    g_iTrackedEnts = g_cvTrackedEnts.IntValue; 
    g_bAutoRemove = g_cvAutoRemove.IntValue ? true : false;
    g_cvDisplayTE.GetString(g_strDisplayTE, sizeof(g_strDisplayTE));
}

void Change_GVar(Handle convar, const char[] old_value, const char[] new_value)
{
    if (convar == g_cvTrackedEnts)
    {
        g_iTrackedEnts = StringToInt(new_value);
    }
    else if (convar == g_cvAutoRemove)
    {
        g_bAutoRemove = StringToInt(new_value) ? true : false; 
    }
    else if (convar == g_cvDisplayTE)
    {
        strcopy(g_strDisplayTE, sizeof(g_strDisplayTE), new_value);
    }
}

public MRESReturn Hook_Weapon(Address pThis, Handle hReturn, Handle hParams)
{
    //PRINT("Hook_Weapon pThis: %i", pThis);
    char weapon_name[64];
    DHookGetParamString(hParams, 1, weapon_name, sizeof(weapon_name));

    // hook a weapon if it's allowed (=1) by the itemlist
    if (KvGetNum(g_hItemHooksKv, weapon_name, 0))
    {
        int weapon_ent = DHookGetReturn(hReturn); //:CBaseEntity
        PRINT("Entity %i of class %s, hooking..", weapon_ent, weapon_name);

        int hookid = DHookEntity(g_hEntHook, true, weapon_ent);
        if (hookid == INVALID_HOOK_ID)
        {
            PRINT("Hooking entity %i failed", weapon_ent);
        }
        else
        {
            PRINT("Hook success! (%i)", hookid);
            g_iSlotHooked[pThis][0] = hookid;
        }
    }

    return MRES_Ignored;
}

// Store entity references to players projectiles in a cyclical array
public MRESReturn Store_Ent(Handle hReturn, Handle hParams)
{
    int entref = EntIndexToEntRef(DHookGetReturn(hReturn)); //:CBaseEntity
    int client = DHookGetParam(hParams, 1);

    PRINT("EntStorePtr = %i", g_iEntStorePtr[client]);
    if (g_iEntStore[client][g_iEntStorePtr[client]] != 0)
    {
        // make space for a new entity. erase previous entity here... 
        Erase_EntByRef(g_iEntStore[client][g_iEntStorePtr[client]]);
    }
    
    g_iEntStore[client][g_iEntStorePtr[client]] = entref;
    g_iEntStorePtr[client] += 1;

    if (g_iEntStorePtr[client] >= g_iTrackedEnts) // a loop
    {
        g_bEntStoreLoops[client] = true;
        g_iEntStorePtr[client] = 0;
        PRINT("EntStore looped");
    }

    PRINT("Stored entity reference %i for client %i", entref, client);
    return MRES_Ignored;
}

public Action Clean_Ents(Event ev, const char[] name, bool dontBroadcast)
{
    if (!g_bAutoRemove)
        return Plugin_Continue;

    if (ev == INVALID_HANDLE)
       SetFailState("Hooking player_death event failed. Another plugin might \
                     be setting a hook in the EventHookMode_PostNoCopy mode"); 

    Clean_Ents_All(GetClientOfUserId(GetEventInt(ev, "userid")));
    return Plugin_Continue;
}

int Clean_Ents_All(int client)
{
    int removed = 0;

    PRINT("Cleaning client %i entities", client);
    while (g_iEntStorePtr[client] > 0)
    {
        g_iEntStorePtr[client] -= 1;
        if (g_iEntStore[client][g_iEntStorePtr[client]] != 0)
        {
            if (Erase_EntByRef(g_iEntStore[client][g_iEntStorePtr[client]]))
                removed++;
            g_iEntStore[client][g_iEntStorePtr[client]] = 0;
        }
    }

    // array looped, start removing from the end
    if (g_bEntStoreLoops[client])
    {
        // dont necessarily need to loop over the entire store
        g_bEntStoreLoops[client] = false;
        g_iEntStorePtr[client] = g_iTrackedEnts;
        PRINT("Cleaning the second loop"); 
        removed += Clean_Ents_All(client);
    }

    return removed; // did we remove any entity during this
}

// return true if this entity was removed here, false otherwise
bool Erase_EntByRef(int entref)
{
    int entity = EntRefToEntIndex(entref);
    if (entity != INVALID_ENT_REFERENCE) // does entity still exists in game?
    {
        // should display a visual effect for the entitys defusal
        if (g_strDisplayTE[0] != '\0')
        {
            float orig[3], dir[3];
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", orig, 0);
            GetEntPropVector(entity, Prop_Send, "m_angRotation", dir, 0);

            TE_Start(g_strDisplayTE);
            if (StrEqual(g_strDisplayTE, "Sparks")) 
            {
                TE_WriteFloat("m_vecOrigin[0]", orig[0]);
                TE_WriteFloat("m_vecOrigin[1]", orig[1]);
                TE_WriteFloat("m_vecOrigin[2]", orig[2]);
                TE_WriteNum("m_nMagnitude", 1);
                TE_WriteNum("m_nTrailLength", 1);
                TE_WriteVector("m_vecDir", dir);
            }
            else if (StrEqual(g_strDisplayTE, "Energy Splash"))
            {
                TE_WriteVector("m_vecPos", orig);
                TE_WriteVector("m_vecDir", dir);
                TE_WriteNum("m_bExplosive", 1);
            }
            TE_SendToAll(0.0);
        } //TODO: add more effects

        RemoveEntity(entity);
        PRINT("Erased previous entity at StorePtr");
        return true;
    }

    return false;
}

// do setup for a new client
public void OnClientConnected(int client)
{
    g_bEntStoreLoops[client] = false;
    g_iEntStorePtr[client] = 0;

    for (int i = 0; i < g_iTrackedEnts; i++)
    {
        g_iEntStore[client][i] = 0;
    }
    for (int i = 0; i < ITEM_SLOTS; i++)
    {
        g_iSlotHooked[client][i] = 0;
    }
}

public void Print_All_Ents(int entity, const char[] classname)
{
    PrintToChatAll("entity %i of class %s created", entity, classname);
}
