#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <colors>

#pragma semicolon 1
#pragma newdecls required

Handle cookie;

int GlowType[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "[L4D2] Glow Survivor",
    author = "King_OXO (edited, now have cookie)",
    description = "Provides Glows for survivors.",
    version = "5.0.0",
    url = "https://forums.alliedmods.net/showthread.php?t=332956"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only supports Left 4 Dead 2");

        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_spawn", 	Event_Player_Spawn);
	HookEvent("player_death", 	Event_Player_Death);
	HookEvent("player_afk", 	Event_PlayerAFK);
	HookEvent("player_team", 	Event_PlayerTeam, EventHookMode_Pre);

	RegConsoleCmd("sm_aura", SetAura, "Set your aura.");
	RegConsoleCmd("sm_glow", SetAura, "Set your aura.");
	cookie = RegClientCookie("l4d2_glow", "cookie for aura id", CookieAccess_Private);
}

public void Event_Player_Spawn(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId( hEvent.GetInt( "userid" ));
	if( client && IsClientInGame( client ))
		CreateTimer( 0.3, PlayerSpawnTimer, GetClientUserId( client ), TIMER_FLAG_NO_MAPCHANGE );
}

public Action PlayerSpawnTimer( Handle hTimer, any UserID )
{
	int client = GetClientOfUserId( UserID );
	if( client <= 0 || IsClientConnected( client ) != true )
		return;
	
	if( GetClientTeam( client ) == 2 && IsPlayerGhost( client ) != true )
	{
		ReadCookies(client);
	}
	else if( GetClientTeam( client ) == 3 )
	{
		DisableGlow( client );
	}
}

public void Event_Player_Death(Event hEvent, const char[] name, bool dontBroadcast)
{
	DisableGlow( GetClientOfUserId( hEvent.GetInt("userid")) );
}

public void Event_PlayerAFK( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	DisableGlow( GetClientOfUserId( hEvent.GetInt("userid")) );
}

public void Event_PlayerTeam(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId (hEvent.GetInt("userid"));
	int iTeam = hEvent.GetInt("team");
	if( iTeam == 3 ) 
		DisableGlow( client );
}

void DisableGlow( int client )
{
	if( IsValidClient( client ))
	{		
		SetEntProp( client, Prop_Send, "m_iGlowType", 0 );
		SetEntProp( client, Prop_Send, "m_bFlashing", 0 );
		SetEntProp( client, Prop_Send, "m_nGlowRange",0 );
		SetEntProp( client, Prop_Send, "m_glowColorOverride", 0 );
		
		SDKUnhook( client, SDKHook_PreThink, RainbowPlayer );
	}
}

public void OnClientPostAdminCheck(int client)
{
    if( AreClientCookiesCached( client ) && GetClientTeam( client ) == 2 )
        ReadCookies(client);
}

public void ReadCookies(int client)
{
    if( IsValidClient( client ) != true || IsFakeClient( client ) == true  || IsClientAuthorized (client ) != true || IsClientConnected( client ) != true )
        return;
    
    char str[4];
    
    GetClientCookie(client, cookie, str, 4);
    if(strcmp(str, "") != 0)
		GetAura(client, StringToInt(str));
}
/**************************************************************************/
stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	
	return false;
}

stock bool IsPlayerGhost( int client )
{
	if( GetEntProp( client, Prop_Send, "m_isGhost", 1 ) ) 
		return true;
	
	return false;
}   
/**************************************************************************/
public Action SetAura(int client, int args)
{
    if( IsValidClient( client ) != true || IsPlayerAlive( client ) != true )
    {
        CPrintToChat(client, "{blue}[{default}GLOW MENU{blue}] {olive}You must be {blue}alive {default}to use this {green}command {default}!");
        return Plugin_Handled;
    }
    
    BuildMenu( client );

    return Plugin_Handled;
}

