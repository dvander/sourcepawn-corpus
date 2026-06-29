#pragma semicolon 1
#include <sourcemod>
#include <netprops>
#include <tentdev>

new Handle:g_hNetprops[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:g_hIgnoreNetProps[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

new g_iMarkedEntity[MAXPLAYERS+1] = {-1,...};
new bool:g_bStopWatching[MAXPLAYERS+1] = {true, ...};

new String:g_sSeparator[40];
new Float:g_fWatchTimerInterval;

//Forwards
new Handle:g_hForwardCompareMessage;
new Handle:g_hForwardShowMessage;
new Handle:g_hForwardInfoMessage;
new Handle:g_hForwardNetpropMessage;

//Cvars
new Handle:g_hCvarSeparator = INVALID_HANDLE;
new Handle:g_hCvarWatchTimerInterval = INVALID_HANDLE;

public Plugin:myinfo =
{
	name 		= "tEntDev",
	author 		= "Thrawn",
	description = "Allows to do stuff with the netprops of an entity",
	version 	= VERSION,
};

public OnPluginStart() {
	CreateConVar("sm_tentdev_version", VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hForwardCompareMessage = CreateGlobalForward("TED_OnCompare", ET_Ignore, Param_Cell, Param_String, Param_String, Param_String, Param_Cell);
	g_hForwardShowMessage = CreateGlobalForward("TED_OnShow", ET_Ignore, Param_Cell, Param_String, Param_String, Param_Cell);
	g_hForwardInfoMessage = CreateGlobalForward("TED_OnInfo", ET_Ignore, Param_Cell, Param_String);
	g_hForwardNetpropMessage = CreateGlobalForward("TED_OnNetpropHint", ET_Ignore, Param_Cell, Param_String, Param_String);

	g_hCvarSeparator = CreateConVar("sm_tentdev_separator", "------------------------------", "Separator between watch steps", FCVAR_PLUGIN);
	g_hCvarWatchTimerInterval = CreateConVar("sm_tentdev_watchinterval", "1.0", "Interval between watch steps", FCVAR_PLUGIN);

	HookConVarChange(g_hCvarSeparator, Cvar_Changed);
	HookConVarChange(g_hCvarWatchTimerInterval, Cvar_Changed);
}

public OnConfigsExecuted() {
	GetConVarString(g_hCvarSeparator, g_sSeparator, sizeof(g_sSeparator));
	g_fWatchTimerInterval = GetConVarFloat(g_hCvarWatchTimerInterval);
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}

public OnPlayerDisconnect(client) {
	g_bStopWatching[client] = true;
	g_iMarkedEntity[client] = -1;
	ClearKeyValues(g_hIgnoreNetProps[client]);
	ClearKeyValues(g_hNetprops[client]);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	RegPluginLibrary("ted");

	CreateNative("TED_IgnoreNetprop", Native_IgnoreNetprop);
	CreateNative("TED_UnignoreNetprop", Native_UnignoreNetprop);
	CreateNative("TED_SelectEntity", Native_SelectEntity);
	CreateNative("TED_ShowNetprops", Native_ShowNetprops);
	CreateNative("TED_WatchNetprops", Native_WatchNetprops);
	CreateNative("TED_StopWatchNetprops", Native_StopWatchNetprops);
	CreateNative("TED_SaveNetprops", Native_SaveNetprops);
	CreateNative("TED_CompareNetprops", Native_CompareNetprops);
	CreateNative("TED_SetNetprop", Native_SetNetprop);

	return APLRes_Success;
}

public Native_SetNetprop(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	if(!CheckClientSelection(client))return false;

	new String:sNetProp[127];
	GetNativeString(2, sNetProp, sizeof(sNetProp));

	new String:sValue[127];
	GetNativeString(3, sValue, sizeof(sValue));

	new iEntity = g_iMarkedEntity[client];
	new bool:bSuccess = false;
	if(KvGotoFirstSubKey(g_hNetprops[client], false)) {
        do {
			new String:sName[64];
			KvGetString(g_hNetprops[client], "name", sName, sizeof(sName));

			new String:sParent[64];
			KvGetString(g_hNetprops[client], "parent", sParent, sizeof(sParent));

			new String:sLongName[128];
			Format(sLongName, sizeof(sLongName), "%s->%s", sParent, sName);

			if(StrEqual(sNetProp, sName) || StrEqual(sNetProp, sLongName)) {
				new String:sOffset[6];
				KvGetSectionName(g_hNetprops[client], sOffset, sizeof(sOffset));
				new iOffset = StringToInt(sOffset);

				new SendPropType:iType = SendPropType:KvGetNum(g_hNetprops[client], "type");
				new iByte = KvGetNum(g_hNetprops[client], "byte");

				if(iOffset > 0) {
					if(iType == DPT_Int) {
						new iValue = StringToInt(sValue);
						if(client != 0) {
							PrintToChat(client, "Setting %s->%s to %i (%i)", sParent, sNetProp, iValue, iType);
						} else {
							PrintToServer("Setting %s->%s to %i (%i)", sParent, sNetProp, iValue, iType);
						}
						SetEntData(iEntity, iOffset, iValue, iByte, true);
						bSuccess = true;
					}

					if(iType == DPT_Vector) {
						Call_StartForward(g_hForwardInfoMessage);
						Call_PushCell(client);
						Call_PushString("Setting of type vector is not implemented yet");
						Call_Finish();
					}

					if(iType == DPT_Float) {
						new Float:fValue = StringToFloat(sValue);
						if(client != 0) {
							PrintToChat(client, "Setting %s->%s to %.2f (%i)", sParent, sNetProp, fValue, iType);
						} else {
							PrintToServer("Setting %s->%s to %.2f (%i)", sParent, sNetProp, fValue, iType);
						}
						SetEntData(iEntity, iOffset, fValue, true);
						bSuccess = true;
					}
				}
			}

			KvSetString(g_hNetprops[client], "value", sValue);
        } while (KvGotoNextKey(g_hNetprops[client], false) && bSuccess == false);
        KvGoBack(g_hNetprops[client]);
    }

	return bSuccess;
}

public Native_UnignoreNetprop(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new String:sNetProp[127];
	GetNativeString(2, sNetProp, sizeof(sNetProp));

	if(g_hIgnoreNetProps[client] == INVALID_HANDLE) {
		g_hIgnoreNetProps[client] = CreateTrie();
	}

	SetTrieValue(g_hIgnoreNetProps[client], sNetProp, 0, true);
	Call_StartForward(g_hForwardNetpropMessage);
	Call_PushCell(client);
	Call_PushString("Stopped ignoring netprop:");
	Call_PushString(sNetProp);
	Call_Finish();
}

public Native_IgnoreNetprop(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new String:sNetProp[127];
	GetNativeString(2, sNetProp, sizeof(sNetProp));

	if(g_hIgnoreNetProps[client] == INVALID_HANDLE) {
		g_hIgnoreNetProps[client] = CreateTrie();
	}

	SetTrieValue(g_hIgnoreNetProps[client], sNetProp, 1, true);
	Call_StartForward(g_hForwardNetpropMessage);
	Call_PushCell(client);
	Call_PushString("Ignoring netprop:");
	Call_PushString(sNetProp);
	Call_Finish();
}

public Native_SaveNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);

	if(!CheckClientSelection(client))return false;
	UpdateKeyValues(client);
	return true;
}

public Native_WatchNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);

	if(!CheckClientSelection(client))return false;

	UpdateKeyValues(client);

	g_bStopWatching[client] = false;
	CreateTimer(g_fWatchTimerInterval, Timer_WatchEntity, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return true;
}

