#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

#define DEBUG 0

// models with dance animation included
char g_cAnimModel[][] = {
		"models/player/custom_player/legacy/tm_balkan_variantc_ii.mdl"
	};

// default model of fraction (index of array should match appropriate model from g_cAnimModel() array! )
char g_cDefaultModel[][] = {
		"models/player/custom_player/legacy/tm_balkan_variantc.mdl"
	};

char g_cAnimName[][] =	{
		"dance1",
		"rom"
	};

int g_iDanceEnt[MAXPLAYERS+1];
bool g_bLoopAnim[MAXPLAYERS+1];
bool g_bLateload;
bool bRoundStarted;

public Plugin myinfo =
{
	name = "[CSGO] Simple Dance",
	author = "Alex Dragokas",
	description = "Introduces dance animation for players",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

/*
	
	Changelog:
	
	1.0 ( 08-Jun-2019 )
	- First release
	
	Commands:
	
	- sm_dance - Start single animation and show menu
	
	Known issues:
	- double shadow
	- not smooth walking during dance (because I was unable to parent model due to invisiblity state inheritance done by Valve in the latest updates )
	
	TODO:
	- make dance animation for all other fractions or found a way to apply .smd directly to model.
	
	How to add new anim / model?
	 1. add path to original model to g_cAnimModel array
	 2. add path to the model with integrated dance to g_cDefaultModel array (you must prepare/compile model by your own)
	 To add new animation name, append g_cAnimName array.
	 
	Credits:
	
	- Malaxus - for balkan_variantc model with integrated dance animation.
	
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_CSGO) {
		strcopy(error, err_max, "Plugin only supports CS:GO");
		return APLRes_SilentFailure;
	}
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_dance", CmdDanceOnce, "Start single animation and show menu");
	
	HookEvent("player_death", 	Event_PlayerDeath);
	HookEvent("player_hurt", 	Event_PlayerDeath);
	HookEvent("round_start", 	Event_RoundStart, 	EventHookMode_PostNoCopy);
	HookEvent("round_end", 		Event_RoundEnd, 	EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_RoundEnd, 	EventHookMode_PostNoCopy);
	
	if (g_bLateload) {
		bRoundStarted = true;
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i))
				OnClientPutInServer(i);
	}
}

/* =============================================================================
				Events
============================================================================= */

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsValidClient(client))
		StopDance(client);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	bRoundStarted = false;
	StopDanceAll();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	bRoundStarted = true;
	StopDanceAll();
}

public void OnMapStart()
{
	// this is actually not required to enter manually if all your model's file names are identical to .mdl
	AddFileToDownloadsTable("models/player/custom_player/legacy/tm_balkan_variantc_II.dx90.vtx");
	AddFileToDownloadsTable("models/player/custom_player/legacy/tm_balkan_variantc_II.phy");
	
	char s[PLATFORM_MAX_PATH];
	int iDot;
	
	// adding .mdl, .dx90.vtx, .phy, .vvd to download table for your clients
	for (int i = 0; i < sizeof(g_cAnimModel); i++) {
		strcopy(s, sizeof(s), g_cAnimModel[i]);
		AddFileToDownloadsTable(s);
		iDot = strlen(s) - 4;
		strcopy(s[iDot], 16, ".dx90.vtx");
		AddFileToDownloadsTable(s);
		strcopy(s[iDot], 16, ".phy");
		AddFileToDownloadsTable(s);
		strcopy(s[iDot], 16, ".vvd");
		AddFileToDownloadsTable(s);
		
		PrecacheModel(g_cAnimModel[i]);	
	}
}

/* =============================================================================
				Animation
============================================================================= */

public void OnClientPutInServer(int client) 
{
	if(!IsFakeClient(client)) 
	{ 
		//SDKHook(client, SDKHook_PreThink, Hook_PreThink);
		SDKHook(client, SDKHook_PreThinkPost, Hook_PreThink);
		//SDKHook(client, SDKHook_Think, Hook_PreThink);
		//SDKHook(client, SDKHook_PostThink, Hook_PreThink);
		//SDKHook(client, SDKHook_PostThinkPost, Hook_PreThink);
	}
}

/*
public void OnGameFrame()
{
	if (IsServerProcessing())
		for (int i = 1; i <= MaxClients; i++)
			Hook_PreThink(i);
}
*/

