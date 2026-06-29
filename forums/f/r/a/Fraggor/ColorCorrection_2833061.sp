#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>
#include <dhooks>
//#tryinclude <intmap>
#if !defined _intmap_included
#include <pseudo-intmap>
#endif

//#define DEBUG
//#define USE_OnEntitySpawned

IntMap2 g_Queue = null;
IntMap2 g_FlaggedClient = null;
IntMap2 g_BackupCurWeight = null;

Menu g_hMenu_Settings = null;
Cookie g_hStatusCookie;
bool g_bClientDisableCC[MAXPLAYERS + 1] = {false, ...};

bool g_bEnabled;

DynamicHook g_hAcceptInput = null;

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name = "Color Correction Controller",
	author = "PŠΣ™ SHUFEN",
	description = "",
	version = "0.3",
	url = "https://possession.jp"
};

public void OnPluginStart()
{
	//======== Array ========//
	g_Queue = new IntMap2();
	g_FlaggedClient = new IntMap2();
	g_BackupCurWeight = new IntMap2();

	//======== Commands ========//
	RegConsoleCmd("sm_cc", Command_ToggleColorCorrection);
	RegConsoleCmd("sm_colorcorrection", Command_ToggleColorCorrection);
	RegConsoleCmd("sm_scxz", Command_ToggleColorCorrection);
	RegConsoleCmd("sm_secaixiuzheng", Command_ToggleColorCorrection);

	//======== CVAR ========//
	ConVar cvar;
	cvar = CreateConVar("sm_cc_enable", "1", "Enable/Disable the feature", _, true, 0.0, true, 1.0);
	cvar.AddChangeHook(OnConVarChange);
	g_bEnabled = cvar.BoolValue;
	delete cvar;

	//======== Cookie ========//
	g_hStatusCookie = new Cookie("sm_cc", "Color Correction Controller", CookieAccess_Protected);

	//======== Menu ========//
	BuildControllerMenu();
	SetCookieMenuItem(PrefMenu, 0, "Color Correction");

	//======== DHook ========//
	char tmpOffset[148] = "sdktools.games\\engine.csgo";
	GameData temp = new GameData(tmpOffset);
	if (temp == null) {
		SetFailState("Why you no has gamedata?");
	}
	else {
		int offset = temp.GetOffset("AcceptInput");
		g_hAcceptInput = new DynamicHook(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
		g_hAcceptInput.AddParam(HookParamType_CharPtr);
		g_hAcceptInput.AddParam(HookParamType_CBaseEntity);
		g_hAcceptInput.AddParam(HookParamType_CBaseEntity);
		g_hAcceptInput.AddParam(HookParamType_Object, 20);
		g_hAcceptInput.AddParam(HookParamType_Int);
	}
	delete temp;

	HookEvent("round_prestart", Event_RoundChange);

	//======== Translation ========//
	LoadTranslations("ColorCorrection.phrases");

	//======== Init ========//
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
			if (AreClientCookiesCached(i) && !IsFakeClient(i)) {
				OnClientCookiesCached(i);
			}
		}
	}

	int entity = INVALID_ENT_REFERENCE;
	#if defined USE_OnEntitySpawned
	while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE) {
	#else
	while ((entity = FindEntityByClassname(entity, "color_correction")) != INVALID_ENT_REFERENCE) {
	#endif
		#if defined USE_OnEntitySpawned
		char sClassname[64];
		if (GetEntityClassname(entity, sClassname, sizeof(sClassname))) {
			OnEntitySpawned(entity, sClassname);
		}
		#else
		OnEntitySpawn_Post(entity);
		#endif
	}
}

public void OnConVarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = view_as<bool>(StringToInt(newValue));
}

//----------------------------------------------------------------------------------------------------
// Purpose: Settings
//----------------------------------------------------------------------------------------------------
public void OnClientPutInServer(int client)
{
	g_bClientDisableCC[client] = false;
}

