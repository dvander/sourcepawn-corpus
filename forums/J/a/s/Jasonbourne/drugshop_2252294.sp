// Compiler Directives
#pragma     semicolon 1
#include    <sourcemod>
#include    <sdktools>
#include    <morecolors>
#include    <drugshop>
#define     PREFIX "{blueviolet}[{hotpink}DrugShop{blueviolet}]{aliceblue}"

// DrugShop Global Variables
new g_iAccount = -1;
new startmoney;
new drugs_per_pistol = 50;
new cost_per_drug = 16000;
new bool:LateLoaded;
new String:drug_name[5][32];
new String:weapon[5][32];
new Handle:Database;
new Handle:g_hStartMoney;
new Handle:g_Cvar_CostPerDrug;
new Handle:g_Cvar_DrugsPerPistol;

// SQL
new String:sql_CreateTable[] =  "CREATE TABLE IF NOT EXISTS `inventory` (user varchar(64), drug int(10), num int(10));";
new String:sql_FindUser[] =     "SELECT user FROM inventory WHERE user = '%s'";
new String:sql_DeleteUser[] =   "DELETE FROM inventory WHERE user = '%s';"; 
new String:sql_AddNewUser[] =   "INSERT into inventory VALUES ('%s', 0, 0), ('%s', 1, 0), ('%s', 2, 0), ('%s', 3, 0), ('%s', 4, 0)";
new String:sql_GetAllDrugs[] =  "SELECT drug, num FROM inventory WHERE user = '%s' ORDER BY drug";
new String:sql_AddDrugs[] =     "UPDATE inventory SET num = num + %d WHERE user = '%s' AND drug  = %d";
new String:sql_GetNumDrugs[] =  "SELECT num FROM inventory WHERE drug = %d AND user = '%s';";
new String:sql_SetNumDrugs[] =  "UPDATE inventory SET num = %d WHERE drug = %d AND user = '%s';";

// Global Forwards
new Handle: g_DrugBuyForward;
new Handle: g_DrugSellForward;
new Handle: g_DrugsPerPistolForward;
new Handle: g_CostPerDrugForward;
new Handle: g_WeaponNameForward;
new Handle: g_DrugNameForward;

public Plugin:myinfo = 
{
    name =          "[DrugShop] Core",
    author =        "JasonBourne && Kolapsicle",
    description =   "JailBreak Fun Mod #1",
    version =       DRUGSHOP_VERSION,
    url =           "https://forums.alliedmods.net/showthread.php?t=255946"
};


#if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
public APLRes:AskPluginLoad2 (Handle:myself, bool:late, String:error[], err_max)
#else
public bool:AskPluginLoad (Handle:myself, bool:late, String:error[], err_max)
#endif
{
// The following line is for backwards compatibility of morecolors.inc
    MarkNativeAsOptional("GetUserMessageType"); 
    
// DrugShop Natives    
    RegPluginLibrary("drugshop");
    CreateNative("DrugShop_AddDrugs", Native_AddDrugs);
    CreateNative("DrugShop_GetDrugName", Native_GetDrugName);
    CreateNative("DrugShop_GetNumDrugs", Native_GetNumDrugs);
    CreateNative("DrugShop_GetDrugID", Native_GetDrugID);
    CreateNative("DrugShop_GetWeaponName", Native_GetWeaponName);
    CreateNative("DrugShop_GetWeaponID", Native_GetWeaponID);
    CreateNative("DrugShop_GetDrugsPerPistol", Native_GetDrugsPerPistol);
    CreateNative("DrugShop_GetCostPerDrug", Native_GetCostPerDrug);
    CreateNative("DrugShop_SetDrugName", Native_SetDrugName);
    CreateNative("DrugShop_SetWeaponName", Native_SetWeaponName);
    CreateNative("DrugShop_SetDrugsPerPistol", Native_SetDrugsPerPistol);
    CreateNative("DrugShop_SetCostPerDrug", Native_SetCostPerDrug);
    CreateNative("DrugShop_SetNumDrugs", Native_SetNumDrugs);
    CreateNative("DrugShop_CheckUserExists", Native_CheckUserExists);
    CreateNative("DrugShop_AddNewUser", Native_AddNewUser);

    LateLoaded = late;

    #if SOURCEMOD_V_MAJOR >= 1 && SOURCEMOD_V_MINOR >= 3
    return APLRes_Success;
    #else
    return true;
    #endif
}


