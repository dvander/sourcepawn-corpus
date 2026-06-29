#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <knife_plugin>
#include <lastrequest>

#define MAX_PAINTS 800

enum Listado
{
	String:Nombre[64],
	index,
	Float:wear,
	stattrak,
	quality
}

new Handle:c_Game = INVALID_HANDLE;
new paintselected[MAXPLAYERS+1];

new Handle:menuw = INVALID_HANDLE;
new g_paints[MAX_PAINTS][Listado];
new g_paintCount = 0;
new String:path_paints[PLATFORM_MAX_PATH];

new bool:g_knife = false;
new bool:g_hosties = false;

new bool:g_c4;
new Handle:cvar_c4;

#define DATA "1.5.2"

public Plugin:myinfo =
{
	name = "SM CS:GO Weapon Paints",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://www.zeuszombie.com"
};

public OnPluginStart()
{
	c_Game = RegClientCookie("Paints_stable", "Paints_stable", CookieAccess_Private);
	
	CreateConVar("sm_wpaints_version", DATA, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	RegAdminCmd("sm_wskins", GetSkins, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_ws", GetSkins, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_paints", GetSkins, ADMFLAG_RESERVATION);
	RegAdminCmd("buyammo1", GetSkins, ADMFLAG_RESERVATION);
	
	RegAdminCmd("sm_reloadwskins", ReloadSkins, ADMFLAG_ROOT);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
			
		OnClientPutInServer(client);
	}
	
	cvar_c4 = CreateConVar("sm_weaponpaints_c4", "1", "Enable or disable that people can apply paints to the C4. 1 = enabled, 0 = disabled");
	
	g_c4 = GetConVarBool(cvar_c4);
	
	HookConVarChange(cvar_c4, OnConVarChanged);
	
	ReadPaints();
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_c4)
	{
		g_c4 = bool:StringToInt(newValue);
	}
}

public OnPluginEnd()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}

public OnClientCookiesCached(client)
{
	new String:SString[12];
	GetClientCookie(client, c_Game, SString, sizeof(SString));
	paintselected[client]  = StringToInt(SString);
}

public OnClientDisconnect(client)
{
	if(AreClientCookiesCached(client))
	{
		new String:SString[12];
		Format(SString, sizeof(SString), "%i", paintselected[client]);
		SetClientCookie(client, c_Game, SString);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("K_GetKnife"); 
	MarkNativeAsOptional("IsClientInLastRequest");

	return APLRes_Success;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "knife_plugin"))
	{
		g_knife = true;
	}
	else if (StrEqual(name, "hosties"))
	{
		g_hosties = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "knife_plugin"))
	{
		g_knife = false;
	}
	else if (StrEqual(name, "hosties"))
	{
		g_hosties = false;
	}
}

public Action:ReloadSkins(client, args)
{	
	ReadPaints();
	ReplyToCommand(client, " \x04[WP]\x01 Weapon paints reloaded");
	
	return Plugin_Handled;
}

public Action:GetSkins(client, args)
{	
	DisplayMenu(menuw, client, 0);
	
	return Plugin_Handled;
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
	
		if(!IsPlayerAlive(client))
		{
			PrintToChat(client, " \x04[WP]\x01 You cant use this when you are dead");
			//GetSkins(client, 0);
			return;
		}
		if(g_hosties && IsClientInLastRequest(client))
		{
			PrintToChat(client, " \x04[WP]\x01 You cant use this when you are in a lastrequest");
			//GetSkins(client, 0);
			return;
		}
		
		decl String:info[4];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		new theindex = StringToInt(info);
		
		new windex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(windex < 1)
		{
			PrintToChat(client, " \x04[WP]\x01 You cant use a paint in this weapon");
			//GetSkins(client, 0);
			return;
		}
		
		decl String:Classname[64];
		GetEdictClassname(windex, Classname, 64);
		
		if(StrEqual(Classname, "weapon_taser"))
		{
			PrintToChat(client, " \x04[WP]\x01 You cant use a paint in this weapon");
			//GetSkins(client, 0);
			return;
		}
		if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == windex || GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == windex || GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == windex || (g_c4 && GetPlayerWeaponSlot(client, CS_SLOT_C4) == windex))
		{
			paintselected[client] = theindex;
			
			if(theindex == -1)
			{
				theindex = GetRandomInt(1, g_paintCount-1);
			}
			ChangePaint(client, windex, Classname, theindex);
			FakeClientCommand(client, "use %s", Classname);
			if(theindex == 0) PrintToChat(client, " \x04[WP]\x01 You have choose\x03 your default paint");
			else PrintToChat(client, " \x04[WP]\x01 You have choose\x03 %s", g_paints[theindex][Nombre]);
		}
		else PrintToChat(client, " \x04[WP]\x01 You cant use a paint in this weapon");
		
		//GetSkins(client, 0);
		
	}
}