public void OnClientCookiesCached(int client)
{
	char buffer[4];
	g_hStatusCookie.Get(client, buffer, sizeof(buffer));

	if (buffer[0] != '\0') {
		g_bClientDisableCC[client] = !!StringToInt(buffer);
	}
}

public void OnClientDisconnect(int client)
{
	#if defined _pseudo_intmap
	g_Queue.Iterate(StopChangeForEachCell, client);
	#else
	g_Queue.IterateCells(StopChangeForEachCell, client);
	#endif
}

public Action Command_ToggleColorCorrection(int client, int args)
{
	if (!g_bEnabled) {
		PrintToChat(client, " \x04%t \x01%t", "prefix", "Plugin Disabled");
		return Plugin_Handled;
	}
	DisplayControllerMenu(client);
	return Plugin_Handled;
}

public void PrefMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen)
{
	if (actions == CookieMenuAction_DisplayOption) {
		FormatEx(buffer, maxlen, "%T", "ColorCorrection", client);
	}

	if (actions == CookieMenuAction_SelectOption) {
		DisplayControllerMenu(client);
	}
}

void BuildControllerMenu()
{
	if (g_hMenu_Settings != null) {
		delete g_hMenu_Settings;
	}
	g_hMenu_Settings = new Menu(ControllerMenu_Handler, MenuAction_Select | MenuAction_Display | MenuAction_DisplayItem);
	g_hMenu_Settings.AddItem("ToggleColorCorrection", "");
	g_hMenu_Settings.ExitBackButton = true;
}

void DisplayControllerMenu(int client)
{
	g_hMenu_Settings.Display(client, 0);
}

public int ControllerMenu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	switch (action) {
		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack) {
				ShowCookieMenu(client);
			}
		}
		case MenuAction_Display: {
			char buffer[255];
			Format(buffer, sizeof(buffer), "%T", "ControllerMenu Title", client);
			view_as<Panel>(param2).SetTitle(buffer);
		}
		case MenuAction_DisplayItem: {
			char ItemName[PLATFORM_MAX_PATH], buffer[255];
			menu.GetItem(param2, ItemName, PLATFORM_MAX_PATH);
			if (StrEqual(ItemName, "ToggleColorCorrection", false)) {
				Format(buffer, sizeof(buffer), "%T: %T", "Block Color Correction", client, g_bClientDisableCC[client] ? "Enabled" : "Disabled", client);
			}
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Select: {
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info,"ToggleColorCorrection")) {
				ToggleColorCorrection(client);
				DisplayControllerMenu(client);
			}
		}
	}
	return 0;
}

void ToggleColorCorrection(int client)
{
	if (!g_bClientDisableCC[client]) {
		PrintToChat(client, " \x04%t \x01%t: \x05%t", "prefix", "Block Color Correction", "Enabled");
	}
	else {
		PrintToChat(client, " \x04%t \x01%t: \x05%t", "prefix", "Block Color Correction", "Disabled");
	}
	g_bClientDisableCC[client] = !g_bClientDisableCC[client];

	char sCookieValue[4];
	FormatEx(sCookieValue, sizeof(sCookieValue), "%i", g_bClientDisableCC[client]);
	g_hStatusCookie.Set(client, sCookieValue);

	#if defined _pseudo_intmap
	g_Queue.Iterate(ReflectChangeForEachCell, client);
	#else
	g_Queue.IterateCells(ReflectChangeForEachCell, client);
	#endif
}

//----------------------------------------------------------------------------------------------------
// Purpose: Entities
//----------------------------------------------------------------------------------------------------
public void Event_RoundChange(Event event, const char[] name, bool dontBroadcast)
{
	#if defined _pseudo_intmap
	g_Queue.Clear();
	g_FlaggedClient.Clear();
	g_BackupCurWeight.Clear();
	#else
	g_Queue.ClearCells();
	g_FlaggedClient.ClearCells();
	g_BackupCurWeight.ClearCells();
	#endif
}