public void Hook_PreThink(int client) 
{
	static int iDancer;
	static float vOrigin[3], vAngles[3];
	
	if (bRoundStarted && g_iDanceEnt[client]) {
		iDancer = EntRefToEntIndex(g_iDanceEnt[client]);
		if (iDancer && iDancer != INVALID_ENT_REFERENCE && IsValidEntity(iDancer)) {
			GetClientAbsAngles(client, vAngles);
			GetClientAbsOrigin(client, vOrigin);
			TeleportEntity(iDancer, vOrigin, vAngles, NULL_VECTOR);
		}
	}
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	static int iAllowedButt = IN_BACK | IN_FORWARD | IN_MOVELEFT | IN_MOVERIGHT | IN_JUMP | IN_WALK;
	
	if (iButtons == 0) return Plugin_Continue;
	if (g_iDanceEnt[client] == 0)
		return Plugin_Continue;
	
	if ((iButtons & iAllowedButt) && !(iButtons &~ iAllowedButt)) {
		return Plugin_Continue;
	}
	
	StopDance(client);
	return Plugin_Continue;
}

Action CmdDanceOnce(int client, int args)
{
	char sAnimModel[PLATFORM_MAX_PATH];
	
	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "You must be alive to dance!");
		return Plugin_Handled;
	}
	
	if (client == 0 || !IsClientInGame(client)) {
		ReplyToCommand(client, "Command is only valid in-game!");
		return Plugin_Handled;
	}
	
	// default model to replace
	strcopy(sAnimModel, sizeof(sAnimModel), g_cAnimModel[0]);
	
	char sOrigModel[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", sOrigModel, sizeof(sOrigModel));
	
	for (int i = 0; i < sizeof(g_cDefaultModel); i++) {
		if (StrEqual(sOrigModel, g_cDefaultModel[i], false)) {
			strcopy(sAnimModel, sizeof(sAnimModel), g_cAnimModel[i]);
			break;
		}
	}
	
	int iEntity = CreateEntityByName("prop_dynamic_override"); // or "prop_dynamic_ornament"
	
	if(iEntity < 0) {
		#if DEBUG
			PrintToChat(client, "Failed to create entity: prop_dynamic_ornament");
		#endif
		return Plugin_Handled;
	}
	
	float pos[3];
	GetClientAbsOrigin(client, pos);
	pos[0] += 20.0;
	TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(iEntity, "model", sAnimModel);
	DispatchKeyValue(iEntity, "HoldAnimation", "0");
	DispatchKeyValue(iEntity, "DefaultAnim", g_cAnimName[0]); // or "rom" or "default" // it's idle anim., when base anim is finished
	TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity);
	SetVariantString(g_cAnimName[0]); // first animation (by default)
	AcceptEntityInput(iEntity, "SetAnimation");
	
	// parenting
	//ParentEntity(iEntity, client);
	
	// make invisible and no move
	SetEntityRenderMode(client, RENDER_NONE);
	//SetEntityMoveType(client, MOVETYPE_NONE);
	
	HookSingleEntityOutput(iEntity, "OnAnimationDone", Callback_AnimEnd, true);
	//SetEntityKillTimer(iEntity, 15.0);
	
	g_iDanceEnt[client] = EntIndexToEntRef(iEntity);
	g_bLoopAnim[client] = false;
	
	ShowDanceMenu(client);
	
	#if DEBUG
		PrintToChat(client, "Finished creating the dance: %i", g_iDanceEnt[client]);
	#endif
	return Plugin_Handled;
}

public void Callback_AnimEnd(const char[] output, int caller, int activator, float delay) 
{
	activator = GetDanceActivator(EntIndexToEntRef(caller));
	if (caller > 0 && !g_bLoopAnim[activator])
		StopDance(activator);
	
	#if DEBUG
		PrintToChatAll("Anim is end. Caller: %i, ref: %i", caller, EntIndexToEntRef(caller));
	#endif
}

int GetDanceActivator(int iEntRefDancer)
{
	if (iEntRefDancer == INVALID_ENT_REFERENCE)
		return 0;
	
	for (int i = 1; i <= MaxClients; i++) {
		if (g_iDanceEnt[i] == iEntRefDancer) {
			return i;
		}
	}
	return 0;
}