public OnPluginStart ()
{
// Load Translations
    LoadTranslations("drugshop.phrases.txt");
    
// Drug Names
    Format(drug_name[0], sizeof(drug_name[]), "Marijuana");
    Format(drug_name[1], sizeof(drug_name[]), "ICE");
    Format(drug_name[2], sizeof(drug_name[]), "Cigarette");
    Format(drug_name[3], sizeof(drug_name[]), "Cocaine");
    Format(drug_name[4], sizeof(drug_name[]), "Ecstasy");

// Weapon Names
    Format(weapon[0], sizeof(weapon[]), "weapon_glock");
    Format(weapon[1], sizeof(weapon[]), "weapon_deagle");
    Format(weapon[2], sizeof(weapon[]), "weapon_usp");
    Format(weapon[3], sizeof(weapon[]), "weapon_fiveseven");
    Format(weapon[4], sizeof(weapon[]), "weapon_elite");
    
// Connect to the DB
    if(!SQL_CheckConfig("drugshop"))
    {
        SetFailState("[DrugShop] Database failure: Could not find Database conf \"drugshop\"");
        return;
    }
    SQL_TConnect(ConnectDatabase_QueryHandler, "drugshop");
    
// Get cash offset
    g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
    if (g_iAccount == -1)
    {
        SetFailState("Drug Shop - Failed to find offset for m_iAccount!");
    }
    
// If plugin is loaded after players join then manually call OnClientAuth
    if(LateLoaded)
    {
        decl String:auth[30];
        for(new i = 1; i <= GetMaxClients(); i++)
        {
            if(IsClientInGame(i) && IsClientAuthorized(i) && !IsFakeClient(i) && GetClientAuthString(i, auth, sizeof(auth)))
            {
                OnClientAuthorized(i, auth);
            }
        }
    }
    
// Get default start money
    g_hStartMoney = FindConVar("mp_startmoney");
    startmoney = GetConVarInt(g_hStartMoney);
    
// Set cash to default on team change
    AddCommandListener(ChangeTeam, "jointeam");
    
// Gloabl Forwards
    g_DrugSellForward = CreateGlobalForward("OnDrugSell", ET_Event, Param_String, Param_String, Param_Cell, Param_Cell);
    g_DrugBuyForward = CreateGlobalForward("OnDrugBuy", ET_Event, Param_String, Param_String, Param_Cell, Param_Cell);
    g_DrugsPerPistolForward = CreateGlobalForward("OnDrugsPerPistolChanged", ET_Event, Param_Cell);
    g_CostPerDrugForward = CreateGlobalForward("OnCostPerDrugChanged", ET_Event, Param_Cell);
    g_WeaponNameForward = CreateGlobalForward("OnWeaponNameChanged", ET_Event, Param_String, Param_Cell);
    g_DrugNameForward = CreateGlobalForward("OnDrugNameChanged", ET_Event, Param_String, Param_Cell);
    
// Create ConVars
    g_Cvar_CostPerDrug = CreateConVar("sm_ds_cost_per_drug", "16000", "How much should it cost to buy a drug?", FCVAR_PLUGIN, true, 0.0, false);
    g_Cvar_DrugsPerPistol = CreateConVar("sm_ds_DrugsPerPistol", "50", "How many drugs to trade for a pistol?", FCVAR_PLUGIN, true, 0.0, false);
    CreateConVar("drugshop_version", DRUGSHOP_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    RegConsoleCmd("sm_drugshop", Command_DrugShop, "Launch the Drug Shop");
    AutoExecConfig(true, "drugshop");
}


public OnConfigsExecuted ()
{
    cost_per_drug = GetConVarInt(g_Cvar_CostPerDrug);
    drugs_per_pistol = GetConVarInt(g_Cvar_DrugsPerPistol);
}


public OnClientAuthorized (client, const String:auth[])
{
    //Do not check bots nor check player with lan steamid.
    if(auth[0] == 'B' || auth[9] == 'L' || Database == INVALID_HANDLE)
    {
        return;
    }

    if ( ! DS_CheckUserExists(auth))
    {
        DS_AddNewUser(auth);
    }
}

public Action:ChangeTeam (client, const String:command[], argc)
{
    SetEntData(client, g_iAccount, startmoney);
}


public Action:Command_DrugShop (client, args)
{
    if (ClientIsValid(client))
    {
        if (GetClientTeam(client) == 2)
        {
            if (IsPlayerAlive(client))
            {
                MainMenu(client);
            }
            else
            {
                // Not Alive
                new String:buffer[128];
                Format(buffer, sizeof(buffer), "%s %T", PREFIX, "alive", LANG_SERVER);
                CPrintToChat(client, "%s", buffer);
            }
        }
        else
        {
            // Wrong Team
            new String:buffer[128];
            Format(buffer, sizeof(buffer), "%s %T", PREFIX, "team", LANG_SERVER);
            CPrintToChat(client, "%s", buffer);
        }
    }
    
    return Plugin_Handled;
}


public MainMenu (client)
{
    if(ClientIsValid(client))
    {
        new Handle:hMenu = CreateMenu(Main_MenuHandler);
        SetMenuTitle(hMenu, "Drug Shop");
        AddMenuItem(hMenu, "0", "Buy Drugs");
        AddMenuItem(hMenu, "1", "Cash in Drugs");
        DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
    }
}


public Main_MenuHandler (Handle:hMenu, MenuAction:action, client, param2)
{
    if(action == MenuAction_Select)
    {
        CreateDrugMenu(client, param2);
    }
}


public CreateDrugMenu (client, mode)
{
    new String:auth[64];
    GetClientAuthString(client, auth, 64);
    new String:query[255];
    Format(query, sizeof(query), sql_GetAllDrugs, auth);
    
    if (mode == 0)
    {
        SQL_TQuery(Database, BuyDrugMenu_QueryHandler, query, client);
    }
    else if(mode == 1)
    {
        SQL_TQuery(Database, CashDrugMenu_QueryHandler, query, client);
    }
}
 

public CashDrugMenu_QueryHandler (Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("Query failed! %s", error);
    }
    
    new client = data;

    if(ClientIsValid(client))
    {
        new count = 0;
        new Handle:hMenu = CreateMenu(CashDrugMenu_MenuHandler);
        SetMenuTitle(hMenu, "Cash in Drugs");
        if(SQL_GetRowCount(hndl) > 0)
        {
            while(SQL_FetchRow(hndl))
            {
                new drug = SQL_FetchInt(hndl, 0);
                new num = SQL_FetchInt(hndl, 1);
                new String:n[32];
                IntToString(drug, n, sizeof(n));
                new String:menu_item[64];
                Format(menu_item, sizeof(menu_item), "%s - [%d/%d]", drug_name[drug], num, drugs_per_pistol);
                if (num >= drugs_per_pistol)
                {
                    count++;
                    AddMenuItem(hMenu, n, menu_item);
                } 
                else
                {
                    AddMenuItem(hMenu, n, menu_item, ITEMDRAW_DISABLED);
                }
            }
        }
        
        if (count  == 0)
        {
            new String:buffer[128];
            Format(buffer, sizeof(buffer), "%s %T", PREFIX, "not_enough_drugs", LANG_SERVER, drugs_per_pistol);
            CPrintToChat(client, "%s", buffer);
        }
        
        DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
    }
}


