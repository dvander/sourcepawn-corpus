#pragma semicolon 1

#include <sourcemod>
#include <colors>

new Handle:adTimer = INVALID_HANDLE;
new Handle:cvar_enabled = INVALID_HANDLE;
new Handle:cvar_ad_timer = INVALID_HANDLE;

new Handle:cvar_private_key = INVALID_HANDLE;
new Handle:cvar_public_key = INVALID_HANDLE;

new Float:adtime = 120.0;
new enabled = true;

public Plugin:myinfo = 
{
    name = "Scrap.TF",
    author = "Geel9 & Jessecar96",
    description = "Allows users to join the scrap.tf queue to sell weapons, keys, items, and junk",
    version = "1.4.0",
    url = "http://scrap.tf"
}

public OnPluginStart()
{
    //LoadTranslations("common.phrases");
    RegConsoleCmd("scrapbank", Command_ScrapBank);
    RegConsoleCmd("keybank", Command_KeyBank);
    RegConsoleCmd("hatbank", Command_HatBank);
    RegConsoleCmd("scrapbankinfo", Command_ScrapBankInfo);
    RegConsoleCmd("bank", Command_Bank);
    
    cvar_enabled = CreateConVar("scrap_enabled", "1", "If 1, players can type !scrapbank to scrap bank, or !keybank to keybank.", FCVAR_NOTIFY);
    cvar_ad_timer = CreateConVar("scrap_ad_time", "120", "If non-0, info about the scrapbank plugin will show every X seconds.", 0, true, 0.0, true, 300.0);
    
    cvar_private_key = CreateConVar("scrap_private_key", "", "The private API key you registered for your server on http://scrap.tf", FCVAR_PROTECTED);
    cvar_public_key = CreateConVar("scrap_public_key", "", "The public API key you registered for your server on http://scrap.tf", FCVAR_PROTECTED);
    
    adTimer = CreateTimer(180.0, Ad, _, TIMER_REPEAT);
    
    HookConVarChange(cvar_ad_timer, hook_ad);
    HookConVarChange(cvar_enabled, hook_enabled);
}

public hook_ad(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(adTimer != INVALID_HANDLE){
        KillTimer(adTimer);
        adTimer = INVALID_HANDLE;
    }
    adtime = GetConVarFloat(cvar_ad_timer);
    if(adtime > 0.0){
        adTimer = CreateTimer(adtime, Ad, _, TIMER_REPEAT);
    }
}

public hook_enabled(Handle:cvar, const String:oldVal[], const String:newVal[]){
    enabled = GetConVarBool(cvar_enabled);
}

public Action:Ad(Handle:timer){
    if(enabled)
        CPrintToChatAll("%s", "You can type {green}!bank{default} to do weapon, key, or hat banking via scrap.tf.");
    
    return Plugin_Continue;
}

public BankMenuHandler(Handle:menu, MenuAction:action, iClient, param)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param, info, sizeof(info));
		if(StrEqual(info,"scrap"))
		{
			ScrapBank(iClient);
		}
		else if(StrEqual(info,"hats"))
		{
			HatBank(iClient);
		}
		else if(StrEqual(info,"keys"))
		{
			KeyBank(iClient);
		}
		else if(StrEqual(info,"items"))
		{
			ItemBank(iClient);
		}
		else if(StrEqual(info,"junk"))
		{
			JunkBank(iClient);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		return;
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Command_Bank(iClient,iArgs)
{
	if(!enabled){
        return Plugin_Handled;
    }
	
	new Handle:menu = CreateMenu(BankMenuHandler);
	SetMenuTitle(menu, "Choose a banking option:");
	AddMenuItem(menu, "scrap", "Scrap Weapons");
	AddMenuItem(menu, "hats", "Sell Hats");
	AddMenuItem(menu, "keys", "Sell Keys");
	AddMenuItem(menu, "items", "Sell Items");
	AddMenuItem(menu, "junk", "Incinerate Items");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, iClient, 20);
	
	return Plugin_Handled;
}

public Action:Command_HatBank(iClient, iArgs)
{
    if(!enabled){
        return Plugin_Handled;
    }
    
    HatBank(iClient);
	
    return Plugin_Handled;
}

public Action:Command_ScrapBankInfo(iClient, iArgs)
{
    if(!enabled){
        return Plugin_Handled;
    }
    ShowWebPanel(iClient,"http://scrap.tf/help?plugin=1");
    return Plugin_Handled;
}

public Action:Command_ScrapBank(iClient, iArgs)
{
    if(!enabled){
        return Plugin_Handled;
    }
    
    ScrapBank(iClient);
	
    return Plugin_Handled;
}

