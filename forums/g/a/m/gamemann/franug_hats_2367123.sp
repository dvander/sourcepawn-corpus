#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <smartdm>
#include <dhooks>
#include <multicolors>

enum Hat
{
	String:Name[64],
	String:szModel[PLATFORM_MAX_PATH],
	String:szAttachment[64],
	Float:fPosition[3],
	Float:fAngles[3],
	bool:bBonemerge,
	String:flag[8]
}

new bool:viendo[MAXPLAYERS+1];

new g_eHats[1024][Hat];
new g_Elegido[MAXPLAYERS + 1];
new g_hats;
new g_Hat[MAXPLAYERS+1];

//new Handle:g_hLookupAttachment = INVALID_HANDLE;

new Handle:c_GameSprays = INVALID_HANDLE;

new Handle:kv;
new String:sConfig[PLATFORM_MAX_PATH];

new Handle:hSetModel;
new Handle:mp_forcecamera;

new Handle:menu_hats;
new Handle:menu_editor;

// ConVars
new Handle:g_hThirdPerson = INVALID_HANDLE;

// ConVar Values
new bool:g_bThirdPerson;

#define DATA "2.2"

public Plugin:myinfo = 
{
	name = "SM Franug Hats",
	author = "Franc1sco franug",
	description = "Hats",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	mp_forcecamera = FindConVar("mp_forcecamera");
	CreateConVar("sm_franughats_version", DATA, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_GameSprays = RegClientCookie("Hats", "Hats", CookieAccess_Private);
	RegConsoleCmd("sm_hats", Command_Hats);
	
	// ConVars
	g_hThirdPerson = CreateConVar("sm_franughats_thirdperson", "1", "Enable/Disable third-person view.");
	
	// ConVar Changes.
	HookConVarChange(g_hThirdPerson, CVarChanged);
	
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	
	new Handle:hGameConf;
	
/* 	hGameConf = LoadGameConfigFile("franug_hats.gamedata");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "LookupAttachment");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hLookupAttachment = EndPrepSDKCall(); */
	
	hGameConf = LoadGameConfigFile("sdktools.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Gamedata file sdktools.games.txt is missing.");
	new iOffset = GameConfGetOffset(hGameConf, "SetEntityModel");
	CloseHandle(hGameConf);
	if(iOffset == -1)
		SetFailState("Gamedata is missing the \"SetEntityModel\" offset.");
		
	hSetModel = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, SetModel);
	DHookAddParam(hSetModel, HookParamType_CharPtr);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegAdminCmd("sm_editor", DOMenu, ADMFLAG_ROOT, "Opens hats editor.");
	RegAdminCmd("sm_reloadhats", Reload, ADMFLAG_ROOT, "Reload hats configuration.");
	
	LoadHats();
	
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
			OnClientPutInServer(i);
		}
		
	// Load Translations.
	LoadTranslations("franughats.phrases.txt");
		
	// Auto-load the config.
	AutoExecConfig(true, "plugin.franughats");
}

public CVarChanged(Handle:hConvar, const String:oldV[], const String:newV[])
{
	OnConfigsExecuted();
}

public OnConfigsExecuted()
{
	// Get the values.
	g_bThirdPerson = GetConVarBool(g_hThirdPerson);
}

public OnClientPutInServer(client)
{
	DHookEntity(hSetModel, true, client);
}

public MRESReturn:SetModel(client, Handle:hParams)
{
	CreateHat(client);
	
	return MRES_Ignored;
}

public OnPluginEnd()
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i)) OnClientDisconnect(i);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	viendo[client] = false;
	CreateHat(client);
}

public Action:Command_Hats(client, args)
{	
	Showmenuh(client, 0);
	return Plugin_Handled;
}

public Action:Reload(client, args)
{	
	LoadHats();
	CPrintToChat(client, "%t%t", "Tag", "ConfigReloaded");
	return Plugin_Handled;
}

