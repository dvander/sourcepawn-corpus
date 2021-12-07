/*-----------------------------------------------/
 G L O B A L  S T U F F
------------------------------------------------*/
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.5.1"

new bool:firstSpawn[MAXPLAYERS+1];
new bool:isDark[MAXPLAYERS+1];
new offsFOV;

new Handle:enabled;
new Handle:welcome;
new Handle:speed;
new Handle:healthbonus;
new Handle:ammo;
new Handle:cloak;
new Handle:regen;
new Handle:hpkill;
new Handle:allowfov;
new Handle:playercolor;
new Handle:dark;

/*-----------------------------------------------/
 P L U G I N  I N F O
------------------------------------------------*/
public Plugin:myinfo = 
{
	name = "[TF2] Premium Members",
	author = "noodleboy347",
	description = "Gives donators/premium members special abilities",
	version = PLUGIN_VERSION,
	url = "http://www.frozencubes.com"
}
/*-----------------------------------------------/
 P L U G I N  S T A R T
------------------------------------------------*/
public OnPluginStart()
{
	//Commands
	RegConsoleCmd("premium", Command_Premium)
	RegConsoleCmd("features", Command_Features)
	RegAdminCmd("premium_fov", Command_Fov, ADMFLAG_CUSTOM1)
	RegAdminCmd("dark", Command_Dark, ADMFLAG_CUSTOM1)

	//Convars
	CreateConVar("premium_version", PLUGIN_VERSION, "Version of the premium members plugin")
	enabled = CreateConVar("premium_enabled", "1", "Enables premium member features")
	welcome = CreateConVar("premium_welcome", "1", "Enables the welcome message")
	speed = CreateConVar("premium_speed", "1", "Enables faster movement speed")
	healthbonus = CreateConVar("premium_health", "1", "Enables the health bonus")
	ammo = CreateConVar("premium_ammo", "1", "Enables the extra rockets + grenades")
	cloak = CreateConVar("premium_cloak", "1", "Enables infinite cloak")
	regen = CreateConVar("premium_cloakregen", "1", "Enables cloaked health regeneration")
	hpkill = CreateConVar("premium_health_onkill", "50", "Amount of health to boost on kill")
	allowfov = CreateConVar("premium_allowfov", "1", "Enables usage of premium_fov")
	playercolor = CreateConVar("premium_color", "0", "Sets which color premiums are")
	dark = CreateConVar("premium_allowdark", "1", "Allows players to use !dark")
	
	//Autoconfig
	AutoExecConfig(true, "plugin.premium", "sourcemod");

	//Hooks
	HookEvent("player_death", Event_Death)
	HookEvent("player_spawn", Event_Spawn)
	
	//Other
	offsFOV = FindSendPropInfo("CBasePlayer", "m_iDefaultFOV");
}
/*-----------------------------------------------/
 E N T E R  S E R V E R
------------------------------------------------*/
public OnClientPutInServer(client)
{
	CreateTimer(30.0, Timer_Welcome, client);
	CreateTimer(0.1, Timer_Speed, client);
	CreateTimer(0.1, Timer_Cloak, client);
	isDark[client] = false;
	firstSpawn[client] = true;
}
/*-----------------------------------------------/
 W E L C O M E  T I M E R
------------------------------------------------*/
public Action:Timer_Welcome(Handle:hTimer, any:client)
{
	if(GetConVarInt(enabled) == 1)
	{
		if(GetConVarInt(welcome) == 1)
		{
			if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
			{
				PrintToChat(client, "\x03Welcome to our server! Enjoy your Premium Member Features!");
			}
		}
	}
	return Plugin_Stop;
}
/*-----------------------------------------------/
 P R E M I U M  C O M M A N D
------------------------------------------------*/
public Action:Command_Premium(client, args)
{
	if(GetConVarInt(enabled) == 1)
	{
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			new Handle:premiumpanel = CreatePanel();
			DrawPanelItem(premiumpanel, "Commands");
			DrawPanelText(premiumpanel, "premium_fov <20-170>");
			DrawPanelText(premiumpanel, "- Changes your field of view.");
			DrawPanelText(premiumpanel, " ");
			DrawPanelText(premiumpanel, "dark");
			DrawPanelText(premiumpanel, "- Makes your character colored black.");
			DrawPanelText(premiumpanel, " ");
			DrawPanelItem(premiumpanel, "Exit");
			SendPanelToClient(premiumpanel, client, Panel_Premium, 30);
			CloseHandle(premiumpanel);
		}
		else
		{
			new Handle:featurepanel = CreatePanel();
			DrawPanelItem(featurepanel, "Premium Member Features");
			DrawPanelText(featurepanel, "- Buffed health on spawn");
			DrawPanelText(featurepanel, "- Faster movement speed");
			DrawPanelText(featurepanel, "- 2 extra rockets and grenades");
			DrawPanelText(featurepanel, "- Infinite cloak time");
			DrawPanelText(featurepanel, "- Regenerating health when cloaked");
			DrawPanelText(featurepanel, "- Health buff on kill");
			DrawPanelText(featurepanel, "- Ability to set your FOV");
			DrawPanelText(featurepanel, "- Special player color");
			DrawPanelText(featurepanel, "- Access to !dark");
			DrawPanelText(featurepanel, "- Much more!");
			DrawPanelText(featurepanel, " ");
			DrawPanelItem(featurepanel, "Exit");
			SendPanelToClient(featurepanel, client, Panel_Features, 30);
			CloseHandle(featurepanel);
			PrintToChat(client, "\x03You are not a Premium Member!")
		}
	}
}
/*-----------------------------------------------/
 P R E M I U M  S P A W N
------------------------------------------------*/
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetConVarInt(enabled) == 1)
	{
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			if(firstSpawn[client] == true)
			{
				if(GetConVarInt(playercolor) == 0)
				{
					//Normal
					SetEntityRenderColor(client, 255, 255, 255, 255);
				}
				if(GetConVarInt(playercolor) == 1)
				{
					//Green
					SetEntityRenderColor(client, 100, 255, 100, 255);
				}
				if(GetConVarInt(playercolor) == 2)
				{
					//Red
					SetEntityRenderColor(client, 255, 100, 100, 255);
				}
				if(GetConVarInt(playercolor) == 3)
				{
					//Blue
					SetEntityRenderColor(client, 100, 100, 255, 255);
				}
				if(GetConVarInt(playercolor) == 4)
				{
					//Yellow
					SetEntityRenderColor(client, 255, 255, 100, 255);
				}
				if(GetConVarInt(playercolor) == 5)
				{
					//Cyan
					SetEntityRenderColor(client, 100, 255, 255, 255);
				}
				if(GetConVarInt(playercolor) == 6)
				{
					//Purple
					SetEntityRenderColor(client, 255, 100, 255, 255);
				}
				firstSpawn[client] = false;
			}
		}
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			//V A R I A B L E S
			new health = GetClientHealth(client);
			new weaponEntityIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new TFClassType:playerClass = TF2_GetPlayerClass(client);
			
			//S T A R T  A P P L Y  F E A T U R E S
			if(GetConVarInt(ammo) == 1)
			{
				if(playerClass == TFClass_DemoMan)
				{
					SetEntProp(weaponEntityIndex, Prop_Send, "m_iClip1", GetEntProp(weaponEntityIndex, Prop_Send, "m_iClip1") + 2)
				}
				if(playerClass == TFClass_Soldier)
				{
					SetEntProp(weaponEntityIndex, Prop_Send, "m_iClip1", GetEntProp(weaponEntityIndex, Prop_Send, "m_iClip1") + 2)
				}
			}
			if(GetConVarInt(healthbonus) == 1)
			{
				SetEntityHealth(client, health + 150);
			}
			firstSpawn[client] = false;
			//E N D  A P P L Y  F E A T U R E S
		}
	}
}
/*-----------------------------------------------/
 S P E E D  T I M E R
------------------------------------------------*/
public Action:Timer_Speed(Handle:timer, any:client)
{
	if(GetConVarInt(enabled) == 1)
	{
		if(GetConVarInt(speed) == 1)
		{
			if(GetEntProp(client, Prop_Send, "m_nPlayerCond") & 1)
			{
				//Nothing
			} 
			else
			{
				if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
				{
					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 400.0)
				}
			}
		}
	}
	CreateTimer(0.1, Timer_Speed, client);
}
/*-----------------------------------------------/
 C L O A K  R E G E N E R A T E
------------------------------------------------*/
public Action:Timer_Cloak(Handle:timer, any:client)
{
	if(GetConVarInt(enabled) == 1)
	{
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			if(GetConVarInt(cloak) == 1)
			{
				SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0)
			}
			if(GetEntProp(client, Prop_Send, "m_nPlayerCond") & 16)
			{
				if(GetConVarInt(regen) == 1)
				{
					if(GetClientHealth(client) < 125)
					{
						new health = GetClientHealth(client);
						SetEntityHealth(client, health + 1);
					}
				}
			}
		}
	}
	CreateTimer(0.2, Timer_Cloak, client);
}
/*-----------------------------------------------/
 P R E M I U M  K I L L
------------------------------------------------*/
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(enabled) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker"));
		new health = GetClientHealth(client);
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{
			SetEntityHealth(client, health + GetConVarInt(hpkill));
		}
	}
}
/*-----------------------------------------------/
 F I E L D   O F   V I E W
------------------------------------------------*/
public Action:Command_Fov(client, args)
{
	if(GetConVarInt(enabled) == 1)
	{
		if(GetConVarInt(allowfov) == 1)
		{
			decl String:arg1[32];
			
			GetCmdArg(1, arg1, sizeof(arg1));
			
			new fov = StringToInt(arg1);
			if(fov >= 20)
			{
				if(fov <= 170)
				{
					SetEntData(client, offsFOV, fov, 1);
					ReplyToCommand(client, "\x03You set your FOV to: %i", fov);
				}
				else
				{
					ReplyToCommand(client, "\x03Usage: premium_fov <20-170>");
				}
			}
			else
			{
				ReplyToCommand(client, "\x03Usage: premium_fov <20-170>");
			}
		}
		else
		{
			ReplyToCommand(client, "\x03Sorry, this feature is disabled.")
		}
	}
	return Plugin_Handled;
}
/*-----------------------------------------------/
 D A R K
------------------------------------------------*/
public Action:Command_Dark(client, args)
{
	if(GetConVarInt(dark) == 1)
	{
		if(isDark[client] == false)
		{
			SetEntityRenderColor(client, 0, 0, 0, 255)
			isDark[client] = true;
			ReplyToCommand(client, "\x03You are now dark. Type !dark to return to normal.")
			PrintToChatAll(client, "\x03%s turned themselves dark.", client)
		}
		else
		{
			if(GetConVarInt(playercolor) == 0)
			{
				//Normal
				SetEntityRenderColor(client, 255, 255, 255, 255);
			}
			if(GetConVarInt(playercolor) == 1)
			{
				//Green
				SetEntityRenderColor(client, 100, 255, 100, 255);
			}
			if(GetConVarInt(playercolor) == 2)
			{
				//Red
				SetEntityRenderColor(client, 255, 100, 100, 255);
			}
			if(GetConVarInt(playercolor) == 3)
			{
				//Blue
				SetEntityRenderColor(client, 100, 100, 255, 255);
			}
			if(GetConVarInt(playercolor) == 4)
			{
				//Yellow
				SetEntityRenderColor(client, 255, 255, 100, 255);
			}
			if(GetConVarInt(playercolor) == 5)
			{
				//Cyan
				SetEntityRenderColor(client, 100, 255, 255, 255);
			}
			if(GetConVarInt(playercolor) == 6)
			{
				//Purple
				SetEntityRenderColor(client, 255, 100, 255, 255);
			}
			isDark[client] = false;
			ReplyToCommand(client, "\x03You are no longer dark.")
			PrintToChatAll(client, "\x03%s turned off dark.", client)
		}
	}
	return Plugin_Handled;
}
/*-----------------------------------------------/
 P R E M I U M  F E A T U R E S
------------------------------------------------*/
public Action:Command_Features(client, args)
{
	if(GetConVarInt(enabled) == 1)
	{
		new Handle:featurepanel = CreatePanel();
		DrawPanelItem(featurepanel, "Premium Member Features");
		DrawPanelText(featurepanel, "- Buffed health on spawn");
		DrawPanelText(featurepanel, "- Faster movement speed");
		DrawPanelText(featurepanel, "- 2 extra rockets and grenades");
		DrawPanelText(featurepanel, "- Infinite cloak time");
		DrawPanelText(featurepanel, "- Regenerating health when cloaked");
		DrawPanelText(featurepanel, "- Health buff on kill");
		DrawPanelText(featurepanel, "- Ability to set your FOV");
		DrawPanelText(featurepanel, "- Special player color");
		DrawPanelText(featurepanel, "- Access to !dark");
		DrawPanelText(featurepanel, "- Much more!");
		DrawPanelText(featurepanel, " ");
		DrawPanelItem(featurepanel, "Exit");
		SendPanelToClient(featurepanel, client, Panel_Features, 30);
		CloseHandle(featurepanel);
	}
}
/*-----------------------------------------------/
 P A N E L   H A N D L E R S
------------------------------------------------*/
public Panel_Features(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		//Nothing
	}
}
public Panel_Premium(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		//Nothing
	}
}