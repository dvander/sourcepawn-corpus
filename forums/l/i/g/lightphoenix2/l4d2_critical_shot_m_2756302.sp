#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <Skills>

#define MyName "Critical Shot"
#define LEVELS 3

public Plugin myinfo = 
{
	name = "[L4D] Critical Shot",
	description = "Damage done to special infected will have chance to become critical",
	author = "[E]c, TK",
	version = "1.1",
	url = ""
};
bool g_bHave[MAXPLAYERS + 1], CritPrint;
float CritForce, g_flLevels[LEVELS], g_criChance[MAXPLAYERS + 1], criMulMin, criMulMAX;
int g_iCost, g_iUpgrade, g_iLevel[MAXPLAYERS + 1];
Menu g_hUpgrade;

public APLRes AskPluginLoad2 (Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public iReloadReType OnReloadConfig(const char[] szPerkName)
{
	if (strcmp(szPerkName, MyName) != 0 && strcmp(szPerkName, "666") != 0)
		return RE_NONE;
		
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG_SETTINGS);
	
	if (!FileExists(szPath))
		return RE_FAIL;
		
	KeyValues hFile = new KeyValues("Data");
	
	if(!hFile.ImportFromFile(szPath))
		return RE_FAIL;
	
	iReloadReType iResult = LoadData(hFile, szPath);
	
	delete hFile;
	return iResult;
}

public void OnPluginStart()
{

}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 1 || entity > 2048)
    {
        return;
    }
    
    if (strcmp(classname, "witch") == 0)
    {
        SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public void OnAllPluginsLoaded()
{	
	if(!LibraryExists("l4d2_skills_core"))
		SetFailState("l4d2_skills_core.smx is not loaded.");
		
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), CONFIG_SETTINGS);
	
	if (!FileExists(szPath))
		return;
		
	KeyValues hFile = new KeyValues("Data");
	
	if(!hFile.ImportFromFile(szPath))
		return;
	
	LoadData(hFile, szPath);
	delete hFile;
}

iReloadReType LoadData(KeyValues hFile, const char[] szPath)
{
	if (hFile.JumpToKey(MyName))
	{
		g_iCost = hFile.GetNum("Cost");
		g_iUpgrade = hFile.GetNum("Cost Upgrade");
		g_flLevels[0] = hFile.GetFloat("Level 1 Critical Chance");
		g_flLevels[1] = hFile.GetFloat("Level 2 Critical Chance");
		g_flLevels[2] = hFile.GetFloat("Level 3 Critical Chance");
		criMulMin = hFile.GetFloat("Min Critical Damage Multiplier");
		criMulMAX = hFile.GetFloat("Max Critical Damage Multiplier");
		CritForce = hFile.GetFloat("Critical Force");
		CritPrint = view_as<bool>(hFile.GetNum("Show critical damage in chat"));	
		
		RegisterPerk (MyName, Passive, g_iCost, false);
		return RE_SUCCESSFUL;
	}
	else
	{
		hFile.JumpToKey(MyName, true);
	
		hFile.SetNum("Cost", 5000);
		hFile.SetNum("Cost Upgrade", 2500);
		hFile.SetFloat("Level 1 Critical Chance", 10.0);
		hFile.SetFloat("Level 2 Critical Chance", 15.0);
		hFile.SetFloat("Level 3 Critical Chance", 20.0);
		hFile.SetFloat("Min Critical Damage Multiplier", 2.0);
		hFile.SetFloat("Max Critical Damage Multiplier", 8.0);
		hFile.SetFloat("Critical Force", 100.0);
		hFile.SetNum("Show critical damage in chat", 1);
		
		hFile.Rewind();
		hFile.ExportToFile(szPath);
		
		LoadData(hFile, szPath);
		return RE_CFGCREATED;
	}
}

public void OnShouldReset()
{
	for (int i = 1; i <= MaxClients; i++)
		g_criChance[i] = 0.0;
}

public int OnClientPerkStateChanged (int client, const char[] szPerkName)
{
	if (strcmp(szPerkName, MyName) == 0)
	{
		if (g_iLevel[client] == LEVELS)
		{
			PrintToChat(client, "%s \x04You \x03have max level of perk \x04%s", CHAT_TAG, szPerkName);
			return 0;
			
		}
		else if (!g_bHave[client])
		{
			g_bHave[client] = true;
			g_iLevel[client] = 1;
			g_criChance[client] = g_flLevels[0];
			PrintToChat(client, "%s \x04You \x03bought perk \x04%s", CHAT_TAG, szPerkName);
			return g_iCost;
		}
		else
		{
			UpgradeMenu(client);
			return 0;
		}
	}
	return 0;
}

