#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int g_iViewModels[MAXPLAYERS + 1][2];

Handle g_hCreateViewModel;

int g_iOffset_ViewModel;
int g_iOffset_ActiveWeapon;

int g_iOffset_Weapon;
int g_iOffset_Sequence;
int g_iOffset_PlaybackRate;

int g_AnimOffset = -1;//this only for testing porpuses

char g_szCustomVM_ClassName[3][] = {
    "pistol",
    "shotgun",
    "smg"
};

char g_szCustomVM_Model[3][] = {
    "models/v_models/weapons/v_claw_hunter.mdl",
    "models/v_models/weapons/v_claw_smoker.mdl",
    "models/v_models/weapons/v_claw_boomer.mdl"
};


int g_iCustomVM_ModelIndex[3];

public void OnPluginStart() {
    Handle gameConf = LoadGameConfigFile("L4DViewmodels");

    if (!gameConf) {
        SetFailState("Fatal Error: Unable to open game config file: \"L4DViewmodels\"!");
    }

    StartPrepSDKCall(SDKCall_Player);
    PrepSDKCall_SetFromConf(gameConf, SDKConf_Virtual, "CreateViewModel");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue);

    if ((g_hCreateViewModel = EndPrepSDKCall()) == INVALID_HANDLE) {
        SetFailState("Fatal Error: Unable to create SDK call \"CreateViewModel\"!");
    }

    CloseHandle(gameConf);

    g_iOffset_ViewModel = GetSendPropOffset("CBasePlayer", "m_hViewModel");
    g_iOffset_ActiveWeapon = GetSendPropOffset("CBasePlayer", "m_hActiveWeapon");
    g_iOffset_Weapon = GetSendPropOffset("CBaseViewModel", "m_hWeapon");
    g_iOffset_Sequence = GetSendPropOffset("CBaseViewModel", "m_nSequence");
    g_iOffset_PlaybackRate = GetSendPropOffset("CBaseViewModel", "m_flPlaybackRate");

    HookEvent("player_spawn", Event_PlayerSpawn);
}

int GetSendPropOffset(const char[] serverClass, const char[] propName) {
    int offset = FindSendPropInfo(serverClass, propName);

    if (!offset) {
        SetFailState("Fatal Error: Unable to find offset: \"%s::%s\"!", serverClass, propName);
    }

    return offset;
}

public void OnMapStart() {
    for (int i = 0; i < 3; i++) {
        g_iCustomVM_ModelIndex[i] = PrecacheModel(g_szCustomVM_Model[i], true);
    }
}

public void OnClientPostAdminCheck(int client) {
    g_iViewModels[client][0] = -1;
    g_iViewModels[client][1] = -1;

    SDKHook(client, SDKHook_PostThink, OnClientThinkPost);
}

public void OnClientThinkPost(int client) {
    static int currentWeapon[MAXPLAYERS + 1];

    int viewModel1 = g_iViewModels[client][0];
    int viewModel2 = g_iViewModels[client][1];

    if (!IsPlayerAlive(client)) {
        if (viewModel2 != -1) {
            // If the player is dead, hide the secondary viewmodel.

            g_iViewModels[client][0] = -1;
            g_iViewModels[client][1] = -1;

            currentWeapon[client] = 0;
        }

        return;
    }

    int activeWeapon = GetEntDataEnt2(client, g_iOffset_ActiveWeapon);

    // Check if the player has switched weapon.
    if (activeWeapon != currentWeapon[client]) {

        currentWeapon[client] = 0;

        char className[32];
        GetEdictClassname(activeWeapon, className, sizeof(className));


        for (int i = 0; i < 3; i++) {
            if (StrContains(className, g_szCustomVM_ClassName[i], false) > -1) {

                SetEntProp(viewModel2, Prop_Send, "m_nModelIndex", g_iCustomVM_ModelIndex[i]);
                SetEntData(viewModel2, g_iOffset_Weapon, GetEntData(viewModel1, g_iOffset_Weapon), _, true);

                currentWeapon[client] = activeWeapon;

                break;
            }
        }
    }

    if (currentWeapon[client]) {
        
        SetEntProp(viewModel1, Prop_Send, "m_nModelIndex", 0); //hide original
        SetEntData(viewModel2, g_iOffset_Sequence, GetEntData(viewModel1, g_iOffset_Sequence)-g_AnimOffset, _, true);
        SetEntData(viewModel2, g_iOffset_PlaybackRate, GetEntData(viewModel1, g_iOffset_PlaybackRate), _, true);

    }else{

        SetEntProp(viewModel2, Prop_Send, "m_nModelIndex", 0); //hide fake
    }
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBrodcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (GetClientTeam(client) > 1) {
        // Create the second view model.
        SDKCall(g_hCreateViewModel, client, 1);

        g_iViewModels[client][0] = GetViewModel(client, 0);
        g_iViewModels[client][1] = GetViewModel(client, 1);
    }
}

int GetViewModel(int client, int index) {
    return GetEntDataEnt2(client, g_iOffset_ViewModel + (index * 4));
}