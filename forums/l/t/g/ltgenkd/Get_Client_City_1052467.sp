#include <sourcemod>

public Plugin:myinfo = 
{
    name = "Get Client City",
    author = "SAMURAI",
    description = "",
    version = "1.0",
    url = "www.cs-utilz.net"
}

enum 
{
    a = 0,
    b,
    c,
    d
};

new String:g_szDataBlock[128];
new String:g_szLocationData[128];

public OnPluginStart()
{
    RegConsoleCmd("test_city",fn_cmdTest);
    
}

public OnConfigsExecuted()
{
    BuildPath(Path_SM,g_szDataBlock,sizeof(g_szDataBlock),"configs/geoip/GeoLiteCity-Blocks.csv");
    BuildPath(Path_SM,g_szLocationData,sizeof(g_szLocationData),"configs/geoip/GeoLiteCity-Location.csv");
}

public Action:fn_cmdTest(client,args)
{
    // get client IP
    new String:szIP[32];
    GetClientIP(client,szIP,sizeof(szIP),true);
    
    new iIP = ip_to_num(szIP); // we need IP in number format
    new iLoc = get_loc_id(iIP); // location id from number IP
    
    // now we get city
    new String:szCity[64];
    get_city(iLoc, szCity); 
    
    // printing
    PrintToChat(client,"I'm from City : %s (IP:%d | Locid:%d)", szCity, iIP, iLoc);
}



stock ip_to_num(const String:szIp[32])
{
    if(!szIp[0])
        return 0;
    
    new String:szTemp[4][16];
    str_piece(szIp, szTemp, sizeof szTemp, sizeof(szTemp[]), '.');
        
    new iIP;
    iIP = (16777216 * StringToInt(szTemp[a])) + (65536 * StringToInt(szTemp[b])) + (256 * StringToInt(szTemp[c])) + StringToInt(szTemp[d]);
    
    return iIP;
}


stock get_loc_id(iIP)
{
    new Handle:iFile = OpenFile(g_szDataBlock,"rt");
    
    new String:szBuffer[256], String:szTemp[3][64];
    new iLoc;
    while(!IsEndOfFile(iFile))
    {
        ReadFileLine(iFile, szBuffer, sizeof(szBuffer));
        
        TrimString(szBuffer);
        
        str_piece(szBuffer, szTemp, sizeof(szTemp), sizeof (szTemp[]), ',');
        
        for(new i = 0 ; i < 3 ; i++)
            StripQuotes(szTemp[i]);
        
        if(StringToInt(szTemp[0]) <= iIP <= StringToInt(szTemp[1]))
        {
            iLoc = StringToInt(szTemp[2]);
            break;
        }
    }
    CloseHandle(iFile);
    return iLoc;
}


stock get_city(iLocid, String:szCity[64])
{
    new Handle:iFile = OpenFile(g_szLocationData,"rt");
    
    new String:szBuffer[256], String:szTemp[10][64];
    while(!IsEndOfFile(iFile))
    {
        ReadFileLine(iFile, szBuffer, sizeof (szBuffer));
        TrimString(szBuffer);
        
        str_piece(szBuffer, szTemp, sizeof szTemp, sizeof(szTemp[]), ',');
        
        if((StringToInt(szTemp[0]) == iLocid))
        {
            StripQuotes(szTemp[3]);
            FormatEx(szCity, sizeof(szCity), "%s", szTemp[3]);
            break;
        }
    }
    CloseHandle(iFile);
}


stock str_piece(const String:input[], String:output[][], outputsize, piecelen, token = '|')
{
    new i = -1, pieces, len = -1 ;
    
    while ( input[++i] != 0 )
    {
        if ( input[i] != token )
        {
            if ( ++len < piecelen )
                output[pieces][len] = input[i] ;
        }
        else
        {
            output[pieces++][++len] = 0 ;
            len = -1 ;
            
            if ( pieces == outputsize )
                return pieces ;
        }
    }
    return pieces + 1;
}