#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define MAX_PAINTS 500

enum Listado
{
	String:Nombre[32],
	index
}

new Handle:menuw = INVALID_HANDLE;
new g_paints[MAX_PAINTS][Listado];
new g_paintCount = 0;
new String:path_paints[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "SM CS:GO Weapon Paints",
	author = "Franc1sco franug",
	description = "",
	version = "1.1",
	url = "http://www.zeuszombie.com"
};

public OnPluginStart()
{
	CreateConVar("sm_wpaints_version", "1.0", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	RegConsoleCmd("sm_wskins", GetSkins);
	
	RegAdminCmd("sm_reloadwskins", ReloadSkins, ADMFLAG_ROOT);
	
	ReadPaints();
}

public Action:ReloadSkins(client, args)
{	
	ReadPaints();
	PrintToChat(client, " \x04[WP]\x01 Weapon paints reloaded");
	
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
		decl String:info[4];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		new i = StringToInt(info);
		new wskin = g_paints[i][index];
		
		new windex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(windex > 0 && (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == windex || GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY) == windex || GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == windex))
		{
			decl String:Classname[64];
			GetEdictClassname(windex, Classname, 64);
			
			if(StrEqual(Classname, "weapon_taser"))
			{
				PrintToChat(client, " \x04[WP]\x01 You cant use a paint in this weapon");
				//GetSkins(client, 0);
				return;
			}
			new bool:knife = false;
			if(StrContains(Classname, "weapon_knife", false) == 0) knife = true;
			
			new ammo, clip;
			if(!knife)
			{
				ammo = GetReserveAmmo(client);
				clip = GetEntProp(windex, Prop_Send, "m_iClip1");
			}
			RemovePlayerItem(client, windex);
			AcceptEntityInput(windex, "Kill");
			
			new Handle:pack;
			new entity = GivePlayerItem(client, "weapon_knife_karambit");
			
			FakeClientCommand(client, "use %s", Classname);
			
			if(!knife)
			{
				SetReserveAmmo(client, ammo);
				SetEntProp(entity, Prop_Send, "m_iClip1", clip);
			}

			new m_iItemIDHigh = GetEntProp(entity, Prop_Send, "m_iItemIDHigh");
			new m_iItemIDLow = GetEntProp(entity, Prop_Send, "m_iItemIDLow");

			SetEntProp(entity,Prop_Send,"m_iItemIDLow",2048);
			SetEntProp(entity,Prop_Send,"m_iItemIDHigh",0);

			SetEntProp(entity,Prop_Send,"m_nFallbackPaintKit",wskin);

			CreateDataTimer(2.0, RestoreItemID, pack);
			WritePackCell(pack,EntIndexToEntRef(entity));
			WritePackCell(pack,m_iItemIDHigh);
			WritePackCell(pack,m_iItemIDLow);
			
			PrintToChat(client, " \x04[WP]\x01 You have choose\x03 %s", g_paints[i][Nombre]);
			
			if(knife) EquipPlayerWeapon(client, entity);
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
	
	decl String:buffer[PLATFORM_MAX_PATH];
	decl Handle:kv;
	g_paintCount = 0;

	kv = CreateKeyValues("Paints");
	FileToKeyValues(kv, path_paints);

	if (!KvGotoFirstSubKey(kv)) {

		SetFailState("CFG File not found: %s", path_paints);
		CloseHandle(kv);
	}
	do {

		KvGetSectionName(kv, buffer, sizeof(buffer));
		Format(g_paints[g_paintCount][Nombre], 32, "%s", buffer);
		KvGetString(kv, "paint", buffer, sizeof(buffer));
		
		g_paints[g_paintCount][index] = StringToInt(buffer);

		g_paintCount++;
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
	
	if(menuw != INVALID_HANDLE) CloseHandle(menuw);
	menuw = INVALID_HANDLE;
	
	menuw = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menuw, "Choose your Weapon Paint");
	decl String:item[4];
	for (new i=0; i<g_paintCount; ++i) {
		Format(item, 4, "%i", i);
		AddMenuItem(menuw, item, g_paints[i][Nombre]);
	}
	SetMenuExitButton(menuw, true);
}

stock GetReserveAmmo(client)
{
    new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    if(weapon < 1) return -1;
    
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return -1;
    
    return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
}

stock SetReserveAmmo(client, ammo)
{
    new weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
    if(weapon < 1) return;
    
    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if(ammotype == -1) return;
    
    SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
} 