public Action:Timer_WatchEntity(Handle:timer, any:client) {
	if(g_bStopWatching[client])return Plugin_Stop;
	if(!IsClientInGame(client) || !IsClientConnected(client))return Plugin_Stop;
	if(!CheckClientSelection(client))return Plugin_Stop;

	UpdateKeyValues(client, true);
	return Plugin_Continue;
}

public Native_StopWatchNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	g_bStopWatching[client] = true;
}

public Native_SelectEntity(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);
	new iEnt = GetNativeCell(2);

	g_bStopWatching[client] = true;

	decl String:sNetclass[64];
	if(GetEntityNetClass(iEnt, sNetclass, sizeof(sNetclass))) {
		LogMessage("Marked: %s", sNetclass);
		Call_StartForward(g_hForwardNetpropMessage);
		Call_PushCell(client);
		Call_PushString("You've marked:");
		Call_PushString(sNetclass);
		Call_Finish();


		g_iMarkedEntity[client] = iEnt;

		new Handle:hSendTable = GetSendTableByNetclass(sNetclass);
		ClearKeyValues(g_hNetprops[client]);
		g_hNetprops[client] = CreateKeyValues(sNetclass);
		GetKeyValuesForNetClass(g_hNetprops[client], hSendTable, 0, sNetclass);

		UpdateKeyValues(client, false);
		KeyValuesToFile(g_hNetprops[client], "kvtest.txt");
		return true;
	}

	return false;
}

