#include <sourcemod>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1

new PropCount[MAXPLAYERS+1];
new Movementtoggle[MAXPLAYERS+1];

new Handle:hRemoveProps;
new Handle:public_prop_menu = INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "tProps",
	author = "Totenfluch",
	description = "spawn props in game at aim point",
	version = "1.h5",
	url = "http://www.sourcemod.net"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	RegAdminCmd("sm_props", PropCommand, ADMFLAG_GENERIC, "opens the main prop menu");
	RegAdminCmd("sm_propstoggle", PropCommandToggle, ADMFLAG_GENERIC, "toggles between psy and static props");
	RegAdminCmd("sm_propsrm", PropCommandRM, ADMFLAG_GENERIC, "Removes prop aimed at");
	RegAdminCmd("sm_propsrmall", PropCommandRMAll, ADMFLAG_GENERIC, "Removes all player props");
	RegAdminCmd("sm_propsrmroot", RMAllPluginProps, ADMFLAG_ROOT, "Removes all props made by plugin");

	hRemoveProps = CreateConVar("prop_removeondeath", "1", "0 is keep the props on death, 1 is remove them on death. Default: 1");
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
		{ OnAdminMenuReady(topmenu); }
}
public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
		hAdminMenu = INVALID_HANDLE;
}
public CategoryHandler(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,
			param,String:buffer[],maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
		Format(buffer, maxlength, "tProps");
	else if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "tProps");
}
 
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hAdminMenu)
		return;
	hAdminMenu = topmenu;
	new TopMenuObject:obj_tPropsMenu = AddToTopMenu(hAdminMenu,
		"tProps",TopMenuObject_Category,CategoryHandler,INVALID_TOPMENUOBJECT);
	
	AddToTopMenu(hAdminMenu, "item1", TopMenuObject_Item, ItemHandler, obj_tPropsMenu, "sm_props");
	AddToTopMenu(hAdminMenu, "item2", TopMenuObject_Item, ItemHandler, obj_tPropsMenu, "sm_propstoggle");
	AddToTopMenu(hAdminMenu, "item3", TopMenuObject_Item, ItemHandler, obj_tPropsMenu, "sm_propsrm");
	AddToTopMenu(hAdminMenu, "item4", TopMenuObject_Item, ItemHandler, obj_tPropsMenu, "sm_propsrmall");
	AddToTopMenu(hAdminMenu, "item5", TopMenuObject_Item, ItemHandler, obj_tPropsMenu, "sm_propsrmroot");
}

public ItemHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id,
			param, String:buffer[], maxlength)
{
	new String:obj_str[64]; GetTopMenuObjName(topmenu, object_id, obj_str, sizeof(obj_str));
	
	if (action == TopMenuAction_DisplayOption)
	{
		if (StrEqual(obj_str, "item1")) { Format(buffer, maxlength, "Props Spawn Menu"); }
		if (StrEqual(obj_str, "item2")) {
			if (Movementtoggle[param]) { Format(buffer, maxlength, "Toggle to PHYSICS props"); }
			else { Format(buffer, maxlength, "Toggle to STATIC props"); }
		}
		if (StrEqual(obj_str, "item3")) { Format(buffer, maxlength, "remove prop aimed at"); }
		if (StrEqual(obj_str, "item4")) { Format(buffer, maxlength, "remove your %d props", PropCount[param]); }
		if (StrEqual(obj_str, "item5")) { Format(buffer, maxlength, "remove ALL Plugins props"); }
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (StrEqual(obj_str, "item1")) { PropCommand(param, param); return; }
		if (StrEqual(obj_str, "item2")) { PropCommandToggle(param, param); }
		if (StrEqual(obj_str, "item3")) { PropCommandRM(param, param); }
		if (StrEqual(obj_str, "item4")) { PropCommandRMAll(param, param); }
		if (StrEqual(obj_str, "item5")) { RMAllPluginProps(param, param); }
		RedisplayAdminMenu(Handle:hAdminMenu,param);
	}
}

