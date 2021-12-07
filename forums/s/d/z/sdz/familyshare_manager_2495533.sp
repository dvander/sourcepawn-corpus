#include <socket>
#include <updater>

#define HOST_PATH "api.steampowered.com"
#define UPDATE_URL "www.coldcommunity.com/dev/plugins/familyshare_manager/update.txt"
#define MAX_STEAMID_LENGTH 21
#define MAX_COMMUNITYID_LENGTH 18 

new Handle:g_hCvar_AppId = INVALID_HANDLE;
new Handle:g_hCvar_APIKey = INVALID_HANDLE;
new Handle:g_hCvar_BanMessage = INVALID_HANDLE;
new Handle:g_hCvar_Whitelist = INVALID_HANDLE;
new Handle:g_hCvar_IgnoreAdmins = INVALID_HANDLE;

// The maximum returned length of 174 occurs when an unauthorized key is provided
// Header length really shouldn't be 900 characters long. But just in case...
new String:g_sAPIBuffer[MAXPLAYERS + 1][1024];
new Handle:g_hAPISocket[MAXPLAYERS + 1];

new String:g_sWhitelist[PLATFORM_MAX_PATH];
new Handle:g_hWhitelistTrie = INVALID_HANDLE;
new bool:g_bParsed = false;

public Plugin:myinfo =
{
    name = "Family Share Manager",
    author = "Sidezz (+bonbon, 11530)",
    description = "Whitelist or ban family shared accounts",
    version = "1.4.2",
    url = "www.coldcommunity.com"
};

public OnPluginStart()
{
    if(LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }

    g_bParsed = false;
    g_hWhitelistTrie = CreateTrie();
    g_hCvar_AppId = CreateConVar("sm_familyshare_appid", "320", "Application ID of current game. HL2:DM (320), CS:S (240), CS:GO (730), TF2 (440)", FCVAR_NOTIFY);
    g_hCvar_APIKey = CreateConVar("sm_familyshare_apikey", "XXXXXXXXXXXXXXXXXXXX", "Steam developer web API key", FCVAR_PROTECTED);
    g_hCvar_BanMessage = CreateConVar("sm_familyshare_banmessage", "Family sharing is disabled.", "Message to display in sourcebans/on ban", FCVAR_NOTIFY);
    g_hCvar_IgnoreAdmins = CreateConVar("sm_familyshare_ignoreadmins", "1", "Check and unblock admins?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hCvar_Whitelist = CreateConVar("sm_familyshare_whitelist", "familyshare_whitelist.ini", "File to use for whitelist (addons/sourcemod/configs/file)");

    decl String:file[PLATFORM_MAX_PATH], String:filePath[PLATFORM_MAX_PATH];
    GetConVarString(g_hCvar_Whitelist, file, sizeof(file));
    BuildPath(Path_SM, g_sWhitelist, sizeof(g_sWhitelist), "configs/%s", file);
    LogMessage("Built Filepath to: %s", g_sWhitelist);

    BuildPath(Path_SM, filePath, sizeof(filePath), "configs");
    CreateDirectory(filePath, 511);

    AutoExecConfig();

    parseList();

    RegAdminCmd("sm_reloadlist", command_reloadWhiteList, ADMFLAG_ROOT, "Reload the whitelist");
    RegAdminCmd("sm_addtolist", command_addToList, ADMFLAG_ROOT, "Add a player to the whitelist");
    RegAdminCmd("sm_removefromlist", command_removeFromList, ADMFLAG_ROOT, "Remove a player from the whitelist");
    RegAdminCmd("sm_displaylist", command_displayList, ADMFLAG_ROOT, "View current whitelist");
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL)
    }
}

public Updater_OnPluginUpdated()
{
    ReloadPlugin();
}