public Action:RestoreItemID(Handle:timer, Handle:pack)
{
    new entity;
    new m_iItemIDHigh;
    new m_iItemIDLow;
    
    ResetPack(pack);
    entity = EntRefToEntIndex(ReadPackCell(pack));
    m_iItemIDHigh = ReadPackCell(pack);
    m_iItemIDLow = ReadPackCell(pack);
    
    if(entity != INVALID_ENT_REFERENCE)
	{
		SetEntProp(entity,Prop_Send,"m_iItemIDHigh",m_iItemIDHigh);
		SetEntProp(entity,Prop_Send,"m_iItemIDLow",m_iItemIDLow);
	}
}

ReadPaints()
{
	BuildPath(Path_SM, path_paints, sizeof(path_paints), "configs/csgo_wpaints.cfg");
	
	decl Handle:kv;
	g_paintCount = 1;

	kv = CreateKeyValues("Paints");
	FileToKeyValues(kv, path_paints);

	if (!KvGotoFirstSubKey(kv)) {

		SetFailState("CFG File not found: %s", path_paints);
		CloseHandle(kv);
	}
	do {

		KvGetSectionName(kv, g_paints[g_paintCount][Nombre], 64);
		g_paints[g_paintCount][index] = KvGetNum(kv, "paint", 0);
		g_paints[g_paintCount][wear] = KvGetFloat(kv, "wear", -1.0);
		g_paints[g_paintCount][stattrak] = KvGetNum(kv, "stattrak", -2);
		g_paints[g_paintCount][quality] = KvGetNum(kv, "quality", -2);

		g_paintCount++;
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
	
	if(menuw != INVALID_HANDLE) CloseHandle(menuw);
	menuw = INVALID_HANDLE;
	
	menuw = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menuw, "Choose your Weapon Paint");
	decl String:item[4];
	AddMenuItem(menuw, "-1", "Random paint");
	AddMenuItem(menuw, "0", "Default paint");
	for (new i=1; i<g_paintCount; ++i) {
		Format(item, 4, "%i", i);
		AddMenuItem(menuw, item, g_paints[i][Nombre]);
	}
	SetMenuExitButton(menuw, true);
}

stock GetReserveAmmo(client, weapon)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return -1;
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

stock SetReserveAmmo(client, weapon, ammo)
{
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return;
    
    SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
} 