Showmenuh(client, item2)
{
	DisplayMenuAtItem(menu_hats, client, item2, 0);
	
	viendo[client] = true;
	SetThirdPersonView(client, true);
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		decl String:info[4];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		new index = StringToInt(info);
		if(!StrEqual(g_eHats[index][flag], "0") && !HasPermission(client, g_eHats[index][flag]))
		{
			CPrintToChat(client, "%t", "NoAccess");
			Showmenuh(client, GetMenuSelectionPosition());
			return;
		}
		g_Elegido[client] = index;
		CPrintToChat(client, "%t%t", "Tag", "Chosen", g_eHats[g_Elegido[client]][Name]);
		CreateHat(client);
		Showmenuh(client, GetMenuSelectionPosition());
	}
	else if (action == MenuAction_Cancel) 
	{ 
		if(IsClientInGame(client) && viendo[client])
		{
			viendo[client] = false;
			SetThirdPersonView(client, false);
		}
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, itemNum); 
	} 
}

public LoadHats()
{
	g_hats = 0;
	BuildPath(Path_SM, sConfig, PLATFORM_MAX_PATH, "configs/franug_hats.txt");
	
	if(kv != INVALID_HANDLE) CloseHandle(kv);
	
	kv = CreateKeyValues("Hats");
	FileToKeyValues(kv, sConfig);

	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			decl Float:m_fTemp[3];
			KvGetSectionName(kv, g_eHats[g_hats][Name], 64);
			KvGetString(kv, "model", g_eHats[g_hats][szModel], PLATFORM_MAX_PATH);
			KvGetVector(kv, "position", m_fTemp);
			g_eHats[g_hats][fPosition] = m_fTemp;
			KvGetVector(kv, "angles", m_fTemp);
			g_eHats[g_hats][fAngles] = m_fTemp;
			g_eHats[g_hats][bBonemerge] = (KvGetNum(kv, "bonemerge", 0)?true:false);
			KvGetString(kv, "attachment", g_eHats[g_hats][szAttachment], 64, "facemask");
			KvGetString(kv, "flag", g_eHats[g_hats][flag], 8, "0");
			
			
			if(!StrEqual(g_eHats[g_hats][szModel], "none") && strcmp(g_eHats[g_hats][szModel], "")!=0)
			{
				
				if(FileExists(g_eHats[g_hats][szModel]))
				{
					PrecacheModel(g_eHats[g_hats][szModel], true);
					Downloader_AddFileToDownloadsTable(g_eHats[g_hats][szModel]);
				}
				else FileExists(g_eHats[g_hats][szModel], true)
				{
					PrecacheModel(g_eHats[g_hats][szModel], true);
				}
				
			}
			
			++g_hats;
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
	
	if(menu_hats != INVALID_HANDLE) CloseHandle(menu_hats);
	
	menu_hats = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu_hats, "Choose Hat");
	decl String:item[4];
	for (new i=0; i<g_hats; ++i) {
		Format(item, 4, "%i", i);
		AddMenuItem(menu_hats, item, g_eHats[i][Name]);
	}
	SetMenuExitButton(menu_hats, true);
	
	if(menu_editor != INVALID_HANDLE) CloseHandle(menu_editor);
	
	menu_editor = CreateMenu(DIDMenuHandler2);
	SetMenuTitle(menu_editor, "Hats Editor");
	
	AddMenuItem(menu_editor, "Position X+0.5", "Position X + 0.5");
	AddMenuItem(menu_editor, "Position X-0.5", "Position X - 0.5");
	AddMenuItem(menu_editor, "Position Y+0.5", "Position Y + 0.5");
	AddMenuItem(menu_editor, "Position Y-0.5", "Position Y - 0.5");
	AddMenuItem(menu_editor, "Position Z+0.5", "Position Z + 0.5");
	AddMenuItem(menu_editor, "Position Z-0.5", "Position Z - 0.5");
	AddMenuItem(menu_editor, "Angle X+0.5", "Angle X + 0.5");
	AddMenuItem(menu_editor, "Angle X-0.5", "Angle X - 0.5");
	AddMenuItem(menu_editor, "Angle Y+0.5", "Angle Y + 0.5");
	AddMenuItem(menu_editor, "Angle Y-0.5", "Angle Y - 0.5");
	AddMenuItem(menu_editor, "Angle Z+0.5", "Angle Z + 0.5");
	AddMenuItem(menu_editor, "Angle Z-0.5", "Angle Z - 0.5");
	AddMenuItem(menu_editor, "save", "Save");
	
	SetMenuExitButton(menu_editor, true);
}