public int VUpgradeHandler(Menu menu, MenuAction action, int client, int index)
{
	if (action == MenuAction_Cancel)
	{
		if (index == MenuCancel_ExitBack)
			ClientMenu(client);
	}
	else if(action == MenuAction_Select)
	{
		if (index == 4)
		{
			SetClientBalance(client, GetClientBalance(client) - g_iUpgrade);
			g_iLevel[client]++;
			g_criChance[client] = g_flLevels[g_iLevel[client]-1];
			PrintToChat(client, "%s \x04You \x03have upgraded perk \x04%s", CHAT_TAG, MyName);
			PrintToChat(client, "%s \x04Now you can deal \x03Critical \x03Shot \x04 to Special Infected", CHAT_TAG);
			ClientMenu(client);
		}
	}
}

void UpgradeMenu(int client)
{
	g_hUpgrade = new Menu(VUpgradeHandler);
	char szTemp[56];
	Format(szTemp, sizeof szTemp, "Your money: %i", GetClientBalance(client));
	g_hUpgrade.AddItem("", szTemp, ITEMDRAW_DISABLED);
	Format(szTemp, sizeof szTemp, "Level of perk: %i", g_iLevel[client]);
	g_hUpgrade.AddItem("", szTemp, ITEMDRAW_DISABLED);
	Format(szTemp, sizeof szTemp, "Upgrade cost: %i", g_iUpgrade);
	g_hUpgrade.AddItem("", szTemp, ITEMDRAW_DISABLED);
	Format(szTemp, sizeof szTemp, "Next level Critical Chance: %.3f%", g_flLevels[g_iLevel[client]]);
	g_hUpgrade.AddItem("", szTemp, ITEMDRAW_DISABLED);
	g_hUpgrade.AddItem("UPGRADE_BUTTON", "Upgrade");
	g_hUpgrade.ExitBackButton = true;
	g_hUpgrade.SetTitle("Skills: Critical Shot Upgrade");
	g_hUpgrade.Display(client, MENU_TIME_FOREVER);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int TempChance = GetRandomInt(0, 100);
	char weaponname[128];
	if (damagetype != 8)
	{
		char classname[6];
		if(damagetype & DMG_BURN)
		{
			return Plugin_Continue;
		}
		else
		{
			if(GetEntityClassname(victim, classname, sizeof(classname)) && StrEqual(classname, "witch") && attacker > 0 && GetClientTeam(attacker) == 2 && g_iLevel[attacker] > 0 && attacker <= MaxClients && TempChance <= g_criChance[attacker])
			{
				damage = GetRandomFloat(criMulMin, criMulMAX) * damage + 1;
				if(damage < 20.0)
				{
					return Plugin_Changed;
				}
				Knockback(attacker, victim, CritForce, 1.5, 2.0);
				if (CritPrint)
				{
					PrintToChat(attacker, "\x01Critical!\x03 %.2f\x01 damage", damage);
				}
				return Plugin_Changed;
			}
			else if (attacker <= MaxClients && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && GetClientTeam(victim) != 2 && g_iLevel[attacker] > 0  && TempChance <= g_criChance[attacker])
			{
				GetClientWeapon(attacker, weaponname, sizeof(weaponname)); // get the attacker weapon
				if(StrEqual(weaponname, "weapon_melee"))
				{
					damage = (GetRandomFloat(criMulMin, criMulMAX) * damage + 1)/3;
				}
				else
				{
					damage = GetRandomFloat(criMulMin, criMulMAX) * damage + 1;
				}
				if(damage < 20.0)
				{
					return Plugin_Changed;
				}
				Knockback(attacker, victim, CritForce, 1.5, 2.0);
				if (CritPrint)
				{
					PrintToChat(attacker, "\x01Critical!\x03 %.2f\x01 damage", damage);
				}
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public void Knockback(int client,int target, float power, float powHor, float powVec)
{
	float HeadingVector[3], AimVector[3];
	GetClientEyeAngles(client, HeadingVector);

	AimVector[0] = Cosine(DegToRad(HeadingVector[1])) * (power * powHor);
	AimVector[1] = Sine(DegToRad(HeadingVector[1])) * (power * powHor);

	float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);

	float resulting[3];
	resulting[0] = current[0] + AimVector[0];
	resulting[1] = current[1] + AimVector[1];
	resulting[2] = power * powVec;

	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}