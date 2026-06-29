#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define VERSION "1.2"

enum WeaponType
{
    Type_Primary,
    Type_Secondary,
	Type_Grenade //add
}

new String:secondary[256] = "weapon_glock, weapon_cz75a, weapon_tec9, weapon_revolver, weapon_p250, weapon_deagle, weapon_elite, weapon_fiveseven, weapon_hkp2000, weapon_usp_silencer";
new String:grenade[128] = "weapon_hegrenade, weapon_decoy, weapon_molotov, weapon_incgrenade, weapon_flashbang, weapon_smokegrenade"; //add

new Handle:hOnWeaponSelected;
new Handle:hPostOnWeaponSelected;

new offsMoney;
new offsActiveWeapon;
new offsClip;

new Handle:kvMarket = INVALID_HANDLE;

new rebuyWeapons[MAXPLAYERS+1][WeaponType];

public Plugin:myinfo =
{
    name = "Market", 
    author = "TummieTum", 
    description = "Zombie Riot CS:GO Market", 
    version = VERSION, 
    url = "Team-Secretforce.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    CreateNative("Market_Send", Native_Send);
    CreateNative("Market_GetWeaponIDInfo", Native_GetWeaponIDInfo);
    
    hOnWeaponSelected = CreateGlobalForward("Market_OnWeaponSelected", ET_Single, Param_Cell, Param_String);
    hPostOnWeaponSelected = CreateGlobalForward("Market_PostOnWeaponSelected", ET_Ignore, Param_Cell, Param_CellByRef);
    
    return APLRes_Success;
}

public OnPluginStart()
{
    LoadTranslations("common.phrases.txt");
    
    // ======================================================================
    
    RegPluginLibrary("market");
    
    // ======================================================================
    
    offsMoney = FindSendPropInfo("CCSPlayer", "m_iAccount");
    if (offsMoney == -1)
    {
        SetFailState("Couldn't find \"m_iAccount\"!");
    }
    
    offsActiveWeapon = FindSendPropInfo("CAI_BaseNPC", "m_hActiveWeapon");
    if (offsActiveWeapon == -1)
    {
        SetFailState("Couldn't find \"m_hActiveWeapon\"!");
    }
    
    offsClip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
    if (offsClip == -1)
    {
        SetFailState("Couldn't find \"m_iClip1\"!");
    }
}

public OnMapStart()
{   
    if (kvMarket != INVALID_HANDLE)
    {
        CloseHandle(kvMarket);
    }
    
    kvMarket = CreateKeyValues("weapons");
    
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/market/weapons.txt");
    
    if (!FileToKeyValues(kvMarket, path))
    {
        SetFailState("\"%s\" missing from server", path);
    }
}

public OnClientPutInServer(client)
{
    rebuyWeapons[client][Type_Primary] = -1;
    rebuyWeapons[client][Type_Secondary] = -1;
    rebuyWeapons[client][Type_Grenade] = -1; //add
}

public Native_Send(Handle:plugin,  argc)
{
    new client = GetNativeCell(1);
    
    if (!client || !IsClientInGame(client))
    {
        ThrowNativeError(SP_ERROR_INDEX, "%T", "No matching client");
        
        return;
    }
    
    decl String:title[64];
    decl String:rebuy[64];
    
    GetNativeString(2, title, sizeof(title));
    GetNativeString(3, rebuy, sizeof(rebuy));
    
    Market(client, title, rebuy);
}

public Native_GetWeaponIDInfo(Handle:plugin,  argc)
{
    decl String:weaponid[8];
    GetNativeString(1, weaponid, sizeof(weaponid));
    
    KvRewind(kvMarket);
    if (!KvJumpToKey(kvMarket, weaponid))
    {
        return false;
    }
    
    decl String:display[64];
    decl String:weapon[64];

    KvGetString(kvMarket, "display", display, sizeof(display));
    KvGetString(kvMarket, "weapon", weapon, sizeof(weapon));
    
    SetNativeString(2, display, sizeof(display));
    SetNativeString(3, weapon, sizeof(weapon));
    
    SetNativeCellRef(4, KvGetNum(kvMarket, "price"));
    
    return true;
}

Market(client, const String:title[], const String:rebuy[])
{
    new Handle:menu_market = CreateMenu(MarketHandle);

    SetMenuTitle(menu_market, "%s", title);

    AddMenuItem(menu_market, "rebuy", rebuy);
    
    decl String:weaponid[8];
    decl String:weaponname[64];
    decl String:weaponent[64];
    
    KvRewind(kvMarket);
    if (KvGotoFirstSubKey(kvMarket))
    {
        do
        {
            KvGetSectionName(kvMarket, weaponid, sizeof(weaponid));
            KvGetString(kvMarket, "display", weaponname, sizeof(weaponname));
            KvGetString(kvMarket, "weapon", weaponent, sizeof(weaponent));
            
            decl String:display[64];
            
            new price;
            
            if (!PlayerHasWeapon(client, weaponent))
            {
                price = KvGetNum(kvMarket, "price");
                
                Format(display, sizeof(display), "%s - $%d", weaponname, price);
            }
            else
            {
                price = KvGetNum(kvMarket, "ammoprice");
                
                Format(display, sizeof(display), "%s Ammo - $%d", weaponname, price);
            }
            
            AddMenuItem(menu_market, weaponid, display);
        } while (KvGotoNextKey(kvMarket));
    }
    
    DisplayMenu(menu_market, client, MENU_TIME_FOREVER);
}

