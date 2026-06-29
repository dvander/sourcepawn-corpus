/*
 * ============================================================================
 *
 *  SourceMod Geolocation Plugin
 *
 *  File:          geolocation.sp
 *  Description:   Shows geolocation of players.
 *
 *  Copyright (C) 2011  Frenzzy
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

#pragma semicolon 1

/* SM Includes */
#include <sourcemod>
#include <socket>
#include <regex>

#undef REQUIRE_EXTENSIONS
#include <steamtools>

#undef REQUIRE_PLUGIN
#include <updater>

/* Plugin Info */
#define PLUGIN_NAME "Geolocation"
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = "Frenzzy",
    description = "Shows geolocation of players",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=1599504"
};

/* Globals */
#define STEAMTOOLS_AVAILABLE() (GetFeatureStatus(FeatureType_Native, "Steam_GetPublicIP") == FeatureStatus_Available)

#define UPDATE_URL "http://vsdir.com/sm/geolocation/update.txt"

new bool:g_bLateLoad = false;

new Handle:g_hCvarVersion = INVALID_HANDLE;
new Handle:g_hCvarIP = INVALID_HANDLE;
new Handle:g_hCvarHostIP = INVALID_HANDLE;
new Handle:g_hCvarShowIPs = INVALID_HANDLE;
new Handle:g_hCvarAdminCmd = INVALID_HANDLE;

new String:g_ClientCountry[MAXPLAYERS + 1][64];
new String:g_ClientRegion[MAXPLAYERS + 1][64];
new String:g_ClientCity[MAXPLAYERS + 1][64];
new String:g_ClientISP[MAXPLAYERS + 1][64];

/* Plugin Functions */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    g_bLateLoad = late;
    
    // SteamTools
    MarkNativeAsOptional("Steam_GetPublicIP");
    
    return APLRes_Success;
}