public bool:CheckClientSelection(client) {
	if(g_hNetprops[client] == INVALID_HANDLE) {
		Call_StartForward(g_hForwardInfoMessage);
		Call_PushCell(client);
		Call_PushString("No netprops saved");
		Call_Finish();
		return false;
	}

	new iEnt = g_iMarkedEntity[client];
	if(iEnt == -1) {
		Call_StartForward(g_hForwardInfoMessage);
		Call_PushCell(client);
		Call_PushString("No entity marked");
		Call_Finish();
		return false;
	}

	if(!IsValidEdict(iEnt)) {
		Call_StartForward(g_hForwardInfoMessage);
		Call_PushCell(client);
		Call_PushString("Entity does not exist");
		Call_Finish();
		return false;
	}

	return true;
}

public Native_CompareNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);

	g_bStopWatching[client] = true;
	if(!CheckClientSelection(client))return false;

	UpdateKeyValues(client, true);
	return true;
}

public Native_ShowNetprops(Handle:hPlugin, iNumParams) {
	new client = GetNativeCell(1);

	g_bStopWatching[client] = true;
	if(!CheckClientSelection(client))return false;

	UpdateKeyValues(client, false, true);
	return true;
}


public ClearKeyValues(&Handle:hKV) {
	if(hKV != INVALID_HANDLE) {
		CloseHandle(hKV);
		hKV = INVALID_HANDLE;
	}

}

ShowSeparator(client) {
	Call_StartForward(g_hForwardInfoMessage);
	Call_PushCell(client);
	Call_PushString(g_sSeparator);
	Call_Finish();
}