public MarketHandle(Handle:menu_market, MenuAction:action, client, slot)
{
    if (action == MenuAction_Select)
    {
        decl String:weaponid[64];
        if (GetMenuItem(menu_market, slot, weaponid, sizeof(weaponid)))
        {
            new bool:allow;
            
            Call_StartForward(hOnWeaponSelected);
            Call_PushCell(client);
            Call_PushString(weaponid);
            Call_Finish(allow);
            
            if (allow)
            {
                if (slot == 0)
                {
                    RebuyGuns(client);
                }
                else
                {
                    EquipWeapon(client, StringToInt(weaponid));
                }
            }
            
            Call_StartForward(hPostOnWeaponSelected);
            Call_PushCell(client);
            Call_PushCellRef(allow);
            Call_Finish();
        }
    }
    if (action == MenuAction_End)
    {
        CloseHandle(menu_market);
    }
}

EquipWeapon(client, weapon)
{
    KvRewind(kvMarket);
    
    decl String:weaponid[64];
    IntToString(weapon, weaponid, sizeof(weaponid));
    
    if (!KvJumpToKey(kvMarket, weaponid))
    {
        return;
    }
    
    decl String:weaponent[64];
    KvGetString(kvMarket, "weapon", weaponent, sizeof(weaponent), "INVALID WEAPON");
    
    new weaponindex = -1; //fix
    
    new WeaponType:type = GetWeaponType(weaponent);
    
    if (!PlayerHasWeapon(client, weaponent))
    {
        new price = KvGetNum(kvMarket, "price");
        if (!TakePlayerMoney(client, price))
        {
            return;
        }
        
        if (type == Type_Primary)
        {
            weaponindex = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
        }
        else if (type == Type_Secondary)
        {
            weaponindex = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
        }
        
        if (weaponindex > -1)
        {
            decl String:classname[64];
            GetEdictClassname(weaponindex, classname, sizeof(classname));
            
            FakeClientCommandEx(client, "use %s", classname);
            FakeClientCommandEx(client, "drop");
        }
        
        GivePlayerItem(client, weaponent);
        
        rebuyWeapons[client][type] = weapon;
    }
    else
    {
        decl String:weaponammo[32];
        KvGetString(kvMarket, "ammo", weaponammo, sizeof(weaponammo));
        
        new price = KvGetNum(kvMarket, "ammoprice");
        if (!TakePlayerMoney(client, price))
        {
            return;
        }
        
        if (!weaponammo[0])
        {
            return;
        }
        
        // Preserve clip ammo while refilling the reserve.
        new weaponindex_prim = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
        new weaponindex_sec = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
        
        new clip_prim;
        new clip_sec;
        
        if (weaponindex_prim != -1)
            clip_prim = GetEntData(weaponindex_prim, offsClip);
        
        if (weaponindex_sec != -1)
            clip_sec = GetEntData(weaponindex_sec, offsClip);
        
        GivePlayerItem(client, weaponammo);
        
        if (weaponindex_prim != -1)
            SetEntData(weaponindex_prim, offsClip, clip_prim);
        
        if (weaponindex_sec != -1)
            SetEntData(weaponindex_sec, offsClip, clip_sec);
        
        rebuyWeapons[client][type] = weapon;
    }
}

RebuyGuns(client)
{
    if (rebuyWeapons[client][Type_Primary] != -1)
    {
        EquipWeapon(client, rebuyWeapons[client][Type_Primary]);
    }
    
    if (rebuyWeapons[client][Type_Secondary] != -1)
    {
        EquipWeapon(client, rebuyWeapons[client][Type_Secondary]);
    }
	//add
	if (rebuyWeapons[client][Type_Grenade] != -1)
	{
		EquipWeapon(client, rebuyWeapons[client][Type_Grenade]);
	}
}

bool:TakePlayerMoney(client, amount)
{
    new money = GetEntData(client, offsMoney);
    
    money -= amount;
    if (money < 0)
    {
        return false;
    }
    
    SetEntData(client, offsMoney, money, 4, true);
    
    return true;
}

bool:PlayerHasWeapon(client, const String:weapon[])
{
    new primindex = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
    new secindex = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
    
    decl String:primname[64];
    decl String:secname[64];
    
    if (primindex > -1)
    {
        GetEdictClassname(primindex, primname, sizeof(primname));
    }
    
    if (secindex > -1)
    {
        GetEdictClassname(secindex, secname, sizeof(secname));
    }
    
    return (StrEqual(weapon, primname, false) || StrEqual(weapon, secname, false));
}

WeaponType:GetWeaponType(const String:weapon[])
{
    if (StrContains(secondary, weapon, false) > -1)
    {
        return Type_Secondary;
    }
	else if (StrContains(grenade, weapon, false) > -1) //add
	{
		return Type_Grenade;
	}

    return Type_Primary;
}