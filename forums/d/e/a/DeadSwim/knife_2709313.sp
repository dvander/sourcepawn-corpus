#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <fpvm_interface>

#pragma tabsize 0
#pragma semicolon 1

int money[24];
int iKnife1,iKnife2,iKnife3;

int u_knife1[64];
int u_knife2[64];
int u_knife3[64];
int u_morehp[64];
int u_heal[64];
int s_hud[64];

int a_can[64];
int a_nothing[64];
int a_moremoney[64];
int a_lowmoney[64];

Handle syn;

ConVar g_iBackStab;
ConVar g_i35hp;
ConVar g_iShop;
ConVar g_iAbe;
ConVar g_iSettings;
ConVar g_iSecure;
ConVar g_iHpc;
ConVar g_iHphc;
ConVar g_iKnife1c;
ConVar g_iKnife2c;
ConVar g_iKnife3c;

#define PLUGIN_VERSION "1.0"


public OnPluginStart()
{	
	g_iBackStab = CreateConVar("knife_back", "0", "enable / disable Anti-backstab");
    g_i35hp = CreateConVar("knife_35hp", "0", "enable / disable Only 35 HP");
    g_iShop = CreateConVar("knife_shop", "1", "enable / disable Shop");
    g_iAbe = CreateConVar("knife_abe", "1", "enable / disable abilities");
    g_iSettings = CreateConVar("knife_settings", "1", "enable / disable settings for players");
    g_iSecure = CreateConVar("knife_secure", "1", "enable / disable buy and get weapon");
    // Cost in shop
        // Items
    g_iHpc = CreateConVar("knife_Hpc", "4", "Cost more HP");
    g_iHphc = CreateConVar("knife_heal", "2", "Cost Heal");
        // Knifes
    g_iKnife1c = CreateConVar("knife_1c", "5", "Cost knife 1");
    g_iKnife2c = CreateConVar("knife_2c", "8", "Cost knife 2");
    g_iKnife3c = CreateConVar("knife_3c", "10", "Cost knife 3");

	AutoExecConfig(true, "knife_mod");
	
    syn = CreateHudSynchronizer();
    CreateTimer(1.0, hud, _, TIMER_REPEAT);

    HookEvent("round_end", ERound); 
	HookEvent("player_spawn", SClient);
	HookEvent("player_death", DClient);
    HookEvent("round_start", SRound, EventHookMode_PostNoCopy);

    RegConsoleCmd("sm_menu", Showmenus); 
    RegConsoleCmd("sm_adminmenu", Showadmin); 
    RegConsoleCmd("sm_shop", Showshop); 
    RegConsoleCmd("sm_settings", Showsettings);
    RegConsoleCmd("sm_abilities", Showabe); 
}

public void ERound(Handle event, const char[] sName, bool bDontBroadcast) 
{     
    // Restart Bought items
    for (int i = 1; i <= MaxClients; i++)
    {
        u_knife1[i] = 0;
        u_knife2[i] = 0;
        u_knife3[i] = 0;

        FPVMI_RemoveViewModelToClient(i, "weapon_knife");
        FPVMI_RemoveWorldModelToClient(i, "weapon_knife");
    }
}	

public void SRound(Event event, const char[] name, bool dontBroadcast) 
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(GetConVarBool(g_iAbe))
    {
        if(a_lowmoney[client] == 1)
        {
            lowmoney(client);
        }
        if(a_moremoney[client] == 1)
        {
            moremoney(client);
        }
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if(GetConVarBool(g_iAbe))
        {
            a_can[i] = 1;
        }
    }
}

public void DClient(Event event, const char[] name, bool dontBroadcast) 
{
	int attacker = GetClientOfUserId(event.GetInt("attacker")); 
    if(GetConVarBool(g_iShop))
    {
        if(GetConVarBool(g_iAbe))
        {
            if(a_lowmoney[attacker])
            {
                PrintToChat(attacker, " \x04[Knife] \x01You dosen't get money.");
            }
            if(a_moremoney[attacker])
            {
                money[attacker] = money[attacker] + 2;
                PrintToChat(attacker, " \x04[Knife] \x01You got +2 money to /shop.");
            }else{
                money[attacker]++;
                PrintToChat(attacker, " \x04[Knife] \x01You got +1 money to /shop.");
            }
        }else{
        money[attacker]++;
        PrintToChat(attacker, " \x04[Knife] \x01You got +1 money to /shop.");
        }
    }
}