public CashDrugMenu_MenuHandler (Handle:hMenu, MenuAction:action, client, drug)
{
    if(action == MenuAction_Select)
    {  
        new String:auth[64];
        GetClientAuthString(client, auth, sizeof(auth));
        DS_AddDrugs(auth, drug, -drugs_per_pistol);
        GivePlayerItem(client, weapon[drug]);
        new String:buffer[128];
        Format(buffer, sizeof(buffer), "%s %T", PREFIX, "cash_in", LANG_SERVER, drugs_per_pistol, drug_name[drug]);
        CPrintToChat(client, "%s", buffer);
    }
}


public BuyDrugMenu_QueryHandler (Handle:owner, Handle:hndl, const String:error[], any:data)
{
 
    if (hndl == INVALID_HANDLE)
    {
        LogError("[DrugShop] BuyMenu_QueryHandler Query failed! %s", error);
    }
    
    new client = data;

    if(ClientIsValid(client))
    {
        new Handle:hMenu = CreateMenu(BuyDrugMenu_MenuHandler);
        SetMenuTitle(hMenu, "Buy Drugs");

        if(SQL_GetRowCount(hndl) > 0)
        {
            while(SQL_FetchRow(hndl))
            {
                new drug = SQL_FetchInt(hndl, 0);
                new num = SQL_FetchInt(hndl, 1);
                new String:n[32];
                IntToString(drug, n, sizeof(n));
                new String:menu_item[64];
                Format(menu_item, sizeof(menu_item), "%s - [%d/%d]", drug_name[drug], num, drugs_per_pistol);
                AddMenuItem(hMenu, n, menu_item);
            }
        }
        
        DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
    }
}