public Action:command_removeFromList(client, args)
{
    new Handle:hFile = OpenFile(g_sWhitelist, "a+");

    if(hFile == INVALID_HANDLE)
    {
        LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> command_removeFromList");
        PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
        CloseHandle(hFile);
        return Plugin_Handled;
    }

    if(args == 0)
    {
        PrintToChat(client, "[Family Share Manager] Invalid Syntax: sm_removefromlist <steam id>");
        return Plugin_Handled;
    }

    decl String:steamid[32], String:playerSteam[32];
    GetCmdArgString(playerSteam, sizeof(playerSteam));

    StripQuotes(playerSteam);
    TrimString(playerSteam);
  
    new bool:found = false;
    new Handle:fileArray = CreateArray(32);

    while(!IsEndOfFile(hFile) && ReadFileLine(hFile, steamid, sizeof(steamid)))
    {
        if(strlen(steamid) < 1 || IsCharSpace(steamid[0])) continue;

        ReplaceString(steamid, sizeof(steamid), "\n", "", false);

        PrintToChat(client, "%s - %s", steamid, playerSteam);
        //Not found, add to next file.
        if(!StrEqual(steamid, playerSteam, false))
        {
            PushArrayString(fileArray, steamid);
        }

        //Found, remove from file.
        else
        {
            found = true;
        }
    }

    CloseHandle(hFile);

    //Delete and rewrite list if found..
    if(found)
    {
        DeleteFile(g_sWhitelist); //I hate this, scares the shit out of me.
        new Handle:newFile = OpenFile(g_sWhitelist, "a+");

        if(newFile == INVALID_HANDLE)
        {
            LogError("[Family Share Manager] Critical Error: newFile is Invalid. --> command_removeFromList");
            PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
            return Plugin_Handled;
        }

        PrintToChat(client, "[Family Share Manager] Found Steam ID: %s, removing from list...", playerSteam);
        
        LogMessage("Begin rewrite of list..");

        for(new i = 0; i < GetArraySize(fileArray); i++)
        {
            decl String:writeLine[32];
            GetArrayString(fileArray, i, writeLine, sizeof(writeLine));
            WriteFileLine(newFile, writeLine);
            LogMessage("Wrote %s to list.", writeLine);
        }

        CloseHandle(newFile);
        CloseHandle(fileArray);
        parseList();
        return Plugin_Handled;
    }
    else PrintToChat(client, "[Family Share Manager] Steam ID: %s not found, no action taken.", playerSteam);
    return Plugin_Handled;
}

public Action:command_addToList(client, args)
{
    new Handle:hFile = OpenFile(g_sWhitelist, "a+");
    
    //Argument Count:
    switch(args)
    {
        //Create Player List:
        case 0:
        {
            new Handle:playersMenu = CreateMenu(playerMenuHandle);
            for(new i = 1; i <= MaxClients; i++)
            {
                if(IsClientAuthorized(i) && i != client)
                {
                    SetMenuTitle(playersMenu, "Viewing all players...");

                    decl String:formatItem[2][32];
                    Format(formatItem[0], sizeof(formatItem[]), "%i", GetClientUserId(i));
                    Format(formatItem[1], sizeof(formatItem[]), "%N", i);

                    //Adds menu item per player --> Client User ID, Display as Username.
                    AddMenuItem(playersMenu, formatItem[0], formatItem[1]);
                }
            }

            SetMenuExitButton(playersMenu, true);
            SetMenuPagination(playersMenu, 7);
            DisplayMenu(playersMenu, client, MENU_TIME_FOREVER);

            PrintToChat(client, "[Family Share Manager] Displaying players menu...");

            CloseHandle(hFile);
            return Plugin_Handled;
        }

        //Directly write Steam ID:
        default:
        {
            decl String:steamid[32];
            GetCmdArgString(steamid, sizeof(steamid));

            StripQuotes(steamid);
            TrimString(steamid);

            if(StrContains(steamid, "STEAM_", false) == -1)
            {
                PrintToChat(client, "[Family Share Manager] Invalid Input - Not a Steam 2 ID. (STEAM_0:X:XXXX)");
                CloseHandle(hFile);
                return Plugin_Handled;
            }

            if(hFile == INVALID_HANDLE)
            {
                LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> command_addToList");
                PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
                CloseHandle(hFile);
                return Plugin_Handled;
            }

            WriteFileLine(hFile, steamid);
            PrintToChat(client, "[Family Share Manager] Successfully added %s to the list.", steamid);
            CloseHandle(hFile);
            parseList();
            return Plugin_Handled;
        }
    }

    return Plugin_Handled;
}