public OnPluginStart()
{
    decl String:buffer[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, buffer, sizeof(buffer), "data/geolocation");
    
    if (!DirExists(buffer))
    {
        CreateDirectory(buffer, 511);
    }
    
    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    
    // Convars.
    g_hCvarVersion = CreateConVar("sm_geolocation_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    OnVersionChanged(g_hCvarVersion, "", "");
    HookConVarChange(g_hCvarVersion, OnVersionChanged);
    
    g_hCvarIP = FindConVar("ip");
    g_hCvarHostIP = FindConVar("hostip");
    g_hCvarShowIPs = CreateConVar("sm_geolocation_ips", "0", "Show IP-addresses for non-admin clients.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarAdminCmd = CreateConVar("sm_geolocation_cmd", "0", "Only admins can use geoinfo command.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    
    AutoExecConfig(true, "geolocation");
    
    // Commands.
    RegConsoleCmd("sm_geoinfo", Command_GeoInfo, "Displays Geolocation Info");
    
    // Updater.
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
    
    if (g_bLateLoad)
    {
        for (new client = 1; client <= MaxClients; client++)
        {
            if (!IsClientConnected(client))
            {
                continue;
            }
            
            OnClientConnected(client);
        }
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public OnVersionChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (!StrEqual(newValue, PLUGIN_VERSION))
    {
        SetConVarString(g_hCvarVersion, PLUGIN_VERSION);
    }
}

public OnClientConnected(client)
{
    strcopy(g_ClientCountry[client], sizeof(g_ClientCountry[]), "Unknown");
    strcopy(g_ClientRegion[client], sizeof(g_ClientRegion[]), "Unknown");
    strcopy(g_ClientCity[client], sizeof(g_ClientCity[]), "Unknown");
    strcopy(g_ClientISP[client], sizeof(g_ClientISP[]), "Unknown");
    
    if (IsFakeClient(client))
    {
        return;
    }
    
    decl String:ip[16];
    if (!GetClientIP(client, ip, sizeof(ip)))
    {
        return;
    }
    
    if (IsIPLocal(ip))
    {
        GetServerIP(ip, sizeof(ip));
        
        if (IsIPLocal(ip))
        {
            strcopy(g_ClientCountry[client], sizeof(g_ClientCountry[]), "Local Network");
            strcopy(g_ClientRegion[client], sizeof(g_ClientRegion[]), "Local Network");
            strcopy(g_ClientCity[client], sizeof(g_ClientCity[]), "Local Network");
            strcopy(g_ClientISP[client], sizeof(g_ClientISP[]), "Local Network");
            
            return;
        }
    }
    
    new userid = GetClientUserId(client);
    
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/geolocation/%d.htm", userid);
    
    new Handle:hFile = OpenFile(path, "wb");
    
    if (hFile == INVALID_HANDLE)
    {
        ThrowError("Error writing to file: %s", path);
    }
    
    new Handle:hDataPack = CreateDataPack();
    WritePackCell(hDataPack, _:hFile);
    WritePackCell(hDataPack, userid);
    WritePackString(hDataPack, ip);
    
    new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
    SocketSetArg(socket, hDataPack);
    SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "whatismyipaddress.com", 80);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hDataPack)
{
    ResetPack(hDataPack);
    CloseHandle(Handle:ReadPackCell(hDataPack));
    new userid = ReadPackCell(hDataPack);
    CloseHandle(hDataPack);
    CloseHandle(socket);
    
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/geolocation/%d.htm", userid);
    DeleteFile(path);
}

public OnSocketConnected(Handle:socket, any:hDataPack)
{
    decl String:request[100], String:ip[16];
    SetPackPosition(hDataPack, 16);
    ReadPackString(hDataPack, ip, sizeof(ip));
    Format(request, sizeof(request), "GET /ip/%s HTTP/1.0\r\nHost: whatismyipaddress.com\r\nConnection: close\r\n\r\n", ip);
    SocketSend(socket, request);
}

public OnSocketReceive(Handle:socket, String:data[], const size, any:hDataPack)
{
    ResetPack(hDataPack);
    new Handle:hFile = Handle:ReadPackCell(hDataPack);
    
    // Skip the header data.
    new pos = StrContains(data, "\r\n\r\n");
    pos = (pos != -1) ? pos + 4 : 0;
    
    for (new i = pos; i < size; i++)
    {
        WriteFileCell(hFile, data[i], 1);
    }
}

public OnSocketDisconnected(Handle:socket, any:hDataPack)
{
    ResetPack(hDataPack);
    CloseHandle(Handle:ReadPackCell(hDataPack));
    new userid = ReadPackCell(hDataPack);
    CloseHandle(hDataPack);
    CloseHandle(socket);
    
    decl String:path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/geolocation/%d.htm", userid);
    
    new client = GetClientOfUserId(userid);
    
    if (client == 0)
    {
        DeleteFile(path);
        return;
    }
    
    new Handle:hFile = OpenFile(path, "rb");
    
    if (hFile == INVALID_HANDLE)
    {
        ThrowError("Failed to open file: %s", path);
    }
    
    new Handle:hCountry = CompileRegex("<th>Country:</th><td>(.*?) <");
    new Handle:hRegion = CompileRegex("<th>State/Region:</th><td>(.*?)</td>");
    new Handle:hCity = CompileRegex("<th>City:</th><td>(.*?)</td>");
    new Handle:hISP = CompileRegex("<th>ISP:</th><td>(.*?)</td>");
    
    decl String:country[64];
    decl String:region[64];
    decl String:city[64];
    decl String:isp[64];
    
    country[0] = '\0';
    region[0] = '\0';
    city[0] = '\0';
    isp[0] = '\0';
    
    decl String:line[2048];
    
    while (!IsEndOfFile(hFile) && ReadFileLine(hFile, line, sizeof(line)))
    {
        if (MatchRegex(hCountry, line) != -1)
        {
            GetRegexSubString(hCountry, 1, country, sizeof(country));
        }
        
        if (MatchRegex(hRegion, line) != -1)
        {
            GetRegexSubString(hRegion, 1, region, sizeof(region));
        }
        
        if (MatchRegex(hCity, line) != -1)
        {
            GetRegexSubString(hCity, 1, city, sizeof(city));
        }
        
        if (MatchRegex(hISP, line) != -1)
        {
            GetRegexSubString(hISP, 1, isp, sizeof(isp));
        }
    }
    
    CloseHandle(hCountry);
    CloseHandle(hRegion);
    CloseHandle(hCity);
    CloseHandle(hISP);
    
    CloseHandle(hFile);
    DeleteFile(path);
    
    if (country[0] != '\0')
    {
        strcopy(g_ClientCountry[client], sizeof(g_ClientCountry[]), country);
    }
    
    if (region[0] != '\0')
    {
        strcopy(g_ClientRegion[client], sizeof(g_ClientRegion[]), region);
    }
    
    if (city[0] != '\0')
    {
        strcopy(g_ClientCity[client], sizeof(g_ClientCity[]), city);
    }
    
    if (isp[0] != '\0')
    {
        strcopy(g_ClientISP[client], sizeof(g_ClientISP[]), isp);
    }
}

public OnClientPostAdminCheck(client)
{
    if (IsFakeClient(client))
    {
        return;
    }
    
    decl String:buffer[1024], String:name[64], String:authid[64], String:ip[16];
    new AdminId:admin, len;
    
    if (!GetClientName(client, name, sizeof(name)))
    {
        strcopy(name, sizeof(name), "Unknown");
    }
    
    if (!GetClientAuthString(client, authid, sizeof(authid)))
    {
        strcopy(authid, sizeof(authid), "Unknown");
    }
    
    if (!GetClientIP(client, ip, sizeof(ip)))
    {
        strcopy(ip, sizeof(ip), "Unknown");
    }
    
    for (new target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
        {
            continue;
        }
        
        if (IsFakeClient(target))
        {
            continue;
        }
        
        admin = GetUserAdmin(target);
        
        len = 0;
        len += Format(buffer[len], sizeof(buffer)-len, "[SM] Geolocation Info:");
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** Player: %s", name);
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** Steam ID: %s", authid);
        
        if (admin != INVALID_ADMIN_ID || GetConVarBool(g_hCvarShowIPs))
        {
            len += Format(buffer[len], sizeof(buffer)-len, "\n  ** IP Address: %s", ip);
        }
        
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** Country: %s", g_ClientCountry[client]);
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** State/Region: %s", g_ClientRegion[client]);
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** City: %s", g_ClientCity[client]);
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** ISP: %s", g_ClientISP[client]);
        PrintToConsole(target, buffer);
    }
}

GetServerIP(String:buffer[], size)
{
    if (STEAMTOOLS_AVAILABLE())
    {
        new octets[4];
        Steam_GetPublicIP(octets);
        
        if (octets[0] != 0)
        {
            Format(buffer, size, "%d.%d.%d.%d", octets[0], octets[1], octets[2], octets[3]);
            
            return;
        }
    }
    
    if (g_hCvarIP != INVALID_HANDLE)
    {
        GetConVarString(g_hCvarIP, buffer, size);
        
        if (!StrEqual(buffer, "localhost"))
        {
            return;
        }
    }
    
    if (g_hCvarHostIP != INVALID_HANDLE)
    {
        new ip = GetConVarInt(g_hCvarHostIP);
        Format(buffer, size, "%d.%d.%d.%d", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8 ) & 0xFF, ip & 0xFF);
        
        return;
    }
    
    Format(buffer, size, "loopback");
}

bool:IsIPLocal(const String:ip[])
{
    decl String:pieces[2][4], octets[2];
    ExplodeString(ip, ".", pieces, sizeof(pieces), sizeof(pieces[]));
    octets[0] = StringToInt(pieces[0]);
    octets[1] = StringToInt(pieces[1]);
    
    if (octets[0] == 0) // Unknown
    {
        return true;
    }
    else if (octets[0] == 10 || octets[0] == 127) // 10.x.x.x | 127.x.x.x
    {
        return true;
    }
    else if (octets[0] == 192 && octets[1] == 168 || octets[0] == 169 && octets[1] == 254) // 192.168.x.x | 169.254.x.x
    {
        return true;
    }
    else if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) // 172.16.x.x - 172.31.x.x
    {
        return true;
    }
    
    return false;
}

