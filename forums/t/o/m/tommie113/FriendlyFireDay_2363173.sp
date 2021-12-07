#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

Handle CountdownTimer;

Menu g_PrimaryWeapon = null;
Menu g_SecundaryWeapon = null;

ConVar g_cvFriendlyFire;

bool:CountdownActive = false;
bool:ffdActive = false;

public Plugin:myinfo =
{
	name = "Friendly Fire Day",
	author = "Evil Knievel",
	description = "Friendly Fire enabled for 1 round.",
	version = "1.0",
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	
	RegAdminCmd("sm_ffd", Command_FFD, ADMFLAG_GENERIC, "Command to start FFD");
	g_cvFriendlyFire = FindConVar("mp_friendlyfire");
	
	HookUserMessage(GetUserMessageId("TextMsg"), Hook_TextMsg, true); 
	HookUserMessage(GetUserMessageId("HintText"), Hook_HintText, true);
}

public void OnMapStart()
{
	g_PrimaryWeapon = BuildPrimaryWeaponMenu();
	g_SecundaryWeapon = BuildSecundaryWeaponMenu();
}

public void OnMapEnd()
{
	if(g_PrimaryWeapon != INVALID_HANDLE)
	{
		delete(g_PrimaryWeapon);
		g_PrimaryWeapon = null;
	}
	
	if(g_SecundaryWeapon != INVALID_HANDLE)
	{
		delete(g_SecundaryWeapon);
		g_SecundaryWeapon = null;
	}
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(ffdActive || CountdownActive)
	{
		CloseHandle(CountdownTimer);
		CountdownTimer = null;
		g_cvFriendlyFire.IntValue = 0;
		ffdActive = false;
		CountdownActive = false;
	}
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(CountdownActive)
	{
		SetEventInt(event, "dmg_health", 0);
		SetEventInt(event, "dmg_armor", 0);
	}
}

public Action:Command_FFD(int client, args)
{
	if(CountdownActive || ffdActive)
	{
		ReplyToCommand(client, "Friendly Fire Day is already active!");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "You have succesfully initiated a Friendly Fire Day!");
	
	new maxClients = GetMaxClients();
		
	for (new i=1; i<=maxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			g_PrimaryWeapon.Display(i, MENU_TIME_FOREVER);
		}
	}
	
	CountdownActive = true;
	
	CountdownTimer = CreateTimer(1.0, Countdown, _, TIMER_REPEAT);
	
	return Plugin_Handled;
}

public Action:Countdown(Handle timer)
{
	static int numPrinted = 0;
	int timeleft = 30 - numPrinted;
	
	PrintHintTextToAll("The Friendly Fire Day will start in %i seconds", timeleft);
	
	if(timeleft == 0)
	{
		numPrinted = 0;
		StartFFD();
		return Plugin_Stop;
	}
	
	numPrinted++;
	
	return Plugin_Continue;
}

public StartFFD()
{
	g_cvFriendlyFire.IntValue = 1;
	PrintHintTextToAll("The Friendly Fire Day has started! You can now kill everyone!");
	CountdownActive = false;
	ffdActive = true;
	CountdownTimer = null;
}

Menu BuildPrimaryWeaponMenu()
{
	Menu menu1 = new Menu(Menu_Primary);
	menu1.AddItem("weapon_ak47", "AK47");
	menu1.AddItem("weapon_m4a1", "M4A4");
	menu1.AddItem("weapon_m4a1_silencer", "M4A1-S");
	menu1.AddItem("weapon_awp", "AWP");
	menu1.AddItem("weapon_ssg08", "SCOUT");
	menu1.AddItem("weapon_galilar", "GALIL");
	menu1.AddItem("weapon_famas", "FAMAS");
	menu1.AddItem("weapon_p90", "P90");
	menu1.AddItem("weapon_aug", "AUG");
	menu1.AddItem("weapon_sg553", "SG553");
	menu1.AddItem("weapon_scar20", "SCAR20");
	menu1.AddItem("weapon_g3sg1", "G3SG1");
	menu1.AddItem("weapon_negev", "NEGEV");
	menu1.SetTitle("Select your primary weapon.");
	return menu1;
}

public int Menu_Primary(Menu menu1, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char weapon_id[32];
		menu1.GetItem(param2, weapon_id, sizeof(weapon_id));
		
		GivePlayerItem(param1, weapon_id);

		g_SecundaryWeapon.Display(param1, MENU_TIME_FOREVER);
	}
}

Menu BuildSecundaryWeaponMenu()
{
	Menu menu2 = new Menu(Menu_Secundary);
	menu2.AddItem("weapon_deagle", "DEAGLE");
	menu2.AddItem("weapon_usp_silencer", "USP-S");
	menu2.AddItem("weapon_hkp2000", "P2000");
	menu2.AddItem("weapon_glock", "GLOCK");
	menu2.AddItem("weapon_fiveseven", "FIVESEVEN");
	menu2.AddItem("weapon_tec9", "TEC9");
	menu2.AddItem("weapon_elite", "DUAL ELITES");
	menu2.AddItem("weapon_p250", "P250");
	menu2.AddItem("weapon_cz75a", "CZ75");
	menu2.SetTitle("Select your secundary weapon.");
	return menu2;
}

public int Menu_Secundary(Menu menu2, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char weapon_id[32];
		menu2.GetItem(param2, weapon_id, sizeof(weapon_id));

		GivePlayerItem(param1, weapon_id);
		GivePlayerItem(param1, "weapon_hegrenade");
	}
}
	
public Action:Hook_TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{ 
    char message[256];
    BfReadString(bf, message, sizeof(message)); 

    if (StrContains(message, "teammate_attack") != -1) 
        return Plugin_Handled; 

    if (StrContains(message, "Killed_Teammate") != -1) 
        return Plugin_Handled; 
         
    return Plugin_Continue; 
} 

public Action:Hook_HintText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{
    char message[256];
    BfReadString(bf, message, sizeof(message)); 
     
    if (StrContains(message, "spotted_a_friend") != -1) 
        return Plugin_Handled; 

    if (StrContains(message, "careful_around_teammates") != -1) 
        return Plugin_Handled; 
     
    if (StrContains(message, "try_not_to_injure_teammates") != -1) 
        return Plugin_Handled; 
         
    return Plugin_Continue; 
} 



