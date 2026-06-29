#include <sourcemod>
#include <sdktools>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define SPEED_CROPPED_DUCK 1

public Plugin myinfo =
{
    name = "CS:S Duck AA Fix",
    author = "jtooler",
    description = "fixes air acceleration reduction when ducking in air",
    version = "1.0",
    url = "https://rampsliders.wiki/"
};

DynamicHook g_hHandleDuckingSpeedCrop;

public void OnPluginStart()
{
    Handle hGameConf = LoadGameConfigFile("duckaafix.games");
    if (hGameConf == null)
    {
        SetFailState("failed to load gamedata file");
    }

    char interfaceName[64];
    if (!GameConfGetKeyValue(hGameConf, "IGameMovement", interfaceName, sizeof(interfaceName)))
    {
        SetFailState("failed to get IGameMovement interface name");
    }

    StartPrepSDKCall(SDKCall_Static);
    if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CreateInterface"))
    {
        SetFailState("failed to get CreateInterface");
    }
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    Handle hCreateInterface = EndPrepSDKCall();

    if (hCreateInterface == null)
    {
        SetFailState("failed to create SDKCall for CreateInterface");
    }

    Address pGameMovement = SDKCall(hCreateInterface, interfaceName, 0);
    if (!pGameMovement)
    {
        SetFailState("failed to get IGameMovement pointer");
    }

    int offset = GameConfGetOffset(hGameConf, "HandleDuckingSpeedCrop");
    if (offset == -1)
    {
        SetFailState("failed to get HandleDuckingSpeedCrop offset");
    }

    g_hHandleDuckingSpeedCrop = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Address, DHook_HandleDuckingSpeedCrop);
    if (!g_hHandleDuckingSpeedCrop)
    {
        SetFailState("failed to create hook for HandleDuckingSpeedCrop");
    }

    if (!DHookRaw(g_hHandleDuckingSpeedCrop, false, pGameMovement))
    {
        SetFailState("failed to hook HandleDuckingSpeedCrop");
    }

    delete hCreateInterface;
    delete hGameConf;
}

public MRESReturn DHook_HandleDuckingSpeedCrop(Address pThis, Handle hParams)
{
    // get the player
    Address pPlayer = view_as<Address>(LoadFromAddress(pThis + view_as<Address>(4), NumberType_Int32));
    int client = GetClientFromAddress(pPlayer);

    if (!IsValidClient(client) || !IsPlayerAlive(client))
    {
        return MRES_Ignored;
    }

    // we dont wanna do anything to free lookers
    if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 6) // OBS_MODE_ROAMING
    {
        return MRES_Supercede; 
    }

    // player is midair, real shit
    if (!(GetEntityFlags(client) & FL_ONGROUND))
    {
        // don't fuck with our wishspeed
        return MRES_Supercede;
    }

    // player is onground... we sleep
    return MRES_Ignored;
}

bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client));
}

int GetClientFromAddress(Address pEntity)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && pEntity == GetEntityAddress(i))
        {
            return i;
        }
    }
    return -1;
}