void BuildMenu( int client )
{
    Menu menu = new Menu( VIPAuraMenuHandler );
    menu.SetTitle("|★| GLOW MENU |★|\n▼▼▼▼▼▼▼▼▼▼\n ");
	
    menu.AddItem("option0", "Desactive\n ", GlowType[client] == 0 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option1", "Green", GlowType[client] == 1 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option2", "Blue", GlowType[client] == 2 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option3", "Violet", GlowType[client] == 3 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option4", "Cyan", GlowType[client] == 4 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option5", "Orange", GlowType[client] == 5 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option6", "Red", GlowType[client] == 6 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option7", "Gray", GlowType[client] == 7 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option8", "Yellow", GlowType[client] == 8 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option9", "Lime", GlowType[client] == 9 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option10", "Maroon", GlowType[client] == 10 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option11", "Teal", GlowType[client] == 11 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option12", "Pink", GlowType[client] == 12 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option13", "Purple", GlowType[client] == 13 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option14", "White", GlowType[client] == 14 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option15", "Golden", GlowType[client] == 15 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    menu.AddItem("option16", "Rainbow", GlowType[client] == 16 ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int VIPAuraMenuHandler(Menu menu, MenuAction action, int param1, int param2) 
{
    switch (action) 
    {
        case MenuAction_End:
            delete menu;
        case MenuAction_Select: 
        {
            if (!IsPlayerAlive(param1)) 
            {
                CPrintToChat(param1, "[SM] You must be alive to set your aura.");
                return 0;
            }

            GetAura(param1, param2);
            SetCookie(param1, cookie, param2);
			
            BuildMenu( param1 );
        }
    }

    return 0;
}


public void SetCookie(int client, Handle hCookie, int n)
{
    char[] strCookie = new char[4];
    
    IntToString(n, strCookie, 4);
    SetClientCookie(client, hCookie, strCookie);
}

void GetAura(int client, int id) 
{
    switch (id) 
    {
        case 0: 
        {    
            DisableGlow( client );
            GlowType[client] = id;
//          PrintToChat(client, "\x05You have turned off the Glow");
            return;
        }
        case 1: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (255 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Green {orange}!");
        }
        case 2: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 7 + (19 * 256) + (250 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Blue {orange}!");
        }
        case 3: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (19 * 256) + (250 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Violet {orange}!");
        }
        case 4: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 66 + (250 * 256) + (250 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Cyan {orange}!");
        }
        case 5: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 249 + (155 * 256) + (84 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Orange {orange}!");
        }
        case 6: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Red {orange}!");
        }
        case 7: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 50 + (50 * 256) + (50 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Gray {orange}!");
        }
        case 8: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (255 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Yellow {orange}!");
        }
        case 9: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (255 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Lime {orange}!");
        }
        case 10: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 128 + (0 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Maroon {orange}!");
        }
        case 11: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 + (128 * 256) + (128 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Teal {orange}!");
        }
        case 12:
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (0 * 256) + (150 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Pink {orange}!");
        }
        case 13:
        {        
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 155 + (0 * 256) + (255 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Purple {orange}!");
        }
        case 14: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", -1 + (-1 * 256) + (-1 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04White {orange}!");
        }
        case 15: 
        {
            SetEntProp(client, Prop_Send, "m_glowColorOverride", 255 + (155 * 256) + (0 * 65536));
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Golden {orange}!");
        }
        case 16: 
        {
            SDKHook(client, SDKHook_PreThink, RainbowPlayer);
            CPrintToChat(client, "\x05You \x04Changed \x03Color\x01: \x04Rainbow {orange}!");
        }
    }

    if (0 <= id <= 15) 
    {
        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
        SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
        SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
		
        SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
    }
    
    GlowType[client] = id;
}

public Action RainbowPlayer(int client)
{
	if( IsValidClient( client ) != true || IsPlayerAlive(client) != true || GetClientTeam( client ) == 3 )
	{
		SDKUnhook(client, SDKHook_PreThink, RainbowPlayer);
		
		if( IsPlayerGhost( client ) || GetClientTeam( client ) == 3 )
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
		}
		
		return;
	}
    
	SetEntProp(client, Prop_Send, "m_glowColorOverride", RoundToNearest(Cosine((GetGameTime() * 8.0) + client + 1) * 127.5 + 127.5) + (RoundToNearest(Cosine((GetGameTime() * 8.0) + client + 3) * 127.5 + 127.5) * 256) + (RoundToNearest(Cosine((GetGameTime() * 8.0) + client + 5) * 127.5 + 127.5) * 65536));
	SetEntProp(client, Prop_Send, "m_iGlowType", 3);
	SetEntProp(client, Prop_Send, "m_nGlowRange", 99999);
	SetEntProp(client, Prop_Send, "m_nGlowRangeMin", 0);
}