public BuyDrugMenu_MenuHandler (Handle:hMenu, MenuAction:action, client, drug)
{
    if(action == MenuAction_Select)
    {   
        new cash = GetEntData(client, g_iAccount);

        if (cash >= cost_per_drug)
        {
            
            SetEntData(client, g_iAccount, cash - cost_per_drug);
            new String:buffer[128];
            Format(buffer, sizeof(buffer), "%s %T", PREFIX, "buy", LANG_SERVER, drug_name[drug]);
            CPrintToChat(client, "%s", buffer);
            new String:auth[64];
            GetClientAuthString(client, auth, 64);
            DS_AddDrugs(auth, drug, 1);
            CreateDrugMenu(client, 0);
        } 
        else
        {
            new String:buffer[128];
            Format(buffer, sizeof(buffer), "%s %T", PREFIX, "not_enough_funds", LANG_SERVER, cost_per_drug);
            CPrintToChat(client, "%s", buffer);
        }
    }
}


/* Natives */


public Native_CheckUserExists (Handle:plugin, numParams)
{
    new String:auth[64];
    GetNativeString(1, auth, sizeof(auth));

    return DS_CheckUserExists(auth);
}


public Native_AddNewUser (Handle:plugin, numParams)
{
    new String:auth[64];
    GetNativeString(1, auth, sizeof(auth));

    DS_AddNewUser(auth);
}


public Native_AddDrugs (Handle:plugin, numParams)
{
   new String:auth[64];
   GetNativeString(1, auth, sizeof(auth));
   new drug = GetNativeCell(2);
   new num_drugs = GetNativeCell(3);
   
   DS_AddDrugs(auth, drug, num_drugs);
}

 
public Native_GetDrugName (Handle:plugin, numParams)
{

    new drug = GetNativeCell(2);
    new len = GetNativeCell(3);

    if (drug >=0 && drug < 5)
    {
        SetNativeString(1, drug_name[drug], len);
        return true;
    }
    else
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "[Drugshop] Drug index [%d] invalid.", drug);
    }
}


public Native_GetWeaponName (Handle:plugin, numParams)
{
    new weapon_id = GetNativeCell(2);
    new len = GetNativeCell(3);

    if (weapon_id >=0 && weapon_id < 5)
    {
        SetNativeString(1, weapon[weapon_id], len);
        return true;
    }
    else
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "[Drugshop] weapon index [%d] invalid.", weapon_id);
    }
}