void StopDance(int client)
{
	if (!g_iDanceEnt[client])
		return;
	
	#if DEBUG
		PrintToChatAll("Stop dance of: %N", client);
	#endif
	
	int iDancer = EntRefToEntIndex(g_iDanceEnt[client]);
	if (iDancer && iDancer != INVALID_ENT_REFERENCE && IsValidEntity(iDancer)) {
		AcceptEntityInput(iDancer, "Kill");
	}
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderMode(client, RENDER_NORMAL);
	g_iDanceEnt[client] = 0;
}

void StopDanceAll()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsValidClient(i))
			StopDance(i);
}

/* =============================================================================
				Menu
============================================================================= */

void ShowDanceMenu(int client)
{
	char sV[64], sI[4];
	Menu menu = new Menu(Handler_MenuDance, MENU_ACTIONS_DEFAULT);
	menu.AddItem("-2", "Stop dance");
	menu.AddItem("-1", "Loop dance");
	
	for (int i = 0; i < sizeof(g_cAnimName); i++) {
		IntToString(i, sI, sizeof(sI));
		Format(sV, sizeof(sV), "Set animation: %s", g_cAnimName[i]);
		menu.AddItem(sI, sV);
	}
	menu.SetTitle("Dancer menu");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_MenuDance(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			int client = param1;
			
			char info[16];
			if(menu.GetItem(param2, info, sizeof(info)))
			{
				int nAlias = StringToInt(info);
				if (nAlias == -2) { // stop
					StopDance(client);
				}
				else {
					// re-launch dance if it ends
					int iDancer = EntRefToEntIndex(g_iDanceEnt[client]);
					if (iDancer == 0 || iDancer == INVALID_ENT_REFERENCE || !IsValidEntity(iDancer)) {
						CmdDanceOnce(client, 0);
					}
					
					if (iDancer && iDancer != INVALID_ENT_REFERENCE && IsValidEntity(iDancer)) {
						if (nAlias == -1) { // loop
							g_bLoopAnim[client] = true;
							PrintToChat(client, "Dance is looped now.");
						}
						else { // new anim
							SetEntPropFloat(iDancer, Prop_Send, "m_flCycle", 1.0);
							SetVariantString(g_cAnimName[nAlias]);
							AcceptEntityInput(iDancer, "SetDefaultAnimation");
							SetVariantString(g_cAnimName[nAlias]);
							AcceptEntityInput(iDancer, "SetAnimation");
						}
					}
					ShowDanceMenu(client);
				}
			}
		}
	}
}

/* =============================================================================
				Helper stocks
============================================================================= */

stock void ParentEntity(int iEntity, int iParent)
{
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetParent", iParent);
	SetVariantString("!activator");
	AcceptEntityInput(iEntity, "SetAttached", iParent);
	
	//parent to attachment point
	/*
	SetVariantString("primary");
	/AcceptEntityInput(iEntity, "SetParentAttachment");
	*/
}

stock void RemoveShadows(int client)
{
	#define EF_NOSHADOW				 (1 << 4)
	#define EF_NORECEIVESHADOW		  (1 << 6)
	
	//seems like no method is work here in csgo
	
	AcceptEntityInput(client, "DisableShadow");
	SetVariantString("disableshadows 1");
	AcceptEntityInput(client, "AddOutput");
	SetVariantString("disablereceiveshadows 1");
	AcceptEntityInput(client, "AddOutput");
	
	DispatchKeyValue(client, "disableshadows", "1");
	DispatchKeyValue(client, "disablereceiveshadows", "1");
	
	SetEntProp(client, Prop_Send, "m_fEffects", GetEntProp(client, Prop_Send, "m_fEffects")|EF_NOSHADOW|EF_NORECEIVESHADOW);
	ChangeEdictState(client, 0);
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

stock void SetEntityKillTimer(int entity, float fTimeout) 
{ 
	char sCmd[32]; 
	Format(sCmd, sizeof(sCmd), "OnUser1 !self:Kill::%f:1", fTimeout); 
	SetVariantString(sCmd); 
	AcceptEntityInput(entity, "AddOutput"); 
	AcceptEntityInput(entity, "FireUser1"); 
}

stock bool IsValidClient(int client)
{ 
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client)) 
		return false; 
	
	return true; 
}  