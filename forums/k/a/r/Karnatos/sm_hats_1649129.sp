#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <ToggleEffects>

#define PLUGIN_VERSION "1.0.3"
#define MESS "\x04[Hats]\x03 "

enum Hat
{
	String:Name[64],
	String:ModelPath[256],
	Float:Position[3],
	Float:Angles[3],
	String:Flag[2]
}

new Handle:g_hLookupAttachment = INVALID_HANDLE;
new Handle:g_hHats = INVALID_HANDLE;
new Handle:g_hEquippedHat = INVALID_HANDLE;
new Handle:g_hCvarRemove = INVALID_HANDLE;

new bool:g_bToggleEffects = false;

new g_iHats[MAXPLAYERS+1]={0,...};

public Plugin:myinfo =
{
	name = "Hats",
	author = "Zephyrus",
	description = "Hats for everyone, so what?!",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_hats", Command_Hats);
	
	g_hCvarRemove = CreateConVar("sm_hats_remove", "0", "Whether to remove hats on death");
	
	AutoExecConfig();
	
	g_hEquippedHat = RegClientCookie("EquippedHat", "EquippedHat", CookieAccess_Private);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	g_bToggleEffects = LibraryExists("ToggleEffects");
	
	new Handle:hGameConf = LoadGameConfigFile("hats.gamedata");
	StartPrepSDKCall(SDKCall_Entity);
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "LookupAttachment"))
		 LogError("PrepSDKCall_SetFromConf fail");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	if((g_hLookupAttachment = EndPrepSDKCall()) == INVALID_HANDLE)
		LogError("EndPrepSDKCall fail");
}

public OnMapStart()
{
	LoadHats();
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnClientDisconnect(client)
{
	if(g_iHats[client]!=0)
		RemoveHat(client);
}

public OnClientCookiesCached(client)
{
	new String:model[256];
	GetClientCookie(client, g_hEquippedHat, model, sizeof(model));
	if(!ItemExists_Hat(model))
		SetClientCookie(client, g_hEquippedHat, "");
}

stock LookupAttachment(client, String:point[])
{
    if(g_hLookupAttachment==INVALID_HANDLE) {
		LogError("LookupAttachment fail");
	}
    if( client<=0 || !IsClientInGame(client) ) return 0;
    return SDKCall(g_hLookupAttachment, client, point);
}

public LoadHats()
{	
	if(g_hHats!=INVALID_HANDLE)
		CloseHandle(g_hHats);
	g_hHats = CreateArray(328);
	
	new String:sConfig[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfig, PLATFORM_MAX_PATH, "configs/hats.txt");
	
	new Handle:kv = CreateKeyValues("Hats");
	FileToKeyValues(kv, sConfig);
	
	new i = 0;
	new Float:temp[3];
	new eHat[Hat];
	if(KvGotoFirstSubKey(kv))
	{
		do
		{
			ResizeArray(g_hHats, i+1);
			KvGetSectionName(kv, eHat[Name], sizeof(eHat[Name]));
			KvGetString(kv, "model", eHat[ModelPath], sizeof(eHat[ModelPath]));
			KvGetString(kv, "flag", eHat[Flag], sizeof(eHat[Flag]));
			KvGetVector(kv, "position", temp);
			eHat[Position] = temp;
			KvGetVector(kv, "angles", temp);
			eHat[Angles] = temp;
			SetArrayArray(g_hHats, i, eHat[0]);
			
			if(strcmp(eHat[ModelPath], "")!=0 && (FileExists(eHat[ModelPath]) || FileExists(eHat[ModelPath], true))) {
				PrecacheModel(eHat[ModelPath], true);
				AddFileToDownloadsTable(eHat[ModelPath]); // added by Sc0rp!@
			}
			
			++i;
		} while (KvGotoNextKey(kv));
	}
	CloseHandle(kv);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_iHats[client]!=0)
		RemoveHat(client);
		
	CreateTimer(0.0, Timer_SpawnPostPost, client);
	
	return Plugin_Continue;
}

public Action:Timer_SpawnPostPost(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			new String:hat[256];
			GetClientCookie(client, g_hEquippedHat, hat, sizeof(hat));
			if(!StrEqual(hat, ""))
				CreateHat(client);
		}
	}
		
	return Plugin_Stop;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_iHats[client]!=0)
		RemoveHat(client);
	
	return Plugin_Continue;
}

public Action:Command_Hats(client, args)
{
	if(!LookupAttachment(client, "forward"))
	{
		PrintToChat(client, "%sSorry, but the model you are using doesn't support hats.", MESS)
		return Plugin_Handled;
	}
	
	if(!GetClientMenu(client, INVALID_HANDLE)) {
		new Handle:tmpmenu = CreateHatsMenu(client);
		if(tmpmenu == INVALID_HANDLE) {
			LogError("InvalidMenuHandle");
			return Plugin_Handled;
		}
		DisplayMenu(tmpmenu, client, 0);
	}
	
	return Plugin_Handled;
}