public Native_GetDrugID (Handle:plugin, numParams)
{
    new len;
    GetNativeStringLength(1, len);
    new String:str[len + 1];
    GetNativeString(1, str, len + 1);
    for (new i = 0; i < 5; i++)
	{
        if (StrEqual(str, drug_name[i]))
        {
            return i;
        }
    }
    
    return -1;
}


public Native_GetWeaponID (Handle:plugin, numParams)
{
    new len;
    GetNativeStringLength(1, len);
    new String:str[len + 1];
    GetNativeString(1, str, len + 1);
    for (new i = 0; i < 5; i++)
	{
        if (StrEqual(str, weapon[i]))
        {
            return i;
        }
    }
    
    return -1;
}


public Native_GetDrugsPerPistol (Handle:plugin, numParams)
{
    return drugs_per_pistol;
}


public Native_GetCostPerDrug(Handle:plugin, numParams)
{
    return cost_per_drug;
}


public Native_SetDrugsPerPistol (Handle:plugin, numParams)
{
    new num_drugs = GetNativeCell(1);
    if (num_drugs >= 0)
    {
        drugs_per_pistol  = num_drugs;
        
        Call_StartForward(g_DrugsPerPistolForward);
        Call_PushCell(num_drugs);
        Call_Finish();
        
        return true;
    }
    else
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "[Drugshop] Drugs per pistol must be positive, currently [%d].", num_drugs);
    }
}


public Native_SetCostPerDrug (Handle:plugin, numParams)
{
    new cost = GetNativeCell(1);
    if (cost >= 0)
    {
        cost_per_drug  = cost;
        
        Call_StartForward(g_CostPerDrugForward);
        Call_PushCell(cost);
        Call_Finish();
        
        return true;
    }
    else
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "[Drugshop] cost per drug must be positive, currently [%d].", cost);
    }
}


public Native_SetDrugName (Handle:plugin, numParams)
{
    new drug = GetNativeCell(2);
    new len;
    GetNativeStringLength(1, len);
    new String:str[len + 1];
    GetNativeString(1, str, len + 1);
    
    if (drug >=0 && drug < 5)
    {
        Format(drug_name[drug], sizeof(drug_name[]), str);
        
        Call_StartForward(g_DrugNameForward);
        Call_PushString(drug_name[drug]);
        Call_PushCell(drug);
        Call_Finish();
        
        return true;
    }
    else
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "[Drugshop] Drug index [%d] invalid.", drug);
    }
}


public Native_SetWeaponName (Handle:plugin, numParams)
{
    new weapon_id = GetNativeCell(2);
    new len;
    GetNativeStringLength(1, len);
    new String:str[len + 1];
    GetNativeString(1, str, len + 1);
    
    if (weapon_id >=0 && weapon_id < 5)
    {
        Format(weapon[weapon_id], sizeof(weapon[]), str);
        
        Call_StartForward(g_WeaponNameForward);
        Call_PushString(weapon[weapon_id]);
        Call_PushCell(weapon_id);
        Call_Finish();
        
        return true;
    }
    else
    {
        return ThrowNativeError(SP_ERROR_NATIVE, "[Drugshop] Weapon index [%d] invalid.", weapon_id);
    }
}


public Native_GetNumDrugs (Handle:plugin, numParams)
{
    new drug = GetNativeCell(2);
    new len;
    GetNativeStringLength(1, len);
    new String:auth[len + 1];
    GetNativeString(1, auth, len + 1);
    
    return DS_GetNumDrugs(auth, drug);
}


public Native_SetNumDrugs (Handle:plugin, numParams)
{
    new drug = GetNativeCell(2);
    new num_drugs = GetNativeCell(3);
    new len;
    GetNativeStringLength(1, len);
    new String:auth[len + 1];
    GetNativeString(1, auth, len + 1);
    
    return DS_SetNumDrugs(auth, drug, num_drugs);
}