public Action:Command_KeyBank(iClient, iArgs)
{
    if(!enabled){
        return Plugin_Handled;
    }
    
    KeyBank(iClient);
    
    return Plugin_Handled;
}


stock ShowWebPanel(client, String:url[])
{
	new Handle:Kv = CreateKeyValues("data");
	KvSetString(Kv, "title", "");
	KvSetString(Kv, "type", "2");
	KvSetString(Kv, "msg", url);
	KvSetNum(Kv, "customsvr", 1);
	ShowVGUIPanel(client, "info", Kv);
	CloseHandle(Kv);
}


// Banking Functions

stock ScrapBank(iClient)
{
    DoBank("scrap",iClient);
}

stock HatBank(iClient)
{
    DoBank("hats",iClient);
}

stock KeyBank(iClient)
{
    DoBank("keys",iClient);
}

stock ItemBank(iClient)
{
    DoBank("items",iClient);
}

stock JunkBank(iClient)
{
    DoBank("junk",iClient);
}

stock DoBank(String:type[], iClient)
{
    decl String:steamid[21], String:scrapurl[256];
    new String:communityid[18];
    
    decl String:privatekey[128], String:publickey[128];
    decl String:privateAndSteam[128], String:hashedKey[128];
    
    GetClientAuthString(iClient, steamid, sizeof(steamid));
    GetCommunityIDString(steamid, communityid, sizeof(communityid));
    
    GetConVarString(cvar_private_key, privatekey, sizeof(privatekey));
    GetConVarString(cvar_public_key, publickey, sizeof(publickey));
    
    if( !privatekey[0] ){
        //Private key wasn't set
        PrintToChatAll("The private API key cvar scrap_private_key hasn't been set for this server. Go to http://scrap.tf/api.php to get an API key.");
        return;
    }
    
    if( !publickey[0] ){
        //Public key wasn't set
        PrintToChatAll("The public API key cvar scrap_public_key hasn't been set for this server. Go to http://scrap.tf/api.php to get an API key.");
        return;
    }
    
    Format(privateAndSteam, sizeof(privateAndSteam), "%s%s", privatekey, communityid);
    
    MD5String(privateAndSteam, hashedKey, sizeof(hashedKey));
    
    //Send to the server:
    //-Steamid (64-bit)
    //-Public key
    //-MD5(Private key + steamid)
    //This is to protect against people fraudulently registering other people for the queue.
    
    Format(scrapurl, sizeof(scrapurl), "http://scrap.tf/?steamid=%s&publickey=%s&hash=%s&m=%s", communityid, publickey, hashedKey, type);
    
    ShowWebPanel(iClient,scrapurl);
}

stock bool:GetCommunityIDString(const String:SteamID[], String:CommunityID[], const CommunityIDSize)
{
    new Identifier[17] = {7, 6, 5, 6, 1, 1, 9, 7, 9, 6, 0, 2, 6, 5, 7, 2, 8};
    decl String:SteamIDParts[3][11];
    
    if (ExplodeString(SteamID, ":", SteamIDParts, sizeof(SteamIDParts), sizeof(SteamIDParts[])) != 3)
    {
        strcopy(CommunityID, CommunityIDSize, "");
        return false;
    }
    
    new SteamIDNumber[CommunityIDSize - 1];
    for (new i = 0; i < strlen(SteamIDParts[2]); i++)
    {
        SteamIDNumber[CommunityIDSize - 2 - i] = SteamIDParts[2][strlen(SteamIDParts[2]) - 1 - i] - 48;
    }

    new Current, CarryOver;
    for (new i = (sizeof(Identifier) - 1); i > -1 ; i--)
    {
        Current = Identifier[i] + (2 * SteamIDNumber[i]) + CarryOver;
        if (i == sizeof(Identifier) - 1 && strcmp(SteamIDParts[1], "1") == 0)
        {
            Current++;
        }

        CarryOver = Current/10;
        Current %= 10;

        SteamIDNumber[i] = Current;
        CommunityID[i] = SteamIDNumber[i] + 48;
    }
    CommunityID[CommunityIDSize - 1] = '\0';
    return true;
}