public Handle:CreateHatsMenu(client)
{
	new Handle:hMenu = CreateMenu(Handler_Hats);
	SetMenuTitle(hMenu, "Hats Menu");
	
	new String:sCookie[PLATFORM_MAX_PATH];
	GetClientCookie(client, g_hEquippedHat, sCookie, PLATFORM_MAX_PATH);

	new eHat[Hat];
	new String:id[11];
	for(new i=0;i<GetArraySize(g_hHats);++i)
	{
		IntToString(i, id, sizeof(id));
		GetArrayArray(g_hHats, i, eHat[0]);
	
		if(!StrEqual(eHat[Flag], "") && !(GetUserFlagBits(client) & ReadFlagString(eHat[Flag])) && !(GetUserFlagBits(client) & ADMFLAG_ROOT))
			continue;
		
		AddMenuItem(hMenu, id, eHat[Name], (strcmp(eHat[ModelPath], sCookie)==0?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT));
	}
	
	return hMenu;
}

public Handler_Hats(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:id[11];
		GetMenuItem(menu, param2, id, sizeof(id));

		new eHat[Hat];
		GetArrayArray(g_hHats, StringToInt(id), eHat[0]);
		SetClientCookie(client, g_hEquippedHat, eHat[ModelPath]);

		if(IsPlayerAlive(client))
			if(g_iHats[client]!=0)
				RemoveHat(client);
				
		
		if(IsPlayerAlive(client) && strcmp(eHat[ModelPath], "")!=0)
		{
			CreateHat(client);
			PrintToChat(client, "%sYou have successfully equipped the \x04%s\x03 hat.", MESS, eHat[Name]);
		}
	}
	else if ((action == MenuAction_Cancel))
		CloseHandle(menu);
}

CreateHat(client)
{
	if(!LookupAttachment(client, "forward"))
		return;
		
	new eHat[Hat];

	new String:model[256];
	GetClientCookie(client, g_hEquippedHat, model, sizeof(model));
	
	for(new i=0;i<GetArraySize(g_hHats);++i)
	{
		GetArrayArray(g_hHats, i, eHat[0]);
		if(StrEqual(eHat[ModelPath], model))
			break;
	}

	new Float:or[3];
	new Float:ang[3];
	new Float:fForward[3];
	new Float:fRight[3];
	new Float:fUp[3];
	GetClientAbsOrigin(client,or);
	GetClientAbsAngles(client,ang);
	
	ang[0] += eHat[Angles][0];
	ang[1] += eHat[Angles][1];
	ang[2] += eHat[Angles][2];

	new Float:fOffset[3];
	fOffset[0] = eHat[Position][0];
	fOffset[1] = eHat[Position][1];
	fOffset[2] = eHat[Position][2];

	GetAngleVectors(ang, fForward, fRight, fUp);

	or[0] += fRight[0]*fOffset[0]+fForward[0]*fOffset[1]+fUp[0]*fOffset[2];
	or[1] += fRight[1]*fOffset[0]+fForward[1]*fOffset[1]+fUp[1]*fOffset[2];
	or[2] += fRight[2]*fOffset[0]+fForward[2]*fOffset[1]+fUp[2]*fOffset[2];
	
	new ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(ent, "model", model);
	DispatchKeyValue(ent, "spawnflags", "4");
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	DispatchSpawn(ent);	
	AcceptEntityInput(ent, "TurnOn", ent, ent, 0);
	
	g_iHats[client]=ent;
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
	
	TeleportEntity(ent, or, ang, NULL_VECTOR); 
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent, 0);
	
	SetVariantString("forward");
	AcceptEntityInput(ent, "SetParentAttachmentMaintainOffset", ent, ent, 0);
}

RemoveHat(client)
{
	if(IsValidEdict(g_iHats[client]) && g_iHats[client] != 0)
	{
		SDKUnhook(g_iHats[client], SDKHook_SetTransmit, ShouldHide);
		AcceptEntityInput(g_iHats[client], "Kill");
	}
	g_iHats[client]=0;
}

public Action:ShouldHide(ent, client)
{
	if(g_bToggleEffects)
		if(!ShowClientEffects(client))
			return Plugin_Handled;

	if(ent == g_iHats[client])
		return Plugin_Handled;

	if(IsClientInGame(client))
		if(IsValidEdict(client))
			if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4 && GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")>=0)
					if(ent == g_iHats[GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")])
						return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(!GetConVarBool(g_hCvarRemove))
		if(GetClientHealth(victim)-damage<=0)
		{
			if(IsValidEdict(g_iHats[victim]) && g_iHats[victim] != 0)
			{
				new String:sModel[PLATFORM_MAX_PATH];
				GetEntPropString(g_iHats[victim], Prop_Data, "m_ModelName", sModel, PLATFORM_MAX_PATH);
				new Float:fPos[3];
				GetClientEyePosition(victim, fPos);
				
				new ent = CreateEntityByName("prop_physics");
				SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);
				SetEntityModel(ent, sModel);
				DispatchSpawn(ent);
				
				TeleportEntity(ent, fPos, NULL_VECTOR, damageForce);
			}
		}
	return Plugin_Continue;
}

public bool:ItemExists_Hat(const String:data[])
{
	new eHat[Hat];
	for(new i=0;i<GetArraySize(g_hHats);++i)
	{
		GetArrayArray(g_hHats, i, eHat[0]);
		if(strcmp(eHat[ModelPath], data)==0)
			return true;
	}
	return false;
}