public playerMenuHandle(Handle:playerMenu, MenuAction:action, client, menuItem)
{
    if(action == MenuAction_Select) 
    {   
        //Should be our Client's User ID.
        decl String:menuItems[32]; 
        GetMenuItem(playerMenu, menuItem, menuItems, sizeof(menuItems));

        new target = GetClientOfUserId(StringToInt(menuItems));
        
        //Invalid UserID/Client Index:
        if(target == 0)
        {
            LogError("[Family Share Manager] Critical Error: Invalid Client of User Id --> playerMenuHandle");
            CloseHandle(playerMenu);
            return;
        }

        decl String:steamid[32];
        GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));

        StripQuotes(steamid);
        TrimString(steamid);

        if(StrContains(steamid, "STEAM_", false) == -1)
        {
            PrintToChat(client, "[Family Share Manager] Invalid Input - Not a Steam 2 ID. (STEAM_0:X:XXXX)");
            return;
        }

        new Handle:hFile = OpenFile(g_sWhitelist, "a+");
        if(hFile == INVALID_HANDLE)
        {
            LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> playerMenuHandle");
            PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
            CloseHandle(hFile);
            return;
        }

        WriteFileLine(hFile, steamid);
        PrintToChat(client, "[Family Share Manager] Successfully added %s (%N) to the list.", steamid, target);
        CloseHandle(hFile);
        parseList();
        return;
    }

    else if(action == MenuAction_End)
    {
        CloseHandle(playerMenu);
    }
}

public Action:command_displayList(client, args)
{
    decl String:auth[32];
    new Handle:hFile = OpenFile(g_sWhitelist, "a+");

    while(!IsEndOfFile(hFile) && ReadFileLine(hFile, auth, sizeof(auth)))
    {
        TrimString(auth);
        StripQuotes(auth);

        if(strlen(auth) < 1) continue;
        ReplaceString(auth, sizeof(auth), "\n", "", false);

        if(StrContains(auth, "STEAM_", false) != -1)
        {
            if(!client) return Plugin_Handled;
            PrintToChat(client, "%s", auth); 
        }
    }

    CloseHandle(hFile);
    return Plugin_Handled;
}

public Action:command_reloadWhiteList(client, args)
{
    PrintToChat(client, "[Family Share Manager] Rebuilding whitelist...");
    parseList(true, client);
    return Plugin_Handled;
}

parseList(bool:rebuild = false, client = 0)
{
    decl String:auth[32];
    new Handle:hFile = OpenFile(g_sWhitelist, "a+");
    LogMessage("Begin parseList()");

    while(!IsEndOfFile(hFile) && ReadFileLine(hFile, auth, sizeof(auth)))
    {
        TrimString(auth);
        StripQuotes(auth);

        if(strlen(auth) < 1) continue;

        if(StrContains(auth, "STEAM_", false) != -1)
        {
            SetTrieString(g_hWhitelistTrie, auth, auth);
            LogMessage("Added %s to whitelist", auth);
        }
    }

    LogMessage("End parseList()");
    if(rebuild && client) PrintToChat(client, "[Family Share Manager] Rebuild complete!");
    g_bParsed = true;
    CloseHandle(hFile);
}

public OnClientPostAdminCheck(client)
{
    new bool:whiteListed = false;
    if(g_bParsed)
    {
        decl String:auth[2][64];
        GetClientAuthId(client, AuthId_Steam2, auth[0], sizeof(auth[]));
        whiteListed = GetTrieString(g_hWhitelistTrie, auth[0], auth[1], sizeof(auth[]));
        if(whiteListed)
        {
            LogMessage("Whitelist found player: %N", client);
            return;
        }
    }

    if(CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC) && GetConVarInt(g_hCvar_IgnoreAdmins) > 0)
    {
        return;
    }

    if(!IsFakeClient(client))
        checkFamilySharing(client);
}

public OnClientDisconnect(client)
{
    if (g_hAPISocket[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hAPISocket[client]);
        g_hAPISocket[client] = INVALID_HANDLE;
    }
}

