#include <sdktools>
#include <thirdperson_api>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.1.0F"

bool g_bThirdPersonEnabled[MAXPLAYERS+1];

public Plugin myinfo ={
	name 		= "[TF2] Thirdperson API",
	author 		= "DarthNinja & Someone [API]",
	description = "Allows players to use thirdperson without having to enable client sv_cheats.",
	version 	= PLUGIN_VERSION,
	url 		= "https://DarthNinja.com | https://hlmod.ru/"
};

Handle 	g_hForward_OnModeChange;

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] sError, int iErr_max){
	CreateNative("TP_SetMod", 					Native_SetMod);
	CreateNative("TP_GetMod", 					Native_GetMod);
	
	g_hForward_OnModeChange = CreateGlobalForward("TP_OnModChange",	ET_Ignore,	Param_Cell,	Param_Cell);

	RegPluginLibrary("thirdperson_api");
	
	return APLRes_Success;
}

int Native_SetMod(Handle hPlugin, int iClient){
	if((iClient = GetNativeCell(1)) > 0 && iClient <= MaxClients && IsClientInGame(iClient)){
		bool bMode = view_as<bool>(GetNativeCell(2));
		g_bThirdPersonEnabled[iClient] = bMode;
		SetMod(iClient, bMode);
		return 0;
	}
	ThrowNativeError(SP_ERROR_NATIVE, "[SetMod] Client %d invalid.", iClient);
	return 0;
}

int Native_GetMod(Handle hPlugin, int iClient){
	if((iClient = GetNativeCell(1)) > 0 && iClient <= MaxClients && IsClientInGame(iClient)){
		return g_bThirdPersonEnabled[iClient];
	}
	ThrowNativeError(SP_ERROR_NATIVE, "[GetMod] Client %d invalid.", iClient);
	return false;
}

public void OnPluginStart(){
	RegConsoleCmd("sm_thirdperson", EnableThirdperson, "Usage: sm_thirdperson");
	RegConsoleCmd("tp", EnableThirdperson, "Usage: sm_thirdperson");
	RegConsoleCmd("sm_firstperson", DisableThirdperson, "Usage: sm_firstperson");
	RegConsoleCmd("fp", DisableThirdperson,"Usage: sm_firstperson");
	//RegConsoleCmd("helloserverplugintogglethirdpresononmeplease", HiLeonardo, "Hi Leonardo");
	HookEvent("player_spawn", Events);
	HookEvent("player_class", Events);
}

Action Events(Handle hEvent, const char[] sName, bool bDontBroadcast){
	int iUserID = GetEventInt(hEvent, "userid");
	if(g_bThirdPersonEnabled[GetClientOfUserId(iUserID)]){
		CreateTimer(0.2, SetViewOnSpawn, iUserID, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action SetViewOnSpawn(Handle hTimer, any iClient){
	iClient = GetClientOfUserId(iClient);
	if(iClient > 0 && iClient <= MaxClients && g_bThirdPersonEnabled[iClient] && IsClientInGame(iClient) && IsPlayerAlive(iClient)){
		SetVariantInt(1);
		AcceptEntityInput(iClient, "SetForcedTauntCam");
	}
}

Action EnableThirdperson(int iClient, int iArgs){
	if(IsClientInGame(iClient)){
		if(!g_bThirdPersonEnabled[iClient]){
			if(!IsPlayerAlive(iClient)){
				PrintToChat(iClient, "[SM] Thirdperson view will be enabled when you spawn.");
				g_bThirdPersonEnabled[iClient] = true;
				OnModeChange(iClient, g_bThirdPersonEnabled[iClient]);
				return Plugin_Handled;
			}
			SetMod(iClient, true);
			g_bThirdPersonEnabled[iClient] = true;
		}else{
			PrintToChat(iClient, "[SM] Thirdperson already enabled.");
		}
	}
	return Plugin_Handled;
}

Action DisableThirdperson(int iClient, int iArgs){
	if(IsClientInGame(iClient)){
		if(g_bThirdPersonEnabled[iClient]){
			if(!IsPlayerAlive(iClient)){
				PrintToChat(iClient, "[SM] Thirdperson view disabled!");
				g_bThirdPersonEnabled[iClient] = false;
				OnModeChange(iClient, g_bThirdPersonEnabled[iClient]);
				return Plugin_Handled;
			}
			SetMod(iClient, false);
			g_bThirdPersonEnabled[iClient] = false;
		}else{
			PrintToChat(iClient, "[SM] Already in firstperson.");
		}
	}
	return Plugin_Handled;
}

void SetMod(int iClient, bool bMode){
	SetVariantInt(bMode);
	AcceptEntityInput(iClient, "SetForcedTauntCam");
	
	OnModeChange(iClient, bMode);
}

void OnModeChange(int iClient, bool bMode){
	Call_StartForward(g_hForward_OnModeChange);
	Call_PushCell(iClient);
	Call_PushCell(bMode);
	Call_Finish();
}

public void OnClientDisconnect(int iClient){
	g_bThirdPersonEnabled[iClient] = false;
}

/*
Action HiLeonardo(int iClient, int iArgs){
	int i;
	FakeClientCommand(iClient, "voicemenu 0 7");
	while (IsPlayerAlive(iClient) && i <= 500){
		SlapPlayer(iClient, 1000);
		i++;
	}
	return Plugin_Handled;
}
*/