public void SClient(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    // Set 35 HP
    if(GetConVarBool(g_i35hp))
    {
        if(!IsFakeClient(client))
        {
            if(IsPlayerAlive(client))
            {
                SetEntityHealth(client, 35);
                PrintToChat(client, " \x04[Knife] \x01You have been set to 35 HP.");
            }
        }
    }
    // Secure weapons get and buy
    if(GetConVarBool(g_iSecure))
    {
        if(IsClientInGame(client))
        {
            if(IsPlayerAlive(client))
            {
                RemoveAllWeapon(client);
                SetEntProp(client, Prop_Send, "m_iAccount", 0);
                GivePlayerItem(client, "weapon_knife");
            }
        }
    }
}

public OnMapStart()
{
    // Knife Precache
    // Mad Can
    iKnife1 = PrecacheModel("models/weapons/eminem/mad_can/v_mad_can.mdl");
    // Old Cleaver
    iKnife2 = PrecacheModel("models/weapons/eminem/old_cleaver/v_old_cleaver.mdl");
    // Wooden Jutte
    iKnife3 = PrecacheModel("models/weapons/eminem/wooden_jutte/v_wooden_jutte.mdl");
    // Models Precache
    // Marcusreed
    PrecacheModel("models/player/custom_player/hekut/marcusreed/marcusreed.mdl");
}

public Action hud(Handle timer, int client)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (!IsClientObserver(i))
            {
                if(s_hud[i] == 1)
                {
                    SetHudTextParams(-1.0, -0.01, 1.0, 255, 0, 0, 255, 0, 0.0, 0.25, 0.25);
                    ShowSyncHudText(i, syn, "⤑ You have ➢ %i Money | HP ➢ %i ⬸", money[i], GetClientHealth(i));
                }
            }
        }
    }
}

public void OnClientPutInServer(int client)
{
    // Anti Backstab
    if(GetConVarBool(g_iBackStab))
	{
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    } 
    // Turn on abilities
    if(GetConVarBool(g_iAbe))
	{
        a_can[client] = 0;
        a_nothing[client] = 1;
    } 
    // Money in shop
    if(GetConVarBool(g_iShop))
	{
        money[client] = 0;
    } 
    if(s_hud[client] == 0)
    {
        s_hud[client] = 1;
    }
}

// Menus
public Action Showmenus(int client, int args)
{
    Menus(client);
    return Plugin_Handled;
}

public void Menus(int client)
{
	char text[64];
	
	Panel panel = CreatePanel();
        Format(text, sizeof(text), "[Menu]");
		panel.SetTitle(text);
        if (ClientIsAdmin(client))
        {
            Format(text, sizeof(text), "Admin Menu");
		    panel.DrawItem(text);
            Format(text, sizeof(text), "⤑ Here you can edit game mode!");
            panel.DrawText(text);
        }

        if (GetConVarBool(g_iSettings))
        {
            Format(text, sizeof(text), "Settings");
		    panel.DrawItem(text);
            Format(text, sizeof(text), "⤑ Here you can edit your Hud and any more!");
            panel.DrawText(text);
        }

        if (GetConVarBool(g_iShop))
        {
            Format(text, sizeof(text), "Shop");
		    panel.DrawItem(text);
            Format(text, sizeof(text), "⤑ Here you can buy Knifes and Items!");
            panel.DrawText(text);
        }

        if (GetConVarBool(g_iAbe))
        {
            Format(text, sizeof(text), "Abilities");
		    panel.DrawItem(text);
            Format(text, sizeof(text), "⤑ Here you can select your abilities!");
            panel.DrawText(text);
        }

	panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
	
	panel.DrawItem("Exit");
	panel.Send(client, MenuMenuHandler, MENU_TIME_FOREVER);
	delete panel;
}

