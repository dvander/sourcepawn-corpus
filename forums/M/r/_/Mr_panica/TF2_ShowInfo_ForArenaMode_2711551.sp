#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo ={
	name 		= 	"TF2 Show Info",
	author 		= 	"Someone",
	version 	= 	"1.0.0",
	url			= 	"https://hlmod.ru/ | https://discord.gg/UfD3dSa"
};

#define ANNOTATION_OFFSET			1500
#define REFRESH_RATE			0.5

bool 	g_bShowUserID[MAXPLAYERS+1];
		//g_bAlreadyEnabled;
int 	g_iPlayerVisible[MAXPLAYERS+1];
float	g_fDistance;
Handle	g_hVisibilityTimer;
ArrayList g_hPlayerNames[MAXPLAYERS+1];

public void OnPluginStart(){
	ConVar CVAR;
	(CVAR = CreateConVar("sm_tf2_showinfo_distance",	"512.0",	"Maximum info distance", _, true, 0.0)).AddChangeHook(OnDistanceChange);
	g_fDistance = CVAR.FloatValue;

	RegAdminCmd("sm_showuid", CMD_SHOW, ADMFLAG_GENERIC);
	RegAdminCmd("sm_showuidchat", CMD_SHOWINFO, ADMFLAG_CUSTOM3);
	
	//HookEvent("player_changename", Event_ChangeName);
	
	for(int i = MaxClients+1; --i;) if(IsClientInGame(i)){
		OnClientPutInServer(i);
	}
	
	LoadTranslations("tf2_showinfo.phrases");
}

public void OnClientSettingsChanged(int iClient){
	if(!IsFakeClient(iClient)){
		char sBuffer[MAX_NAME_LENGTH];
		GetClientName(iClient, sBuffer, sizeof(sBuffer));
		
		int iLen = g_hPlayerNames[iClient].Length;
		char sOldName[MAX_NAME_LENGTH];
		if(g_hPlayerNames[iClient].GetString(iLen-1, sOldName, sizeof(sOldName)) && strcmp(sBuffer, sOldName) != 0){
			if(iLen == 5){
				g_hPlayerNames[iClient].Erase(0);
			}
			g_hPlayerNames[iClient].PushString(sBuffer);
		}
	}
}

/*
void Event_ChangeName(Event hEvent, const char[] sName, bool bDontBroadcast){
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if(IsClientInGame(iClient) && !IsFakeClient(iClient)){
		char sBuffer[MAX_NAME_LENGTH];
		hEvent.GetString("newname", sBuffer, sizeof(sBuffer));
		if(g_hPlayerNames[iClient].Length == 5){
			g_hPlayerNames[iClient].Erase(0);
		}
		g_hPlayerNames[iClient].PushString(sBuffer);
	}
}
*/

void OnDistanceChange(ConVar convar, const char[] oldValue, const char[] newValue){
	g_fDistance = convar.FloatValue;
}

Action CMD_SHOWINFO(int iClient, int iArgs){
	char sBuffer[256], sName[MAX_NAME_LENGTH];
	if(iClient){
		if(IsClientInGame(iClient)) {
			for(int i = MaxClients+1, iLen, x; --i;) if(IsClientInGame(i) && !IsFakeClient(i)){
				FormatEx(sBuffer, sizeof(sBuffer), "[#%d]", GetClientUserId(i));
				for(x = 0, iLen = g_hPlayerNames[i].Length; x < iLen; x++){
					g_hPlayerNames[i].GetString(x, sName, sizeof(sName));
					Format(sBuffer, sizeof(sBuffer), "%s%s%s", sBuffer, x == 0 ? " ":"->", sName);
				}
				PrintToChat(iClient, sBuffer);
			}
		}
	}else{
		for(int i = MaxClients+1; --i;) if(IsClientInGame(i) && !IsFakeClient(i)){
			
		}
	}
	return Plugin_Handled;
}