stock LookupAttachment(client, String:point[])
{
    if(g_hLookupAttachment==INVALID_HANDLE) return 0;
    if( client<=0 || !IsClientInGame(client) ) return 0;
    return SDKCall(g_hLookupAttachment, client, point);
}

public OnMapStart()
{
	for (new i=0; i<g_hats; ++i)
	{
		if(!StrEqual(g_eHats[i][szModel], "none") && strcmp(g_eHats[i][szModel], "")!=0)
		{	
			if(FileExists(g_eHats[i][szModel]))
			{
				PrecacheModel(g_eHats[i][szModel], true);
				Downloader_AddFileToDownloadsTable(g_eHats[i][szModel]);
			}
			else FileExists(g_eHats[i][szModel], true)
			{
				PrecacheModel(g_eHats[i][szModel], true);
			}
		}
	}
}

CreateHat(client)
{	
	if(!IsPlayerAlive(client) || GetClientTeam(client) < 2 || IsFakeClient(client)) return;

	//PrintToChatAll("paso0");
/* 	new bool:second = false;
	if(!LookupAttachment(client, g_eHats[g_Elegido[client]][szAttachment]))
	{
		if(LookupAttachment(client, "forward")) second = true;
		else return;
	} */
	
	//PrintToChatAll("paso1");
	RemoveHat(client);
	if(StrEqual(g_eHats[g_Elegido[client]][szModel], "none")) return;
	
 	if(!StrEqual(g_eHats[g_Elegido[client]][flag], "0") && !HasPermission(client, g_eHats[g_Elegido[client]][flag]))
	{
		g_Elegido[client] = 0;
		return;
	}
	//PrintToChatAll("paso2");
	
	
	// Calculate the final position and angles for the hat
	decl Float:m_fHatOrigin[3];
	decl Float:m_fHatAngles[3];
	decl Float:m_fForward[3];
	decl Float:m_fRight[3];
	decl Float:m_fUp[3];
	GetClientAbsOrigin(client,m_fHatOrigin);
	GetClientAbsAngles(client,m_fHatAngles);
	
	m_fHatAngles[0] += g_eHats[g_Elegido[client]][fAngles][0];
	m_fHatAngles[1] += g_eHats[g_Elegido[client]][fAngles][1];
	m_fHatAngles[2] += g_eHats[g_Elegido[client]][fAngles][2];

	new Float:m_fOffset[3];
	m_fOffset[0] = g_eHats[g_Elegido[client]][fPosition][0];
	m_fOffset[1] = g_eHats[g_Elegido[client]][fPosition][1];
	m_fOffset[2] = g_eHats[g_Elegido[client]][fPosition][2];

	GetAngleVectors(m_fHatAngles, m_fForward, m_fRight, m_fUp);

	m_fHatOrigin[0] += m_fRight[0]*m_fOffset[0]+m_fForward[0]*m_fOffset[1]+m_fUp[0]*m_fOffset[2];
	m_fHatOrigin[1] += m_fRight[1]*m_fOffset[0]+m_fForward[1]*m_fOffset[1]+m_fUp[1]*m_fOffset[2];
	m_fHatOrigin[2] += m_fRight[2]*m_fOffset[0]+m_fForward[2]*m_fOffset[1]+m_fUp[2]*m_fOffset[2];
	
	// Create the hat entity
	new m_iEnt = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(m_iEnt, "model", g_eHats[g_Elegido[client]][szModel]);
	DispatchKeyValue(m_iEnt, "spawnflags", "256");
	DispatchKeyValue(m_iEnt, "solid", "0");
	SetEntPropEnt(m_iEnt, Prop_Send, "m_hOwnerEntity", client);
	
	if(g_eHats[g_Elegido[client]][bBonemerge]) Bonemerge(m_iEnt);

	DispatchSpawn(m_iEnt);	
	AcceptEntityInput(m_iEnt, "TurnOn", m_iEnt, m_iEnt, 0);
	
	// Save the entity index
	g_Hat[client]=EntIndexToEntRef(m_iEnt);
	
	// We don't want the client to see his own hat
	SDKHook(m_iEnt, SDKHook_SetTransmit, ShouldHide);
	
	// Teleport the hat to the right position and attach it
	TeleportEntity(m_iEnt, m_fHatOrigin, m_fHatAngles, NULL_VECTOR); 

	SetVariantString("!activator");
	AcceptEntityInput(m_iEnt, "SetParent", client, m_iEnt, 0);

	SetVariantString(g_eHats[g_Elegido[client]][szAttachment]);
/* 	if(!second) SetVariantString(g_eHats[g_Elegido[client]][szAttachment]);
	else SetVariantString("forward"); */
	AcceptEntityInput(m_iEnt, "SetParentAttachmentMaintainOffset", m_iEnt, m_iEnt, 0);	
}