public int MenuMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsPlayerAlive(param1))
		{
			switch (param2)
			{
                case 1:
				{
                    Admin(param1);
				}
				case 2:
				{
                    Settings(param1);
				}
				case 3:
				{
                    Shop(param1);
				}
				case 4:
				{
                    Abe(param1);
				}
				case 9:
				{
					return;
				}
			}
		}
		else
		{
			delete menu;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action Showadmin(int client, int args)
{
    if(ClientIsAdmin(client))
    {
        Admin(client);
        return Plugin_Handled;
    }else{
        PrintToChat(client," \x04[Knife] \x01You don't have permission for this command!");
    }
    return Plugin_Handled;
}

public void Admin(int client)
{
	char text[64];
	
	Panel panel = CreatePanel();
        Format(text, sizeof(text), "[Admin Menu]");
		panel.SetTitle(text);

        if (GetConVarBool(g_iSettings))
        {
            Format(text, sizeof(text), "✔ ‒ Turn OFF player Settings");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "✘ ‒ Turn ON player Settings");
		    panel.DrawItem(text);
        }

        if (GetConVarBool(g_iShop))
        {
            Format(text, sizeof(text), "✔ ‒ Turn OFF Shop and Money");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "✘ ‒ Turn ON Shop and Money");
		    panel.DrawItem(text);
        }

        if (GetConVarBool(g_iAbe))
        {
            Format(text, sizeof(text), "✔ ‒ Turn OFF Abilities");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "✘ ‒ Turn ON Abilities");
		    panel.DrawItem(text);
        }

        if (GetConVarBool(g_i35hp))
        {
            Format(text, sizeof(text), "✔ ‒ Turn OFF 35 HP");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "✘ ‒ Turn ON 35 HP");
		    panel.DrawItem(text);
        }

        if (GetConVarBool(g_iBackStab))
        {
            Format(text, sizeof(text), "✔ ‒ Turn OFF Anti-Backstab");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "✘ ‒ Turn ON Anti-Backstab");
		    panel.DrawItem(text);
        }

        if (GetConVarBool(g_iSecure))
        {
            Format(text, sizeof(text), "✔ ‒ Turn OFF Secure");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "✘ ‒ Turn ON Secure");
		    panel.DrawItem(text);
        }

    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
	
	panel.DrawItem("Exit");
	panel.Send(client, AdminMenuHandler, MENU_TIME_FOREVER);
	delete panel;
}