/* DrugShop Internal Functions */


public DS_SetNumDrugs (const String:auth[], drug, num_drugs)
{
    if ( ! DS_CheckUserExists(auth))
    {
        DS_AddNewUser(auth);
    }
    
    new String:query[255];
    Format(query, sizeof(query), sql_SetNumDrugs, num_drugs, drug, auth);
    
    SQL_LockDatabase(Database);
    new Handle:hQuery = SQL_Query(Database, query);
    SQL_UnlockDatabase(Database);
    
    if (hQuery != INVALID_HANDLE)
    {
        return true;
    }
    
    return false;
}


public DS_GetNumDrugs (const String:auth[], drug)
{
    new String:query[255];
    Format(query, sizeof(query), sql_GetNumDrugs, drug, auth);
    
    SQL_LockDatabase(Database);
    new Handle:hQuery = SQL_Query(Database, query);
    SQL_UnlockDatabase(Database);
    
    new num = 0;
    if (hQuery != INVALID_HANDLE)
    {
        
        if(SQL_GetRowCount(hQuery) > 0)
        {
            while(SQL_FetchRow(hQuery))
            {
                num = SQL_FetchInt(hQuery, 0);
            }
        }
    }
    
    return num;
}


public DS_AddDrugs (String:auth[], drug, num_drugs)
{
    if ( ! DS_CheckUserExists(auth))
    {
        DS_AddNewUser(auth);
    }
    
    if (num_drugs > 0)
    {
        Call_StartForward(g_DrugBuyForward);
        Call_PushString(auth);
        Call_PushString(drug_name[drug]);
        Call_PushCell(drug);
        Call_PushCell(num_drugs);
        Call_Finish();
    } 
    else if (num_drugs < 0)
    {
        Call_StartForward(g_DrugSellForward);
        Call_PushString(auth);
        Call_PushString(drug_name[drug]);
        Call_PushCell(drug);
        Call_PushCell(num_drugs);
        Call_Finish();
    }
    
    new String:query[255];
    Format(query, sizeof(query), sql_AddDrugs, num_drugs, auth, drug);
    SQL_TQuery(Database, AddDrugs_QueryHandler, query);
}


public bool:DS_CheckUserExists(const String:auth[])
{
    new String:query[256];
    Format(query, sizeof(query), sql_FindUser, auth);

    SQL_LockDatabase(Database);
    new Handle:hQuery = SQL_Query(Database, query);
    SQL_UnlockDatabase(Database);

    if (hQuery != INVALID_HANDLE)
    {
        if(SQL_GetRowCount(hQuery) > 0)
        {
            return true;
        }
    }

    return false;
}


public DS_AddNewUser(const String:auth[])
{
    new String:query[256];
    Format(query, sizeof(query), sql_DeleteUser, auth);

    SQL_LockDatabase(Database);
    SQL_Query(Database, query);
    SQL_UnlockDatabase(Database);

    Format(query, sizeof(query), sql_AddNewUser, auth, auth, auth, auth, auth);
    SQL_TQuery(Database, AddNewUser_QueryHandler, query);
    
}


/* SQL Query Handler Functions */


public AddDrugs_QueryHandler (Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("[DrugShop] AddDrugs_QueryHandler Query failed! %s", error);
    }
}


public ConnectDatabase_QueryHandler (Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        SetFailState("[DrugShop] Unable to connect to database. %s", error);
    }

    Database = hndl;
    SQL_TQuery(Database, TableCreate_QueryHandler, sql_CreateTable);
}


public TableCreate_QueryHandler (Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if(hndl == INVALID_HANDLE) 
    {
		SetFailState("[DrugShop] Unable to create table. %s", error);
	}
}


public AddNewUser_QueryHandler (Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("[DrugShop] AddNewUser_QueryHandler Query failed! %s", error);
    }
}
/* End of drugshop.sp */