#if !defined USE_OnEntitySpawned
public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > MaxClients && entity < 2048) {
		if (classname[0] == 'c' && classname[1] == 'o' && classname[5] == '_' && classname[6] == 'c') {
			SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawn_Post);
		}
	}
}
#endif

#if defined USE_OnEntitySpawned
public void OnEntitySpawned(int entity, const char[] classname)
#else
public void OnEntitySpawn_Post(int entity)
#endif
{
	if (!g_bEnabled) {
		return;
	}

	#if defined USE_OnEntitySpawned
	if (entity > MaxClients && entity < 2048) {
		if (classname[0] == 'c' && classname[1] == 'o' && classname[5] == '_' && classname[6] == 'c') {
	#else
	{
	#endif
			SetEdictFlags(entity, GetEdictFlags(entity) & ~FL_EDICT_ALWAYS);
			SDKHook(entity, SDKHook_SetTransmit, CC_SetTransmit);

			bool bEnabled = !!GetEntProp(entity, Prop_Send, "m_bEnabled");

			#if defined DEBUG
			char EntityName[64];
			GetEntPropString(entity, Prop_Data, "m_iName", EntityName, sizeof(EntityName));
			PrintToConsoleAll("ColorCorrection[EntityName]: %s", EntityName);
			PrintToConsoleAll("ColorCorrection[Index]: %d", entity);
			PrintToConsoleAll("ColorCorrection[Master]: %d", GetEntProp(entity, Prop_Send, "m_bMaster"));
			PrintToConsoleAll("ColorCorrection[ClientSide]: %d", GetEntProp(entity, Prop_Send, "m_bClientSide"));
			PrintToConsoleAll("ColorCorrection[StartEnable]: %d", bEnabled);
			PrintToConsoleAll("---");
			#endif

			g_Queue.SetValue(entity, bEnabled);
			g_FlaggedClient.SetValue(entity, 0);
			g_BackupCurWeight.SetValue(entity, 0.0);

			g_hAcceptInput.HookEntity(Hook_Pre, entity, AcceptInput);
	#if defined USE_OnEntitySpawned
		}
	}
	#else
	}
	#endif
}

public void OnEntityDestroyed(int entity)
{
	if (!g_bEnabled) {
		return;
	}

	if (entity == -1) {
		return;
	}

	int _entity = EntIndexToEntRef(EntRefToEntIndex(entity));
	if (_entity < 0 || _entity >= 2048) {
		return;
	}

	#if defined _pseudo_intmap
	g_Queue.Remove(_entity);
	g_FlaggedClient.Remove(_entity);
	g_BackupCurWeight.Remove(_entity);
	#else
	g_Queue.RemoveCell(_entity);
	g_FlaggedClient.RemoveCell(_entity);
	g_BackupCurWeight.RemoveCell(_entity);
	#endif
}

#if defined DEBUG
float last_weight[2048];
#endif
public Action CC_SetTransmit(int entity, int client)
{
	SetEdictFlags(entity, GetEdictFlags(entity) & ~FL_EDICT_ALWAYS);

	#if defined DEBUG
	if (last_weight[entity] != GetEntPropFloat(entity, Prop_Send, "m_flCurWeight")) {
		last_weight[entity] = GetEntPropFloat(entity, Prop_Send, "m_flCurWeight");
		PrintToChat(client, "ColorCorrection[LastWeight]: %f", last_weight[entity]);
	}
	#endif

	static int queue;
	queue = g_FlaggedClient.GetValue(entity);

	static float weight;

	if (queue == client) {
		bool disable = g_bClientDisableCC[client];

		RequestFrame(Frame_RevertEdictState, EntIndexToEntRef(entity));

		SetEdictFlags(entity, GetEdictFlags(entity) | FL_EDICT_DONTSEND);

		weight = GetEntPropFloat(entity, Prop_Send, "m_flCurWeight");
		g_BackupCurWeight.SetValue(entity, weight);
		SetEntPropFloat(entity, Prop_Send, "m_flCurWeight", disable ? 0.0 : weight);
		ChangeEdictState(entity, GetEntSendPropOffs(entity, "m_flCurWeight", true));

		SetEntProp(entity, Prop_Send, "m_bEnabled", !disable ? (!!g_Queue.GetValue(entity)) ? true : false : false);
		ChangeEdictState(entity, GetEntSendPropOffs(entity, "m_bEnabled", true));

		return Plugin_Continue;
	}

	return g_bClientDisableCC[client] ? Plugin_Handled : Plugin_Continue;
}