public OnSocketConnected(Handle:socket, any:userid)
{
    new client = GetClientOfUserId(userid);

    if (!client)
    {
        CloseHandle(socket);
        return;
    }

    decl String:apikey[64];
    decl String:get[256];
    decl String:request[512];
    decl String:steamid[MAX_STEAMID_LENGTH];
    decl String:steamid64[MAX_COMMUNITYID_LENGTH];

    GetConVarString(g_hCvar_APIKey, apikey, sizeof(apikey));
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    GetCommunityIDString(steamid, steamid64, sizeof(steamid64));

    Format(get, sizeof(get),
           "%s/IPlayerService/IsPlayingSharedGame/v0001/?key=%s&steamid=%s&appid_playing=%d&format=json",
           HOST_PATH, apikey, steamid64, GetConVarInt(g_hCvar_AppId));

    Format(request, sizeof(request),
           "GET http://%s HTTP/1.1\r\nHost: %s\r\nConnection: close\r\nAccept-Encoding: *\r\n\r\n",
           get, HOST_PATH);

    SocketSend(socket, request);
}

public OnSocketReceive(Handle:socket, String:receiveData[], dataSize, any:userid)
{
    new client = GetClientOfUserId(userid);

    if (client > 0)
    {
        StrCat(g_sAPIBuffer[client], 1024, receiveData);
    
        if (StrContains(receiveData, "404 Not Found", false) != -1)
        {
            OnSocketError(socket, 404, 404, userid);
        }

        else if (StrContains(receiveData, "Unauthorized", false) != -1)
        {
            OnSocketError(socket, 403, 403, userid);
        }
    }
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:userid)
{
    new client = GetClientOfUserId(userid);
    if (client > 0)
    {
        g_hAPISocket[client] = INVALID_HANDLE;
        LogError("Error checking family sharing for %L -- error %d (%d)", client, errorType, errorNum);
    }

    CloseHandle(socket);
}

public OnSocketDisconnected(Handle:socket, any:userid)
{
    new client = GetClientOfUserId(userid);

    if (client > 0)
    {
        g_hAPISocket[client] = INVALID_HANDLE;
        ReplaceString(g_sAPIBuffer[client], 1024, " ", "");
        ReplaceString(g_sAPIBuffer[client], 1024, "\t", "");

        new index = StrContains(g_sAPIBuffer[client], "\"lender_steamid\":", false);

        if (index == -1)
        {
            LogError("unexpected error returned in request - %s", g_sAPIBuffer[client]);
        }

        else
        {
            index += strlen("\"lender_steamid\":");
            decl String:banMessage[128];
            GetConVarString(g_hCvar_BanMessage, banMessage, sizeof(banMessage));
            if (g_sAPIBuffer[client][index + 1] != '0' || g_sAPIBuffer[client][index + 2] != '"')
            {
                LogMessage("Banning %L for 10 minutes", client);
                ServerCommand("sm_ban #%i 10 \"%s\"", userid, banMessage);
            }
        }
    }

    CloseHandle(socket);
}

Action:checkFamilySharing(client)
{
    new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);

    g_hAPISocket[client] = socket;
    g_sAPIBuffer[client][0] = '\0';

    SocketSetArg(socket, GetClientUserId(client));
    SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, HOST_PATH, 80);
}

// Credit to 11530
// https://forums.alliedmods.net/showthread.php?t=183443&highlight=communityid
stock bool:GetCommunityIDString(const String:SteamID[], String:CommunityID[], const CommunityIDSize)
{
    decl String:SteamIDParts[3][11];
    new const String:Identifier[] = "76561197960265728";
    
    if ((CommunityIDSize < 1) || (ExplodeString(SteamID, ":", SteamIDParts, sizeof(SteamIDParts), sizeof(SteamIDParts[])) != 3))
    {
        CommunityID[0] = '\0';
        return false;
    }

    new Current, CarryOver = (SteamIDParts[1][0] == '1');
    for (new i = (CommunityIDSize - 2), j = (strlen(SteamIDParts[2]) - 1), k = (strlen(Identifier) - 1); i >= 0; i--, j--, k--)
    {
        Current = (j >= 0 ? (2 * (SteamIDParts[2][j] - '0')) : 0) + CarryOver + (k >= 0 ? ((Identifier[k] - '0') * 1) : 0);
        CarryOver = Current / 10;
        CommunityID[i] = (Current % 10) + '0';
    }

    CommunityID[CommunityIDSize - 1] = '\0';
    return true;
}  