Action CMD_SHOW(int iClient, int iArgs){
	if(iClient && IsClientInGame(iClient)){
		g_bShowUserID[iClient] = !(g_bShowUserID[iClient]);
		
		if(g_bShowUserID[iClient]){
			if(!g_hVisibilityTimer){
				g_hVisibilityTimer = CreateTimer(REFRESH_RATE, TIMER_CHECK_VISIBILITY, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			
			//int iVisibility;
			//Event hEvent;
			//for(int iTarget = MaxClients+1; --iTarget;) if(iTarget != iClient){
			//	hEvent = CreateEvent("show_annotation");
			//	hEvent.SetInt("follow_entindex", iTarget);
			//	hEvent.SetInt("id", ANNOTATION_OFFSET+iTarget);
			//	hEvent.SetInt("visibilityBitfield", (1 << iClient)|(1 << iTarget));
			//	hEvent.SetFloat("lifetime", 99999.0);
			//	hEvent.SetString("text", "test");
			//	hEvent.Fire();
			//}
			
			PrintToChat(iClient, "%t%t", "Prefix", "Enabled");
		}else{
			bool bIsAnotherOne;
			for(int iTarget = MaxClients+1; --iTarget;){
				if(g_bShowUserID[iClient]){
					bIsAnotherOne = true;
				}
				if(g_iPlayerVisible[iClient] & (1 << iTarget)){
					HideAnnotation(iTarget, iClient);
				}
			}
			
			g_iPlayerVisible[iClient] = 0;
			
			if(!bIsAnotherOne){
				delete g_hVisibilityTimer;
				// g_hVisibilityTimer = null;
			}
			
			PrintToChat(iClient, "%t%t", "Prefix", "Disabled");
		}
	}

	return Plugin_Handled;
}

Action TIMER_CHECK_VISIBILITY(Handle hTimer){
	float fTargetPos[3], fAdminPos[3];
	int iVisibility;
	Event hEvent;
	/*
	for(int i = MaxClients+1, b; --i;) if(g_bShowUserID[i]){
		GetClientEyePosition(i, fStart);
		iVisibility = 0;
		for(b = MaxClients+1; --b;) if(i != b && IsClientInGame(b) && IsPlayerAlive(b)){
			GetClientEyePosition(b, fEnd);
			TR_TraceRayFilter(fStart, fEnd, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceFilterEntity, iTarget);
			if(TR_GetEntityIndex() == b){
				if(!g_bPlayerVisible[i][b]){
					iVisibility |= (1 << b);
					g_bPlayerVisible[i][b] = true;
				}
			}else if(g_bPlayerVisible[i][b]){
				hEvent = CreateEvent(,"hide_annotation");
				hEvent.SetInt("id", iID);
				hEvent.FireToClient(i);
				hEvent.Close();
				g_bPlayerVisible[i][b] = false;
			}
		}
		
		if(iVisibility){
			Event hEvent = CreateEvent("show_annotation");
			hEvent.SetInt("follow_entindex", iClient);
			hEvent.SetInt("id", iID);
			hEvent.SetInt("visibilityBitfield", visibility);
			hEvent.SetFloat("lifetime", 99999999.0);
		}
	}
	*/
	char sBuffer[128];
	for(int iTarget = MaxClients+1, iAdmin; --iTarget;) if(IsClientInGame(iTarget) && IsPlayerAlive(iTarget) && !IsClientSourceTV(iTarget)){
		GetClientEyePosition(iTarget, fTargetPos);
		iVisibility = 0;
		
		for(iAdmin = MaxClients+1; --iAdmin;) if(iTarget != iAdmin && g_bShowUserID[iAdmin]){
			GetClientEyePosition(iAdmin, fAdminPos);
			if(g_fDistance == 0.0 || GetVectorDistance(fAdminPos, fTargetPos) < g_fDistance){
				TR_TraceRayFilter(fAdminPos, fTargetPos, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceFilterEntity, iTarget);
				if(TR_GetEntityIndex() == iTarget){
					if(!(g_iPlayerVisible[iAdmin] & (1 << iTarget))){
						iVisibility |= (1 << iAdmin);
						g_iPlayerVisible[iAdmin] |= (1 << iTarget);
					}
				}else if(g_iPlayerVisible[iAdmin] & (1 << iTarget)){
					HideAnnotation(iTarget, iAdmin);
					g_iPlayerVisible[iAdmin] &= ~(1 << iTarget);
				}
			}else if(g_iPlayerVisible[iAdmin] & (1 << iTarget)){
				HideAnnotation(iTarget, iAdmin);
				g_iPlayerVisible[iAdmin] &= ~(1 << iTarget);
			}
		}

		if(iVisibility){
			hEvent = CreateEvent("show_annotation");
			hEvent.SetInt("follow_entindex", iTarget);
			hEvent.SetInt("id", ANNOTATION_OFFSET+iTarget);
			hEvent.SetInt("visibilityBitfield", iVisibility);
			hEvent.SetFloat("lifetime", 99999999.0);
			FormatEx(sBuffer, sizeof(sBuffer), "%N\nUserID: #%d", iTarget, GetClientUserId(iTarget));
			hEvent.SetString("text", sBuffer);
			hEvent.Fire();
		}
	}

	return Plugin_Continue;
}

bool TraceFilterEntity(int iEnt, int iMask, any iData){
	return iEnt == iData;
}

public void OnClientPutInServer(int iClient){
	if(!IsFakeClient(iClient)){
		g_hPlayerNames[iClient] = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
		char sBuffer[MAX_NAME_LENGTH];
		GetClientName(iClient, sBuffer, sizeof(sBuffer));
		g_hPlayerNames[iClient].PushString(sBuffer);
	}
}

public void OnClientDisconnect(int iClient){
	if(!IsFakeClient(iClient)){
		if(g_hVisibilityTimer){
			bool bAlreadyFired, bIsAnotherOne;
			for(int iAdmin = MaxClients+1, iTarget; --iAdmin;) if(g_bShowUserID[iAdmin] && g_iPlayerVisible[iAdmin] & (1 << iClient)){
				g_iPlayerVisible[iAdmin] &= ~(1 << iClient);
				if(!bAlreadyFired){
					HideAnnotation(iClient, 0);
					bAlreadyFired = true;
				}
				
				if(!bIsAnotherOne){
					for(iTarget = MaxClients+1; --iTarget;) if(g_iPlayerVisible[iAdmin] & (1 << iTarget)){
						bIsAnotherOne = true;
						break;
					}
				}
			}

			if(!bIsAnotherOne){
				delete g_hVisibilityTimer;
				// g_hVisibilityTimer = null;
			}
		}
		
		g_bShowUserID[iClient] = false;
		g_iPlayerVisible[iClient] = 0;
		delete g_hPlayerNames[iClient];
	}
}

public void OnMapStart(){
	g_hVisibilityTimer = null;
}

void HideAnnotation(int iID, int iClient){
	Event hEvent = CreateEvent("hide_annotation");
	hEvent.SetInt("id", ANNOTATION_OFFSET+iID);
	if(iClient){
		hEvent.FireToClient(iClient);
		hEvent.Close();
	}else{
		hEvent.Fire();
	}
}