public Bonemerge(ent)
{
	new m_iEntEffects = GetEntProp(ent, Prop_Send, "m_fEffects"); 
	m_iEntEffects &= ~32;
	m_iEntEffects |= 1;
	m_iEntEffects |= 128;
	SetEntProp(ent, Prop_Send, "m_fEffects", m_iEntEffects); 
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(viendo[client])
	{
		viendo[client] = false;
		SetThirdPersonView(client, false);
	}
	RemoveHat(client);
}

public OnClientCookiesCached(client)
{
	new String:SprayString[12];
	GetClientCookie(client, c_GameSprays, SprayString, sizeof(SprayString));
	g_Elegido[client]  = StringToInt(SprayString);
	if(g_hats <= g_Elegido[client]) g_Elegido[client] = 0;
	
	g_Hat[client] = INVALID_ENT_REFERENCE;
}

public OnClientDisconnect(client)
{
	if(AreClientCookiesCached(client))
	{
		new String:SprayString[12];
		Format(SprayString, sizeof(SprayString), "%i", g_Elegido[client]);
		SetClientCookie(client, c_GameSprays, SprayString);
	}
	RemoveHat(client);
}

public Action:ShouldHide(ent, client)
{
	if(ent == EntRefToEntIndex(g_Hat[client]) && !viendo[client])
		return Plugin_Handled;
		
	if(IsClientInGame(client))
		if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")>=0)
			if(ent == EntRefToEntIndex(g_Hat[GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")]))
				return Plugin_Handled;
	
	return Plugin_Continue;
}

public RemoveHat(client)
{
	new entity = EntRefToEntIndex(g_Hat[client]);
	if(entity != INVALID_ENT_REFERENCE)
	{
		SDKUnhook(entity, SDKHook_SetTransmit, ShouldHide);
		AcceptEntityInput(entity, "Kill");
		g_Hat[client] = INVALID_ENT_REFERENCE;
	}
}

stock SetThirdPersonView(client, bool:third)
{
    if(third)
    {
		if (!g_bThirdPerson)
		{
			return;
		}
		
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		SendConVarValue(client, mp_forcecamera, "1");
    }
    else
    {
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		decl String:valor[6];
		GetConVarString(mp_forcecamera, valor, 6);
		SendConVarValue(client, mp_forcecamera, valor);
    }
}  

public Action:DOMenu(client,args)
{
	if(!StrEqual(g_eHats[g_Elegido[client]][szModel], "none")) ShowMenu(client, 0);
	else CPrintToChat(client, "%t%t", "Tag", "FirstChoose");
	
	return Plugin_Handled;
}

ShowMenu(client, item)
{
	DisplayMenuAtItem(menu_editor, client, item, 0);
	
	viendo[client] = true;
	SetThirdPersonView(client, true);
}

public DIDMenuHandler2(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		new numero;
		new Float:posicion;
		if (StrContains(info, "Position", false) != -1)
		{
			ReplaceString(info, 32, "Position", "", false);
			if (StrContains(info, "X", false) != -1)
			{
				numero = 0;
				ReplaceString(info, 32, "X", "", false);
			}
			else if (StrContains(info, "Y", false) != -1)
			{
				numero = 1;
				ReplaceString(info, 32, "Y", "", false);
			}
			else if (StrContains(info, "Z", false) != -1)
			{
				numero = 2;
				ReplaceString(info, 32, "Z", "", false);
			}
			
			posicion = StringToFloat(info);
			
			g_eHats[g_Elegido[client]][fPosition][numero] += posicion;
			
			CreateHat(client);
			
		}
		else if (StrContains(info, "Angle", false) != -1)
		{
			ReplaceString(info, 32, "Angle", "", false);
			if (StrContains(info, "X", false) != -1)
			{
				numero = 0;
				ReplaceString(info, 32, "X", "", false);
			}
			else if (StrContains(info, "Y", false) != -1)
			{
				numero = 1;
				ReplaceString(info, 32, "Y", "", false);
			}
			else if (StrContains(info, "Z", false) != -1)
			{
				numero = 2;
				ReplaceString(info, 32, "Z", "", false);
			}
			
			posicion = StringToFloat(info);
			
			g_eHats[g_Elegido[client]][fAngles][numero] += posicion;
			
			CreateHat(client);
			
		}
		else if (StrContains(info, "Save", false) != -1)
		{
			KvJumpToKey(kv, g_eHats[g_Elegido[client]][Name])
			new Float:m_fTemp[3];
			m_fTemp[0] = g_eHats[g_Elegido[client]][fPosition][0];
			m_fTemp[1] = g_eHats[g_Elegido[client]][fPosition][1];
			m_fTemp[2] = g_eHats[g_Elegido[client]][fPosition][2];
			KvSetVector(kv, "position", m_fTemp);
			m_fTemp[0] = g_eHats[g_Elegido[client]][fAngles][0];
			m_fTemp[1] = g_eHats[g_Elegido[client]][fAngles][1];
			m_fTemp[2] = g_eHats[g_Elegido[client]][fAngles][2];
			KvSetVector(kv, "angles", m_fTemp);
			KvRewind(kv);
			KeyValuesToFile(kv, sConfig);
			
			CPrintToChat(client, "%t%t", "Tag", "ConfigSaved");
		}
		ShowMenu(client, GetMenuSelectionPosition());
	}
	else if (action == MenuAction_Cancel) 
	{ 
		if(IsClientInGame(client) && viendo[client])
		{
			viendo[client] = false;
			SetThirdPersonView(client, false);
		}
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, itemNum); 
	} 
}

// Just a quick function.
stock bool:HasPermission(iClient, const String:flagString[]) 
{
	if (StrEqual(flagString, "")) 
	{
		return true;
	}
	
	new AdminId:admin = GetUserAdmin(iClient);
	
	if (admin != INVALID_ADMIN_ID)
	{
		new count, found, flags = ReadFlagString(flagString);
		for (new i = 0; i <= 20; i++) 
		{
			if (flags & (1<<i)) 
			{
				count++;
				
				if (GetAdminFlag(admin, AdminFlag:i)) 
				{
					found++;
				}
			}
		}

		if (count == found) {
			return true;
		}
	}

	return false;
} 