void Frame_RevertEdictState(int ref)
{
	if (!IsValidEntity(ref)) {
		return;
	}

	int entity = EntRefToEntIndex(ref);

	SetEntProp(entity, Prop_Send, "m_bEnabled", (!!g_Queue.GetValue(entity)) ? true : false);
	ChangeEdictState(entity, GetEntSendPropOffs(entity, "m_bEnabled", true));

	SetEntPropFloat(entity, Prop_Send, "m_flCurWeight", g_BackupCurWeight.GetValue(entity));
	ChangeEdictState(entity, GetEntSendPropOffs(entity, "m_flCurWeight", true));

	SetEdictFlags(entity, GetEdictFlags(entity) & ~FL_EDICT_ALWAYS & ~FL_EDICT_DONTSEND);

	g_FlaggedClient.SetValue(entity, 0);
}

#if defined _pseudo_intmap
public Action ReflectChangeForEachCell(IntMap2 map, int index, int key, int client)
#else
public Action ReflectChangeForEachCell(IntMap map, int key, any value, int client)
#endif
{
	if (IsValidEntity(key) && IsClientInGame(client)) {
		#if defined _pseudo_intmap
		if (g_FlaggedClient.GetValue(key) != 0 && g_FlaggedClient.GetValue(key) != client)
		#else
		if (value != 0 && value != client)
		#endif
		{
			RequestFrame(Frame_RetryAddQueue, ((key << 7) | client));
			return Plugin_Continue;
		}

		g_FlaggedClient.SetValue(key, client);
	}
	return Plugin_Continue;
}

void Frame_RetryAddQueue(int data)
{
	int entity = (data >> 7);
	int client = (data & 0x7F);

	if (IsValidEntity(entity) && IsClientInGame(client)) {
		if (g_FlaggedClient.GetValue(entity) != 0 && g_FlaggedClient.GetValue(entity) != client) {
			RequestFrame(Frame_RetryAddQueue, data);
			return;
		}

		g_FlaggedClient.SetValue(entity, client);
	}
}

#if defined _pseudo_intmap
public Action StopChangeForEachCell(IntMap2 map, int index, int key, int client)
#else
public Action StopChangeForEachCell(IntMap map, int key, any value, int client)
#endif
{
	#if defined _pseudo_intmap
	if (g_FlaggedClient.GetValue(key) == client)
	#else
	if (value == client)
	#endif
	{
		g_FlaggedClient.SetValue(key, 0);
	}
	return Plugin_Continue;
}

public MRESReturn AcceptInput(int entity, DHookReturn hReturn, DHookParam hParams)
{
	if (!IsValidEntity(entity)) {
		return MRES_Ignored;
	}

	if (g_FlaggedClient.GetValue(entity) != 0) {
		return MRES_Ignored;
	}

	char eCommand[16];
	hParams.GetString(1, eCommand, 16);

	if (StrEqual(eCommand, "Enable", false)) {
		g_Queue.SetValue(entity, true);
	}
	else if (StrEqual(eCommand, "Disable", false)) {
		g_Queue.SetValue(entity, false);
	}
	return MRES_Ignored;
}