UpdateKeyValues(client, bool:bShowChanges = false, bool:bShowAll = false) {
	new iEntity = g_iMarkedEntity[client];

	new bSeparatorShown = false;

	if(KvGotoFirstSubKey(g_hNetprops[client], false)) {
        do {
			new String:sKey[6];
			KvGetSectionName(g_hNetprops[client], sKey, sizeof(sKey));
			new iOffset = StringToInt(sKey);

			new SendPropType:iType = SendPropType:KvGetNum(g_hNetprops[client], "type");
			new iByte = KvGetNum(g_hNetprops[client], "byte");

			new String:sResult[64];
			if(iOffset > 0) {
				if(iType == DPT_Int) {
					Format(sResult, sizeof(sResult), "%i", GetEntData(iEntity, iOffset, iByte));
				}

				if(iType == DPT_Vector) {
					new Float:vData[3];
					GetEntDataVector(iEntity, iOffset, vData);
					Format(sResult, sizeof(sResult), "%.4f %.4f %.4f", vData[0], vData[1], vData[2]);
				}

				if(iType == DPT_Float) {
					Format(sResult, sizeof(sResult), "%.4f", GetEntDataFloat(iEntity, iOffset));
				}
			}

			new String:sCurrentValue[64];
			KvGetString(g_hNetprops[client], "value", sCurrentValue, sizeof(sCurrentValue));

			new String:sName[64];
			KvGetString(g_hNetprops[client], "name", sName, sizeof(sName));

			new String:sParent[64];
			KvGetString(g_hNetprops[client], "parent", sParent, sizeof(sParent));

			new String:sLongName[128];
			Format(sLongName, sizeof(sLongName), "%s->%s", sParent, sName);

			if(!StrEqual(sCurrentValue, sResult) && bShowChanges && !bShowAll) {
				new bool:bIgnore = false;
				if(g_hIgnoreNetProps[client] != INVALID_HANDLE) {
					GetTrieValue(g_hIgnoreNetProps[client], sName, bIgnore);
					GetTrieValue(g_hIgnoreNetProps[client], sLongName, bIgnore);
				}
				if(bIgnore)continue;

				if((bShowChanges || bShowAll) && !bSeparatorShown) {
					ShowSeparator(client);
					bSeparatorShown = true;
				}

				Call_StartForward(g_hForwardCompareMessage);
				Call_PushCell(client);
				Call_PushString(sLongName);
				Call_PushString(sCurrentValue);
				Call_PushString(sResult);
				Call_PushCell(iOffset);
				Call_Finish();

				//LogMessage("%s changed from %s to %s", sName, sCurrentValue, sResult);
			}

			if(bShowAll) {
				if((bShowChanges || bShowAll) && !bSeparatorShown) {
					ShowSeparator(client);
					bSeparatorShown = true;
				}

				Call_StartForward(g_hForwardShowMessage);
				Call_PushCell(client);
				Call_PushString(sLongName);
				Call_PushString(sResult);
				Call_PushCell(iOffset);
				Call_Finish();

				//LogMessage("%s -> %s", sName, sResult);
			}


			KvSetString(g_hNetprops[client], "value", sResult);
        } while (KvGotoNextKey(g_hNetprops[client], false));
        KvGoBack(g_hNetprops[client]);
    }

}

public GetKeyValuesForNetClass(Handle:hKV, Handle:hSendTable, iOffsetRecursive, const String:sParent[]) {
	new iCount = GetNumProps(hSendTable);

	for(new i = 0; i < iCount; i++) {
		new Handle:hProp = GetProp(hSendTable, i);

		new String:sName[64];
		GetPropName(hProp, sName, sizeof(sName));

		new iOffset = GetOffset(hProp);
		new iActualOffset = iOffset + iOffsetRecursive;
		new iBits = GetBits(hProp);
		new iByte = 1;
		if(iBits > 8)iByte = 2;
		if(iBits > 16)iByte = 4;

		new SendPropType:iType = GetType(hProp);

		if(iType == DPT_DataTable) {
			//GetTableName(GetDataTable(hProp), sName, sizeof(sName));

			GetKeyValuesForNetClass(hKV, GetDataTable(hProp), iActualOffset, sName);
		} else {
			AddEntry(hKV, sName, sParent, iActualOffset, _:iType, iByte);
			//LogMessage("%i->%s (%s)", iActualOffset, sName, sResult);
		}
	}
}


public AddEntry(Handle:hKV, const String:sName[], const String:sParent[], iOffset, iType, iByte) {
	if(iOffset == 0)return;

	new String:sOffset[6];
	Format(sOffset, sizeof(sOffset), "%i", iOffset);

	if(!KvJumpToKey(hKV, sOffset, false)) { //Only create non existing keys, dont overwrite
		KvJumpToKey(hKV, sOffset, true);
		KvSetString(hKV, "parent", sParent);
		KvSetString(hKV, "name", sName);
		KvSetNum(hKV, "type", iType);
		KvSetNum(hKV, "byte", iByte);
	}
	KvGoBack(hKV);
}