public OnClientPostAdminCheck(client){
	if(!IsFakeClient(client) && CheckCommandAccess(client, "override_string", ADMFLAG_GENERIC))
		Movementtoggle[client] = 1;
}

public Event_PlayerDeath(Handle: event , const String: name[] , bool: dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!Client_IsValid(attacker))
		return;
	
	if(GetConVarInt(hRemoveProps))
		KillProps(victim);
}
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1; i<=MaxClients; i++) {
		if(IsClientConnected(i) && !IsFakeClient(i) && PropCount[i] > 0)
			PropCount[i] = 0;
	}
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); KillProps(client);
}

public Action:PropCommand(client, args)
{	
	if (client) {
		new String:textPath[255];
		BuildPath(Path_SM, textPath, sizeof(textPath), "data/propslist.txt");
		new Handle:kv = CreateKeyValues("Props");
		FileToKeyValues(kv, textPath);
		public_prop_menu = CreateMenu(Public_Prop_Menu_Handler);
		SetMenuTitle(public_prop_menu, "propSpawn Menu");
		PopLoop(kv); DisplayMenu(public_prop_menu, client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public Public_Prop_Menu_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		PropSpawn(param1, param2); new String:textPath[255];
		BuildPath(Path_SM, textPath, sizeof(textPath), "data/propslist.txt");
		new Handle:kv = CreateKeyValues("Props"); FileToKeyValues(kv, textPath);
		public_prop_menu = CreateMenu(Public_Prop_Menu_Handler);
		SetMenuTitle(public_prop_menu, "propSpawn Menu");
		PopLoop(kv); DisplayMenu(public_prop_menu, param1, MENU_TIME_FOREVER);
	}
}

PopLoop(Handle:kv)
{
	if (KvGotoFirstSubKey(kv)) {
		do {
			new String:buffer[256];
			KvGetSectionName(kv, buffer, sizeof(buffer));
			AddMenuItem(public_prop_menu, buffer, buffer);
		}
		while (KvGotoNextKey(kv));
		CloseHandle(kv);
	}
}

public PropSpawn(client, param2)
{
	new String:prop_choice[255];
	
	GetMenuItem(public_prop_menu, param2, prop_choice, sizeof(prop_choice));
	
	new String:name[255]; GetClientName(client, name, sizeof(name));
	
	decl String:modelname[255]; new String:file[255];
	BuildPath(Path_SM, file, 255, "data/propslist.txt");
	new Handle:kv = CreateKeyValues("Props");
	FileToKeyValues(kv, file); KvJumpToKey(kv, prop_choice);
	KvGetString(kv, "model", modelname, sizeof(modelname),"");
	
	decl Ent; PrecacheModel(modelname,true);
	Ent = CreateEntityByName("prop_physics_override"); 
	
	new String:EntName[256];
	Format(EntName, sizeof(EntName), "tPropSpawn%d_n%d", client, PropCount[client]);
	
	DispatchKeyValue(Ent, "physdamagescale", "0.0");
	DispatchKeyValue(Ent, "model", modelname);
	DispatchKeyValue(Ent, "targetname", EntName);
	
	if (StrContains(modelname, "barrel") > -1) {
		DispatchKeyValue(Ent, "spawnflags", "48");
		DispatchKeyValue(Ent, "health", "40"); DispatchKeyValue(Ent, "minhealthdmg", "2");
		DispatchKeyValue(Ent, "ExplodeRadius", "800"); DispatchKeyValue(Ent, "ExplodeDamage", "25");
    }
	
	DispatchSpawn(Ent);
	
	decl Float:viewpos[3]; viewpos = GetViewPoint(client);
	
	decl Float:propang[3], Float:clientang[3];
	GetClientEyeAngles(client, clientang);
	propang[1] = clientang[1] + 90;

	TeleportEntity(Ent, viewpos, propang, NULL_VECTOR);
	
	if (Movementtoggle[client] == 0) { SetEntityMoveType(Ent, MOVETYPE_VPHYSICS); }
	else { SetEntityMoveType(Ent, MOVETYPE_PUSH); }
	
	if(viewpos[0] == 0.0 && viewpos[1] == 0.0 && viewpos[2] == 0.0){
		new prop = Entity_FindByName(EntName);
		AcceptEntityInput(prop, "kill");
	}
	else{ PrintToChat(client, "[SM] You spawned \x05%s", prop_choice); }
	CloseHandle(kv); PropCount[client] += 1; return;
}

Float:GetViewPoint(client)
{
	decl Float:start[3], Float:angle[3], Float:end[3];
	GetClientEyePosition(client, start);
	GetClientEyeAngles(client, angle);
	TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
	if (TR_DidHit(INVALID_HANDLE))
		{ TR_GetEndPosition(end, INVALID_HANDLE); return end; }
	else {
		PrintToChat(client, "[SM] Could not spawn prop at that view positon!");
		end[0] = 0.0; end[1] = 0.0; end[2] = 0.0; return end;
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)  
{ 
	return entity > MaxClients;
}  

public Action:PropCommandRM(client, args)
{
	if(client){
		new prop = GetClientAimTarget(client, false);
		if (prop == -1)
			return Plugin_Handled;
			
		new String:EntName[256];
		Entity_GetName(prop, EntName, sizeof(EntName));
		
		new validProp = StrContains(EntName, "tPropSpawn");
		if(validProp > -1) {
			new String:tempInd[3];
			tempInd[0] = EntName[15];
			tempInd[1] = EntName[16];
			tempInd[2] = EntName[17];
		
			ReplaceString(tempInd, sizeof(tempInd), "_", "");
			new clientIndex = StringToInt(tempInd);
			AcceptEntityInput(prop, "kill");
			PropCount[clientIndex] = PropCount[clientIndex] - 1;
			PrintToChat(client, "[SM] Removed the prop you were aiming at.");
		}
	}
	return Plugin_Handled;
}

public Action:PropCommandRMAll(client, args)
{
	if(client) { KillProps(client); }
	return Plugin_Handled;
}

public Action:PropCommandToggle(client, args)
{	
	if(client){
		if(Movementtoggle[client]){
			Movementtoggle[client] = 0;
			PrintToChat(client, "*** You will now spawn \x05physics\x01 props.");
		}
		else {
			Movementtoggle[client] = 1;
			PrintToChat(client, "*** You will now spawn \x05static\x01 Props.");
		}
	}
	return Plugin_Handled;
}

stock KillProps(client)
{
	for(new i=0; i<=PropCount[client]; i++) {
		new String:EntName[MAX_NAME_LENGTH+5];
		Format(EntName, sizeof(EntName), "tPropSpawn%d_n%d", client, i);
		new prop = Entity_FindByName(EntName);
		if(prop != -1)
			AcceptEntityInput(prop, "kill");
	}
	PropCount[client] = 0;
}

public Action:RMAllPluginProps(client, args)
{
	new maxent = GetMaxEntities(); decl String:sClassName[64];
	for (new i=MaxClients; i < maxent; i++) {
		if (IsValidEntity(i) && GetEntityClassname(i, sClassName, sizeof(sClassName))) {
			if (StrEqual(sClassName, "prop_physics")) {
				new String:EntName[256]; Entity_GetName(i, EntName, sizeof(EntName));
				if(StrContains(EntName, "tPropSpawn") > -1)
					AcceptEntityInput(i, "kill");
			}
		}
	}
	for(new i=1; i<=MaxClients; i++) {
		if(IsClientConnected(i) && !IsFakeClient(i) && PropCount[i] > 0)
			PropCount[i] = 0;
	}
	decl String:nick[64]; GetClientName(client, nick, sizeof(nick));
	PrintToChatAll("[SM] %s removed all plugin props.", nick); return Plugin_Handled;
}