public Action:Command_GeoInfo(client, args)
{
    new AdminId:admin = INVALID_ADMIN_ID;
    
    if (client != 0)
    {
        admin = GetUserAdmin(client);
        
        if (admin == INVALID_ADMIN_ID && GetConVarBool(g_hCvarAdminCmd))
        {
            ReplyToCommand(client, "[SM] %t", "No Access");
            
            return Plugin_Handled;
        }
    }
    
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_geoinfo <#userid|name>");
        
        return Plugin_Handled;
    }
    
    decl String:arg[64];
    GetCmdArg(1, arg, sizeof(arg));
    
    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
    
    if ((target_count = ProcessTargetString(arg, 0, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        
        return Plugin_Handled;
    }
    
    if (GetCmdReplySource() == SM_REPLY_TO_CHAT)
    {
        ReplyToCommand(client, "[SM] %t", "See console for output");
    }
    
    decl String:buffer[1024], String:name[64], String:authid[64], String:ip[16];
    new len;
    
    for (new i = 0; i < target_count; i++)
    {
        new target = target_list[i];
        
        if (!GetClientName(target, name, sizeof(name)))
        {
            strcopy(name, sizeof(name), "Unknown");
        }
        
        if (!GetClientAuthString(target, authid, sizeof(authid)))
        {
            strcopy(authid, sizeof(authid), "Unknown");
        }
        
        if (!GetClientIP(target, ip, sizeof(ip)))
        {
            strcopy(ip, sizeof(ip), "Unknown");
        }
        
        len = 0;
        len += Format(buffer[len], sizeof(buffer)-len, "[SM] Geolocation Info:");
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** Player: %s", name);
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** Steam ID: %s", authid);
        
        if (client == 0 || admin != INVALID_ADMIN_ID || GetConVarBool(g_hCvarShowIPs))
        {
            len += Format(buffer[len], sizeof(buffer)-len, "\n  ** IP Address: %s", ip);
        }
        
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** Country: %s", g_ClientCountry[target]);
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** State/Region: %s", g_ClientRegion[target]);
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** City: %s", g_ClientCity[target]);
        len += Format(buffer[len], sizeof(buffer)-len, "\n  ** ISP: %s", g_ClientISP[target]);
        PrintToConsole(client, buffer);
    }
    
    return Plugin_Handled;
}