public int AdminMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsPlayerAlive(param1))
		{
			switch (param2)
			{
				case 1:
				{
                    if (GetConVarBool(g_iSettings))
                    {
                        FindConVar("knife_settings").SetInt(0);
                    }else{
                        FindConVar("knife_settings").SetInt(1);
                    }
				}
				case 2:
				{
                    if (GetConVarBool(g_iShop))
                    {
                        FindConVar("knife_shop").SetInt(0);
                    }else{
                        FindConVar("knife_shop").SetInt(1);
                    }
				}
				case 3:
				{
                    if (GetConVarBool(g_iAbe))
                    {
                        FindConVar("knife_abe").SetInt(0);
                    }else{
                        FindConVar("knife_abe").SetInt(1);
                    }
				}
				case 4:
				{
                    if (GetConVarBool(g_i35hp))
                    {
                        FindConVar("knife_35hp").SetInt(0);
                    }else{
                        FindConVar("knife_35hp").SetInt(1);
                    }
				}
				case 5:
				{
                    if (GetConVarBool(g_iBackStab))
                    {
                        FindConVar("knife_back").SetInt(0);
                    }else{
                        FindConVar("knife_back").SetInt(1);
                    }
				}
				case 6:
				{
                    if (GetConVarBool(g_iSecure))
                    {
                        FindConVar("knife_secure").SetInt(0);
                    }else{
                        FindConVar("knife_secure").SetInt(1);
                    }
				}
				case 9:
				{
					return;
				}
			}
		}
		else
		{
			delete menu;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action Showshop(int client, int args)
{
    if(GetConVarBool(g_iShop))
    {
        if(IsPlayerAlive(client))
        {
            Shop(client);
            return Plugin_Handled;
        }else{
            PrintToChat(client, " \x04[Knife] \x01You must be alive!");
        }
    }
    return Plugin_Handled;
}

public void Shop(int client)
{
	char text[64];
	
	Panel panel = CreatePanel();
        Format(text, sizeof(text), "[Shop] You have %i", money[client]);
		panel.SetTitle(text);

        // Knife 1
        if(u_knife1[client] == 0)
        {
            Format(text, sizeof(text), "Mad Can [ Cost %i ]", g_iKnife1c.IntValue);
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "Mad Can [ Cost %i ]", g_iKnife1c.IntValue);
		    panel.DrawItem(text, ITEMDRAW_DISABLED);
        }
		Format(text, sizeof(text), "⤑ You get more speed!");
		panel.DrawText(text);
        // Knife 2
        if(u_knife2[client] == 0)
        {
            Format(text, sizeof(text), "Old Cleaver [ Cost %i ]", g_iKnife2c.IntValue);
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "Old Cleaver [ Cost %i ]", g_iKnife2c.IntValue);
            panel.DrawItem(text, ITEMDRAW_DISABLED);
        }
		Format(text, sizeof(text), "⤑ You get more speed and gravity!");
		panel.DrawText(text);
        // Knife 3
        if(u_knife3[client] == 0)
        {
            Format(text, sizeof(text), "Wooden Jutte [ Cost %i ]", g_iKnife3c.IntValue);
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "Wooden Jutte [ Cost %i ]", g_iKnife3c.IntValue);
            panel.DrawItem(text, ITEMDRAW_DISABLED);
        }
		Format(text, sizeof(text), "⤑ You get more speed and health!");
        panel.DrawText(text);
        // More HP (50)
        if(u_morehp[client] == 0)
        {
            Format(text, sizeof(text), "More HP [ Cost %i ]", g_iHpc.IntValue);
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "More HP [ Cost %i ]", g_iHpc.IntValue);
            panel.DrawItem(text, ITEMDRAW_DISABLED);
        }
		Format(text, sizeof(text), "⤑ You get more HP (+50 HP)");
		panel.DrawText(text);
        // Heal
        if(u_heal[client] == 0)
        {
            Format(text, sizeof(text), "Heal [ Cost %i ]", g_iHphc.IntValue);
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "Heal [ Cost %i ]", g_iHphc.IntValue);
            panel.DrawItem(text, ITEMDRAW_DISABLED);
        }
		Format(text, sizeof(text), "⤑ You get HEAL!");
		panel.DrawText(text);

	panel.DrawItem("", ITEMDRAW_NOTEXT);
	panel.DrawItem("Back");
	panel.DrawItem("", ITEMDRAW_NOTEXT);
	
	panel.DrawItem("Exit");
	panel.Send(client, ShopMenuHandler, MENU_TIME_FOREVER);
	delete panel;
}
public int ShopMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsPlayerAlive(param1))
		{
			switch (param2)
			{
				case 1:
				{
                    if(money[param1] >= g_iKnife1c.IntValue)
                    {
                        if(u_knife1[param1] == 0)
                        {
                            // Set knife is bought
                            u_knife1[param1] = 1;
                            // Set new money
                            int set_money = money[param1] - g_iKnife1c.IntValue;
                            money[param1] = set_money;

                            float zjisti_speed = GetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue");
                            float novy_speed = zjisti_speed + 0.5;
                            SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", novy_speed);

                            // Set knife model

                            FPVMI_AddViewModelToClient(param1, "weapon_knife", iKnife1);
                            FPVMI_AddWorldModelToClient(param1, "weapon_knife", iKnife1);

                            PrintToChat(param1," \x04[Knife] \x01You bought a knife Mad Can!");
                        }
                    }
				}
				case 2:
				{
                    if(money[param1] >= g_iKnife2c.IntValue)
                    {
                        if(u_knife2[param1] == 0)
                        {
                            // Set knife is bought
                            u_knife2[param1] = 1;
                            // Set new money
                            int set_money = money[param1] - g_iKnife2c.IntValue;
                            money[param1] = set_money;

                            float zjisti_speed = GetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue");
                            float novy_speed = zjisti_speed + 0.3;
                            SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", novy_speed);

                            SetEntityGravity(param1, 200);

                            // Set knife model

                            FPVMI_AddViewModelToClient(param1, "weapon_knife", iKnife2);
                            FPVMI_AddWorldModelToClient(param1, "weapon_knife", iKnife2);

                            PrintToChat(param1," \x04[Knife] \x01You bought a knife Mad Can!");
                        }
                    }
                }
				case 3:
				{
                    if(money[param1] >= g_iKnife3c.IntValue)
                    {
                        if(u_knife3[param1] == 0)
                        {
                            // Set knife is bought
                            u_knife3[param1] = 1;
                            // Set new money
                            int set_money = money[param1] - g_iKnife3c.IntValue;
                            money[param1] = set_money;

                            float zjisti_speed = GetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue");
                            float novy_speed = zjisti_speed + 0.3;
                            SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", novy_speed);

                            int health = GetEntProp(param1, Prop_Send, "m_iHealth");
	                        int nowhealth = health + 15;
	                        SetEntityHealth(param1, nowhealth);

                            // Set knife model

                            FPVMI_AddViewModelToClient(param1, "weapon_knife", iKnife3);
                            FPVMI_AddWorldModelToClient(param1, "weapon_knife", iKnife3);

                            PrintToChat(param1," \x04[Knife] \x01You bought a knife Wooden Jutte!");
                        }
                    }
				}
				case 4:
				{
                    if(money[param1] >= g_iHpc.IntValue)
                    {
                        if(u_morehp[param1] == 0)
                        {
                            // Set knife is bought
                            u_morehp[param1] = 1;
                            // Set new money
                            int set_money = money[param1] - g_iHpc.IntValue;
                            money[param1] = set_money;

                            // Set HP
                            int health = GetEntProp(param1, Prop_Send, "m_iHealth");
	                        int nowhealth = health + 50;
	                        SetEntityHealth(param1, nowhealth);

                            PrintToChat(param1," \x04[Knife] \x01You bought a knife More HP!");
                        }
                    }
                }
				case 5:
				{
                    if(money[param1] >= g_iHphc.IntValue)
                    {
                        if(u_heal[param1] == 0)
                        {
                            // Set knife is bought
                            u_heal[param1] = 1;
                            // Set new money
                            int set_money = money[param1] - g_iHphc.IntValue;
                            money[param1] = set_money;

                            // Set HP
                                if(GetConVarBool(g_i35hp))
                                {
                                SetEntityHealth(param1, 35);
                                }else{
                                SetEntityHealth(param1, 100);
                                }
                            PrintToChat(param1," \x04[Knife] \x01You bought a knife Heal!");
                        }
                    }
                }
				case 9:
				{
					return;
				}
			}
		}
		else
		{
			delete menu;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action Showsettings(int client, int args)
{
    if(GetConVarBool(g_iSettings))
    {
        Settings(client);
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

public void Settings(int client)
{
	char text[64];
	
	Panel panel = CreatePanel();
        Format(text, sizeof(text), "[Settings]");
		panel.SetTitle(text);

        if(s_hud[client] == 0)
        {
            Format(text, sizeof(text), "✘ ‒ Turn ON HUDS");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "✔ ‒ Turn OFF Huds");
		    panel.DrawItem(text);
        }
		Format(text, sizeof(text), "⤑ You'll see the money and HP below");
		panel.DrawText(text);

	panel.DrawItem("", ITEMDRAW_NOTEXT);
	panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
	
	panel.DrawItem("Exit");
	panel.Send(client, SettingsMenuHandler, MENU_TIME_FOREVER);
	delete panel;
}

public int SettingsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsPlayerAlive(param1))
		{
			switch (param2)
			{
				case 1:
				{
                    if(s_hud[param1] == 0)
                    {
                        s_hud[param1] = 1;
                        PrintToChat(param1," \x04[Knife] \x01You turn ON huds!");
                    }else{
                        s_hud[param1] = 0;
                        PrintToChat(param1," \x04[Knife] \x01You turn OFF huds!");
                    }
				}
				case 9:
				{
					return;
				}
			}
		}
		else
		{
			delete menu;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}


public Action Showabe(int client, int args)
{
    if(GetConVarBool(g_iAbe))
    {
        Abe(client);
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

public void Abe(int client)
{
	char text[64];
	
	Panel panel = CreatePanel();
        Format(text, sizeof(text), "[Abilities]");
		panel.SetTitle(text);

        if(a_nothing[client] == 1)
        {
            Format(text, sizeof(text), "Nothing [ACTIVE]");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "Nothing [NOACTIVE]");
		    panel.DrawItem(text);
        }
		Format(text, sizeof(text), "⤑ You can change your abilities!");
		panel.DrawText(text);

        if(a_lowmoney[client] == 1)
        {
            Format(text, sizeof(text), "Stilts [ACTIVE]");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "Stilts [NOACTIVE]");
		    panel.DrawItem(text);
        }
		Format(text, sizeof(text), "⤑ You will receive less money, but you will have better abilities!");
		panel.DrawText(text);

        if(a_moremoney[client] == 1)
        {
            Format(text, sizeof(text), "Rich [ACTIVE]");
		    panel.DrawItem(text);
        }else{
            Format(text, sizeof(text), "Rich [NOACTIVE]");
		    panel.DrawItem(text);
        }
		Format(text, sizeof(text), "⤑ You will have more money but worse abilities than others!");
		panel.DrawText(text);

	panel.DrawItem("", ITEMDRAW_NOTEXT);
	panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
    panel.DrawItem("", ITEMDRAW_NOTEXT);
	
	panel.DrawItem("Exit");
	panel.Send(client, AbeMenuHandler, MENU_TIME_FOREVER);
	delete panel;
}

public int AbeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsPlayerAlive(param1))
		{
			switch (param2)
			{
				case 1:
				{
                    if(a_can[param1] == 1)
                    {
                        a_can[param1] = 0;
                        a_nothing[param1] = 1;
                        a_moremoney[param1] = 0;
                        a_lowmoney[param1] = 0;
                    }else{
                        PrintToChat(param1, " \x04[Knife] \x01You can't change Abilities! Wait for now round!");
                    }
				}
				case 2:
				{
                    if(a_can[param1] == 1)
                    {
                        lowmoney(param1);
                        a_can[param1] = 0;
                        a_lowmoney[param1] = 1;
                    }else{
                        PrintToChat(param1, " \x04[Knife] \x01You can't change Abilities! Wait for now round!");
                    }
				}
				case 3:
				{
                    if(a_can[param1] == 1)
                    {
                        moremoney(param1);
                        a_can[param1] = 0;
                        a_moremoney[param1] = 1;
                    }else{
                        PrintToChat(param1, " \x04[Knife] \x01You can't change Abilities! Wait for now round!");
                    }
				}
				case 9:
				{
					return;
				}
			}
		}
		else
		{
			delete menu;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

// Abilities
public Action lowmoney(int client)
{
    if(!IsFakeClient(client))
    {
        if(IsPlayerAlive(client))
        {
            char iMarcus[300];

            // Give more speed them normal players
            float zjisti_speed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
            float novy_speed = zjisti_speed + 0.2;
            SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", novy_speed);

            if(GetConVarBool(g_i35hp))
            {
                SetEntityHealth(client, 50);
            }else{
                SetEntityHealth(client, 115);
            }

            // Give special model
            Format(iMarcus, sizeof(iMarcus), "models/player/custom_player/hekut/marcusreed/marcusreed.mdl");
            SetEntityModel(client, iMarcus);

            PrintToChat(client, " \x04[Knife] \x01You have just set the abilities of the Stilis");
        }
    }
}

public Action moremoney(int client)
{
    if(!IsFakeClient(client))
    {
        if(IsPlayerAlive(client))
        {
            char iMarcus[300];

            // Give more speed them normal players
            float zjisti_speed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
            float novy_speed = zjisti_speed - 0.2;
            SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", novy_speed);
            
            if(GetConVarBool(g_i35hp))
            {
                SetEntityHealth(client, 20);
            }else{
                SetEntityHealth(client, 85);
            }

            // Give special model
            Format(iMarcus, sizeof(iMarcus), "models/player/custom_player/hekut/marcusreed/marcusreed.mdl");
            SetEntityModel(client, iMarcus);

            PrintToChat(client, " \x04[Knife] \x01You have just set the abilities of the Rich");
        }
    }
}

// Hooks

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ( (victim>=1) && (victim<=MaxClients) && (attacker>=1) && (attacker<=MaxClients) && (attacker==inflictor) )
    {
        char WeaponName[64];
        GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
        if(damage > 100.0)
        {
            if (StrContains(WeaponName, "knife", false) != -1)
            {
                damage = 0.0;
                PrintToChat(attacker, " \x04[Knife] \x01Backstab is disabled.");
                return Plugin_Changed;
            }
        }
	}
    return Plugin_Continue;
} 

// Stocks and Bools

bool ClientIsAdmin(client)
{
	return CheckCommandAccess(client, "generic_admin", ADMFLAG_ROOT, 0);
}

stock RemoveAllWeapon(client)
{
    RemoveWeapon(client, CS_SLOT_PRIMARY);
    RemoveWeapon(client, CS_SLOT_SECONDARY);
    RemoveWeapon(client, CS_SLOT_C4);
}

stock RemoveWeapon(client, slot)
{
    new weapon = GetPlayerWeaponSlot(client, slot);
    if (weapon != -1)
    {
        AcceptEntityInput(weapon, "Kill");
    }
} 