stock MD5String(const String:str[], String:output[], maxlen)
{
    decl x[2];
    decl buf[4];
    decl input[64];
    new i, ii;
    
    new len = strlen(str);
    
    // MD5Init
    x[0] = x[1] = 0;
    buf[0] = 0x67452301;
    buf[1] = 0xefcdab89;
    buf[2] = 0x98badcfe;
    buf[3] = 0x10325476;
    
    // MD5Update
    new in[16];

    in[14] = x[0];
    in[15] = x[1];
    
    new mdi = (x[0] >>> 3) & 0x3F;
    
    if ((x[0] + (len << 3)) < x[0])
    {
        x[1] += 1;
    }
    
    x[0] += len << 3;
    x[1] += len >>> 29;
    
    new c = 0;
    while (len--)
    {
        input[mdi] = str[c];
        mdi += 1;
        c += 1;
        
        if (mdi == 0x40)
        {
            for (i = 0, ii = 0; i < 16; ++i, ii += 4)
            {
                in[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
            }
            // Transform
            MD5Transform(buf, in);
            
            mdi = 0;
        }
    }
    
    // MD5Final
    new padding[64] = {
        0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    };
    new inx[16];
    inx[14] = x[0];
    inx[15] = x[1];
    
    mdi = (x[0] >>> 3) & 0x3F;
    
    len = (mdi < 56) ? (56 - mdi) : (120 - mdi);
    in[14] = x[0];
    in[15] = x[1];
    
    mdi = (x[0] >>> 3) & 0x3F;
    
    if ((x[0] + (len << 3)) < x[0])
    {
        x[1] += 1;
    }
    
    x[0] += len << 3;
    x[1] += len >>> 29;
    
    c = 0;
    while (len--)
    {
        input[mdi] = padding[c];
        mdi += 1;
        c += 1;
        
        if (mdi == 0x40)
        {
            for (i = 0, ii = 0; i < 16; ++i, ii += 4)
            {
                in[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
            }
            // Transform
            MD5Transform(buf, in);
            
            mdi = 0;
        }
    }
    
    for (i = 0, ii = 0; i < 14; ++i, ii += 4)
    {
        inx[i] = (input[ii + 3] << 24) | (input[ii + 2] << 16) | (input[ii + 1] << 8) | input[ii];
    }
    MD5Transform(buf, inx);
    
    new digest[16];
    for (i = 0, ii = 0; i < 4; ++i, ii += 4)
    {
        digest[ii] = (buf[i]) & 0xFF;
        digest[ii + 1] = (buf[i] >>> 8) & 0xFF;
        digest[ii + 2] = (buf[i] >>> 16) & 0xFF;
        digest[ii + 3] = (buf[i] >>> 24) & 0xFF;
    }
    
    FormatEx(output, maxlen, "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
        digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
        digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]);
}

stock MD5Transform_FF(&a, &b, &c, &d, x, s, ac)
{
    a += (((b) & (c)) | ((~b) & (d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

stock MD5Transform_GG(&a, &b, &c, &d, x, s, ac)
{
    a += (((b) & (d)) | ((c) & (~d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

stock MD5Transform_HH(&a, &b, &c, &d, x, s, ac)
{
    a += ((b) ^ (c) ^ (d)) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

stock MD5Transform_II(&a, &b, &c, &d, x, s, ac)
{
    a += ((c) ^ ((b) | (~d))) + x + ac;
    a = (((a) << (s)) | ((a) >>> (32-(s))));
    a += b;
}

stock MD5Transform(buf[], in[])
{
    new a = buf[0];
    new b = buf[1];
    new c = buf[2];
    new d = buf[3];
    
    MD5Transform_FF(a, b, c, d, in[0], 7, 0xd76aa478);
    MD5Transform_FF(d, a, b, c, in[1], 12, 0xe8c7b756);
    MD5Transform_FF(c, d, a, b, in[2], 17, 0x242070db);
    MD5Transform_FF(b, c, d, a, in[3], 22, 0xc1bdceee);
    MD5Transform_FF(a, b, c, d, in[4], 7, 0xf57c0faf);
    MD5Transform_FF(d, a, b, c, in[5], 12, 0x4787c62a);
    MD5Transform_FF(c, d, a, b, in[6], 17, 0xa8304613);
    MD5Transform_FF(b, c, d, a, in[7], 22, 0xfd469501);
    MD5Transform_FF(a, b, c, d, in[8], 7, 0x698098d8);
    MD5Transform_FF(d, a, b, c, in[9], 12, 0x8b44f7af);
    MD5Transform_FF(c, d, a, b, in[10], 17, 0xffff5bb1);
    MD5Transform_FF(b, c, d, a, in[11], 22, 0x895cd7be);
    MD5Transform_FF(a, b, c, d, in[12], 7, 0x6b901122);
    MD5Transform_FF(d, a, b, c, in[13], 12, 0xfd987193);
    MD5Transform_FF(c, d, a, b, in[14], 17, 0xa679438e);
    MD5Transform_FF(b, c, d, a, in[15], 22, 0x49b40821);
    
    MD5Transform_GG(a, b, c, d, in[1], 5, 0xf61e2562);
    MD5Transform_GG(d, a, b, c, in[6], 9, 0xc040b340);
    MD5Transform_GG(c, d, a, b, in[11], 14, 0x265e5a51);
    MD5Transform_GG(b, c, d, a, in[0], 20, 0xe9b6c7aa);
    MD5Transform_GG(a, b, c, d, in[5], 5, 0xd62f105d);
    MD5Transform_GG(d, a, b, c, in[10], 9, 0x02441453);
    MD5Transform_GG(c, d, a, b, in[15], 14, 0xd8a1e681);
    MD5Transform_GG(b, c, d, a, in[4], 20, 0xe7d3fbc8);
    MD5Transform_GG(a, b, c, d, in[9], 5, 0x21e1cde6);
    MD5Transform_GG(d, a, b, c, in[14], 9, 0xc33707d6);
    MD5Transform_GG(c, d, a, b, in[3], 14, 0xf4d50d87);
    MD5Transform_GG(b, c, d, a, in[8], 20, 0x455a14ed);
    MD5Transform_GG(a, b, c, d, in[13], 5, 0xa9e3e905);
    MD5Transform_GG(d, a, b, c, in[2], 9, 0xfcefa3f8);
    MD5Transform_GG(c, d, a, b, in[7], 14, 0x676f02d9);
    MD5Transform_GG(b, c, d, a, in[12], 20, 0x8d2a4c8a);
    
    MD5Transform_HH(a, b, c, d, in[5], 4, 0xfffa3942);
    MD5Transform_HH(d, a, b, c, in[8], 11, 0x8771f681);
    MD5Transform_HH(c, d, a, b, in[11], 16, 0x6d9d6122);
    MD5Transform_HH(b, c, d, a, in[14], 23, 0xfde5380c);
    MD5Transform_HH(a, b, c, d, in[1], 4, 0xa4beea44);
    MD5Transform_HH(d, a, b, c, in[4], 11, 0x4bdecfa9);
    MD5Transform_HH(c, d, a, b, in[7], 16, 0xf6bb4b60);
    MD5Transform_HH(b, c, d, a, in[10], 23, 0xbebfbc70);
    MD5Transform_HH(a, b, c, d, in[13], 4, 0x289b7ec6);
    MD5Transform_HH(d, a, b, c, in[0], 11, 0xeaa127fa);
    MD5Transform_HH(c, d, a, b, in[3], 16, 0xd4ef3085);
    MD5Transform_HH(b, c, d, a, in[6], 23, 0x04881d05);
    MD5Transform_HH(a, b, c, d, in[9], 4, 0xd9d4d039);
    MD5Transform_HH(d, a, b, c, in[12], 11, 0xe6db99e5);
    MD5Transform_HH(c, d, a, b, in[15], 16, 0x1fa27cf8);
    MD5Transform_HH(b, c, d, a, in[2], 23, 0xc4ac5665);

    MD5Transform_II(a, b, c, d, in[0], 6, 0xf4292244);
    MD5Transform_II(d, a, b, c, in[7], 10, 0x432aff97);
    MD5Transform_II(c, d, a, b, in[14], 15, 0xab9423a7);
    MD5Transform_II(b, c, d, a, in[5], 21, 0xfc93a039);
    MD5Transform_II(a, b, c, d, in[12], 6, 0x655b59c3);
    MD5Transform_II(d, a, b, c, in[3], 10, 0x8f0ccc92);
    MD5Transform_II(c, d, a, b, in[10], 15, 0xffeff47d);
    MD5Transform_II(b, c, d, a, in[1], 21, 0x85845dd1);
    MD5Transform_II(a, b, c, d, in[8], 6, 0x6fa87e4f);
    MD5Transform_II(d, a, b, c, in[15], 10, 0xfe2ce6e0);
    MD5Transform_II(c, d, a, b, in[6], 15, 0xa3014314);
    MD5Transform_II(b, c, d, a, in[13], 21, 0x4e0811a1);
    MD5Transform_II(a, b, c, d, in[4], 6, 0xf7537e82);
    MD5Transform_II(d, a, b, c, in[11], 10, 0xbd3af235);
    MD5Transform_II(c, d, a, b, in[2], 15, 0x2ad7d2bb);
    MD5Transform_II(b, c, d, a, in[9], 21, 0xeb86d391);
    
    buf[0] += a;
    buf[1] += b;
    buf[2] += c;
    buf[3] += d;
}  