ChangePaint(client, windex, String:Classname[64], theindex)
{
	new bool:knife = false;
	new c_knife;
	if(StrContains(Classname, "weapon_knife", false) == 0) 
	{
		
		if(g_knife) c_knife = K_GetKnife(client);
		else c_knife = 0;
		
		knife = true;
	}
	
	//PrintToChat(client, "valor es %i", GetEntProp(windex, Prop_Send, "m_weaponMode"));
	if(StrContains(Classname, "weapon_m4a1", false) == 0 && GetEntProp(windex, Prop_Send, "m_bSilencerOn") == 1)
	{
		Format(Classname, 64, "weapon_m4a1_silencer");
	}
	
	//PrintToChat(client, "weapon %s", Classname);
	new ammo, clip;
	if(!knife)
	{
		ammo = GetReserveAmmo(client, windex);
		clip = GetEntProp(windex, Prop_Send, "m_iClip1");
	}
	RemovePlayerItem(client, windex);
	AcceptEntityInput(windex, "Kill");
	
	new Handle:pack;
	new entity;
	if(!knife || !g_knife) entity = GivePlayerItem(client, Classname);
	else
	{
		switch(c_knife) {
			case 1:entity = GivePlayerItem(client, "weapon_bayonet");
			case 2:entity = GivePlayerItem(client, "weapon_knife_gut");
			case 3:entity = GivePlayerItem(client, "weapon_knife_flip");
			case 4:entity = GivePlayerItem(client, "weapon_knife_m9_bayonet");
			case 5:entity = GivePlayerItem(client, "weapon_knife_karambit");
			case 6:entity = GivePlayerItem(client, "weapon_knife_tactical");
			case 7:entity = GivePlayerItem(client, "weapon_knife_butterfly");
			case 8:entity = GivePlayerItem(client, "weapon_knife");
			case 9:entity = GivePlayerItem(client, "weapon_knifegg");
			default: return;
		}
		EquipPlayerWeapon(client, entity);
	}
	
	if(!knife)
	{
		SetReserveAmmo(client, windex, ammo);
		SetEntProp(entity, Prop_Send, "m_iClip1", clip);
	}

	if(theindex == 0) return;
	
	new m_iItemIDHigh = GetEntProp(entity, Prop_Send, "m_iItemIDHigh");
	new m_iItemIDLow = GetEntProp(entity, Prop_Send, "m_iItemIDLow");

	SetEntProp(entity,Prop_Send,"m_iItemIDLow",2048);
	SetEntProp(entity,Prop_Send,"m_iItemIDHigh",0);

	SetEntProp(entity,Prop_Send,"m_nFallbackPaintKit",g_paints[theindex][index]);
	if(g_paints[theindex][wear] >= 0.0) SetEntPropFloat(entity,Prop_Send,"m_flFallbackWear",g_paints[theindex][wear]);
	if(g_paints[theindex][stattrak] != -2) SetEntProp(entity,Prop_Send,"m_nFallbackStatTrak",g_paints[theindex][stattrak]);
	if(g_paints[theindex][quality] != -2) SetEntProp(entity,Prop_Send,"m_iEntityQuality",g_paints[theindex][quality]);
	

	CreateDataTimer(2.0, RestoreItemID, pack);
	WritePackCell(pack,EntIndexToEntRef(entity));
	WritePackCell(pack,m_iItemIDHigh);
	WritePackCell(pack,m_iItemIDLow);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnPostWeaponEquip);
}

public Action:OnPostWeaponEquip(client, weapon)
{
	new Handle:pack;
	CreateDataTimer(0.0, Pasado, pack);
	WritePackCell(pack,EntIndexToEntRef(weapon));
	WritePackCell(pack, client);
}

public Action:Pasado(Handle:timer, Handle:pack)
{
	new weapon;
	new client
    
	ResetPack(pack);
	weapon = EntRefToEntIndex(ReadPackCell(pack));
	client = ReadPackCell(pack);
    
	if(weapon == INVALID_ENT_REFERENCE || !IsClientInGame(client) || !IsPlayerAlive(client) || (g_hosties && IsClientInLastRequest(client))) return;
	
	if(weapon < 1 || !IsValidEdict(weapon) || !IsValidEntity(weapon)) return;
	
	if (paintselected[client] == 0 || GetEntProp(weapon, Prop_Send, "m_hPrevOwner") > 0 || (GetEntProp(weapon, Prop_Send, "m_iItemIDHigh") == 0 && GetEntProp(weapon, Prop_Send, "m_iItemIDLow") == 2048))
		return;
		
	decl String:Classname[64];
	GetEdictClassname(weapon, Classname, 64);
	if(StrEqual(Classname, "weapon_taser"))
	{
		return;
	}
	if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == weapon || GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == weapon || GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == weapon || (g_c4 && GetPlayerWeaponSlot(client, CS_SLOT_C4) == weapon))
	{
		new theindex = paintselected[client];
		if(theindex == -1)
		{
			theindex = GetRandomInt(1, g_paintCount-1);
		}
		//PrintToChat(client, "prueba");
		ChangePaint(client, weapon, Classname, theindex);
	}

}
